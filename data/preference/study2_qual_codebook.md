# Study 2 — Qualitative Codebook (post-session interview, "most balanced" ranking)

Source: `study2_interview_notes.txt` (experimenter notes of the end-of-session interview,
transcribed and corrected by the experimenter; immutable).
Coded data: `study2_qual_coding.csv` — one row per **Participant × Method × Code × Valence**
(a participant contributes at most one count per cell, however often they repeat the point),
so every prevalence figure is a **number of participants**.

Columns: `Participant, Method, Code, Valence, Source, Excerpt`.

## Three levels kept apart

| Level | Data | Used for |
|---|---|---|
| **Overall balance** | the ranking + `Source = ranking` cells | why an interface was ranked 1st / last |
| **Perceived sickness mitigation** | `best_sickness` pick (input CSV) + `SICKNESS` code | separate from balance; never equated with measured ΔSSQ |
| **Perceived realism / immersion** | `most_realistic` pick (input CSV) + `REALISM` code | separate from balance; never equated with measured Presence |

The remaining nine codes (**interface experience**) describe what helped or disrupted the
experience. They help explain the ranking but are *not* direct measures of immersion: an
interface described as unobtrusive is not thereby reported as more immersive.

Attributes are **not interchangeable** and are never summed into a net score — a method can be
favourable on one attribute and unfavourable on another, and that trade-off is the finding.

## Coding rules

1. **Unit** = a statement attributing a property to one method. A statement about two methods
   ("những đường dẫn khiến cảm giác ko đc điều khiển") is coded for each method it names.
2. **Valence**: `+1` the property counts in the method's favour, `-1` against it. The same
   participant can have both for one method (mixed evaluation) — both are kept.
3. **Source**: `ranking` = said while explaining the balance ranking; `pick` = said only while
   answering a secondary question ("Giảm say tốt nhất", "Chân thực nhất", or an equivalent
   superlative statement such as P12's). A cell supported by any ranking statement is `ranking`.
   Analyses of *why an interface was ranked where it was* use `ranking` cells only.
4. **Only reasons are coded.** A bare pick with no reason ("Giảm say tốt nhất: ROF") is *not*
   coded; picks live in `study2_preference_input.csv` (`best_sickness`, `most_realistic`).
   A pick *with* a reason is coded on the reason (`Source = pick`), and on SICKNESS / REALISM.
   P3's picks were derived from their ranking explanation, so P3's cells are `ranking`.
5. Purely comparative remarks with no evaluative content for one side
   ("minimap hình dung hướng đi tốt hơn overlay") are coded only for the favoured method.
6. Excerpts are verbatim (typos preserved); `...` joins two verbatim fragments.

## Codes

| Family | Code | + (favourable) | − (unfavourable) |
|---|---|---|---|
| Perceived sickness | **SICKNESS** | perceived to reduce dizziness / nausea | perceived not to help, or to cause dizziness |
| Perceived realism | **REALISM** | explicitly realistic, natural, immersive, sense of physical motion ("hiệu ứng gió"), blends with the scene | explicitly unrealistic, game-like, intrusive on the experience, misaligned with the scene |
| Interface experience | **OCCLUSION** | doesn't block / cover the scene; small, tucked away | covers the scene; too big; takes up screen |
| | **DISTRACTION** | unobtrusive; attention stays on the scenery | pulls attention away from the scenery; "phân tâm", "xao nhãng" |
| | **GLANCE_COST** | no need to move eyes / split gaze | must look down, shift or split gaze, keep eyes glued to the cue |
| | **ANTICIPATION** | clear route information; know the turn in advance; "chuẩn bị tâm lí" | unclear, missing or wrong route information |
| | **TIMING** | low latency, well-timed relative to the turn | delay, appears too early, abrupt |
| | **VISUAL_NOISE** | smooth, clean, a single thin element | flicker, glare, jitter, too many moving elements, looks glitchy |
| | **VISIBILITY** | easy to see; available on demand ("khi nào cần thì mới nhìn") | not noticed, hidden, easy to forget |
| | **FAMILIARITY** | familiar (Google Maps), easy to understand | confusing, unclear purpose, unfamiliar |
| | **AGENCY** | sense of control / autonomy over the experience | feels guided / not in control |

## Coder and reliability procedure

- Coder 1: Claude (Oct 2026), deductive from the Study 1 interview themes (predictability,
  glance cost, occlusion, implementation quality) plus inductive codes (TIMING, VISUAL_NOISE,
  AGENCY, FAMILIARITY).
- Recommended check: a second coder, blind to coder 1's file, codes the same notes with this
  codebook into `study2_qual_coding_coder2.csv` (same columns). `scripts/study2_preference.R`
  then reports:
  - **positive specific agreement** over cells either coder marked (the primary figure, because
    it is not inflated by the thousands of cells both coders leave empty);
  - Cohen's κ over all Participant × Method × Code × Valence cells, overall and per code
    (reported for convention; it treats each cell as a present/absent judgement, which is not
    the same as assigning one category per statement);
  - a disagreement list (`tables/t10_coder_disagreements.csv`).
- Disagreements are then discussed and reconciled into a final coding file. κ is reported for
  the pre-reconciliation coding; the reconciled file is what the analysis uses.
