# =============================================================================
# Study 2 — "Most balanced interface" preference ranking + qualitative analysis
#
#   Design : at the end of the session each of the 36 participants ranked the
#            three methods (ROF / Minimap / Path Overlay) by which one best
#            BALANCES immersion against motion-sickness mitigation (1 = best),
#            and explained the ranking in a short interview. Later participants
#            were also asked which method best reduced sickness and which felt
#            most realistic (partial coverage, exploratory).
#
#   Input  : data/preference/study2_preference_input.csv  (rankings + picks)
#            data/preference/study2_qual_coding.csv       (coded interview)
#            data/processed/study2_trials.csv             (Delta SSQ, Presence)
#   Output : results/study2/preference/study2_preference_results.txt
#            results/study2/preference/tables/*.csv
#            results/study2/preference/plots/*.png
#
#   Analyses are tiered so the paper can lead with what the design supports:
#     1  PRIMARY       rank distribution, Friedman + Kendall's W, Holm-corrected
#                      exact sign tests, pairwise preference proportions + 95% CI
#     2  SUPPLEMENTARY Plackett-Luce P(ranked first) — a model-based summary of the
#                      SAME 36 rankings, not an independent confirmation
#     3  QUALITATIVE   participant-level prevalence of coded reasons, kept separate
#                      by construct (perceived sickness / perceived realism /
#                      interface experience); reasons for 1st and last place;
#                      mixed evaluations and cases in tension with the ranking
#     4  SECONDARY     stated preference vs each person's own MEASURED Delta TSC
#                      and Presence; secondary PERCEIVED picks (association only)
#     5  EXPLORATORY   equivalence bounds (no pre-specified margin), first/last
#                      split, VR-experience split, Plackett-Luce tree
#
#   Perceived sickness reduction (interview picks / comments), measured sickness
#   change (Delta SSQ) and overall balance (the ranking) are kept distinct
#   throughout. Study 2 has no Baseline: every statement is method-vs-method.
#
# Run from the repository root (or from scripts/).
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(ggplot2)
  library(PlackettLuce); library(survival)
})

options(width = 110, scipen = 6)
set.seed(20261012)

BASE <- getwd()
if (!dir.exists(file.path(BASE, "data/preference"))) BASE <- dirname(BASE)
stopifnot(dir.exists(file.path(BASE, "data/preference")))
PREF <- file.path(BASE, "data", "preference")
RES  <- file.path(BASE, "results", "study2", "preference")
TAB  <- file.path(RES, "tables")
PLOT <- file.path(RES, "plots")
dir.create(TAB,  recursive = TRUE, showWarnings = FALSE)
dir.create(PLOT, recursive = TRUE, showWarnings = FALSE)

METHODS <- c("ROF", "Minimap", "Path")
# Construct families (see codebook): only explicit sickness / realism statements
# are read as perceived sickness / immersion; everything else is interface
# experience that may HELP EXPLAIN balance but is not a direct measure of it.
CODE_FAMILY <- c(
  SICKNESS = "Perceived sickness", REALISM = "Perceived realism",
  OCCLUSION = "Interface experience", DISTRACTION = "Interface experience",
  GLANCE_COST = "Interface experience", ANTICIPATION = "Interface experience",
  TIMING = "Interface experience", VISUAL_NOISE = "Interface experience",
  VISIBILITY = "Interface experience", FAMILIARITY = "Interface experience",
  AGENCY = "Interface experience")
CODES    <- names(CODE_FAMILY)
FAMILIES <- c("Perceived sickness", "Perceived realism", "Interface experience")
N_BOOT   <- 2000

# ---------------------------------------------------------------- palette/theme
# Same tokens as scripts/study2_analysis.R so figures sit together in the paper.
PAL_METHOD <- c(ROF = "#2a78d6", Minimap = "#eb6834", Path = "#1baf7a")
PAL_RANK   <- c("1st" = "#1d4f91", "2nd" = "#7ea7d8", "3rd" = "#d5e1f1")
SEQ_LO <- "#eef3fa"; SEQ_HI <- "#1d4f91"
INK  <- "#0b0b0b"; INK2 <- "#52514e"; GRID <- "#e6e5e1"

theme_pub <- function(base = 11) {
  theme_minimal(base_size = base, base_family = "sans") +
    theme(
      plot.title       = element_text(face = "bold", size = base + 2, colour = INK,
                                      margin = margin(b = 3)),
      plot.subtitle    = element_text(size = base - 1, colour = INK2,
                                      margin = margin(b = 9)),
      plot.caption     = element_text(size = base - 2.5, colour = INK2, hjust = 0,
                                      margin = margin(t = 9)),
      axis.title       = element_text(size = base - 1, colour = INK2),
      axis.text        = element_text(size = base - 1.5, colour = INK2),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = GRID, linewidth = .35),
      panel.grid.major.x = element_blank(),
      strip.text       = element_text(face = "bold", size = base - 0.5, colour = INK),
      legend.position  = "top",
      legend.title     = element_blank(),
      legend.text      = element_text(size = base - 1, colour = INK2),
      legend.key.height = unit(10, "pt"),
      plot.title.position = "plot",
      plot.caption.position = "plot"
    )
}
save_fig <- function(p, file, w, h) {
  ggsave(file.path(PLOT, file), p, width = w, height = h, dpi = 300,
         bg = "#ffffff")
  invisible(file)
}

hdr   <- function(x) cat("\n", strrep("=", 90), "\n", x, "\n", strrep("=", 90), "\n", sep = "")
sub   <- function(x) cat("\n--- ", x, " ---\n\n", sep = "")
fmt_p <- function(p) ifelse(is.na(p), "NA", ifelse(p < .001, "<.001", sprintf("%.3f", p)))
show  <- function(df, digits = 3) print(as.data.frame(df), digits = digits, row.names = FALSE)
wtab  <- function(df, file) write_csv(df, file.path(TAB, file))

