#!/usr/bin/env Rscript
# =============================================================================
# 2-way Repeated Measures ANOVA: Method (4) x Video (3) on SSQ & Presence
# Bead: bd-20g (Kennedy 1993 weighted SSQ scoring)
# =============================================================================
# Design: 34 participants, fully within-subject
# IV1: method_experienced (Baseline, Dynamic FOV, Minimap, Overlay Path)
# IV2: video_experienced  (Cycling, Walking, Driving)
# DV (SSQ): ssq_tsc, ssq_n, ssq_o, ssq_d (Kennedy 1993 Table 4 weighted)
# DV (Presence): mean_presence (mean of 5 presence items, range 1-7)
# Post-hoc: Bonferroni correction (within DV), Holm across 4 SSQ DVs
# Effect size: Generalized eta-squared (eta_G_sq)
# =============================================================================

# --- 0. PACKAGE MANAGEMENT ---------------------------------------------------

required_packages <- c("tidyverse", "afex", "emmeans", "rstatix", "ggpubr")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing package: %s", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(tidyverse)
library(afex)
library(emmeans)
library(rstatix)
library(ggpubr)

# Save output to file AND console simultaneously
output_file <- "anova_results.txt"
con <- file(output_file, open = "wt")
sink(con, split = TRUE)         # split=TRUE -> print to both file and console
sink(con, type = "message")     # also capture warnings/messages

# Set afex to use type III SS and compute generalized eta-squared
afex_options(
  type        = 3,
  es_aov      = "ges",      # generalized eta-squared
  correction_aov = "GG",    # default Greenhouse-Geisser
  emmeans_model  = "multivariate"
)

cat("\n==============================================================\n")
cat("  2-WAY REPEATED MEASURES ANOVA: Method x Video\n")
cat("  SSQ (Kennedy 1993 subscales) & Presence (mean)\n")
cat("==============================================================\n\n")

# --- Kennedy 1993 SSQ Dependent Variables ------------------------------------
# These are the 4 SSQ DVs computed via weighted subscale scoring:
#   ssq_tsc : Total Severity Count  = (N_raw + O_raw + D_raw) * 3.74
#   ssq_n   : Nausea subscale       = N_raw * 9.54
#   ssq_o   : Oculomotor subscale   = O_raw * 7.58
#   ssq_d   : Disorientation subscale = D_raw * 13.92

ssq_dvs <- c("ssq_tsc", "ssq_n", "ssq_o", "ssq_d")
ssq_labels <- c(
  ssq_tsc = "SSQ Total (TSC)",
  ssq_n   = "SSQ Nausea (N)",
  ssq_o   = "SSQ Oculomotor (O)",
  ssq_d   = "SSQ Disorientation (D)"
)

# --- 1. DATA LOADING & PREPARATION ------------------------------------------

cat("--- 1. DATA LOADING & PREPARATION ---\n\n")

# Check files exist
if (!file.exists("ssq_dataset.csv")) stop("File not found: ssq_dataset.csv")
if (!file.exists("presence_dataset.csv")) stop("File not found: presence_dataset.csv")

ssq_raw <- read_csv("ssq_dataset.csv", show_col_types = FALSE)
presence_raw <- read_csv("presence_dataset.csv", show_col_types = FALSE)

# Presence items to compute mean
presence_items <- c(
  "presence_env_video",
  "focus_env_video",
  "control_attention",
  "presence_virtual_space",
  "unaware_real_env"
)

# Compute mean_presence
presence_raw <- presence_raw %>%
  mutate(mean_presence = rowMeans(select(., all_of(presence_items)), na.rm = FALSE))

# Deduplicate: keep first occurrence per (subject, video, method)
# Source data has a known duplicate: Nguyen Dinh Triet / Walking / Overlay Path
ssq_raw <- ssq_raw %>%
  distinct(full_name, video_experienced, method_experienced, .keep_all = TRUE)

presence_raw <- presence_raw %>%
  distinct(full_name, video_experienced, method_experienced, .keep_all = TRUE)

n_dedup_ssq <- nrow(read_csv("ssq_dataset.csv", show_col_types = FALSE)) - nrow(ssq_raw)
n_dedup_pres <- nrow(read_csv("presence_dataset.csv", show_col_types = FALSE)) - nrow(presence_raw)
if (n_dedup_ssq > 0 || n_dedup_pres > 0) {
  cat(sprintf("Deduplicated: %d SSQ rows, %d Presence rows removed\n", n_dedup_ssq, n_dedup_pres))
}

# Select key columns for merge
ssq_data <- ssq_raw %>%
  select(full_name, video_experienced, method_experienced,
         ssq_tsc, ssq_n, ssq_o, ssq_d,
         ssq_n_raw, ssq_o_raw, ssq_d_raw)

presence_data <- presence_raw %>%
  select(full_name, video_experienced, method_experienced, mean_presence)

# Merge by subject x video x method (1:1 after dedup)
merged_data <- inner_join(
  ssq_data, presence_data,
  by = c("full_name", "video_experienced", "method_experienced")
)

# Convert IVs and subject ID to factors with explicit levels
merged_data <- merged_data %>%
  mutate(
    subject     = factor(full_name),
    method      = factor(method_experienced,
                         levels = c("Baseline", "Dynamic FOV", "Minimap", "Overlay Path")),
    video       = factor(video_experienced,
                         levels = c("Cycling", "Walking", "Driving"))
  )

