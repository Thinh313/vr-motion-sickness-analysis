"""
Normalize + Merge + Split: all_data.csv + data_2.csv
=====================================================
Output:
  - merged_normalized.csv  (intermediate)
  - presence_dataset.csv   (context + 5 Presence cols, 1-7)
  - ssq_dataset.csv        (context + 16 SSQ items + Kennedy subscale scores)
  - qc_report.md           (quality check report)

Rules:
  - method_experienced: Baseline, Dynamic FOV, Minimap, Overlay Path
  - video_experienced: Walking, Cycling, Driving
  - vr_experience_before: yes / no
  - Presence Likert 1-7 (Vietnamese text -> numeric)
  - SSQ 0-3 (already numeric)
  - overall_sickness_severity is DROPPED entirely
"""

import pandas as pd
import sys
from pathlib import Path
from datetime import datetime

# ─── Constants ──────────────────────────────────────────────────────
PRESENCE_LIKERT_MAP = {
    "Hoàn toàn không đồng ý": 1,
    "Không đồng ý": 2,
    "Hơi không đồng ý": 3,
    "Trung lập": 4,
    "Hơi đồng ý": 5,
    "Đồng ý": 6,
    "Hoàn toàn đồng ý": 7,
}

METHOD_MAP_D1 = {
    "B": "Baseline",
    "D": "Dynamic FOV",
    "M": "Minimap",
    "O": "Overlay Path",
}

VIDEO_MAP_D1 = {
    "walk": "Walking",
    "cycl": "Cycling",
    "driv": "Driving",
}

VR_EXP_MAP_D1 = {
    "1": "yes",
    "0": "no",
}

# data_2 has "Overlay" instead of "Overlay Path"
METHOD_MAP_D2 = {
    "Baseline": "Baseline",
    "Dynamic FOV": "Dynamic FOV",
    "Minimap": "Minimap",
    "Overlay": "Overlay Path",
}

VR_EXP_MAP_D2 = {
    "Có": "yes",
    "Chưa": "no",
}

# Standardized column names
PRESENCE_COLS = [
    "presence_env_video",
    "focus_env_video",
    "control_attention",
    "presence_virtual_space",
    "unaware_real_env",
]

SSQ_COLS = [
    "general_discomfort",
    "fatigue",
    "headache",
    "eye_strain",
    "difficulty_focusing",
    "increased_salivation",
    "sweating",
    "nausea",
    "difficulty_concentrating",
    "fullness_head",
    "blurred_vision",
    "dizzy_eyes_open",
    "dizzy_eyes_closed",
    "vertigo",
    "stomach_awareness",
    "burping",
]

# Kennedy 1993 Table 4 — SSQ subscale item mapping
# Each subscale has 7 items; some items belong to multiple subscales
SSQ_NAUSEA_ITEMS = [
    "general_discomfort",
    "increased_salivation",
    "sweating",
    "nausea",
    "difficulty_concentrating",
    "stomach_awareness",
    "burping",
]

SSQ_OCULOMOTOR_ITEMS = [
    "general_discomfort",
    "fatigue",
    "headache",
    "eye_strain",
    "difficulty_focusing",
    "difficulty_concentrating",
    "blurred_vision",
]

SSQ_DISORIENTATION_ITEMS = [
    "difficulty_focusing",
    "nausea",
    "fullness_head",
    "blurred_vision",
    "dizzy_eyes_open",
    "dizzy_eyes_closed",
    "vertigo",
]

# Kennedy 1993 Table 4 — Weight factors
SSQ_WEIGHT_N = 9.54
SSQ_WEIGHT_O = 7.58
SSQ_WEIGHT_D = 13.92
SSQ_WEIGHT_TSC = 3.74

# Kennedy subscale output columns
SSQ_KENNEDY_COLS = [
    "ssq_n_raw", "ssq_o_raw", "ssq_d_raw",
    "ssq_n", "ssq_o", "ssq_d", "ssq_tsc",
]

CONTEXT_COLS = [
    "timestamp",
    "full_name",
    "vr_experience_before",
    "video_experienced",
    "method_experienced",
]

METHOD_WHITELIST = {"Baseline", "Dynamic FOV", "Minimap", "Overlay Path"}
VIDEO_WHITELIST = {"Walking", "Cycling", "Driving"}
VR_EXP_WHITELIST = {"yes", "no"}