# =============================================================================
# 0. Load and validate
# =============================================================================
pref <- read_csv(file.path(PREF, "study2_preference_input.csv"),
                 show_col_types = FALSE) %>% arrange(Participant)
qual <- read_csv(file.path(PREF, "study2_qual_coding.csv"), show_col_types = FALSE) %>%
  mutate(Family = unname(CODE_FAMILY[Code]))
trials <- read_csv(file.path(BASE, "data/processed/study2_trials.csv"),
                   show_col_types = FALSE)

W <- as.matrix(pref[, c("rank_ROF", "rank_Minimap", "rank_Path")])
colnames(W) <- METHODS
stopifnot(
  nrow(pref) == 36, all(sort(pref$Participant) == 1:36),
  all(apply(W, 1, function(r) identical(sort(as.integer(r)), 1:3))),
  all(na.omit(pref$best_sickness)  %in% c(METHODS, "None")),
  all(na.omit(pref$most_realistic) %in% METHODS),
  all(qual$Method %in% METHODS), all(qual$Code %in% CODES),
  all(qual$Valence %in% c(-1, 1)), all(qual$Participant %in% 1:36),
  all(qual$Source %in% c("ranking", "pick")),
  !anyDuplicated(qual[, c("Participant", "Method", "Code", "Valence")]),
  !any(is.na(qual$Excerpt) | qual$Excerpt == ""),
  setequal(unique(trials$Participant), 1:36)
)

rk <- pref %>%
  select(Participant, starts_with("rank_")) %>%
  pivot_longer(-Participant, names_to = "Method", names_prefix = "rank_",
               values_to = "Rank") %>%
  mutate(Method = factor(Method, METHODS))
rkc <- rk %>% mutate(Method = as.character(Method))

ordering <- apply(W, 1, function(r) paste(METHODS[order(r)], collapse = " > "))
PERMS <- c("ROF > Minimap > Path", "ROF > Path > Minimap", "Minimap > ROF > Path",
           "Minimap > Path > ROF", "Path > ROF > Minimap", "Path > Minimap > ROF")

# Per-participant x method MEASURED outcomes (mean over the 3 videos).
pm <- trials %>%
  group_by(Participant, Method) %>%
  summarise(dTSC = mean(Delta_TSC), Presence = mean(Presence), .groups = "drop")
pcov <- trials %>%
  group_by(Participant) %>%
  summarise(VRExperience = factor(first(VRExperience), c("No", "Yes")),
            Susceptibility = mean(Delta_TSC), Presence = mean(Presence),
            .groups = "drop")

sink(file.path(RES, "study2_preference_results.txt"), split = TRUE)

hdr("STUDY 2 — 'MOST BALANCED INTERFACE' PREFERENCE RANKING + QUALITATIVE ANALYSIS")
cat("Question : rank the three interfaces by how well each BALANCES immersion and\n",
    "           motion-sickness mitigation (1 = most balanced).\n",
    "Coverage : ", nrow(pref), "/36 complete strict rankings (no ties).\n",
    "Secondary: best-sickness pick n = ", sum(!is.na(pref$best_sickness)),
    " (incl. ", sum(pref$best_sickness %in% "None"), " 'None'); most-realistic pick n = ",
    sum(!is.na(pref$most_realistic)), " (not asked systematically; exploratory).\n",
    "Coding   : ", nrow(qual), " coded cells (Participant x Method x Code x Valence), ",
    length(unique(qual$Participant)), " participants, ", length(CODES),
    " codes in 3 families (data/preference/study2_qual_codebook.md).\n",
    "Terms    : 'balance' = the ranking; 'perceived' = interview statements/picks;\n",
    "           'measured' = Delta SSQ / Presence questionnaires. These are not interchangeable.\n",
    "NOTE     : Study 2 has no Baseline condition — all statements are method-vs-method.\n",
    sep = "")

# =============================================================================
# 1. PRIMARY — which interface is perceived as most balanced?
# =============================================================================
hdr("1. PRIMARY — RANK DISTRIBUTION, FRIEDMAN, PAIRWISE SIGN TESTS")

desc <- rk %>%
  group_by(Method) %>%
  summarise(n = n(), MeanRank = mean(Rank), SD = sd(Rank), MedianRank = median(Rank),
            First = sum(Rank == 1), Second = sum(Rank == 2), Last = sum(Rank == 3),
            Borda = sum(3 - Rank), .groups = "drop") %>%
  mutate(FirstPct = 100 * First / n, LastPct = 100 * Last / n)
sub("1.1 Rank summary (1 = most balanced; Borda: 2 pts for 1st, 1 for 2nd)")
show(desc)
wtab(desc, "t01_rank_summary.csv")

fr <- friedman.test(W)
kW <- unname(fr$statistic) / (nrow(W) * (ncol(W) - 1))
sub("1.2 Friedman test + Kendall's W (omnibus)")
cat(sprintf("Friedman chi2(%d) = %.3f, p = %s; Kendall's W = %.4f (n = %d)\n",
            fr$parameter, fr$statistic, fmt_p(fr$p.value), kW, nrow(W)))
cat("A non-significant Friedman test is absence of evidence for a difference, not evidence\n",
    "of equal preference (see 5.1 for how precisely the pairwise splits are estimated).\n", sep = "")

pw <- bind_rows(lapply(combn(METHODS, 2, simplify = FALSE), function(p) {
  k <- sum(W[, p[1]] < W[, p[2]])
  bt <- binom.test(k, nrow(W))
  tibble(A = p[1], B = p[2], A_preferred = k, B_preferred = nrow(W) - k, n = nrow(W),
         Prop = k / nrow(W), CI95_lo = bt$conf.int[1], CI95_hi = bt$conf.int[2],
         p = bt$p.value)
})) %>% mutate(p_holm = p.adjust(p, "holm"))
sub("1.3 Pairwise preference: proportion ranking A above B, exact 95% CI, exact sign test (Holm)")
show(pw)
wtab(pw, "t02_pairwise.csv")

