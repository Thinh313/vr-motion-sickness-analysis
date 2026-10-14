# Study 2 — Qualitative Codebook (post-session interview, "most balanced" ranking)

Source: `study2_interview_notes.txt` (experimenter notes of the end-of-session interview,
transcribed and corrected by the experimenter; immutable).
Coded data: `study2_qual_coding.csv` — one row per **Participant × Method × Code × Valence**
(a participant contributes at most one count per cell, however often they repeat the point).

## Coding rules

1. **Unit** = a statement attributing a property to one method. A statement about two methods
   ("những đường dẫn khiến cảm giác ko đc điều khiển") is coded for each method it names.
2. **Valence**: `+1` the property counts in the method's favour, `-1` against it.
3. **Only reasons are coded.** A bare pick ("Giảm say tốt nhất: ROF") with no reason is *not*
   coded here; picks live in `study2_preference_input.csv` (`best_sickness`, `most_realistic`)
   and are analysed separately. A pick *with* a reason is coded on the reason (and on
   SICKNESS/REALISM when the reason is about sickness/realism).
4. Purely comparative remarks with no evaluative content for one side
   ("minimap hình dung hướng đi tốt hơn overlay") are coded only for the favoured method.
5. Excerpts are verbatim (typos preserved); `...` joins two verbatim fragments.
6. Single coder (Claude, Oct 2026), deductive from Study 1 interview themes
   (predictability, glance cost, occlusion, implementation quality) plus inductive codes
   (TIMING, VISUAL_NOISE, AGENCY, FAMILIARITY). To estimate reliability, a second coder can
   code into `study2_qual_coding_coder2.csv` (same schema); `scripts/study2_preference.R`
   then reports Cohen's κ automatically.

## Codes

| Code | + (favourable) | − (unfavourable) |
|---|---|---|
| **OCCLUSION** | doesn't block / cover the scene; small, tucked away | covers the scene; too big; takes up screen |
| **DISTRACTION** | unobtrusive; lets attention stay on the scenery | pulls attention away from the scenery; "phân tâm", "xao nhãng" |
| **GLANCE_COST** | no need to move eyes / split gaze | must look down, shift or split gaze, keep eyes glued to the cue |
| **ANTICIPATION** | clear route information; know the turn in advance; "chuẩn bị tâm lí" | unclear, missing or wrong route information |
| **TIMING** | low latency, well-timed relative to the turn | delay, appears too early, abrupt |
| **VISUAL_NOISE** | smooth, clean, a single thin element | flicker, glare, jitter, too many moving elements, looks glitchy |
| **REALISM** | natural, realistic, immersive, sense of physical motion ("hiệu ứng gió"), integrated with the scene | artificial, game-like, intrusive, misaligned with the scene |
| **SICKNESS** | perceived to reduce dizziness / nausea | perceived not to help, or to cause dizziness |
| **VISIBILITY** | easy to see; available on demand ("khi nào cần thì mới nhìn") | not noticed, hidden, easy to forget |
| **FAMILIARITY** | familiar (Google Maps), easy to understand | confusing, unclear purpose, unfamiliar |
| **AGENCY** | sense of control / autonomy over the experience | feels guided / not in control |
