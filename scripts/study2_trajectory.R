# =============================================================================
# Study 2 — Trajectory-based interfaces vs the non-trajectory comparison
#
#   RQ     : are the trajectory-based interfaces developed for this study
#            (Minimap, Path Overlay) as effective as the non-trajectory comparison
#            technique (Reverse Optical Flow) at limiting motion sickness, while
#            being less intrusive?
#   Groups : design-level, fixed before data collection — Minimap and Path Overlay
#            are the two interfaces built for Study 2; ROF is the comparison.
#            Each participant saw BOTH trajectory interfaces and ONE ROF, so every
#            contrast first averages a person's two trajectory interfaces
#            (weights -1, 1/2, 1/2) and is then tested within person.
#
#   Decision structure (intersection-union: the joint claim needs BOTH, so no
#   alpha splitting between them):
#     H1  PRIMARY   measured sickness — NON-INFERIORITY of trajectory vs ROF on
#                   Delta TSC, margin +5 TSC points, one-sided alpha = .05
#     H2  PRIMARY*  recorded intrusiveness-related complaints (interview coding,
#                   definition in data/preference/study2_qual_codebook.md) —
#                   SUPERIORITY, exact within-participant permutation test
#                   * provisional until a second coder's file is reconciled
#   Secondary / sensitivity (never substitutes for H1/H2):
#     C  H1: +15 margin, participant bootstrap, trial-level mixed model,
#            N/O/D subscales (estimates), Group x Video (exploratory)
#     D  H1 per interface: Minimap vs ROF, Path vs ROF, Minimap vs Path
#     F  H2: ranking-source only, + REALISM-, leave-one-code-out, per code,
#            favourable mentions, GLMM, coder agreement (when available)
#     G  Presence contrast; perceived-sickness / realism picks (descriptive);
#        "most balanced" ranking: ROF position + grouped Plackett-Luce
#     H  Study 1 cross-study corroboration: trajectory vs Dynamic FOV, every
#        method vs Baseline (post-trial TSC only — not a direct replication)
#
#   Inputs : data/processed/study2_trials.csv
#            data/preference/study2_preference_input.csv, study2_qual_coding.csv
#            data/processed/ssq_dataset.csv, presence_dataset.csv  (Study 1)
#   Output : results/study2/trajectory/study2_trajectory_results.txt
#            results/study2/trajectory/tables/*.csv, plots/*.png
#
#   Study 2 has no Baseline: every Study 2 statement is method-vs-method.
#   Run from the repository root (or from scripts/).
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(ggplot2)
  library(afex); library(emmeans); library(lme4); library(lmerTest)
})

options(width = 110, scipen = 6)
afex_options(emmeans_model = "multivariate")
emm_options(lmer.df = "satterthwaite")
set.seed(20261017)

BASE <- getwd()
if (!dir.exists(file.path(BASE, "data/preference"))) BASE <- dirname(BASE)
stopifnot(dir.exists(file.path(BASE, "data/preference")))
PREF <- file.path(BASE, "data", "preference")
RES  <- file.path(BASE, "results", "study2", "trajectory")
TAB  <- file.path(RES, "tables")
PLOT <- file.path(RES, "plots")
dir.create(TAB,  recursive = TRUE, showWarnings = FALSE)
dir.create(PLOT, recursive = TRUE, showWarnings = FALSE)

METHODS    <- c("ROF", "Minimap", "Path")
MARGIN     <- 5      # primary non-inferiority margin, TSC points
MARGIN_SENS <- 15    # sensitivity margin
ALPHA      <- .05
N_BOOT     <- 10000
INTR_CODES <- c("OCCLUSION", "DISTRACTION", "GLANCE_COST", "VISUAL_NOISE")

# ---------------------------------------------------------------- palette/theme
# Same tokens as scripts/study2_analysis.R / study2_preference.R.
PAL_METHOD <- c(ROF = "#2a78d6", Minimap = "#eb6834", Path = "#1baf7a")
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
      panel.grid.major.y = element_blank(),
      strip.text       = element_text(face = "bold", size = base - 0.5, colour = INK,
                                      hjust = 0),
      legend.position  = "top",
      legend.title     = element_blank(),
      legend.text      = element_text(size = base - 1, colour = INK2),
      legend.key.height = unit(10, "pt"),
      plot.title.position = "plot",
      plot.caption.position = "plot"
    )
}
save_fig <- function(p, file, w, h) {
  ggsave(file.path(PLOT, file), p, width = w, height = h, dpi = 300, bg = "#ffffff")
  invisible(file)
}

hdr   <- function(x) cat("\n", strrep("=", 90), "\n", x, "\n", strrep("=", 90), "\n", sep = "")
sub   <- function(x) cat("\n--- ", x, " ---\n\n", sep = "")
fmt_p <- function(p) ifelse(is.na(p), "NA", ifelse(p < .001, "<.001", sprintf("%.3f", p)))
show  <- function(df, digits = 3) print(as.data.frame(df), digits = digits, row.names = FALSE)
wtab  <- function(df, file) write_csv(df, file.path(TAB, file))
cp_ci <- function(x, n) as.numeric(binom.test(x, n)$conf.int)

