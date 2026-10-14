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
#   A  descriptives          B  Friedman / sign tests / Plackett-Luce
#   C  equivalence (TOST)    D  heterogeneity: polarisation, PL tree
#   E  link to SSQ/Presence  F  qualitative content analysis + joint display
#
# Run from the repository root (or from scripts/).
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(ggplot2)
  library(PlackettLuce); library(survival)
})

options(width = 105, scipen = 6)
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
CODES <- c("OCCLUSION", "DISTRACTION", "GLANCE_COST", "ANTICIPATION", "TIMING",
           "VISUAL_NOISE", "REALISM", "SICKNESS", "VISIBILITY", "FAMILIARITY",
           "AGENCY")
EQ_MARGIN <- c(.30, .70)   # "no clear majority": neither side wins more than 70:30
N_BOOT    <- 2000

# ---------------------------------------------------------------- palette/theme
# Same tokens as scripts/study2_analysis.R so figures sit together in the paper.
PAL_METHOD <- c(ROF = "#2a78d6", Minimap = "#eb6834", Path = "#1baf7a")
PAL_RANK   <- c("1st" = "#1d4f91", "2nd" = "#7ea7d8", "3rd" = "#d5e1f1")
PAL_DIV    <- c(neg = "#c4492f", mid = "#f3f2ee", pos = "#2f6fb0")
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
qual <- read_csv(file.path(PREF, "study2_qual_coding.csv"), show_col_types = FALSE)
trials <- read_csv(file.path(BASE, "data/processed/study2_trials.csv"),
                   show_col_types = FALSE)

W <- as.matrix(pref[, c("rank_ROF", "rank_Minimap", "rank_Path")])
colnames(W) <- METHODS
stopifnot(
  nrow(pref) == 36, identical(sort(pref$Participant), 1:36),
  all(apply(W, 1, function(r) identical(sort(as.integer(r)), 1:3))),
  all(na.omit(pref$best_sickness)  %in% c(METHODS, "None")),
  all(na.omit(pref$most_realistic) %in% METHODS),
  all(qual$Method %in% METHODS), all(qual$Code %in% CODES),
  all(qual$Valence %in% c(-1, 1)), all(qual$Participant %in% 1:36),
  !anyDuplicated(qual[, c("Participant", "Method", "Code", "Valence")]),
  setequal(unique(trials$Participant), 1:36)
)

rk <- pref %>%
  select(Participant, starts_with("rank_")) %>%
  pivot_longer(-Participant, names_to = "Method", names_prefix = "rank_",
               values_to = "Rank") %>%
  mutate(Method = factor(Method, METHODS))

ordering <- apply(W, 1, function(r) paste(METHODS[order(r)], collapse = " > "))
first    <- METHODS[apply(W, 1, which.min)]
PERMS <- c("ROF > Minimap > Path", "ROF > Path > Minimap", "Minimap > ROF > Path",
           "Minimap > Path > ROF", "Path > ROF > Minimap", "Path > Minimap > ROF")

# Per-participant x method quantitative outcomes (mean over the 3 videos).
pm <- trials %>%
  group_by(Participant, Method) %>%
  summarise(dTSC = mean(Delta_TSC), PostTSC = mean(Post_TSC),
            Presence = mean(Presence), .groups = "drop")
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
    "; most-realistic pick n = ", sum(!is.na(pref$most_realistic)),
    " (not asked systematically; exploratory).\n",
    "Coding   : ", nrow(qual), " coded segments, ", length(unique(qual$Participant)),
    " participants, ", length(CODES), " codes (see data/preference/study2_qual_codebook.md).\n",
    "NOTE     : Study 2 has no Baseline condition — all statements are method-vs-method.\n",
    sep = "")

# =============================================================================
# A. Descriptives
# =============================================================================
hdr("A. DESCRIPTIVE STATISTICS")

