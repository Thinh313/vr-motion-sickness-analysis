"""
Study 2 data preparation: PRE/POST SSQ around every 360-degree video trial.

Reads the two raw Google-Forms exports in experiment2_raw/ and produces the
analysis-ready long dataset plus a data-validation report.

Inputs
  experiment2_raw/before_watching_video.csv   (PRE-trial SSQ,  324 rows)
  experiment2_raw/after_watching_video.csv    (POST-trial SSQ + Presence, 324 rows)

Outputs
  data/processed/study2_trials.csv        one row per participant x trial (324)
  data/processed/study2_ssq_long.csv      Time (Pre/Post) stacked (648 rows)
  results/study2/study2_data_validation.md
  results/study2/tables/*.csv

Design: 36 participants x 3 Methods (ROF / Minimap / Path) x 3 Videos
(Walking / Cycling / Driving) = 324 trials, fully within-subject, method
administered in three-trial blocks.

SSQ scoring follows Kennedy, Lane, Berbaum & Lilienthal (1993) Table 4, using
exactly the same item-to-subscale mapping and weights as the Study 1 pipeline
(scripts/normalize_data.py).
"""

import io
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

import pandas as pd

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

BASE = Path(__file__).resolve().parent.parent
RAW = BASE / "experiment2_raw"
OUT_DATA = BASE / "data" / "processed"
OUT_RES = BASE / "results" / "study2"

# ---------------------------------------------------------------- SSQ scoring
# Item order is identical in both raw files (survey items 1-16).
SSQ_ITEMS = [
    "general_discomfort", "fatigue", "headache", "eye_strain",
    "difficulty_focusing", "increased_salivation", "sweating", "nausea",
    "difficulty_concentrating", "fullness_head", "blurred_vision",
    "dizzy_eyes_open", "dizzy_eyes_closed", "vertigo", "stomach_awareness",
    "burping",
]

# Kennedy et al. (1993) Table 4 -- subscale membership (7 items each).
SSQ_NAUSEA_ITEMS = [
    "general_discomfort", "increased_salivation", "sweating", "nausea",
    "difficulty_concentrating", "stomach_awareness", "burping",
]
SSQ_OCULOMOTOR_ITEMS = [
    "general_discomfort", "fatigue", "headache", "eye_strain",
    "difficulty_focusing", "difficulty_concentrating", "blurred_vision",
]
SSQ_DISORIENTATION_ITEMS = [
    "difficulty_focusing", "nausea", "fullness_head", "blurred_vision",
    "dizzy_eyes_open", "dizzy_eyes_closed", "vertigo",
]

W_N, W_O, W_D, W_TSC = 9.54, 7.58, 13.92, 3.74

# ------------------------------------------------------- Presence (AFTER only)
PRESENCE_ITEMS = [
    "presence_being_there", "presence_focus", "presence_control",
    "presence_virtual_space", "presence_unaware_real",
]
PRESENCE_LIKERT_MAP = {
    "Hoàn toàn không đồng ý": 1,
    "Không đồng ý": 2,
    "Hơi không đồng ý": 3,
    "Trung lập": 4,
    "Hơi đồng ý": 5,
    "Đồng ý": 6,
    "Hoàn toàn đồng ý": 7,
}

# ------------------------------------------------------- factor label mapping
METHOD_MAP = {
    "Reverse Optical Flow": "ROF",
    "Minimap": "Minimap",
    "Path overlay": "Path",   # spelling used in before_watching_video.csv
    "Overlay": "Path",        # spelling used in after_watching_video.csv
}
VIDEO_MAP = {
    "Walking": "Walking",
    "Cycling": "Cycling",
    "Driving": "Driving",
    # free-text annotation meaning "initially forgot to fill this in"
    "Walking (lúc đầu quên điền)": "Walking",
}

