%% manual_annotation_compare_and_consensus_auto_detector_ready.m
% Inter-annotator comparison + automatic adjudication + detector-ready export
%
% Final exported detector CSV matches the detector requirements:
%   time_s
%   burrow_smooth_mm
%   dBurrow_dt_mmps
%   optional mask_detected
%
% Also keeps extra columns for traceability.
%
% FIXES v2:
%   - All ginput() calls wrapped in try/catch to survive figure deletion
%   - Interactive scroll-wheel zoom + pan on the full-image axes during review
%   - Zoom panel syncs to clicked/current region when zooming

clear; close all; clc;

%% =====================================================================
%                         USER PARAMETERS
% ======================================================================

params.folder                    = 'E:\Computer vision Paper\dataset_2\subset_1';
params.pattern                   = 'Image*.tif';

params.a1_csv                    = fullfile(params.folder, 'manual_annotations_A1.csv');
params.a2_csv                    = fullfile(params.folder, 'manual_annotations_A2.csv');

params.output_comparison         = fullfile(params.folder, 'annotation_comparison_summary.csv');
params.output_consensus_csv      = fullfile(params.folder, 'consensus_annotations.csv');
params.output_consensus_mat      = fullfile(params.folder, 'consensus_annotations.mat');
params.output_detector_ready_csv = fullfile(params.folder, 'manual_detector_input.csv');

params.auto_agree_px             = 10;   % <= this: average A1 and A2
params.manual_review_px          = 35;   % > this: manual review

params.show_zoom_panel           = true;
params.zoom_half_width           = 120;
params.zoom_half_height          = 120;
params.marker_size               = 10;
params.line_width                = 1.5;
params.font_size                 = 12;

params.use_bedline               = true;
params.bedline_file              = fullfile(params.folder, 'bed_line.mat');

% Calibration / mussel size
params.mm_per_px                 = 1/35.19;   % mm/px
params.mussel_length_px          = [];
params.mussel_length_mm          = 81.33;

if isempty(params.mussel_length_px) && ~isempty(params.mussel_length_mm) && ~isempty(params.mm_per_px)
    params.mussel_length_px = params.mussel_length_mm / params.mm_per_px;
end

%% =====================================================================
%                         LOAD DATA
% ======================================================================

assert(exist(params.a1_csv, 'file') == 2, 'A1 CSV not found.');
assert(exist(params.a2_csv, 'file') == 2, 'A2 CSV not found.');

T1 = readtable(params.a1_csv);
T2 = readtable(params.a2_csv);

assert(ismember('frame_idx', T1.Properties.VariableNames), 'A1 CSV missing frame_idx.');
assert(ismember('frame_idx', T2.Properties.VariableNames), 'A2 CSV missing frame_idx.');

keyVars = {'frame_idx','filename','time_s'};

vars1 = T1.Properties.VariableNames;
vars2 = T2.Properties.VariableNames;

for i = 1:numel(vars1)
    if ~ismember(vars1{i}, keyVars)
        vars1{i} = [vars1{i} '_A1'];
    end
end
T1.Properties.VariableNames = vars1;

for i = 1:numel(vars2)
    if ~ismember(vars2{i}, keyVars)
        vars2{i} = [vars2{i} '_A2'];
    end
end
T2.Properties.VariableNames = vars2;

T = outerjoin(T1, T2, ...
    'Keys', {'frame_idx','filename','time_s'}, ...
    'MergeKeys', true, ...
    'Type', 'full');

nRows = size(T,1);

%% =====================================================================
%                    NATURAL-SORT IMAGE FILES
% ======================================================================

files = dir(fullfile(params.folder, params.pattern));
assert(~isempty(files), 'No image files found.');

[~, idx] = sort_nat({files.name});
files = files(idx);

%% =====================================================================
%                         LOAD BED LINE
% ======================================================================

bed = struct('enabled', false, 'x1', [], 'y1', [], 'x2', [], 'y2', []);
if params.use_bedline && exist(params.bedline_file, 'file') == 2
    S = load(params.bedline_file);
    bed = parse_bedline_struct(S);
end