# ─── Helpers ────────────────────────────────────────────────────────
def safe_parse_timestamp(ts: str) -> str:
    """Try multiple timestamp formats, return ISO string or raw if all fail."""
    ts = ts.strip()
    formats = [
        "%Y/%m/%d %I:%M:%S %p GMT+7",
        "%m/%d/%Y %H:%M:%S",
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%d %H:%M:%S",
        "%d/%m/%Y %H:%M:%S",
        "%m/%d/%Y %I:%M:%S %p",
    ]
    for fmt in formats:
        try:
            return datetime.strptime(ts, fmt).isoformat()
        except ValueError:
            continue
    # Return raw timestamp if no format matches
    return ts


def compute_kennedy_scores(df: pd.DataFrame) -> pd.DataFrame:
    """Compute Kennedy 1993 Table 4 weighted SSQ subscale scores.

    Adds columns: ssq_n_raw, ssq_o_raw, ssq_d_raw, ssq_n, ssq_o, ssq_d, ssq_tsc
    """
    # Raw subscale sums (sum of item scores 0-3 for each subscale's 7 items)
    # min_count ensures NaN propagation if any item is missing (no silent partial sums)
    df["ssq_n_raw"] = df[SSQ_NAUSEA_ITEMS].sum(axis=1, min_count=len(SSQ_NAUSEA_ITEMS))
    df["ssq_o_raw"] = df[SSQ_OCULOMOTOR_ITEMS].sum(axis=1, min_count=len(SSQ_OCULOMOTOR_ITEMS))
    df["ssq_d_raw"] = df[SSQ_DISORIENTATION_ITEMS].sum(axis=1, min_count=len(SSQ_DISORIENTATION_ITEMS))

    # Weighted subscale scores (Kennedy 1993 Table 4)
    df["ssq_n"] = df["ssq_n_raw"] * SSQ_WEIGHT_N
    df["ssq_o"] = df["ssq_o_raw"] * SSQ_WEIGHT_O
    df["ssq_d"] = df["ssq_d_raw"] * SSQ_WEIGHT_D

    # Total Severity Count: sum of ALL three raw subscale sums × 3.74
    df["ssq_tsc"] = (df["ssq_n_raw"] + df["ssq_o_raw"] + df["ssq_d_raw"]) * SSQ_WEIGHT_TSC

    return df


# ─── Load & Normalize all_data.csv (source 1) ──────────────────────
def load_source_1(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, dtype=str)
    df.columns = df.columns.str.strip()

    # Rename columns already in standard names
    # Map categories
    df["method_experienced"] = df["method_experienced"].str.strip().map(METHOD_MAP_D1)
    df["video_experienced"] = df["video_experienced"].str.strip().map(VIDEO_MAP_D1)
    df["vr_experience_before"] = df["vr_experience_before"].str.strip().map(VR_EXP_MAP_D1)

    # Parse timestamp
    df["timestamp"] = df["timestamp"].apply(safe_parse_timestamp)

    # Presence: already numeric 1-7, just convert
    for col in PRESENCE_COLS:
        df[col] = df[col].str.strip().astype(int)

    # SSQ: already numeric 0-3
    for col in SSQ_COLS:
        df[col] = df[col].str.strip().astype(int)

    # Compute Kennedy 1993 weighted SSQ subscale scores
    df = compute_kennedy_scores(df)

    # Drop overall_sickness_severity and extra columns
    drop_cols = [c for c in ["overall_sickness_severity", "presence_scene", "overall_video_experience"] if c in df.columns]
    df = df.drop(columns=drop_cols)

    # Keep only needed columns
    df["source"] = "all_data"
    return df[CONTEXT_COLS + PRESENCE_COLS + SSQ_COLS + SSQ_KENNEDY_COLS + ["source"]]