# --- 2. DATA VALIDATION -----------------------------------------------------

cat("--- 2. DATA VALIDATION ---\n\n")

n_obs      <- nrow(merged_data)
n_subjects <- n_distinct(merged_data$subject)
n_cells    <- n_distinct(interaction(merged_data$method, merged_data$video))

cat(sprintf("Total observations : %d (expected 408)\n", n_obs))
cat(sprintf("Unique subjects    : %d (expected 34)\n", n_subjects))
cat(sprintf("Unique cells       : %d (expected 12)\n", n_cells))

# Check completeness: each subject should have exactly 12 observations
obs_per_subj <- merged_data %>%
  count(subject) %>%
  filter(n != 12)

if (nrow(obs_per_subj) > 0) {
  cat("\nWARNING: Subjects with incomplete data (will be excluded from RM-ANOVA):\n")
  print(obs_per_subj)
  incomplete_subjects <- obs_per_subj$subject
  merged_data <- merged_data %>% filter(!subject %in% incomplete_subjects)
  merged_data$subject <- droplevels(merged_data$subject)
  cat(sprintf("Excluded %d subject(s). Remaining: %d subjects, %d observations\n",
              length(incomplete_subjects), n_distinct(merged_data$subject), nrow(merged_data)))
} else {
  cat("Completeness check : PASS (all subjects have 12 observations)\n")
}

# Check for missing values in DVs
all_dvs <- c(ssq_dvs, "mean_presence")
for (dv in all_dvs) {
  na_count <- sum(is.na(merged_data[[dv]]))
  cat(sprintf("Missing %-15s: %d\n", dv, na_count))
  if (na_count > 0) {
    stop(sprintf("Missing values detected in %s. Cannot proceed with RM-ANOVA.", dv))
  }
}

# Re-compute after possible exclusion
n_obs_final      <- nrow(merged_data)
n_subjects_final <- n_distinct(merged_data$subject)
stopifnot(n_obs_final == n_subjects_final * 12, n_subjects_final >= 30)

cat(sprintf("\nFinal dataset: %d subjects x 12 conditions = %d observations\n",
            n_subjects_final, n_obs_final))
cat("Data validation: ALL CHECKS PASSED\n")

# --- 3. DESCRIPTIVE STATISTICS -----------------------------------------------

cat("\n--- 3. DESCRIPTIVE STATISTICS ---\n\n")

# By Method x Video cell for each SSQ DV
for (dv in ssq_dvs) {
  desc <- merged_data %>%
    group_by(method, video) %>%
    summarise(
      n    = n(),
      mean = mean(.data[[dv]]),
      sd   = sd(.data[[dv]]),
      min  = min(.data[[dv]]),
      max  = max(.data[[dv]]),
      .groups = "drop"
    )
  cat(sprintf("%s by Method x Video:\n", ssq_labels[dv]))
  print(as.data.frame(desc), digits = 2, row.names = FALSE)
  cat("\n")
}

# Presence descriptives
desc_pres <- merged_data %>%
  group_by(method, video) %>%
  summarise(
    n    = n(),
    mean = mean(mean_presence),
    sd   = sd(mean_presence),
    min  = min(mean_presence),
    max  = max(mean_presence),
    .groups = "drop"
  )
cat("Presence (mean) by Method x Video:\n")
print(as.data.frame(desc_pres), digits = 2, row.names = FALSE)

# Marginal means by Method
for (dv in ssq_dvs) {
  cat(sprintf("\n%s marginal means by Method:\n", ssq_labels[dv]))
  merged_data %>%
    group_by(method) %>%
    summarise(mean = mean(.data[[dv]]), sd = sd(.data[[dv]]), .groups = "drop") %>%
    print(n = Inf)
}

cat("\nPresence marginal means by Method:\n")
merged_data %>%
  group_by(method) %>%
  summarise(mean = mean(mean_presence), sd = sd(mean_presence), .groups = "drop") %>%
  print(n = Inf)

# Marginal means by Video
for (dv in ssq_dvs) {
  cat(sprintf("\n%s marginal means by Video:\n", ssq_labels[dv]))
  merged_data %>%
    group_by(video) %>%
    summarise(mean = mean(.data[[dv]]), sd = sd(.data[[dv]]), .groups = "drop") %>%
    print(n = Inf)
}

cat("\nPresence marginal means by Video:\n")
merged_data %>%
  group_by(video) %>%
  summarise(mean = mean(mean_presence), sd = sd(mean_presence), .groups = "drop") %>%
  print(n = Inf)

# --- 4. ASSUMPTION CHECKS ---------------------------------------------------

cat("\n--- 4. ASSUMPTION CHECKS ---\n\n")

# 4a. Outlier detection (per cell) for each SSQ DV
cat("4a. Outlier detection (values beyond 1.5*IQR per cell):\n\n")

for (dv in ssq_dvs) {
  outliers <- merged_data %>%
    group_by(method, video) %>%
    identify_outliers(!!sym(dv))

  if (nrow(outliers) > 0) {
    cat(sprintf("%s outliers found: %d (extreme: %d)\n",
                ssq_labels[dv], nrow(outliers), sum(outliers$is.extreme)))
    print(outliers %>% select(subject, method, video, !!sym(dv), is.outlier, is.extreme))
  } else {
    cat(sprintf("%s outliers: none detected\n", ssq_labels[dv]))
  }
  cat("\n")
}

