# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-04-24

Initial public release accompanying the submission of the manuscript to
*Ecological Informatics*.

### Added
- `code/mussel_tracker_v9.m`: hybrid shell-top tracker with motion support,
  feature-based local tracking, normalized cross-correlation template
  matching, contour-based edge refinement, plausibility rejection, recovery
  mode, and post-tracking jump and plateau guards.
- `code/detect_events_v10.m`: quality-aware multiscale detector for
  burrowing and resurfacing events with adaptive thresholding, cross-scale
  consolidation, and committed-event qualification.
- `code/annotation/apex_manual_tracking.m`: interactive per-frame shell-top
  annotation tool used by the two independent annotators (A1, A2) to build
  the manual reference.
- `code/annotation/inter_annotator_comparison.m`: inter-annotator comparison,
  two-threshold automatic adjudication, interactive manual review for
  flagged frames, and export of the detector-ready consensus CSV. Produced
  the inter-annotator statistics reported in Table 8 of the manuscript.
- Baseline/ablation switches for the tracker variants reported in Table 15
  of the manuscript: `full`, `template_only`, `motion_only`,
  `no_edge_refinement`, `no_feature_support`, `no_confidence_logic`,
  `no_recovery_logic`.
- Detector variants: `full`, `simple`, `no_multiscale`.
- `data/dataset2_validation/auto_tracker_results.csv`: frozen tracker
  output for the 1001-frame adjudicated validation subset from Dataset 2.
- `data/dataset3_validation/auto_tracker_results_dataset3.csv`: frozen
  tracker output for the 6001-frame held-out validation interval from
  Dataset 3.
- `docs/annotation_guide.md`: full annotator protocol used to construct the
  manual reference trajectory.
- `docs/data_availability.md`: Data Availability Statement.
- `examples/walkthrough.md`: executable walkthrough reproducing the
  trajectory- and event-level results on the included Dataset 2 CSV.
- `reproducibility_materials/`: original MATLAB Live Script (`.mlx`)
  sources for all four scripts above.
