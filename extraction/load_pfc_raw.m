function R = load_pfc_raw(data_root, rec, trim_s, fiber)
%LOAD_PFC_RAW  Raw 465/405 for one recording and fiber, start-trimmed, plus provenance.
%
%   R = load_pfc_raw(data_root, rec, trim_s, fiber)
%     rec     one row of pfc_recordings(): {folder, source, mat prefix}
%     trim_s  start trim in seconds (legacy: 1)
%     fiber   'A' = PFC (465A/405A, default) or 'C' = OC (465C/405C);
%             'C' needs a full tank
%
%   R.s465, R.s405   single row vectors, same length, after the start trim
%   R.fs             sampling rate from the recording's TSQ index
%   R.t0_s           time of the first returned sample from recording start
%   R.start_time     recording start from the TSQ index, POSIX seconds as the rig clock wrote it
%   R.n_source, R.n_tsq, R.n_missing, R.source_files, R.channel
%
%   The pre-extracted .mat arrays are exactly round(fs) samples shorter than
%   their TSQ index: the legacy 1-s trim was already applied when they were
%   saved. Any shortfall is treated as already trimmed from the start, and
%   only what remains of trim_s is removed, so every recording starts at the
%   same point.

if nargin < 4 || isempty(fiber), fiber = 'A'; end
assert(ismember(fiber, {'A', 'C'}), 'fiber must be ''A'' (PFC) or ''C'' (OC)');
name = rec{1}; src = rec{2}; prefix = rec{3};
rec_dir = fullfile(data_root, name);
k465 = ['x465' fiber]; k405 = ['x405' fiber];

% Sampling rate and expected length come from the TSQ index, which every
% usable recording has (the .tev is not needed for headers).
heads = TDTbin2mat([rec_dir filesep], 'HEADERS', 1);
fs = heads.stores.(k465).fs;
assert(abs(heads.stores.(k405).fs - fs) < 1e-6, '465 and 405 sampling rates differ');
% The two stores can differ by a block at the end (one 48-h tank: 465C has
% 128 more samples than 405C). Both start together, so compare against the
% shorter index; a longer one would be read as a start-trim shortfall.
n_tsq = min(tsq_sample_count(heads.stores.(k465)), tsq_sample_count(heads.stores.(k405)));

switch src
    case 'tank'
        d = TDTbin2mat([rec_dir filesep], 'TYPE', {'streams'}, 'STORE', {k465(2:end), k405(2:end)});
        s465 = d.streams.(k465).data;
        s405 = d.streams.(k405).data;
        assert(abs(d.streams.(k465).fs - fs) < 1e-6, 'stream fs differs from TSQ fs');
        source_files = {rec_dir};
    case 'mat'
        assert(strcmp(fiber, 'A'), '%s: the pre-extracted .mat arrays hold fiber A only', name);
        f465 = fullfile(rec_dir, [prefix '_signal_465.mat']);
        f405 = fullfile(rec_dir, [prefix '_signal_405.mat']);
        s465 = getfield(load(f465, 'signal_465'), 'signal_465'); %#ok<GFLD>
        s405 = getfield(load(f405, 'signal_405'), 'signal_405'); %#ok<GFLD>
        source_files = {f465, f405};
    otherwise
        error('unknown source type %s', src);
end
s465 = s465(:)'; s405 = s405(:)';
n_source = [numel(s465) numel(s405)];
if n_source(1) ~= n_source(2)
    warning('%s: 465 has %d samples, 405 has %d; truncating to the shorter.', name, n_source(1), n_source(2));
end

n = min(n_source);
n_missing = n_tsq - n;
if n_missing < 0 || n_missing > 2 * round(trim_s * fs)
    warning('%s: source has %d samples but the TSQ indexes %d.', name, n, n_tsq);
end
n_missing = max(0, n_missing);
n_trim = max(0, round(trim_s * fs) - n_missing);

R = struct();
R.s465 = s465(n_trim+1:n);
R.s405 = s405(n_trim+1:n);
R.fs = fs;
R.t0_s = (n_missing + n_trim) / fs;
R.start_time = heads.startTime;
R.n_source = n_source;
R.n_tsq = n_tsq;
R.n_missing = n_missing;
R.source_files = source_files;
if strcmp(fiber, 'A')
    R.channel = 'PFC fiber: 465A (GRAB-NE hSyn-NE2m) / 405A (isosbestic)';
else
    R.channel = 'OC fiber: 465C (GRAB-NE hSyn-NE2m) / 405C (isosbestic)';
end
if strcmp(src, 'mat')
    R.channel = [R.channel ' -- from pre-extracted .mat arrays, verified identical to 465A/405A on 2026-10-28'];
end
end


function n = tsq_sample_count(store)
% Samples indexed for a float32 stream store: blocks x (block size in 32-bit words - 10 header words).
assert(store.dform == 0, 'expected float32 stream data (dform 0)');
ts = store.ts;
if iscell(ts), ts = [ts{:}]; end
n = double(numel(ts)) * (double(store.size) - 10);
end
