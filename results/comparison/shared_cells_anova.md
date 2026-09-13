# Study 1 vs Study 2 — Mixed ANOVA on the Shared Method × Video Cells

**Question:** do POST-exposure SSQ scores in the six cells both studies share (Minimap and Path Overlay × Walking, Cycling, Driving) differ between Study 1 and Study 2?

**Reproduce:** `Rscript scripts/compare_shared_cells_anova.R` (from the repo root)
**Full output:** `shared_cells_anova.txt` · **Tables:** `shared_cells_anova.csv`, `shared_cells_study_contrasts.csv`

## Design

| Factor | Type | Levels |
|---|---|---|
| Study | between-subjects | Study 1, Study 2 (36 participants each, **no overlap**) |
| Method | within-subjects | Minimap, Path Overlay |
| Video | within-subjects | Walking, Cycling, Driving |

Outcome: **POST** SSQ score (TSC, Nausea, Oculomotor, Disorientation), Kennedy et al. (1993) scoring. POST is the only measure both studies share, because Study 1 did not collect a pre-trial SSQ. 72 participants × 6 cells = 432 observations; every participant has exactly one observation per cell.

Conventions follow Study 1: afex type III, Greenhouse–Geisser correction, generalized η², Holm correction across the four SSQ outcomes within each effect, and Bonferroni post-hocs.

## Result

**Yes. Every shared cell differs significantly between the studies, on all four SSQ outcomes.**

### Mixed ANOVA (Holm across outcomes)

| Effect | TSC | Nausea | Oculomotor | Disorientation |
|---|---|---|---|---|
| **Study** | ***F*(1, 70) = 42.76, *p* < .001, η²_G = .287** | **41.66, <.001, .259** | **41.33, <.001, .283** | **34.06, <.001, .231** |
| Method | 0.03, 1.000 | 0.00, 1.000 | 0.18, 1.000 | 0.00, 1.000 |
| Video | 1.61, .622 | 1.36, .622 | 2.02, .565 | 1.08, .622 |
| Study × Method | 0.57, 1.000 | 0.61, 1.000 | 0.77, 1.000 | 0.16, 1.000 |
| Study × Video | 0.10, 1.000 | 0.05, 1.000 | 1.01, 1.000 | 0.06, 1.000 |
| Method × Video | 0.83, .856 | 1.31, .817 | 1.84, .665 | 0.48, .856 |
| Study × Method × Video | 1.17, .927 | 2.71, .305 | 0.71, .963 | 0.60, .963 |

Cells show *F*, then Holm-corrected *p* (η²_G is shown for the Study effect only; all others are ≤ .005). For Video and the interactions involving it, df are GG-corrected (≈ 1.5–1.8 and 107–128).

### Study 1 − Study 2 in each shared cell, POST TSC (Bonferroni across the 6 cells)

| Method | Video | Study 1 M | Study 2 M | Difference [95% CI] | *t*(70) | *p* | *d* |
|---|---|---|---|---|---|---|---|
| Minimap | Walking | 60.36 | 20.99 | 39.37 [18.20, 60.55] | 5.05 | <.001 | 1.19 |
| Minimap | Cycling | 55.27 | 18.08 | 37.19 [17.60, 56.79] | 5.15 | <.001 | 1.21 |
| Minimap | Driving | 50.91 | 16.31 | 34.59 [15.42, 53.77] | 4.90 | <.001 | 1.15 |
| Path Overlay | Walking | 56.00 | 19.74 | 36.26 [18.79, 53.73] | 5.64 | <.001 | 1.33 |
| Path Overlay | Cycling | 58.18 | 15.48 | 42.70 [21.30, 64.10] | 5.42 | <.001 | 1.28 |
| Path Overlay | Driving | 56.00 | 14.54 | 41.45 [22.09, 60.81] | 5.81 | <.001 | 1.37 |

The subscales show the same pattern in all six cells, all Bonferroni *p* < .001:

| Outcome | Difference range | *d* range |
|---|---|---|
| Nausea | 18.0–24.4 | 0.99–1.53 |
| Oculomotor | 29.5–39.8 | 1.10–1.34 |
| Disorientation | 43.7–52.6 | 0.99–1.19 |

## What to notice

1. **The gap between studies is large and uniform.** Study explains about 23–29% of the variance (η²_G), and the per-cell effect sizes are *d* ≈ 1.2–1.4 for TSC.
2. **The gap does not depend on method or video.** Study × Method, Study × Video and the three-way interaction are all null. It is a roughly constant shift of about 35–43 TSC points, or about 3× on the ratio scale, applied to every shared cell.
3. **Minimap and Path Overlay do not differ in either study** (Method and Study × Method null). This agrees with both studies' own analyses.
4. **Video has no effect on raw POST scores in either study.** That includes Study 2, where the Δ-score analysis *did* find a Walking effect. Within Study 2, Walking − Driving on POST is +4.9 TSC, *p* = .44, versus +7.65, *p* = .003 on Δ. This supports the report's point that subtracting each trial's own pre-score is what made the video effect detectable.

## Assumption checks and robustness

- **Unequal variances between studies** (Levene on participant means, *p* = .018; significant after Holm in 4 of 6 cells). Study 1 is more spread out, as expected at a higher mean. Group sizes are equal (36 vs 36), which makes the mixed ANOVA fairly robust, and the checks below do not assume equal variances.
- **Non-normal residuals** (Shapiro–Wilk *W* = 0.950, *p* < .001).
- **Welch *t*-tests per cell** (Holm across 6): all *p* < .001.
- **Mann–Whitney tests per cell** (Holm across 6): all *p* < .001.
- **Mixed ANOVA on log(TSC + 1)**, which tests proportional rather than additive differences and evens out the variance gap: Study *F*(1, 70) = 41.25, *p* < .001, η²_G = .303. Study × Method (*p* = .138), Study × Video (*p* = .263) and the three-way interaction (*p* = .664) remain null. On this scale Video becomes significant (*p* = .005) with no Study × Video interaction, so a small, proportional video effect common to both studies can't be ruled out.
- **Sphericity:** Mauchly was significant for Video and Method × Video (*p* = .001 and .015). GG correction is applied throughout.

**Every analysis agrees:** the shared cells are significantly different between the two studies.

## Interpretation limits

- **This is a between-study comparison, not an experiment.** Study is not randomised. The studies differ in participants, dates (Jul 2025–Mar 2026 vs Mar–Jun 2026), and possibly clips, headset, session length and instructions. The ANOVA shows the difference is real and large. It cannot say which of these causes it.
- **Only POST scores can be compared.** Study 1 has no pre-trial SSQ, so we cannot tell whether Study 1 participants already started with higher symptoms or developed more during the videos.
- **Study 1 had four methods per session (12 trials) and Study 2 had three (9 trials).** Given the carryover found in Study 2, longer sessions could raise POST scores somewhat. That alone is unlikely to explain a threefold gap, but it is one more uncontrolled difference.