# Paired non-inferiority on a participant-level difference d (positive = the
# trajectory side is WORSE). H0: mu >= margin vs H1: mu < margin. The one-sided
# 95% upper bound equals the upper end of the two-sided 90% CI.
ni_test <- function(d, margin, label) {
  d <- d[!is.na(d)]; n <- length(d); m <- mean(d); se <- sd(d) / sqrt(n); df <- n - 1
  data.frame(comparison = label, n = n, diff = m, se = se,
             lo95 = m - qt(.975, df) * se, hi95 = m + qt(.975, df) * se,
             upper_1s95 = m + qt(1 - ALPHA, df) * se, margin = margin,
             p_NI = pt((m - margin) / se, df),
             noninferior = (m + qt(1 - ALPHA, df) * se) < margin)
}
# Estimate + 95% CI + two-sided paired t (for outcomes without a margin)
est_test <- function(d, label) {
  d <- d[!is.na(d)]; tt <- t.test(d)
  data.frame(comparison = label, n = length(d), diff = mean(d),
             lo95 = tt$conf.int[1], hi95 = tt$conf.int[2],
             t = unname(tt$statistic), df = unname(tt$parameter), p = tt$p.value)
}
boot_mean <- function(d, B = N_BOOT) {
  d <- d[!is.na(d)]
  bs <- replicate(B, mean(sample(d, replace = TRUE)))
  c(lo95 = unname(quantile(bs, .025)), hi95 = unname(quantile(bs, .975)),
    upper_1s95 = unname(quantile(bs, 1 - ALPHA)))
}

# =============================================================================
# Load
# =============================================================================
trials <- read_csv(file.path(BASE, "data/processed/study2_trials.csv"),
                   show_col_types = FALSE) %>%
  mutate(Method = factor(Method, levels = METHODS),
         Video  = factor(Video, levels = c("Cycling", "Walking", "Driving")),
         Group  = factor(ifelse(Method == "ROF", "ROF", "Trajectory"),
                         levels = c("ROF", "Trajectory")),
         Pid    = factor(Participant))
pref <- read_csv(file.path(PREF, "study2_preference_input.csv"),
                 show_col_types = FALSE) %>% arrange(Participant)
qual <- read_csv(file.path(PREF, "study2_qual_coding.csv"), show_col_types = FALSE)

# Study 1 (same loading and de-duplication as scripts/analysis_anova.R)
S1_METHODS <- c("Baseline", "Dynamic FOV", "Minimap", "Overlay Path")
s1_ssq <- read_csv(file.path(BASE, "data/processed/ssq_dataset.csv"), show_col_types = FALSE) %>%
  distinct(full_name, video_experienced, method_experienced, .keep_all = TRUE)
s1_pres <- read_csv(file.path(BASE, "data/processed/presence_dataset.csv"),
                    show_col_types = FALSE) %>%
  distinct(full_name, video_experienced, method_experienced, .keep_all = TRUE) %>%
  mutate(Presence = rowMeans(across(c(presence_env_video, focus_env_video,
                                      control_attention, presence_virtual_space,
                                      unaware_real_env))))
s1 <- inner_join(
  s1_ssq %>% select(full_name, video_experienced, method_experienced, ssq_tsc),
  s1_pres %>% select(full_name, video_experienced, method_experienced, Presence),
  by = c("full_name", "video_experienced", "method_experienced")) %>%
  mutate(Method = factor(method_experienced, levels = S1_METHODS))

sink(file.path(RES, "study2_trajectory_results.txt"), split = TRUE)

hdr("STUDY 2 — TRAJECTORY-BASED (Minimap, Path Overlay) vs NON-TRAJECTORY (ROF) INTERFACES")
cat("Research question: are the trajectory-based interfaces as effective as ROF at limiting\n",
    "motion sickness, while being less intrusive?\n\n",
    "Grouping is design-level: Minimap and Path Overlay are the interfaces developed for\n",
    "Study 2; ROF is the comparison technique. The intrusiveness OUTCOME (H2) was defined\n",
    "on 2026-10-17, after the interview coding existed (see the codebook).\n\n",
    "Joint claim = H1 AND H2 (intersection-union, each at one-sided alpha = .05).\n",
    "ROF is the only non-trajectory interface in Study 2, so every Study 2 result is\n",
    "'trajectory vs ROF', not 'trajectory vs non-trajectory interfaces in general'.\n",
    "Study 2 has no Baseline: nothing here says any interface reduces sickness vs no aid.\n",
    sep = "")

# =============================================================================
hdr("A. DATA AUDIT")
# =============================================================================
cells <- trials %>% count(Participant, Method)
stopifnot(nrow(trials) == 324, n_distinct(trials$Participant) == 36,
          nrow(cells) == 108, all(cells$n == 3),
          all(sort(unique(pref$Participant)) == 1:36),
          all(qual$Method %in% METHODS), all(qual$Participant %in% 1:36))
cat(sprintf("Study 2 trials: %d (36 participants x 3 interfaces x 3 videos), complete.\n",
            nrow(trials)))
cat(sprintf("Interview coding: %d rows; preference file: %d participants.\n",
            nrow(qual), nrow(pref)))
s1_cells <- s1 %>% count(full_name)
stopifnot(n_distinct(s1$full_name) == 36, all(s1_cells$n == 12), !anyNA(s1$Method))
cat(sprintf("Study 1: %d observations (36 x 4 methods x 3 videos), complete.\n", nrow(s1)))

# Participant x Method means over the 3 videos (Study 2)
pm <- trials %>%
  group_by(Participant, Method) %>%
  summarise(TSC = mean(Delta_TSC), Nausea = mean(Delta_Nausea),
            Oculomotor = mean(Delta_Oculomotor), Disorientation = mean(Delta_Disorientation),
            Presence = mean(Presence), PreTSC = mean(Pre_TSC), .groups = "drop")