outliers_pres <- merged_data %>%
  group_by(method, video) %>%
  identify_outliers(mean_presence)

if (nrow(outliers_pres) > 0) {
  cat(sprintf("Presence outliers found: %d (extreme: %d)\n",
              nrow(outliers_pres), sum(outliers_pres$is.extreme)))
  print(outliers_pres %>% select(subject, method, video, mean_presence, is.outlier, is.extreme))
} else {
  cat("Presence outliers: none detected\n")
}

# 4b. Normality check (Shapiro-Wilk per cell)
cat("\n4b. Normality check (Shapiro-Wilk per cell, alpha = .05):\n\n")

for (dv in ssq_dvs) {
  shapiro_res <- merged_data %>%
    group_by(method, video) %>%
    shapiro_test(!!sym(dv)) %>%
    mutate(normal = ifelse(p > 0.05, "YES", "NO"))

  n_nonnormal <- sum(shapiro_res$p <= 0.05)
  cat(sprintf("%s Shapiro-Wilk results:\n", ssq_labels[dv]))
  print(as.data.frame(shapiro_res), row.names = FALSE)

  if (n_nonnormal > 0) {
    cat(sprintf("NOTE: %d/12 cells violate normality (p < .05). ANOVA robust with N=%d.\n\n",
                n_nonnormal, n_subjects_final))
  } else {
    cat("All cells normal.\n\n")
  }
}

shapiro_pres <- merged_data %>%
  group_by(method, video) %>%
  shapiro_test(mean_presence) %>%
  mutate(normal = ifelse(p > 0.05, "YES", "NO"))

cat("Presence Shapiro-Wilk results:\n")
print(as.data.frame(shapiro_pres), row.names = FALSE)

n_nonnormal_pres <- sum(shapiro_pres$p <= 0.05)
if (n_nonnormal_pres > 0) {
  cat(sprintf("NOTE: %d/12 Presence cells violate normality. ANOVA robust with N=%d.\n",
              n_nonnormal_pres, n_subjects_final))
}

# 4c. Q-Q Plots per cell
cat("\n4c. Q-Q Plots (saved to plots/):\n\n")

if (!dir.exists("plots")) dir.create("plots")

for (dv in ssq_dvs) {
  fname <- sprintf("plots/%s_qqplots.png", dv)
  cat(sprintf("Creating: %s\n", fname))
  p_qq <- ggqqplot(
    merged_data, x = dv,
    facet.by = c("method", "video"),
    title = sprintf("Q-Q Plots: %s by Method x Video", ssq_labels[dv])
  ) +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      strip.text = element_text(size = 8)
    )
  ggsave(fname, p_qq, width = 12, height = 8, dpi = 300)
}

cat("Creating: plots/presence_qqplots.png\n")
p_qq_pres <- ggqqplot(
  merged_data, x = "mean_presence",
  facet.by = c("method", "video"),
  title = "Q-Q Plots: Presence Score by Method x Video"
) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    strip.text = element_text(size = 8)
  )
ggsave("plots/presence_qqplots.png", p_qq_pres, width = 12, height = 8, dpi = 300)

cat("Q-Q plots saved.\n")

# 4d. Residual normality check
cat("\n4d. Residual normality check:\n\n")

for (dv in ssq_dvs) {
  formula <- as.formula(sprintf("%s ~ method * video + Error(subject / (method * video))", dv))
  aov_resid <- aov(formula, data = merged_data)
  resid_vals <- residuals(aov_resid[["subject:method:video"]])
  sw_test <- shapiro.test(resid_vals)
  cat(sprintf("%s residuals: W = %.4f, p = %.4f %s\n",
              ssq_labels[dv], sw_test$statistic, sw_test$p.value,
              ifelse(sw_test$p.value < 0.05, "(non-normal)", "(normal)")))
}

aov_pres_resid <- aov(mean_presence ~ method * video + Error(subject / (method * video)),
                      data = merged_data)
resid_pres <- residuals(aov_pres_resid[["subject:method:video"]])
sw_resid_pres <- shapiro.test(resid_pres)
cat(sprintf("Presence residuals: W = %.4f, p = %.4f %s\n",
            sw_resid_pres$statistic, sw_resid_pres$p.value,
            ifelse(sw_resid_pres$p.value < 0.05, "(non-normal)", "(normal)")))

cat("\nNOTE: RM-ANOVA is robust to non-normality with N >= 30 and equal group sizes\n")
cat("  (Field 2018; Tabachnick & Fidell 2019).\n")

# --- 5. RM-ANOVA: SSQ (4 Kennedy DVs) ----------------------------------------

cat("\n==============================================================\n")
cat("  5. RM-ANOVA: SSQ (Kennedy 1993 Subscales)\n")
cat("  DVs: TSC, Nausea, Oculomotor, Disorientation\n")
cat("==============================================================\n\n")

# Store all ANOVA results for effect map
ssq_aov_list <- list()
ssq_anova_tables <- list()

for (dv in ssq_dvs) {
  cat(sprintf("--- %s ---\n\n", ssq_labels[dv]))

  aov_result <- aov_ez(
    id      = "subject",
    dv      = dv,
    data    = merged_data,
    within  = c("method", "video"),
    type    = 3,
    anova_table = list(es = "ges", correction = "GG")
  )

  ssq_aov_list[[dv]] <- aov_result
  ssq_anova_tables[[dv]] <- anova(aov_result)

  cat(sprintf("ANOVA Table (%s) - Greenhouse-Geisser corrected:\n", ssq_labels[dv]))
  print(nice(aov_result))

  cat(sprintf("\nDetailed ANOVA Table (%s):\n", ssq_labels[dv]))
  print(anova(aov_result))
  cat("\n")
}

