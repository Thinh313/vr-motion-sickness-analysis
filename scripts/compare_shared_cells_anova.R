# =============================================================================
# Do the shared Method x Video cells differ between Study 1 and Study 2?
#
#   Mixed ANOVA on POST SSQ scores:
#     Study  (between: Study 1 / Study 2; no participant took part in both)
#     Method (within : Minimap / Path Overlay — the two methods both studies used)
#     Video  (within : Walking / Cycling / Driving)
#
#   Study 1 measured SSQ after each trial only, so POST is the only outcome the
#   two studies share. Conventions follow Study 1: afex type III, GG correction,
#   generalized eta-squared, Holm across the four SSQ DVs, Bonferroni post-hocs.
#
#   Output: results/comparison/shared_cells_anova.txt
#           results/comparison/shared_cells_anova.csv
#           results/comparison/shared_cells_study_contrasts.csv
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(afex); library(emmeans)
  library(car)
})
options(width = 110)
afex_options(type = 3, es = "ges", correction_aov = "GG", check_contrasts = TRUE,
             emmeans_model = "multivariate")

BASE <- getwd()
if (!dir.exists(file.path(BASE, "data/processed"))) BASE <- dirname(BASE)
OUT <- file.path(BASE, "results", "comparison")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

DVS <- c("TSC", "Nausea", "Oculomotor", "Disorientation")
fmt_p <- function(p) ifelse(p < .001, "<.001", sub("^0", "", sprintf("%.3f", p)))

# ----------------------------------------------------------------------- data
s1 <- read_csv(file.path(BASE, "data/processed/ssq_dataset.csv"),
               show_col_types = FALSE) |>
  filter(method_experienced %in% c("Minimap", "Overlay Path")) |>
  transmute(Study = "Study 1", Participant = paste0("S1_", full_name),
            Method = dplyr::recode(method_experienced, "Overlay Path" = "Path Overlay"),
            Video = video_experienced,
            TSC = ssq_tsc, Nausea = ssq_n, Oculomotor = ssq_o, Disorientation = ssq_d)
s2 <- read_csv(file.path(BASE, "data/processed/study2_trials.csv"),
               show_col_types = FALSE) |>
  filter(Method %in% c("Minimap", "Path")) |>
  transmute(Study = "Study 2", Participant = paste0("S2_", Participant),
            Method = dplyr::recode(Method, "Path" = "Path Overlay"), Video,
            TSC = Post_TSC, Nausea = Post_Nausea, Oculomotor = Post_Oculomotor,
            Disorientation = Post_Disorientation)
d <- bind_rows(s1, s2) |>
  mutate(Study = factor(Study), Participant = factor(Participant),
         Method = factor(Method, levels = c("Minimap", "Path Overlay")),
         Video = factor(Video, levels = c("Walking", "Cycling", "Driving")))

# every participant must contribute exactly one observation to each of the 6 cells
cells_per_p <- d |> count(Study, Participant, Method, Video)
stopifnot(all(cells_per_p$n == 1),
          all(table(d$Participant) == 6),
          nlevels(droplevels(d$Participant[d$Study == "Study 1"])) == 36,
          nlevels(droplevels(d$Participant[d$Study == "Study 2"])) == 36)

sink(file.path(OUT, "shared_cells_anova.txt"), split = TRUE)
cat("SHARED CELLS: STUDY 1 vs STUDY 2 — MIXED ANOVA ON POST SSQ\n")
cat("Study (between) x Method [Minimap, Path Overlay] (within) x Video (within)\n")
cat(sprintf("N = %d + %d participants, %d observations (6 per participant)\n",
            36, 36, nrow(d)))

# ------------------------------------------------------------ cell means
cat("\n==== 1. Cell means, POST TSC (n = 36 per cell) ====\n")
cm <- d |> group_by(Method, Video, Study) |>
  summarise(M = mean(TSC), SD = sd(TSC), .groups = "drop") |>
  pivot_wider(names_from = Study, values_from = c(M, SD)) |>
  mutate(ratio = `M_Study 1` / `M_Study 2`)
print(as.data.frame(cm |> mutate(across(where(is.numeric), ~round(., 2)))), row.names = FALSE)

# ------------------------------------------------------------ mixed ANOVA
cat("\n==== 2. Mixed ANOVA, all four SSQ outcomes (Holm across DVs per effect) ====\n")
fits <- setNames(lapply(DVS, function(dv)
  aov_ez("Participant", dv, data = d, between = "Study",
         within = c("Method", "Video"))), DVS)
tab <- bind_rows(lapply(DVS, function(dv) {
  a <- as.data.frame(anova(fits[[dv]], es = "ges", correction = "GG"))
  data.frame(DV = dv, Effect = rownames(a), df1 = a$`num Df`, df2 = a$`den Df`,
             F = a$F, p = a$`Pr(>F)`, ges = a$ges)
})) |> group_by(Effect) |> mutate(p_holm = p.adjust(p, "holm")) |> ungroup() |>
  arrange(factor(Effect, levels = unique(Effect)), factor(DV, levels = DVS))
print(as.data.frame(tab |>
  mutate(sig = case_when(p_holm < .001 ~ "***", p_holm < .01 ~ "**",
                         p_holm < .05 ~ "*", p_holm < .10 ~ ".", TRUE ~ "")) |>
  transmute(DV, Effect, df = sprintf("%.2f, %.2f", df1, df2), F = sprintf("%.2f", F),
            p = fmt_p(p), p_holm = fmt_p(p_holm), eta2G = sprintf("%.3f", ges), sig)),
  row.names = FALSE)
