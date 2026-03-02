# QC Report: Presence/SSQ Data Normalization

Generated: 2026-03-02T12:48:21.877760

## Summary
- Total records: 408
- From all_data.csv: 288
- From data_2.csv: 120

## Category Checks
- method_experienced values: ['Baseline', 'Dynamic FOV', 'Minimap', 'Overlay Path']
- video_experienced values: ['Cycling', 'Driving', 'Walking']
- vr_experience_before values: ['no', 'yes']

## Presence Range Check (expected: 1-7)
- presence_env_video: min=1, max=7 [PASS]
- focus_env_video: min=1, max=7 [PASS]
- control_attention: min=1, max=7 [PASS]
- presence_virtual_space: min=1, max=7 [PASS]
- unaware_real_env: min=1, max=7 [PASS]

## SSQ Range Check (expected: 0-3)
- general_discomfort: min=0, max=3 [PASS]
- fatigue: min=0, max=3 [PASS]
- headache: min=0, max=3 [PASS]
- eye_strain: min=0, max=3 [PASS]
- difficulty_focusing: min=0, max=3 [PASS]
- increased_salivation: min=0, max=3 [PASS]
- sweating: min=0, max=3 [PASS]
- nausea: min=0, max=3 [PASS]
- difficulty_concentrating: min=0, max=3 [PASS]
- fullness_head: min=0, max=3 [PASS]
- blurred_vision: min=0, max=3 [PASS]
- dizzy_eyes_open: min=0, max=3 [PASS]
- dizzy_eyes_closed: min=0, max=3 [PASS]
- vertigo: min=0, max=3 [PASS]
- stomach_awareness: min=0, max=3 [PASS]
- burping: min=0, max=2 [PASS]

## Kennedy 1993 SSQ Subscale Scoring Verification

### Item Mapping (Table 4)
- **N (Nausea)**: general_discomfort, increased_salivation, sweating, nausea, difficulty_concentrating, stomach_awareness, burping
- **O (Oculomotor)**: general_discomfort, fatigue, headache, eye_strain, difficulty_focusing, difficulty_concentrating, blurred_vision
- **D (Disorientation)**: difficulty_focusing, nausea, fullness_head, blurred_vision, dizzy_eyes_open, dizzy_eyes_closed, vertigo

### Weight Factors
- N = raw_sum × 9.54
- O = raw_sum × 7.58
- D = raw_sum × 13.92
- TSC = (N_raw + O_raw + D_raw) × 3.74

### Raw Subscale Score Ranges (expected: 0-21)
- ssq_n_raw: min=0, max=20 [PASS]
- ssq_o_raw: min=0, max=21 [PASS]
- ssq_d_raw: min=0, max=21 [PASS]

### Weighted Subscale Score Verification
- N: raw_match=100.0%, weighted_match=100.0% [PASS]
- O: raw_match=100.0%, weighted_match=100.0% [PASS]
- D: raw_match=100.0%, weighted_match=100.0% [PASS]
- TSC: match=100.0% [PASS]

### Descriptive Statistics
- ssq_n_raw: mean=3.54, sd=2.79, min=0.00, max=20.00
- ssq_o_raw: mean=7.21, sd=4.70, min=0.00, max=21.00
- ssq_d_raw: mean=5.75, sd=4.28, min=0.00, max=21.00
- ssq_n: mean=33.81, sd=26.65, min=0.00, max=190.80
- ssq_o: mean=54.64, sd=35.62, min=0.00, max=159.18
- ssq_d: mean=80.04, sd=59.53, min=0.00, max=292.32
- ssq_tsc: mean=61.72, sd=41.38, min=0.00, max=231.88

## overall_sickness_severity Check
- Column present in output: False [PASS]

## RM-ANOVA Results (Kennedy 1993 Subscales)

Analysis: 2-way Repeated Measures ANOVA (Method × Video)
Subjects: 33 (1 excluded for incomplete data) × 12 conditions = 396 observations
Correction: Greenhouse-Geisser for sphericity, Holm for multiple DVs

### SSQ Effect Map

