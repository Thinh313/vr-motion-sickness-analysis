# QC Report: Presence/SSQ Data Normalization

Generated: 2026-03-11T22:26:32.010912

## Summary
- Total records: 432
- From cohort_01 (23 users): 276
- From cohort_02 (13 users): 156

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
- ssq_n_raw: mean=3.29, sd=2.80, min=0.00, max=20.00
- ssq_o_raw: mean=6.80, sd=4.69, min=0.00, max=21.00
- ssq_d_raw: mean=5.42, sd=4.19, min=0.00, max=21.00
- ssq_n: mean=31.42, sd=26.67, min=0.00, max=190.80
- ssq_o: mean=51.57, sd=35.55, min=0.00, max=159.18
- ssq_d: mean=75.43, sd=58.34, min=0.00, max=292.32
- ssq_tsc: mean=58.03, sd=41.14, min=0.00, max=231.88

## overall_sickness_severity Check
- Column present in output: False [PASS]

## Validation Issues
- None. All checks passed.

## Output Files
- [x] survey_normalized_combined_36_users.csv
- [x] presence_dataset.csv
- [x] ssq_dataset.csv
