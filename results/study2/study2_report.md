# Study 2 — Pre/Post SSQ Analysis of Three VIMS Mitigation Methods

**Design:** 36 participants × 3 methods (Reverse Optical Flow, Minimap, Path Overlay) × 3 video types (Walking, Cycling, Driving), fully within-subject. The 16-item SSQ was administered immediately **before** and immediately **after** every trial — 324 trials, 648 SSQ administrations.

**Reproduce:** `python scripts/study2_prepare.py` → `Rscript scripts/study2_analysis.R`
**Full output:** `results/study2/study2_results.txt` · **Tables:** `results/study2/tables/*.csv` · **Figures:** `results/study2/plots/*.png`
**Data validation:** `results/study2/study2_data_validation.md`

---

## Headline

> Watching the 360° videos **reliably and substantially increased** simulator sickness — SSQ Total Severity roughly **doubled** from pre to post (+8.4 points, +88%, *d*z = 0.90).
>
> **Which mitigation method was used made no detectable difference to that increase.** The Time × Method interaction — the primary Study-2 effect — was null on all four SSQ outcomes (all *F* ≤ 0.78, all *p* ≥ .44, η²_G ≤ .001).
>
> **What did matter was the video.** The Walking clip induced roughly **2.4× the symptom increase** of Driving (Time × Video, Holm *p* = .004). This is a **new result: Study 1 found no effect of video type at all.**
>
> A separate finding with direct implications for protocol design: **symptoms did not clear between trials.** The previous trial's post-score strongly predicted the next trial's pre-score (*b* = 0.39, *p* < .001), and pre-trial sickness climbed steadily from trial 2 to trial 9.

---

## 1. Data validation

All checks passed; details in `study2_data_validation.md`. Summary:

| Check | Result |
|---|---|
| Rows (before / after) | 324 / 324 ✔ |
| Participants after ID normalisation | **36** ✔ |
| Trials per participant | 9 for all 36 ✔ |
| PRE↔POST matched | 324 / 324, 0 unmatched ✔ |
| Missing values | 0 ✔ |
| Duplicate Participant × Method × Video | 0 ✔ |
| SSQ item range | 0–3 as expected ✔ |
| Survey `SUM SSQ` vs recomputed item sum | 324/324 agree ✔ |
| Counterbalancing | exact (see §8) ✔ |

## 2. SSQ scoring

Kennedy, Lane, Berbaum & Lilienthal (1993) Table 4, identical to the Study 1 pipeline, applied separately to the PRE and POST item sets.

| Subscale | Items (survey numbers) | Weight |
|---|---|---|
| Nausea (N) | 1, 6, 7, 8, 9, 15, 16 | raw × 9.54 |
| Oculomotor (O) | 1, 2, 3, 4, 5, 9, 11 | raw × 7.58 |
| Disorientation (D) | 5, 8, 10, 11, 12, 13, 14 | raw × 13.92 |
| Total Severity (TSC) | (N_raw + O_raw + D_raw) | × 3.74 |

Change scores: `Delta_X = Post_X − Pre_X`. Positive = symptoms increased during viewing.

## 3. Descriptive statistics

### Table 1 — Overall pre → post change (participant means, n = 36)

| Outcome | PRE M (SD) | POST M (SD) | Δ M (SD) | Δ 95% CI | *t*(35) | *p*_holm | *d*z | Change |
|---|---|---|---|---|---|---|---|---|
| **TSC** | 9.55 (15.92) | 17.98 (19.86) | **+8.44** (9.38) | [5.27, 11.61] | 5.40 | <.001 | 0.90 | +88% |
| Nausea | 5.27 (9.32) | 8.54 (9.88) | +3.27 (5.89) | [1.28, 5.26] | 3.33 | .004 | 0.55 | +62% |
| Oculomotor | 8.70 (14.36) | 16.45 (19.28) | +7.74 (9.49) | [4.53, 10.95] | 4.90 | <.001 | 0.82 | +89% |
| Disorientation | 11.86 (21.90) | 24.27 (26.88) | +12.42 (13.92) | [7.71, 17.13] | 5.35 | <.001 | 0.89 | +105% |

