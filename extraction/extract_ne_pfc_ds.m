function summary = extract_ne_pfc_ds(data_root, out_dir, only, v1_dir)
%EXTRACT_NE_PFC_DS  Downsampled (~20 Hz) PFC NE dF/F with a robust, segment-anchored 405 fit (v2).
%
%   summary = extract_ne_pfc_ds()                      % all recordings, default paths
%   summary = extract_ne_pfc_ds(data_root, out_dir, only, v1_dir)
%
%   Differences from extract_ne_pfc (v1):
%     * Downsampled x50 (~1017 -> ~20.3 Hz) with an anti-aliasing filter
%       (resample). The new Nyquist (~10 Hz) is above the ~6 Hz roll-off
%       seen in every recording (likely the TDT demodulator's low-pass), so
%       no recorded content is lost.
%     * The linear 405 -> 465 fit is robust (bisquare IRLS), so NE dips and
%       transients don't pull it.
%     * Fit window for long sessions (>= LONG_SESSION_H): baseline (first
%       BASELINE_MIN) + last END_MIN only. In 13-h sessions, 405 and 465 bleach
%       at different rates and NE stays elevated for hours after the
%       injection, so a whole-recording fit leaves the baseline at -8..-13%.
%       Anchoring on baseline + end assumes NE has returned to baseline
%       ~12 h post-injection; the lab's earlier "BL+end_fitting" outputs did
%       the same. Shorter sessions keep the whole-recording fit, because their
%       end (~4 h post-injection) can't be assumed NE-neutral and their
%       baseline offsets were already small.
%   Unchanged from v1: dF/F % = 100 * (465 - control) / control, where
%   control = fit applied to 405 and smoothed with a 1-s moving average
%   (filtfilt), as in the legacy pipeline.
%
%   Tried and rejected (2026-10-20, see work log): per-channel double-
%   exponential bleaching fits + robust motion regression. The 465 bleach fit
%   absorbs the hours-long post-injection NE rise, and the motion slope was
%   up to 2.8, injecting 405 noise.
%
%   Writes <recording>.mat (v7), qc/<recording>_qc.png and summary.csv to
%   out_dir. If v1 output exists in v1_dir, the QC figure overlays it.

TRIM_S = 1;            % legacy start trim, seconds
DS_FACTOR = 50;        % ~1017.25 Hz -> ~20.35 Hz
SMOOTH_S = 1;          % moving average on the fitted control (legacy: 1000 samples at 1017 Hz)
LONG_SESSION_H = 10;   % sessions at least this long get the baseline + end fit
BASELINE_MIN = 50;     % baseline window (injection is at ~60 min)
END_MIN = 60;          % end window for long sessions

here = fileparts(mfilename('fullpath'));
repo_root = fileparts(here);
addpath(fullfile(here, 'tdt'));

if nargin < 1 || isempty(data_root), data_root = repo_root; end
if nargin < 2 || isempty(out_dir),   out_dir = fullfile(repo_root, 'outputs', 'ne_pfc_ds20'); end
if nargin < 3, only = {}; end
if nargin < 4 || isempty(v1_dir),    v1_dir = fullfile(repo_root, 'outputs', 'ne_pfc_fullrate'); end

recs = pfc_recordings(only);
if ~exist(fullfile(out_dir, 'qc'), 'dir'), mkdir(fullfile(out_dir, 'qc')); end
git_commit = get_git_commit(repo_root);

n_rec = size(recs, 1);
vars = {'recording','string'; 'fs','double'; 'n_samples','double'; 'duration_h','double'; ...
    'fit_window','string'; 'fit_slope','double'; 'fit_intercept','double'; ...
    'v2_baseline','double'; 'v2_mid_2to4h','double'; 'v2_last_hour','double'; ...
    'v1_baseline','double'; 'v1_mid_2to4h','double'; 'v1_last_hour','double'; 'status','string'};
summary = table('Size', [n_rec size(vars, 1)], 'VariableTypes', vars(:,2)', 'VariableNames', vars(:,1)');

for k = 1:n_rec
    name = recs{k,1};
    summary.recording(k) = name;
    fprintf('\n[%s] %s\n', datestr(now, 'HH:MM:SS'), name);
    try
        R = load_pfc_raw(data_root, recs(k,:), TRIM_S);

        % 1. anti-aliased downsampling
        fs = R.fs / DS_FACTOR;
        y = ds(R.s465, DS_FACTOR);
        x = ds(R.s405, DS_FACTOR);
        n = min(numel(x), numel(y));
        y = y(1:n); x = x(1:n);
        t_min = (R.t0_s + (0:n-1) / fs) / 60;   % time from recording start
        dur_h = n / fs / 3600;

        % 2. robust linear fit of 405 onto 465 over the fit window
        if dur_h >= LONG_SESSION_H
            in_fit = t_min < BASELINE_MIN | t_min > t_min(end) - END_MIN;
            fit_window = sprintf('baseline (t < %d min) + last %d min', BASELINE_MIN, END_MIN);
            fit_window_min = [t_min(1) BASELINE_MIN; t_min(end) - END_MIN t_min(end)];
        else
            in_fit = true(1, n);
            fit_window = 'whole recording';
            fit_window_min = t_min([1 end]);
        end
        b = robustfit(x(in_fit)', y(in_fit)', 'bisquare');      % [intercept; slope]

        % 3. smoothed control and dF/F
        w = max(1, round(SMOOTH_S * fs));
        control = filtfilt(ones(w, 1) / w, 1, b(2) * x + b(1));
        if any(control <= 0)
            warning('%s: fitted control is non-positive somewhere; dF/F is unreliable there.', name);
        end
        dff = 100 * (y - control) ./ control;

        % save
        S = struct();
        S.dff = single(dff);
        S.signal_465 = single(y);
        S.signal_405 = single(x);
        S.control = single(control);
        S.fs = fs;
        S.t0_s = R.t0_s;
        S.fit_coef = [b(2) b(1)];
        S.fit_window = fit_window;
        S.fit_window_min = fit_window_min;
        S.method = sprintf(['x%d anti-aliased resample; robust (bisquare) linear fit of 405 onto 465 over: %s; ' ...
            'control = fit smoothed with a %g-s moving average (filtfilt); dff = 100*(465 - control)/control'], ...
            DS_FACTOR, fit_window, SMOOTH_S);
        S.units = 'dff: % dF/F; signal_465/405, control: raw TDT units';
        S.channel = R.channel;
        S.recording = name;
        S.source = recs{k,2};
        S.source_files = R.source_files;
        S.fs_original = R.fs;
        S.ds_factor = DS_FACTOR;
        S.created = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        S.script = 'extraction/extract_ne_pfc_ds.m';
        S.git_commit = git_commit;
        save(fullfile(out_dir, [name '.mat']), '-struct', 'S', '-v7');

        % levels, and v1 for comparison if available
        win = {t_min < BASELINE_MIN, t_min > 120 & t_min < 240, t_min > t_min(end) - 60};
        lv = cellfun(@(m) mean(dff(m)), win);
        v1 = [];
        v1_file = fullfile(v1_dir, [name '.mat']);
        if exist(v1_file, 'file')
            v1 = load(v1_file, 'dff', 'fs', 't0_s');
            v1.dff = ds(v1.dff, DS_FACTOR);
            v1.dff = v1.dff(1:min(n, numel(v1.dff)));
            m1 = cellfun(@(m) m(1:numel(v1.dff)), win, 'UniformOutput', false);
            lv1 = cellfun(@(m) mean(v1.dff(m)), m1);
        else
            lv1 = nan(1, 3);
        end

        save_qc_figure(fullfile(out_dir, 'qc', [name '_qc.png']), name, t_min, fs, y, control, in_fit, ...
            dff, x, v1, fit_window, b(2));

        summary.fs(k) = fs;
        summary.n_samples(k) = n;
        summary.duration_h(k) = dur_h;
        summary.fit_window(k) = fit_window;
        summary.fit_slope(k) = b(2);
        summary.fit_intercept(k) = b(1);
        summary.v2_baseline(k) = lv(1); summary.v2_mid_2to4h(k) = lv(2); summary.v2_last_hour(k) = lv(3);
        summary.v1_baseline(k) = lv1(1); summary.v1_mid_2to4h(k) = lv1(2); summary.v1_last_hour(k) = lv1(3);
        summary.status(k) = "ok";
        fprintf('  ok: %.2f h at %.3f Hz, fit (%s) = %.3f*405 + %.2f; baseline dF/F %.1f%% (v1 %.1f%%)\n', ...
            dur_h, fs, fit_window, b(2), b(1), lv(1), lv1(1));
        clear R S v1
    catch err
        summary.status(k) = "FAILED: " + string(err.message);
        fprintf(2, '  FAILED: %s\n', err.message);
    end
end

writetable(summary, fullfile(out_dir, 'summary.csv'));
disp(summary);
end


function y = ds(x, q)
% Anti-aliased downsampling by an integer factor (polyphase FIR via resample).
% Mean removed first so the zero-padded edges don't ring.
x = double(x(:)');
m = mean(x);
y = resample(x - m, 1, q) + m;
end


function save_qc_figure(png_path, name, t_min, fs, y, control, in_fit, dff, x, v1, fit_window, slope)
% Traces shown as 1-s bin means (plotting only); PSDs from the full downsampled data.
bin = max(1, round(fs));
nb = floor(numel(t_min) / bin) * bin;
bm = @(v) mean(reshape(v(1:nb), bin, []), 1);
tm = bm(t_min);

fig = figure('Visible', 'off', 'Position', [0 0 1200 1000]);
tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');

nexttile;
yl = [min(bm(y)) max(bm(y))]; yl = yl + [-0.05 0.05] * diff(yl);
shade_fit_window(tm, bm(double(in_fit)) > 0.5, yl);
plot(tm, bm(y), 'Color', [0 0.45 0.74]); hold on;
plot(tm, bm(control), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2);
xlim(tm([1 end])); ylim(yl); ylabel('raw (TDT units)');
legend({'fit window', '465', 'control (fitted 405)'}, 'Location', 'best');
title(sprintf('%s   (v2: robust fit over %s, slope %.2f)', strrep(name, '_', '\_'), fit_window, slope));

nexttile;
leg = {};
if ~isempty(v1)
    plot(tm(1:floor(numel(v1.dff)/bin)), mean(reshape(v1.dff(1:floor(numel(v1.dff)/bin)*bin), bin, []), 1), ...
        'Color', [0.85 0.33 0.10 0.6]); hold on;
    leg{end+1} = 'v1 (whole-recording fit)';
end
plot(tm, bm(dff), 'Color', [0.15 0.15 0.15]); hold on;
leg{end+1} = 'v2';
yline(0, ':', 'HandleVisibility', 'off');
xlim(tm([1 end])); ylabel('\DeltaF/F (%)'); xlabel('time (min)');
legend(leg, 'Location', 'best');

nexttile;
win = round(60 * fs);                       % 60-s Welch windows: ~0.017 Hz resolution
[p2, f] = pwelch(dff - mean(dff), hann(win), round(win / 2), [], fs);
xn = 100 * (x - mean(x)) / mean(x);
p4 = pwelch(xn, hann(win), round(win / 2), [], fs);
loglog(f(2:end), p2(2:end), 'Color', [0.15 0.15 0.15]); hold on;
leg = {'v2 \DeltaF/F'};
if ~isempty(v1)
    p1 = pwelch(v1.dff - mean(v1.dff), hann(win), round(win / 2), [], fs);
    loglog(f(2:end), p1(2:end), 'Color', [0.85 0.33 0.10]);
    leg{end+1} = 'v1 \DeltaF/F (downsampled)';
end
loglog(f(2:end), p4(2:end), 'Color', [0.6 0.6 0.6]);
leg{end+1} = '405 (% of its mean)';
xlim([f(2) fs / 2]); grid on;
xlabel('frequency (Hz)'); ylabel('PSD (%^2/Hz)');
legend(leg, 'Location', 'southwest');

exportgraphics(fig, png_path, 'Resolution', 100);
close(fig);
end


function shade_fit_window(tm, mask, yl)
% Light grey background over the samples used for the fit.
d = diff([0 mask 0]);
starts = find(d == 1); stops = find(d == -1) - 1;
for i = 1:numel(starts)
    patch(tm([starts(i) stops(i) stops(i) starts(i)]), yl([1 1 2 2]), [0.9 0.9 0.9], ...
        'EdgeColor', 'none', 'HandleVisibility', ternary(i == 1, 'on', 'off'));
    hold on;
end
if isempty(starts)
    patch(nan(1, 4), nan(1, 4), [0.9 0.9 0.9], 'EdgeColor', 'none'); hold on;
end
end


function out = ternary(c, a, b)
if c, out = a; else, out = b; end
end