# =============================================================================
# 2. SUPPLEMENTARY — Plackett-Luce
# =============================================================================
hdr("2. SUPPLEMENTARY — PLACKETT-LUCE MODEL (same 36 rankings; model-based summary)")

R  <- as.rankings(W)
pl <- PlackettLuce(R, npseudo = 0)
print(summary(pl))
ll_null <- nrow(W) * log(1 / factorial(ncol(W)))
pl_LR   <- 2 * (as.numeric(logLik(pl)) - ll_null)
pl_p    <- pchisq(pl_LR, df = ncol(W) - 1, lower.tail = FALSE)
cat(sprintf("\nLikelihood-ratio test vs equal worth: LR chi2(2) = %.3f, p = %s\n",
            pl_LR, fmt_p(pl_p)))

pfirst <- function(fit) { lw <- coef(fit)[METHODS]; exp(lw) / sum(exp(lw)) }
pl_est <- pfirst(pl)
boot <- t(replicate(N_BOOT, {
  idx <- sample(nrow(W), replace = TRUE)
  tryCatch(pfirst(PlackettLuce(as.rankings(W[idx, ]), npseudo = 0)),
           error = function(e) rep(NA_real_, 3))
}))
pl_tab <- tibble(Method = METHODS, LogWorth = unname(coef(pl)[METHODS]),
                 P_first = unname(pl_est),
                 CI_lo = apply(boot, 2, quantile, .025, na.rm = TRUE),
                 CI_hi = apply(boot, 2, quantile, .975, na.rm = TRUE),
                 Observed_first = as.numeric(desc$FirstPct[match(METHODS, desc$Method)]) / 100)
qvf <- qvcalc(pl)$qvframe
pl_tab$QuasiSE <- qvf$quasiSE[match(METHODS, rownames(qvf))]
cat("\nWorth as P(ranked most balanced); 95% CI = participant bootstrap (B = ", N_BOOT,
    ", ", sum(is.na(boot[, 1])), " failed fits). Chance = .333\n", sep = "")
show(pl_tab)
wtab(pl_tab, "t03_plackett_luce.csv")

# =============================================================================
# 3. QUALITATIVE — why participants ranked as they did
# =============================================================================
hdr("3. QUALITATIVE CONTENT ANALYSIS (unit of prevalence = participant)")
cat("Counts below are NUMBERS OF PARTICIPANTS (each Participant x Method x Code x Valence\n",
    "cell is coded at most once). No inferential tests are run on attribute cells: the\n",
    "counts describe and explain the ranking pattern, they are not outcomes in themselves.\n",
    "Attributes are not interchangeable and are never summed into a single score.\n", sep = "")

qbase <- qual %>% left_join(rkc, by = c("Participant", "Method"))
# Reasons for the BALANCE ranking only: excludes statements made when answering the
# secondary best-sickness / most-realistic questions (Source = "pick"), so the
# perceived picks are not read back in as explanations of overall balance.
qrank <- qbase %>% filter(Source == "ranking")
cat(sprintf("Coded cells: %d from the ranking explanation, %d from answers to the secondary questions.\n",
            sum(qual$Source == "ranking"), sum(qual$Source == "pick")))
cat("Sections 3.1-3.2 and 3.5-3.6 use all cells; 3.3, 3.4 and 3.7 (reasons for the ranking) use\n",
    "ranking-explanation cells only.\n", sep = "")

sub("3.1 Coverage: participants giving reasons for each interface")
qpart <- qbase %>%
  group_by(Participant, Method) %>%
  summarise(AnyPos = any(Valence > 0), AnyNeg = any(Valence < 0), .groups = "drop")
cover <- qpart %>%
  group_by(Method) %>%
  summarise(WithReasons = n(), AnyFavourable = sum(AnyPos), AnyUnfavourable = sum(AnyNeg),
            BothDirections = sum(AnyPos & AnyNeg), .groups = "drop") %>%
  mutate(Method = factor(Method, METHODS)) %>% arrange(Method)
show(cover)
cat(sprintf("Participants with >= 1 coded reason: %d/36\n", n_distinct(qual$Participant)))

sub("3.2 Prevalence: participants citing each attribute FOR (+) / AGAINST (-) each interface")
qcell <- qual %>%
  mutate(Val = ifelse(Valence > 0, "Pos", "Neg")) %>%
  count(Method, Code, Val) %>%
  tidyr::complete(Method = METHODS, Code = CODES, Val = c("Pos", "Neg"), fill = list(n = 0)) %>%
  pivot_wider(names_from = Val, values_from = n) %>%
  mutate(Family = factor(unname(CODE_FAMILY[Code]), FAMILIES),
         Total = Pos + Neg, TwoSided = Pos >= 3 & Neg >= 3,
         Method = factor(Method, METHODS), Code = factor(Code, CODES)) %>%
  arrange(Family, Code, Method)
code_part <- qual %>% group_by(Code) %>%
  summarise(ParticipantsAnyMethod = n_distinct(Participant), .groups = "drop")
qwide <- qcell %>%
  mutate(Cell = sprintf("+%d / -%d", Pos, Neg)) %>%
  select(Family, Code, Method, Cell) %>%
  pivot_wider(names_from = Method, values_from = Cell) %>%
  left_join(code_part, by = "Code") %>%
  arrange(Family, desc(ParticipantsAnyMethod))
show(qwide)
wtab(qcell, "t04_qual_prevalence.csv")

sub("3.3 Reasons given for the interface ranked FIRST (+) and the one ranked LAST (-)")
reason_tab <- function(rank_pos, val) {
  qrank %>% filter(Rank == rank_pos, Valence == val) %>%
    distinct(Participant, Method, Code) %>%
    count(Code, Method) %>%
    tidyr::complete(Code = CODES, Method = METHODS, fill = list(n = 0)) %>%
    pivot_wider(names_from = Method, values_from = n) %>%
    select(Code, all_of(METHODS)) %>%
    mutate(All = ROF + Minimap + Path)
}
n_first <- table(factor(rkc$Method[rkc$Rank == 1], METHODS))
n_last  <- table(factor(rkc$Method[rkc$Rank == 3], METHODS))
reasons <- reason_tab(1, 1) %>% rename_with(~ paste0("First_", .x), -Code) %>%
  left_join(reason_tab(3, -1) %>% rename_with(~ paste0("Last_", .x), -Code), by = "Code") %>%
  mutate(Family = factor(unname(CODE_FAMILY[Code]), FAMILIES)) %>%
  relocate(Family, .after = Code) %>%
  arrange(Family, desc(First_All + Last_All))