Wilcoxon signed-rank tests agree with every row. **The answer to the first high-level question is unambiguous: SSQ values rise from PRE to POST.**

### Table 2 — By method, collapsed across video

| Method | PRE TSC | POST TSC | **Δ TSC** | Δ 95% CI |
|---|---|---|---|---|
| ROF | 9.90 (18.65) | 18.91 (21.18) | **+9.00** (9.56) | [5.77, 12.24] |
| Minimap | 9.38 (15.02) | 18.46 (20.51) | **+9.07** (11.39) | [5.22, 12.93] |
| Path Overlay | 9.35 (19.45) | 16.59 (21.59) | **+7.24** (12.60) | [2.98, 11.50] |

The three methods start from effectively identical pre-trial levels (9.9 / 9.4 / 9.4) — so, unlike the cautionary case in the brief, the post-exposure ordering here is **not** an artefact of differing baselines. The Δ values still differ by less than 2 TSC points.

### Table 3 — By video, collapsed across method

| Video | PRE TSC | POST TSC | **Δ TSC** | Δ 95% CI |
|---|---|---|---|---|
| **Walking** | 9.04 (15.11) | 22.13 (21.00) | **+13.09** (11.88) | [9.07, 17.11] |
| Cycling | 9.70 (17.73) | 16.48 (21.01) | +6.79 (12.11) | [2.69, 10.89] |
| Driving | 9.90 (17.94) | 15.34 (19.38) | +5.44 (11.46) | [1.56, 9.31] |

Full Method × Video cell means for all four outcomes: `tables/t4_method_x_video.csv`.

### Trial-level distribution of Δ TSC

| Method | Worse | Unchanged | Better | % worse | Median Δ [IQR] |
|---|---|---|---|---|---|
| ROF | 59 | 38 | 11 | 54.6% | 3.74 [0.0, 15.0] |
| Minimap | 61 | 37 | 10 | 56.5% | 3.74 [0.0, 18.7] |
| Path | 53 | 42 | 13 | 49.1% | 0.00 [0.0, 15.0] |

SSQ data are strongly zero-inflated: PRE TSC = 0 in 203 of 324 trials, POST TSC = 0 in 117.

## 4. Baseline / pre-trial state analysis

**Pre-trial symptom level did not differ by method or by video.** A 3 × 3 RM-ANOVA on the PRE scores alone returned nothing approaching significance on any outcome (Method: all *p* ≥ .77; Video: all *p* ≥ .62; Method × Video: all *p* ≥ .62; all η²_G ≤ .003; `tables/t5_pre_anova.csv`).

This is the key licence for the rest of the analysis: because participants entered ROF, Minimap and Path trials equally symptomatic, differences in POST scores can be read as differences in what the trial added — and the change-score and raw-score analyses must agree, which they do.

## 5. Primary analysis — 2 (Time) × 3 (Method) × 3 (Video) RM-ANOVA

Greenhouse–Geisser corrected; generalized η²; Holm-corrected across the four SSQ DVs within each effect family. Full table: `tables/t7_primary_anova.csv`.

### Table 4 — The four effects of interest

| Effect | Outcome | *F* | df | *p* | *p*_holm | η²_G |
|---|---|---|---|---|---|---|
| **Time** | TSC | **29.15** | 1, 35 | <.001 | **<.001** | .036 |
| | Nausea | **11.08** | 1, 35 | .002 | **.002** | .015 |
| | Oculomotor | **23.97** | 1, 35 | <.001 | **<.001** | .036 |
| | Disorientation | **28.64** | 1, 35 | <.001 | **<.001** | .041 |
| **Time × Method** | TSC | 0.67 | 1.48, 51.97 | .473 | 1.000 | .000 |
| *(primary effect)* | Nausea | 0.42 | 1.72, 60.36 | .626 | 1.000 | .000 |
| | Oculomotor | 0.78 | 1.66, 58.08 | .443 | 1.000 | .001 |
| | Disorientation | 0.61 | 1.74, 60.88 | .525 | 1.000 | .000 |
| **Time × Video** | TSC | **7.73** | 1.79, 62.72 | .001 | **.004** | .006 |
| | Nausea | 2.93 | 1.99, 69.73 | .060 | .060 | .005 |
| | Oculomotor | **9.61** | 1.91, 66.75 | <.001 | **.001** | .006 |
| | Disorientation | **6.91** | 1.59, 55.56 | .004 | **.008** | .005 |
| **Time × Method × Video** | TSC | 0.57 | 2.84, 99.30 | .629 | 1.000 | .001 |
| | Nausea | 0.46 | 2.85, 99.90 | .704 | 1.000 | .002 |
| | Oculomotor | 0.99 | 2.69, 94.29 | .395 | 1.000 | .002 |
| | Disorientation | 0.46 | 3.01, 105.48 | .710 | 1.000 | .001 |

