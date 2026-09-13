# =============================================================================
# Absolute post-exposure SSQ Total Severity: Study 1 vs Study 2
#
#   Study 1: data/processed/ssq_dataset.csv   (432 rows; SSQ post-trial only)
#   Study 2: data/processed/study2_trials.csv (324 rows; Post_TSC used here)
#
#   Both are scored with Kennedy et al. (1993) Table 4 weights, and no
#   participant took part in both studies (checked by normalised name), so the
#   between-study comparison uses independent-samples tests on participant means.
#
#   Output: results/comparison/post_tsc_study1_vs_study2.txt
#           results/comparison/post_tsc_cells.csv
#           results/comparison/plots/*.png
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(ggplot2); library(patchwork)
})
options(width = 105)
set.seed(20260913)

BASE <- getwd()
if (!dir.exists(file.path(BASE, "data/processed"))) BASE <- dirname(BASE)
OUT  <- file.path(BASE, "results", "comparison")
PLOT <- file.path(OUT, "plots")
dir.create(PLOT, recursive = TRUE, showWarnings = FALSE)

PAL_STUDY <- c("Study 1" = "#2a78d6", "Study 2" = "#eb6834")
INK <- "#0b0b0b"; INK2 <- "#52514e"; GRID <- "#e6e5e1"
METHODS <- c("Baseline", "Dynamic FOV", "ROF", "Minimap", "Path Overlay")
SHARED  <- c("Minimap", "Path Overlay")

theme_pub <- function(base = 11) {
  theme_minimal(base_size = base) +
    theme(plot.title = element_text(face = "bold", size = base + 2, colour = INK),
          plot.subtitle = element_text(size = base - 1, colour = INK2,
                                       margin = margin(b = 8)),
          plot.caption = element_text(size = base - 2.5, colour = INK2, hjust = 0),
          axis.title = element_text(size = base - 1, colour = INK2),
          axis.text = element_text(size = base - 1.5, colour = INK2),
          strip.text = element_text(face = "bold", colour = INK),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_line(colour = GRID, linewidth = .35),
          panel.grid.major.x = element_blank(),
          legend.position = "top", legend.title = element_blank(),
          plot.title.position = "plot", plot.caption.position = "plot")
}

# ----------------------------------------------------------------------- data
s1 <- read_csv(file.path(BASE, "data/processed/ssq_dataset.csv"),
               show_col_types = FALSE) |>
  transmute(Study = "Study 1", Participant = paste0("S1_", full_name),
            Method = recode(method_experienced, "Overlay Path" = "Path Overlay"),
            Video = video_experienced, Post_TSC = ssq_tsc)
s2 <- read_csv(file.path(BASE, "data/processed/study2_trials.csv"),
               show_col_types = FALSE) |>
  transmute(Study = "Study 2", Participant = paste0("S2_", Participant),
            Method = recode(Method, "Path" = "Path Overlay"),
            Video, Post_TSC)
d <- bind_rows(s1, s2) |>
  mutate(Study = factor(Study, levels = names(PAL_STUDY)),
         Method = factor(Method, levels = METHODS),
         Video = factor(Video, levels = c("Walking", "Cycling", "Driving")))
stopifnot(nrow(d) == 432 + 324, !anyNA(d$Method), !anyNA(d$Video))

summ <- function(x, ...) x |> group_by(...) |>
  summarise(n = dplyr::n(), mean = mean(Post_TSC), sd = sd(Post_TSC),
            median = median(Post_TSC),
            lo = mean - qt(.975, n - 1) * sd / sqrt(n),
            hi = mean + qt(.975, n - 1) * sd / sqrt(n), .groups = "drop")

# participant means: every condition, and the two methods both studies share
pm_all    <- d |> group_by(Study, Participant) |>
  summarise(Post_TSC = mean(Post_TSC), .groups = "drop") |> mutate(Set = "All conditions")
pm_shared <- d |> filter(Method %in% SHARED) |> group_by(Study, Participant) |>
  summarise(Post_TSC = mean(Post_TSC), .groups = "drop") |>
  mutate(Set = "Shared methods only\n(Minimap + Path Overlay)")
