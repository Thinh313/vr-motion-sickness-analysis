#!/usr/bin/env Rscript
# =============================================================================
# Preference Ranking Analysis (Exploratory)
# Bead: bd-3k8
# =============================================================================
# Design: 13 of 36 participants provided preference rankings
# Conditions: Baseline, Overlay Path, Minimap, Dynamic FOV
# Ranking: 1 = most preferred, 4 = least preferred (midranks for ties)
# Analyses: descriptive summaries, pairwise sign tests (Holm correction)
# Framing: EXPLORATORY — partial coverage (13/36)
# =============================================================================

# --- 0. PACKAGE MANAGEMENT ---------------------------------------------------

required_packages <- c("tidyverse")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing package: %s", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(tidyverse)

# --- 1. OUTPUT SETUP ---------------------------------------------------------

output_file <- "preference_results.txt"
con <- file(output_file, open = "wt", encoding = "UTF-8")
sink(con, split = TRUE)
sink(con, type = "message")

cat("\n==============================================================\n")
cat("  PREFERENCE RANKING ANALYSIS (EXPLORATORY)\n")
cat("  13/36 participants — partial coverage\n")
cat("==============================================================\n\n")

# --- 2. READ AND VALIDATE INPUT ----------------------------------------------

cat("--- 2. DATA LOADING & VALIDATION ---\n\n")

df <- read.csv("preference_input.csv", stringsAsFactors = FALSE,
               fileEncoding = "UTF-8")

# Expected columns
expected_cols <- c("participant_name", "baseline_rank", "overlay_path_rank",
                   "minimap_rank", "dynamic_fov_rank")
rank_cols <- c("baseline_rank", "overlay_path_rank", "minimap_rank",
               "dynamic_fov_rank")

# Schema check
if (!all(expected_cols %in% colnames(df))) {
  missing <- setdiff(expected_cols, colnames(df))
  stop(sprintf("Missing columns: %s", paste(missing, collapse = ", ")))
}

# Duplicate participant check
if (any(duplicated(df$participant_name))) {
  dups <- df$participant_name[duplicated(df$participant_name)]
  stop(sprintf("Duplicate participant names: %s", paste(dups, collapse = ", ")))
}

# Rank validity check (each rank between 1 and 4, sum = 10)
for (i in seq_len(nrow(df))) {
  ranks <- as.numeric(df[i, rank_cols])
  name <- df$participant_name[i]

  if (any(is.na(ranks))) {
    stop(sprintf("Non-numeric rank values for participant: %s", name))
  }
  if (any(ranks < 1) || any(ranks > 4)) {
    stop(sprintf("Rank values outside [1, 4] for participant: %s (values: %s)",
                 name, paste(ranks, collapse = ", ")))
  }
  if (abs(sum(ranks) - 10) > 0.001) {
    stop(sprintf("Rank sum != 10 for participant: %s (sum: %.1f)",
                 name, sum(ranks)))
  }
}

n_participants <- nrow(df)
n_total <- 36  # total study participants
cat(sprintf("Participants with rankings: %d / %d (%.1f%% coverage)\n",
            n_participants, n_total, 100 * n_participants / n_total))
cat(sprintf("Conditions: Baseline, Overlay Path, Minimap, Dynamic FOV\n"))
cat(sprintf("Rank scale: 1 = most preferred, 4 = least preferred\n"))
cat("Validation: PASS (all rows have valid schema and rank sums)\n\n")

# --- 3. DESCRIPTIVE STATISTICS -----------------------------------------------

cat("--- 3. DESCRIPTIVE STATISTICS ---\n\n")

method_labels <- c(baseline_rank = "Baseline",
                   overlay_path_rank = "Overlay Path",
                   minimap_rank = "Minimap",
                   dynamic_fov_rank = "Dynamic FOV")

