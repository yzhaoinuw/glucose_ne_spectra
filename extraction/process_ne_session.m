function row = process_ne_session(R, name, out_dir, opts)
%PROCESS_NE_SESSION  v2 processing of one raw 465/405 pair: downsample, robust 405 fit, dF/F, save, QC.
%
%   row = process_ne_session(R, name, out_dir, opts)
%     R        raw signals and provenance, as returned by load_pfc_raw
%     name     output name: writes <out_dir>/<name>.mat and <out_dir>/qc/<name>_qc.png
%     opts     struct, all fields optional:
%                max_h    keep only the first max_h hours from recording start (default Inf)
%                v1_dir   folder of v1 outputs to overlay in the QC figure (default: none)
%                fiber    'A' or 'C', stored in the output (default 'A')
%                script   caller, stored as provenance
%                git_commit
%                meta     struct of extra fields copied into the output .mat
%                inj_min  injection time, minutes from recording start; marked in the QC figure
%   row      struct of summary values for the caller's summary table
%
%   Method (v2):
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
%       by the end; the lab's earlier "BL+end_fitting" outputs did the same.
%       Shorter sessions keep the whole-recording fit, because their end
%       (~4 h post-injection) can't be assumed NE-neutral and their baseline
%       offsets were already small.
%     * dF/F % = 100 * (465 - control) / control, where control = fit applied
%       to 405 and smoothed with a 1-s moving average (filtfilt), as in the
%       legacy pipeline.
%
%   Tried and rejected (2026-10-20, see work log): per-channel double-
%   exponential bleaching fits + robust motion regression. The 465 bleach fit
%   absorbs the hours-long post-injection NE rise, and the motion slope was
%   up to 2.8, injecting 405 noise.

DS_FACTOR = 50;        % ~1017.25 Hz -> ~20.35 Hz
SMOOTH_S = 1;          % moving average on the fitted control (legacy: 1000 samples at 1017 Hz)
LONG_SESSION_H = 10;   % sessions at least this long get the baseline + end fit
BASELINE_MIN = 50;     % baseline window (injection is at >= ~60 min in every session)
END_MIN = 60;          % end window for long sessions

if nargin < 4, opts = struct(); end
opts = set_default(opts, 'max_h', Inf);
opts = set_default(opts, 'v1_dir', '');
opts = set_default(opts, 'fiber', 'A');
opts = set_default(opts, 'script', 'extraction/process_ne_session.m');
opts = set_default(opts, 'git_commit', 'unknown');
opts = set_default(opts, 'meta', struct());
opts = set_default(opts, 'inj_min', NaN);
max_h = opts.max_h;

if isfinite(max_h)
    % crop at max_h from recording start (t0_s is already elapsed)
    n_keep = min(numel(R.s465), floor((max_h * 3600 - R.t0_s) * R.fs));
    R.s465 = R.s465(1:n_keep); R.s405 = R.s405(1:n_keep);
end

% 1. anti-aliased downsampling
fs = R.fs / DS_FACTOR;
y = ds(R.s465, DS_FACTOR);
R.s465 = [];
x = ds(R.s405, DS_FACTOR);
R.s405 = [];
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
    if isfinite(max_h)
        fit_window = sprintf('whole window (first %g h)', max_h);
    else
        fit_window = 'whole recording';
    end
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
S.fiber = opts.fiber;
S.recording = name;
S.source = R.source;
S.source_files = R.source_files;
S.fs_original = R.fs;
S.max_h = max_h;
S.ds_factor = DS_FACTOR;
S.created = datestr(now, 'yyyy-mm-dd HH:MM:SS');
S.script = opts.script;
S.git_commit = opts.git_commit;
mf = fieldnames(opts.meta);
for i = 1:numel(mf)
    S.(mf{i}) = opts.meta.(mf{i});
end
if ~exist(fullfile(out_dir, 'qc'), 'dir'), mkdir(fullfile(out_dir, 'qc')); end
save(fullfile(out_dir, [name '.mat']), '-struct', 'S', '-v7');

% levels, and v1 for comparison if available
win = {t_min < BASELINE_MIN, t_min > 120 & t_min < 240, t_min > t_min(end) - 60};
lv = cellfun(@(m) mean(dff(m)), win);
v1 = [];
v1_file = fullfile(opts.v1_dir, [name '.mat']);
if ~isempty(opts.v1_dir) && exist(v1_file, 'file')
    v1 = load(v1_file, 'dff', 'fs', 't0_s');
    v1.dff = ds(v1.dff, DS_FACTOR);
    v1.dff = v1.dff(1:min(n, numel(v1.dff)));
    m1 = cellfun(@(m) m(1:numel(v1.dff)), win, 'UniformOutput', false);
    lv1 = cellfun(@(m) mean(v1.dff(m)), m1);
else
    lv1 = nan(1, 3);
end

save_qc_figure(fullfile(out_dir, 'qc', [name '_qc.png']), name, t_min, fs, y, control, in_fit, ...
    dff, x, v1, fit_window, b(2), opts.inj_min);

row = struct('fs', fs, 'n_samples', n, 'duration_h', dur_h, 'fit_window', string(fit_window), ...
    'fit_slope', b(2), 'fit_intercept', b(1), ...
    'v2_baseline', lv(1), 'v2_mid_2to4h', lv(2), 'v2_last_hour', lv(3), ...
    'v1_baseline', lv1(1), 'v1_mid_2to4h', lv1(2), 'v1_last_hour', lv1(3));
fprintf('  ok: %.2f h at %.3f Hz, fit (%s) = %.3f*405 + %.2f; baseline dF/F %.1f%% (v1 %.1f%%)\n', ...
    dur_h, fs, fit_window, b(2), b(1), lv(1), lv1(1));
end


function s = set_default(s, f, v)
if ~isfield(s, f) || isempty(s.(f)), s.(f) = v; end
end


function y = ds(x, q)
% Anti-aliased downsampling by an integer factor (polyphase FIR via resample).
% Mean removed first so the zero-padded edges don't ring.
x = double(x(:)');
m = mean(x);
y = resample(x - m, 1, q) + m;
end


function save_qc_figure(png_path, name, t_min, fs, y, control, in_fit, dff, x, v1, fit_window, slope, inj_min)
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
leg = {'fit window', '465', 'control (fitted 405)'};
if isfinite(inj_min)
    xline(inj_min, 'k--');
    leg{end+1} = 'injection';
end
xlim(tm([1 end])); ylim(yl); ylabel('raw (TDT units)');
legend(leg, 'Location', 'best');
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
if isfinite(inj_min), xline(inj_min, 'k--', 'HandleVisibility', 'off'); end
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