cat(sprintf("Ranked first: ROF n = %d, Minimap n = %d, Path n = %d; ranked last: ROF n = %d, Minimap n = %d, Path n = %d\n\n",
            n_first[["ROF"]], n_first[["Minimap"]], n_first[["Path"]],
            n_last[["ROF"]], n_last[["Minimap"]], n_last[["Path"]]))
print(as.data.frame(reasons), digits = 3, row.names = FALSE)
wtab(reasons, "t05_reasons_first_last.csv")

sub("3.4 What does 'balance' rest on? Construct families cited in favour of the #1 interface")
fam_first <- qrank %>% filter(Rank == 1, Valence > 0) %>%
  distinct(Participant, Family) %>%
  mutate(v = TRUE) %>%
  tidyr::complete(Participant = 1:36, Family = FAMILIES, fill = list(v = FALSE)) %>%
  pivot_wider(names_from = Family, values_from = v)
fam_sum <- tibble(
  Pattern = c("Cites perceived sickness", "Cites perceived realism",
              "Cites interface experience", "Cites BOTH sickness and realism",
              "Cites interface experience ONLY", "No favourable reason coded for #1"),
  Participants = c(sum(fam_first$`Perceived sickness`), sum(fam_first$`Perceived realism`),
                   sum(fam_first$`Interface experience`),
                   sum(fam_first$`Perceived sickness` & fam_first$`Perceived realism`),
                   sum(fam_first$`Interface experience` & !fam_first$`Perceived sickness` &
                         !fam_first$`Perceived realism`),
                   sum(!fam_first$`Perceived sickness` & !fam_first$`Perceived realism` &
                         !fam_first$`Interface experience`))) %>%
  mutate(Pct = 100 * Participants / 36)
show(fam_sum)

sub("3.5 Two-sided attributes (>= 3 participants for AND >= 3 against the same interface)")
show(qcell %>% filter(TwoSided) %>% select(Method, Code, Pos, Neg))

sub("3.6 Mixed evaluations within one person (favourable AND unfavourable reasons, same interface)")
mixed <- qbase %>%
  group_by(Participant, Method, Rank) %>%
  filter(any(Valence > 0) & any(Valence < 0)) %>%
  summarise(For = paste(sort(Code[Valence > 0]), collapse = ", "),
            Against = paste(sort(Code[Valence < 0]), collapse = ", "), .groups = "drop") %>%
  arrange(Method, Participant)
show(mixed)
wtab(mixed, "t06_mixed_evaluations.csv")

sub("3.7 Cases in tension with the ranking (flagged for close reading, not scored)")
tension <- qrank %>%
  group_by(Participant, Method, Rank) %>%
  summarise(nFor = sum(Valence > 0), nAgainst = sum(Valence < 0),
            For = paste(sort(Code[Valence > 0]), collapse = ", "),
            Against = paste(sort(Code[Valence < 0]), collapse = ", "), .groups = "drop") %>%
  right_join(rkc, by = c("Participant", "Method", "Rank")) %>%
  mutate(nFor = coalesce(nFor, 0L), nAgainst = coalesce(nAgainst, 0L),
         Flag = case_when(
           Rank == 1 & nFor == 0 & nAgainst > 0 ~ "ranked 1st, only unfavourable reasons",
           Rank == 1 & nFor == 0                ~ "ranked 1st, no ranking reason coded",
           Rank == 3 & nAgainst == 0 & nFor > 0 ~ "ranked last, only favourable reasons",
           Rank == 1 & nAgainst > nFor          ~ "ranked 1st, more reasons against than for",
           Rank == 3 & nFor > nAgainst          ~ "ranked last, more reasons for than against",
           TRUE ~ NA_character_)) %>%
  filter(!is.na(Flag)) %>%
  left_join(qual %>% filter(Source == "ranking") %>% group_by(Participant, Method) %>%
              summarise(Excerpts = paste(sprintf("[%s%s] %s", ifelse(Valence > 0, "+", "-"),
                                                 Code, Excerpt), collapse = " | "),
                        .groups = "drop"),
            by = c("Participant", "Method")) %>%
  arrange(Rank, Participant)
if (nrow(tension) == 0) {
  cat("None: every participant gave >= 1 favourable ranking reason for their #1 interface, and no\n",
      "last-ranked interface drew more favourable than unfavourable ranking reasons. Ties (equal\n",
      "for/against) appear among the mixed evaluations in 3.6.\n", sep = "")
} else show(tension %>% select(Participant, Method, Rank, Flag, For, Against))
wtab(tension, "t07_tension_cases.csv")

sub("3.8 Mixed-methods joint display (ranking | measured outcomes | perceived picks | reasons)")
pick_n <- function(col) {
  x <- table(factor(pref[[col]], METHODS)); tibble(Method = METHODS, n = as.integer(x))
}
top_codes <- function(m, col, k = 3) {
  d <- qcell %>% filter(Method == m, .data[[col]] > 0) %>%
    arrange(desc(.data[[col]])) %>% head(k)
  paste(sprintf("%s (%d)", d$Code, d[[col]]), collapse = ", ")
}
quant <- rkc %>% left_join(pm, by = c("Participant", "Method")) %>%
  group_by(Method) %>%
  summarise(Measured_dTSC = mean(dTSC), Measured_Presence = mean(Presence), .groups = "drop")