# ─── Load & Normalize data_2.csv (source 2) ────────────────────────
def load_source_2(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, dtype=str)
    df.columns = df.columns.str.strip()

    # Column mapping from Vietnamese to standard
    col_map = {}

    # Find columns by position/content
    orig_cols = list(df.columns)

    # Context columns
    col_map[orig_cols[0]] = "timestamp"          # Timestamp
    col_map[orig_cols[1]] = "full_name"          # Tên đầy đủ
    col_map[orig_cols[2]] = "vr_experience_before"  # VR experience
    col_map[orig_cols[3]] = "video_experienced"  # Video
    col_map[orig_cols[4]] = "method_experienced" # Method

    # Presence columns (indices 5-9)
    for i, pres_col in enumerate(PRESENCE_COLS):
        col_map[orig_cols[5 + i]] = pres_col

    # SSQ columns (indices 10-25)
    for i, ssq_col in enumerate(SSQ_COLS):
        col_map[orig_cols[10 + i]] = ssq_col

    # Rename
    df = df.rename(columns=col_map)

    # Map categories
    df["method_experienced"] = df["method_experienced"].str.strip().map(METHOD_MAP_D2)
    df["video_experienced"] = df["video_experienced"].str.strip()  # Already correct names
    df["vr_experience_before"] = df["vr_experience_before"].str.strip().map(VR_EXP_MAP_D2)

    # Parse timestamp
    df["timestamp"] = df["timestamp"].apply(safe_parse_timestamp)

    # Presence: text -> numeric via Likert map
    for col in PRESENCE_COLS:
        df[col] = df[col].str.strip().map(PRESENCE_LIKERT_MAP)
        unmapped = df[col].isna().sum()
        if unmapped > 0:
            print(f"WARNING: {unmapped} unmapped Presence values in {col}")

    # SSQ: already numeric 0-3
    for col in SSQ_COLS:
        df[col] = df[col].str.strip().astype(int)

    # Compute Kennedy 1993 weighted SSQ subscale scores
    df = compute_kennedy_scores(df)

    # Drop extra columns (Cột 1, etc.)
    df["source"] = "data_2"
    return df[CONTEXT_COLS + PRESENCE_COLS + SSQ_COLS + SSQ_KENNEDY_COLS + ["source"]]


# ─── Validation ─────────────────────────────────────────────────────
def validate(df: pd.DataFrame) -> list[str]:
    """Run validation checks, return list of issues."""
    issues = []

    # Category whitelist
    bad_method = set(df["method_experienced"].dropna().unique()) - METHOD_WHITELIST
    if bad_method:
        issues.append(f"Invalid method_experienced values: {bad_method}")

    bad_video = set(df["video_experienced"].dropna().unique()) - VIDEO_WHITELIST
    if bad_video:
        issues.append(f"Invalid video_experienced values: {bad_video}")

    bad_vr = set(df["vr_experience_before"].dropna().unique()) - VR_EXP_WHITELIST
    if bad_vr:
        issues.append(f"Invalid vr_experience_before values: {bad_vr}")

    # Presence range 1-7
    for col in PRESENCE_COLS:
        out_of_range = df[(df[col] < 1) | (df[col] > 7)]
        if len(out_of_range) > 0:
            issues.append(f"Presence col {col} has {len(out_of_range)} values outside 1-7")

    # SSQ range 0-3
    for col in SSQ_COLS:
        out_of_range = df[(df[col] < 0) | (df[col] > 3)]
        if len(out_of_range) > 0:
            issues.append(f"SSQ col {col} has {len(out_of_range)} values outside 0-3")

    # Kennedy subscale raw score validation
    # Each subscale has 7 items scored 0-3, so raw range is 0-21
    for name, items in [("N", SSQ_NAUSEA_ITEMS), ("O", SSQ_OCULOMOTOR_ITEMS), ("D", SSQ_DISORIENTATION_ITEMS)]:
        raw_col = f"ssq_{name.lower()}_raw"
        expected_raw = df[items].sum(axis=1, min_count=len(items))
        mismatch = (df[raw_col] != expected_raw).sum()
        if mismatch > 0:
            issues.append(f"{raw_col} mismatch in {mismatch} rows")
        out_of_range = df[(df[raw_col] < 0) | (df[raw_col] > 21)]
        if len(out_of_range) > 0:
            issues.append(f"{raw_col} has {len(out_of_range)} values outside 0-21")

    # Kennedy weighted score validation
    for name, weight, raw_col in [("N", SSQ_WEIGHT_N, "ssq_n_raw"),
                                    ("O", SSQ_WEIGHT_O, "ssq_o_raw"),
                                    ("D", SSQ_WEIGHT_D, "ssq_d_raw")]:
        weighted_col = f"ssq_{name.lower()}"
        expected = df[raw_col] * weight
        mismatch = (abs(df[weighted_col] - expected) > 0.01).sum()
        if mismatch > 0:
            issues.append(f"{weighted_col} mismatch in {mismatch} rows")

    # TSC validation
    expected_tsc = (df["ssq_n_raw"] + df["ssq_o_raw"] + df["ssq_d_raw"]) * SSQ_WEIGHT_TSC
    tsc_mismatch = (abs(df["ssq_tsc"] - expected_tsc) > 0.01).sum()
    if tsc_mismatch > 0:
        issues.append(f"ssq_tsc mismatch in {tsc_mismatch} rows")

    # No NaN in key columns
    for col in CONTEXT_COLS + PRESENCE_COLS + SSQ_COLS + SSQ_KENNEDY_COLS:
        na_count = df[col].isna().sum()
        if na_count > 0:
            issues.append(f"Column {col} has {na_count} NaN values")

    return issues