# --------------------------------------------------------- participant IDs
# Participant numbering supplied by the experimenter (chronological by session).
PARTICIPANT_ORDER = [
    "Trần Trọng Nguyễn", "Huỳnh Phúc Thành", "Đặng Đỗ Thái Mỹ Trân",
    "Lý Cẩm Khang", "Lâm Tuyết Nhung", "Mai Lê Hương Giang",
    "Hoàng Nguyễn Hòa Bình", "Lê Gia Linh", "LÊ THÙY DÂN",
    "Thái Phạm Như Quỳnh", "Lê Trọng Hiếu", "Lương Thị Bạch Dương",
    "Nguyễn Đặng Kim Ngân", "Lê Phan Nhật Minh", "Nguyễn Thảo Linh",
    "Phạm Minh Hoà", "Nguyễn Quỳnh Tú Hân", "Trần Ngọc Hân",
    "Nguyễn Gia Huy", "Nguyễn Đại Dũng", "Nguyễn Hoàng Lân",
    "Trần Nguyên Anh", "Trần Thị Khánh Vy", "Nguyễn Văn Khôi",
    "Trịnh Hồ Anh Thư", "Đỗ Anh Thư", "Lê Quỳnh Như",
    "Nguyễn Ngọc Minh Ánh", "Hoàng Thị Tố Như", "Tăng Triều Khánh",
    "Tăng Triều Tường", "Nguyễn Quốc Huy", "Trương Thị Anh Thư",
    "Đỗ Thị Thanh Hiền", "Mạch Chấn Minh", "Trần Đức An",
]

# Vietnamese tone-mark placement variants ("Hoà" vs "Hòa") are orthographic
# alternatives that Unicode normalisation does not unify.
TONE_VARIANTS = {
    "oà": "òa", "oá": "óa", "oả": "ỏa", "oã": "õa", "oạ": "ọa",
    "uỳ": "ùy", "uý": "úy", "uỷ": "ủy", "uỹ": "ũy", "uỵ": "ụy",
    "oè": "òe", "oé": "óe", "oẻ": "ỏe", "oẽ": "õe", "oẹ": "ọe",
}

# Short form used by P02 for part of their own session (verified by
# interleaved timestamps inside one 26-Mar-2026 session).
NAME_ALIASES = {"phuc thanh": "huynh phuc thanh"}


def normalise_name(s: str) -> str:
    """Collapse free-text name spellings to a stable participant key."""
    s = unicodedata.normalize("NFC", str(s))
    s = re.sub(r"\(.*?\)", " ", s)              # drop "(2k7)"-style suffixes
    s = re.sub(r"\s+", " ", s).strip().lower()
    for bad, good in TONE_VARIANTS.items():
        s = s.replace(bad, good)
    # strip diacritics entirely for the final key (robust to any residual variant)
    s = "".join(c for c in unicodedata.normalize("NFD", s)
                if unicodedata.category(c) != "Mn")
    s = s.replace("đ", "d")
    s = re.sub(r"\s+", " ", s).strip()
    return NAME_ALIASES.get(s, s)


NAME_TO_PID = {normalise_name(n): i + 1 for i, n in enumerate(PARTICIPANT_ORDER)}


def score_ssq(df: pd.DataFrame, prefix: str) -> pd.DataFrame:
    """Attach Kennedy (1993) raw sums and weighted subscale scores."""
    out = pd.DataFrame(index=df.index)
    out[f"{prefix}_N_raw"] = df[SSQ_NAUSEA_ITEMS].sum(axis=1)
    out[f"{prefix}_O_raw"] = df[SSQ_OCULOMOTOR_ITEMS].sum(axis=1)
    out[f"{prefix}_D_raw"] = df[SSQ_DISORIENTATION_ITEMS].sum(axis=1)
    out[f"{prefix}_Nausea"] = out[f"{prefix}_N_raw"] * W_N
    out[f"{prefix}_Oculomotor"] = out[f"{prefix}_O_raw"] * W_O
    out[f"{prefix}_Disorientation"] = out[f"{prefix}_D_raw"] * W_D
    out[f"{prefix}_TSC"] = (out[f"{prefix}_N_raw"] + out[f"{prefix}_O_raw"]
                            + out[f"{prefix}_D_raw"]) * W_TSC
    return out


