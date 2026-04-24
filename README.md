# mussel-burrow-cv

A computer vision framework for quantifying freshwater mussel burrowing under
hydraulic flume conditions from side-view image sequences.

This repository accompanies the manuscript:

> Lungudi, G. O., Wyssmann, M., Sansom, B., McMurray, S., Wszola, L.
> *A computer vision framework for quantifying freshwater mussel burrowing under
> hydraulic flume conditions from side-view image sequences.*
> Submitted to *Ecological Informatics*.

[![License: MIT](https://img.shields.io/badge/Code%20License-MIT-blue.svg)](LICENSE)
[![Data License: CC BY 4.0](https://img.shields.io/badge/Data%20License-CC%20BY%204.0-lightgrey.svg)](LICENSE-DATA)
<!-- After first Zenodo release, replace the placeholder below with the real DOI badge -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19741089.svg)](https://doi.org/10.5281/zenodo.19741089)

---

## What this code does

The pipeline converts a temporally ordered side-view image sequence (0.5 Hz) of
a freshwater mussel in a hydraulic flume into:

1. a frame-wise shell-top localization,
2. a quality-aware burrow-depth trajectory,
3. a set of burrowing / resurfacing events with confidence labels, and
4. trial-level summary metrics (latency, net depth change, peak rate, path
   length, wiggle ratio, effort, etc.).

It is an auditable measurement chain: every downstream number can be traced
back to the frames that supported it, the frames whose evidence was rejected,
and the rules by which that decision was made.

## Repository layout

```
mussel-burrow-cv/
├── code/                          # MATLAB source for the full pipeline
│   ├── mussel_tracker_v9.m        # Hybrid shell-top tracker with guards
│   ├── detect_events_v10.m        # Multiscale burrow/resurfacing detector
│   └── annotation/                # Manual reference construction tools
│       ├── apex_manual_tracking.m       # Frame-by-frame shell-top annotator
│       └── inter_annotator_comparison.m # A1/A2 adjudication + consensus export
├── data/
│   ├── dataset2_validation/       # Frozen auto-tracker output for Dataset 2 subset
│   ├── dataset3_validation/       # Frozen auto-tracker output for Dataset 3 interval
│   ├── sample/                    # Small demo inputs for the executable walkthrough
│   └── README.md                  # What's here, what's not, and why
├── docs/
│   ├── annotation_guide.md        # Shell-top annotation protocol used to build the reference
│   ├── data_availability.md       # Data Availability Statement as used in the manuscript
│   └── reproducibility_checklist.md
├── examples/
│   └── walkthrough.md             # End-to-end demo that regenerates one figure
├── reproducibility_materials/     # Original Live Script (.mlx) sources
├── CITATION.cff
├── CHANGELOG.md
├── LICENSE                        # MIT (code)
├── LICENSE-DATA                   # CC BY 4.0 (annotations, CSVs)
├── .gitignore
├── .zenodo.json                   # Metadata Zenodo reads on release
├── PUBLISH.md                     # Step-by-step guide to publishing the repo
└── README.md
```

## Requirements

- **MATLAB R2022a or later** (tested on R2023b).
- Toolboxes:
  - Image Processing Toolbox
  - Computer Vision Toolbox
  - Signal Processing Toolbox
  - Statistics and Machine Learning Toolbox

No external internet connection is required at runtime.

## Quick start

### 1. Clone

```bash
git clone https://github.com/ghislain-lungudi/mussel-burrow-cv.git
cd mussel-burrow-cv
```

### 2. Run the tracker on your own image sequence

Open `code/mussel_tracker_v9.m` in MATLAB and set the three user parameters at
the top of the script:

```matlab
params.folder          = '/path/to/your/frames';   % folder containing the .tif stack
params.pattern         = 'Image*.tif';
params.mm_per_px       = 1/35.19;                  % from your metric calibration
params.mussel_length_mm = 81.33;                   % from direct measurement
params.bed_px_guess     = 4145;                    % approximate bedline in pixels
```

On the first frame the script will prompt you to:

1. draw the region of interest,
2. mark the fixed bedline,
3. click the initial shell-top seed.

Output: a CSV (`auto_tracker_results.csv`) with the frame-wise trajectory in
the same format as `data/dataset2_validation/auto_tracker_results.csv`.

### 3. Run the event detector on the tracker output

```matlab
% In MATLAB:
detect_events_v10
```

Set `params.input_csv` to the CSV produced in step 2. The detector emits event
intervals, committed-event labels, and trial-level summary metrics.

### 4. Ablations

`cfg.variant` at the top of `mussel_tracker_v9.m` controls which pipeline
modules are active. Options:

| Variant | What it does |
|---|---|
| `'full'` | Reference configuration used in the paper |
| `'template_only'` | Disables feature support and edge refinement |
| `'no_edge_refinement'` | Disables the contour-based geometric refinement |
| `'motion_only'` | Disables template matching and edge refinement |
| `'no_feature_support'` | Disables the feature-support stage |
| `'no_confidence_logic'` | Disables quality labels and plausibility rejection |
| `'no_recovery_logic'` | Disables the trajectory recovery mode |

The detector has an analogous switch (`cfg.variant`) for `'simple'` and
`'no_multiscale'` ablations. These are the exact variants whose results appear
in Table 15 of the manuscript.

### 5. Reproducing the manual reference (optional)

If you have access to the raw image frames (available from the corresponding
author on reasonable request) and want to reconstruct the adjudicated manual
reference end-to-end rather than use the consensus CSV directly, use the
annotation tools under `code/annotation/`:

1. Two annotators run `apex_manual_tracking.m` independently on the same
   frame range, each producing a per-annotator CSV.
2. `inter_annotator_comparison.m` computes per-frame discrepancies, applies
   the two-threshold adjudication rule, opens an interactive review panel
   for flagged frames, and writes the consensus CSV.

This is the pipeline that produced the inter-annotator statistics in
Table 8 of the manuscript (mean discrepancy 55.08 px; 336 frames
auto-resolved; 665 frames manually adjudicated). See
`code/annotation/README.md` for the full protocol.

## Reproducing the figures in the paper

`data/dataset2_validation/auto_tracker_results.csv` is the frozen tracker
output for the 1001-frame adjudicated validation subset from Dataset 2 (the
sequence analyzed in Section 3.2–3.5 of the paper). It is included so that
reviewers can regenerate the trajectory-level and event-level figures without
needing access to the raw images (≈70 GB of uncompressed TIFs).

To regenerate Figures 12–15 from this CSV:

```matlab
% See examples/walkthrough.md for the full step-by-step script.
T = readtable('data/dataset2_validation/auto_tracker_results.csv');
plot(T.time_s/60, T.burrow_smooth_mm);
xlabel('Time (min)'); ylabel('Burrow depth (mm)');
```

See [`examples/walkthrough.md`](examples/walkthrough.md) for the complete
worked example.

## Data availability

The raw image datasets (Dataset 1: 10,800 frames; Dataset 2: 10,800 frames;
Dataset 3: 32,400 frames) are not redistributed here because the full image
archive is ≈200 GB and is tied to specific live-animal experiments. They are
available from the corresponding author on reasonable request.

What **is** in the repository:

- The full MATLAB source for the tracker and detector (`code/`).
- The frozen tracker output for the Dataset 2 validation subset and the
  Dataset 3 validation interval (`data/`).
- The adjudicated manual annotation CSVs that were used to produce every
  validation metric reported in Section 3 (`data/*_validation/`).
- The annotation guide used to construct the manual reference
  ([`docs/annotation_guide.md`](docs/annotation_guide.md)).

See [`docs/data_availability.md`](docs/data_availability.md) for the exact
statement used in the manuscript.

## How to cite

If you use this code or the released validation tables, please cite both the
paper and this software release:

```bibtex
@article{Lungudi2026MusselBurrowCV,
  title   = {A computer vision framework for quantifying freshwater mussel burrowing
             under hydraulic flume conditions from side-view image sequences},
  author  = {Lungudi, Ghislain O. and Wyssmann, Micah and Sansom, Brandon
             and McMurray, Steve and Wszola, Lyndsie},
  journal = {Ecological Informatics},
  year    = {2026},
  note    = {In review}
}

@software{Lungudi2026MusselBurrowCVCode,
  author  = {Lungudi, Ghislain O. and Wyssmann, Micah and Sansom, Brandon
             and McMurray, Steve and Wszola, Lyndsie},
  title   = {mussel-burrow-cv: computer vision framework for freshwater mussel burrowing},
  year    = {2026},
  version = {v1.0.0},
  doi     = {10.5281/zenodo.19741089},
  url     = {https://github.com/ghislain-lungudi/mussel-burrow-cv}
}
```

A citable archive of this repository is minted automatically on Zenodo at each
GitHub release.

## License

- **Code** (everything under `code/` and `examples/`): [MIT](LICENSE).
- **Data / annotations** (everything under `data/` and `docs/`):
  [CC BY 4.0](LICENSE-DATA).

## Contact

Ghislain O. Lungudi — `ghislainlungudi@gmail.com`
Department of Civil Engineering, University of Missouri–Kansas City.

Issues and pull requests are welcome via GitHub.