# Compute per-method summaries
summary_list <- lapply(rank_cols, function(col) {
  ranks <- df[[col]]
  label <- method_labels[col]

  # First choice: rank == 1 (split ties)
  first_choice <- 0
  for (i in seq_along(ranks)) {
    row_ranks <- as.numeric(df[i, rank_cols])
    if (ranks[i] == min(row_ranks)) {
      n_tied_first <- sum(row_ranks == min(row_ranks))
      first_choice <- first_choice + 1.0 / n_tied_first
    }
  }

  # Last choice: rank == 4 (split ties)
  last_choice <- 0
  for (i in seq_along(ranks)) {
    row_ranks <- as.numeric(df[i, rank_cols])
    if (ranks[i] == max(row_ranks)) {
      n_tied_last <- sum(row_ranks == max(row_ranks))
      last_choice <- last_choice + 1.0 / n_tied_last
    }
  }

  # Borda score: sum of (5 - rank) across all participants
  borda <- sum(5 - ranks)

  data.frame(
    Method = label,
    Mean_Rank = round(mean(ranks), 4),
    Median_Rank = median(ranks),
    SD_Rank = round(sd(ranks), 4),
    Borda_Score = borda,
    First_Choice = round(first_choice, 1),
    First_Pct = round(100 * first_choice / n_participants, 1),
    Last_Choice = round(last_choice, 1),
    Last_Pct = round(100 * last_choice / n_participants, 1),
    stringsAsFactors = FALSE
  )
})

summary_df <- do.call(rbind, summary_list)
summary_df <- summary_df[order(summary_df$Mean_Rank), ]  # best (lowest) first

cat("Ranking Summary (ordered by mean rank, lower = more preferred):\n\n")
print(summary_df, row.names = FALSE)
cat("\n")

cat(sprintf("Interpretation:\n"))
cat(sprintf("  Best mean rank:  %s (%.3f)\n",
            summary_df$Method[1], summary_df$Mean_Rank[1]))
cat(sprintf("  Worst mean rank: %s (%.3f)\n",
            summary_df$Method[nrow(summary_df)],
            summary_df$Mean_Rank[nrow(summary_df)]))
cat(sprintf("  Most first choices:  %s (%.1f)\n",
            summary_df$Method[which.max(summary_df$First_Choice)],
            max(summary_df$First_Choice)))
cat(sprintf("  Most last choices:   %s (%.1f)\n",
            summary_df$Method[which.max(summary_df$Last_Choice)],
            max(summary_df$Last_Choice)))
cat("\n")

# --- 4. PAIRWISE PREFERENCE COMPARISONS --------------------------------------

cat("--- 4. PAIRWISE PREFERENCE COMPARISONS ---\n\n")

# Build pairwise win/loss/tie matrix
pairs <- combn(rank_cols, 2, simplify = FALSE)
pair_results <- list()

for (p in pairs) {
  a_col <- p[1]
  b_col <- p[2]
  a_label <- method_labels[a_col]
  b_label <- method_labels[b_col]

  a_ranks <- df[[a_col]]
  b_ranks <- df[[b_col]]

  # A wins when A has lower rank (more preferred)
  a_wins <- sum(a_ranks < b_ranks)
  b_wins <- sum(a_ranks > b_ranks)
  ties   <- sum(a_ranks == b_ranks)

  pair_results[[length(pair_results) + 1]] <- data.frame(
    Pair = sprintf("%s vs %s", a_label, b_label),
    A_Wins = a_wins,
    B_Wins = b_wins,
    Ties = ties,
    A_Label = a_label,
    B_Label = b_label,
    stringsAsFactors = FALSE
  )
}

pair_df <- do.call(rbind, pair_results)

cat("Pairwise preference counts (A wins = A preferred over B):\n\n")
print(pair_df[, c("Pair", "A_Wins", "B_Wins", "Ties")], row.names = FALSE)
cat("\n")

# --- 5. EXACT SIGN TESTS WITH HOLM CORRECTION --------------------------------

cat("--- 5. PAIRWISE SIGN TESTS (EXACT BINOMIAL, HOLM CORRECTION) ---\n\n")
cat("Note: ties are excluded from sign test (only discordant pairs tested)\n")
cat("H0: P(A preferred) = 0.5 among discordant pairs\n")
cat("Framing: EXPLORATORY — p-values are descriptive, not confirmatory\n\n")

sign_results <- list()

for (i in seq_len(nrow(pair_df))) {
  a_wins <- pair_df$A_Wins[i]
  b_wins <- pair_df$B_Wins[i]
  n_disc <- a_wins + b_wins  # discordant pairs (excl ties)

  if (n_disc > 0) {
    # Two-sided exact binomial test
    test <- binom.test(a_wins, n_disc, p = 0.5, alternative = "two.sided")
    p_raw <- test$p.value
  } else {
    p_raw <- 1.0
  }

  sign_results[[i]] <- data.frame(
    Pair = pair_df$Pair[i],
    A_Wins = a_wins,
    B_Wins = b_wins,
    Ties = pair_df$Ties[i],
    n_discordant = n_disc,
    p.value = round(p_raw, 4),
    stringsAsFactors = FALSE
  )
}