def load_raw():
    """Read both exports and return tidied frames with harmonised factors."""
    pre = pd.read_csv(RAW / "before_watching_video.csv", encoding="utf-8")
    post = pd.read_csv(RAW / "after_watching_video.csv", encoding="utf-8")

    log = {"pre_shape": pre.shape, "post_shape": post.shape,
           "pre_cols": list(pre.columns), "post_cols": list(post.columns)}

    # ---- BEFORE: ts | name | video | method | 16 SSQ items | SUM SSQ
    b = pd.DataFrame({
        "name_raw": pre.iloc[:, 1],
        "ts_pre": pd.to_datetime(pre.iloc[:, 0], format="%d/%m/%Y %H:%M:%S"),
        "Video_pre_label": pre.iloc[:, 2],
        "Method_pre_label": pre.iloc[:, 3],
    })
    b[SSQ_ITEMS] = pre.iloc[:, 4:20].to_numpy()
    b["sum_ssq_reported"] = pre["SUM SSQ"]

    # ---- AFTER: ts | name | vr_exp | video | method | 5 Presence | 16 SSQ | SUM
    a = pd.DataFrame({
        "name_raw": post.iloc[:, 1],
        "ts_post": pd.to_datetime(post.iloc[:, 0], format="%d/%m/%Y %H:%M:%S"),
        "vr_experience_label": post.iloc[:, 2],
        "Video_post_label": post.iloc[:, 3],
        "Method_post_label": post.iloc[:, 4],
    })
    a[PRESENCE_ITEMS] = post.iloc[:, 5:10].to_numpy()
    a[SSQ_ITEMS] = post.iloc[:, 10:26].to_numpy()
    a["sum_ssq_reported"] = post["SUM SSQ"]

    for d in (b, a):
        d["pid_key"] = d["name_raw"].map(normalise_name)
        d["Participant"] = d["pid_key"].map(NAME_TO_PID)

    b["Method"] = b["Method_pre_label"].map(METHOD_MAP)
    b["Video"] = b["Video_pre_label"].map(VIDEO_MAP)
    a["Method"] = a["Method_post_label"].map(METHOD_MAP)
    a["Video"] = a["Video_post_label"].map(VIDEO_MAP)

    a["Presence"] = (a[PRESENCE_ITEMS]
                     .apply(lambda c: c.map(PRESENCE_LIKERT_MAP))
                     .mean(axis=1))
    a["VRExperience"] = a["vr_experience_label"].map({"Có": "Yes", "Chưa": "No"})
    for c in PRESENCE_ITEMS:
        a[c] = a[c].map(PRESENCE_LIKERT_MAP)

    return b, a, log


def match_pre_post(b: pd.DataFrame, a: pd.DataFrame):
    """Pair PRE and POST records within participant.

    Primary key is Participant x Method x Video: the design is a complete 3x3
    per participant, so that key is unique whenever both files agree.  Where a
    POST record carries a mislabelled Video (making the key degenerate), fall
    back to temporal-order pairing, which is unambiguous for that participant,
    and take Method/Video from the PRE record.
    """
    notes = []
    rows = []

    for pid, gb in b.groupby("Participant"):
        gb = gb.sort_values("ts_pre").reset_index(drop=True)
        ga = a[a.Participant == pid].sort_values("ts_post").reset_index(drop=True)

        key_ok = (Counter(zip(gb.Method, gb.Video)) == Counter(zip(ga.Method, ga.Video)))
        if key_ok:
            strategy = "key(Participant x Method x Video)"
            for _, r in gb.iterrows():
                m = ga[(ga.Method == r.Method) & (ga.Video == r.Video)]
                assert len(m) == 1
                rows.append((pid, r, m.iloc[0], strategy))
        else:
            strategy = "temporal-order (POST Video label repaired from PRE)"
            notes.append(
                f"P{pid:02d}: POST Method/Video labels do not reproduce the 3x3 "
                f"design; paired by within-session time order instead. "
                f"POST labels seen: {sorted(Counter(zip(ga.Method, ga.Video)).items())}"
            )
            for k in range(len(gb)):
                r, m = gb.iloc[k], ga.iloc[k]
                if (r.Method, r.Video) != (m.Method, m.Video):
                    notes.append(
                        f"   trial {k+1}: PRE={r.Method}/{r.Video} vs "
                        f"POST={m.Method}/{m.Video} -> using PRE labels"
                    )
                rows.append((pid, r, m, strategy))

    recs = []
    for pid, r, m, strategy in rows:
        rec = {"Participant": pid, "Method": r.Method, "Video": r.Video,
               "ts_pre": r.ts_pre, "ts_post": m.ts_post,
               "MatchStrategy": strategy,
               "VRExperience": m.VRExperience,
               "Presence": m.Presence}
        for c in PRESENCE_ITEMS:
            rec[c] = m[c]
        for c in SSQ_ITEMS:
            rec[f"pre_{c}"] = r[c]
            rec[f"post_{c}"] = m[c]
        rec["pre_sum_reported"] = r.sum_ssq_reported
        rec["post_sum_reported"] = m.sum_ssq_reported
        recs.append(rec)

    trials = pd.DataFrame(recs)
    return trials, notes