desc <- rk %>%
  group_by(Method) %>%
  summarise(n = n(), MeanRank = mean(Rank), SD = sd(Rank), MedianRank = median(Rank),
            First = sum(Rank == 1), Second = sum(Rank == 2), Last = sum(Rank == 3),
            Borda = sum(3 - Rank), .groups = "drop") %>%
  mutate(FirstPct = 100 * First / n, LastPct = 100 * Last / n)
sub("A.1 Rank summary (1 = most balanced; Borda: 2 pts for 1st, 1 for 2nd)")
show(desc)
wtab(desc, "p1_rank_summary.csv")

ord_tab <- tibble(Ordering = PERMS,
                  n = as.integer(table(factor(ordering, levels = PERMS)))) %>%
  mutate(Pct = 100 * n / sum(n)) %>% arrange(desc(n))
sub("A.2 Frequency of the six possible orderings (uniform expectation = 6 each)")
show(ord_tab)
wtab(ord_tab, "p2_orderings.csv")

pw <- bind_rows(lapply(combn(METHODS, 2, simplify = FALSE), function(p) {
  k <- sum(W[, p[1]] < W[, p[2]])
  tibble(A = p[1], B = p[2], A_preferred = k, B_preferred = nrow(W) - k, n = nrow(W))
}))
sub("A.3 Pairwise preference counts (A preferred = A ranked above B)")
show(pw)

# =============================================================================
# B. Omnibus tests and Plackett-Luce model
# =============================================================================
hdr("B. OMNIBUS TESTS AND PLACKETT-LUCE MODEL")

fr <- friedman.test(W)
kW <- unname(fr$statistic) / (nrow(W) * (ncol(W) - 1))
sub("B.1 Friedman test + Kendall's W")
cat(sprintf("Friedman chi2(%d) = %.3f, p = %s; Kendall's W = %.4f\n",
            fr$parameter, fr$statistic, fmt_p(fr$p.value), kW))

sign_tab <- pw %>%
  rowwise() %>%
  mutate(p = binom.test(A_preferred, n)$p.value) %>%
  ungroup() %>%
  mutate(p_holm = p.adjust(p, "holm"))
sub("B.2 Pairwise exact sign tests (H0: P(A over B) = .5), Holm-corrected")
show(sign_tab)

sub("B.3 Plackett-Luce model (MLE, npseudo = 0)")
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
                 CI_hi = apply(boot, 2, quantile, .975, na.rm = TRUE))
qv <- qvcalc(pl)
pl_tab$QuasiSE <- qv$qvframe[METHODS, "quasiSE"]
cat("\nWorth expressed as P(ranked most balanced); 95% CI = participant bootstrap (B = ",
    N_BOOT, "). Chance = .333\n", sep = "")
show(pl_tab)
wtab(pl_tab, "p3_plackett_luce.csv")

# =============================================================================
# C. Equivalence: is there evidence of NO majority preference?
# =============================================================================
hdr("C. EQUIVALENCE TESTS ON PAIRWISE PREFERENCE (TOST + Bayes factor)")
cat(sprintf(paste0("Equivalence region for P(A over B): [%.2f, %.2f] — i.e. no pair is split\n",
                   "more lopsidedly than 70:30. TOST = two one-sided exact binomial tests;\n",
                   "equivalent at alpha = .05 when the 90%% CI lies inside the region.\n",
                   "BF01 = evidence for P = .5 vs a uniform Beta(1,1) alternative.\n"),
            EQ_MARGIN[1], EQ_MARGIN[2]))

