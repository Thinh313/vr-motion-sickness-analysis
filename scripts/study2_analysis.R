# =============================================================================
# Study 2 — PRE/POST SSQ analysis for three VIMS mitigation methods
#
#   Design : 36 participants x 3 Methods (ROF / Minimap / Path)
#            x 3 Videos (Walking / Cycling / Driving), fully within-subject.
#            SSQ administered immediately BEFORE and AFTER every trial.
#   Primary: 2 (Time) x 3 (Method) x 3 (Video) RM-ANOVA on each SSQ outcome;
#            the Time x Method interaction is the primary effect of interest.
#
#   Input  : data/processed/study2_trials.csv    (324 rows, from study2_prepare.py)
#            data/processed/study2_ssq_long.csv  (648 rows)
#   Output : results/study2/study2_results.txt   (full statistical output)
#            results/study2/tables/*.csv         (compact tables for LaTeX)
#            results/study2/plots/*.png          (figures)
#
# Conventions carried over from Study 1 (scripts/analysis_anova.R):
#   afex::aov_ez, type III SS, Greenhouse-Geisser correction, generalized
#   eta-squared, Holm correction across the four SSQ DVs, Bonferroni post-hocs.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(ggplot2)
  library(afex);  library(emmeans); library(lmerTest); library(patchwork)
})

options(width = 105, scipen = 6)
emm_options(lmerTest.limit = 2000, pbkrtest.limit = 2000)
afex::afex_options(check_contrasts = TRUE, type = 3, es = "ges",
                   correction_aov = "GG", emmeans_model = "multivariate")
set.seed(20260912)

