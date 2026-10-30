function summary = extract_ne_48h(data_root, out_dir, only)
%EXTRACT_NE_48H  v2 NE extraction (~20 Hz) for every mouse-session of the 48-h study.
%
%   summary = extract_ne_48h()                         % all 14 mouse-sessions
%   summary = extract_ne_48h(data_root, out_dir, {'COM10_glucose'})   % subset
%
%   data_root  folder holding 48H_GLU_FP/ and 48H_SAL_FP/ (default: the Yue/
%              folder that contains this repo)
%   out_dir    default outputs/ne_48h_ds20/
%
%   Same processing as the 5-h study (process_ne_session, v2): the whole
%   ~48 h, downsampled to ~20 Hz, robust 405 fit over the first 50 min plus
%   the last hour. One <mouse>_<condition>.mat per mouse-session, with the
%   journal metadata and the injection time in minutes from recording start
%   (inj_min). Both fibers are PFC, one mouse each (see recordings48).
%
%   Rig clock: the tanks' start times decode to ~03:00 EDT, but the journal
%   and every block name that carries a time say ~09:00 (e.g.
%   Subject1-240603-090537 vs 03:05:39 EDT). The rig PCs' clocks were 6 h off,
%   so the rig wall clock is EDT + RIG_CLOCK_OFFSET_H. Injection times in the
%   journal are on that wall clock. Block-name times are checked when present.

TRIM_S = 1;                 % legacy start trim, seconds
RIG_CLOCK_OFFSET_H = 6;     % rig wall clock = start time decoded in America/New_York + 6 h

here = fileparts(mfilename('fullpath'));
repo_root = fileparts(here);
addpath(fullfile(here, 'tdt'));
if nargin < 1 || isempty(data_root), data_root = fileparts(repo_root); end
if nargin < 2 || isempty(out_dir),   out_dir = fullfile(repo_root, 'outputs', 'ne_48h_ds20'); end
if nargin < 3, only = {}; end

T = recordings48();
if ~isempty(only)
    T = T(ismember(T.name, cellstr(string(only))), :);
    assert(height(T) > 0, 'None of the requested sessions are in recordings48.');
end
git_commit = get_git_commit(repo_root);
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

n = height(T);
vars = {'name','string'; 'mouse','string'; 'sex','string'; 'condition','string'; 'date','string'; ...
    'rig','string'; 'fiber','string'; 'rig_start','string'; 'block_clock','string'; 'inj','string'; ...
    'inj_min','double'; 'fs','double'; 'n_samples','double'; 'duration_h','double'; ...
    'fit_window','string'; 'fit_slope','double'; 'fit_intercept','double'; ...
    'v2_baseline','double'; 'v2_mid_2to4h','double'; 'v2_last_hour','double'; 'status','string'};
summary = table('Size', [n size(vars, 1)], 'VariableTypes', vars(:,2)', 'VariableNames', vars(:,1)');

for k = 1:n
    r = T(k, :);
    name = r.name{1};
    for f = {'name', 'mouse', 'sex', 'condition', 'date', 'rig', 'fiber', 'inj'}
        summary.(f{1})(k) = r.(f{1}){1};
    end
    fprintf('\n[%s] %s  (%s, fiber %s)\n', datestr(now, 'HH:MM:SS'), name, r.folder{1}, r.fiber{1});
    try
        % the folder name must agree with the table's mouse -> fiber mapping
        assert(contains(r.folder{1}, [r.mouse{1} '(' r.fiber{1} ')']), ...
            'folder name does not say %s is on fiber %s', r.mouse{1}, r.fiber{1});

        R = load_pfc_raw(data_root, {r.folder{1}, 'tank', ''}, TRIM_S, r.fiber{1});
        R.source = 'tank';
        R.channel = sprintf('PFC, mouse %s on fiber %s: 465%s (GRAB-NE hSyn-NE2m) / 405%s (isosbestic)', ...
            r.mouse{1}, r.fiber{1}, r.fiber{1}, r.fiber{1});

        % rig wall clock and injection time
        t_start = datetime(R.start_time, 'ConvertFrom', 'posixtime', 'TimeZone', 'America/New_York') ...
            + hours(RIG_CLOCK_OFFSET_H);
        t_start.TimeZone = '';
        assert(strcmp(datestr(t_start, 'yyyy-mm-dd'), r.date{1}), ...
            'rig start date %s differs from the journal date %s', datestr(t_start, 'yyyy-mm-dd'), r.date{1});
        t_inj = datetime([r.date{1} ' ' r.inj{1}], 'InputFormat', 'yyyy-MM-dd HH:mm');
        inj_min = minutes(t_inj - t_start);
        assert(inj_min > 60 && inj_min < 180, 'injection at %.1f min from start; expected ~2 h', inj_min);
        block_clock = check_block_clock(fullfile(data_root, r.folder{1}), t_start);

        meta = struct('mouse', r.mouse{1}, 'sex', r.sex{1}, 'condition', r.condition{1}, ...
            'date', r.date{1}, 'rig', r.rig{1}, 'weight_g', r.weight_g, 'dose_ml', r.dose_ml, ...
            'rig_start', datestr(t_start, 'yyyy-mm-dd HH:MM:SS'), 'inj_clock', r.inj{1}, ...
            'inj_min', inj_min, 'clock_note', sprintf(['rig wall clock = tank start time in ' ...
            'America/New_York + %d h (rig PC clock offset; matches block names and journal)'], ...
            RIG_CLOCK_OFFSET_H), 'study', '48-h glucose/saline crossover');
        opts = struct('fiber', r.fiber{1}, 'script', 'extraction/extract_ne_48h.m', ...
            'git_commit', git_commit, 'meta', meta, 'inj_min', inj_min);
        row = process_ne_session(R, name, out_dir, opts);
        clear R

        summary.rig_start(k) = datestr(t_start, 'yyyy-mm-dd HH:MM:SS');
        summary.block_clock(k) = block_clock;
        summary.inj_min(k) = inj_min;
        for f = setdiff(intersect(fieldnames(row), vars(:,1)), {'name'})'
            summary.(f{1})(k) = row.(f{1});
        end
        summary.status(k) = "ok";
        fprintf('  rig start %s, injection %s = %.1f min; block clock: %s\n', ...
            datestr(t_start, 'HH:MM:SS'), r.inj{1}, inj_min, block_clock);
    catch err
        summary.status(k) = "FAILED: " + string(err.message);
        fprintf(2, '  FAILED: %s\n', err.message);
    end
end

writetable(summary, fullfile(out_dir, 'summary.csv'));
disp(summary);
end


function s = check_block_clock(rec_dir, t_start)
% Compare the rig start time with the yymmdd-HHMMSS time at the end of the block name, if any.
f = dir(fullfile(rec_dir, '*.tsq'));
tok = regexp(f(1).name, '-(\d{6})-(\d{6})\.tsq$', 'tokens', 'once');
if isempty(tok)
    s = "no time in block name";
    return
end
t_block = datetime([tok{1} tok{2}], 'InputFormat', 'yyMMddHHmmss');
d = seconds(t_start - t_block);
assert(abs(d) < 60, 'rig start %s vs block name %s: %+.0f s apart', datestr(t_start), datestr(t_block), d);
s = sprintf("block name %s, %+.0f s", datestr(t_block, 'HH:MM:SS'), d);
end