eq_tab <- pw %>%
  rowwise() %>%
  mutate(
    Prop     = A_preferred / n,
    CI95_lo  = binom.test(A_preferred, n)$conf.int[1],
    CI95_hi  = binom.test(A_preferred, n)$conf.int[2],
    CI90_lo  = binom.test(A_preferred, n, conf.level = .90)$conf.int[1],
    CI90_hi  = binom.test(A_preferred, n, conf.level = .90)$conf.int[2],
    p_lower  = binom.test(A_preferred, n, p = EQ_MARGIN[1], alternative = "greater")$p.value,
    p_upper  = binom.test(A_preferred, n, p = EQ_MARGIN[2], alternative = "less")$p.value,
    p_TOST   = max(p_lower, p_upper),
    BF01     = choose(n, A_preferred) * 0.5^n * (n + 1),
    SmallestEqMargin = max(abs(c(CI90_lo, CI90_hi) - .5))
  ) %>%
  ungroup() %>%
  mutate(p_TOST_holm = p.adjust(p_TOST, "holm"),
         Equivalent  = p_TOST_holm < .05) %>%
  select(-p_lower, -p_upper)
show(eq_tab)
cat("\nSmallestEqMargin = the tightest +/- margin around .5 at which TOST would still pass.\n")
wtab(eq_tab, "p4_equivalence.csv")

# =============================================================================
# D. Heterogeneity: polarisation and preference segments
# =============================================================================
hdr("D. HETEROGENEITY — POLARISATION AND PREFERENCE SEGMENTS (exploratory)")

pol <- rk %>%
  group_by(Method) %>%
  summarise(First = sum(Rank == 1), Last = sum(Rank == 3),
            Extreme = sum(Rank != 2), n = n(), .groups = "drop") %>%
  rowwise() %>%
  mutate(ExtremePct = 100 * Extreme / n,
         p = binom.test(Extreme, n, p = 2 / 3, alternative = "greater")$p.value) %>%
  ungroup() %>%
  mutate(p_holm = p.adjust(p, "holm"))
sub("D.1 Polarisation: share of participants placing the method at an extreme (chance = 2/3)")
show(pol)
wtab(pol, "p5_polarisation.csv")

sub("D.2 Are the six orderings uniformly distributed? (Monte-Carlo chi-square)")
gof <- chisq.test(ord_tab$n, simulate.p.value = TRUE, B = 1e5)
cat(sprintf("chi2 = %.3f, Monte-Carlo p = %s\n", gof$statistic, fmt_p(gof$p.value)))

sub("D.3 Mean rank by VR experience")
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

sub("D.4 Plackett-Luce tree (model-based recursive partitioning)")
cat("Partitioning variables: VRExperience, Susceptibility (participant mean Delta TSC),\n",
    "Presence (participant mean). minsize = 10, alpha = .05.\n\n", sep = "")
covd <- pref %>% select(Participant) %>% left_join(pcov, by = "Participant")
covd$G <- group(R, index = seq_len(nrow(W)))
tree <- pltree(G ~ VRExperience + Susceptibility + Presence, data = covd,
               minsize = 10, alpha = .05, npseudo = 0)
print(tree)
root_test <- tryCatch(partykit::nodeapply(tree, ids = 1, FUN = function(n) n$info$test)[[1]],
                      error = function(e) NULL)
if (!is.null(root_test)) {
  cat("\nRoot-node parameter-instability tests (Bonferroni-adjusted p):\n")
  print(round(root_test, 4))
}
cat(sprintf("\nTerminal nodes: %d (1 = no covariate splits the preference structure)\n",
            length(partykit::nodeids(tree, terminal = TRUE))))

# =============================================================================
# E. Link to the quantitative data (stated preference vs measured outcomes)
# =============================================================================
hdr("E. STATED PREFERENCE vs MEASURED SICKNESS AND PRESENCE")

link <- rk %>% mutate(Method = as.character(Method)) %>%
  left_join(pm, by = c("Participant", "Method"))

tau_fun <- function(r, x) {
  if (length(unique(x)) < 2) return(NA_real_)
  suppressWarnings(cor(r, x, method = "kendall"))
}
taus <- link %>%
  group_by(Participant) %>%
  summarise(tau_dTSC = tau_fun(Rank, dTSC),        # + : prefers the method that made them LESS sick
            tau_Pres = tau_fun(Rank, -Presence),   # + : prefers the method with HIGHER presence
            .groups = "drop")