contrasts_of <- function(var) {
  pm %>% select(Participant, Method, v = all_of(var)) %>%
    pivot_wider(names_from = Method, values_from = v) %>%
    mutate(traj = (Minimap + Path) / 2 - ROF, min_rof = Minimap - ROF,
           path_rof = Path - ROF, min_path = Minimap - Path)
}
cTSC <- contrasts_of("TSC")

sub("A.1 Pre-trial TSC by group (is the Delta-score comparison on a level footing?)")
pre_chk <- est_test(contrasts_of("PreTSC")$traj, "Pre-trial TSC: Trajectory - ROF")
show(pre_chk)
cat("A Delta-score difference between groups estimates the same quantity as a post-trial\n",
    "difference only if pre-trial levels are similar; a near-zero difference here supports\n",
    "comparing Delta TSC with the Study 1 (post-trial) margin below.\n", sep = "")

sub("A.2 Interface means (participant-level, averaged over videos)")
desc <- pm %>% group_by(Method) %>%
  summarise(n = n(), dTSC_mean = mean(TSC), dTSC_sd = sd(TSC),
            Presence_mean = mean(Presence), Presence_sd = sd(Presence), .groups = "drop")
show(desc)
wtab(desc, "t01_interface_means.csv")

# =============================================================================
hdr("B. H1 PRIMARY — MEASURED SICKNESS: NON-INFERIORITY ON DELTA TSC (margin +5)")
# =============================================================================
sub("B.1 Where the margin comes from (Study 1, post-trial TSC vs Baseline)")
s1_pm <- s1 %>% group_by(full_name, Method) %>%
  summarise(TSC = mean(ssq_tsc), Presence = mean(Presence), .groups = "drop") %>%
  pivot_wider(names_from = Method, values_from = c(TSC, Presence))
s1_red <- bind_rows(lapply(S1_METHODS[-1], function(m)
  est_test(s1_pm$TSC_Baseline - s1_pm[[paste0("TSC_", m)]],
           paste0("Baseline - ", m, " (reduction)"))))
show(s1_red %>% select(comparison, n, diff, lo95, hi95))
smallest <- min(s1_red$diff)
cat(sprintf("\nSmallest Study 1 reduction vs Baseline = %.2f TSC; one third = %.2f -> margin = %g.\n",
            smallest, smallest / 3, MARGIN))
cat("Rationale: a trajectory interface may be at most 5 TSC points worse than ROF, i.e. it\n",
    "would still keep about two-thirds of the smallest benefit any assistance method showed\n",
    "over no assistance in Study 1. The margin was set in scripts/study2_analysis.R (4.F)\n",
    "before this research question was posed. Same units (TSC points) and direction\n",
    "(higher = sicker); Study 1 is post-trial TSC, Study 2 is the pre-to-post change.\n",
    "Constancy caveat: Study 2 has no Baseline, so it cannot show that ROF itself reduced\n",
    "sickness here; 'as effective as ROF' is not 'effective'.\n", sep = "")
wtab(s1_red, "t02_margin_source_study1.csv")

sub("B.2 Primary test: d = mean(Delta TSC Minimap, Path) - Delta TSC ROF (positive = trajectory sicker)")
h1 <- ni_test(cTSC$traj, MARGIN, "Trajectory - ROF")
show(h1, 4)
cat(sprintf("\nNon-inferiority %s: one-sided 95%% upper bound %.2f %s +%g (p_NI = %s).\n",
            ifelse(h1$noninferior, "ESTABLISHED", "NOT established"),
            h1$upper_1s95, ifelse(h1$noninferior, "<", ">="), MARGIN, fmt_p(h1$p_NI)))

sub("B.3 Same contrast from the Method x Video RM-ANOVA (emmeans, checks the coding order)")
fit_d <- aov_ez(id = "Pid", dv = "Delta_TSC", data = trials, within = c("Method", "Video"))
emm   <- emmeans(fit_d, ~ Method)
lv    <- as.character(summary(emm)$Method)
cvec  <- c(ROF = -1, Minimap = .5, Path = .5)[lv]
cat("Factor level order:", paste(lv, collapse = ", "), "-> weights",
    paste(cvec, collapse = ", "), "\n")
con <- summary(contrast(emm, list(`Trajectory - ROF` = unname(cvec))),
               infer = TRUE, level = .90)
show(con, 4)
stopifnot(abs(con$estimate - h1$diff) < 1e-8)
cat("(two-sided 90% CI upper = one-sided 95% bound; identical to B.2.)\n")

# =============================================================================
hdr("C. H1 SENSITIVITY / SECONDARY")
# =============================================================================
sub("C.1 Wider margin (+15 = the size of the Study 1 reductions) — sensitivity only")
show(ni_test(cTSC$traj, MARGIN_SENS, "Trajectory - ROF"), 4)

sub("C.2 Participant bootstrap (percentile, 10,000 resamples) of the same mean difference")
bt <- boot_mean(cTSC$traj)
cat(sprintf("mean %.2f, 95%% CI [%.2f, %.2f], one-sided 95%% upper bound %.2f -> %s\n",
            mean(cTSC$traj), bt["lo95"], bt["hi95"], bt["upper_1s95"],
            ifelse(bt["upper_1s95"] < MARGIN, "non-inferior", "not non-inferior")))