# Run from the repository root (or from scripts/).
BASE <- getwd()
if (!dir.exists(file.path(BASE, "data/processed"))) BASE <- dirname(BASE)
stopifnot(dir.exists(file.path(BASE, "data/processed")))
RES   <- file.path(BASE, "results", "study2")
TAB   <- file.path(RES, "tables")
PLOT  <- file.path(RES, "plots")
dir.create(TAB,  recursive = TRUE, showWarnings = FALSE)
dir.create(PLOT, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------- palette/theme
PAL_METHOD <- c(ROF = "#2a78d6", Minimap = "#eb6834", Path = "#1baf7a")
PAL_TIME   <- c(Pre = "#7d7c78", Post = "#2a78d6")
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

# --------------------------------------------------------------------- data
trials <- read_csv(file.path(BASE, "data/processed/study2_trials.csv"),
                   show_col_types = FALSE) |>
  mutate(
    Participant = factor(Participant),
    Method      = factor(Method, levels = c("ROF", "Minimap", "Path")),
    Video       = factor(Video,  levels = c("Walking", "Cycling", "Driving")),
    MethodOrderGroup    = factor(MethodOrderGroup),
    MethodBlockPosition = factor(MethodBlockPosition),
    TrialF              = factor(TrialNumber)
  )

ssq_long <- read_csv(file.path(BASE, "data/processed/study2_ssq_long.csv"),
                     show_col_types = FALSE) |>
  mutate(
    Participant = factor(Participant),
    Time        = factor(Time,   levels = c("Pre", "Post")),
    Method      = factor(Method, levels = c("ROF", "Minimap", "Path")),
    Video       = factor(Video,  levels = c("Walking", "Cycling", "Driving"))
  )

DVS   <- c("TSC", "Nausea", "Oculomotor", "Disorientation")
DVLAB <- c(TSC = "Total Severity (TSC)", Nausea = "Nausea",
           Oculomotor = "Oculomotor", Disorientation = "Disorientation")

# ------------------------------------------------------------------- helpers
h  <- function(...) cat("\n\n", strrep("=", 78), "\n", sprintf(...), "\n",
                        strrep("=", 78), "\n", sep = "")
h2 <- function(...) cat("\n", sprintf(...), "\n", strrep("-", 78), "\n", sep = "")

fmt_p <- function(p) ifelse(is.na(p), "NA",
                     ifelse(p < .001, "<.001", sub("^0", "", sprintf("%.3f", p))))

ci95 <- function(x) {
  n <- sum(!is.na(x)); m <- mean(x, na.rm = TRUE); s <- sd(x, na.rm = TRUE)
  e <- qt(.975, n - 1) * s / sqrt(n)
  c(mean = m, sd = s, n = n, lo = m - e, hi = m + e)
}
# mean +/- 95% CI of a set of per-participant values
summ <- function(d, value, ...) {
  d |> group_by(...) |>
    summarise(n = dplyr::n(), mean = mean({{ value }}), sd = sd({{ value }}),
              se = sd / sqrt(n), lo = mean - qt(.975, n - 1) * se,
              hi = mean + qt(.975, n - 1) * se, .groups = "drop")
}

# tidy an afex anova table -> data.frame
tidy_afex <- function(fit, dv) {
  at <- as.data.frame(anova(fit, es = "ges", correction = "GG"))
  data.frame(DV = dv, Effect = rownames(at),
             df1 = at$`num Df`, df2 = at$`den Df`, F = at$F,
             p = at$`Pr(>F)`, ges = at$ges, row.names = NULL)
}
# Holm-adjust p across the four DVs, within each effect
holm_across_dvs <- function(df) {
  df |> group_by(Effect) |> mutate(p_holm = p.adjust(p, "holm")) |> ungroup() |>
    arrange(match(Effect, unique(df$Effect)), match(DV, DVS))
}
print_anova <- function(df) {
  out <- df |> mutate(
    stars = dplyr::case_when(p_holm < .001 ~ "***", p_holm < .01 ~ "**",
                             p_holm < .05 ~ "*", p_holm < .10 ~ ".",
                             TRUE ~ "")) |>
    transmute(
      DV, Effect,
      df = sprintf("%.2f, %.2f", df1, df2),
      F  = sprintf("%.2f", F),
      p  = fmt_p(p),
      p_holm = fmt_p(p_holm),
      eta2G = sprintf("%.3f", ges),
      sig = stars)
  print(as.data.frame(out), row.names = FALSE)
}

sink(file.path(RES, "study2_results.txt"), split = TRUE)
cat("STUDY 2 — PRE/POST SSQ ANALYSIS\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "|", R.version.string, "\n")
cat("N =", nlevels(trials$Participant), "participants,", nrow(trials), "trials,",
    nrow(ssq_long), "SSQ administrations\n")

# =============================================================================
h("1. DESCRIPTIVE STATISTICS")
# =============================================================================
cat("\nSSQ scored per Kennedy et al. (1993) Table 4; see study2_data_validation.md.\n")

h2("1.0  Overall PRE vs POST (participant means, n = 36)")
overall <- trials |>
  group_by(Participant) |>
  summarise(across(all_of(c(paste0("Pre_", DVS), paste0("Post_", DVS),
                            paste0("Delta_", DVS))), mean), .groups = "drop")
ov <- lapply(DVS, function(dv) {
  pre <- ci95(overall[[paste0("Pre_", dv)]]); post <- ci95(overall[[paste0("Post_", dv)]])
  del <- ci95(overall[[paste0("Delta_", dv)]])
  tt  <- t.test(overall[[paste0("Post_", dv)]], overall[[paste0("Pre_", dv)]], paired = TRUE)
  wt  <- suppressWarnings(wilcox.test(overall[[paste0("Post_", dv)]],
                                      overall[[paste0("Pre_", dv)]], paired = TRUE))
  dz  <- unname(del["mean"] / del["sd"])
  data.frame(DV = dv,
             Pre = sprintf("%.2f (%.2f)", pre["mean"], pre["sd"]),
             Post = sprintf("%.2f (%.2f)", post["mean"], post["sd"]),
             Delta = sprintf("%.2f (%.2f)", del["mean"], del["sd"]),
             Delta_CI = sprintf("[%.2f, %.2f]", del["lo"], del["hi"]),
             t = sprintf("%.2f", tt$statistic), df = tt$parameter,
             p_raw = tt$p.value, dz = sprintf("%.2f", dz),
             p_wilcox = fmt_p(wt$p.value),
             pct = sprintf("%+.1f%%", 100 * del["mean"] / pre["mean"]))
}) |> bind_rows()
ov <- ov |> mutate(p = fmt_p(p_raw), p_holm = fmt_p(p.adjust(p_raw, "holm"))) |>
  select(DV, Pre, Post, Delta, Delta_CI, t, df, p, p_holm, dz, p_wilcox, pct)
print(ov, row.names = FALSE)
write_csv(ov, file.path(TAB, "t1_overall_pre_post.csv"))
cat("\n(paired t-tests on participant means; Holm across the 4 DVs; dz = Cohen's d for paired data)\n")

h2("1.A  By Method, collapsed across Video (participant x method means, n = 36)")
byM <- trials |> group_by(Participant, Method) |>
  summarise(across(starts_with(c("Pre_", "Post_", "Delta_")), mean), .groups = "drop")
tabA <- lapply(DVS, function(dv) {
  summ(byM, .data[[paste0("Delta_", dv)]], Method) |>
    transmute(DV = dv, Method,
              Pre = sprintf("%.2f (%.2f)",
                     tapply(byM[[paste0("Pre_", dv)]], byM$Method, mean)[as.character(Method)],
                     tapply(byM[[paste0("Pre_", dv)]], byM$Method, sd)[as.character(Method)]),
              Post = sprintf("%.2f (%.2f)",
                     tapply(byM[[paste0("Post_", dv)]], byM$Method, mean)[as.character(Method)],
                     tapply(byM[[paste0("Post_", dv)]], byM$Method, sd)[as.character(Method)]),
              Delta = sprintf("%.2f (%.2f)", mean, sd),
              Delta_CI = sprintf("[%.2f, %.2f]", lo, hi))
}) |> bind_rows()
print(as.data.frame(tabA), row.names = FALSE)
write_csv(tabA, file.path(TAB, "t2_by_method.csv"))

h2("1.B  By Video, collapsed across Method (participant x video means, n = 36)")
byV <- trials |> group_by(Participant, Video) |>
  summarise(across(starts_with(c("Pre_", "Post_", "Delta_")), mean), .groups = "drop")
tabB <- lapply(DVS, function(dv) {
  summ(byV, .data[[paste0("Delta_", dv)]], Video) |>
    transmute(DV = dv, Video,
              Pre = sprintf("%.2f (%.2f)",
                     tapply(byV[[paste0("Pre_", dv)]], byV$Video, mean)[as.character(Video)],
                     tapply(byV[[paste0("Pre_", dv)]], byV$Video, sd)[as.character(Video)]),
              Post = sprintf("%.2f (%.2f)",
                     tapply(byV[[paste0("Post_", dv)]], byV$Video, mean)[as.character(Video)],
                     tapply(byV[[paste0("Post_", dv)]], byV$Video, sd)[as.character(Video)]),
              Delta = sprintf("%.2f (%.2f)", mean, sd),
              Delta_CI = sprintf("[%.2f, %.2f]", lo, hi))
}) |> bind_rows()
print(as.data.frame(tabB), row.names = FALSE)
write_csv(tabB, file.path(TAB, "t3_by_video.csv"))

h2("1.C  Every Method x Video cell (n = 36 per cell)")
tabC <- lapply(DVS, function(dv) {
  trials |> group_by(Method, Video) |>
    summarise(Pre = sprintf("%.2f (%.2f)", mean(.data[[paste0("Pre_", dv)]]),
                                            sd(.data[[paste0("Pre_", dv)]])),
              Post = sprintf("%.2f (%.2f)", mean(.data[[paste0("Post_", dv)]]),
                                             sd(.data[[paste0("Post_", dv)]])),
              dm = mean(.data[[paste0("Delta_", dv)]]),
              dsd = sd(.data[[paste0("Delta_", dv)]]), .groups = "drop") |>
    mutate(DV = dv, Delta = sprintf("%.2f (%.2f)", dm, dsd),
           Delta_CI = sprintf("[%.2f, %.2f]", dm - qt(.975, 35) * dsd / 6,
                                              dm + qt(.975, 35) * dsd / 6)) |>
    select(DV, Method, Video, Pre, Post, Delta, Delta_CI)
}) |> bind_rows()
print(as.data.frame(tabC), row.names = FALSE)
write_csv(tabC, file.path(TAB, "t4_method_x_video.csv"))

h2("1.D  Distribution of Delta_TSC (how many trials got worse / unchanged / better?)")
print(trials |> group_by(Method) |>
  summarise(n = dplyr::n(),
            worse = sum(Delta_TSC > 0), unchanged = sum(Delta_TSC == 0),
            better = sum(Delta_TSC < 0),
            pct_worse = sprintf("%.1f%%", 100 * mean(Delta_TSC > 0)),
            median = median(Delta_TSC),
            IQR = sprintf("[%.1f, %.1f]", quantile(Delta_TSC, .25),
                                          quantile(Delta_TSC, .75)),
            max = max(Delta_TSC)) |> as.data.frame(), row.names = FALSE)
cat("\nPRE_TSC == 0 in", sum(trials$Pre_TSC == 0), "of", nrow(trials),
    "trials; POST_TSC == 0 in", sum(trials$Post_TSC == 0), "trials.\n")

# =============================================================================
h("2. BASELINE / PRE-TRIAL STATE ANALYSIS")
# =============================================================================
cat("\nDid participants enter different trials with different symptom levels?\n")

h2("2.A  PRE scores: 3 (Method) x 3 (Video) RM-ANOVA")
pre_anova <- lapply(DVS, function(dv) {
  f <- aov_ez("Participant", paste0("Pre_", dv), data = trials,
              within = c("Method", "Video"))
  tidy_afex(f, dv)
}) |> bind_rows() |> holm_across_dvs()
print_anova(pre_anova)
write_csv(pre_anova, file.path(TAB, "t5_pre_anova.csv"))
cat("\nAny Method/Video effect here reflects pre-exposure state only — it cannot be\n",
    "caused by the method, which has not yet been shown. It indexes carryover.\n", sep = "")

h2("2.B  PRE_TSC by trial number (1-9): one-way RM-ANOVA + linear trend")
pre_trial <- aov_ez("Participant", "Pre_TSC", data = trials, within = "TrialF")
print(pre_trial)
cat("\nPer-trial means (n = 36 each):\n")
pt <- summ(trials, Pre_TSC, TrialNumber)
print(as.data.frame(pt |> mutate(across(c(mean, sd, se, lo, hi), ~round(., 2)))),
      row.names = FALSE)
write_csv(pt, file.path(TAB, "t6_pre_tsc_by_trial.csv"))

cat("\nLinear trend across trials (within-subject polynomial contrast):\n")
emm_trial <- emmeans(pre_trial, ~ TrialF)
print(contrast(emm_trial, "poly", max.degree = 2))
cat("\nPer-participant OLS slope of Pre_TSC on TrialNumber, tested against 0:\n")
slopes <- trials |> group_by(Participant) |>
  summarise(slope = coef(lm(Pre_TSC ~ TrialNumber))[2], .groups = "drop")
st <- t.test(slopes$slope)
cat(sprintf("  mean slope = %+.3f TSC points/trial, 95%% CI [%+.3f, %+.3f], t(%d) = %.2f, p = %s\n",
            mean(slopes$slope), st$conf.int[1], st$conf.int[2],
            st$parameter, st$statistic, fmt_p(st$p.value)))
cat(sprintf("  participants with a positive slope: %d / %d\n",
            sum(slopes$slope > 0), nrow(slopes)))

h2("2.C  PRE_TSC by method block position (1-3) and by method-order group")
print(aov_ez("Participant", "Pre_TSC", data = trials, within = "MethodBlockPosition"))
cat("\nMethod-order group is BETWEEN subjects (6 groups x 6 participants):\n")
og <- trials |> group_by(Participant, MethodOrderGroup) |>
  summarise(Pre_TSC = mean(Pre_TSC), Delta_TSC = mean(Delta_TSC), .groups = "drop")
print(summary(aov(Pre_TSC ~ MethodOrderGroup, data = og)))
cat("\nPer-group means:\n")
print(as.data.frame(summ(og, Pre_TSC, MethodOrderGroup) |>
        mutate(across(c(mean, sd, se, lo, hi), ~round(., 2)))), row.names = FALSE)

h2("2.D  RESIDUAL SICKNESS: does POST at trial t-1 predict PRE at trial t?")
lagd <- trials |> filter(!is.na(PrevPost_TSC))
cat("n =", nrow(lagd), "trial pairs (trials 2-9 of each participant)\n\n")
m_lag0 <- lmer(Pre_TSC ~ PrevPost_TSC + (1 | Participant), data = lagd)
cat("--- Pre_TSC ~ PrevPost_TSC + (1|Participant) ---\n"); print(summary(m_lag0)$coefficients)
m_lag1 <- lmer(Pre_TSC ~ PrevPost_TSC + TrialNumber + (1 | Participant), data = lagd)
cat("\n--- adding TrialNumber ---\n"); print(summary(m_lag1)$coefficients)
m_lag2 <- lmer(Pre_TSC ~ PrevPost_TSC + TrialNumber + RecoveryMinutes + (1 | Participant),
               data = lagd)
cat("\n--- adding inter-trial recovery time (min) ---\n")
print(summary(m_lag2)$coefficients)
cat("\nWithin-participant correlation of Pre_TSC(t) with Post_TSC(t-1):\n")
wc <- lagd |> group_by(Participant) |>
  filter(sd(Pre_TSC) > 0, sd(PrevPost_TSC) > 0) |>
  summarise(r = cor(Pre_TSC, PrevPost_TSC), .groups = "drop")
cat(sprintf("  mean within-participant r = %.3f (n = %d participants with variance), ",
            mean(wc$r), nrow(wc)))
wt <- t.test(atanh(pmin(pmax(wc$r, -.999), .999)))
cat(sprintf("Fisher-z t(%d) = %.2f, p = %s\n", wt$parameter, wt$statistic,
            fmt_p(wt$p.value)))
cat(sprintf("\n  Recovery time between trials: median %.1f min (IQR %.1f-%.1f)\n",
            median(lagd$RecoveryMinutes), quantile(lagd$RecoveryMinutes, .25),
            quantile(lagd$RecoveryMinutes, .75)))

# =============================================================================
h("3. PRIMARY ANALYSIS: 2 (Time) x 3 (Method) x 3 (Video) RM-ANOVA")
# =============================================================================
cat("\nGreenhouse-Geisser corrected; generalized eta-squared; Holm across the 4 DVs.\n")
cat("Time x Method is the PRIMARY Study-2 effect.\n")

fits <- setNames(lapply(DVS, function(dv)
  aov_ez("Participant", dv, data = ssq_long, within = c("Time", "Method", "Video"))
), DVS)

main_anova <- bind_rows(lapply(DVS, function(dv) tidy_afex(fits[[dv]], dv))) |>
  holm_across_dvs()
h2("3.A  Full ANOVA table (all 7 effects x 4 DVs)")
print_anova(main_anova)
write_csv(main_anova, file.path(TAB, "t7_primary_anova.csv"))

h2("3.B  Effects of interest, side by side")
for (eff in c("Time", "Time:Method", "Time:Video", "Time:Method:Video")) {
  cat("\n### ", eff, "\n", sep = "")
  print_anova(main_anova |> filter(Effect == eff))
}

h2("3.C  Mauchly sphericity tests")
for (dv in DVS) {
  cat("\n--- ", DVLAB[dv], " ---\n", sep = "")
  st <- summary(fits[[dv]]$Anova)$sphericity.tests
  if (length(st)) print(round(st, 4)) else cat("  (no test required)\n")
}

h2("3.D  Estimated marginal means, Time x Method (TSC)")
emm_tm <- emmeans(fits$TSC, ~ Time * Method)
print(emm_tm)
cat("\nSimple effect of Time within each Method (the pre->post rise):\n")
print(summary(contrast(emmeans(fits$TSC, ~ Time | Method), "revpairwise"),
              infer = TRUE, adjust = "bonferroni"))

# =============================================================================
h("4. CHANGE-SCORE (DELTA) ANALYSIS: 3 (Method) x 3 (Video) RM-ANOVA")
# =============================================================================
cat("\nCompanion/sensitivity analysis. For a complete balanced within-subject\n")
cat("design the Method effect here is algebraically the Time x Method interaction\n")
cat("of the primary model — the two are cross-checked numerically below.\n")

dfits <- setNames(lapply(DVS, function(dv)
  aov_ez("Participant", paste0("Delta_", dv), data = trials,
         within = c("Method", "Video"))), DVS)
delta_anova <- bind_rows(lapply(DVS, function(dv) tidy_afex(dfits[[dv]], dv))) |>
  holm_across_dvs()
h2("4.A  Delta-score ANOVA table")
print_anova(delta_anova)
write_csv(delta_anova, file.path(TAB, "t8_delta_anova.csv"))

h2("4.B  Cross-check against the primary model")
chk2 <- bind_rows(lapply(DVS, function(dv) {
  d <- delta_anova |> filter(DV == dv, Effect %in% c("Method", "Video", "Method:Video"))
  m <- main_anova  |> filter(DV == dv, Effect %in% c("Time:Method", "Time:Video",
                                                     "Time:Method:Video"))
  data.frame(DV = dv, Effect_delta = d$Effect, F_delta = round(d$F, 4),
             Effect_primary = m$Effect, F_primary = round(m$F, 4),
             match = abs(d$F - m$F) < 1e-6)
}))
print(chk2, row.names = FALSE)
cat("\nAll F values identical => the two analyses are the same test, as expected.\n")

h2("4.C  Delta_TSC: pairwise method comparisons (Bonferroni and Holm)")
emm_d <- emmeans(dfits$TSC, ~ Method)
print(emm_d)
cat("\nBonferroni:\n"); print(summary(pairs(emm_d, adjust = "bonferroni"), infer = TRUE))
cat("\nHolm:\n");       print(summary(pairs(emm_d, adjust = "holm"),       infer = TRUE))
cat("\nEffect sizes (Cohen's dz on participant-level method means):\n")
dw <- byM |> select(Participant, Method, Delta_TSC) |>
  pivot_wider(names_from = Method, values_from = Delta_TSC)
for (p in list(c("ROF", "Minimap"), c("ROF", "Path"), c("Minimap", "Path"))) {
  d <- dw[[p[1]]] - dw[[p[2]]]
  tt <- t.test(d)
  cat(sprintf("  %-8s vs %-8s : diff = %+6.2f, dz = %+.2f, t(%d) = %+.2f, p = %s\n",
              p[1], p[2], mean(d), mean(d) / sd(d), tt$parameter, tt$statistic,
              fmt_p(tt$p.value)))
}

h2("4.D  Delta pairwise comparisons for the other three subscales")
for (dv in c("Nausea", "Oculomotor", "Disorientation")) {
  cat("\n--- Delta_", dv, " ---\n", sep = "")
  print(summary(pairs(emmeans(dfits[[dv]], ~ Method), adjust = "bonferroni"),
                infer = TRUE))
}

h2("4.E  VIDEO post-hoc comparisons (the effect that DOES justify them)")
for (dv in DVS) {
  cat("\n--- Delta_", dv, " : Video contrasts (Bonferroni) ---\n", sep = "")
  print(summary(pairs(emmeans(dfits[[dv]], ~ Video), adjust = "bonferroni"),
                infer = TRUE))
}
cat("\nCohen's dz for the Video contrasts on Delta_TSC (participant means):\n")
vw <- byV |> select(Participant, Video, Delta_TSC) |>
  pivot_wider(names_from = Video, values_from = Delta_TSC)
for (p in list(c("Walking", "Cycling"), c("Walking", "Driving"),
               c("Cycling", "Driving"))) {
  d <- vw[[p[1]]] - vw[[p[2]]]; tt <- t.test(d)
  cat(sprintf("  %-8s vs %-8s : diff = %+6.2f, dz = %+.2f, t(%d) = %+.2f, p = %s\n",
              p[1], p[2], mean(d), mean(d) / sd(d), tt$parameter, tt$statistic,
              fmt_p(tt$p.value)))
}

h2("4.F  PRECISION OF THE NULL METHOD EFFECT: sensitivity power + equivalence")
cat("A non-significant Time x Method effect is only informative if the study\n")
cat("could have detected an effect worth caring about. Two complementary views:\n")

cat("\n(i) Smallest pairwise difference detectable with 80% power (n = 36, two-sided a = .05):\n")
mdd <- bind_rows(lapply(list(c("ROF", "Minimap"), c("ROF", "Path"),
                             c("Minimap", "Path")), function(p) {
  d <- dw[[p[1]]] - dw[[p[2]]]; se <- sd(d) / sqrt(length(d))
  data.frame(comparison = paste(p[1], "-", p[2]),
             observed = round(mean(d), 2),
             CI95 = sprintf("[%.2f, %.2f]", t.test(d)$conf.int[1],
                                            t.test(d)$conf.int[2]),
             SE = round(se, 2),
             MDD_TSC = round(se * (qt(.975, 35) + qt(.80, 35)), 2),
             MDD_dz = round((qt(.975, 35) + qt(.80, 35)) / sqrt(36), 3))
}))
print(mdd, row.names = FALSE)
cat("\n(ii) Omnibus Time x Method: minimum detectable generalized effect at 80% power,\n")
cat("    given the GG-corrected df actually obtained:\n")
for (dv in DVS) {
  r  <- main_anova |> filter(DV == dv, Effect == "Time:Method")
  f2 <- uniroot(function(f2) pf(qf(.95, r$df1, r$df2), r$df1, r$df2,
                                ncp = f2 * (r$df2 + r$df1 + 1)) - .20,
                c(1e-6, 5))$root
  cat(sprintf("  %-15s df = %.2f, %.2f -> detectable f2 = %.3f "
              , dv, r$df1, r$df2, f2))
  cat(sprintf("(partial eta2 = %.3f); observed eta2G = %.3f\n",
              f2 / (1 + f2), r$ges))
}

cat("\n(iii) Equivalence tests (TOST) on the pairwise Delta_TSC differences.\n")
cat("    Bounds: +/-5 TSC (a third of the smallest Study-1 mitigation effect) and\n")
cat("    +/-15 TSC (the size of the Study-1 method-vs-baseline reductions).\n\n")
tost <- bind_rows(lapply(c(5, 15), function(bnd) {
  bind_rows(lapply(list(c("ROF", "Minimap"), c("ROF", "Path"),
                        c("Minimap", "Path")), function(p) {
    d <- dw[[p[1]]] - dw[[p[2]]]; n <- length(d)
    se <- sd(d) / sqrt(n); m <- mean(d)
    p1 <- pt((m + bnd) / se, n - 1, lower.tail = FALSE)  # H0: diff <= -bnd
    p2 <- pt((m - bnd) / se, n - 1)                      # H0: diff >= +bnd
    data.frame(bound = sprintf("+/-%g", bnd),
               comparison = paste(p[1], "-", p[2]),
               diff = round(m, 2), p_TOST = fmt_p(max(p1, p2)),
               equivalent = ifelse(max(p1, p2) < .05, "YES", "no"))
  }))
}))
print(tost, row.names = FALSE)
write_csv(bind_rows(mdd |> mutate(kind = "MDD"),
                    tost |> mutate(kind = "TOST")),
          file.path(TAB, "t11_precision_equivalence.csv"))
cat("\nRead together: differences between methods larger than ~5-7 TSC points are\n")
cat("inconsistent with these data, so the null is a reasonably informative null\n")
cat("for large effects — but it does NOT establish exact equivalence.\n")

h2("4.G  Method x Video cell means of Delta_TSC, with simple effects by video")
print(as.data.frame(summ(trials, Delta_TSC, Method, Video) |>
        mutate(across(c(mean, sd, se, lo, hi), ~round(., 2)))), row.names = FALSE)
cat("\nMethod contrasts within each Video (Bonferroni within video):\n")
print(summary(pairs(emmeans(dfits$TSC, ~ Method | Video), adjust = "bonferroni"),
              infer = TRUE))

# =============================================================================
h("5. MIXED-EFFECTS SENSITIVITY ANALYSIS")
# =============================================================================
cat("\nDoes the Method conclusion survive adjustment for pre-trial symptom level,\n")
cat("trial progression, and within-participant clustering?\n")

h2("5.A  Random-effects structure selection (TSC)")
m_ri <- lmer(Post_TSC ~ Pre_TSC + Method * Video + TrialNumber + (1 | Participant),
             data = trials, REML = TRUE)
m_rs <- lmer(Post_TSC ~ Pre_TSC + Method * Video + TrialNumber +
               (1 + TrialNumber | Participant), data = trials, REML = TRUE,
             control = lmerControl(optimizer = "bobyqa"))
m_rm <- suppressWarnings(
  lmer(Post_TSC ~ Pre_TSC + Method * Video + TrialNumber + (1 + Method | Participant),
       data = trials, REML = TRUE, control = lmerControl(optimizer = "bobyqa")))
cat("Comparing random-intercept vs random-slope structures (REML, same fixed part):\n")
print(data.frame(
  model = c("(1|P)", "(1+TrialNumber|P)", "(1+Method|P)"),
  npar  = c(attr(logLik(m_ri), "df"), attr(logLik(m_rs), "df"), attr(logLik(m_rm), "df")),
  AIC   = round(c(AIC(m_ri), AIC(m_rs), AIC(m_rm)), 1),
  BIC   = round(c(BIC(m_ri), BIC(m_rs), BIC(m_rm)), 1),
  singular = c(isSingular(m_ri), isSingular(m_rs), isSingular(m_rm))),
  row.names = FALSE)
cat("\nLRT vs the random-intercept model:\n")
print(anova(m_ri, m_rs, refit = FALSE)); print(anova(m_ri, m_rm, refit = FALSE))
cat("\nRandom-intercept model retained unless a slope term is both non-singular\n")
cat("and preferred by AIC/BIC and the LRT.\n")

h2("5.B  Primary mixed model, all four outcomes")
mm_tab <- list()
for (dv in DVS) {
  cat("\n########## ", DVLAB[dv], " ##########\n", sep = "")
  f <- as.formula(sprintf(
    "Post_%s ~ Pre_%s + Method * Video + TrialNumber + (1 | Participant)", dv, dv))
  m <- lmer(f, data = trials, REML = TRUE)
  cat("\nType III ANOVA (Satterthwaite):\n")
  a <- anova(m, type = 3); print(a)
  cat("\nFixed effects:\n"); print(round(summary(m)$coefficients, 4))
  cat("\nICC (participant) = ",
      sprintf("%.3f", as.numeric(VarCorr(m)$Participant) /
                (as.numeric(VarCorr(m)$Participant) + sigma(m)^2)), "\n", sep = "")
  cat("\nAdjusted EMMs for Method (Bonferroni pairwise):\n")
  e <- emmeans(m, ~ Method)
  print(e); print(summary(pairs(e, adjust = "bonferroni"), infer = TRUE))
  mm_tab[[dv]] <- data.frame(DV = dv, Effect = rownames(a),
                             df1 = a$NumDF, df2 = round(a$DenDF, 1),
                             F = round(a$`F value`, 2), p = a$`Pr(>F)`)
}
mm_all <- bind_rows(mm_tab) |> group_by(Effect) |>
  mutate(p_holm = p.adjust(p, "holm")) |> ungroup()
h2("5.C  Mixed-model effects summary")
print(as.data.frame(mm_all |> mutate(p = fmt_p(p), p_holm = fmt_p(p_holm))),
      row.names = FALSE)
write_csv(mm_all, file.path(TAB, "t9_mixed_models.csv"))

h2("5.D  Adding order terms (diagnostic): does the Method effect move?")
m_ord <- lmer(Post_TSC ~ Pre_TSC + Method * Video + TrialNumber +
                MethodBlockPosition + (1 | Participant), data = trials)
print(anova(m_ord, type = 3))
cat("\nBetween-subject order group added:\n")
m_ord2 <- lmer(Post_TSC ~ Pre_TSC + Method * Video + TrialNumber +
                 MethodOrderGroup + (1 | Participant), data = trials)
print(anova(m_ord2, type = 3))
cat("\nDelta_TSC with order terms:\n")
print(anova(lmer(Delta_TSC ~ Method * Video + TrialNumber + MethodBlockPosition +
                   (1 | Participant), data = trials), type = 3))

# =============================================================================
h("6. ASSUMPTION CHECKS AND ROBUSTNESS")
# =============================================================================
h2("6.A  Distributional summary")
print(as.data.frame(bind_rows(lapply(DVS, function(dv) {
  x <- trials[[paste0("Delta_", dv)]]
  data.frame(DV = paste0("Delta_", dv), mean = round(mean(x), 2),
             sd = round(sd(x), 2), median = median(x),
             min = min(x), max = max(x),
             skew = round(mean((x - mean(x))^3) / sd(x)^3, 2),
             kurt = round(mean((x - mean(x))^4) / sd(x)^4 - 3, 2),
             pct_zero = sprintf("%.1f%%", 100 * mean(x == 0)))
}))), row.names = FALSE)

h2("6.B  Normality of MODEL RESIDUALS (the assumption that actually matters)")
resid_tab <- bind_rows(lapply(DVS, function(dv) {
  r_aov <- residuals(lm(as.formula(sprintf(
    "Delta_%s ~ Participant + Method * Video", dv)), data = trials))
  r_mm  <- residuals(lmer(as.formula(sprintf(
    "Post_%s ~ Pre_%s + Method * Video + TrialNumber + (1|Participant)", dv, dv)),
    data = trials))
  data.frame(DV = dv,
             shapiro_W_aov = round(shapiro.test(r_aov)$statistic, 3),
             p_aov = fmt_p(shapiro.test(r_aov)$p.value),
             shapiro_W_mm = round(shapiro.test(r_mm)$statistic, 3),
             p_mm = fmt_p(shapiro.test(r_mm)$p.value))
}))
print(as.data.frame(resid_tab), row.names = FALSE)
cat("\nRM-ANOVA on 36 subjects is robust to moderate non-normality; the rank-based\n")
cat("and bootstrap checks in 6.D-6.E exist precisely to bound this risk.\n")

h2("6.C  Extreme observations (3 x IQR on Delta_TSC) and sensitivity re-analysis")
q <- quantile(trials$Delta_TSC, c(.25, .75)); iqr <- diff(q)
lo3 <- q[1] - 3 * iqr; hi3 <- q[2] + 3 * iqr
trials$outlier3 <- trials$Delta_TSC < lo3 | trials$Delta_TSC > hi3
cat(sprintf("3xIQR fence on Delta_TSC: [%.1f, %.1f]; %d of %d trials outside (%.1f%%)\n",
            lo3, hi3, sum(trials$outlier3), nrow(trials),
            100 * mean(trials$outlier3)))
if (any(trials$outlier3)) {
  print(trials |> filter(outlier3) |>
          select(Participant, TrialNumber, Method, Video, Pre_TSC, Post_TSC,
                 Delta_TSC) |> as.data.frame(), row.names = FALSE)
  cat("\nOutliers are NOT deleted. Sensitivity: linear mixed model on Delta_TSC\n")
  cat("with and without them (unbalanced data rules out RM-ANOVA after removal).\n")
  cat("\n-- ALL data --\n")
  print(anova(lmer(Delta_TSC ~ Method * Video + (1 | Participant), data = trials),
              type = 3))
  cat("\n-- 3xIQR outliers excluded (n =", sum(!trials$outlier3), ") --\n")
  print(anova(lmer(Delta_TSC ~ Method * Video + (1 | Participant),
                   data = filter(trials, !outlier3)), type = 3))
  cat("\nMethod EMMs, outliers excluded:\n")
  print(emmeans(lmer(Delta_TSC ~ Method * Video + (1 | Participant),
                     data = filter(trials, !outlier3)), ~ Method))
}
cat("\nSensitivity: excluding P07 (late POST submission at trial 9):\n")
print(anova(lmer(Delta_TSC ~ Method * Video + (1 | Participant),
                 data = filter(trials, !(Participant == "7" & TrialNumber == 9))),
            type = 3))

h2("6.D  Non-parametric checks preserving the repeated-measures structure")
cat("Friedman test on Delta_TSC by Method (participant means over the 3 videos):\n")
fw <- byM |> select(Participant, Method, Delta_TSC) |>
  pivot_wider(names_from = Method, values_from = Delta_TSC)
fr <- friedman.test(as.matrix(fw[, c("ROF", "Minimap", "Path")]))
print(fr)
cat(sprintf("Kendall's W = %.3f\n", fr$statistic / (nrow(fw) * (3 - 1))))
cat("\nWilcoxon signed-rank, pairwise on Delta_TSC (Holm):\n")
pv <- c(
  "ROF-Minimap" = wilcox.test(fw$ROF, fw$Minimap, paired = TRUE, exact = FALSE)$p.value,
  "ROF-Path"    = wilcox.test(fw$ROF, fw$Path,    paired = TRUE, exact = FALSE)$p.value,
  "Minimap-Path"= wilcox.test(fw$Minimap, fw$Path, paired = TRUE, exact = FALSE)$p.value)
print(data.frame(comparison = names(pv), p = fmt_p(pv),
                 p_holm = fmt_p(p.adjust(pv, "holm"))), row.names = FALSE)
cat("\nFriedman on Delta_TSC by Video:\n")
fwv <- byV |> select(Participant, Video, Delta_TSC) |>
  pivot_wider(names_from = Video, values_from = Delta_TSC)
print(friedman.test(as.matrix(fwv[, c("Walking", "Cycling", "Driving")])))
cat("\nRank-based RM-ANOVA: Delta_TSC ranked within participant, then 3x3 RM-ANOVA\n")
tr_rank <- trials |> group_by(Participant) |> mutate(rDelta = rank(Delta_TSC)) |> ungroup()
print(aov_ez("Participant", "rDelta", data = tr_rank, within = c("Method", "Video")))

h2("6.E  Bootstrap CIs for the pairwise Method differences in Delta_TSC")
B <- 10000
bd <- sapply(1:B, function(i) {
  idx <- sample(nrow(fw), replace = TRUE)
  c(mean(fw$ROF[idx] - fw$Minimap[idx]), mean(fw$ROF[idx] - fw$Path[idx]),
    mean(fw$Minimap[idx] - fw$Path[idx]))
})
print(data.frame(
  comparison = c("ROF - Minimap", "ROF - Path", "Minimap - Path"),
  observed = round(c(mean(fw$ROF - fw$Minimap), mean(fw$ROF - fw$Path),
                     mean(fw$Minimap - fw$Path)), 2),
  boot_lo = round(apply(bd, 1, quantile, .025), 2),
  boot_hi = round(apply(bd, 1, quantile, .975), 2)), row.names = FALSE)
cat("(", B, " bootstrap resamples of participants)\n", sep = "")

# =============================================================================
h("7. SUPPLEMENTARY: PRESENCE (5-item, 7-point; POST only)")
# =============================================================================
cat("\nThe AFTER export contains the Study-1 Presence scale, contrary to the\n")
cat("handoff brief. Reported separately from the primary SSQ analysis.\n")
pres_items <- c("presence_being_there", "presence_focus", "presence_control",
                "presence_virtual_space", "presence_unaware_real")
alpha <- function(m) {
  k <- ncol(m); k / (k - 1) * (1 - sum(apply(m, 2, var)) / var(rowSums(m)))
}
cat(sprintf("\nCronbach's alpha (5 items, %d trials) = %.3f\n",
            nrow(trials), alpha(as.matrix(trials[, pres_items]))))
print(as.data.frame(summ(trials, Presence, Method) |>
        mutate(across(c(mean, sd, se, lo, hi), ~round(., 2)))), row.names = FALSE)
pres_fit <- aov_ez("Participant", "Presence", data = trials,
                   within = c("Method", "Video"))
print(pres_fit)
cat("\nMauchly:\n"); print(round(summary(pres_fit$Anova)$sphericity.tests, 4))
cat("\nPairwise (Bonferroni):\n")
print(summary(pairs(emmeans(pres_fit, ~ Method), adjust = "bonferroni"), infer = TRUE))
write_csv(summ(trials, Presence, Method), file.path(TAB, "t10_presence.csv"))
cat("\nPresence vs symptom increase (participant-level, n = 36):\n")
pp <- trials |> group_by(Participant) |>
  summarise(Presence = mean(Presence), Delta_TSC = mean(Delta_TSC), .groups = "drop")
print(cor.test(pp$Presence, pp$Delta_TSC))

# =============================================================================
h("8. FIGURES")
# =============================================================================

# ---- FIGURE 1: PRE vs POST TSC by Method -----------------------------------
f1d <- byM |> select(Participant, Method, Pre_TSC, Post_TSC) |>
  pivot_longer(c(Pre_TSC, Post_TSC), names_to = "Time", values_to = "TSC") |>
  mutate(Time = factor(sub("_TSC", "", Time), levels = c("Pre", "Post")))
f1m <- summ(f1d, TSC, Method, Time)
fig1 <- ggplot(f1d, aes(Time, TSC)) +
  geom_line(aes(group = Participant), colour = "#c9c8c3", linewidth = .35, alpha = .75) +
  geom_point(colour = "#c9c8c3", size = .8, alpha = .7) +
  geom_line(data = f1m, aes(y = mean, group = Method, colour = Method), linewidth = 1.1) +
  geom_errorbar(data = f1m, aes(y = mean, ymin = lo, ymax = hi, colour = Method),
                width = .07, linewidth = .8) +
  geom_point(data = f1m, aes(y = mean, colour = Method), size = 2.9) +
  geom_text(data = f1m |> mutate(hj = ifelse(Time == "Pre", 1.35, -.35)),
            aes(y = mean, label = sprintf("%.1f", mean), hjust = hj),
            colour = INK, size = 3.05, fontface = "bold", vjust = -.9) +
  geom_text(data = f1m |> filter(Time == "Post") |>
              left_join(f1m |> filter(Time == "Pre") |> select(Method, pre = mean),
                        by = "Method"),
            aes(x = 1.5, y = pmax(mean, pre) + 19,
                label = sprintf("Δ = %+.1f", mean - pre)),
            colour = INK2, size = 3.05) +
  facet_wrap(~ Method, nrow = 1) +
  scale_colour_manual(values = PAL_METHOD, guide = "none") +
  scale_x_discrete(expand = expansion(mult = .28)) +
  labs(title = "SSQ Total Severity rises from before to after the video under all three methods",
       subtitle = "Participant means (n = 36); grey lines are individual participants, coloured points the mean with 95% CI",
       x = NULL, y = "SSQ Total Severity (TSC)",
       caption = "Study 2. Kennedy et al. (1993) scoring. Δ is the mean pre→post change.") +
  theme_pub()
save_fig(fig1, "fig1_pre_post_tsc_by_method.png", 9, 4.3)

# ---- FIGURE 2: Delta TSC by Method x Video ---------------------------------
f2m <- summ(trials, Delta_TSC, Method, Video)
fig2 <- ggplot(f2m, aes(Video, mean, colour = Method, group = Method)) +
  geom_hline(yintercept = 0, colour = "#b9b8b3", linewidth = .5) +
  geom_point(data = trials, aes(y = Delta_TSC), size = .85, alpha = .28,
             position = position_jitterdodge(jitter.width = .22, dodge.width = .62)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .14, linewidth = .85,
                position = position_dodge(.62)) +
  geom_point(size = 3.1, position = position_dodge(.62)) +
  geom_text(aes(label = sprintf("%+.1f", mean)), position = position_dodge(.62),
            vjust = -1.5, size = 3, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = PAL_METHOD) +
  coord_cartesian(ylim = c(-50, 66)) +
  labs(title = "Pre→post increase in SSQ Total Severity, by method and video type",
       subtitle = "Mean Δ TSC with 95% CI (n = 36 per cell); faint points are individual trials",
       x = "Video type", y = "Δ TSC  (post − pre)",
       caption = "Positive = symptoms increased during viewing. No baseline (unmodified) condition exists in Study 2,\nso the three methods are compared only with each other.") +
  theme_pub()
save_fig(fig2, "fig2_delta_tsc_method_x_video.png", 8.2, 4.9)

# ---- FIGURE 3: Delta subscales by Method -----------------------------------
f3 <- bind_rows(lapply(c("Nausea", "Oculomotor", "Disorientation"), function(dv)
  summ(byM, .data[[paste0("Delta_", dv)]], Method) |> mutate(Subscale = dv))) |>
  mutate(Subscale = factor(Subscale, levels = c("Nausea", "Oculomotor",
                                                "Disorientation")))
f3raw <- byM |>
  select(Participant, Method, Delta_Nausea, Delta_Oculomotor, Delta_Disorientation) |>
  pivot_longer(-c(Participant, Method), names_to = "Subscale", values_to = "val") |>
  mutate(Subscale = factor(sub("Delta_", "", Subscale),
                           levels = c("Nausea", "Oculomotor", "Disorientation")))
fig3 <- ggplot(f3, aes(Method, mean, colour = Method)) +
  geom_hline(yintercept = 0, colour = "#b9b8b3", linewidth = .5) +
  geom_point(data = f3raw, aes(y = val), size = .9, alpha = .3,
             position = position_jitter(width = .17)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .13, linewidth = .85) +
  geom_point(size = 3.1) +
  geom_text(aes(label = sprintf("%+.1f", mean)), hjust = -0.4, size = 3,
            fontface = "bold") +
  facet_wrap(~ Subscale, nrow = 1) +
  scale_colour_manual(values = PAL_METHOD, guide = "none") +
  scale_x_discrete(expand = expansion(add = .62)) +
  labs(title = "Pre→post change in the three SSQ subscales",
       subtitle = "Participant means with 95% CI (n = 36); faint points are individual participants",
       x = NULL, y = "Δ subscale score  (post − pre)",
       caption = "Subscale weights differ (N ×9.54, O ×7.58, D ×13.92), so absolute sizes are not directly comparable across panels.") +
  theme_pub()
save_fig(fig3, "fig3_delta_subscales_by_method.png", 9, 4.4)

# ---- FIGURE 4: PRE TSC across trial number ---------------------------------
f4 <- summ(trials, Pre_TSC, TrialNumber)
f4p <- summ(trials, Post_TSC, TrialNumber)
fig4 <- ggplot(f4, aes(TrialNumber, mean)) +
  geom_ribbon(data = f4p, aes(ymin = lo, ymax = hi), fill = "#eb6834", alpha = .13) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#2a78d6", alpha = .16) +
  geom_line(aes(colour = "PRE (before the video)"), linewidth = 1.15) +
  geom_point(aes(colour = "PRE (before the video)"), size = 2.6) +
  geom_line(data = f4p, aes(colour = "POST (after the video)"), linewidth = 1.15,
            linetype = "31") +
  geom_point(data = f4p, aes(colour = "POST (after the video)"), size = 2.6,
             shape = 17) +
  geom_text(aes(label = sprintf("%.1f", mean),
                hjust = ifelse(TrialNumber == 1, -0.25, 0.5)), vjust = 2.3,
            size = 2.9, colour = "#2a78d6", fontface = "bold") +
  annotate("segment", x = 3.5, xend = 3.5, y = -Inf, yend = Inf,
           colour = "#d5d4cf", linewidth = .4, linetype = "22") +
  annotate("segment", x = 6.5, xend = 6.5, y = -Inf, yend = Inf,
           colour = "#d5d4cf", linewidth = .4, linetype = "22") +
  annotate("text", x = c(2, 5, 8), y = Inf, label = paste("method block", 1:3),
           vjust = 1.5, size = 2.9, colour = INK2) +
  scale_colour_manual(values = c("PRE (before the video)" = "#2a78d6",
                                 "POST (after the video)" = "#eb6834")) +
  scale_x_continuous(breaks = 1:9) +
  annotate("text", x = 1.08, y = f4$mean[1] + 5.5, hjust = 0, size = 2.9,
           colour = INK2, fontface = "italic",
           label = "trial 1 PRE is inflated by\npre-existing (non-VR) symptoms") +
  labs(title = "Pre-trial sickness climbs steadily from trial 2 to trial 9",
       subtitle = "Mean SSQ Total Severity at each of the nine trials, with 95% CI bands",
       x = "Trial number within session", y = "SSQ Total Severity (TSC)",
       caption = "Each participant ran three three-trial method blocks. PRE rising from trial 2 onward indicates residual/carryover VIMS,\nwhich counterbalancing distributes evenly across methods but does not eliminate. Trial 1 sits high because 8 of 36\nparticipants arrived with symptoms already present, before any VR exposure.") +
  theme_pub()
save_fig(fig4, "fig4_pre_tsc_across_trials.png", 8.6, 5)

# ---- FIGURE 5: paired PRE/POST for every Method x Video cell ----------------
f5 <- trials |> select(Participant, Method, Video, Pre_TSC, Post_TSC) |>
  pivot_longer(c(Pre_TSC, Post_TSC), names_to = "Time", values_to = "TSC") |>
  mutate(Time = factor(sub("_TSC", "", Time), levels = c("Pre", "Post")))
f5m <- summ(f5, TSC, Method, Video, Time)
fig5 <- ggplot(f5m, aes(Time, mean, colour = Method, group = Method)) +
  geom_line(data = f5, aes(y = TSC, group = interaction(Participant, Method)),
            colour = "#d5d4cf", linewidth = .3, alpha = .7) +
  geom_line(linewidth = 1.05) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .09, linewidth = .8) +
  geom_point(size = 2.7) +
  facet_grid(Video ~ Method) +
  scale_colour_manual(values = PAL_METHOD, guide = "none") +
  scale_x_discrete(expand = expansion(mult = .26)) +
  labs(title = "PRE → POST SSQ Total Severity in all nine Method × Video cells",
       subtitle = "Mean with 95% CI (n = 36 per cell); grey lines are individual participants",
       x = NULL, y = "SSQ Total Severity (TSC)", caption = "Study 2.") +
  theme_pub()
save_fig(fig5, "fig5_pre_post_all_cells.png", 8, 7.4)

# ---- FIGURE 6: residual diagnostics ----------------------------------------
qq <- bind_rows(lapply(DVS, function(dv) {
  r <- residuals(lm(as.formula(sprintf("Delta_%s ~ Participant + Method * Video", dv)),
                    data = trials))
  data.frame(DV = DVLAB[dv], theo = qqnorm(r, plot.it = FALSE)$x,
             samp = qqnorm(r, plot.it = FALSE)$y)
})) |> mutate(DV = factor(DV, levels = DVLAB))
fig6a <- ggplot(qq, aes(theo, samp)) +
  geom_abline(slope = 1, intercept = 0, colour = "#eb6834", linewidth = .6) +
  geom_point(size = .8, alpha = .45, colour = "#2a78d6") +
  facet_wrap(~ DV, nrow = 1, scales = "free_y") +
  labs(title = "Q–Q plots of RM-ANOVA residuals (Δ score models)",
       x = "Theoretical quantile", y = "Sample quantile") + theme_pub()
hs <- trials |> select(starts_with("Delta_")) |>
  pivot_longer(everything(), names_to = "DV", values_to = "val") |>
  mutate(DV = factor(DVLAB[sub("Delta_", "", DV)], levels = DVLAB))
fig6b <- ggplot(hs, aes(val)) +
  geom_histogram(bins = 34, fill = "#2a78d6", colour = "#ffffff", linewidth = .2) +
  geom_vline(xintercept = 0, colour = "#eb6834", linewidth = .6) +
  facet_wrap(~ DV, nrow = 1, scales = "free") +
  labs(title = "Distribution of the change scores",
       subtitle = "Zero-inflated and right-skewed, as is typical of SSQ data",
       x = "Δ score (post − pre)", y = "Trials") + theme_pub()
save_fig(fig6a / fig6b, "fig6_residual_diagnostics.png", 10, 7)

# ---- FIGURE 7: residual sickness scatter -----------------------------------
fig7 <- ggplot(lagd, aes(PrevPost_TSC, Pre_TSC)) +
  geom_abline(slope = 1, intercept = 0, colour = "#d5d4cf", linewidth = .5,
              linetype = "22") +
  geom_point(aes(colour = Method), size = 1.5, alpha = .6) +
  geom_smooth(method = "lm", formula = y ~ x, colour = INK, fill = "#c9c8c3",
              linewidth = .9, alpha = .35) +
  scale_colour_manual(values = PAL_METHOD) +
  labs(title = "Symptoms carry over: POST score of the previous trial predicts the next PRE score",
       subtitle = sprintf("%d consecutive trial pairs (trials 2–9); dashed line is complete carryover (no recovery)",
                          nrow(lagd)),
       x = "POST TSC at trial t − 1", y = "PRE TSC at trial t",
       caption = "Solid line = OLS fit with 95% CI; the mixed-model estimate that adjusts for participant is in section 2.D.") +
  theme_pub()
save_fig(fig7, "fig7_carryover_scatter.png", 7.6, 5)

# ---- FIGURE 8: Presence supplement -----------------------------------------
f8 <- summ(trials |> group_by(Participant, Method) |>
             summarise(Presence = mean(Presence), .groups = "drop"),
           Presence, Method)
fig8 <- ggplot(f8, aes(Method, mean, colour = Method)) +
  geom_point(data = trials |> group_by(Participant, Method) |>
               summarise(Presence = mean(Presence), .groups = "drop"),
             aes(y = Presence), size = 1, alpha = .32,
             position = position_jitter(width = .16)) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .12, linewidth = .85) +
  geom_point(size = 3.1) +
  geom_text(aes(label = sprintf("%.2f", mean)), vjust = -1.6, size = 3,
            fontface = "bold") +
  scale_colour_manual(values = PAL_METHOD, guide = "none") +
  scale_y_continuous(breaks = 1:7) +
  coord_cartesian(ylim = c(1, 7.25)) +
  labs(title = "Presence by method (supplementary)",
       subtitle = "Mean of the five 7-point items, participant means with 95% CI (n = 36)",
       x = NULL, y = "Presence (1–7)",
       caption = "Present in the Study-2 AFTER export although the analysis brief stated it was not collected.") +
  theme_pub()
