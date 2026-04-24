# Data

This folder contains everything from the validation pipeline that can be
redistributed. The raw image stacks themselves are not here, because they
total on the order of 200 GB and are tied to specific live-animal
experiments. They are available from the corresponding author on reasonable
request.

## What is here

### `dataset2_validation/auto_tracker_results.csv`

Frozen output of the full tracker (configuration `cfg.variant = 'full'`)
applied to the 1001-frame adjudicated validation subset from Dataset 2.
This is the file that underlies the trajectory-level and event-level
metrics reported in Sections 3.2–3.5 of the manuscript (Tables 9–14,
Figures 8–17).

Columns:

| Column | Units | Meaning |
|---|---|---|
| `frame` | — | 1-indexed frame number within the subset |
| `time_s` | s | seconds since the first annotated frame (Δt = 2 s) |
| `mask_detected` | 0/1 | whether a shell mask was accepted in this frame |
| `detection_mode` | enum | which localization branch produced the point (template, edge, recovery, …) |
| `centroid_x_px`, `centroid_y_px` | px | accepted shell-region centroid in image coordinates |
| `bed_y_px` | px | fixed bedline evaluated at `centroid_x_px` |
| `bed_y_mm` | mm | bedline converted using the trial-specific `mm_per_px` |
| `top_y_px_raw_pre_guard` | px | shell-top *before* jump/plateau guards |
| `top_y_px` | px | shell-top *after* jump/plateau guards and plausibility checks |
| `top_y_mm_raw` | mm | raw metric shell-top height |
| `top_y_mm_interp` | mm | gap-interpolated metric shell-top height |
| `protrusion_mm` | mm | visible shell above bed, `P(t) = ybed − ytop` |
| `burrow_mm` | mm | operational burrow depth, `D_B(t) = L − P(t)` |
| `burrow_smooth_mm` | mm | display-smoothed burrow depth (used for plots only) |
| `dBurrow_dt_mmps` | mm s⁻¹ | derivative used for event inference (computed on a longer-scale smoothed signal) |
| `burrow_rate_mmph` | mm h⁻¹ | convenience rescaling of `dBurrow_dt_mmps` |

### `dataset3_validation/auto_tracker_results_dataset3.csv`

Frozen output of the full tracker applied to the 6001-frame held-out
validation interval from Dataset 3 (frames 18,000–24,000 of the 18 h
acquisition). This file underlies every metric reported in Section 3.7
of the manuscript (Table 16, Figures 27–29). It was produced from a
**different mussel individual** than Dataset 2. The column schema is
identical to `dataset2_validation/auto_tracker_results.csv`.

### `sample/`

A tiny synthetic example used by `examples/walkthrough.md` so that the
executable walkthrough runs end-to-end even when the full validation CSV is
not present on disk.

## What is not here, and why

- **Raw image sequences** (Dataset 1: 10,800 frames; Dataset 2: 10,800
  frames; Dataset 3: 32,400 frames). These are large and tied to specific
  animals and experimental campaigns; they are available from the
  corresponding author on reasonable request.
- **Dataset 1 artifacts.** Dataset 1 was used exclusively for framework
  development and parameter tuning. It is intentionally excluded from
  formal validation, so no Dataset 1 validation CSV appears in this
  repository.

## Reproducing the validation results from the included CSV

Open `examples/walkthrough.md`. The walkthrough uses
`dataset2_validation/auto_tracker_results.csv` as its only input and
regenerates the trajectory overlay, the Bland–Altman plot, and the
event-level summary reported in the manuscript.

## License

All files under `data/` are released under
[CC BY 4.0](../LICENSE-DATA).
