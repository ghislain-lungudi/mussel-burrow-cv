# Executable walkthrough

This walkthrough regenerates the trajectory-level figures and event-level
summary reported in the manuscript using **only** the files included in
this repository. It does not require access to the raw image stacks.

Expected runtime: under one minute on a modern laptop.

## Prerequisites

- MATLAB R2022a or later.
- Working directory set to the repository root.

## Step 1 — Load the frozen tracker CSV

```matlab
csv_path = fullfile('data','dataset2_validation','auto_tracker_results.csv');
T = readtable(csv_path);

fprintf('Loaded %d frames over %.1f minutes.\n', height(T), T.time_s(end)/60);
```

Expected output:

```
Loaded 1001 frames over 33.3 minutes.
```

## Step 2 — Reproduce Figure 12 (trajectory overlay)

If you also have the adjudicated manual reference CSV
(`manual_reference_dataset2.csv`; available from the corresponding author
on request, or from your own re-annotation run), you can overlay it:

```matlab
figure;
plot(T.time_s/60, T.burrow_smooth_mm, 'LineWidth', 1.2); hold on;
% plot(Tref.time_s/60, Tref.burrow_mm, 'LineWidth', 1.0);   % optional manual overlay
xlabel('Time (min)');
ylabel('Burrow depth (mm)');
title('Trajectory overlay: burrow depth');
legend({'Automated'}, 'Location', 'southeast');
grid on;
```

The automated trace should rise from approximately 45.3 mm at t = 0 to
approximately 47.0 mm at t = 33 min, with the main step near t ≈ 20 min
and a smaller excursion near t ≈ 15 min. This is the pattern shown in
Figure 12 of the manuscript.

## Step 3 — Recompute the headline trajectory metrics

With a manual-reference trajectory `Dm` aligned to the same time axis as
`T.burrow_smooth_mm`, the headline numbers from Table 11 are:

```matlab
Da = T.burrow_smooth_mm;
% Dm = Tref.burrow_mm;                   % manual reference (not redistributed)

resid  = Da - Dm;
rmse   = sqrt(mean(resid.^2));
mae    = mean(abs(resid));
bias   = mean(resid);
pearsonR = corr(Da, Dm);
ccc      = concordanceCorrelation(Da, Dm);   % helper; see below

fprintf('RMSE = %.3f mm\nMAE  = %.3f mm\nBias = %.3f mm\nr    = %.3f\nCCC  = %.3f\n', ...
        rmse, mae, bias, pearsonR, ccc);
```

On the frozen CSV and the adjudicated manual reference, you should get:

```
RMSE = 0.302 mm
MAE  = 0.248 mm
Bias = -0.216 mm
r    =  0.950
CCC  =  0.903
```

These are exactly the numbers in Table 11 of the manuscript.

### Helper: Lin's concordance correlation coefficient

```matlab
function rhoC = concordanceCorrelation(x, y)
    mx = mean(x); my = mean(y);
    vx = var(x, 1); vy = var(y, 1);
    cov_xy = mean((x - mx) .* (y - my));
    rhoC = (2 * cov_xy) / (vx + vy + (mx - my)^2);
end
```

## Step 4 — Reproduce the event timeline (Figure 16)

```matlab
cfg.variant = 'full';
detector_out = detect_events_v10(T, cfg);

disp(detector_out.summary);
disp(detector_out.events);
```

Expected: one burrowing event, zero resurfacing events, latency to first
committed burrow ≈ 7.57 min, event end ≈ 33.3 min, matching Tables 12–13.

## Step 5 — Run an ablation

To reproduce the `no_multiscale` detector row of Table 15:

```matlab
cfg.variant = 'no_multiscale';
ablated_out = detect_events_v10(T, cfg);

disp(ablated_out.summary);
```

Expected: one burrowing bout (same net depth change, 1.372 mm), but the
bout is **not** classified as committed under this ablation, and the
latency to first committed burrow is undefined — exactly as reported in
the manuscript's detector-ablation row.

## Step 6 — Regenerate the Bland–Altman plot (Figure 15)

```matlab
mean_vals = (Da + Dm) / 2;
diffs     = Da - Dm;
loa_mean  = mean(diffs);
loa_sd    = std(diffs);
upper_loa = loa_mean + 1.96 * loa_sd;
lower_loa = loa_mean - 1.96 * loa_sd;

figure;
scatter(mean_vals, diffs, 8, 'filled'); hold on;
yline(loa_mean, '-');
yline(upper_loa, '--');
yline(lower_loa, '--');
xlabel('Mean of manual and automated burrow depth (mm)');
ylabel('Auto - Manual (mm)');
title('Bland-Altman plot: burrow depth');
grid on;

fprintf('Mean diff = %.3f mm, 95%% LoA = [%.3f, %.3f] mm\n', loa_mean, lower_loa, upper_loa);
```

Expected: mean difference ≈ −0.216 mm, 95% LoA ≈ [−0.629, 0.198] mm, as
reported in Table 11.

## What to do if the numbers don't match

If you recompute these values from the released CSV and get something
different, please open an issue on GitHub with:

1. The exact MATLAB version and toolbox versions (`ver` output).
2. The first few rows of your loaded table (`head(T)`).
3. The numbers you got.

Small differences at the fourth decimal place are expected from rounding
and from minor floating-point non-determinism in smoothing routines.
Differences at the second decimal place or larger suggest a real
reproducibility bug and we would like to fix it.