# --- 5b. EFFECT MAP TABLE (SSQ) -----------------------------------------------

cat("\n==============================================================\n")
cat("  5b. EFFECT MAP TABLE (SSQ Kennedy Subscales)\n")
cat("  Rows = Effects, Cols = TSC / N / O / D\n")
cat("  Holm correction applied across 4 DVs per effect family\n")
cat("==============================================================\n\n")

effects <- c("method", "video", "method:video")
effect_labels <- c("Method", "Video", "Method:Video")

# Build effect map data frame
effect_map <- data.frame(
  Effect = character(),
  DV = character(),
  F_value = numeric(),
  df1 = numeric(),
  df2 = numeric(),
  p_raw = numeric(),
  ges = numeric(),
  stringsAsFactors = FALSE
)

for (i in seq_along(effects)) {
  eff <- effects[i]
  for (dv in ssq_dvs) {
    tbl <- ssq_anova_tables[[dv]]
    row_data <- tbl[eff, ]
    effect_map <- rbind(effect_map, data.frame(
      Effect  = effect_labels[i],
      DV      = dv,
      F_value = row_data[["F"]],
      df1     = row_data[["num Df"]],
      df2     = row_data[["den Df"]],
      p_raw   = row_data[["Pr(>F)"]],
      ges     = row_data[["ges"]],
      stringsAsFactors = FALSE
    ))
  }
}

# Apply Holm correction within each effect family (across 4 DVs)
effect_map <- effect_map %>%
  group_by(Effect) %>%
  mutate(p_holm = p.adjust(p_raw, method = "holm")) %>%
  ungroup() %>%
  mutate(
    sig_raw  = ifelse(p_raw < 0.05, "*", ""),
    sig_holm = ifelse(p_holm < 0.05, "*", "")
  )

cat("Effect Map (with Holm correction across 4 SSQ DVs per effect):\n\n")
effect_map_print <- effect_map %>%
  mutate(
    cell = sprintf("F(%.1f,%.1f)=%.2f, p=%.4f%s, p_holm=%.4f%s, ges=%.4f",
                   df1, df2, F_value, p_raw, sig_raw, p_holm, sig_holm, ges)
  ) %>%
  select(Effect, DV, cell)

# Pivot to wide matrix: rows = effects, cols = DVs
effect_map_wide <- effect_map_print %>%
  tidyr::pivot_wider(names_from = DV, values_from = cell)

# Rename DV columns to readable labels
colnames(effect_map_wide) <- gsub("ssq_tsc", "TSC", colnames(effect_map_wide))
colnames(effect_map_wide) <- gsub("ssq_n",   "Nausea", colnames(effect_map_wide))
colnames(effect_map_wide) <- gsub("ssq_o",   "Oculomotor", colnames(effect_map_wide))
colnames(effect_map_wide) <- gsub("ssq_d",   "Disorientation", colnames(effect_map_wide))

print(as.data.frame(effect_map_wide), row.names = FALSE)

cat("\n* = p < .05\n")
cat("Holm correction controls family-wise error rate across 4 SSQ DVs per effect.\n")

# --- 6. RM-ANOVA: PRESENCE ---------------------------------------------------

cat("\n==============================================================\n")
cat("  6. RM-ANOVA: PRESENCE (mean_presence)\n")
cat("==============================================================\n\n")

aov_pres <- aov_ez(
  id      = "subject",
  dv      = "mean_presence",
  data    = merged_data,
  within  = c("method", "video"),
  type    = 3,
  anova_table = list(es = "ges", correction = "GG")
)

cat("ANOVA Table (Presence) - Greenhouse-Geisser corrected:\n")
print(nice(aov_pres))

cat("\nDetailed ANOVA Table (Presence):\n")
print(anova(aov_pres))

# --- 7. POST-HOC ANALYSIS (Conditional) --------------------------------------

cat("\n==============================================================\n")
cat("  7. POST-HOC ANALYSIS\n")
cat("  SSQ: Conditional on Holm-corrected significance\n")
cat("  Presence: Bonferroni correction\n")
cat("==============================================================\n\n")

# SSQ post-hoc: only for Holm-significant effect x DV combinations
sig_combos <- effect_map %>% filter(p_holm < 0.05)