Method and Video **main** effects (which mix pre-trial state with exposure and so are interpreted cautiously): Method was null on every outcome (all *p*_holm = 1.000); Video reached significance for Oculomotor (*p*_holm = .021) and was marginal for TSC (*p*_holm = .101). Because pre-trial scores are balanced (§4), these main effects carry no information beyond the Time interactions.

**Simple effect of Time within each method** (Bonferroni): all three methods produced a significant rise — ROF +9.00 [5.77, 12.24], *t*(35) = 5.65; Minimap +9.07; Path +7.24. No method held sickness flat.

## 6. Change-score (Δ) analysis

The 3 × 3 RM-ANOVA on Δ scores reproduces the primary model's Time interactions **exactly** — every *F* matches to 4 decimal places (verified in §4.B of the results file), as it must for a complete balanced within-subject design. The two analyses are the same test, so they cannot disagree, and the Δ framing is simply the more interpretable presentation.

| Effect | TSC | Nausea | Oculomotor | Disorientation |
|---|---|---|---|---|
| Method | *F* = 0.67, *p* = .473 | 0.42, .626 | 0.78, .443 | 0.61, .525 |
| **Video** | ***F* = 7.73, *p* = .001** | 2.93, .060 | **9.61, <.001** | **6.91, .004** |
| Method × Video | *F* = 0.57, *p* = .629 | 0.46, .704 | 0.99, .395 | 0.46, .710 |

## 7. Pairwise comparisons

### Method — reported for completeness; the omnibus effect does not license them

| Contrast | Δ difference | 95% CI | *d*z | *p* (Bonf.) |
|---|---|---|---|---|
| ROF − Minimap | −0.07 | [−3.24, 3.10] | −0.01 | 1.000 |
| ROF − Path | +1.77 | [−1.19, 4.72] | +0.20 | 0.699 |
| Minimap − Path | +1.84 | [−2.75, 6.42] | +0.14 | 1.000 |

Nothing approaches significance on any subscale (`study2_results.txt` §4.D).

### Video — the effect that does license post-hocs

| Contrast | Δ TSC difference | 95% CI | *d*z | *p* (Bonf.) |
|---|---|---|---|---|
| **Walking − Cycling** | **+6.30** | [2.00, 10.61] | 0.61 | **.002** |
| **Walking − Driving** | **+7.65** | [2.27, 13.04] | 0.60 | **.003** |
| Cycling − Driving | +1.35 | [−4.51, 7.22] | 0.10 | 1.000 |

The same pattern holds for Oculomotor (*p* = .002 / .002) and Disorientation (*p* < .001 / .007); Nausea shows the same direction but does not survive correction. **Walking is the outlier; Cycling and Driving are indistinguishable.**

### How informative is the null Method effect?

A null is only meaningful if the study could have detected something worth detecting.

| Contrast | Observed Δ diff | 95% CI | Min. detectable diff (80% power) |
|---|---|---|---|
| ROF − Minimap | −0.07 | [−3.24, 3.10] | 4.50 TSC |
| ROF − Path | +1.77 | [−1.19, 4.72] | 4.19 TSC |
| Minimap − Path | +1.84 | [−2.75, 6.42] | 6.52 TSC |

