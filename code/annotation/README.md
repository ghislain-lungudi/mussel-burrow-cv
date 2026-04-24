# Annotation tools

These scripts are the manual reference construction pipeline. They are
what produced the adjudicated consensus reference used to validate the
automated tracker in Section 3 of the manuscript.

They are separate from the automated tracker (`../mussel_tracker_v9.m`)
and the event detector (`../detect_events_v10.m`). Those run on the raw
image sequence. These run on the raw image sequence too, but with a
human in the loop.

## `apex_manual_tracking.m`

Frame-by-frame manual shell-top annotation tool.

### What it does

For each frame in an image sequence, the annotator clicks the shell-top
point with the mouse and optionally assigns a visibility class:

- `1` = clear
- `2` = moderate ambiguity
- `3` = high ambiguity

The tool supports:

- auto-advance after left-click,
- forward/backward navigation and jump-to-frame,
- optional fixed bed-line overlay loaded from `.mat`,
- optional on-the-fly computation of bed-referenced shell height and
  manual burrow depth,
- save-and-resume at any point.

### How it was used in the paper

Two independent annotators (A1 and A2) ran this tool on the same 1001
frames of the Dataset 2 validation subset, producing two CSVs:

- `manual_annotations_A1.csv`
- `manual_annotations_A2.csv`

Annotators worked from the raw image sequence and the written
protocol in `../../docs/annotation_guide.md`. They did **not** see the
automated tracker output during first-pass annotation (leakage control,
§6 of the annotation guide).

### Output schema

One row per frame, with at minimum:

```
frame, time_s, x_px, y_px, visibility_class, ambiguous, missing, annotator_id
```

Optional extra columns are added when bed-referenced measurements are
enabled (bed height, manual protrusion, manual burrow depth).

## `inter_annotator_comparison.m`

Inter-annotator comparison, automatic adjudication, manual review for
the remaining disagreements, and export of the detector-ready consensus
CSV.

### What it does

1. Loads the two per-annotator CSVs produced by
   `apex_manual_tracking.m`.
2. Computes per-frame Euclidean discrepancy between A1 and A2.
3. Applies the two-threshold adjudication rule:
   - discrepancy ≤ `auto_agree_px` (default 10 px) → average A1 and A2
     automatically,
   - discrepancy > `manual_review_px` (default 35 px) → flagged for
     manual adjudication,
   - in between → also flagged for manual review (conservative).
4. For flagged frames, opens an interactive review panel showing the
   raw frame plus a synced zoom panel, with scroll-wheel zoom and pan,
   so the adjudicator can pick the correct point.
5. Writes three outputs:
   - `annotation_comparison_summary.csv`: per-frame discrepancies and
     adjudication decisions.
   - `consensus_annotations.csv` / `.mat`: the final adjudicated
     reference trajectory used in Section 3 of the paper.
   - `manual_detector_input.csv`: detector-ready CSV in exactly the
     schema the event detector expects
     (`time_s`, `burrow_smooth_mm`, `dBurrow_dt_mmps`,
     `mask_detected`).

### How it was used in the paper

This is the script that produced the numbers in **Table 8** of the
manuscript:

| | Value |
|---|---|
| Frames with both annotations | 1001 |
| Mean inter-annotator discrepancy (px) | 55.08 |
| Median inter-annotator discrepancy (px) | 51.26 |
| RMSE inter-annotator discrepancy (px) | 65.58 |
| Frames auto-resolved during consensus | 336 |
| Frames manually adjudicated | 665 |

It is also the script that produced the adjudicated consensus
reference that every validation metric in Sections 3.2–3.5 is scored
against.

## Reproducing the reference construction

If you have Dataset 2 or Dataset 3 raw frames in hand:

1. Have two annotators run `apex_manual_tracking.m` independently on
   the same frame range. Each produces a per-annotator CSV.
2. Run `inter_annotator_comparison.m` pointing to those two CSVs.
3. The script emits the consensus CSV and a detector-ready CSV.

The consensus CSV is then used as the reference against which
`auto_tracker_results.csv` (from the main tracker) is compared to
produce Tables 9–14 of the manuscript.

## Relation to the other scripts

```
             raw image sequence
             /              \
            /                \
           v                  v
   apex_manual_tracking    mussel_tracker_v9
    (annotator A1)         (automated)
   apex_manual_tracking           |
    (annotator A2)                |
           \                      |
            v                     |
   inter_annotator_comparison     |
           |                      |
           v                      v
   consensus reference   auto_tracker_results.csv
           \                      /
            \                    /
             v                  v
           validation metrics (Tables 9-14)
           detector input      detect_events_v10
                                    |
                                    v
                          event / trial summaries
                          (Tables 12-13, 16)
```
