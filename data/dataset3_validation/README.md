# Dataset 3 held-out validation output

`auto_tracker_results_dataset3.csv` is the frozen output of the full
tracker (`cfg.variant = 'full'`) applied to the 6001-frame held-out
validation interval from Dataset 3 (frames 18,000–24,000 of the 18 h
acquisition, corresponding to 200 min at 0.5 Hz).

This file is the source of every metric reported in Section 3.7 of the
manuscript (Table 16, Figures 27–29). It was produced from a **different
mussel individual** than Dataset 2 and was processed with the frozen
pipeline without any further tuning.

The column schema is identical to
`../dataset2_validation/auto_tracker_results.csv` — see `../README.md`
for the full column-by-column description.

## Reproducing Table 16 from this CSV

```matlab
csv_path = fullfile('data','dataset3_validation','auto_tracker_results_dataset3.csv');
T = readtable(csv_path);
fprintf('Loaded %d frames over %.1f minutes.\n', height(T), T.time_s(end)/60);
```

Expected output:

```
Loaded 6001 frames over 200.0 minutes.
```

From there, follow `examples/walkthrough.md` with `csv_path` pointing
here to recompute:

- Mean Euclidean shell-top error: 0.218 mm
- Burrow-depth RMSE: 0.192 mm
- Lin's concordance correlation coefficient: 0.995
- Burrowing precision / recall / F1: 1.00 / 1.00 / 1.00
- Median burrowing tIoU: 0.984