Equivalence tests (TOST): against a ±5 TSC bound, ROF ≡ Minimap (*p* = .002) and ROF ≡ Path (*p* = .016) are statistically equivalent; Minimap ≡ Path is not (*p* = .085). Against a ±15 TSC bound — the size of the method-vs-baseline reductions found in Study 1 — **all three pairs are equivalent (*p* < .001)**.

**Interpretation:** the data rule out method differences of the magnitude Study 1 reported between conditions. They do not establish exact equivalence, and they cannot exclude differences of ~2–6 TSC points.

## 8. Trial-order and carryover analysis

Counterbalancing was **exact**: six method orders × 6 participants each; six video orders × 18 blocks each; every method appeared 12 times in each block position and every video 36 times in each within-block position.

That protects against confounding — but, as the brief correctly insists, it does not prove carryover is absent. It is not.

### Pre-trial TSC by trial number

| Trial | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| Mean PRE TSC | 20.78 | 4.68 | 7.27 | 6.86 | 7.27 | 9.14 | 9.35 | 9.56 | 11.01 |

One-way RM-ANOVA: *F*(2.72, 95.24) = 4.07, *p* = .011, η²_G = .044.

The shape is **not** a simple rise. Trial 1 sits far above everything else because 8 of 36 participants arrived with symptoms already present, before any VR exposure (max PRE TSC = 157). For several of them the first trial's Δ is strongly *negative* — they felt better afterwards. Consequently the overall linear trend is non-significant (*p* = .543) while the quadratic is significant (*p* = .006).

**From trial 2 onward the climb is steady: 4.68 → 11.01, a 2.4-fold increase.**

### Direct test of residual sickness

Does the POST score at trial *t*−1 predict the PRE score at trial *t*? (288 consecutive pairs, random intercept per participant):

| Model | PrevPost_TSC *b* (SE) | TrialNumber *b* (SE) | Recovery min *b* (SE) |
|---|---|---|---|
| `Pre ~ PrevPost` | **0.389 (0.038)**, *p* < .001 | — | — |
| `+ TrialNumber` | **0.399 (0.037)**, *p* < .001 | **+0.973 (0.233)**, *p* < .001 | — |
| `+ RecoveryMinutes` | **0.399 (0.037)**, *p* < .001 | **+0.978 (0.238)**, *p* < .001 | −0.015 (0.142), *p* = .916 |

Mean within-participant *r*(Pre_t, Post_t−1) = 0.333, *p* = .002.

**Roughly 40% of the sickness a participant finished a trial with was still present when the next trial began**, and an *additional* ~1 TSC point accumulated per trial beyond that. The median inter-trial gap was 6.3 min (IQR 5.1–7.3) and — importantly — longer gaps did **not** predict lower pre-scores, so within the range used, waiting longer did not help.

Block position (*p* = .343) and between-subject method-order group (*p* = .624) showed no effect on PRE TSC, and adding either to the models leaves the Method conclusion unchanged (§9).

## 9. Mixed-model sensitivity analysis

`Post_X ~ Pre_X + Method × Video + TrialNumber + (1 | Participant)`, REML, Satterthwaite df.

**Random-effects structure.** A random slope for Method was **singular** and not supported (LRT *p* = .835). A random slope for TrialNumber was non-singular and marginally favoured by AIC (2628.7 vs 2630.7) but not by BIC (2685.5 vs 2679.8) nor by the LRT (*p* = .052). The random-intercept model was therefore retained — the parsimonious choice that the data clearly support. Participant ICCs were substantial (0.50–0.65), confirming that clustering had to be modelled.

### Table 5 — Mixed-model effects (Holm across the four outcomes)

| Outcome | Pre score | Method | Video | TrialNumber | Method × Video |
|---|---|---|---|---|---|
| TSC | *F* = 30.65, **<.001** | 0.99, .373 | 10.13, **<.001** | 4.16, .042 (holm .127) | 0.95, .437 |
| Nausea | 4.24, **.040** | 1.15, .317 | 5.58, **.004** | 0.26, .614 | 1.39, .239 |
| Oculomotor | 38.49, **<.001** | 1.22, .298 | 11.26, **<.001** | 6.13, .014 (holm .056) | 1.23, .300 |
| Disorientation | 50.25, **<.001** | 0.46, .635 | 6.40, **.002** | 4.13, .043 (holm .127) | 0.61, .657 |