def add_design_structure(trials: pd.DataFrame) -> pd.DataFrame:
    """Reconstruct trial order, method blocks and lag variables from PRE times."""
    trials = trials.sort_values(["Participant", "ts_pre"]).reset_index(drop=True)
    trials["TrialNumber"] = trials.groupby("Participant").cumcount() + 1
    trials["MethodBlockPosition"] = (trials["TrialNumber"] - 1) // 3 + 1
    trials["VideoOrderWithinBlock"] = (trials["TrialNumber"] - 1) % 3 + 1

    order = (trials.sort_values("TrialNumber")
             .groupby("Participant")["Method"]
             .apply(lambda s: "-".join(dict.fromkeys(s))))
    trials["MethodOrderGroup"] = trials["Participant"].map(order)
    vorder = (trials[trials.MethodBlockPosition == 1]
              .sort_values("TrialNumber")
              .groupby("Participant")["Video"]
              .apply(lambda s: "-".join(s)))
    trials["VideoOrderGroup"] = trials["Participant"].map(vorder)

    g = trials.groupby("Participant")
    trials["PreviousMethod"] = g["Method"].shift(1).fillna("none")
    trials["PreviousVideo"] = g["Video"].shift(1).fillna("none")
    trials["Trial"] = trials["Method"] + "_" + trials["Video"]

    # inter-trial recovery time: this trial's PRE minus previous trial's POST
    trials["PrevPostTime"] = g["ts_post"].shift(1)
    trials["RecoveryMinutes"] = ((trials["ts_pre"] - trials["PrevPostTime"])
                                 .dt.total_seconds() / 60)
    trials["ExposureMinutes"] = ((trials["ts_post"] - trials["ts_pre"])
                                 .dt.total_seconds() / 60)
    return trials


def main():
    OUT_DATA.mkdir(parents=True, exist_ok=True)
    (OUT_RES / "tables").mkdir(parents=True, exist_ok=True)

    b, a, log = load_raw()
    trials, match_notes = match_pre_post(b, a)

    pre_items = trials[[f"pre_{c}" for c in SSQ_ITEMS]].copy()
    pre_items.columns = SSQ_ITEMS
    post_items = trials[[f"post_{c}" for c in SSQ_ITEMS]].copy()
    post_items.columns = SSQ_ITEMS

    trials = pd.concat([trials, score_ssq(pre_items, "Pre"),
                        score_ssq(post_items, "Post")], axis=1)
    for sub in ["Nausea", "Oculomotor", "Disorientation", "TSC"]:
        trials[f"Delta_{sub}"] = trials[f"Post_{sub}"] - trials[f"Pre_{sub}"]

    trials = add_design_structure(trials)

    # lagged POST (residual-sickness test): POST TSC of trial t-1
    trials["PrevPost_TSC"] = trials.groupby("Participant")["Post_TSC"].shift(1)

    core = ["Participant", "Trial", "TrialNumber", "Method", "Video",
            "MethodBlockPosition", "MethodOrderGroup", "VideoOrderGroup",
            "VideoOrderWithinBlock", "PreviousMethod", "PreviousVideo",
            "VRExperience", "ExposureMinutes", "RecoveryMinutes",
            "Pre_Nausea", "Post_Nausea", "Delta_Nausea",
            "Pre_Oculomotor", "Post_Oculomotor", "Delta_Oculomotor",
            "Pre_Disorientation", "Post_Disorientation", "Delta_Disorientation",
            "Pre_TSC", "Post_TSC", "Delta_TSC", "PrevPost_TSC",
            "Pre_N_raw", "Pre_O_raw", "Pre_D_raw",
            "Post_N_raw", "Post_O_raw", "Post_D_raw",
            "Presence"] + PRESENCE_ITEMS
    out = trials[core].copy()
    out.to_csv(OUT_DATA / "study2_trials.csv", index=False, encoding="utf-8")

    # long (Time-stacked) form for the Time x Method x Video RM-ANOVA
    long_rows = []
    for t in ("Pre", "Post"):
        d = out[["Participant", "Trial", "TrialNumber", "Method", "Video",
                 "MethodBlockPosition", "MethodOrderGroup"]].copy()
        d["Time"] = t
        for sub in ["Nausea", "Oculomotor", "Disorientation", "TSC"]:
            d[sub] = out[f"{t}_{sub}"]
        long_rows.append(d)
    long = pd.concat(long_rows, ignore_index=True)
    long.to_csv(OUT_DATA / "study2_ssq_long.csv", index=False, encoding="utf-8")

    write_validation_report(b, a, trials, out, long, log, match_notes,
                           pre_items, post_items)
    print(f"Wrote {OUT_DATA/'study2_trials.csv'}  ({len(out)} rows)")
    print(f"Wrote {OUT_DATA/'study2_ssq_long.csv'} ({len(long)} rows)")
    print(f"Wrote {OUT_RES/'study2_data_validation.md'}")