%% =====================================================================
%                  COMPUTE INTER-ANNOTATOR DISCREPANCY
% ======================================================================

T.dx_px = T.x_top_px_A2 - T.x_top_px_A1;
T.dy_px = T.y_top_px_A2 - T.y_top_px_A1;
T.euclid_px = sqrt(T.dx_px.^2 + T.dy_px.^2);

T.has_both = ~isnan(T.x_top_px_A1) & ~isnan(T.y_top_px_A1) & ...
             ~isnan(T.x_top_px_A2) & ~isnan(T.y_top_px_A2);

T.flag_missing_one = ...
    (isnan(T.x_top_px_A1) ~= isnan(T.x_top_px_A2)) | ...
    (isnan(T.y_top_px_A1) ~= isnan(T.y_top_px_A2));

T.height_above_bed_A1 = nan(nRows,1);
T.height_above_bed_A2 = nan(nRows,1);

if bed.enabled
    for i = 1:nRows
        if ~isnan(T.x_top_px_A1(i)) && ~isnan(T.y_top_px_A1(i))
            yb1 = bed_y_at_x(bed, T.x_top_px_A1(i));
            T.height_above_bed_A1(i) = yb1 - T.y_top_px_A1(i);
        end
        if ~isnan(T.x_top_px_A2(i)) && ~isnan(T.y_top_px_A2(i))
            yb2 = bed_y_at_x(bed, T.x_top_px_A2(i));
            T.height_above_bed_A2(i) = yb2 - T.y_top_px_A2(i);
        end
    end
end

T.flag_manual_review = false(nRows,1);
T.flag_manual_review(T.has_both & T.euclid_px > params.manual_review_px) = true;
T.flag_manual_review(T.flag_missing_one) = true;

validErr = T.euclid_px(T.has_both);
summaryStats.mean_px         = mean(validErr, 'omitnan');
summaryStats.median_px       = median(validErr, 'omitnan');
summaryStats.std_px          = std(validErr, 'omitnan');
summaryStats.rmse_px         = sqrt(mean(validErr.^2, 'omitnan'));
summaryStats.n_both          = sum(T.has_both);
summaryStats.n_manual_review = sum(T.flag_manual_review);

fprintf('\nInter-annotator summary:\n');
fprintf('  Frames with both points: %d\n', summaryStats.n_both);
fprintf('  Mean discrepancy (px):   %.3f\n', summaryStats.mean_px);
fprintf('  Median discrepancy (px): %.3f\n', summaryStats.median_px);
fprintf('  RMSE discrepancy (px):   %.3f\n', summaryStats.rmse_px);
fprintf('  Frames flagged review:   %d\n\n', summaryStats.n_manual_review);

writetable(T, params.output_comparison);
fprintf('Saved comparison table:\n  %s\n', params.output_comparison);

%% =====================================================================
%                     INITIALIZE CONSENSUS TABLE
% ======================================================================

C = table();
C.frame_idx = T.frame_idx;
C.filename  = T.filename;
C.time_s    = T.time_s;

C.x_top_px  = nan(nRows,1);
C.y_top_px  = nan(nRows,1);
C.source    = strings(nRows,1);
C.note      = strings(nRows,1);