**The Method conclusion is unchanged after adjusting for pre-trial symptom level, trial progression and within-participant clustering.** Adding block position or method-order group moves nothing (Method *p* = .372 and .371 respectively).

## 10. Assumption checks and robustness

**Distributions.** Δ scores are zero-inflated (36–60% exact zeros) and heavy-tailed (excess kurtosis 2.5–21.4). Residual normality is formally rejected for every model (Shapiro–Wilk *p* < .001; *W* = 0.85–0.89 for the ANOVA residuals, 0.90–0.95 for the mixed-model residuals). See `fig6_residual_diagnostics.png`.

This is expected of SSQ data and is not by itself grounds to discard RM-ANOVA at n = 36 — but it does oblige a robustness check, so the conclusion was re-derived four independent ways:

| Check | Method effect | Video effect |
|---|---|---|
| Primary RM-ANOVA | *F* = 0.67, *p* = .473 | *F* = 7.73, **p = .001** |
| Rank-transformed RM-ANOVA (within-participant ranks) | *F* = 0.83, *p* = .438 | *F* = 13.38, **p < .001**, η²_G = .081 |
| Friedman (participant means) | χ²(2) = 3.66, *p* = .160, *W* = .051 | χ²(2) = 13.39, **p = .001** |
| Mixed model, outliers excluded | *F* = 0.81, *p* = .444 | *F* = 7.12, **p < .001** |

Bootstrap 95% CIs (10 000 participant resamples) for the pairwise method differences all include zero: ROF−Minimap [−3.01, 3.08], ROF−Path [−1.14, 4.57], Minimap−Path [−2.63, 6.23].

**Extreme observations.** Five of 324 trials (1.5%) fall outside a 3×IQR fence on Δ TSC. **None were deleted.** Re-running with them excluded leaves both conclusions intact (table above), and the Method EMMs barely move (8.51 / 9.66 / 7.24 vs 9.00 / 9.07 / 7.24). Excluding P07's late-submitted trial likewise changes nothing (Method *p* = .680).

**Sphericity.** Greenhouse–Geisser applied throughout; Mauchly tests reported in `study2_results.txt` §3.C.

## 11. Supplementary — Presence