pm <- bind_rows(pm_all, pm_shared) |> mutate(Set = factor(Set, levels = unique(Set)))

compare <- function(x, label) {
  a <- x$Post_TSC[x$Study == "Study 1"]; b <- x$Post_TSC[x$Study == "Study 2"]
  wt <- t.test(a, b); mw <- wilcox.test(a, b, exact = FALSE)
  sp <- sqrt(((length(a) - 1) * var(a) + (length(b) - 1) * var(b)) /
               (length(a) + length(b) - 2))
  boot <- replicate(10000, mean(sample(a, replace = TRUE)) / mean(sample(b, replace = TRUE)))
  cat(sprintf("\n--- %s (participant means, n = %d vs %d) ---\n", label, length(a), length(b)))
  cat(sprintf("  Study 1: M = %.2f (SD %.2f), Mdn = %.2f\n", mean(a), sd(a), median(a)))
  cat(sprintf("  Study 2: M = %.2f (SD %.2f), Mdn = %.2f\n", mean(b), sd(b), median(b)))
  cat(sprintf("  Difference = %.2f, 95%% CI [%.2f, %.2f]; Welch t(%.1f) = %.2f, p = %.2g\n",
              mean(a) - mean(b), wt$conf.int[1], wt$conf.int[2], wt$parameter,
              wt$statistic, wt$p.value))
  cat(sprintf("  Mann-Whitney W = %.0f, p = %.2g; Cohen's d = %.2f\n",
              mw$statistic, mw$p.value, (mean(a) - mean(b)) / sp))
  cat(sprintf("  Ratio of means S1/S2 = %.2f, bootstrap 95%% CI [%.2f, %.2f]\n",
              mean(a) / mean(b), quantile(boot, .025), quantile(boot, .975)))
}

sink(file.path(OUT, "post_tsc_study1_vs_study2.txt"), split = TRUE)
cat("ABSOLUTE POST-EXPOSURE SSQ TSC — STUDY 1 vs STUDY 2\n")
cat("Both studies scored with Kennedy (1993) Table 4 weights; no participant overlap.\n")
cat("Study 1 measured SSQ after each trial only; Study 2 values are the POST scores.\n")

cat("\n==== Between-study tests ====\n")
compare(pm_all, "All conditions")
compare(pm_shared, "Shared methods only (Minimap + Path Overlay)")

cat("\n==== Trial-level summaries by study ====\n")
print(as.data.frame(summ(d, Study) |> mutate(across(where(is.numeric), ~round(., 2)))),
      row.names = FALSE)

cells <- summ(d, Study, Method, Video)
cat("\n==== Method x Video cell means (n = 36 per cell) ====\n")
print(as.data.frame(cells |> mutate(across(where(is.numeric), ~round(., 2)))),
      row.names = FALSE)
cat(sprintf("\nCell-mean range: Study 1 %.1f-%.1f; Study 2 %.1f-%.1f\n",
            min(cells$mean[cells$Study == "Study 1"]), max(cells$mean[cells$Study == "Study 1"]),
            min(cells$mean[cells$Study == "Study 2"]), max(cells$mean[cells$Study == "Study 2"])))

cat("\n==== Shared methods: Study 1 / Study 2 ratio of cell means ====\n")
ratio <- cells |> filter(Method %in% SHARED) |>
  select(Study, Method, Video, mean) |>
  pivot_wider(names_from = Study, values_from = mean) |>
  mutate(ratio = `Study 1` / `Study 2`)
print(as.data.frame(ratio |> mutate(across(where(is.numeric), ~round(., 2)))),
      row.names = FALSE)

cat("\n==== Share of trials with POST TSC = 0 ====\n")
print(as.data.frame(d |> group_by(Study) |>
  summarise(zero = sum(Post_TSC == 0), n = dplyr::n(),
            pct = sprintf("%.1f%%", 100 * mean(Post_TSC == 0)))), row.names = FALSE)
sink()
write_csv(cells, file.path(OUT, "post_tsc_cells.csv"))

