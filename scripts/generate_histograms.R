# generate_histograms.R
# Generates residual histograms with normal curve overlay to support normality checks
# Companion to analysis_anova.R — uses identical data loading and model specification

library(tidyverse)
library(ggpubr)

# ── 1. Data Loading (mirrors analysis_anova.R) ──────────────────────────────

ssq_dvs <- c("ssq_tsc", "ssq_n", "ssq_o", "ssq_d")
ssq_labels <- c(
  ssq_tsc = "SSQ Total (TSC)",
  ssq_n   = "SSQ Nausea (N)",
  ssq_o   = "SSQ Oculomotor (O)",
  ssq_d   = "SSQ Disorientation (D)"
)

presence_items <- c(
  "presence_env_video", "focus_env_video", "control_attention",
  "presence_virtual_space", "unaware_real_env"
)

ssq_raw <- read_csv("data/processed/ssq_dataset.csv", show_col_types = FALSE)
presence_raw <- read_csv("data/processed/presence_dataset.csv", show_col_types = FALSE)

presence_raw <- presence_raw %>%
  mutate(mean_presence = rowMeans(select(., all_of(presence_items)), na.rm = FALSE))

ssq_raw <- ssq_raw %>%
  distinct(full_name, video_experienced, method_experienced, .keep_all = TRUE)
presence_raw <- presence_raw %>%
  distinct(full_name, video_experienced, method_experienced, .keep_all = TRUE)

ssq_data <- ssq_raw %>%
  select(full_name, video_experienced, method_experienced,
         ssq_tsc, ssq_n, ssq_o, ssq_d)

presence_data <- presence_raw %>%
  select(full_name, video_experienced, method_experienced, mean_presence)

merged_data <- inner_join(
  ssq_data, presence_data,
  by = c("full_name", "video_experienced", "method_experienced")
)

merged_data <- merged_data %>%
  mutate(
    subject = factor(full_name),
    method  = factor(method_experienced,
                     levels = c("Baseline", "Dynamic FOV", "Minimap", "Overlay Path")),
    video   = factor(video_experienced,
                     levels = c("Cycling", "Walking", "Driving"))
  )

if (!dir.exists("plots")) dir.create("plots")

# ── 2. Extract Model Residuals ──────────────────────────────────────────────

residual_list <- list()

for (dv in ssq_dvs) {
  formula <- as.formula(sprintf("%s ~ method * video + Error(subject / (method * video))", dv))
  aov_fit <- aov(formula, data = merged_data)
  residual_list[[dv]] <- residuals(aov_fit[["subject:method:video"]])
}

aov_pres <- aov(mean_presence ~ method * video + Error(subject / (method * video)),
                data = merged_data)
residual_list[["mean_presence"]] <- residuals(aov_pres[["subject:method:video"]])

# ── 3. Individual Residual Histograms ────────────────────────────────────────

all_dvs <- c(ssq_dvs, "mean_presence")
all_labels <- c(ssq_labels, mean_presence = "Presence")

for (dv in all_dvs) {
  resid_vals <- residual_list[[dv]]
  df <- data.frame(residuals = resid_vals)
  sw <- shapiro.test(resid_vals)

  # Skewness calculation (base R)
  n <- length(resid_vals)
  m <- mean(resid_vals)
  s <- sd(resid_vals)
  skew <- (n / ((n - 1) * (n - 2))) * sum(((resid_vals - m) / s)^3)
  kurt <- ((n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))) *
    sum(((resid_vals - m) / s)^4) -
    (3 * (n - 1)^2) / ((n - 2) * (n - 3))

  p <- ggplot(df, aes(x = residuals)) +
    geom_histogram(aes(y = after_stat(density)),
                   bins = 25, fill = "#4A90D9", color = "white", alpha = 0.7) +
    stat_function(fun = dnorm,
                  args = list(mean = mean(resid_vals), sd = sd(resid_vals)),
                  color = "#D94A4A", linewidth = 1, linetype = "solid") +
    labs(
      title    = sprintf("Residual Histogram: %s", all_labels[dv]),
      subtitle = sprintf("Shapiro-Wilk: W = %.4f, p = %.4f | Skewness = %.2f, Kurtosis = %.2f",
                         sw$statistic, sw$p.value, skew, kurt),
      x = "Model Residuals",
      y = "Density"
    ) +
    theme_bw(base_size = 12) +
    theme(
      plot.title    = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10, color = "grey40"),
      panel.grid.minor = element_blank()
    )

  fname <- sprintf("results/anova/plots/%s_residual_histogram.png", dv)
  ggsave(fname, p, width = 7, height = 5, dpi = 300)
  cat(sprintf("Saved: %s\n", fname))
}

# ── 4. Combined Panel (all 5 DVs) ───────────────────────────────────────────

plot_list <- list()

for (dv in all_dvs) {
  resid_vals <- residual_list[[dv]]
  df <- data.frame(residuals = resid_vals)
  sw <- shapiro.test(resid_vals)

  n <- length(resid_vals)
  m <- mean(resid_vals)
  s <- sd(resid_vals)
  skew <- (n / ((n - 1) * (n - 2))) * sum(((resid_vals - m) / s)^3)

  p <- ggplot(df, aes(x = residuals)) +
    geom_histogram(aes(y = after_stat(density)),
                   bins = 20, fill = "#4A90D9", color = "white", alpha = 0.7) +
    stat_function(fun = dnorm,
                  args = list(mean = m, sd = s),
                  color = "#D94A4A", linewidth = 0.8) +
    labs(
      title    = all_labels[dv],
      subtitle = sprintf("W=%.3f, p=%.4f, skew=%.2f", sw$statistic, sw$p.value, skew),
      x = "Residuals", y = "Density"
    ) +
    theme_bw(base_size = 10) +
    theme(
      plot.title    = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 8, color = "grey40"),
      panel.grid.minor = element_blank()
    )

  plot_list[[dv]] <- p
}

combined <- ggarrange(plotlist = plot_list, ncol = 3, nrow = 2)
combined <- annotate_figure(combined,
  top = text_grob("Residual Histograms — All DVs (with Normal Curve Overlay)",
                  face = "bold", size = 14))

ggsave("results/anova/plots/all_residual_histograms.png", combined, width = 14, height = 9, dpi = 300)
cat("Saved: plots/all_residual_histograms.png\n")

cat("\nDone. All histogram plots generated.\n")