The five-item Presence scale (Cronbach's α = .784) shows **no difference between methods**: ROF 5.10 [4.88, 5.31], Minimap 5.12 [4.90, 5.34], Path 5.04 [4.81, 5.27]; *F*(1.84, 64.48) = 0.25, *p* = .758, η²_G = .001. Video and Method × Video are also null. Presence was uncorrelated with symptom increase (*r* = −.04, *p* = .825).

This matters for the Study 1 narrative: Study 1's central trade-off was that **Dynamic FOV** bought the largest TSC reduction at a significant cost in Presence. **Study 2 contains no Dynamic FOV condition, and none of its three methods incurs a Presence penalty.** All three sit near 5.1 on the 1–7 scale.

## 12. Interpretation

**What the evidence supports.**

- Viewing these 360° videos induces VIMS reliably and at meaningful magnitude — SSQ roughly doubles, with the largest relative rise in Disorientation (+105%).
- **Reverse Optical Flow, Minimap and Path Overlay are not distinguishable from one another** in how much sickness they allow a trial to induce. Every analysis agrees, the effect sizes are near zero (*d*z ≤ 0.20), and differences larger than ~5–7 TSC points are inconsistent with the data.
- **Camera motion type dominates.** Walking induced 2.4× the symptom increase of Driving. The high-frequency oscillatory camera motion of handheld/head-mounted walking footage appears to be the driver, rather than the translational speed of the depicted motion — Driving, the fastest depicted motion, was the *least* provocative.
- **The effect of method does not depend on video type** (Time × Method × Video null everywhere): no method was selectively better for the hard case. Descriptively, Walking was the worst cell for all three methods (Δ = +15.9 / +13.1 / +10.3).

**What the evidence does not support.**

- Because Study 2 has **no unmodified baseline condition**, nothing here shows that any of these methods reduces sickness relative to unmitigated 360° video. The null Time × Method effect is equally consistent with "all three work about equally well" and "none of them does much" — those hypotheses cannot be separated without a baseline. Any claim of the form *"ROF reduces sickness compared with unmodified VR"* is unsupported by this dataset.
- Path Overlay has the numerically smallest increase (+7.24 vs +9.00 and +9.07) and the lowest share of trials that got worse (49% vs 55–57%). This is a **descriptive observation, not a finding** — the CI spans −1.2 to +6.4 against ROF.

**On baselines and absolute levels.** The brief's cautionary case — a method looking good only because its participants started lower — does not arise here: pre-trial scores were statistically identical across methods (9.9 / 9.4 / 9.4). The three levels the brief asks to be kept distinct behave as follows: *starting symptom level* was equal across methods but rose across the session; *symptoms induced during the video* differed by video type but not by method; *absolute post-exposure sickness* tracked the other two and adds no independent ordering.

## 13. Comparison with Study 1

| | Study 1 | Study 2 |
|---|---|---|
| Conditions | 4 methods (incl. Baseline) × 3 videos | 3 methods (no baseline) × 3 videos |
| SSQ timing | post-trial only | **pre *and* post every trial** |
| Method effect on SSQ | **significant**, *F*(2.6, 91.2) = 9.02, *p* < .001, η²_G = .043 | **null**, *F*(1.48, 52.0) = 0.67, *p* = .473, η²_G = .000 |
| Video effect | null, *F*(1.7, 60.1) = 1.51, *p* = .230 | **significant**, *F*(1.79, 62.7) = 7.73, *p*_holm = .004 |
| Method × Video | null | null (agrees) |
| Presence | **differed by method** (Dynamic FOV significantly lower) | **no difference** (all ≈ 5.1) |
| Absolute POST TSC | 42–78 | **15–26** |

Three differences deserve to be stated explicitly rather than smoothed over:

1. **The Method effect reverses.** Study 1's significant method effect was driven entirely by *mitigation vs Baseline*; its own post-hocs found **no significant differences among Dynamic FOV, Minimap and Overlay Path**. Study 2 removed Baseline and compared only the mitigation methods — and found nothing. **The two studies are therefore consistent**, not contradictory: both say the mitigation methods do not differ from each other. Study 2 adds that this holds for the *induced change*, not just the post-exposure level, and adds ROF to the set.

2. **The Video effect reverses — and this is a genuine new finding.** Study 1 found no effect of video type (*p* = .230), though Walking was numerically highest for Baseline (78 vs 68/68). Study 2 detects it clearly. The likely reason is measurement, not population: subtracting each trial's own pre-score removes a large source of between-trial noise (participant drift across a 90-minute session), and the change score is a far more sensitive instrument than the post-score alone. **Pre/post measurement is what made the video effect visible.**

3. **Absolute sickness is 3–4× lower in Study 2** (POST TSC 15–26 vs 42–78). This gap is too large to be sampling noise and points to a protocol difference — shorter or less provocative clips, different hardware, or different instructions. It has a direct bearing on interpretation: **a floor effect is a live alternative explanation for the null Method result.** With sickness this mild, the methods may simply have had little to do. Study 1's method effects, by contrast, were measured in a regime where baseline TSC reached ~72.

## 14. Limitations

1. **No baseline condition.** The single most important limitation. Without unmitigated 360° video, absolute efficacy is unmeasurable; only relative comparison among the three methods is possible.
2. **Possible floor effect.** POST TSC of 15–26 is mild, and much lower than Study 1's. A null difference between methods is harder to interpret when there is little sickness to prevent.
3. **Carryover is present and substantial.** ~40% of each trial's end-state persisted into the next trial, plus ~1 TSC point per trial of accumulation, and longer inter-trial gaps did not help within the 5–7 min range used. Counterbalancing distributes this evenly across methods, so it does not bias the Method comparison, but it inflates error variance and reduces power — a real cost to the null result's precision.
4. **Trial 1 is not a clean baseline.** 8 of 36 participants arrived already symptomatic, and their first trial often shows improvement, complicating any "pre-exposure resting state" interpretation.
5. **Non-normal, zero-inflated residuals.** Mitigated by four convergent robustness checks, but the parametric *p*-values should not be read to three decimals.
6. **Participant identity rests on free-text names.** Reconstruction was unambiguous and independently validated by the design structure, but a participant-code field would remove the need for judgement entirely.
7. **Trial order reconstructed from form timestamps**, not logged directly. It is corroborated by all 36 participants showing clean three-trial method blocks, but three participants submitted some POST forms out of order and one submitted a POST form 35 days late (retained, per instruction; excluding it changes nothing).
8. **One participant's POST video labels were mis-entered** and were repaired from the PRE record (§1).
9. **No preference or qualitative data** in this dataset, so the polarisation and glance-cost themes from Study 1's interviews cannot be revisited.

## 15. Conclusions

1. Watching these 360° videos **roughly doubled** SSQ Total Severity (+8.4 points, +88%, *d*z = 0.90); the effect was significant on all four SSQ outcomes.
2. **The primary hypothesis was not supported.** Reverse Optical Flow, Minimap and Path Overlay produced statistically indistinguishable pre→post increases (Time × Method null on all four outcomes, η²_G ≤ .001). The data exclude differences larger than ~5–7 TSC points.
3. **Video type mattered more than method.** Walking induced ~2.4× the symptom increase of Driving (Time × Video, Holm *p* = .004); Cycling and Driving were indistinguishable. This effect was invisible in Study 1 and is surfaced here by the pre/post design.
4. **No method was differentially suited to any video type** (three-way interaction null).
5. **Symptoms did not clear between trials**: previous-trial POST predicted next-trial PRE (*b* = 0.39, *p* < .001), with ~1 TSC point of additional accumulation per trial and no benefit from longer rests. **Future protocols in this line should lengthen or actively verify recovery, and should keep collecting pre-trial SSQ.**
6. **Presence was unaffected by method** (all ≈ 5.1/7), so the sickness/Presence trade-off Study 1 found for Dynamic FOV does not appear among these three methods.
7. Because Study 2 has no baseline, **the practical recommendation is that the choice among these three techniques can be made on grounds other than VIMS reduction** — implementation cost, aesthetics, task fit — since none of them distinguishes itself on symptom increase. Establishing whether any of them beats unmitigated video requires a study that includes a baseline condition.

---

### Figures

| File | Content |
|---|---|
| `fig1_pre_post_tsc_by_method.png` | **Figure 1** — PRE vs POST TSC by method, paired participant means with 95% CI |
| `fig2_delta_tsc_method_x_video.png` | **Figure 2** — Δ TSC by Method × Video |
| `fig3_delta_subscales_by_method.png` | **Figure 3** — Δ Nausea / Oculomotor / Disorientation by method |
| `fig4_pre_tsc_across_trials.png` | **Figure 4** — PRE TSC across trials 1–9 (carryover) |
| `fig5_pre_post_all_cells.png` | Figure 5 — PRE→POST in all nine Method × Video cells |
| `fig6_residual_diagnostics.png` | Figure 6 — Q–Q plots and Δ-score distributions |
| `fig7_carryover_scatter.png` | Figure 7 — POST(*t*−1) vs PRE(*t*) residual-sickness scatter |
| `fig8_presence_by_method.png` | Figure 8 — Presence by method (supplementary) |
| `fig9_delta_tsc_by_video.png` | Figure 9 — Δ TSC by video type (the significant effect) |

### Tables for LaTeX

`tables/t1_overall_pre_post.csv` · `t2_by_method.csv` · `t3_by_video.csv` · `t4_method_x_video.csv` · `t5_pre_anova.csv` · `t6_pre_tsc_by_trial.csv` · `t7_primary_anova.csv` · `t8_delta_anova.csv` · `t9_mixed_models.csv` · `t10_presence.csv` · `t11_precision_equivalence.csv`