boot_mean_ci <- function(x) {
  x <- na.omit(x)
  q <- quantile(replicate(N_BOOT, mean(sample(x, replace = TRUE))), c(.025, .975))
  c(mean = mean(x), lo = q[[1]], hi = q[[2]])
}
tau_sum <- bind_rows(
  lapply(list(c("tau_dTSC", "Own Delta TSC (prefers less-sick method)"),
              c("tau_Pres", "Own Presence (prefers higher-presence method)")),
         function(v) {
           x <- taus[[v[1]]]; ci <- boot_mean_ci(x)
           tibble(Measure = v[2], n = sum(!is.na(x)), MeanTau = ci[["mean"]],
                  CI_lo = ci[["lo"]], CI_hi = ci[["hi"]],
                  Wilcoxon_p = suppressWarnings(wilcox.test(x, mu = 0, exact = FALSE)$p.value))
         }))
sub("E.1 Within-person Kendall tau between ranking and own outcome (mean over participants)")
show(tau_sum)
cat("(Participants with identical values for all three methods are excluded — tau undefined.)\n")
wtab(tau_sum, "p6_tau_link.csv")

uniq_arg <- function(m, x, fun) { k <- which(x == fun(x)); if (length(k) == 1) m[k] else NA_character_ }
best <- link %>%
  group_by(Participant) %>%
  summarise(Balanced   = Method[Rank == 1],
            LeastSick  = uniq_arg(Method, dTSC, min),
            MostPresent = uniq_arg(Method, Presence, max), .groups = "drop") %>%
  left_join(pref %>% select(Participant, best_sickness, most_realistic), by = "Participant")

match_test <- function(a, b, label) {
  ok <- !is.na(a) & !is.na(b) & a %in% METHODS & b %in% METHODS
  k <- sum(a[ok] == b[ok]); n <- sum(ok)
  tibble(Comparison = label, Match = k, n = n, Pct = 100 * k / n,
         p_vs_chance = binom.test(k, n, p = 1 / 3)$p.value)
}
matches <- bind_rows(
  match_test(best$Balanced, best$LeastSick,   "Most balanced  == own least-sick method (Delta TSC)"),
  match_test(best$Balanced, best$MostPresent, "Most balanced  == own highest-Presence method"),
  match_test(best$best_sickness, best$LeastSick, "Best-sickness pick == own least-sick method"),
  match_test(best$most_realistic, best$MostPresent, "Most-realistic pick == own highest-Presence method"),
  match_test(best$Balanced, best$best_sickness,  "Most balanced  == best-sickness pick"),
  match_test(best$Balanced, best$most_realistic, "Most balanced  == most-realistic pick"),
  match_test(best$best_sickness, best$most_realistic, "Best-sickness pick == most-realistic pick")
)
sub("E.2 Agreement between choices (chance = 1/3; exact binomial)")
show(matches)
wtab(matches, "p7_choice_agreement.csv")

sub("E.3 Rank-ordered (exploded) logit with each person's own outcomes as predictors")
cat("Stage 1: choose the #1 from all three; stage 2: choose #2 from the remaining two.\n",
    "Method constants = Plackett-Luce log-worths (ROF reference). dTSC per 10 points.\n\n", sep = "")
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
cat(sprintf("\nLRT adding own Delta TSC + Presence: chi2(%d) = %.3f, p = %s\n",
            lrt$Df[2], lrt$Chisq[2], fmt_p(lrt$`Pr(>|Chi|)`[2])))
rol_tab <- as_tibble(summary(rol1)$coefficients, rownames = "Term") %>%
  bind_cols(as_tibble(summary(rol1)$conf.int[, 3:4, drop = FALSE]))
wtab(rol_tab, "p8_rank_ordered_logit.csv")