sign_df <- do.call(rbind, sign_results)

# Holm correction across all 6 tests
sign_df$p.Holm <- round(p.adjust(sign_df$p.value, method = "holm"), 4)

cat("Pairwise sign test results:\n\n")
print(sign_df, row.names = FALSE)
cat("\n")

# Flag any nominally significant results
nom_sig <- sign_df[sign_df$p.value < 0.05, ]
if (nrow(nom_sig) > 0) {
  cat("Nominally significant pairs (p < .05, uncorrected):\n")
  for (j in seq_len(nrow(nom_sig))) {
    cat(sprintf("  %s: p = %.4f (Holm-adjusted: %.4f)\n",
                nom_sig$Pair[j], nom_sig$p.value[j], nom_sig$p.Holm[j]))
  }
} else {
  cat("No pairwise comparisons reached nominal significance (p < .05).\n")
}
cat("\n")

# --- 6. FRIEDMAN TEST & KENDALL'S W ------------------------------------------

cat("--- 6. FRIEDMAN TEST & KENDALL'S W (EXPLORATORY) ---\n\n")

# Build rank matrix (participants x methods)
rank_matrix <- as.matrix(df[, rank_cols])

# Friedman test (base R)
friedman_result <- friedman.test(rank_matrix)
cat(sprintf("Friedman chi-squared = %.4f, df = %d, p-value = %.4f\n",
            friedman_result$statistic, friedman_result$parameter,
            friedman_result$p.value))

# Kendall's W = chi2 / (n * (k - 1))
k <- length(rank_cols)  # 4 methods
W <- as.numeric(friedman_result$statistic) / (n_participants * (k - 1))
cat(sprintf("Kendall's W = %.4f\n", W))
cat(sprintf("Interpretation: W ranges from 0 (no agreement) to 1 (perfect agreement)\n"))

if (W < 0.3) {
  cat("  -> Weak agreement among raters\n")
} else if (W < 0.5) {
  cat("  -> Moderate agreement among raters\n")
} else if (W < 0.7) {
  cat("  -> Good agreement among raters\n")
} else {
  cat("  -> Strong agreement among raters\n")
}
cat("\n")

# --- 7. GENERATE PLOTS -------------------------------------------------------

cat("--- 7. GENERATING PLOTS ---\n\n")

# Ensure plots directory exists
if (!dir.exists("plots")) dir.create("plots")

# Method order for consistent plotting (by mean rank, best first)
method_order <- summary_df$Method

# Color palette matching existing project style
method_colors <- c("Baseline" = "#F8766D", "Overlay Path" = "#7CAE00",
                   "Minimap" = "#00BFC4", "Dynamic FOV" = "#C77CFF")

# --- Plot 1: First-choice bar chart ---
p1_data <- summary_df %>%
  mutate(Method = factor(Method, levels = method_order))

p1 <- ggplot(p1_data, aes(x = Method, y = First_Choice, fill = Method)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.1f", First_Choice)),
            vjust = -0.5, size = 4) +
  scale_fill_manual(values = method_colors) +
  labs(title = "First-Choice Preference Counts",
       subtitle = sprintf("n = %d participants (exploratory, %d/%d coverage)",
                          n_participants, n_participants, n_total),
       x = "Navigation Aid Method", y = "First-Choice Count (tie-split)") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave("plots/preference_first_choice.png", p1,
       width = 7, height = 5, dpi = 150)
cat("  Saved: plots/preference_first_choice.png\n")

# --- Plot 2: Mean rank bar chart (lower = better) ---
p2_data <- summary_df %>%
  mutate(Method = factor(Method, levels = method_order))