joint <- desc %>% mutate(Method = as.character(Method)) %>%
  select(Method, MeanRank, First, Last) %>%
  left_join(quant, by = "Method") %>%
  left_join(pick_n("best_sickness")  %>% rename(Perceived_BestSickness = n), by = "Method") %>%
  left_join(pick_n("most_realistic") %>% rename(Perceived_MostRealistic = n), by = "Method") %>%
  rowwise() %>%
  mutate(TopFor = top_codes(Method, "Pos"), TopAgainst = top_codes(Method, "Neg")) %>%
  ungroup()
for (i in seq_len(nrow(joint))) {
  j <- joint[i, ]
  cat(sprintf("%-8s rank: mean %.2f, 1st %d, last %d | measured: dTSC %.2f, Presence %.2f | perceived picks: sickness %d, realism %d\n",
              j$Method, j$MeanRank, j$First, j$Last, j$Measured_dTSC, j$Measured_Presence,
              j$Perceived_BestSickness, j$Perceived_MostRealistic))
  cat(sprintf("         for:     %s\n         against: %s\n", j$TopFor, j$TopAgainst))
}
cat("(Reason counts = participants; perceived picks from the subset who were asked.)\n")
wtab(joint, "t08_joint_display.csv")

quotes <- qual %>%
  arrange(Method, Code, desc(Valence), Participant) %>%
  group_by(Family, Method, Code, Valence) %>%
  summarise(Participants = n(),
            Quotes = paste(sprintf("P%02d: \"%s\"", head(Participant, 3), head(Excerpt, 3)),
                           collapse = " | "), .groups = "drop") %>%
  arrange(factor(Family, FAMILIES), Method, Code, desc(Valence))
wtab(quotes, "t09_exemplar_quotes.csv")
cat("\nExemplar quotes per Method x Code x Valence: tables/t09_exemplar_quotes.csv\n")

sub("3.9 Inter-coder reliability")
coder2 <- file.path(PREF, "study2_qual_coding_coder2.csv")
if (file.exists(coder2)) {
  q2 <- read_csv(coder2, show_col_types = FALSE)
  key  <- function(d) paste(d$Participant, d$Method, d$Code, d$Valence)
  A <- unique(key(qual)); B <- unique(key(q2))
  psa <- 2 * length(intersect(A, B)) / (length(A) + length(B))
  grid <- expand_grid(Participant = 1:36, Method = METHODS, Code = CODES, Valence = c(-1, 1))
  g <- key(grid); a <- g %in% A; b <- g %in% B
  kappa <- function(a, b) {
    po <- mean(a == b); pe <- mean(a) * mean(b) + (1 - mean(a)) * (1 - mean(b))
    (po - pe) / (1 - pe)
  }
  cat(sprintf("Positive specific agreement (cells coded by either coder): %.3f\n", psa))
  cat(sprintf("Cohen's kappa over all %d possible cells: %.3f\n", length(g), kappa(a, b)),
      "  (most cells are empty for both coders, which inflates raw agreement; kappa corrects\n",
      "   for this only partly — report PSA alongside it.)\n", sep = "")
  per_code <- sapply(CODES, function(cd) { s <- grid$Code == cd; kappa(a[s], b[s]) })
  print(round(per_code, 3))
  dis <- tibble(Cell = c(setdiff(A, B), setdiff(B, A)),
                CodedBy = c(rep("coder1 only", length(setdiff(A, B))),
                            rep("coder2 only", length(setdiff(B, A)))))
  wtab(dis, "t10_coder_disagreements.csv")
  cat("Disagreements to reconcile: tables/t10_coder_disagreements.csv\n")
} else {
  cat("Single coder. Add data/preference/study2_qual_coding_coder2.csv (same schema, coded\n",
      "independently) to report positive specific agreement, Cohen's kappa and a\n",
      "disagreement list for reconciliation.\n", sep = "")
}

# =============================================================================
# 4. SECONDARY — does stated preference align with measured experience?
# =============================================================================
hdr("4. SECONDARY — STATED PREFERENCE vs OWN MEASURED OUTCOMES (association only)")

link <- rkc %>% left_join(pm, by = c("Participant", "Method"))

tau_fun <- function(r, x) {
  if (length(unique(x)) < 2) return(NA_real_)
  suppressWarnings(cor(r, x, method = "kendall"))
}
taus <- link %>%
  group_by(Participant) %>%
  summarise(tau_dTSC = tau_fun(Rank, dTSC),        # + : ranks the method with the SMALLER measured increase higher
            tau_Pres = tau_fun(Rank, -Presence),   # + : ranks the method with the HIGHER measured presence higher
            .groups = "drop")
boot_mean_ci <- function(x) {
  x <- na.omit(x)
  q <- quantile(replicate(N_BOOT, mean(sample(x, replace = TRUE))), c(.025, .975))
  c(mean = mean(x), lo = q[[1]], hi = q[[2]])
}
tau_sum <- bind_rows(
  lapply(list(c("tau_dTSC", "Measured Delta TSC (smaller increase = better)"),
              c("tau_Pres", "Measured Presence (higher = better)")),
         function(v) {
           x <- taus[[v[1]]]; ci <- boot_mean_ci(x)
           tibble(Measure = v[2], n_contributing = sum(!is.na(x)),
                  n_excluded_ties = sum(is.na(x)), MeanTau = ci[["mean"]],
                  CI95_lo = ci[["lo"]], CI95_hi = ci[["hi"]],
                  Wilcoxon_p = suppressWarnings(wilcox.test(x, mu = 0, exact = FALSE)$p.value))
         }))
sub("4.1 Within-person Kendall tau between the balance ranking and own measured outcome")
cat("tau > 0: the participant ranks higher the interface on which they measured better.\n",
    "Participants with identical values on all three interfaces cannot contribute (tau undefined).\n\n",
    sep = "")
show(tau_sum)
wtab(tau_sum, "t11_preference_vs_measured.csv")

uniq_arg <- function(m, x, fun) { k <- which(x == fun(x)); if (length(k) == 1) m[k] else NA_character_ }
best <- link %>%
  group_by(Participant) %>%
  summarise(Balanced = Method[Rank == 1],
            MeasuredLeastSick = uniq_arg(Method, dTSC, min),
            MeasuredMostPresent = uniq_arg(Method, Presence, max), .groups = "drop") %>%
  left_join(pref %>% select(Participant, best_sickness, most_realistic), by = "Participant")