sub("C.3 Trial-level mixed model: Delta TSC ~ Group * Video + (1|P) + (1|P:Method)")
cat("Uses all 324 trials; the (1|P:Method) term keeps the two trajectory interfaces as\n",
    "separate repeated units instead of treating their 6 trials as one condition.\n\n", sep = "")
m_lmm <- lmer(Delta_TSC ~ Group * Video + (1 | Pid) + (1 | Pid:Method), data = trials)
lmm_c <- summary(contrast(emmeans(m_lmm, ~ Group), "revpairwise"),
                 infer = TRUE, level = .90)
lmm_c$p_NI <- pt((lmm_c$estimate - MARGIN) / lmm_c$SE, lmm_c$df)
show(lmm_c, 4)
cat(sprintf("Singular fit: %s. Upper 90%% limit %.2f -> %s at +%g.\n",
            isSingular(m_lmm), lmm_c$upper.CL,
            ifelse(lmm_c$upper.CL < MARGIN, "non-inferior", "not non-inferior"), MARGIN))

sub("C.4 Two-sided equivalence (TOST, +/-5) — a different question: is trajectory also not BETTER by > 5?")
se_t <- sd(cTSC$traj) / sqrt(36)
p_lo <- pt((mean(cTSC$traj) + MARGIN) / se_t, 35, lower.tail = FALSE)
cat(sprintf("p(lower) = %s, p(upper) = %s -> TOST p = %s (%s)\n", fmt_p(p_lo), fmt_p(h1$p_NI),
            fmt_p(max(p_lo, h1$p_NI)),
            ifelse(max(p_lo, h1$p_NI) < ALPHA, "equivalent within +/-5", "not shown equivalent")))

sub("C.5 Subscales (Delta, Trajectory - ROF): estimates only — no margin defined; Holm across N/O/D")
subs <- bind_rows(lapply(c("Nausea", "Oculomotor", "Disorientation"), function(v)
  est_test(contrasts_of(v)$traj, v))) %>% mutate(p_holm = p.adjust(p, "holm"))
show(subs, 3)
wtab(bind_rows(h1 %>% mutate(analysis = "primary"),
               ni_test(cTSC$traj, MARGIN_SENS, "Trajectory - ROF") %>% mutate(analysis = "margin 15")),
     "t03_h1_noninferiority.csv")
wtab(subs, "t04_h1_subscales.csv")

sub("C.6 Group x Video (exploratory): the trajectory - ROF contrast within each video")
dv_vid <- trials %>% group_by(Participant, Video, Method) %>%
  summarise(v = mean(Delta_TSC), .groups = "drop") %>%
  pivot_wider(names_from = Method, values_from = v) %>%
  mutate(traj = (Minimap + Path) / 2 - ROF)
by_vid <- bind_rows(lapply(levels(trials$Video), function(vd)
  ni_test(dv_vid$traj[dv_vid$Video == vd], MARGIN, vd)))
show(by_vid %>% select(comparison, n, diff, lo95, hi95, upper_1s95), 3)
gv <- aov_ez(id = "Participant", dv = "traj", data = dv_vid, within = "Video")
cat("\nDoes the contrast differ by video? (RM-ANOVA on the contrast, GG-corrected)\n")
print(nice(gv))
wtab(by_vid, "t05_h1_by_video.csv")

# =============================================================================
hdr("D. H1 PER INTERFACE — is the group result carried by both trajectory interfaces?")
# =============================================================================
ind <- bind_rows(ni_test(cTSC$min_rof,  MARGIN, "Minimap - ROF"),
                 ni_test(cTSC$path_rof, MARGIN, "Path - ROF")) %>%
  mutate(p_NI_holm = p.adjust(p_NI, "holm"))
show(ind, 3)
cat("\nHomogeneity of the group (Minimap vs Path; a difference here weakens pooling):\n")
show(est_test(cTSC$min_path, "Minimap - Path"), 3)
wtab(ind, "t06_h1_per_interface.csv")

# =============================================================================
hdr("E. H2 PRIMARY* — RECORDED INTRUSIVENESS-RELATED COMPLAINTS")
# =============================================================================
cat("Outcome: Complaint[participant, interface] = 1 if the coding has at least one\n",
    "Valence = -1 cell on ", paste(INTR_CODES, collapse = ", "), "\n",
    "for that participant and interface. Unsolicited comments only: a missing complaint\n",
    "is NOT evidence that the interface was unobtrusive. *Single coder — provisional.\n", sep = "")