| Effect | TSC | Nausea (N) | Oculomotor (O) | Disorientation (D) |
|--------|-----|------------|----------------|-------------------|
| **Method** | F(2.6,84.4)=10.29, p<.001***, ges=.055 | F(2.9,92.8)=8.14, p<.001***, ges=.042 | F(2.5,81.1)=10.05, p<.001***, ges=.056 | F(2.8,90.0)=7.80, p<.001***, ges=.046 |
| **Video** | F(1.7,54.4)=1.35, p=.265, ges=.007 | F(1.4,44.8)=1.50, p=.233, ges=.009 | F(1.8,58.7)=2.49, p=.096, ges=.012 | F(1.8,57.7)=0.60, p=.535, ges=.003 |
| **Method×Video** | F(3.9,126.1)=0.77, p=.543, ges=.004 | F(3.3,105.2)=0.65, p=.596, ges=.004 | F(4.5,144.9)=0.93, p=.457, ges=.005 | F(4.3,139.1)=0.79, p=.542, ges=.004 |

All Method effects survive Holm correction (p_holm < .001). No Video or Interaction effects are significant.

### SSQ Marginal Means by Method

| Method | TSC (M±SD) | N (M±SD) | O (M±SD) | D (M±SD) |
|--------|-----------|----------|----------|----------|
| Baseline | 75.9 ± 47.1 | 42.5 ± 30.4 | 66.7 ± 40.4 | 97.9 ± 66.8 |
| Dynamic FOV | 49.4 ± 39.3 | 27.9 ± 27.1 | 43.6 ± 34.5 | 63.1 ± 51.1 |
| Minimap | 58.2 ± 37.8 | 31.0 ± 25.4 | 52.1 ± 31.9 | 75.5 ± 56.9 |
| Overlay Path | 59.2 ± 35.8 | 32.3 ± 22.0 | 52.8 ± 31.0 | 76.2 ± 54.1 |

### Post-hoc: Method Pairwise Comparisons (Bonferroni)

Pattern consistent across all 4 SSQ DVs:
- **Baseline > Dynamic FOV**: significant on all DVs (TSC p=.0002, N p=.0006, O p=.0005, D p=.0004)
- **Baseline > Minimap**: significant on all DVs (TSC p=.008, N p=.005, O p=.017, D p=.026)
- **Baseline > Overlay Path**: significant on TSC (p=.013), N (p=.020), O (p=.017); marginal on D (p=.052)
- **Dynamic FOV vs Minimap**: not significant on any DV
- **Dynamic FOV vs Overlay Path**: not significant on any DV
- **Minimap vs Overlay Path**: not significant on any DV

**Interpretation**: All three mitigation methods (Dynamic FOV, Minimap, Overlay Path) reduce motion sickness compared to Baseline, but are not significantly different from each other. Dynamic FOV shows the largest numerical reduction.

### Presence (IPQ mean)

| Effect | F | p | ges |
|--------|---|---|-----|
| **Method** | F(1.9,61.8)=15.85 | p<.001*** | .099 |
| **Video** | F(1.8,59.0)=1.01 | p=.366 | .003 |
| **Method×Video** | F(4.3,138.4)=1.72 | p=.143 | .011 |

Presence marginal means: Baseline (4.80) > Minimap (4.52) > Overlay Path (4.42) > Dynamic FOV (3.84)
Post-hoc: Dynamic FOV significantly lower presence than Baseline (p=.0002), Minimap (p=.001), Overlay Path (p=.003).

### Sensitivity Analysis

Excluded 3 subjects with extreme outliers (>3×IQR). Remaining: 30 subjects, 360 observations.
All 12 effect×DV combinations show **identical significance pattern** (Holm-corrected) with and without extreme outliers. Results are **robust**.

### Assumptions

- **Normality**: Some cells violate Shapiro-Wilk (especially Nausea: 10/12 cells). RM-ANOVA is robust with N≥30 and balanced design (Field, 2018).
- **Sphericity**: Greenhouse-Geisser correction applied to all F-tests.
- **Outliers**: 7 TSC, 12 N, 4 O, 7 D outliers detected. Sensitivity analysis confirms robustness.

## Validation Issues
- None. All checks passed.

## Output Files
- [x] merged_normalized.csv
- [x] presence_dataset.csv
- [x] ssq_dataset.csv
- [x] anova_results.txt
- [x] plots/ (18 plots: interaction, boxplot, QQ per DV)