if (nrow(sig_combos) == 0) {
  cat("No SSQ effects are significant after Holm correction.\n")
  cat("No post-hoc tests needed for SSQ.\n\n")
} else {
  # Identify DVs with significant interactions — skip main effects for these
  interaction_sig_dvs <- sig_combos %>%
    filter(Effect == "Method:Video") %>%
    pull(DV)

  cat(sprintf("Running post-hoc for %d significant effect x DV combinations:\n",
              nrow(sig_combos)))
  if (length(interaction_sig_dvs) > 0) {
    cat(sprintf("Note: DVs with significant interaction (%s) — main effects decomposed via simple effects only.\n",
                paste(ssq_labels[interaction_sig_dvs], collapse = ", ")))
  }
  cat("\n")

  for (r in seq_len(nrow(sig_combos))) {
    eff <- sig_combos$Effect[r]
    dv <- sig_combos$DV[r]
    p_h <- sig_combos$p_holm[r]
    aov_obj <- ssq_aov_list[[dv]]

    # Skip main-effect post-hoc when interaction is significant for same DV
    # (interaction subsumes main effects; use simple effects instead)
    if (eff %in% c("Method", "Video") && dv %in% interaction_sig_dvs) {
      cat(sprintf("--- SKIPPED: %s on %s (p_holm = %.4f) ---\n", eff, ssq_labels[dv], p_h))
      cat(sprintf("  Interaction is significant for %s; main effect subsumed by simple effects.\n\n",
                  ssq_labels[dv]))
      next
    }

    cat(sprintf("--- Post-hoc: %s on %s (p_holm = %.4f) ---\n\n", eff, ssq_labels[dv], p_h))

    if (eff == "Method:Video") {
      # Interaction: simple main effects
      cat("Interaction SIGNIFICANT: Running simple main effects\n\n")

      cat("Simple effects of Method at each Video level:\n")
      emm_method_at_video <- emmeans(aov_obj, ~ method | video)
      pairs_method_at_video <- pairs(emm_method_at_video, adjust = "bonferroni")
      print(summary(pairs_method_at_video))

      cat("\nSimple effects of Video at each Method level:\n")
      emm_video_at_method <- emmeans(aov_obj, ~ video | method)
      pairs_video_at_method <- pairs(emm_video_at_method, adjust = "bonferroni")
      print(summary(pairs_video_at_method))

    } else if (eff == "Method") {
      cat("Main effect of Method pairwise comparisons (Bonferroni):\n")
      emm_method <- emmeans(aov_obj, ~ method)
      pairs_method <- pairs(emm_method, adjust = "bonferroni")
      print(summary(pairs_method))
      cat("\nEstimated Marginal Means (Method):\n")
      print(summary(emm_method))

    } else if (eff == "Video") {
      cat("Main effect of Video pairwise comparisons (Bonferroni):\n")
      emm_video <- emmeans(aov_obj, ~ video)
      pairs_video <- pairs(emm_video, adjust = "bonferroni")
      print(summary(pairs_video))
      cat("\nEstimated Marginal Means (Video):\n")
      print(summary(emm_video))
    }
    cat("\n")
  }
}

# Presence post-hoc (single DV, no Holm needed)
cat("--- Presence Post-hoc ---\n\n")

pres_table <- anova(aov_pres)
p_method_pres <- pres_table["method", "Pr(>F)"]
p_video_pres <- pres_table["video", "Pr(>F)"]
p_int_pres <- pres_table["method:video", "Pr(>F)"]

cat(sprintf("Main effect Method      : p = %.4f %s\n",
            p_method_pres, ifelse(p_method_pres < 0.05, "*", "")))
cat(sprintf("Main effect Video       : p = %.4f %s\n",
            p_video_pres, ifelse(p_video_pres < 0.05, "*", "")))
cat(sprintf("Interaction Method:Video : p = %.4f %s\n\n",
            p_int_pres, ifelse(p_int_pres < 0.05, "*", "")))

if (p_int_pres < 0.05) {
  cat("Interaction SIGNIFICANT: Running simple main effects\n\n")

  emm_method_at_video <- emmeans(aov_pres, ~ method | video)
  pairs_method_at_video <- pairs(emm_method_at_video, adjust = "bonferroni")
  cat("Simple effects of Method at each Video level:\n")
  print(summary(pairs_method_at_video))

  emm_video_at_method <- emmeans(aov_pres, ~ video | method)
  pairs_video_at_method <- pairs(emm_video_at_method, adjust = "bonferroni")
  cat("\nSimple effects of Video at each Method level:\n")
  print(summary(pairs_video_at_method))

} else {
  if (p_method_pres < 0.05) {
    cat("Main effect of Method pairwise comparisons (Bonferroni):\n")
    emm_method <- emmeans(aov_pres, ~ method)
    pairs_method <- pairs(emm_method, adjust = "bonferroni")
    print(summary(pairs_method))
    cat("\nEstimated Marginal Means (Method):\n")
    print(summary(emm_method))
  } else {
    cat("Main effect of Method: NOT significant. No pairwise tests.\n")
  }

  cat("\n")

  if (p_video_pres < 0.05) {
    cat("Main effect of Video pairwise comparisons (Bonferroni):\n")
    emm_video <- emmeans(aov_pres, ~ video)
    pairs_video <- pairs(emm_video, adjust = "bonferroni")
    print(summary(pairs_video))
    cat("\nEstimated Marginal Means (Video):\n")
    print(summary(emm_video))
  } else {
    cat("Main effect of Video: NOT significant. No pairwise tests.\n")
  }
}

# --- 8. SENSITIVITY ANALYSIS (with/without extreme outlier) ------------------

cat("\n==============================================================\n")
cat("  8. SENSITIVITY ANALYSIS: Excluding Extreme Outliers\n")
cat("==============================================================\n\n")

# Identify extreme outliers across all SSQ DVs
all_extreme_subjects <- c()
for (dv in ssq_dvs) {
  ext <- merged_data %>%
    group_by(method, video) %>%
    identify_outliers(!!sym(dv)) %>%
    filter(is.extreme == TRUE)
  if (nrow(ext) > 0) {
    cat(sprintf("Extreme outliers in %s:\n", ssq_labels[dv]))
    print(ext %>% select(subject, method, video, !!sym(dv)) %>% as.data.frame())
    all_extreme_subjects <- c(all_extreme_subjects, as.character(ext$subject))
    cat("\n")
  }
}