# ─── QC Report ──────────────────────────────────────────────────────
def generate_qc_report(df: pd.DataFrame, issues: list[str], output_path: str):
    """Generate QC report markdown."""
    lines = [
        "# QC Report: Presence/SSQ Data Normalization",
        f"\nGenerated: {datetime.now().isoformat()}",
        "",
        "## Summary",
        f"- Total records: {len(df)}",
        f"- From all_data.csv: {len(df[df['source'] == 'all_data'])}",
        f"- From data_2.csv: {len(df[df['source'] == 'data_2'])}",
        "",
        "## Category Checks",
        f"- method_experienced values: {sorted(df['method_experienced'].unique())}",
        f"- video_experienced values: {sorted(df['video_experienced'].unique())}",
        f"- vr_experience_before values: {sorted(df['vr_experience_before'].unique())}",
        "",
        "## Presence Range Check (expected: 1-7)",
    ]
    for col in PRESENCE_COLS:
        mn, mx = df[col].min(), df[col].max()
        status = "PASS" if mn >= 1 and mx <= 7 else "FAIL"
        lines.append(f"- {col}: min={mn}, max={mx} [{status}]")

    lines.append("")
    lines.append("## SSQ Range Check (expected: 0-3)")
    for col in SSQ_COLS:
        mn, mx = df[col].min(), df[col].max()
        status = "PASS" if mn >= 0 and mx <= 3 else "FAIL"
        lines.append(f"- {col}: min={mn}, max={mx} [{status}]")

    lines.append("")
    lines.append("## Kennedy 1993 SSQ Subscale Scoring Verification")
    lines.append("")
    lines.append("### Item Mapping (Table 4)")
    lines.append("- **N (Nausea)**: " + ", ".join(SSQ_NAUSEA_ITEMS))
    lines.append("- **O (Oculomotor)**: " + ", ".join(SSQ_OCULOMOTOR_ITEMS))
    lines.append("- **D (Disorientation)**: " + ", ".join(SSQ_DISORIENTATION_ITEMS))
    lines.append("")
    lines.append("### Weight Factors")
    lines.append(f"- N = raw_sum × {SSQ_WEIGHT_N}")
    lines.append(f"- O = raw_sum × {SSQ_WEIGHT_O}")
    lines.append(f"- D = raw_sum × {SSQ_WEIGHT_D}")
    lines.append(f"- TSC = (N_raw + O_raw + D_raw) × {SSQ_WEIGHT_TSC}")
    lines.append("")
    lines.append("### Raw Subscale Score Ranges (expected: 0-21)")
    for name, raw_col in [("N", "ssq_n_raw"), ("O", "ssq_o_raw"), ("D", "ssq_d_raw")]:
        mn, mx = df[raw_col].min(), df[raw_col].max()
        status = "PASS" if mn >= 0 and mx <= 21 else "FAIL"
        lines.append(f"- {raw_col}: min={mn}, max={mx} [{status}]")
    lines.append("")
    lines.append("### Weighted Subscale Score Verification")
    for name, items, weight, raw_col, weighted_col in [
        ("N", SSQ_NAUSEA_ITEMS, SSQ_WEIGHT_N, "ssq_n_raw", "ssq_n"),
        ("O", SSQ_OCULOMOTOR_ITEMS, SSQ_WEIGHT_O, "ssq_o_raw", "ssq_o"),
        ("D", SSQ_DISORIENTATION_ITEMS, SSQ_WEIGHT_D, "ssq_d_raw", "ssq_d"),
    ]:
        expected_raw = df[items].sum(axis=1)
        raw_match = (df[raw_col] == expected_raw).sum() / len(df) * 100
        expected_weighted = df[raw_col] * weight
        weighted_match = (abs(df[weighted_col] - expected_weighted) < 0.01).sum() / len(df) * 100
        status = "PASS" if raw_match == 100 and weighted_match == 100 else "FAIL"
        lines.append(f"- {name}: raw_match={raw_match:.1f}%, weighted_match={weighted_match:.1f}% [{status}]")
    # TSC verification
    expected_tsc = (df["ssq_n_raw"] + df["ssq_o_raw"] + df["ssq_d_raw"]) * SSQ_WEIGHT_TSC
    tsc_match = (abs(df["ssq_tsc"] - expected_tsc) < 0.01).sum() / len(df) * 100
    status = "PASS" if tsc_match == 100 else "FAIL"
    lines.append(f"- TSC: match={tsc_match:.1f}% [{status}]")
    lines.append("")
    lines.append("### Descriptive Statistics")
    for col in SSQ_KENNEDY_COLS:
        lines.append(f"- {col}: mean={df[col].mean():.2f}, sd={df[col].std():.2f}, "
                     f"min={df[col].min():.2f}, max={df[col].max():.2f}")

    lines.append("")
    lines.append("## overall_sickness_severity Check")
    all_cols = list(df.columns)
    has_oss = "overall_sickness_severity" in all_cols
    status = "PASS" if not has_oss else "FAIL"
    lines.append(f"- Column present in output: {has_oss} [{status}]")

    lines.append("")
    lines.append("## Validation Issues")
    if not issues:
        lines.append("- None. All checks passed.")
    else:
        for issue in issues:
            lines.append(f"- {issue}")

    lines.append("")
    lines.append("## Output Files")
    lines.append("- [x] merged_normalized.csv")
    lines.append("- [x] presence_dataset.csv")
    lines.append("- [x] ssq_dataset.csv")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