p2 <- ggplot(p2_data, aes(x = Method, y = Mean_Rank, fill = Method)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_errorbar(aes(ymin = Mean_Rank - SD_Rank / sqrt(n_participants),
                     ymax = Mean_Rank + SD_Rank / sqrt(n_participants)),
                width = 0.2) +
  geom_text(aes(label = sprintf("%.2f", Mean_Rank)),
            vjust = -0.5, size = 4) +
  scale_fill_manual(values = method_colors) +
  scale_y_continuous(limits = c(0, 4), breaks = 1:4) +
  labs(title = "Mean Preference Rank by Method",
       subtitle = sprintf("n = %d (lower = more preferred; error bars = SE)",
                          n_participants),
       x = "Navigation Aid Method", y = "Mean Rank") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

ggsave("plots/preference_mean_rank.png", p2,
       width = 7, height = 5, dpi = 150)
cat("  Saved: plots/preference_mean_rank.png\n")

# --- Plot 3: Pairwise-win heatmap ---
methods <- names(method_labels)
method_names <- as.character(method_labels)
n_methods <- length(methods)

# Build win matrix
win_matrix <- matrix(0, nrow = n_methods, ncol = n_methods,
                     dimnames = list(method_names, method_names))

for (i in 1:(n_methods - 1)) {
  for (j in (i + 1):n_methods) {
    a_ranks <- df[[methods[i]]]
    b_ranks <- df[[methods[j]]]
    a_wins <- sum(a_ranks < b_ranks)
    b_wins <- sum(a_ranks > b_ranks)
    win_matrix[method_names[i], method_names[j]] <- a_wins
    win_matrix[method_names[j], method_names[i]] <- b_wins
  }
}

# Convert to long format for ggplot
win_long <- as.data.frame(as.table(win_matrix))
colnames(win_long) <- c("Row_Method", "Col_Method", "Wins")

# Set factor levels
win_long$Row_Method <- factor(win_long$Row_Method, levels = method_names)
win_long$Col_Method <- factor(win_long$Col_Method, levels = method_names)

p3 <- ggplot(win_long, aes(x = Col_Method, y = Row_Method, fill = Wins)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = ifelse(Row_Method == Col_Method, "-",
                                as.character(Wins))),
            size = 5) +
  scale_fill_gradient(low = "white", high = "#2166AC",
                      limits = c(0, n_participants),
                      name = "Wins") +
  labs(title = "Pairwise Preference Wins",
       subtitle = sprintf("Cell (row, col) = times row method preferred over col method (n = %d)",
                          n_participants),
       x = "Column Method (opponent)", y = "Row Method (winner)") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 30, hjust = 1),
        panel.grid = element_blank()) +
  coord_fixed()

ggsave("plots/preference_pairwise_heatmap.png", p3,
       width = 7, height = 6, dpi = 150)
cat("  Saved: plots/preference_pairwise_heatmap.png\n")

# --- Plot 4: Borda score bar chart ---
p4_data <- summary_df %>%
  mutate(Method = factor(Method, levels = method_order))

p4 <- ggplot(p4_data, aes(x = Method, y = Borda_Score, fill = Method)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.1f", Borda_Score)),
            vjust = -0.5, size = 4) +
  scale_fill_manual(values = method_colors) +
  labs(title = "Borda Preference Scores by Method",
       subtitle = sprintf("n = %d (higher = more preferred; Borda = sum of [5 - rank])",
                          n_participants),
       x = "Navigation Aid Method", y = "Borda Score") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

ggsave("plots/preference_borda_score.png", p4,
       width = 7, height = 5, dpi = 150)
cat("  Saved: plots/preference_borda_score.png\n")

cat("\n")

# --- 8. SUMMARY ---------------------------------------------------------------

cat("--- 8. SUMMARY ---\n\n")
cat("EXPLORATORY PREFERENCE ANALYSIS COMPLETE\n")
cat(sprintf("Coverage: %d / %d participants (%.1f%%)\n",
            n_participants, n_total, 100 * n_participants / n_total))
cat(sprintf("Friedman test: chi2 = %.4f, df = %d, p = %.4f\n",
            friedman_result$statistic, friedman_result$parameter,
            friedman_result$p.value))
cat(sprintf("Kendall's W = %.4f\n", W))
cat("\nCAVEAT: These results are exploratory due to partial coverage (13/36).\n")
cat("P-values should be interpreted as descriptive patterns, not confirmatory.\n")
cat("\nOutput files:\n")
cat("  preference_results.txt (this file)\n")
cat("  plots/preference_first_choice.png\n")
cat("  plots/preference_mean_rank.png\n")
cat("  plots/preference_pairwise_heatmap.png\n")
cat("  plots/preference_borda_score.png\n")

# --- Close sink ---------------------------------------------------------------
sink(type = "message")
sink()
close(con)

cat("Done. Results written to preference_results.txt\n")