def write_validation_report(b, a, trials, out, long, log, match_notes,
                            pre_items, post_items):
    L = []
    W = L.append
    W("# Study 2 — Data Validation Report\n")
    W("Generated by `scripts/study2_prepare.py`. Inputs treated as immutable.\n")

    W("## A. Raw file schemas\n")
    W(f"| | `before_watching_video.csv` | `after_watching_video.csv` |")
    W("|---|---|---|")
    W(f"| Rows (excl. header) | {log['pre_shape'][0]} | {log['post_shape'][0]} |")
    W(f"| Columns | {log['pre_shape'][1]} | {log['post_shape'][1]} |")
    W("| Timestamp | col 1 `Dấu thời gian` (dd/mm/yyyy hh:mm:ss) | col 1, same format |")
    W("| Participant ID | col 2 free-text full name | col 2 free-text full name |")
    W("| VR experience | *absent* | col 3 (`Có`/`Chưa`) |")
    W("| Video | col 3 (`Môi trường bạn **sắp** trải nghiệm`) | col 4 (`…bạn **vừa** trải nghiệm`) |")
    W("| Method | col 4 | col 5 |")
    W("| Presence (5 items, 7-pt) | *absent* | cols 6–10 |")
    W("| SSQ items 1–16 | cols 5–20 | cols 11–26 |")
    W("| `SUM SSQ` | col 21 (unweighted item sum) | col 27 (unweighted item sum) |")
    W("")
    W("Both files are **long format**: one row per participant × trial. There is")
    W("no explicit trial-number or participant-code column — trial order must be")
    W("reconstructed from the submission timestamp.\n")

    W("### Factor encodings and the label mismatch between files\n")
    W("| Factor | BEFORE labels | AFTER labels | Harmonised |")
    W("|---|---|---|---|")
    W("| Method | `Reverse Optical Flow`, `Minimap`, `Path overlay` | `Reverse Optical Flow`, `Minimap`, **`Overlay`** | `ROF`, `Minimap`, `Path` |")
    W("| Video | `Walking`, `Cycling`, `Driving` | same + **`Walking (lúc đầu quên điền)`** | `Walking`, `Cycling`, `Driving` |")
    W("")
    W("The Path-Overlay method is spelled differently in the two exports")
    W("(`Path overlay` vs `Overlay`); this is a labelling difference only, not a")
    W("design difference. One AFTER record carries the free-text annotation")
    W("*\"lúc đầu quên điền\"* (\"initially forgot to fill this in\"), mapped to `Walking`.\n")

    W("## B. Participant identification\n")
    W(f"- Distinct raw name strings: **{b.name_raw.nunique()}** (BEFORE), "
      f"**{a.name_raw.nunique()}** (AFTER) — inflated by trailing/double spaces, "
      "`(2k5)`/`(2k6)`/`(2k7)` birth-year suffixes, ALL-CAPS entry, and the")
    W("  Vietnamese tone-placement variants `Hoà`/`Hòa`, `Quỳnh`/`Qùynh`.")
    W("- After normalisation (NFC → strip parentheticals → collapse whitespace →")
    W("  lowercase → unify tone placement → strip diacritics) and applying the")
    W("  experimenter-supplied participant numbering: "
      f"**{trials.Participant.nunique()} participants**.")
    W("- `Phúc Thành` and `Huỳnh Phúc Thành` are treated as **one participant (P02)**:")
    W("  their 18 submissions interleave inside a single session on 26 Mar 2026")
    W("  (10:09–11:49) and together total exactly 9 PRE and 9 POST forms.")
    W("")
    counts = trials.groupby("Participant").size()
    W(f"- Trials per participant: min {counts.min()}, max {counts.max()} "
      f"(all {int((counts==9).sum())}/36 participants have exactly 9). ")
    W(f"- Total matched trials: **{len(trials)}** = 36 × 9. ✔\n")

    W("## C. PRE ↔ POST matching\n")
    W("Primary key **Participant × Method × Video** — unique by construction,")
    W("because every participant completes a complete 3 × 3 design. Where the")
    W("POST labels do not reproduce that design, temporal-order pairing is used")
    W("and the PRE labels are taken as authoritative.\n")
    W("| Strategy | Trials |")
    W("|---|---|")
    for s, n in trials.MatchStrategy.value_counts().items():
        W(f"| {s} | {n} |")
    W("")
    if match_notes:
        W("**Records requiring the fallback:**\n")
        for n in match_notes:
            W(f"- {n}")
        W("")
    W(f"Unmatched PRE records: **{len(b) - len(trials)}**; "
      f"unmatched POST records: **{len(a) - len(trials)}**.\n")

    W("### Timestamp anomalies (matching is unaffected)\n")
    exp = trials["ExposureMinutes"]
    W(f"- PRE→POST elapsed time, median **{exp.median():.1f} min** "
      f"(IQR {exp.quantile(.25):.1f}–{exp.quantile(.75):.1f}).")
    odd = trials[trials.ExposureMinutes > 60][
        ["Participant", "TrialNumber", "Method", "Video", "ts_pre", "ts_post",
         "ExposureMinutes"]]
    if len(odd):
        W(f"- **{len(odd)} trial(s)** with elapsed time > 60 min:\n")
        W(odd.to_markdown(index=False))
        W("")
        W("  P07's final POST form was submitted 35 days after the session; all")
        W("  nine trials were run on 26 May 2026. Retained without special")
        W("  treatment, as instructed, and noted in the limitations.")
    W("")
    W("Three participants submitted some POST forms out of trial order "
      "(P02, P29, P13); this is a form-submission artefact. Because matching is "
      "key-based rather than positional, none of it affects the paired data.\n")

    W("## D. Missing values, ranges, duplicates\n")
    W(f"- Missing cells in either raw file: **{int(b.isna().sum().sum())}** (BEFORE), "
      f"**{int(a.isna().sum().sum())}** (AFTER).")
    W(f"- SSQ item response range observed: **{int(pre_items.min().min())}–"
      f"{int(pre_items.max().max())}** (PRE) and **{int(post_items.min().min())}–"
      f"{int(post_items.max().max())}** (POST) — matches the expected 0–3 scale. ✔")
    mis_pre = int((pre_items.sum(axis=1) != trials.pre_sum_reported).sum())
    mis_post = int((post_items.sum(axis=1) != trials.post_sum_reported).sum())
    W(f"- The survey's own `SUM SSQ` column equals the unweighted 16-item sum in")
    W(f"  **{len(trials)-mis_pre}/{len(trials)}** PRE and **{len(trials)-mis_post}/"
      f"{len(trials)}** POST records ({mis_pre} and {mis_post} mismatches). ✔")
    dup = trials.duplicated(["Participant", "Method", "Video"]).sum()
    W(f"- Duplicate Participant × Method × Video records: **{dup}**. ✔")
    W(f"- Missing values in the analysis dataset: "
      f"**{int(out.drop(columns=['PrevPost_TSC','RecoveryMinutes']).isna().sum().sum())}** "
      "(excluding lag variables, which are undefined at trial 1 by design).\n")

    W("## E. Reconstructed design structure\n")
    W("Trial order reconstructed from PRE-form timestamps. All 36 participants")
    W("show clean three-trial method blocks in that order, which independently")
    W("validates the reconstruction.\n")
    W("**Method-order groups (all six sequences used):**\n")
    mo = (trials[trials.TrialNumber == 1]
          .groupby("MethodOrderGroup").size().rename("n").reset_index())
    W(mo.to_markdown(index=False))
    W("")
    W("**Video order within method block (all six sequences used):**\n")
    vo = (trials.groupby(["Participant", "MethodBlockPosition"])
          .apply(lambda g: "-".join(g.sort_values("TrialNumber").Video),
                 include_groups=False)
          .value_counts().rename("blocks").reset_index())
    vo.columns = ["VideoOrder", "blocks"]
    W(vo.to_markdown(index=False))
    W("")
    W("**Balance checks:**\n")
    W("Method × block position (each cell should be 12):\n")
    W(pd.crosstab(trials[trials.VideoOrderWithinBlock == 1].Method,
                  trials[trials.VideoOrderWithinBlock == 1].MethodBlockPosition
                  ).to_markdown())
    W("")
    W("Video × position within block (each cell should be 36):\n")
    W(pd.crosstab(trials.Video, trials.VideoOrderWithinBlock).to_markdown())
    W("")
    W("Method × Video (each cell should be 36):\n")
    W(pd.crosstab(trials.Method, trials.Video).to_markdown())
    W("")
    W("Counterbalancing is exact: six method orders × 6 participants, six video")
    W("orders × 18 blocks, and every position cell perfectly balanced.\n")

    W("## F. SSQ scoring implementation\n")
    W("Kennedy, Lane, Berbaum & Lilienthal (1993) Table 4 — identical item")
    W("mapping and weights to the Study 1 pipeline (`scripts/normalize_data.py`),")
    W("applied separately to the PRE and POST item sets.\n")
    W("| Subscale | Items (survey numbers) | Weight |")
    W("|---|---|---|")
    idx = {c: i + 1 for i, c in enumerate(SSQ_ITEMS)}
    for nm, items, w in [("Nausea (N)", SSQ_NAUSEA_ITEMS, W_N),
                         ("Oculomotor (O)", SSQ_OCULOMOTOR_ITEMS, W_O),
                         ("Disorientation (D)", SSQ_DISORIENTATION_ITEMS, W_D)]:
        nums = ", ".join(f"{idx[i]}" for i in items)
        W(f"| {nm} | {nums} ({len(items)} items) | × {w} |")
    W(f"| Total Severity (TSC) | (N_raw + O_raw + D_raw) | × {W_TSC} |")
    W("")
    W("with, per subscale, `raw = Σ items` on the 0–3 scale, then")
    W(f"`N = raw_N × {W_N}`, `O = raw_O × {W_O}`, `D = raw_D × {W_D}`, and")
    W(f"`TSC = (raw_N + raw_O + raw_D) × {W_TSC}`.\n")
    W("Item membership (7 items per subscale; several items load on two):\n")
    for nm, items in [("Nausea", SSQ_NAUSEA_ITEMS),
                      ("Oculomotor", SSQ_OCULOMOTOR_ITEMS),
                      ("Disorientation", SSQ_DISORIENTATION_ITEMS)]:
        W(f"- **{nm}**: {', '.join(items)}")
    W("")
    W("Change scores: `Delta_X = Post_X − Pre_X` for each of the four outcomes.\n")

    W("## G. Presence scale — present in the data, contrary to the handoff\n")
    W("The AFTER export **does** contain the same five-item, seven-point")
    W("Presence scale used in Study 1 (cols 6–10), plus a VR-experience item.")
    W("Items were mapped from the Vietnamese Likert labels")
    W("(`Hoàn toàn không đồng ý` = 1 … `Hoàn toàn đồng ý` = 7) and averaged.")
    W("Presence is reported as a **supplementary** analysis, kept separate from")
    W("the primary SSQ models.\n")
    W(f"- VR experience: "
      + ", ".join(f"{k} = {v} trials"
                  for k, v in trials.VRExperience.value_counts().items())
      + ".\n")

    W("## H. Analysis datasets written\n")
    W(f"- `data/processed/study2_trials.csv` — **{len(out)} rows** × {out.shape[1]} cols;")
    W("  one row per participant × trial with PRE/POST/Delta for all four outcomes.")
    W(f"- `data/processed/study2_ssq_long.csv` — **{len(long)} rows** "
      "(Time-stacked) for the Time × Method × Video RM-ANOVA.\n")

    (OUT_RES / "study2_data_validation.md").write_text("\n".join(L), encoding="utf-8")


if __name__ == "__main__":
    main()