all_extreme_subjects <- unique(all_extreme_subjects)

if (length(all_extreme_subjects) > 0) {
  cat(sprintf("Excluding subject(s): %s\n", paste(all_extreme_subjects, collapse = ", ")))

  data_no_outlier <- merged_data %>%
    filter(!subject %in% all_extreme_subjects) %>%
    mutate(subject = droplevels(subject))

  cat(sprintf("Remaining: %d subjects, %d observations\n\n",
              n_distinct(data_no_outlier$subject), nrow(data_no_outlier)))

  # Re-run all 4 SSQ ANOVAs
  cat("--- SSQ ANOVAs (outlier excluded) ---\n\n")

  sensitivity_results <- data.frame(
    DV = character(), Effect = character(),
    p_full_raw = numeric(), p_excl_raw = numeric(),
    stringsAsFactors = FALSE
  )

  for (dv in ssq_dvs) {
    aov_no <- aov_ez(
      id = "subject", dv = dv, data = data_no_outlier,
      within = c("method", "video"), type = 3,
      anova_table = list(es = "ges", correction = "GG")
    )
    cat(sprintf("ANOVA Table (%s, outlier excluded):\n", ssq_labels[dv]))
    print(nice(aov_no))
    cat("\n")

    # Collect raw p-values for each effect
    for (eff in effects) {
      p_full <- ssq_anova_tables[[dv]][eff, "Pr(>F)"]
      p_excl <- anova(aov_no)[eff, "Pr(>F)"]
      sensitivity_results <- rbind(sensitivity_results, data.frame(
        DV = dv, Effect = eff,
        p_full_raw = p_full, p_excl_raw = p_excl,
        stringsAsFactors = FALSE
      ))
    }
  }

  # Apply Holm correction within each effect family (matching primary analysis)
  sensitivity_results <- sensitivity_results %>%
    group_by(Effect) %>%
    mutate(
      p_full_holm = p.adjust(p_full_raw, method = "holm"),
      p_excl_holm = p.adjust(p_excl_raw, method = "holm"),
      same_sig = (p_full_holm < 0.05) == (p_excl_holm < 0.05)
    ) %>%
    ungroup()

  # Re-run Presence ANOVA
  cat("--- Presence ANOVA (outlier excluded) ---\n\n")
  aov_pres_no <- aov_ez(
    id = "subject", dv = "mean_presence", data = data_no_outlier,
    within = c("method", "video"), type = 3,
    anova_table = list(es = "ges", correction = "GG")
  )
  cat("ANOVA Table (Presence, outlier excluded):\n")
  print(nice(aov_pres_no))

  # Sensitivity comparison table
  cat("\n--- Sensitivity Comparison ---\n\n")
  print(as.data.frame(sensitivity_results), row.names = FALSE)

  all_robust <- all(sensitivity_results$same_sig)
  if (all_robust) {
    cat("\nCONCLUSION: Pattern of significance is IDENTICAL with and without\n")
    cat("  extreme outliers. Results are robust.\n")
  } else {
    cat("\nWARNING: Pattern of significance CHANGED for some effects.\n")
    cat("  Consider reporting both analyses in the paper.\n")
    changed <- sensitivity_results %>% filter(!same_sig)
    cat("Changed effects:\n")
    print(as.data.frame(changed), row.names = FALSE)
  }
} else {
  cat("No extreme outliers detected. Sensitivity analysis not needed.\n")
}

# --- 9. VISUALIZATIONS -------------------------------------------------------

cat("\n==============================================================\n")
cat("  9. GENERATING PLOTS\n")
cat("==============================================================\n\n")

if (!dir.exists("plots")) dir.create("plots")

# Color palette (colorblind-friendly)
method_colors <- c(
  "Baseline"     = "#E69F00",
  "Dynamic FOV"  = "#56B4E9",
  "Minimap"      = "#009E73",
  "Overlay Path" = "#CC79A7"
)

# SSQ Interaction Plots + Boxplots — combined 2x2 panels only
library(cowplot)

int_plots <- list()
box_plots <- list()

for (dv in ssq_dvs) {
  # --- Interaction plot (for combined panel) ---
  desc_plot <- merged_data %>%
    group_by(method, video) %>%
    summarise(
      mean = mean(.data[[dv]]),
      se   = sd(.data[[dv]]) / sqrt(n()),
      .groups = "drop"
    )

  p_int <- ggplot(desc_plot, aes(x = video, y = mean, color = method, group = method)) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = 0.15, linewidth = 0.6) +
    scale_color_manual(values = method_colors) +
    labs(
      title = ssq_labels[dv],
      x     = "Video Type",
      y     = ssq_labels[dv],
      color = "Method"
    ) +
    theme_pubr() +
    theme(
      plot.title      = element_text(face = "bold", size = 12),
      legend.position = "none"
    )

  int_plots[[dv]] <- p_int

  # --- Boxplot (for combined panel) ---
  p_box <- ggboxplot(
    merged_data,
    x        = "video",
    y        = dv,
    color    = "method",
    fill     = "method",
    palette  = unname(method_colors),
    add      = "jitter",
    add.params = list(size = 0.8, alpha = 0.4),
    xlab     = "Video Type",
    ylab     = ssq_labels[dv],
    title    = ssq_labels[dv],
    legend.title = "Method"
  ) +
    theme(
      plot.title      = element_text(face = "bold", size = 12),
      legend.position = "none"
    )

  box_plots[[dv]] <- p_box
}

