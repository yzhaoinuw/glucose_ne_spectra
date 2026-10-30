function summary = extract_ne_pfc_ds(data_root, out_dir, only, v1_dir, max_h, fiber)
%EXTRACT_NE_PFC_DS  Downsampled (~20 Hz) PFC NE dF/F with a robust, segment-anchored 405 fit (v2).
%
%   summary = extract_ne_pfc_ds()                      % all recordings, default paths
%   summary = extract_ne_pfc_ds(data_root, out_dir, only, v1_dir, max_h, fiber)
%
%   fiber: 'A' = PFC (default) or 'C' = OC; see load_pfc_raw.
%
%   max_h (default Inf): keep only the first max_h hours from recording
%   start, then process that window as a short session (whole-window fit).
%   max_h = 5 gives every mouse the same baseline + ~4 h post-injection
%   window, fitted the same way (see extract_ne_pfc_first5h).
%
%   Differences from extract_ne_pfc (v1): ~20 Hz anti-aliased downsampling,
%   robust 405 fit, baseline + end fit window for long sessions. The
%   processing itself is in process_ne_session, shared with extract_ne_48h.
%
%   Writes <recording>.mat (v7), qc/<recording>_qc.png and summary.csv to
%   out_dir. If v1 output exists in v1_dir, the QC figure overlays it.

TRIM_S = 1;            % legacy start trim, seconds

here = fileparts(mfilename('fullpath'));
repo_root = fileparts(here);
addpath(fullfile(here, 'tdt'));

if nargin < 1 || isempty(data_root), data_root = repo_root; end
if nargin < 2 || isempty(out_dir),   out_dir = fullfile(repo_root, 'outputs', 'ne_pfc_ds20'); end
if nargin < 3, only = {}; end
if nargin < 4 || isempty(v1_dir),    v1_dir = fullfile(repo_root, 'outputs', 'ne_pfc_fullrate'); end
if nargin < 5 || isempty(max_h),     max_h = Inf; end
if nargin < 6 || isempty(fiber),     fiber = 'A'; end

recs = pfc_recordings(only);
opts = struct('max_h', max_h, 'v1_dir', v1_dir, 'fiber', fiber, ...
    'script', 'extraction/extract_ne_pfc_ds.m', 'git_commit', get_git_commit(repo_root));

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
        R = load_pfc_raw(data_root, recs(k,:), TRIM_S, fiber);
        R.source = recs{k,2};
        row = process_ne_session(R, name, out_dir, opts);
        clear R
        for f = fieldnames(row)'
            summary.(f{1})(k) = row.(f{1});
        end
        summary.status(k) = "ok";
    catch err
        summary.status(k) = "FAILED: " + string(err.message);
        fprintf(2, '  FAILED: %s\n', err.message);
    end
end

if ~exist(out_dir, 'dir'), mkdir(out_dir); end
writetable(summary, fullfile(out_dir, 'summary.csv'));
disp(summary);
end