sub("E.4 Secondary picks (exploratory; not asked of every participant)")
pick_tab <- bind_rows(
  tibble(Question = "Most balanced (all)", Pick = best$Balanced),
  tibble(Question = "Best sickness reduction", Pick = na.omit(pref$best_sickness)),
  tibble(Question = "Most realistic", Pick = na.omit(pref$most_realistic))
) %>%
  count(Question, Pick) %>%
  complete(Question, Pick = c(METHODS, "None"), fill = list(n = 0)) %>%
  filter(!(Pick == "None" & n == 0)) %>%
  group_by(Question) %>% mutate(N = sum(n), Pct = 100 * n / N) %>% ungroup()
show(pick_tab)
for (q in c("Best sickness reduction", "Most realistic")) {
  x <- pick_tab %>% filter(Question == q, Pick %in% METHODS) %>% pull(n)
  g <- chisq.test(x, simulate.p.value = TRUE, B = 1e5)
  cat(sprintf("  %-24s uniform GOF over the 3 methods: chi2 = %.3f, MC p = %s (n = %d)\n",
              q, g$statistic, fmt_p(g$p.value), sum(x)))
}
wtab(pick_tab, "p9_secondary_picks.csv")

# =============================================================================
# F. Qualitative content analysis + mixed-methods joint display
# =============================================================================
hdr("F. QUALITATIVE CONTENT ANALYSIS (codebook: data/preference/study2_qual_codebook.md)")

qcell <- qual %>%
  mutate(Val = ifelse(Valence > 0, "Pos", "Neg")) %>%
  count(Method, Code, Val) %>%
  complete(Method = METHODS, Code = CODES, Val = c("Pos", "Neg"), fill = list(n = 0)) %>%
  pivot_wider(names_from = Val, values_from = n) %>%
  mutate(Net = Pos - Neg, Total = Pos + Neg,
         Contested = Pos >= 3 & Neg >= 3,
         Method = factor(Method, METHODS), Code = factor(Code, CODES)) %>%
  arrange(Method, Code)

sub("F.1 Participants mentioning each attribute, by method and valence")
qwide <- qcell %>%
  mutate(Cell = sprintf("+%d/-%d", Pos, Neg)) %>%
  select(Code, Method, Cell) %>%
  pivot_wider(names_from = Method, values_from = Cell)
code_tot <- qcell %>% group_by(Code) %>%
  summarise(AllPos = sum(Pos), AllNeg = sum(Neg), Participants = NA_integer_, .groups = "drop")
code_tot$Participants <- sapply(as.character(code_tot$Code),
                                function(c) length(unique(qual$Participant[qual$Code == c])))
qwide <- qwide %>% left_join(code_tot, by = "Code") %>% arrange(desc(Participants))
show(qwide)
wtab(qcell, "p10_qual_method_code.csv")

sub("F.2 Per-method valence balance")
qmeth <- qual %>%
  group_by(Method) %>%
  summarise(Participants = n_distinct(Participant), Segments = n(),
            Pos = sum(Valence > 0), Neg = sum(Valence < 0), .groups = "drop") %>%
  mutate(PctPositive = 100 * Pos / Segments, Method = factor(Method, METHODS)) %>%
  arrange(Method)
show(qmeth)

sub("F.3 Contested attributes (>= 3 participants on each side)")
show(qcell %>% filter(Contested) %>% select(Method, Code, Pos, Neg))

sub("F.4 Validity check: does coded net valence track the participant's own ranking?")
pnet <- qual %>% group_by(Participant, Method) %>%
  summarise(Net = sum(Valence), .groups = "drop") %>%
  right_join(rk %>% mutate(Method = as.character(Method)), by = c("Participant", "Method")) %>%
  mutate(Net = coalesce(Net, 0L))
