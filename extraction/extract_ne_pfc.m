function summary = extract_ne_pfc(data_root, out_dir, only)
%EXTRACT_NE_PFC  Full-rate PFC NE dF/F for every recording with usable raw signal.
%
%   summary = extract_ne_pfc()                      % all recordings, default paths
%   summary = extract_ne_pfc(data_root, out_dir)
%   summary = extract_ne_pfc([], [], {'FiberPhot4_260324_morning'})   % subset
%
%   Writes one <recording>.mat per recording to out_dir, a QC figure per
%   recording to out_dir/qc/, and a summary table to out_dir/summary.csv.
%
%   Normalization follows the legacy pipeline
%   (matlab_scripts/Pre_process_batch_and_analyse_Glucose_PFC_morning.m):
%     1. Drop the first 1 s (the legacy "TTL" trim; these tanks have no TTL store).
%     2. Linear fit of 405 onto 465 over the whole remaining recording.
%     3. Smooth the fitted control with the legacy 1000-sample moving average
%        (filtfilt, so zero-phase).
%     4. dF/F % = 100 * (465 - fit) / fit
%   Unlike the legacy pipeline, the dF/F itself is NOT smoothed or downsampled,
%   so the spectrum up to fs/2 is preserved for spectral analysis.
%
%   Output .mat (v7; readable with scipy.io.loadmat) holds:
%     dff          single row, dF/F in %, at fs
%     signal_465   single row, raw 465 after the start trim (same samples as dff)
%     signal_405   single row, raw 405 after the start trim
%     fs           sampling rate (Hz), read from the recording's TSQ
%     t0_s         time of dff(1) from recording start (~1 s); time_s = t0_s + (0:N-1)/fs
%     fit_coef     [slope intercept]: unsmoothed control = slope*405 + intercept
%     plus provenance fields (recording, source, channel, n_samples_*, git_commit, ...)

TRIM_S = 1;                    % legacy start trim, seconds
MEAN_FILTER_ORDER = 1000;      % legacy moving-average length for the fitted control, samples

here = fileparts(mfilename('fullpath'));
repo_root = fileparts(here);
addpath(fullfile(here, 'tdt'));

if nargin < 1 || isempty(data_root), data_root = repo_root; end
if nargin < 2 || isempty(out_dir),   out_dir = fullfile(repo_root, 'outputs', 'ne_pfc_fullrate'); end
if nargin < 3, only = {}; end

recs = pfc_recordings(only);

if ~exist(fullfile(out_dir, 'qc'), 'dir'), mkdir(fullfile(out_dir, 'qc')); end
git_commit = get_git_commit(repo_root);
mean_filter = ones(MEAN_FILTER_ORDER, 1) / MEAN_FILTER_ORDER;

n_rec = size(recs, 1);
summary = table('Size', [n_rec 9], ...
    'VariableTypes', {'string','string','double','double','double','double','double','double','string'}, ...
    'VariableNames', {'recording','source','fs','n_samples','duration_h','fit_slope','fit_intercept','n_missing_vs_tsq','status'});