complaint_matrix <- function(q) {
  hits <- q %>% distinct(Participant, Method) %>% mutate(I = 1L)
  expand_grid(Participant = 1:36, Method = METHODS) %>%
    left_join(hits, by = c("Participant", "Method")) %>%
    mutate(I = coalesce(I, 0L)) %>%
    pivot_wider(names_from = Method, values_from = I) %>%
    arrange(Participant)
}
# Exact permutation test. Null: within each participant the three interface labels
# are exchangeable (no interface differs in complaint propensity). Under that null,
# each of the 6 label permutations is equally likely, so 2*D_i takes the value
# 3*x_k - sum(x) for each of the participant's three observations x_k with
# probability 1/3; the null distribution of S = sum(2*D_i) is the exact convolution.
perm_exact <- function(W) {
  X <- as.matrix(W[, METHODS]); n <- nrow(X); off <- 3 * n
  dist <- numeric(2 * off + 1); dist[off + 1] <- 1
  for (i in seq_len(n)) {
    vals <- 3 * X[i, ] - sum(X[i, ]); new <- numeric(length(dist)); idx <- which(dist > 0)
    for (v in vals) new[idx + v] <- new[idx + v] + dist[idx] / 3
    dist <- new
  }
  S <- sum(2 * X[, "ROF"] - X[, "Minimap"] - X[, "Path"]); sup <- (-off):off
  p_up <- sum(dist[sup >= S]); p_dn <- sum(dist[sup <= S])
  c(S = S, p_one = p_up, p_two = min(1, 2 * min(p_up, p_dn)))
}
h2_summary <- function(W, label) {
  D  <- W$ROF - (W$Minimap + W$Path) / 2
  pe <- perm_exact(W); bt <- boot_mean(D)
  data.frame(variant = label,
             ROF = sum(W$ROF), Minimap = sum(W$Minimap), Path = sum(W$Path),
             traj_mean_pct = 100 * mean((W$Minimap + W$Path) / 2),
             ROF_pct = 100 * mean(W$ROF),
             mean_D = mean(D), lo95 = bt[["lo95"]], hi95 = bt[["hi95"]],
             p_exact_one = pe[["p_one"]], p_exact_two = pe[["p_two"]])
}
neg <- qual %>% filter(Valence == -1)
W_main <- complaint_matrix(neg %>% filter(Code %in% INTR_CODES))

sub("E.1 Participants with >= 1 recorded complaint, per interface (n = 36 each)")
rates <- tibble(Method = METHODS,
                n = sapply(METHODS, function(m) sum(W_main[[m]])),
                pct = 100 * n / 36,
                lo95 = sapply(n, function(x) 100 * cp_ci(x, 36)[1]),
                hi95 = sapply(n, function(x) 100 * cp_ci(x, 36)[2]))
show(rates, 3)

sub("E.2 Primary test: D_i = Complaint_ROF - mean(Complaint_Minimap, Complaint_Path); H1: E[D] > 0")
h2 <- h2_summary(W_main, "primary (4 codes, all sources)")
show(h2, 3)
cat(sprintf("\nmean D = %+.3f (bootstrap 95%% CI [%.3f, %.3f]); exact one-sided p = %s -> %s.\n",
            h2$mean_D, h2$lo95, h2$hi95, fmt_p(h2$p_exact_one),
            ifelse(h2$p_exact_one < ALPHA,
                   "fewer recorded complaints for the trajectory interfaces (provisional)",
                   "no evidence of fewer recorded complaints for the trajectory interfaces")))
cat("D distribution:\n"); print(table(D = W_main$ROF - (W_main$Minimap + W_main$Path) / 2))

sub("E.3 Per interface vs ROF: exact McNemar (Holm over the two vs-ROF tests)")
mcn <- function(a, b, label) {
  b10 <- sum(W_main[[a]] == 1 & W_main[[b]] == 0); b01 <- sum(W_main[[a]] == 0 & W_main[[b]] == 1)
  data.frame(comparison = label, only_first = b10, only_second = b01,
             p = if (b10 + b01 > 0) binom.test(b10, b10 + b01)$p.value else 1)
}
pw <- bind_rows(mcn("ROF", "Minimap", "ROF vs Minimap"), mcn("ROF", "Path", "ROF vs Path")) %>%
  mutate(p_holm = p.adjust(p, "holm"))
show(pw, 3)
cat("\nHomogeneity check:\n"); show(mcn("Minimap", "Path", "Minimap vs Path"), 3)
wtab(rates, "t07_h2_complaint_rates.csv")
wtab(bind_rows(pw, mcn("Minimap", "Path", "Minimap vs Path")), "t08_h2_pairwise.csv")

# =============================================================================
hdr("F. H2 SENSITIVITY / SECONDARY")
# =============================================================================
sub("F.1 Alternative scopes of the same outcome (exact one-sided p; H1: ROF more complaints)")
variants <- list(
  "ranking-source only"   = neg %>% filter(Code %in% INTR_CODES, Source == "ranking"),
  "+ REALISM-"            = neg %>% filter(Code %in% c(INTR_CODES, "REALISM")))
for (cd in INTR_CODES)
  variants[[paste("without", cd)]] <- neg %>% filter(Code %in% setdiff(INTR_CODES, cd))
sens <- bind_rows(h2, bind_rows(lapply(names(variants), function(v)
  h2_summary(complaint_matrix(variants[[v]]), v))))
show(sens, 3)
cat("\nLeave-one-code-out shows which complaint type the result depends on.\n")

sub("F.2 Each complaint type separately (participants, n = 36 per interface)")
per_code <- expand_grid(Code = INTR_CODES, Method = METHODS) %>%
  left_join(neg %>% filter(Code %in% INTR_CODES) %>% distinct(Participant, Method, Code) %>%
              count(Code, Method, name = "complaints"), by = c("Code", "Method")) %>%
  left_join(qual %>% filter(Valence == 1, Code %in% INTR_CODES) %>%
              distinct(Participant, Method, Code) %>% count(Code, Method, name = "favourable"),
            by = c("Code", "Method")) %>%
  mutate(across(c(complaints, favourable), ~ coalesce(.x, 0L)))
show(per_code %>% pivot_wider(names_from = Method, values_from = c(complaints, favourable)))
wtab(per_code, "t09_h2_per_code.csv")

sub("F.3 Favourable mentions on the same four codes (reported separately, never netted)")
fav <- h2_summary(complaint_matrix(qual %>% filter(Valence == 1, Code %in% INTR_CODES)),
                  "favourable (4 codes)")
