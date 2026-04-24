# Reproducibility materials

This folder preserves the original MATLAB Live Script (`.mlx`) sources
for every script in the pipeline, as they existed at the moment the
frozen validation numbers were produced.

## Contents

- `mussel_tracker_v9_jump_guard_IMPROVED_toggleable.mlx` — the
  shell-top tracker with jump and plateau guards and all ablation
  switches.
- `detect_burrowing_and_resurfacing_quality_aware_v10_toggleable.mlx` —
  the multiscale quality-aware event detector.
- `Apex_Manual_Tracking.mlx` — the frame-by-frame manual annotation
  tool used by A1 and A2.
- `Inter_annotator_comparison.mlx` — the inter-annotator comparison,
  adjudication, and consensus export tool that produced the Table 8
  statistics.

## Why both `.m` and `.mlx`?

The `.m` versions in `../code/` and `../code/annotation/` are the
canonical source of truth: they diff cleanly in git, are portable
across MATLAB versions, and are what reviewers should read.

The `.mlx` originals preserved here keep the exact Live Script layout
with inline narrative cells and with any inline results that were on
screen when the validation runs were performed. This is occasionally
useful for audit purposes — you can see, at a glance, what the author
saw.

If you only ever open one version, open the `.m` files.