match_test <- function(a, b, label) {
  ok <- !is.na(a) & !is.na(b) & a %in% METHODS & b %in% METHODS
  k <- sum(a[ok] == b[ok]); n <- sum(ok); bt <- binom.test(k, n, p = 1 / 3)
  tibble(Comparison = label, Match = k, n = n, Pct = 100 * k / n,
         CI95_lo = 100 * bt$conf.int[1], CI95_hi = 100 * bt$conf.int[2],
         p_vs_chance = bt$p.value)
}
matches <- bind_rows(
  match_test(best$Balanced, best$MeasuredLeastSick,   "Balanced #1 == measured least-sick (unique min dTSC)"),
  match_test(best$Balanced, best$MeasuredMostPresent, "Balanced #1 == measured highest Presence"),
  match_test(best$best_sickness, best$MeasuredLeastSick, "PERCEIVED best-sickness == MEASURED least-sick"),
  match_test(best$most_realistic, best$MeasuredMostPresent, "PERCEIVED most-realistic == MEASURED highest Presence"),
  match_test(best$Balanced, best$best_sickness,  "Balanced #1 == perceived best-sickness"),
  match_test(best$Balanced, best$most_realistic, "Balanced #1 == perceived most-realistic"),
  match_test(best$best_sickness, best$most_realistic, "Perceived best-sickness == perceived most-realistic")
)
sub("4.2 Agreement between choices (chance = 1/3; exact binomial; n differs per row)")
show(matches)
wtab(matches, "t12_choice_agreement.csv")

sub("4.3 Secondary perceived picks (exploratory; asked of a subset)")
pick_tab <- bind_rows(
  tibble(Question = "Most balanced (all)", Pick = best$Balanced),
  tibble(Question = "Perceived best sickness reduction", Pick = na.omit(pref$best_sickness)),
  tibble(Question = "Perceived most realistic", Pick = na.omit(pref$most_realistic))
) %>%
  count(Question, Pick) %>%
  tidyr::complete(Question, Pick = c(METHODS, "None"), fill = list(n = 0)) %>%
  filter(!(Pick == "None" & n == 0)) %>%
  group_by(Question) %>% mutate(N = sum(n), Pct = 100 * n / N) %>% ungroup()
show(pick_tab)
wtab(pick_tab, "t13_secondary_picks.csv")

sub("4.4 Rank-ordered (exploded) logit with own measured outcomes as predictors (exploratory)")
cat("Stage 1: choose #1 of three; stage 2: #2 of the remaining two (72 choice sets, 4 parameters).\n",
    "Method constants = Plackett-Luce log-worths (ROF reference); dTSC per 10 points.\n\n", sep = "")
expl <- bind_rows(
  link %>% mutate(Stage = 1, Chosen = as.integer(Rank == 1)),
  link %>% filter(Rank != 1) %>% mutate(Stage = 2, Chosen = as.integer(Rank == 2))
) %>%
  mutate(Set = paste(Participant, Stage), Method = factor(Method, METHODS),
         dTSC10 = dTSC / 10)
rol0 <- clogit(Chosen ~ Method + strata(Set), data = expl)
rol1 <- clogit(Chosen ~ Method + dTSC10 + Presence + strata(Set), data = expl)
print(summary(rol1)$coefficients, digits = 3)
cat("\nOdds ratios with 95% CI:\n")
print(round(summary(rol1)$conf.int[, c(1, 3, 4)], 3))
lrt <- anova(rol0, rol1)
cat(sprintf("\nLRT adding own dTSC + Presence: chi2(%d) = %.3f, p = %s\n",
            lrt$Df[2], lrt$Chisq[2], fmt_p(lrt$`Pr(>|Chi|)`[2])))
rol_tab <- as_tibble(summary(rol1)$coefficients, rownames = "Term") %>%
  bind_cols(as_tibble(summary(rol1)$conf.int[, 3:4, drop = FALSE]))
wtab(rol_tab, "t14_rank_ordered_logit.csv")

# =============================================================================
# 5. EXPLORATORY — precision of the null, heterogeneity
# =============================================================================
hdr("5. EXPLORATORY — EQUIVALENCE BOUNDS AND HETEROGENEITY")

sub("5.1 Equivalence bounds for the pairwise splits (no margin was pre-specified)")
cat("No equivalence margin was fixed before the data were seen, so no binary 'equivalent'\n",
    "decision is made. Instead, for each pair we report the tightest symmetric margin around\n",
    ".50 that a TOST at alpha = .05 would accept (= the farther bound of the 90% CI from .50),\n",
    "and the same with Bonferroni adjustment over the 3 pairs (96.7% CI). Readers can judge\n",
    "whether a split of that size is practically negligible.\n\n", sep = "")
eqb <- pw %>%
  rowwise() %>%
  mutate(CI90_lo = binom.test(A_preferred, n, conf.level = .90)$conf.int[1],
         CI90_hi = binom.test(A_preferred, n, conf.level = .90)$conf.int[2],
         CIadj_lo = binom.test(A_preferred, n, conf.level = 1 - .10 / 3)$conf.int[1],
         CIadj_hi = binom.test(A_preferred, n, conf.level = 1 - .10 / 3)$conf.int[2],
         Margin = max(abs(c(CI90_lo, CI90_hi) - .5)),
         Margin_adj = max(abs(c(CIadj_lo, CIadj_hi) - .5))) %>%
  ungroup() %>%
  mutate(Supported_split = sprintf("within %.0f:%.0f", 100 * (.5 + Margin), 100 * (.5 - Margin)),
         Supported_split_adj = sprintf("within %.0f:%.0f", 100 * (.5 + Margin_adj),
                                       100 * (.5 - Margin_adj))) %>%
  select(A, B, A_preferred, n, Prop, CI90_lo, CI90_hi, Margin, Supported_split,
         Margin_adj, Supported_split_adj)