ct <- cor.test(pnet$Rank, pnet$Net, method = "spearman", exact = FALSE)
show(pnet %>% group_by(Rank) %>% summarise(MeanNet = mean(Net), n = n(), .groups = "drop"))
cat(sprintf("Spearman rho(rank, net valence) = %.3f, p = %s (expected strongly negative)\n",
            ct$estimate, fmt_p(ct$p.value)))

sub("F.5 Mixed-methods joint display")
top_codes <- function(m, sign, k = 3) {
  d <- qcell %>% filter(Method == m) %>%
    mutate(v = if (sign > 0) Pos else Neg) %>% filter(v > 0) %>%
    arrange(desc(v)) %>% head(k)
  paste(sprintf("%s (%d)", d$Code, d$v), collapse = ", ")
}
quant <- link %>% group_by(Method) %>%
  summarise(DeltaTSC = mean(dTSC), Presence = mean(Presence), .groups = "drop")
joint <- desc %>% mutate(Method = as.character(Method)) %>%
  select(Method, MeanRank, First, Last) %>%
  left_join(tibble(Method = METHODS, P_first = unname(pl_est)), by = "Method") %>%
  left_join(quant, by = "Method") %>%
  left_join(pick_tab %>% filter(Question == "Best sickness reduction") %>%
              select(Method = Pick, SicknessPicks = n), by = "Method") %>%
  left_join(pick_tab %>% filter(Question == "Most realistic") %>%
              select(Method = Pick, RealismPicks = n), by = "Method") %>%
  rowwise() %>%
  mutate(TopPositive = top_codes(Method, +1), TopNegative = top_codes(Method, -1)) %>%
  ungroup()
for (i in seq_len(nrow(joint))) {
  j <- joint[i, ]
  cat(sprintf("%-8s mean rank %.2f | 1st %d / last %d | P(first) %.2f | dTSC %.2f | Presence %.2f | picks: sickness %d, realism %d\n",
              j$Method, j$MeanRank, j$First, j$Last, j$P_first, j$DeltaTSC, j$Presence,
              j$SicknessPicks, j$RealismPicks))
  cat(sprintf("         + %s\n         - %s\n", j$TopPositive, j$TopNegative))
}
wtab(joint, "p11_joint_display.csv")

quotes <- qual %>%
  arrange(Method, Code, desc(Valence), Participant) %>%
  group_by(Method, Code, Valence) %>%
  summarise(n = n(), Quotes = paste(sprintf("P%02d: \"%s\"", head(Participant, 3),
                                            head(Excerpt, 3)), collapse = " | "),
            .groups = "drop")
wtab(quotes, "p12_exemplar_quotes.csv")
cat("\nExemplar quotes per Method x Code x Valence: tables/p12_exemplar_quotes.csv\n")

coder2 <- file.path(PREF, "study2_qual_coding_coder2.csv")
sub("F.6 Inter-coder reliability")
if (file.exists(coder2)) {
  q2 <- read_csv(coder2, show_col_types = FALSE)
  grid <- expand_grid(Participant = 1:36, Method = METHODS, Code = CODES, Valence = c(-1, 1))
  key  <- function(d) paste(d$Participant, d$Method, d$Code, d$Valence)
  a <- key(grid) %in% key(qual); b <- key(grid) %in% key(q2)
  po <- mean(a == b); pe <- mean(a) * mean(b) + (1 - mean(a)) * (1 - mean(b))
  cat(sprintf("Cohen's kappa over %d Participant x Method x Code x Valence cells: %.3f (agreement %.1f%%)\n",
              length(a), (po - pe) / (1 - pe), 100 * po))
} else {
  cat("Single coder. Add data/preference/study2_qual_coding_coder2.csv to report Cohen's kappa.\n")
}

# =============================================================================
# Figures
# =============================================================================
hdr("FIGURES")

