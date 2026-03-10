# VR Motion Sickness Analysis

Statistical analysis pipeline for a within-subject VR motion sickness study comparing four navigation assistance methods across three video content types.

## Study Design

- **Participants:** 36 (fully within-subject)
- **IV1 — Method (4):** Baseline, Dynamic FOV, Minimap, Overlay Path
- **IV2 — Video (3):** Cycling, Walking, Driving
- **Conditions per participant:** 12 (4 × 3)
- **Total observations:** 432

### Dependent Variables

| DV | Instrument | Scale | Scoring |
|----|-----------|-------|---------|
| SSQ (Nausea, Oculomotor, Disorientation, TSC) | Simulator Sickness Questionnaire | 16 items, 0–3 | Kennedy et al. (1993) Table 4 weighted subscales |
| Presence | 5-item questionnaire | 1–7 Likert | Mean of 5 items |

## Data Pipeline

```
Raw survey data
  all_data.csv + data_2.csv
          │
          ▼
  normalize_data.py          ← merges, normalizes categories,
          │                     maps Vietnamese Likert → numeric,
          │                     computes Kennedy SSQ subscales
          ▼
  ┌───────┴────────────┐
  │                    │
  presence_dataset.csv ssq_dataset.csv    merged_normalized.csv
  │                    │                  qc_report.md
  └────────┬───────────┘
           ▼
    analysis_anova.R         ← 2-way RM-ANOVA (Method × Video),
           │                    GG correction, Holm across SSQ DVs,
           │                    Bonferroni post-hoc, sensitivity analysis
           ▼
    anova_results.txt        ← full statistical output
    anova_evaluation.md      ← interpreted results (Vietnamese)
    plots/                   ← visualizations
```

```
Preference ranking data (13 of 36 participants)
  preference_input.csv
          │
          ▼
  analysis_preference.R       ← descriptive stats, pairwise sign tests,
          │                     Friedman/Kendall's W, 4 preference plots
          ▼
  preference_results.txt      ← full statistical output
  preference_evaluation.md    ← interpreted results (Vietnamese)
  plots/preference_*.png      ← preference visualizations
```

## Requirements

### Python

- Python 3.10+
- pandas

```bash
python -m venv venv
venv\Scripts\activate    # Windows
pip install pandas
```

### R

- R 4.5+
- Packages: tidyverse, afex, emmeans, rstatix, ggpubr (auto-installed on first run)

## Usage

### 1. Normalize data

```bash
python normalize_data.py
```

Reads `all_data.csv` and `data_2.csv`, produces:
- `merged_normalized.csv` — full merged dataset
- `presence_dataset.csv` — presence items (1–7 scale)
- `ssq_dataset.csv` — SSQ items (0–3) + Kennedy weighted subscales
- `qc_report.md` — data quality report

### 2. Run ANOVA

```bash
Rscript analysis_anova.R
```

Produces:
- `anova_results.txt` — complete statistical output
- `plots/` — boxplots, interaction plots, Q-Q plots

### 3. Preference ranking analysis

```bash
Rscript analysis_preference.R
```

Produces:
- `preference_results.txt` — descriptive stats, pairwise sign tests, Friedman/Kendall's W
- `preference_evaluation.md` — interpreted preference results (Vietnamese)
- `plots/preference_*.png` — first-choice, mean-rank, Borda score, pairwise heatmap

## File Reference

| File | Description |
|------|-------------|
| `all_data.csv` | Primary raw survey data |
| `data_2.csv` | Secondary raw data (merged with primary) |
| `normalize_data.py` | Data normalization and SSQ scoring script |
| `analysis_anova.R` | 2-way RM-ANOVA analysis script |
| `merged_normalized.csv` | Intermediate merged dataset |
| `presence_dataset.csv` | Analysis-ready presence data (432 rows) |
| `ssq_dataset.csv` | Analysis-ready SSQ data with Kennedy subscales (432 rows) |
| `anova_results.txt` | Full R statistical output |
| `anova_evaluation.md` | Results interpretation and APA write-up (Vietnamese) |
| `qc_report.md` | Data quality validation report |
| `preference_input.csv` | Preference ranking data (13 participants, wide format) |
| `analysis_preference.R` | Preference ranking analysis script |
| `preference_results.txt` | Preference analysis statistical output |
| `preference_evaluation.md` | Preference results interpretation (Vietnamese) |

### Plots

| File | Content |
|------|---------|
| `ssq_combined_boxplot.png` | SSQ subscale boxplots by Method × Video |
| `ssq_combined_interaction.png` | SSQ interaction plot (Method × Video) |
| `ssq_grouped_bar.png` | SSQ subscale grouped bar chart |
| `ssq_tsc_residual_qqplot.png` | Residual Q-Q plot for TSC normality |
| `ssq_n_residual_qqplot.png` | Residual Q-Q plot for Nausea normality |
| `ssq_o_residual_qqplot.png` | Residual Q-Q plot for Oculomotor normality |
| `ssq_d_residual_qqplot.png` | Residual Q-Q plot for Disorientation normality |
| `presence_residual_qqplot.png` | Residual Q-Q plot for Presence normality |
| `preference_first_choice.png` | First-choice preference bar chart |
| `preference_mean_rank.png` | Mean preference rank with SE bars |
| `preference_borda_score.png` | Borda preference score bar chart |
| `preference_pairwise_heatmap.png` | Pairwise preference win heatmap |

## Key Results (N = 36)

**Method** significantly affected all SSQ subscales (all *p* < .001, η²_G = .034–.043) and Presence (*p* < .001, η²_G = .079). **Video** and **Method × Video** interaction were not significant.

| Method | SSQ TSC (EMM) | % Reduction | Presence (EMM) |
|--------|--------------|-------------|----------------|
| Baseline | 71.6 | — | 4.79 |
| Dynamic FOV | 48.3 | −33% | 3.92 |
| Minimap | 55.5 | −22% | 4.53 |
| Overlay Path | 56.7 | −21% | 4.41 |

All three methods significantly reduced SSQ vs Baseline, but did not differ from each other. Minimap preserved presence best (not significantly different from Baseline), while Dynamic FOV significantly reduced presence.

See `anova_evaluation.md` for full analysis and APA-formatted write-up.

## SSQ Scoring Method

SSQ subscales follow Kennedy, Lane, Berbaum & Lilienthal (1993) Table 4:

- **Nausea (N):** weighted sum × 9.54
- **Oculomotor (O):** weighted sum × 7.58
- **Disorientation (D):** weighted sum × 13.92
- **Total Severity (TSC):** (N_raw + O_raw + D_raw) × 3.74

## Statistical Approach

### SSQ & Presence (N = 36)

- **Analysis:** 2-way Repeated Measures ANOVA (afex::aov_ez)
- **Sphericity:** Greenhouse-Geisser correction
- **Multiple comparisons (across DVs):** Holm correction across 4 SSQ subscales
- **Post-hoc (within DV):** Bonferroni pairwise comparisons via emmeans
- **Effect size:** Generalized eta-squared (η²_G)
- **Sensitivity:** Re-analysis excluding extreme outliers (3×IQR criterion)

### Preference (n = 13/36, exploratory)

- **Design:** Within-subject complete ranking of 4 methods
- **Descriptive:** Mean/median rank, Borda score, first/last-choice counts
- **Pairwise:** Exact binomial sign tests with Holm correction
- **Overall agreement:** Friedman test, Kendall's W
- **Framing:** Exploratory only — partial coverage, no confirmatory claims