show(fav %>% select(-p_exact_one), 3)
cat("Here D > 0 means MORE favourable mentions for ROF (two-sided exact p shown).\n")
wtab(bind_rows(sens, fav), "t10_h2_sensitivity.csv")

sub("F.4 GLMM: Complaint ~ Group + (1 | Participant), 108 participant x interface rows")
long_c <- W_main %>% pivot_longer(all_of(METHODS), names_to = "Method", values_to = "I") %>%
  mutate(Group = factor(ifelse(Method == "ROF", "ROF", "Trajectory"),
                        levels = c("Trajectory", "ROF")))
glmm <- tryCatch(glmer(I ~ Group + (1 | Participant), data = long_c, family = binomial),
                 error = function(e) NULL)
if (!is.null(glmm)) {
  cf <- summary(glmm)$coefficients["GroupROF", ]
  cat(sprintf("OR (ROF vs Trajectory) = %.2f, Wald 95%% CI [%.2f, %.2f], one-sided p = %s; singular = %s\n",
              exp(cf[1]), exp(cf[1] - 1.96 * cf[2]), exp(cf[1] + 1.96 * cf[2]),
              fmt_p(pnorm(cf[3], lower.tail = FALSE)), isSingular(glmm)))
} else cat("GLMM did not converge.\n")

sub("F.5 Coding reliability for this outcome")
coder2 <- file.path(PREF, "study2_qual_coding_coder2.csv")
if (file.exists(coder2)) {
  W2 <- complaint_matrix(read_csv(coder2, show_col_types = FALSE) %>%
                           filter(Valence == -1, Code %in% INTR_CODES))
  a <- unlist(W_main[, METHODS]); b <- unlist(W2[, METHODS])
  po <- mean(a == b); pe <- mean(a) * mean(b) + (1 - mean(a)) * (1 - mean(b))
  cat(sprintf("Participant x interface cells: raw agreement %.2f, positive agreement %.2f, kappa %.2f\n",
              po, 2 * sum(a & b) / (sum(a) + sum(b)), (po - pe) / (1 - pe)))
  cat("Per-code agreement: see results/study2/preference (section 3.9).\n")
} else {
  cat("Single coder: no data/preference/study2_qual_coding_coder2.csv yet.\n",
      "H2 is therefore PROVISIONAL and the joint claim cannot be called established.\n", sep = "")
}

# =============================================================================
hdr("G. SECONDARY — PRESENCE, PERCEIVED PICKS, 'MOST BALANCED' RANKING")
# =============================================================================
sub("G.1 Presence (1-7, measured each trial): Trajectory - ROF. No equivalence margin is defined.")
cP <- contrasts_of("Presence")
pres <- bind_rows(est_test(cP$traj, "Trajectory - ROF"),
                  est_test(cP$min_rof, "Minimap - ROF"), est_test(cP$path_rof, "Path - ROF"))
show(pres, 3)
cat("Presence is immersion, not intrusiveness: it gives context for H2, it does not replace it.\n")
wtab(pres, "t11_presence.csv")

sub("G.2 Secondary picks (descriptive; asked of a subset, after the ranking)")
picks <- bind_rows(lapply(c("best_sickness", "most_realistic"), function(col) {
    x <- pref[[col]]; x <- x[!is.na(x) & x %in% METHODS]; n <- length(x); r <- sum(x == "ROF")
    ci <- cp_ci(r, n)
    data.frame(question = col, n = n, ROF = r, Minimap = sum(x == "Minimap"),
               Path = sum(x == "Path"), ROF_share = r / n, ROF_lo95 = ci[1], ROF_hi95 = ci[2],
               p_vs_third = binom.test(r, n, 1/3)$p.value)
  }))
show(picks, 3)
cat("Reference share for ROF if picks were uniform = 1/3 (trajectory = 2/3). Exploratory,\n",
    "two-sided; perceived picks are never read as measured sickness or intrusiveness.\n", sep = "")
wtab(picks, "t12_picks.csv")

sub("G.3 'Most balanced' ranking. With 3 items, mean trajectory rank = (6 - ROF rank)/2,")
cat("so ROF's position carries all of the group information.\n\n")
rof_rank <- table(factor(pref$rank_ROF, levels = 1:3))
cat("ROF rank distribution (1 = most balanced):\n"); print(rof_rank)
n_last <- sum(pref$rank_ROF == 3); n_first <- sum(pref$rank_ROF == 1)
cat(sprintf("\nROF ranked last : %d/36 = %.2f, 95%% CI [%.2f, %.2f]; one-sided binomial vs 1/3 p = %s\n",
            n_last, n_last / 36, cp_ci(n_last, 36)[1], cp_ci(n_last, 36)[2],
            fmt_p(binom.test(n_last, 36, 1/3, alternative = "greater")$p.value)))
cat(sprintf("ROF ranked first: %d/36 = %.2f, 95%% CI [%.2f, %.2f]\n",
            n_first, n_first / 36, cp_ci(n_first, 36)[1], cp_ci(n_first, 36)[2]))
ord <- apply(pref[, c("rank_ROF", "rank_Minimap", "rank_Path")], 1, function(r)
  paste(METHODS[order(r)], collapse = " > "))
cat("\nAll six orderings:\n"); print(sort(table(ord), decreasing = TRUE))
wtab(as.data.frame(sort(table(ordering = ord), decreasing = TRUE)), "t13_orderings.csv")