# Combined 2x2: SSQ Interaction plots (cowplot)
cat("Creating: plots/ssq_combined_interaction.png\n")

# Extract shared legend from first interaction plot with legend enabled
p_legend_src <- int_plots[[1]] +
  scale_color_manual(values = method_colors, name = "Method") +
  theme(legend.position = "bottom")
shared_legend <- get_legend(p_legend_src)

grid_int <- plot_grid(
  int_plots[[1]], int_plots[[2]],
  int_plots[[3]], int_plots[[4]],
  ncol = 2, labels = "AUTO", label_size = 14
)

title_int <- ggdraw() +
  draw_label(
    "SSQ Subscales: Method x Video Interaction",
    fontface = "bold", size = 16, x = 0.5
  ) +
  draw_label(
    sprintf("Mean +/- SE (N = %d)", n_subjects_final),
    size = 12, colour = "grey40", x = 0.5, y = 0.2
  )

p_combined_int <- plot_grid(
  title_int, grid_int, shared_legend,
  ncol = 1, rel_heights = c(0.06, 1, 0.06)
)

ggsave("plots/ssq_combined_interaction.png", p_combined_int,
       width = 14, height = 10, dpi = 300)

# Combined 2x2: SSQ Boxplots (cowplot)
cat("Creating: plots/ssq_combined_boxplot.png\n")

# Extract shared legend from first boxplot with legend enabled
p_box_legend_src <- box_plots[[1]] +
  theme(legend.position = "bottom")
shared_box_legend <- get_legend(p_box_legend_src)

grid_box <- plot_grid(
  box_plots[[1]], box_plots[[2]],
  box_plots[[3]], box_plots[[4]],
  ncol = 2, labels = "AUTO", label_size = 14
)

title_box <- ggdraw() +
  draw_label(
    "SSQ Subscales: Distribution by Method x Video",
    fontface = "bold", size = 16, x = 0.5
  ) +
  draw_label(
    sprintf("N = %d", n_subjects_final),
    size = 12, colour = "grey40", x = 0.5, y = 0.2
  )

p_combined_box <- plot_grid(
  title_box, grid_box, shared_box_legend,
  ncol = 1, rel_heights = c(0.06, 1, 0.06)
)

ggsave("plots/ssq_combined_boxplot.png", p_combined_box,
       width = 14, height = 10, dpi = 300)

# ── SSQ Grouped Bar Chart (all subscales, significance vs Baseline) ──────────
cat("Creating: plots/ssq_grouped_bar.png\n")

# Reshape to long format for plotting
ssq_long <- merged_data %>%
  select(full_name, method, all_of(ssq_dvs)) %>%
  pivot_longer(
    cols      = all_of(ssq_dvs),
    names_to  = "subscale",
    values_to = "score"
  ) %>%
  mutate(
    subscale = factor(subscale,
      levels = c("ssq_n", "ssq_o", "ssq_d", "ssq_tsc"),
      labels = c("Nausea", "Oculomotor", "Disorientation", "Total")
    )
  )

# Summary: mean +/- SE per method x subscale (collapsed across videos)
bar_summary <- ssq_long %>%
  group_by(method, subscale) %>%
  summarise(
    mean = mean(score),
    se   = sd(score) / sqrt(n()),
    .groups = "drop"
  )

# Subscale colors (reference-style)
subscale_colors <- c(
  "Nausea"          = "#2CA02C",
  "Oculomotor"      = "#D62728",
  "Disorientation"  = "#FF7F0E",
  "Total"           = "#1F77B4"
)

# Compute paired significance vs Baseline per subscale (subject-averaged)
subj_means <- merged_data %>%
  group_by(full_name, method) %>%
  summarise(across(all_of(ssq_dvs), mean), .groups = "drop")

baseline_subj <- subj_means %>% filter(method == "Baseline") %>% arrange(full_name)
methods_other <- setdiff(levels(merged_data$method), "Baseline")

sig_results <- data.frame()
for (dv in ssq_dvs) {
  for (m in methods_other) {
    other_subj <- subj_means %>% filter(method == m) %>% arrange(full_name)
    tt <- t.test(baseline_subj[[dv]], other_subj[[dv]], paired = TRUE)
    sig_results <- rbind(sig_results, data.frame(
      subscale = dv, method = m, p_raw = tt$p.value, stringsAsFactors = FALSE
    ))
  }
}
sig_results$p_adj <- p.adjust(sig_results$p_raw, method = "holm")
sig_results$stars <- ifelse(sig_results$p_adj < 0.001, "***",
                    ifelse(sig_results$p_adj < 0.01, "**",
                    ifelse(sig_results$p_adj < 0.05, "*", "ns")))

cat("Significance vs Baseline (Holm-corrected):\n")
print(sig_results[, c("subscale", "method", "p_adj", "stars")])