for i = 1:nRows
    hasA1 = ~isnan(T.x_top_px_A1(i)) && ~isnan(T.y_top_px_A1(i));
    hasA2 = ~isnan(T.x_top_px_A2(i)) && ~isnan(T.y_top_px_A2(i));

    if hasA1 && hasA2
        if T.euclid_px(i) <= params.auto_agree_px
            C.x_top_px(i) = mean([T.x_top_px_A1(i), T.x_top_px_A2(i)]);
            C.y_top_px(i) = mean([T.y_top_px_A1(i), T.y_top_px_A2(i)]);
            C.source(i)   = "auto_agree";
        elseif T.euclid_px(i) <= params.manual_review_px
            if ~isnan(T.height_above_bed_A1(i)) && ~isnan(T.height_above_bed_A2(i))
                if T.height_above_bed_A1(i) >= T.height_above_bed_A2(i)
                    C.x_top_px(i) = T.x_top_px_A1(i);
                    C.y_top_px(i) = T.y_top_px_A1(i);
                    C.source(i)   = "auto_A1_higher";
                else
                    C.x_top_px(i) = T.x_top_px_A2(i);
                    C.y_top_px(i) = T.y_top_px_A2(i);
                    C.source(i)   = "auto_A2_higher";
                end
            else
                C.x_top_px(i) = mean([T.x_top_px_A1(i), T.x_top_px_A2(i)], 'omitnan');
                C.y_top_px(i) = mean([T.y_top_px_A1(i), T.y_top_px_A2(i)], 'omitnan');
                C.source(i)   = "auto_fallback_mean";
            end
        end
    elseif hasA1 && ~hasA2
        C.x_top_px(i) = T.x_top_px_A1(i);
        C.y_top_px(i) = T.y_top_px_A1(i);
        C.source(i)   = "A1_only";
    elseif ~hasA1 && hasA2
        C.x_top_px(i) = T.x_top_px_A2(i);
        C.y_top_px(i) = T.y_top_px_A2(i);
        C.source(i)   = "A2_only";
    end
end

reviewIdx = find(T.flag_manual_review);

fprintf('Automatic consensus assigned to %d frames.\n', sum(strlength(C.source) > 0));
fprintf('Frames remaining for manual review: %d\n', numel(reviewIdx));

%% =====================================================================
%                      REVIEW / ADJUDICATION LOOP
% ======================================================================

