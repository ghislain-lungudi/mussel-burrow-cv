# Annotation guide

This is the written protocol used to produce the manual shell-top reference
for the adjudicated validation subset of Dataset 2 (1001 frames) and for
the Dataset 3 held-out validation interval (6001 frames, frames
18,000–24,000). It is reproduced here so that the reference construction is
fully auditable and so that future annotators can reapply the same
convention.

## 1. Scope

You are marking **one point per frame**: the shell-top in image
coordinates. You are *not* marking the bedline. The bedline is fixed once
per sequence before annotation begins and is held constant for the rest of
the record.

Image coordinates: x increases to the right, y increases **downward**
(standard image convention). A shell-top with a smaller `y` is closer to
the top of the image and therefore more exposed.

## 2. Definition of the shell-top

The shell-top is the **highest visible point on the exposed shell boundary
in image coordinates**, subject to the exclusions listed in §3.

If the shell edge is unambiguous, this is the single highest pixel on the
boundary.

If the shell edge contains multiple locally highest points (e.g. a
bi-lobed apex, a notch near the umbo, or a partial burial that exposes
both anterior and posterior ends), take the point that is highest in
image-y and that visibly belongs to the shell surface. If two or more
candidates are within ~3 px of each other in y, prefer the one nearest
the estimated center of the previously marked shell, to preserve
temporal continuity.

## 3. Exclusions

Do **not** mark any of the following, even if they are the pixel closest
to the top of the frame:

- **Detached grains** resting on top of the shell. Substrate grains
  (especially pea gravel) can sit briefly on the dorsal surface and
  appear to form a higher "shell-top." These are not the shell.
- **Isolated glare streaks** or specular highlights. Glare from the
  sidewall or the water surface sometimes creates a bright line above the
  true shell. Ignore it; mark the shell boundary under it.
- **Biofilm strings, algae, or suspended fines** projecting above the
  shell. These are not part of the shell.
- **Any feature whose continuity with the rest of the shell cannot be
  visually traced** through the frame. If you cannot mentally follow a
  line from the candidate point down along the shell boundary, do not
  mark it.

## 4. Difficulty classes

Every annotated frame falls into one of four difficulty classes (these
correspond to panels A–D of Figure 7 in the manuscript).

| Class | Description | How to handle |
|---|---|---|
| **A — Easy** | Clear shell boundary, high contrast, fully exposed apex. | Mark the obvious apex. |
| **B — Moderate** | Partial burial, moderate contrast, some surrounding sediment. | Apply §2 and §3 normally. |
| **C — Difficult** | Low contrast, coarse substrate, weak local texture. | Mark the best-supported point; use temporal context from adjacent frames. |
| **D — Ambiguous** | Very low contrast, boundary indistinct, multiple plausible candidates. | Record as ambiguous; see §5. |

## 5. Handling ambiguous frames (class D)

For ambiguous frames:

1. Mark your single best estimate anyway.
2. Add a flag in the annotation CSV (`ambiguous = 1`) so the adjudicator
   can review it first.
3. If you genuinely cannot place a point — for example, the shell has
   disappeared into fines and no boundary is visible anywhere in the ROI —
   mark `missing = 1` and leave the coordinates blank. Do not guess.

Missing and ambiguous frames are handled by the automated pipeline's
gap-interpolation and quality-aware smoothing logic. Better to leave a gap
than to fabricate a point.

## 6. Temporal consistency

Annotators worked from the raw image sequence in chronological order and
were permitted to scroll backwards and forwards to resolve ambiguity. You
are allowed — and encouraged — to use the trajectory of recent frames to
discipline your interpretation of the current one. What you must **not**
do is:

- Look at the automated tracker output before first-pass annotation.
  Leakage control requires that first-pass manual annotation be performed
  without viewing automated predictions.
- Coordinate with another annotator during first-pass annotation. The two
  annotators worked independently; their disagreements were then resolved
  by adjudication (§7).

## 7. Adjudication workflow

Two independent annotators marked the full 1001-frame validation subset.
Inter-annotator discrepancy was quantified at the frame level:

- mean Euclidean discrepancy: 55.08 px
- median: 51.26 px
- RMSE: 65.58 px

Disagreements were resolved as follows:

1. Frames where the two annotators agreed within an auto-resolve tolerance
   were accepted automatically. This accounted for 336 frames of the 1001.
2. The remaining 665 frames were reviewed manually. The adjudicator (a
   third reviewer) had access to both annotators' points and to the raw
   frame, but *not* to the automated tracker output during first-pass
   adjudication. Automated outputs were consulted only at a later review
   stage, if at all, to sanity-check the final consensus.
3. The adjudicated point was taken as the final consensus reference for
   that frame.

The same protocol was applied to the Dataset 3 held-out validation
interval. Because the primary purpose of Dataset 3 was to broaden held-out
evaluation rather than to repeat a second full inter-annotator study under
deliberately difficult conditions, the detailed inter-annotator discrepancy
statistics are reported for Dataset 2 only.

## 8. Output format

Each annotator produced one CSV with columns:

```
frame, x_px, y_px, ambiguous, missing, notes
```

The adjudicated consensus CSV has the same columns plus a
`consensus_source` column recording whether the row was auto-resolved
(`'auto'`) or manually adjudicated (`'manual'`).

## 9. Event-level annotation

For each sequence, after shell-top annotation and adjudication were
complete, burrowing and resurfacing events were annotated by jointly
reviewing:

- the ordered image sequence,
- the manually reconstructed burrow-depth trajectory obtained by combining
  the adjudicated shell-top coordinates with the fixed bedline.

Each event received:

- a start time and an end time (in frame units and in minutes),
- a class (`burrowing` or `resurfacing`),
- a confidence label (`committed` or `candidate`).

A **committed** event must satisfy, at a minimum, sustained directional
motion over at least 5 minutes, a net depth change of at least 1 mm over
the interval, and an unambiguous visual signature in the corresponding
frames. The exact numerical thresholds used by the automated detector are
tabulated in Table C.17 of the manuscript; the manual event labels follow
the same general logic but use annotator judgment rather than fixed
arithmetic.

## 10. Trial-level labels

At the end of the sequence, the annotator records:

- `burrowing_present`: `yes`/`no`,
- `resurfacing_present`: `yes`/`no`,
- `committed_burrowing_present`: `yes`/`no`,
- `committed_resurfacing_present`: `yes`/`no`,
- `trial_acceptable_for_event_inference`: `yes`/`no`, with a short reason
  if `no` (e.g. camera bump, lighting failure, animal removed by
  experimenter).

These trial-level labels are the ground truth against which the automated
pipeline's trial-level agreement (Table 14 in the manuscript) is scored.