# P1 — rank distribution
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
  labs(title = "No interface is consistently ranked most balanced",
       subtitle = sprintf("Rank positions, N = 36. Friedman χ²(2) = %.2f, p = %s; Kendall's W = %.3f",
                          fr$statistic, fmt_p(fr$p.value), kW),
       x = "Participants", y = NULL) +
  theme_pub() + theme(panel.grid.major.y = element_blank(),
                      panel.grid.major.x = element_line(colour = GRID, linewidth = .35))
save_fig(p1, "pref1_rank_distribution.png", 7.5, 3.6)

# P2 — Plackett-Luce P(first) with bootstrap CI
p2 <- ggplot(pl_tab, aes(x = factor(Method, METHODS), y = P_first, colour = Method)) +
  geom_hline(yintercept = 1 / 3, linetype = "dashed", colour = INK2, linewidth = .4) +
  geom_errorbar(aes(ymin = CI_lo, ymax = CI_hi), width = .12, linewidth = .8) +
  geom_point(size = 3.2) +
  geom_text(aes(label = sprintf("%.2f", P_first)), nudge_x = .22, colour = INK, size = 3.4) +
  annotate("text", x = 3.45, y = 1 / 3, label = "chance", vjust = -.5, hjust = 1,
           size = 3, colour = INK2) +
  scale_colour_manual(values = PAL_METHOD, guide = "none") +
  scale_y_continuous(limits = c(0, .65), breaks = seq(0, .6, .1)) +
  labs(title = "Plackett–Luce estimate of P(ranked most balanced)",
       subtitle = sprintf("95%% participant-bootstrap CI (B = %d). LR test vs equal worth: χ²(2) = %.2f, p = %s",
                          N_BOOT, pl_LR, fmt_p(pl_p)),
       x = NULL, y = "P(ranked 1st)") +
  theme_pub()
save_fig(p2, "pref2_plackett_luce.png", 6, 4)

# P3 — pairwise preference with equivalence region
d3 <- eq_tab %>% mutate(Pair = factor(paste(A, "over", B), rev(paste(A, "over", B))))
p3 <- ggplot(d3, aes(y = Pair, x = Prop)) +
  annotate("rect", xmin = EQ_MARGIN[1], xmax = EQ_MARGIN[2], ymin = -Inf, ymax = Inf,
           fill = "#eef3fa") +
  geom_vline(xintercept = .5, colour = INK2, linewidth = .4) +
  geom_errorbarh(aes(xmin = CI95_lo, xmax = CI95_hi), height = 0, linewidth = .5, colour = INK2) +
  geom_errorbarh(aes(xmin = CI90_lo, xmax = CI90_hi), height = 0, linewidth = 2, colour = "#2f6fb0") +
  geom_point(size = 3, colour = INK) +
  geom_text(aes(label = sprintf("%d/%d   TOST p = %s", A_preferred, n, fmt_p(p_TOST_holm))),
            nudge_y = .3, size = 3.1, colour = INK2) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, .1)) +
  labs(title = "Pairwise preference is equivalent to a 50:50 split",
       subtitle = sprintf("Proportion preferring A; thick = 90%% CI (TOST), thin = 95%% CI. Shaded = equivalence region [%.2f, %.2f]",
                          EQ_MARGIN[1], EQ_MARGIN[2]),
       x = "P(A ranked above B)", y = NULL) +
  theme_pub() + theme(panel.grid.major.y = element_blank(),
                      panel.grid.major.x = element_line(colour = GRID, linewidth = .35))
save_fig(p3, "pref3_pairwise_equivalence.png", 7.5, 3.6)

# P4 — stated preference vs own outcomes (per-person tau)
d4 <- taus %>% pivot_longer(-Participant, names_to = "Measure", values_to = "tau") %>%
  filter(!is.na(tau)) %>%
  mutate(Measure = recode(Measure, tau_dTSC = "Own Δ TSC\n(+ = prefers less-sick method)",
                          tau_Pres = "Own Presence\n(+ = prefers higher-presence method)"))