if ~isempty(reviewIdx)
    r = 1;
    hFig = figure('Name', 'Consensus / Adjudication Viewer', ...
        'Color', 'w', 'NumberTitle', 'off', 'Units', 'normalized', ...
        'Position', [0.05 0.05 0.9 0.85]);

    % ── Zoom state (per-frame, resets on frame change) ──────────────────
    zoomState = struct('active', false, 'xlim', [], 'ylim', []);

    % Attach scroll-wheel zoom callback to the figure
    set(hFig, 'WindowScrollWheelFcn', @(src, ev) scrollZoom(src, ev));

    while ishandle(hFig)
        clf(hFig);

        % Re-attach scroll callback after clf clears it
        set(hFig, 'WindowScrollWheelFcn', @(src, ev) scrollZoom(src, ev));

        idxRow = reviewIdx(r);
        I = imread(fullfile(params.folder, char(T.filename(idxRow))));
        [imgH, imgW, ~] = size(I);

        % Default zoom covers full image
        if ~zoomState.active
            zoomState.xlim = [0.5, imgW + 0.5];
            zoomState.ylim = [0.5, imgH + 0.5];
        end

        ax1 = subplot(1,2,1, 'Parent', hFig);
        imshow(I, [], 'Parent', ax1); hold(ax1, 'on');

        % Apply current zoom limits
        set(ax1, 'XLim', zoomState.xlim, 'YLim', zoomState.ylim);

        title(ax1, sprintf('Manual review  %d / %d  |  frame_idx = %d  |  %s', ...
            r, numel(reviewIdx), T.frame_idx(idxRow), char(T.filename(idxRow))), ...
            'FontSize', params.font_size, 'Interpreter', 'none');

        if bed.enabled
            plot(ax1, [bed.x1 bed.x2], [bed.y1 bed.y2], 'c-', 'LineWidth', 1.5);
        end

        if ~isnan(T.x_top_px_A1(idxRow))
            plot(ax1, T.x_top_px_A1(idxRow), T.y_top_px_A1(idxRow), 'go', ...
                'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
            text(ax1, T.x_top_px_A1(idxRow)+10, T.y_top_px_A1(idxRow), 'A1', ...
                'Color', 'g', 'FontWeight', 'bold');
        end

        if ~isnan(T.x_top_px_A2(idxRow))
            plot(ax1, T.x_top_px_A2(idxRow), T.y_top_px_A2(idxRow), 'mo', ...
                'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
            text(ax1, T.x_top_px_A2(idxRow)+10, T.y_top_px_A2(idxRow), 'A2', ...
                'Color', 'm', 'FontWeight', 'bold');
        end

        if ~isnan(C.x_top_px(idxRow))
            plot(ax1, C.x_top_px(idxRow), C.y_top_px(idxRow), 'ro', ...
                'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
            text(ax1, C.x_top_px(idxRow)+10, C.y_top_px(idxRow), 'Consensus', ...
                'Color', 'r', 'FontWeight', 'bold');
        end

        infoStr = sprintf(['dx = %.2f px\n' ...
                           'dy = %.2f px\n' ...
                           'euclid = %.2f px\n' ...
                           'A1 h_bed = %.2f px\n' ...
                           'A2 h_bed = %.2f px\n' ...
                           'Current source = %s\n\n' ...
                           'Keys:\n' ...
                           '1 = use A1\n' ...
                           '2 = use A2\n' ...
                           'c = click new consensus\n' ...
                           'z = reset zoom\n' ...
                           'n / Enter = next\n' ...
                           'b = back\n' ...
                           's = save\n' ...
                           'q = save + quit\n\n' ...
                           'Scroll to zoom left panel'], ...
                           T.dx_px(idxRow), T.dy_px(idxRow), T.euclid_px(idxRow), ...
                           T.height_above_bed_A1(idxRow), T.height_above_bed_A2(idxRow), ...
                           string_or_empty(C.source(idxRow)));

        text(ax1, 10, 30, infoStr, 'Color', 'y', 'FontSize', 10, ...
            'VerticalAlignment', 'top', 'BackgroundColor', 'k', 'Margin', 6, ...
            'Units', 'data');

        % ── Right panel: fixed zoom thumbnail around markers ─────────────
        if params.show_zoom_panel
            ax2 = subplot(1,2,2, 'Parent', hFig);

            xvals = [T.x_top_px_A1(idxRow), T.x_top_px_A2(idxRow), C.x_top_px(idxRow)];
            yvals = [T.y_top_px_A1(idxRow), T.y_top_px_A2(idxRow), C.y_top_px(idxRow)];

            xz = mean(xvals(~isnan(xvals)));
            yz = mean(yvals(~isnan(yvals)));

            if isempty(xz) || isnan(xz), xz = imgW/2; end
            if isempty(yz) || isnan(yz), yz = imgH/2; end

            [cropIm, xlimZoom, ylimZoom] = get_zoom_patch(I, xz, yz, ...
                params.zoom_half_width, params.zoom_half_height);
            imshow(cropIm, [], 'Parent', ax2); hold(ax2, 'on');
            title(ax2, 'Fixed zoom (A1 / A2 / consensus)', 'FontSize', params.font_size);

            if bed.enabled
                xx = [bed.x1 bed.x2];
                yy = [bed.y1 bed.y2];
                plot(ax2, xx - xlimZoom(1) + 1, yy - ylimZoom(1) + 1, ...
                    'c-', 'LineWidth', 1.2);
            end

            if ~isnan(T.x_top_px_A1(idxRow))
                plot(ax2, T.x_top_px_A1(idxRow)-xlimZoom(1)+1, T.y_top_px_A1(idxRow)-ylimZoom(1)+1, ...
                    'go', 'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
            end
            if ~isnan(T.x_top_px_A2(idxRow))
                plot(ax2, T.x_top_px_A2(idxRow)-xlimZoom(1)+1, T.y_top_px_A2(idxRow)-ylimZoom(1)+1, ...
                    'mo', 'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
            end
            if ~isnan(C.x_top_px(idxRow))
                plot(ax2, C.x_top_px(idxRow)-xlimZoom(1)+1, C.y_top_px(idxRow)-ylimZoom(1)+1, ...
                    'ro', 'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
            end
        end

        drawnow;

        % ── Wait for keypress via ginput ─────────────────────────────────
        % Wrapped in try/catch so figure closure does not throw an error.
        try
            figure(hFig);
            [~, ~, button] = ginput(1);
        catch
            fprintf('Figure closed – exiting review loop.\n');
            break;
        end

        if isempty(button)
            continue;
        end

        switch button
            case 49  % '1'
                if ~isnan(T.x_top_px_A1(idxRow))
                    C.x_top_px(idxRow) = T.x_top_px_A1(idxRow);
                    C.y_top_px(idxRow) = T.y_top_px_A1(idxRow);
                    C.source(idxRow)   = "A1_manual";
                end
                r = min(r+1, numel(reviewIdx));
                zoomState.active = false;

            case 50  % '2'
                if ~isnan(T.x_top_px_A2(idxRow))
                    C.x_top_px(idxRow) = T.x_top_px_A2(idxRow);
                    C.y_top_px(idxRow) = T.y_top_px_A2(idxRow);
                    C.source(idxRow)   = "A2_manual";
                end
                r = min(r+1, numel(reviewIdx));
                zoomState.active = false;

            case 99  % 'c' – manual click
                if ~ishandle(hFig), break; end
                clf(hFig);
                set(hFig, 'WindowScrollWheelFcn', @(src, ev) scrollZoom(src, ev));

                ax = axes('Parent', hFig);
                imshow(I, [], 'Parent', ax); hold(ax, 'on');
                % Restore any active zoom so the click is in context
                set(ax, 'XLim', zoomState.xlim, 'YLim', zoomState.ylim);

                title(ax, sprintf('Click consensus point for frame %d (%s)', ...
                    T.frame_idx(idxRow), char(T.filename(idxRow))), ...
                    'FontSize', params.font_size, 'Interpreter', 'none');

                if bed.enabled
                    plot(ax, [bed.x1 bed.x2], [bed.y1 bed.y2], 'c-', 'LineWidth', 1.5);
                end
                if ~isnan(T.x_top_px_A1(idxRow))
                    plot(ax, T.x_top_px_A1(idxRow), T.y_top_px_A1(idxRow), 'go', ...
                        'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
                end
                if ~isnan(T.x_top_px_A2(idxRow))
                    plot(ax, T.x_top_px_A2(idxRow), T.y_top_px_A2(idxRow), 'mo', ...
                        'MarkerSize', params.marker_size, 'LineWidth', params.line_width);
                end

                text(ax, 10, 30, sprintf('Scroll to zoom  |  Left-click = place consensus'), ...
                    'Color', 'y', 'FontSize', 11, 'BackgroundColor', 'k', 'Margin', 6, ...
                    'VerticalAlignment', 'top');
                drawnow;

                try
                    [xManual, yManual, b2] = ginput(1);
                catch
                    fprintf('Figure closed during manual click – skipping.\n');
                    break;
                end
                if ~isempty(b2) && b2 == 1
                    C.x_top_px(idxRow) = xManual;
                    C.y_top_px(idxRow) = yManual;
                    C.source(idxRow)   = "manual_click";
                end
                r = min(r+1, numel(reviewIdx));
                zoomState.active = false;

            case 122  % 'z' – reset zoom
                zoomState.active = false;
                zoomState.xlim   = [0.5, imgW + 0.5];
                zoomState.ylim   = [0.5, imgH + 0.5];

            case {110, 13}  % 'n' or Enter
                r = min(r+1, numel(reviewIdx));
                zoomState.active = false;

            case 98   % 'b'
                r = max(r-1, 1);
                zoomState.active = false;

            case 115  % 's'
                writetable(C, params.output_consensus_csv);
                save(params.output_consensus_mat, 'C', 'T', 'summaryStats', 'params', 'bed');
                fprintf('Saved consensus outputs.\n');

            case 113  % 'q'
                break;
        end
    end

    if ishandle(hFig)
        close(hFig);
    end
end

%% =====================================================================
%                 BUILD DETECTOR INPUT CSV FROM CONSENSUS
% ======================================================================

Mdet = table();

Mdet.frame    = C.frame_idx;
Mdet.filename = C.filename;
Mdet.time_s   = C.time_s;

Mdet.mask_detected = double(~isnan(C.x_top_px) & ~isnan(C.y_top_px));

Mdet.x_top_px = C.x_top_px;
Mdet.y_top_px = C.y_top_px;

Mdet.bed_y_at_x_px       = nan(nRows,1);
Mdet.height_above_bed_px = nan(nRows,1);
Mdet.height_above_bed_mm = nan(nRows,1);
Mdet.burrow_depth_px     = nan(nRows,1);
Mdet.burrow_depth_mm     = nan(nRows,1);

for i = 1:nRows
    if Mdet.mask_detected(i) == 1 && bed.enabled
        yb = bed_y_at_x(bed, C.x_top_px(i));
        protrusion_px = yb - C.y_top_px(i);

        Mdet.bed_y_at_x_px(i)       = yb;
        Mdet.height_above_bed_px(i) = protrusion_px;
        Mdet.height_above_bed_mm(i) = protrusion_px * params.mm_per_px;

        if ~isempty(params.mussel_length_px)
            Mdet.burrow_depth_px(i) = params.mussel_length_px - protrusion_px;
            Mdet.burrow_depth_mm(i) = Mdet.burrow_depth_px(i) * params.mm_per_px;
        elseif ~isempty(params.mussel_length_mm)
            Mdet.burrow_depth_mm(i) = params.mussel_length_mm - Mdet.height_above_bed_mm(i);
            Mdet.burrow_depth_px(i) = Mdet.burrow_depth_mm(i) / params.mm_per_px;
        end
    end
end

% Detector-required signal
Mdet.burrow_mm        = Mdet.burrow_depth_mm;
Mdet.burrow_smooth_mm = Mdet.burrow_depth_mm;

Mdet.dBurrow_dt_mmps = nan(nRows,1);
if nRows >= 1
    Mdet.dBurrow_dt_mmps(1) = 0;
end

for i = 2:nRows
    if isfinite(Mdet.burrow_smooth_mm(i)) && isfinite(Mdet.burrow_smooth_mm(i-1))
        dt_i = Mdet.time_s(i) - Mdet.time_s(i-1);
        if isfinite(dt_i) && dt_i > 0
            Mdet.dBurrow_dt_mmps(i) = (Mdet.burrow_smooth_mm(i) - Mdet.burrow_smooth_mm(i-1)) / dt_i;
        end
    end
end

bad = ~isfinite(Mdet.dBurrow_dt_mmps);
Mdet.dBurrow_dt_mmps(bad) = 0;

Mdet.source = C.source;
Mdet.note   = C.note;

writetable(C, params.output_consensus_csv);
writetable(Mdet, params.output_detector_ready_csv);
save(params.output_consensus_mat, 'C', 'Mdet', 'T', 'summaryStats', 'params', 'bed');

fprintf('\nSaved outputs:\n');
fprintf('  Comparison:     %s\n', params.output_comparison);
fprintf('  Consensus CSV:  %s\n', params.output_consensus_csv);
fprintf('  Detector input: %s\n', params.output_detector_ready_csv);
fprintf('  MAT file:       %s\n', params.output_consensus_mat);

%% =====================================================================
%            SCROLL-WHEEL ZOOM CALLBACK  (nested / closure-style)
% ======================================================================
% Updates zoomState in the caller's workspace via the figure's UserData.
% Strategy: store xlim/ylim in hFig.UserData and let the redraw loop pick
% them up through zoomState, which is shared by reference (handle class not
% needed – we update the struct fields and the loop reads them each pass).

    function scrollZoom(~, ev)
        % Operates on the LEFT (ax1) subplot only.
        % ev.VerticalScrollCount > 0 → scroll down → zoom out
        %                          < 0 → scroll up  → zoom in
        if ~ishandle(hFig), return; end

        % Find the left axes (ax1 is first axes in figure)
        axList = findobj(hFig, 'Type', 'axes');
        if isempty(axList), return; end

        % subplot(1,2,1) is the last-created axes stored first in findobj;
        % we want the one whose position is on the left half.
        leftAx = [];
        for ai = 1:numel(axList)
            pos = get(axList(ai), 'Position');
            if pos(1) < 0.5   % left half
                leftAx = axList(ai);
                break;
            end
        end
        if isempty(leftAx), return; end

        % Get current limits
        xl = get(leftAx, 'XLim');
        yl = get(leftAx, 'YLim');

        % Zoom factor per scroll tick
        factor = 1.15;
        if ev.VerticalScrollCount < 0
            scale = 1 / factor;   % zoom in
        else
            scale = factor;        % zoom out
        end

        % Zoom around the centre of the current view
        xc = mean(xl);
        yc = mean(yl);
        xHalf = (xl(2)-xl(1))/2 * scale;
        yHalf = (yl(2)-yl(1))/2 * scale;

        newXlim = [xc - xHalf, xc + xHalf];
        newYlim = [yc - yHalf, yc + yHalf];

        % Clamp to image bounds
        newXlim(1) = max(newXlim(1), 0.5);
        newXlim(2) = min(newXlim(2), imgW + 0.5);
        newYlim(1) = max(newYlim(1), 0.5);
        newYlim(2) = min(newYlim(2), imgH + 0.5);

        set(leftAx, 'XLim', newXlim, 'YLim', newYlim);

        % Persist so the next redraw keeps the zoom
        zoomState.active = true;
        zoomState.xlim   = newXlim;
        zoomState.ylim   = newYlim;
    end

%% =====================================================================
%                           LOCAL HELPERS
% ======================================================================

function s = string_or_empty(v)
    if ismissing(v) || (isstring(v) && strlength(v) == 0)
        s = '';
    elseif iscell(v)
        s = char(v{1});
    else
        s = char(string(v));
    end
end

function yb = bed_y_at_x(bed, x)
    if ~bed.enabled
        yb = nan;
        return;
    end
    if abs(bed.x2 - bed.x1) < eps
        yb = mean([bed.y1 bed.y2]);
    else
        m = (bed.y2 - bed.y1) / (bed.x2 - bed.x1);
        yb = bed.y1 + m * (x - bed.x1);
    end
end

function bed = parse_bedline_struct(S)
    bed = struct('enabled', true, 'x1', [], 'y1', [], 'x2', [], 'y2', []);

    if all(isfield(S, {'x1','y1','x2','y2'}))
        bed.x1 = S.x1; bed.y1 = S.y1; bed.x2 = S.x2; bed.y2 = S.y2;
        return;
    end

    nestedNames = {'bed','bedline','bed_line','bedLine'};
    for i = 1:numel(nestedNames)
        name = nestedNames{i};
        if isfield(S, name)
            b = S.(name);
            if isstruct(b) && all(isfield(b, {'x1','y1','x2','y2'}))
                bed.x1 = b.x1; bed.y1 = b.y1; bed.x2 = b.x2; bed.y2 = b.y2;
                return;
            end
            if isnumeric(b) && ismatrix(b) && size(b,2) == 2 && size(b,1) >= 2
                bed.x1 = b(1,1); bed.y1 = b(1,2); bed.x2 = b(end,1); bed.y2 = b(end,2);
                return;
            end
        end
    end

    if isfield(S, 'bedModel')
        bm = S.bedModel;
        if isstruct(bm) && all(isfield(bm, {'p1','p2'}))
            p1 = bm.p1(:)';
            p2 = bm.p2(:)';
            bed.x1 = p1(1); bed.y1 = p1(2);
            bed.x2 = p2(1); bed.y2 = p2(2);
            return;
        end
    end

    if isfield(S, 'linePts')
        P = S.linePts;
        if isnumeric(P) && ismatrix(P) && size(P,2) == 2 && size(P,1) >= 2
            bed.x1 = P(1,1); bed.y1 = P(1,2); bed.x2 = P(end,1); bed.y2 = P(end,2);
            return;
        end
    end

    error('Could not parse bed line from file.');
end

function [cropIm, xlimZoom, ylimZoom] = get_zoom_patch(I, x, y, hw, hh)
    [H, W, ~] = size(I);
    x1 = max(1, floor(x - hw));
    x2 = min(W, ceil(x + hw));
    y1 = max(1, floor(y - hh));
    y2 = min(H, ceil(y + hh));
    cropIm = I(y1:y2, x1:x2, :);
    xlimZoom = [x1 x2];
    ylimZoom = [y1 y2];
end

function [sorted, idx] = sort_nat(c)
    expr = '\d+';
    keys = regexprep(c, expr, '${sprintf(''%08d'', str2double($0))}');
    [~, idx] = sort(lower(keys));
    sorted = c(idx);
end