# ─── Main ───────────────────────────────────────────────────────────
def main():
    base = Path(__file__).parent

    print("Loading all_data.csv ...")
    df1 = load_source_1(str(base / "all_data.csv"))
    print(f"  -> {len(df1)} rows")

    print("Loading data_2.csv ...")
    df2 = load_source_2(str(base / "data_2.csv"))
    print(f"  -> {len(df2)} rows")

    print("Merging ...")
    merged = pd.concat([df1, df2], ignore_index=True)
    print(f"  -> {len(merged)} total rows")

    # Validate
    print("Validating ...")
    issues = validate(merged)
    if issues:
        for issue in issues:
            print(f"  WARNING: {issue}")
    else:
        print("  All checks passed.")

    # Save merged_normalized.csv
    merged.to_csv(str(base / "merged_normalized.csv"), index=False, encoding="utf-8")
    print("Saved: merged_normalized.csv")

    # Split: presence_dataset.csv
    presence_df = merged[CONTEXT_COLS + PRESENCE_COLS].copy()
    presence_df.to_csv(str(base / "presence_dataset.csv"), index=False, encoding="utf-8")
    print("Saved: presence_dataset.csv")

    # Split: ssq_dataset.csv
    ssq_df = merged[CONTEXT_COLS + SSQ_COLS + SSQ_KENNEDY_COLS].copy()
    ssq_df.to_csv(str(base / "ssq_dataset.csv"), index=False, encoding="utf-8")
    print("Saved: ssq_dataset.csv")

    # QC Report
    generate_qc_report(merged, issues, str(base / "qc_report.md"))
    print("Saved: qc_report.md")

    # Final assertions
    assert "overall_sickness_severity" not in merged.columns, "overall_sickness_severity must not be in output!"
    assert len(presence_df) == len(merged), "Presence dataset row count mismatch"
    assert len(ssq_df) == len(merged), "SSQ dataset row count mismatch"

    # Kennedy subscale assertions
    for name, items in [("n", SSQ_NAUSEA_ITEMS), ("o", SSQ_OCULOMOTOR_ITEMS), ("d", SSQ_DISORIENTATION_ITEMS)]:
        raw_col = f"ssq_{name}_raw"
        assert (merged[raw_col] == merged[items].sum(axis=1)).all(), f"{raw_col} mismatch"
    expected_tsc = (merged["ssq_n_raw"] + merged["ssq_o_raw"] + merged["ssq_d_raw"]) * SSQ_WEIGHT_TSC
    assert (abs(merged["ssq_tsc"] - expected_tsc) < 0.01).all(), "ssq_tsc mismatch"

    print(f"\nDone! {len(merged)} records processed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