for k = 1:n_rec
    name = recs{k,1}; src = recs{k,2};
    summary.recording(k) = name; summary.source(k) = src;
    fprintf('\n[%s] %s (%s)\n', datestr(now, 'HH:MM:SS'), name, src);
    try
        R = load_pfc_raw(data_root, recs(k,:), TRIM_S);
        s465 = R.s465; s405 = R.s405; fs = R.fs;

        % 2-4. fit, smooth the fitted control, dF/F
        y = double(s465);
        x = double(s405);
        fit_coef = polyfit(x, y, 1);
        control_fit = filtfilt(mean_filter, 1, fit_coef(1) * x + fit_coef(2));
        clear x
        if any(control_fit <= 0)
            warning('%s: fitted control is non-positive somewhere; dF/F is unreliable there.', name);
        end
        dff = single(100 * (y - control_fit) ./ control_fit);
        clear y

        % save
        S = struct();
        S.dff = dff;
        S.signal_465 = single(s465);
        S.signal_405 = single(s405);
        S.fs = fs;
        S.t0_s = R.t0_s;
        S.fit_coef = fit_coef;
        S.fit_window = 'whole recording after the start trim';
        S.smoothing = sprintf(['fitted control only: filtfilt with a %d-sample moving average. ' ...
            'dff itself is unsmoothed and not downsampled.'], MEAN_FILTER_ORDER);
        S.units = 'dff: % dF/F; signal_465/405: raw TDT units';
        S.channel = R.channel;
        S.recording = name;
        S.source = src;
        S.source_files = R.source_files;
        S.n_samples_source = R.n_source;
        S.n_samples_tsq = R.n_tsq;
        S.created = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        S.script = 'extraction/extract_ne_pfc.m';
        S.git_commit = git_commit;
        save(fullfile(out_dir, [name '.mat']), '-struct', 'S', '-v7');

        save_qc_figure(fullfile(out_dir, 'qc', [name '_qc.png']), name, s465, control_fit, dff, s405, fs, S.t0_s);

        summary.fs(k) = fs;
        summary.n_samples(k) = numel(dff);
        summary.duration_h(k) = numel(dff) / fs / 3600;
        summary.fit_slope(k) = fit_coef(1);
        summary.fit_intercept(k) = fit_coef(2);
        summary.n_missing_vs_tsq(k) = R.n_missing;
        summary.status(k) = "ok";
        fprintf('  ok: %.2f h at %.3f Hz, fit = %.4f*405 + %.4f\n', summary.duration_h(k), fs, fit_coef);
        clear R s465 s405 control_fit dff S
    catch err
        summary.status(k) = "FAILED: " + string(err.message);
        fprintf(2, '  FAILED: %s\n', err.message);
    end
end

writetable(summary, fullfile(out_dir, 'summary.csv'));
disp(summary);
end


function save_qc_figure(png_path, name, s465, control_fit, dff, s405, fs, t0_s)
% Overview at ~1 Hz (plotting only) plus Welch PSDs at full rate.
step = max(1, round(fs));
idx = 1:step:numel(dff);
t_min = (t0_s + (idx - 1) / fs) / 60;

fig = figure('Visible', 'off', 'Position', [0 0 1200 1000]);
tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');

nexttile;
plot(t_min, s465(idx), 'Color', [0 0.45 0.74]); hold on;
plot(t_min, control_fit(idx), 'Color', [0.85 0.33 0.10], 'LineWidth', 1);
xlim(t_min([1 end])); ylabel('raw (TDT units)'); legend({'465', 'fitted 405 (smoothed)'}, 'Location', 'best');
title(strrep(name, '_', '\_'));

nexttile;
plot(t_min, dff(idx), 'Color', [0.2 0.2 0.2]);
xlim(t_min([1 end])); ylabel('\DeltaF/F (%)'); xlabel('time (min)');

nexttile;
win = round(60 * fs);                         % 60-s Welch windows: resolution ~0.017 Hz
[p_dff, f] = pwelch(double(dff), hann(win), round(win / 2), [], fs);
p_405 = pwelch(double(s405 - mean(s405)) ./ mean(control_fit) * 100, hann(win), round(win / 2), [], fs);
loglog(f(2:end), p_dff(2:end), 'Color', [0.2 0.2 0.2]); hold on;
loglog(f(2:end), p_405(2:end), 'Color', [0.6 0.6 0.6]);
xlim([f(2) fs / 2]); grid on;
xlabel('frequency (Hz)'); ylabel('PSD (%^2/Hz)');
legend({'\DeltaF/F', '405 (scaled like \DeltaF/F)'}, 'Location', 'southwest');

exportgraphics(fig, png_path, 'Resolution', 110);
close(fig);
end