save_fig(fig8, "fig8_presence_by_method.png", 6.4, 4.6)

# ---- FIGURE 9: the effect that IS significant — Delta TSC by video ----------
f9d <- byV |> select(Participant, Video, Delta_TSC)
f9m <- summ(f9d, Delta_TSC, Video)
fig9 <- ggplot(f9m, aes(Video, mean)) +
  geom_hline(yintercept = 0, colour = "#b9b8b3", linewidth = .5) +
  geom_line(data = f9d, aes(x = Video, y = Delta_TSC, group = Participant),
            colour = "#d5d4cf", linewidth = .3, alpha = .8, inherit.aes = FALSE) +
  geom_point(data = f9d, aes(x = Video, y = Delta_TSC), colour = "#c9c8c3",
             size = 1, alpha = .8, inherit.aes = FALSE) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .1, linewidth = .9,
                colour = "#2a78d6") +
  geom_point(size = 3.4, colour = "#2a78d6") +
  geom_text(aes(label = sprintf("%+.1f", mean)), hjust = -.42, size = 3.15,
            fontface = "bold", colour = INK) +
  labs(title = "Camera motion — not the method — drives how much sickness a trial adds",
       subtitle = "Mean Δ TSC with 95% CI, collapsed across the three methods (participant means, n = 36)",
       x = "Video type", y = "Δ TSC  (post − pre)",
       caption = "Walking induced roughly 2.4× the symptom increase of Driving (Holm-corrected p = .004 for the Time × Video interaction).\nGrey lines are individual participants.") +
  theme_pub()
save_fig(fig9, "fig9_delta_tsc_by_video.png", 7.6, 4.8)

cat("\nFigures written to results/study2/plots/:\n")
cat(paste0("  ", list.files(PLOT, pattern = "\\.png$"), collapse = "\n"), "\n")
cat("\nTables written to results/study2/tables/:\n")
cat(paste0("  ", list.files(TAB, pattern = "\\.csv$"), collapse = "\n"), "\n")

h("END OF OUTPUT")
sink()
cat("\nDone. See results/study2/study2_results.txt\n")
