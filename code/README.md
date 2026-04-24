# Source code

Two MATLAB scripts implement the full pipeline.

## `mussel_tracker_v9.m`

Frame-wise shell-top localization with:

- optional temporal background suppression, Gaussian background handling,
  morphological top-hat enhancement, and median/sharpening preprocessing;
- short-term motion support and feature-based local tracking;
- normalized cross-correlation template matching inside a predicted search
  window;
- hybrid segmentation and edge-aware refinement to recover the uppermost
  plausible shell point;
- plausibility rejection against inter-frame motion bounds and the fixed
  bedline;
- a jump guard that reverts short spike-like excursions followed by a
  return, and a plateau guard that repairs frozen runs followed by a large
  exit jump;
- a recovery mode that bridges limited intervals of weak visibility using
  short-term temporal continuity.

Top-of-file switch `cfg.variant` controls which ablation variant is run.

Output is a single CSV per run. See
`../data/README.md` for the column schema.

## `detect_events_v10.m`

Multiscale quality-aware event detector operating on the reconstructed
trajectory:

- scale-space smoothing over the scale set
  `[60, 120, 240, 480, 900, 1800]` s;
- hysteresis-type detection on the smoothed derivative and depth
  progression, with per-scale thresholds
  `r_start = max(0.5, k_start · σ_r)` and `r_end = max(0.2, k_end · σ_r)`
  where `k_end = 0.5 · k_start`;
- an autotuned start multiplier `k_start ∈ {2.5, 3, 4, 5, 6}` chosen by
  maximizing an ensemble objective;
- cross-scale consolidation requiring support on ≥ 2 smoothing scales to
  qualify as a committed event;
- directional consistency, anchor-count, coverage, and allowed-internal-gap
  gates (see Table C.17 of the manuscript for the full rule set).

Top-of-file switch `cfg.variant` controls which detector variant is run
(`full`, `simple`, `no_multiscale`).

## Note on the MATLAB Live Script originals

These `.m` files are plain-text exports of the MATLAB Live Scripts
(`*.mlx`) that were the working format during development. The original
`.mlx` files are preserved in `../reproducibility_materials/` for anyone
who wants the annotated Live Script view with inline results. The `.m`
versions are committed at the top level of the repo because they diff
cleanly and version-control well — they are the canonical source of truth.
