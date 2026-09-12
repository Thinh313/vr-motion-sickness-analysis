# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Statistical analysis pipelines for two within-subject VR motion sickness studies (N = 36 each).

- **Study 1** — 4 navigation assistance methods (Baseline, Dynamic FOV, Minimap, Overlay Path) × 3 video types (Cycling, Walking, Driving); 12 conditions/participant, 432 observations; SSQ measured **post-trial only**.
- **Study 2** — 3 methods (Reverse Optical Flow, Minimap, Path Overlay) × 3 video types; 9 trials/participant, 324 trials; SSQ measured **both before and after every trial** (648 administrations). No Baseline condition.

## Pipeline (run in order)

```bash
# 1. Normalize raw cohort CSVs → analysis-ready datasets
python scripts/normalize_data.py

# 2. Two-way RM-ANOVA on SSQ + Presence (requires step 1 outputs)
Rscript scripts/analysis_anova.R

# 3. Preference ranking analysis (independent; uses data/preference/preference_input.csv)
Rscript scripts/analysis_preference.R

# --- Study 2 (independent of steps 1-3) ---
# 4. Build the Study 2 analysis dataset from experiment2_raw/
python scripts/study2_prepare.py

# 5. Full Study 2 analysis (run from the repo root)
Rscript scripts/study2_analysis.R
```

Supporting plot scripts: `scripts/generate_combined_qqplot.R`, `scripts/generate_histograms.R`.

Python 3.10+ (see `requirements.txt`), R 4.5+ (tidyverse, afex, emmeans, rstatix, ggpubr — auto-installed on first run).

## Architecture

Two independent analysis tracks share the same raw survey but diverge after normalization:

- **Main track (ANOVA, N = 36):** `data/raw/survey_raw_cohort_01_23_users.csv` + `data/raw/survey_raw_cohort_02_13_users.csv` → `normalize_data.py` merges cohorts, maps Vietnamese Likert text → numeric (see `PRESENCE_LIKERT_MAP`), normalizes cohort-specific method/video/VR-experience codes (cohort 01 uses single-letter codes `B/D/M/O` and `walk/cycl/driv`; cohort 02 uses display names with `"Overlay"` → `"Overlay Path"` remapping), drops `overall_sickness_severity`, and computes **Kennedy et al. (1993) Table 4** weighted SSQ subscales. Writes three analysis-ready CSVs to `data/processed/` plus `qc_report.md`.

- **Preference track (n = 13/36, exploratory):** wide-format rankings in `data/preference/preference_input.csv` are independent of the normalization pipeline. Framed as exploratory — do not make confirmatory claims from partial coverage.

### SSQ scoring (Kennedy 1993)

Hard-coded formulas applied in `normalize_data.py` and surfaced as DVs in `analysis_anova.R`:
- `ssq_n` (Nausea) = N_raw × 9.54
- `ssq_o` (Oculomotor) = O_raw × 7.58
- `ssq_d` (Disorientation) = D_raw × 13.92
- `ssq_tsc` (Total) = (N_raw + O_raw + D_raw) × 3.74

### Statistical conventions in `analysis_anova.R`

- `afex::aov_ez` with type III SS, Greenhouse-Geisser sphericity correction, generalized η² (η²_G) effect size.
- Multiple-comparison strategy is two-level: **Holm across the 4 SSQ DVs**, **Bonferroni within-DV** post-hocs via `emmeans`.
- Sensitivity re-analysis excludes extreme outliers by 3×IQR criterion.
- Output is tee'd to `results/anova/anova_results.txt` via `sink(..., split = TRUE)` — edits that add printed output must stay inside the sink block.

### Study 2 track (`scripts/study2_prepare.py` + `scripts/study2_analysis.R`)

Raw inputs are two Google-Forms exports in `experiment2_raw/` (immutable): `before_watching_video.csv` (PRE SSQ) and `after_watching_video.csv` (POST SSQ + the 5-item Presence scale + VR experience). Both are long format, 324 rows each, with **no participant-code or trial-number column** — participant identity comes from free-text Vietnamese names and trial order is reconstructed from form timestamps.

`study2_prepare.py` handles the three data-quality traps; do not "simplify" these away:
- **Name normalisation** (NFC → strip `(2k7)`-style parentheticals → collapse whitespace → lowercase → unify Vietnamese tone placement `Hoà`/`Hòa` → strip diacritics), plus the alias `Phúc Thành` → `Huỳnh Phúc Thành` (verified one participant by interleaved timestamps). `PARTICIPANT_ORDER` holds the experimenter-supplied numbering; it is authoritative.
- **Method label mismatch between files**: `Path overlay` (before) vs `Overlay` (after), both → `Path`.
- **PRE↔POST matching** on the key Participant × Method × Video, with a temporal-order fallback for the one participant (P13) whose POST video labels were mis-entered; PRE labels win.

`study2_analysis.R` reuses the Study 1 conventions (afex/GG/η²_G, Holm across the 4 SSQ DVs, Bonferroni post-hocs) and adds: a 2×3×3 Time × Method × Video RM-ANOVA (the **Time × Method** interaction is the primary effect), an algebraically equivalent Δ-score model, a pre-trial/carryover analysis, `lmer` sensitivity models, rank-based and bootstrap robustness checks, and TOST equivalence bounds for the null Method effect. Output is tee'd to `results/study2/study2_results.txt` via `sink(..., split = TRUE)` — added printed output must stay inside the sink block.

### Results layout

- `results/anova/` — raw stats (`anova_results.txt`), Vietnamese interpretation (`anova_evaluation.md`), and `plots/` (boxplots, interaction, grouped bar, per-DV residual Q-Q).
- `results/preference/` — `preference_results.txt`, Vietnamese `preference_evaluation.md`, and `plots/` (first/last-choice, mean-rank, Borda, pairwise heatmap).
- `results/study2/` — `study2_results.txt` (full stats), `study2_data_validation.md`, English `study2_report.md`, Vietnamese `study2_evaluation.md`, `tables/*.csv` (LaTeX-ready), and `plots/fig1..fig9`.

Evaluation/interpretation docs are written in **Vietnamese**; raw data contains Vietnamese Likert strings. Preserve Vietnamese text verbatim when editing these files or the `*_LIKERT_MAP` dictionaries.

## Conventions

- Treat `data/raw/` and `experiment2_raw/` as immutable — never modify; regenerate `data/processed/` via `normalize_data.py` (Study 1) and `study2_prepare.py` (Study 2).
- Study 2 has **no Baseline condition**. Never write claims of the form "method X reduces sickness vs unmodified VR" from Study 2 data — only method-vs-method comparisons are supported.
- Commit messages in this repo use a `type(bd-XXX): subject` style referencing a Beads issue ID (see recent `git log`).