sub("G.4 Grouped Plackett-Luce (supplementary): log-worth ROF = 0; Minimap, Path free or tied")
rk <- t(apply(pref[, c("rank_ROF", "rank_Minimap", "rank_Path")], 1, function(r) METHODS[order(r)]))
pl_nll <- function(lw) {         # lw: named log-worths for all three items
  -sum(apply(rk, 1, function(o) {
    w <- exp(lw[o]); log(w[1] / sum(w)) + log(w[2] / (w[2] + w[3]))
  }))
}
f_full <- optim(c(0, 0), function(p) pl_nll(c(ROF = 0, Minimap = p[1], Path = p[2])),
                method = "BFGS")
f_grp  <- optim(0, function(p) pl_nll(c(ROF = 0, Minimap = p, Path = p)),
                method = "BFGS", hessian = TRUE)
ll0 <- -pl_nll(c(ROF = 0, Minimap = 0, Path = 0))
lrt <- data.frame(
  test = c("Group effect (tied trajectory worth vs all equal)",
           "Grouping holds? (Minimap, Path free vs tied)"),
  chisq = c(2 * (-f_grp$value - ll0), 2 * (f_grp$value - f_full$value)), df = 1) %>%
  mutate(p = pchisq(chisq, df, lower.tail = FALSE))
show(lrt, 3)
se_g <- sqrt(1 / f_grp$hessian[1, 1]); th <- f_grp$par
pf <- function(t) c(ROF = 1 / (1 + 2 * exp(t)), each_traj = exp(t) / (1 + 2 * exp(t)))
cat(sprintf("\nWorth ratio trajectory/ROF = %.2f, Wald 95%% CI [%.2f, %.2f]\n",
            exp(th), exp(th - 1.96 * se_g), exp(th + 1.96 * se_g)))
cat(sprintf("Implied P(ranked first): ROF %.2f, each trajectory interface %.2f (equal-worth = .33)\n",
            pf(th)["ROF"], pf(th)["each_traj"]))
wf <- exp(c(0, f_full$par)); cat(sprintf("Full-model P(first) check: ROF %.2f, Minimap %.2f, Path %.2f\n",
                                       wf[1] / sum(wf), wf[2] / sum(wf), wf[3] / sum(wf)))
wtab(lrt, "t14_grouped_plackett_luce.csv")

# =============================================================================
hdr("H. STUDY 1 CROSS-STUDY CORROBORATION (Dynamic FOV as the non-trajectory comparison)")
# =============================================================================
cat("Study 1 measured SSQ after each trial only, so the outcome is post-trial TSC (not a\n",
    "change score); it is a second, independent sample with a different non-trajectory\n",
    "interface and a Baseline. It corroborates the category contrast; it is not a direct\n",
    "replication of Study 2.\n", sep = "")
s1c <- s1_pm %>% mutate(traj = (TSC_Minimap + `TSC_Overlay Path`) / 2 - `TSC_Dynamic FOV`,
                        min_dfov = TSC_Minimap - `TSC_Dynamic FOV`,
                        ovl_dfov = `TSC_Overlay Path` - `TSC_Dynamic FOV`)
sub("H.1 Non-inferiority vs Dynamic FOV (post-trial TSC, margin +5; +15 sensitivity)")
s1_ni <- bind_rows(ni_test(s1c$traj, MARGIN, "Trajectory - Dynamic FOV"),
                   ni_test(s1c$min_dfov, MARGIN, "Minimap - Dynamic FOV"),
                   ni_test(s1c$ovl_dfov, MARGIN, "Overlay Path - Dynamic FOV"),
                   ni_test(s1c$traj, MARGIN_SENS, "Trajectory - Dynamic FOV"))
s1_ni$p_NI_holm <- c(NA, p.adjust(s1_ni$p_NI[2:3], "holm"), NA)
show(s1_ni, 3)
dfov_red <- s1_red$diff[s1_red$comparison == "Baseline - Dynamic FOV (reduction)"]
cat(sprintf("\nThe +5 margin is %.0f%% of Dynamic FOV's own reduction vs Baseline (%.2f TSC).\n",
            100 * MARGIN / dfov_red, dfov_red))
sub("H.2 Every method vs Baseline (reductions; Holm over the three methods)")
show(s1_red %>% mutate(p_holm = p.adjust(p, "holm")) %>%
       bind_rows(est_test(s1_pm$TSC_Baseline - (s1_pm$TSC_Minimap + s1_pm$`TSC_Overlay Path`) / 2,
                          "Baseline - Trajectory (pooled)")), 3)
sub("H.3 Presence: Trajectory - Dynamic FOV")
s1_pres_c <- est_test((s1_pm$Presence_Minimap + s1_pm$`Presence_Overlay Path`) / 2 -
                        s1_pm$`Presence_Dynamic FOV`, "Trajectory - Dynamic FOV")
show(s1_pres_c, 3)
wtab(s1_ni, "t15_study1_noninferiority.csv")