show(eqb)
wtab(eqb, "t15_equivalence_bounds.csv")

sub("5.2 First / last split per interface (descriptive)")
cat("Many 1st AND many last places = divisive; many last places only = consensually disliked.\n\n")
split_tab <- desc %>%
  transmute(Method, First, Last, FirstPct, LastPct)
show(split_tab)
wtab(split_tab, "t16_first_last_split.csv")

ord_tab <- tibble(Ordering = PERMS,
                  n = as.integer(table(factor(ordering, levels = PERMS)))) %>%
  mutate(Pct = 100 * n / sum(n)) %>% arrange(desc(n))
sub("5.3 The six possible orderings (uniform expectation = 6 each)")
show(ord_tab)
gof <- chisq.test(ord_tab$n, simulate.p.value = TRUE, B = 1e5)
cat(sprintf("Monte-Carlo chi-square vs uniform: chi2 = %.3f, p = %s\n", gof$statistic,
            fmt_p(gof$p.value)))
wtab(ord_tab, "t17_orderings.csv")

sub("5.4 By prior VR experience (descriptive + per-group Friedman)")
by_vr <- rk %>% left_join(pcov, by = "Participant") %>%
  group_by(VRExperience, Method) %>%
  summarise(n = n(), MeanRank = mean(Rank), First = sum(Rank == 1),
            Last = sum(Rank == 3), .groups = "drop")
show(by_vr)
for (g in levels(pcov$VRExperience)) {
  ids <- pcov$Participant[pcov$VRExperience == g]
  f <- friedman.test(W[pref$Participant %in% ids, , drop = FALSE])
  cat(sprintf("  VRExperience = %-3s (n = %2d): Friedman chi2(2) = %.3f, p = %s\n",
              g, length(ids), f$statistic, fmt_p(f$p.value)))
}
wtab(by_vr, "t18_by_vr_experience.csv")

sub("5.5 Plackett-Luce tree (appendix; low power at n = 36)")
cat("One Bonferroni-adjusted parameter-instability test per covariate (VRExperience,\n",
    "Susceptibility = participant mean measured dTSC, Presence = participant mean);\n",
    "minsize = 10, alpha = .05. A split would be hypothesis-generating only.\n\n", sep = "")
covd <- pref %>% select(Participant) %>% left_join(pcov, by = "Participant")
covd$G <- group(R, index = seq_len(nrow(W)))
tree <- pltree(G ~ VRExperience + Susceptibility + Presence, data = covd,
               minsize = 10, alpha = .05, npseudo = 0)
print(tree)
root_test <- tryCatch(partykit::nodeapply(tree, ids = 1, FUN = function(n) n$info$test)[[1]],
                      error = function(e) NULL)
if (!is.null(root_test)) {
  cat("\nRoot-node parameter-instability tests:\n")
  print(round(root_test, 4))
}
cat(sprintf("\nTerminal nodes: %d (1 = no covariate splits the preference structure)\n",
            length(partykit::nodeids(tree, terminal = TRUE))))

# =============================================================================
# Figures
# =============================================================================
hdr("FIGURES")

# F1 — rank distribution (primary)
d1 <- rk %>%
  mutate(Pos = factor(c("1st", "2nd", "3rd")[Rank], c("3rd", "2nd", "1st"))) %>%
  count(Method, Pos)
p1 <- ggplot(d1, aes(y = Method, x = n, fill = Pos)) +
  geom_col(position = "stack", width = .62, colour = "#ffffff", linewidth = .5) +
  geom_text(aes(label = n, colour = Pos == "1st"), position = position_stack(vjust = .5),
            size = 3.4, show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "#ffffff", `FALSE` = INK), guide = "none") +
  scale_fill_manual(values = PAL_RANK, breaks = c("1st", "2nd", "3rd"),
                    labels = c("Ranked 1st (most balanced)", "2nd", "3rd")) +
  scale_y_discrete(limits = rev(METHODS)) +
  scale_x_continuous(expand = expansion(mult = c(0, .02)), breaks = seq(0, 36, 6)) +
  labs(title = "Rank positions for the most balanced interface",
       subtitle = sprintf("N = 36 complete rankings. Friedman χ²(2) = %.2f, p = %s; Kendall's W = %.3f",
                          fr$statistic, fmt_p(fr$p.value), kW),
       x = "Participants", y = NULL) +
  theme_pub() + theme(panel.grid.major.y = element_blank(),
                      panel.grid.major.x = element_line(colour = GRID, linewidth = .35))
save_fig(p1, "pref1_rank_distribution.png", 7.5, 3.6)

# F2 — pairwise preference proportions with 95% CI (primary)
d2 <- pw %>% mutate(Pair = factor(paste(A, "over", B), rev(paste(A, "over", B))))
p2 <- ggplot(d2, aes(y = Pair, x = Prop)) +
  geom_vline(xintercept = .5, colour = INK2, linewidth = .4, linetype = "dashed") +
  geom_errorbar(aes(xmin = CI95_lo, xmax = CI95_hi), orientation = "y", width = 0, linewidth = 1.1,
                 colour = "#2f6fb0") +
  geom_point(size = 3, colour = INK) +
  geom_text(aes(x = 1, label = sprintf("%d/%d, Holm p = %s", A_preferred, n, fmt_p(p_holm))),
            hjust = 1, size = 3.1, colour = INK2) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, .1)) +
  labs(title = "Pairwise preference between interfaces",
       subtitle = "Proportion of participants ranking A above B, exact 95% CI; dashed line = 50:50",
       x = "P(A ranked above B)", y = NULL) +
  theme_pub() + theme(panel.grid.major.y = element_blank(),
                      panel.grid.major.x = element_line(colour = GRID, linewidth = .35))
save_fig(p2, "pref2_pairwise_preference.png", 7.5, 3.4)

