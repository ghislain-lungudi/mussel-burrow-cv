# Data Availability Statement

The following statement accompanies the manuscript and is reproduced here
so the repository stays consistent with the published paper.

---

**Data and code availability.** The source code for the shell-top tracker
(`mussel_tracker_v9.m`) and for the multiscale quality-aware event
detector (`detect_events_v10.m`), together with the frozen auto-tracker
output tables used to produce the trajectory-level, event-level, and
trial-level validation metrics reported in Section 3, are openly available
in the GitHub repository

    https://github.com/ghislain-lungudi/mussel-burrow-cv

and are permanently archived on Zenodo with DOI

    10.5281/zenodo.XXXXXXX

(both links will be finalized at acceptance). The repository also contains
the written annotation guide used to construct the manual reference
trajectory, an executable walkthrough that regenerates the trajectory- and
event-level figures from the released CSVs, and the exact ablation switches
corresponding to the tracker and detector variants reported in Table 15.

The raw side-view image sequences — Dataset 1 (10,800 frames),
Dataset 2 (10,800 frames), and Dataset 3 (32,400 frames) — are not
redistributed in the repository because the full image archive is on the
order of 200 GB and is tied to specific live-animal experiments. The raw
image sequences are available from the corresponding author on reasonable
request.

All manual reference annotations, adjudication outputs, and derived
trajectory/event CSVs used as ground truth in Section 3 are released under
CC BY 4.0; the software is released under the MIT License.

---

## Notes for reviewers

- The frozen CSV at `data/dataset2_validation/auto_tracker_results.csv`
  is the exact output used to produce the numbers in Tables 9–14 and the
  corresponding figures (Figures 8–17) for the primary held-out
  validation subset. You can reproduce those numbers without access to
  the raw image stack.
- The Dataset 3 held-out validation CSV
  (`data/dataset3_validation/`) is released on the same basis.
- Dataset 1 was used exclusively for development and parameter tuning,
  and therefore does not appear in the released validation tables. This
  is an intentional design choice (role-based split; see Section 2.3 of
  the manuscript).
- If you want to re-run the pipeline end-to-end on the raw frames rather
  than from the frozen tracker CSV, contact the corresponding author for
  access to Dataset 2 or Dataset 3.