# Build grouped bar chart
p_bar <- ggplot(bar_summary, aes(x = method, y = mean, fill = subscale)) +
  geom_col(position = position_dodge(0.8), width = 0.7,
           color = "black", linewidth = 0.3) +
  geom_errorbar(
    aes(ymin = pmax(mean - se, 0), ymax = mean + se),
    position = position_dodge(0.8), width = 0.2, linewidth = 0.5
  ) +
  scale_fill_manual(values = subscale_colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.20))) +
  labs(
    title = "Simulator Sickness Questionnaire Score",
    subtitle = sprintf(
      "Mean ± SE  (N = %d)  |  * p<.05   ** p<.01   *** p<.001 vs Baseline (Holm-corrected)",
      n_subjects_final
    ),
    x    = NULL,
    y    = "SSQ Score",
    fill = ""
  ) +
  theme_pubr() +
  theme(
    plot.title      = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle   = element_text(size = 10, color = "grey40", hjust = 0.5),
    legend.position = "bottom",
    axis.text.x     = element_text(size = 11, face = "bold"),
    plot.margin     = margin(10, 10, 10, 10)
  )

# Add significance brackets (one per method vs Baseline, stacked)
ymax_bar <- max(bar_summary$mean + bar_summary$se, na.rm = TRUE)
bracket_step <- ymax_bar * 0.07
tick_h        <- ymax_bar * 0.015
base_y        <- ymax_bar * 1.04

# Aggregate: use most significant subscale per method comparison
method_sig <- sig_results %>%
  group_by(method) %>%
  summarise(
    p_min  = min(p_adj),
    stars  = ifelse(min(p_adj) < 0.001, "***",
             ifelse(min(p_adj) < 0.01,  "**",
             ifelse(min(p_adj) < 0.05,  "*", "ns"))),
    .groups = "drop"
  )

# Method x-positions: Baseline=1, Dynamic FOV=2, Minimap=3, Overlay Path=4
segments_df <- data.frame()
labels_df   <- data.frame()

for (i in seq_along(methods_other)) {
  m <- methods_other[i]
  sig_row <- method_sig %>% filter(method == m)
  if (nrow(sig_row) == 0 || sig_row$stars == "ns") next

  x1 <- 1          # Baseline
  x2 <- i + 1      # other method
  y  <- base_y + bracket_step * (i - 1)

  # Horizontal line
  segments_df <- rbind(segments_df, data.frame(x = x1, xend = x2, y = y, yend = y))
  # Left tick
  segments_df <- rbind(segments_df, data.frame(x = x1, xend = x1, y = y, yend = y - tick_h))
  # Right tick
  segments_df <- rbind(segments_df, data.frame(x = x2, xend = x2, y = y, yend = y - tick_h))
  # Label
  labels_df <- rbind(labels_df, data.frame(
    x = (x1 + x2) / 2, y = y + tick_h * 0.5, label = sig_row$stars
  ))
}

if (nrow(segments_df) > 0) {
  p_bar <- p_bar +
    geom_segment(
      data = segments_df,
      aes(x = x, xend = xend, y = y, yend = yend),
      inherit.aes = FALSE, linewidth = 0.5
    ) +
    geom_text(
      data = labels_df,
      aes(x = x, y = y, label = label),
      inherit.aes = FALSE, size = 5, fontface = "bold"
    )
}

ggsave("plots/ssq_grouped_bar.png", p_bar, width = 12, height = 8, dpi = 300)

# Presence plots (unchanged)
cat("Creating: plots/presence_interaction.png\n")

desc_pres_plot <- merged_data %>%
  group_by(method, video) %>%
  summarise(
    mean = mean(mean_presence),
    se   = sd(mean_presence) / sqrt(n()),
    .groups = "drop"
  )

p_pres_int <- ggplot(desc_pres_plot, aes(x = video, y = mean, color = method, group = method)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = 0.15, linewidth = 0.6) +
  scale_color_manual(values = method_colors) +
  labs(
    title    = "Presence Score by Method and Video Type",
    subtitle = sprintf("Mean +/- SE (N = %d)", n_subjects_final),
    x        = "Video Type",
    y        = "Presence (1-7)",
    color    = "Method"
  ) +
  theme_pubr() +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    legend.position = "right"
  )

ggsave("plots/presence_interaction.png", p_pres_int, width = 8, height = 5, dpi = 300)

cat("Creating: plots/presence_boxplot.png\n")

p_pres_box <- ggboxplot(
  merged_data,
  x        = "video",
  y        = "mean_presence",
  color    = "method",
  fill     = "method",
  palette  = unname(method_colors),
  add      = "jitter",
  add.params = list(size = 0.8, alpha = 0.4),
  xlab     = "Video Type",
  ylab     = "Presence (1-7)",
  title    = "Presence Scores: Method x Video",
  legend.title = "Method"
) +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave("plots/presence_boxplot.png", p_pres_box, width = 9, height = 5, dpi = 300)

cat("\nAll plots saved to plots/ directory.\n")

# --- 10. SESSION INFO ---------------------------------------------------------

cat("\n==============================================================\n")
cat("  10. SESSION INFO (Reproducibility)\n")
cat("==============================================================\n\n")

cat(sprintf("Date: %s\n", Sys.time()))
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("Platform: %s\n", R.version$platform))
cat("\nPackage versions:\n")
for (pkg in required_packages) {
  cat(sprintf("  %-12s : %s\n", pkg, packageVersion(pkg)))
}

cat("\n==============================================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("==============================================================\n")

# Close sink connections
sink(type = "message")
sink()
close(con)
cat(sprintf("\nResults saved to: %s\n", output_file))