d4s <- tau_sum %>% mutate(Measure = unique(d4$Measure)[c(1, 2)])
p4 <- ggplot(d4, aes(x = Measure, y = tau)) +
  geom_hline(yintercept = 0, colour = INK2, linewidth = .4) +
  geom_jitter(width = .12, height = .03, size = 1.8, colour = "#9a9893", alpha = .8) +
  geom_errorbar(data = d4s, aes(y = MeanTau, ymin = CI_lo, ymax = CI_hi), width = .1,
                linewidth = .8, colour = INK) +
  geom_point(data = d4s, aes(y = MeanTau), size = 3.2, colour = INK) +
  scale_y_continuous(limits = c(-1.05, 1.05), breaks = seq(-1, 1, .5)) +
  labs(title = "Stated preference does not track measured sickness or presence",
       subtitle = "Within-person Kendall τ between 'most balanced' rank and own outcome; mean with 95% bootstrap CI",
       x = NULL, y = "Kendall τ") +
  theme_pub()
save_fig(p4, "pref4_preference_vs_outcomes.png", 6.5, 4.2)

# P5 — secondary picks next to the balanced #1
d5 <- pick_tab %>% filter(Pick %in% METHODS) %>%
  mutate(Question = factor(Question, c("Most balanced (all)", "Best sickness reduction", "Most realistic")),
         Pick = factor(Pick, METHODS))
d5$Question <- factor(sprintf("%s\n(n = %d)", d5$Question, d5$N),
                      levels = unique(sprintf("%s\n(n = %d)", d5$Question, d5$N)[order(d5$Question)]))
p5 <- ggplot(d5, aes(x = Pick, y = n, fill = Pick)) +
  geom_col(width = .62) +
  geom_text(aes(label = n), vjust = -.4, size = 3.3, colour = INK) +
  facet_wrap(~Question, nrow = 1) +
  scale_fill_manual(values = PAL_METHOD, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, .12))) +
  labs(title = "Every question splits three ways",
       subtitle = "Counts of participants choosing each interface (secondary questions not asked of everyone)",
       x = NULL, y = "Participants") +
  theme_pub()
save_fig(p5, "pref5_secondary_picks.png", 8, 3.8)

# P6 — qualitative heatmap (net valence, labelled +pos / -neg)
code_order <- qwide$Code
d6 <- qcell %>% mutate(Code = factor(Code, rev(code_order)),
                       Label = ifelse(Total == 0, "", sprintf("+%d / −%d", Pos, Neg)))
lim <- max(abs(d6$Net))
p6 <- ggplot(d6, aes(x = Method, y = Code, fill = Net)) +
  geom_tile(colour = "#ffffff", linewidth = 1.2) +
  geom_text(aes(label = Label), size = 3.2,
            colour = ifelse(abs(d6$Net) > .6 * lim, "#ffffff", INK)) +
  scale_fill_gradient2(low = PAL_DIV[["neg"]], mid = PAL_DIV[["mid"]], high = PAL_DIV[["pos"]],
                       midpoint = 0, limits = c(-lim, lim), name = "Net (pos − neg)") +
  scale_x_discrete(position = "top") +
  labs(title = "Why participants ranked as they did",
       subtitle = "Participants citing each attribute for or against each interface (coded interview)",
       x = NULL, y = NULL) +
  theme_pub() +
  theme(panel.grid = element_blank(), legend.position = "right",
        legend.title = element_text(size = 9, colour = INK2),
        axis.text.x = element_text(face = "bold", colour = INK, size = 10))
save_fig(p6, "pref6_qual_heatmap.png", 7, 5.6)

cat("Saved: plots/pref1_rank_distribution.png, pref2_plackett_luce.png,\n",
    "       pref3_pairwise_equivalence.png, pref4_preference_vs_outcomes.png,\n",
    "       pref5_secondary_picks.png, pref6_qual_heatmap.png\n", sep = "")

sink()
