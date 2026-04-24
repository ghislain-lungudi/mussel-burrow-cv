# Reproducibility checklist

This checklist documents what is and is not reproducible from the
material in this repository. It is aligned with the reproducibility
criteria used by *Ecological Informatics* and the broader reproducible-
research community (e.g. ACM Artifact Review guidelines).

## ✔ Code and configuration

- [x] **Full source code** for the tracker is public
  (`code/mussel_tracker_v9.m`).
- [x] **Full source code** for the event detector is public
  (`code/detect_events_v10.m`).
- [x] **Full source code** for the manual annotation and inter-annotator
  adjudication tools is public (`code/annotation/`). This is the pipeline
  that produced the consensus reference against which every validation
  metric is scored, and is what reproduced the inter-annotator statistics
  in Table 8 of the manuscript.
- [x] **All ablation variants** reported in Table 15 of the manuscript
  are selectable via a single top-of-file switch (`cfg.variant`).
- [x] **All thresholds and hyperparameters** are printed in the source
  and also tabulated in Table C.17 of the manuscript.
- [x] **Software environment** is specified (MATLAB R2022a+, Image
  Processing, Computer Vision, Signal Processing, and Statistics and
  Machine Learning toolboxes). See README.
- [x] **Version-controlled release.** v1.0.0 is tagged; a Zenodo DOI is
  minted at release.

## ✔ Reference data

- [x] **Frozen tracker CSV** for the Dataset 2 adjudicated validation
  subset (`data/dataset2_validation/auto_tracker_results.csv`). Every
  metric in Tables 9–14 of the manuscript can be recomputed from this
  file.
- [x] **Frozen tracker CSV** for the Dataset 3 held-out validation
  interval (`data/dataset3_validation/`). Every metric in Table 16 can
  be recomputed from this file.
- [x] **Column schema** for every released CSV is documented
  (`data/README.md`).
- [x] **Annotation protocol** is published as supplementary material
  and also in this repo (`docs/annotation_guide.md`).
- [x] **Adjudication summary statistics** (inter-annotator discrepancy,
  frames auto-resolved vs. manually adjudicated) are reported.

## ✔ Executable walkthrough

- [x] **Sample walkthrough** regenerates the trajectory- and event-level
  results from the released CSV without requiring access to the raw
  images (`examples/walkthrough.md`).
- [x] **Expected outputs** are documented so the reader can verify that
  their run matches the published numbers.

## ⚠ Partial / by-request

- [ ] **Raw image sequences** are not redistributed. Dataset 1 (10,800
  frames), Dataset 2 (10,800 frames), and Dataset 3 (32,400 frames)
  total ≈200 GB and are tied to specific live-animal experiments.
  Available from the corresponding author on reasonable request.
  *Rationale:* size and animal-specific provenance, not an IP
  restriction.
- [ ] **Re-running from raw frames** requires the raw images above.
  Everything downstream of the frozen tracker CSV can be rerun from
  the CSV alone.

## ✔ Licensing and citation

- [x] **Code license:** MIT.
- [x] **Data license:** CC BY 4.0.
- [x] **CITATION.cff** provided so GitHub shows a "Cite this repository"
  button.
- [x] **Zenodo metadata** (`.zenodo.json`) provided so the mint-on-release
  integration produces a properly-described record.

## ✔ Provenance

- [x] **Role-based split** between development (Dataset 1) and formal
  validation (Dataset 2, Dataset 3) is documented in the manuscript
  (Section 2.3) and re-stated in `data/README.md`.
- [x] **Leakage controls.** Dataset 2 was excluded from tuning and
  first-pass manual annotation was performed without viewing the
  automated outputs. See `docs/annotation_guide.md` §6.

## Known limitations of this release

- Formal accuracy reporting rests on two held-out annotated sequences
  from different individuals. Extending the validation corpus to more
  substrates, more individuals, and more species is called out as
  future work in Section 4.6 of the manuscript.
- The bedline is user-defined on the first frame and held fixed. Active
  bed evolution (scour, deposition, bedload) is outside the current
  operating envelope.
- Every validated sequence contained exactly one positive committed
  burrowing event and no positive resurfacing event. Event-level
  metrics should therefore be read as sequence-specific agreement
  descriptors rather than stable estimates of general detector
  performance. This is stated explicitly in Sections 3.4, 3.7, 4.1, and
  4.4 of the manuscript.