# ------------------------------------------------------------------ Figure A
pm_s <- pm |> group_by(Set, Study) |>
  summarise(n = dplyr::n(), mean = mean(Post_TSC), sd = sd(Post_TSC),
            lo = mean - qt(.975, n - 1) * sd / sqrt(n),
            hi = mean + qt(.975, n - 1) * sd / sqrt(n), .groups = "drop")
ratio_lab <- pm_s |> group_by(Set) |>
  summarise(y = max(hi), r = mean[Study == "Study 1"] / mean[Study == "Study 2"],
            .groups = "drop")

figA <- ggplot(pm, aes(Study, Post_TSC, colour = Study)) +
  geom_boxplot(width = .42, outlier.shape = NA, fill = NA, linewidth = .4,
               colour = "#b9b8b3") +
  geom_point(position = position_jitter(width = .12, height = 0), size = 1.4,
             alpha = .45) +
  geom_errorbar(data = pm_s, aes(y = mean, ymin = lo, ymax = hi), width = .09,
                linewidth = .95, position = position_nudge(x = .3)) +
  geom_point(data = pm_s, aes(y = mean), size = 3.3, position = position_nudge(x = .3)) +
  geom_text(data = pm_s, aes(y = mean, label = sprintf("%.1f", mean)),
            position = position_nudge(x = .44), hjust = 0, size = 3.2,
            fontface = "bold", colour = INK) +
  geom_text(data = ratio_lab, aes(x = 1.5, y = 136, label = sprintf("Study 1 ≈ %.1f× Study 2", r)),
            inherit.aes = FALSE, size = 3.3, colour = INK2) +
  facet_wrap(~ Set, nrow = 1) +
  scale_colour_manual(values = PAL_STUDY, guide = "none") +
  scale_y_continuous(limits = c(0, 140), breaks = seq(0, 125, 25)) +
  labs(title = "Post-exposure sickness was about three times higher in Study 1",
       subtitle = "SSQ Total Severity after the video, one point per participant (mean over that participant's trials)",
       x = NULL, y = "POST SSQ Total Severity (TSC)",
       caption = paste0("Box = median and IQR; large point = mean with 95% CI. n = 36 participants per study, no overlap between studies.\n",
                        "Right panel restricts both studies to the two methods they share, removing Baseline and Dynamic FOV (Study 1) and ROF (Study 2).")) +
  theme_pub()
ggsave(file.path(PLOT, "post_tsc_by_study.png"), figA, width = 8.6, height = 5.4,
       dpi = 300, bg = "#ffffff")

# ------------------------------------------------------------------ Figure B
cellsB <- cells |> mutate(Method = factor(Method, levels = METHODS))
figB <- ggplot(cellsB, aes(Method, mean, colour = Study)) +
  annotate("rect", xmin = 3.5, xmax = 5.5, ymin = -Inf, ymax = Inf,
           fill = "#f1f0ec", alpha = .8) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .18, linewidth = .85) +
  geom_point(size = 3) +
  geom_text(aes(label = sprintf("%.0f", mean)), hjust = -.45, size = 2.9,
            colour = INK, show.legend = FALSE) +
  facet_wrap(~ Video, nrow = 1) +
  scale_colour_manual(values = PAL_STUDY) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
  labs(title = "Study 1 conditions sit well above every Study 2 condition, including the methods both studies share",
       subtitle = "Mean POST SSQ Total Severity with 95% CI for each Method × Video cell (n = 36 per cell)",
       x = NULL, y = "POST SSQ Total Severity (TSC)",
       caption = "Shaded band = methods used in both studies. Baseline and Dynamic FOV were tested only in Study 1; ROF only in Study 2.") +
  theme_pub() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))
ggsave(file.path(PLOT, "post_tsc_method_video_by_study.png"), figB, width = 11,
       height = 5.2, dpi = 300, bg = "#ffffff")

cat("\nWrote results/comparison/ (txt, csv, plots/post_tsc_by_study.png, plots/post_tsc_method_video_by_study.png)\n")