# =============================================================================
hdr("I. JOINT DECISION")
# =============================================================================
h2_prov <- !file.exists(coder2)
dec <- data.frame(
  part = c("H1 measured sickness, non-inferior at +5 (Study 2)",
           "H2 fewer recorded intrusiveness-related complaints",
           "Joint claim (H1 AND H2)",
           "Study 1 corroboration: non-inferior to Dynamic FOV at +5"),
  result = c(sprintf("upper bound %.2f vs +5", h1$upper_1s95),
             sprintf("mean D %+.3f, exact one-sided p = %s", h2$mean_D, fmt_p(h2$p_exact_one)),
             "", sprintf("upper bound %.2f vs +5", s1_ni$upper_1s95[1])),
  decision = c(ifelse(h1$noninferior, "supported", "not supported"),
               paste0(ifelse(h2$p_exact_one < ALPHA, "supported", "not supported"),
                      ifelse(h2_prov, " (provisional: single coder)", "")),
               ifelse(h1$noninferior & h2$p_exact_one < ALPHA,
                      ifelse(h2_prov, "supported, pending second coder", "supported"),
                      ifelse(h1$noninferior,
                             "only H1: comparable sickness; intrusiveness difference not shown",
                             "not supported")),
               ifelse(s1_ni$noninferior[1], "supported", "not supported")))
show(dec)
wtab(dec, "t16_joint_decision.csv")

# =============================================================================
# Figures
# =============================================================================
fig1 <- bind_rows(
  bind_rows(h1, ind %>% select(-p_NI_holm)) %>% mutate(study = "Study 2 — vs ROF (change in TSC, pre to post)"),
  s1_ni[1:3, ] %>% select(-p_NI_holm) %>% mutate(study = "Study 1 — vs Dynamic FOV (post-trial TSC)")) %>%
  mutate(df = n - 1, lo90 = diff - qt(.95, df) * se, hi90 = upper_1s95,
         who = case_when(grepl("^Trajectory", comparison) ~ "Trajectory (pooled)",
                         grepl("^Minimap", comparison) ~ "Minimap",
                         TRUE ~ "Path"),
         label = base::sub(" - .*", "", comparison),
         label = ifelse(label == "Path", "Path Overlay", label),
         label = factor(label, levels = rev(c("Trajectory", "Minimap", "Path Overlay", "Overlay Path"))),
         study = factor(study, levels = unique(study)))
p1 <- ggplot(fig1, aes(y = label)) +
  annotate("rect", xmin = MARGIN, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "#f6e3e1") +
  geom_vline(xintercept = 0, colour = INK2, linewidth = .4) +
  geom_vline(xintercept = MARGIN, colour = "#b23a2f", linewidth = .5, linetype = "22") +
  geom_errorbar(aes(xmin = lo95, xmax = hi95, colour = who), width = 0,
                orientation = "y", linewidth = .5) +
  geom_errorbar(aes(xmin = lo90, xmax = hi90, colour = who), width = 0,
                orientation = "y", linewidth = 1.8) +
  geom_point(aes(x = diff, colour = who), size = 2.6) +
  scale_colour_manual(values = c("Trajectory (pooled)" = INK, Minimap = PAL_METHOD[["Minimap"]],
                                 Path = PAL_METHOD[["Path"]])) +
  facet_wrap(~ study, ncol = 1, scales = "free_y") +
  labs(title = "Sickness: trajectory-based interfaces vs the non-trajectory comparison",
       subtitle = "Difference in TSC points (positive = trajectory sicker). Thick bar = 90% CI,\nthin bar = 95% CI. Non-inferior when the thick bar ends left of the +5 margin.",
       x = "Trajectory minus comparison (TSC points)", y = NULL,
       caption = "Study 2 has no Baseline; Study 1 measured SSQ post-trial only. n = 36 per study.") +
  theme_pub() + theme(legend.position = "none")
save_fig(p1, "traj1_sickness_noninferiority.png", 7.5, 5.2)

fig2 <- bind_rows(
  per_code %>% transmute(Code, Method, n = complaints),
  tibble(Code = "Any of the four", Method = METHODS,
         n = sapply(METHODS, function(m) sum(W_main[[m]])))) %>%
  mutate(pct = 100 * n / 36,
         Code = factor(Code, levels = rev(c("Any of the four", INTR_CODES))),
         Method = factor(Method, levels = METHODS))
p2 <- ggplot(fig2, aes(x = pct, y = Code, colour = Method)) +
  geom_point(size = 3, position = position_dodge(width = .6, reverse = TRUE)) +
  geom_text(aes(label = n), position = position_dodge(width = .6, reverse = TRUE), hjust = -.9,
            size = 3, show.legend = FALSE) +
  scale_colour_manual(values = PAL_METHOD, labels = c("ROF", "Minimap", "Path Overlay")) +
  scale_x_continuous(limits = c(0, 60), labels = function(x) paste0(x, "%")) +
  labs(title = "Recorded intrusiveness-related complaints, by interface",
       subtitle = sprintf("Share of the 36 participants with at least one complaint. Composite: ROF %d, Minimap %d,\nPath %d; trajectory vs ROF exact one-sided p = %s.",
                          sum(W_main$ROF), sum(W_main$Minimap), sum(W_main$Path),
                          fmt_p(h2$p_exact_one)),
       x = "Participants with a complaint", y = NULL,
       caption = "Unsolicited interview comments, single coder. A missing complaint does not mean the interface was unobtrusive.") +
  theme_pub() + theme(panel.grid.major.y = element_line(colour = GRID, linewidth = .35),
                      panel.grid.major.x = element_blank())
save_fig(p2, "traj2_complaint_profile.png", 7.5, 4.6)

hdr("OUTPUT FILES")
cat("Tables:", paste(list.files(TAB), collapse = ", "), "\n")
cat("Plots :", paste(list.files(PLOT), collapse = ", "), "\n")
sink()