write_csv(tab, file.path(OUT, "shared_cells_anova.csv"))

cat("\nMauchly sphericity tests (TSC):\n")
print(round(summary(fits$TSC$Anova)$sphericity.tests, 4))

# ------------------------------------------------------------ post-hocs
cat("\n==== 3. Study 1 vs Study 2 within each Method x Video cell ====\n")
cat("(emmeans on the mixed-ANOVA model; Bonferroni across the 6 cells)\n")
contr <- bind_rows(lapply(DVS, function(dv) {
  pr <- summary(pairs(emmeans(fits[[dv]], ~ Study | Method * Video)),
                by = NULL, adjust = "bonferroni", infer = TRUE)
  sds <- d |> group_by(Method, Video) |>
    summarise(sp = sqrt((var(.data[[dv]][Study == "Study 1"]) +
                         var(.data[[dv]][Study == "Study 2"])) / 2), .groups = "drop")
  as.data.frame(pr) |>
    mutate(Method = dplyr::recode(as.character(Method), "Path.Overlay" = "Path Overlay"),
           Video = as.character(Video)) |>
    left_join(sds |> mutate(Method = as.character(Method), Video = as.character(Video)),
              by = c("Method", "Video")) |>
    transmute(DV = dv, Method, Video, diff = estimate, lower = lower.CL,
              upper = upper.CL, t = t.ratio, df, p_bonf = p.value, d = estimate / sp)
}))
for (dv in DVS) {
  cat("\n--- ", dv, " (Study 1 − Study 2) ---\n", sep = "")
  print(as.data.frame(contr |> filter(DV == dv) |> transmute(
    Method, Video, diff = round(diff, 2),
    CI95_bonf = sprintf("[%.2f, %.2f]", lower, upper),
    t = round(t, 2), df = round(df, 1), p_bonf = fmt_p(p_bonf), d = round(d, 2))),
    row.names = FALSE)
}
write_csv(contr, file.path(OUT, "shared_cells_study_contrasts.csv"))

cat("\n==== 4. How the Study difference varies (TSC EMMs) ====\n")
cat("\nStudy x Video:\n");  print(emmeans(fits$TSC, ~ Study | Video))
cat("\nStudy x Method:\n"); print(emmeans(fits$TSC, ~ Study | Method))
cat("\nVideo contrasts within each study (Bonferroni):\n")
print(summary(pairs(emmeans(fits$TSC, ~ Video | Study)), adjust = "bonferroni", infer = TRUE))
cat("\nMethod contrast within each study:\n")
print(summary(pairs(emmeans(fits$TSC, ~ Method | Study)), infer = TRUE))

# ------------------------------------------------------------ assumptions
cat("\n==== 5. Assumption checks and robustness (TSC) ====\n")
pm <- d |> group_by(Study, Participant) |> summarise(TSC = mean(TSC), .groups = "drop")
cat("\nLevene test (median-centred) on participant means, by Study:\n")
print(leveneTest(TSC ~ Study, data = pm))
cat("\nLevene test within each cell (Holm across 6):\n")
lev <- d |> group_by(Method, Video) |>
  group_modify(~ data.frame(F = leveneTest(TSC ~ Study, data = .x)$`F value`[1],
                            p = leveneTest(TSC ~ Study, data = .x)$`Pr(>F)`[1])) |>
  ungroup() |> mutate(p_holm = p.adjust(p, "holm"))
print(as.data.frame(lev |> mutate(F = round(F, 2), p = fmt_p(p), p_holm = fmt_p(p_holm))),
      row.names = FALSE)
cat("\nWith equal group sizes (36 vs 36) the mixed ANOVA is fairly robust to unequal\n")
cat("variances, but the checks below do not rely on that assumption.\n")

r <- residuals(fits$TSC$lm)
cat(sprintf("\nShapiro-Wilk on model residuals: W = %.3f, p = %s\n",
            shapiro.test(as.vector(r))$statistic, fmt_p(shapiro.test(as.vector(r))$p.value)))

cat("\nPer-cell Welch t-tests and Mann-Whitney tests (Holm across 6 cells):\n")
rob <- d |> group_by(Method, Video) |>
  group_modify(~ {
    a <- .x$TSC[.x$Study == "Study 1"]; b <- .x$TSC[.x$Study == "Study 2"]
    data.frame(welch_t = t.test(a, b)$statistic, welch_p = t.test(a, b)$p.value,
               mw_p = wilcox.test(a, b, exact = FALSE)$p.value)
  }) |> ungroup() |>
  mutate(welch_p_holm = p.adjust(welch_p, "holm"), mw_p_holm = p.adjust(mw_p, "holm"))
print(as.data.frame(rob |> transmute(Method, Video, welch_t = round(welch_t, 2),
  welch_p_holm = fmt_p(welch_p_holm), mw_p_holm = fmt_p(mw_p_holm))), row.names = FALSE)

cat("\nSensitivity: mixed ANOVA on log(TSC + 1) — tests PROPORTIONAL rather than\n")
cat("additive differences, and stabilises the variance gap between studies:\n")
d$logTSC <- log(d$TSC + 1)
print(aov_ez("Participant", "logTSC", data = d, between = "Study",
             within = c("Method", "Video")))
sink()
cat("\nWrote results/comparison/shared_cells_anova.{txt,csv} and shared_cells_study_contrasts.csv\n")