# F3 — Plackett-Luce P(first) with bootstrap CI (supplementary)
p3 <- ggplot(pl_tab, aes(x = factor(Method, METHODS), y = P_first, colour = Method)) +
  geom_hline(yintercept = 1 / 3, linetype = "dashed", colour = INK2, linewidth = .4) +
  geom_errorbar(aes(ymin = CI_lo, ymax = CI_hi), width = .12, linewidth = .8) +
  geom_point(size = 3.2) +
  geom_text(aes(label = sprintf("%.2f", P_first)), nudge_x = .22, colour = INK, size = 3.4) +
  annotate("text", x = .55, y = 1 / 3, label = "chance (1/3)", vjust = -.5, hjust = 0,
           size = 3, colour = INK2) +
  scale_colour_manual(values = PAL_METHOD, guide = "none") +
  scale_y_continuous(limits = c(0, .7), breaks = seq(0, .7, .1)) +
  labs(title = "Plackett–Luce estimate of P(ranked most balanced)",
       subtitle = sprintf("Supplementary model of the same rankings, 95%% bootstrap CI.\nLR test vs equal worth: χ²(2) = %.2f, p = %s",
                          pl_LR, fmt_p(pl_p)),
       x = NULL, y = "P(ranked 1st)") +
  theme_pub()
save_fig(p3, "pref3_plackett_luce.png", 6.5, 4)

# F4 — qualitative prevalence: for / against, by construct family (participants)
d4 <- qcell %>%
  pivot_longer(c(Pos, Neg), names_to = "Val", values_to = "n") %>%
  mutate(Val = factor(ifelse(Val == "Pos", "Cited in favour", "Cited against"),
                      c("Cited in favour", "Cited against")),
         Code = factor(Code, rev(qwide$Code)),
         Family = factor(Family, FAMILIES))
nmax <- max(d4$n)
p4 <- ggplot(d4, aes(x = Method, y = Code, fill = n)) +
  geom_tile(colour = "#ffffff", linewidth = 1.2) +
  geom_text(aes(label = ifelse(n == 0, "", n), colour = n > .55 * nmax), size = 3.2,
            show.legend = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "#ffffff", `FALSE` = INK), guide = "none") +
  scale_fill_gradient(low = SEQ_LO, high = SEQ_HI, limits = c(0, nmax),
                      name = "Participants") +
  facet_grid(Family ~ Val, scales = "free_y", space = "free_y") +
  labs(title = "Reasons participants gave for and against each interface",
       subtitle = "Number of participants citing each attribute (coded interview, N = 36); attributes are not summed",
       x = NULL, y = NULL) +
  theme_pub() +
  theme(panel.grid = element_blank(), legend.position = "right",
        legend.title = element_text(size = 9, colour = INK2),
        strip.text.y = element_text(angle = 0, hjust = 0),
        axis.text.x = element_text(face = "bold", colour = INK, size = 10))
save_fig(p4, "pref4_qual_reasons.png", 9, 6)

# F5 — stated preference vs own measured outcomes (secondary)
lab_d <- "Measured Δ TSC\n(+ = ranks less-sick interface higher)"
lab_p <- "Measured Presence\n(+ = ranks higher-presence interface higher)"
d5 <- taus %>% pivot_longer(-Participant, names_to = "Measure", values_to = "tau") %>%
  filter(!is.na(tau)) %>%
  mutate(Measure = factor(ifelse(Measure == "tau_dTSC", lab_d, lab_p), c(lab_d, lab_p)))
d5s <- tau_sum %>% mutate(Measure = factor(c(lab_d, lab_p), c(lab_d, lab_p)))
p5 <- ggplot(d5, aes(x = Measure, y = tau)) +
  geom_hline(yintercept = 0, colour = INK2, linewidth = .4) +
  geom_jitter(width = .12, height = .03, size = 1.8, colour = "#9a9893", alpha = .8) +
  geom_errorbar(data = d5s, aes(y = MeanTau, ymin = CI95_lo, ymax = CI95_hi), width = .1,
                linewidth = .8, colour = INK) +
  geom_point(data = d5s, aes(y = MeanTau), size = 3.2, colour = INK) +
  geom_text(data = d5s, aes(y = 1.12, label = sprintf("n = %d", n_contributing)),
            size = 3.1, colour = INK2) +
  scale_y_continuous(limits = c(-1.05, 1.18), breaks = seq(-1, 1, .5)) +
  labs(title = "Balance ranking vs each participant's own measured outcomes",
       subtitle = "Within-person Kendall τ; grey = participants, black = mean with 95% bootstrap CI",
       x = NULL, y = "Kendall τ") +
  theme_pub()
save_fig(p5, "pref5_preference_vs_measured.png", 6.5, 4.4)

# F6 — perceived picks next to the balanced #1 (exploratory)
d6 <- pick_tab %>% filter(Pick %in% METHODS) %>%
  mutate(Q = factor(Question, c("Most balanced (all)", "Perceived best sickness reduction",
                                "Perceived most realistic")),
         Pick = factor(Pick, METHODS)) %>%
  arrange(Q) %>%
  mutate(Panel = factor(sprintf("%s\n(n = %d)", Q, N),
                        unique(sprintf("%s\n(n = %d)", Q, N))))
p6 <- ggplot(d6, aes(x = Pick, y = n, fill = Pick)) +
  geom_col(width = .62) +
  geom_text(aes(label = n), vjust = -.4, size = 3.3, colour = INK) +
  facet_wrap(~Panel, nrow = 1) +
  scale_fill_manual(values = PAL_METHOD, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, .12))) +
  labs(title = "Interface chosen, by question",
       subtitle = "Secondary questions were asked of a subset only; 'None' answers omitted",
       x = NULL, y = "Participants") +
  theme_pub()
save_fig(p6, "pref6_choice_by_question.png", 8.5, 3.8)

cat("Saved: plots/pref1_rank_distribution.png, pref2_pairwise_preference.png,\n",
    "       pref3_plackett_luce.png, pref4_qual_reasons.png,\n",
    "       pref5_preference_vs_measured.png, pref6_choice_by_question.png\n", sep = "")

sink()
