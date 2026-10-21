function R = load_pfc_raw(data_root, rec, trim_s)
%LOAD_PFC_RAW  Raw PFC 465/405 for one recording, start-trimmed, plus provenance.
%
%   R = load_pfc_raw(data_root, rec, trim_s)
%     rec     one row of pfc_recordings(): {folder, source, mat prefix}
%     trim_s  start trim in seconds (legacy: 1)
%
%   R.s465, R.s405   single row vectors, same length, after the start trim
%   R.fs             sampling rate from the recording's TSQ index
%   R.t0_s           time of the first returned sample from recording start
%   R.n_source, R.n_tsq, R.n_missing, R.source_files, R.channel
%
%   The pre-extracted .mat arrays are exactly round(fs) samples shorter than
%   their TSQ index: the legacy 1-s trim was already applied when they were
%   saved. Any shortfall is treated as already trimmed from the start, and
%   only what remains of trim_s is removed, so every recording starts at the
%   same point.

name = rec{1}; src = rec{2}; prefix = rec{3};
rec_dir = fullfile(data_root, name);

% Sampling rate and expected length come from the TSQ index, which every
% usable recording has (the .tev is not needed for headers).
heads = TDTbin2mat([rec_dir filesep], 'HEADERS', 1);
fs = heads.stores.x465A.fs;
assert(abs(heads.stores.x405A.fs - fs) < 1e-6, '465A and 405A sampling rates differ');
n_tsq = tsq_sample_count(heads.stores.x465A);

switch src
    case 'tank'
        d = TDTbin2mat([rec_dir filesep], 'TYPE', {'streams'}, 'STORE', {'465A', '405A'});
        s465 = d.streams.x465A.data;
        s405 = d.streams.x405A.data;
        assert(abs(d.streams.x465A.fs - fs) < 1e-6, 'stream fs differs from TSQ fs');
        source_files = {rec_dir};
    case 'mat'
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
    warning('%s: 465 has %d samples, 405 has %d; truncating to the shorter.', name, n_source);
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
R.n_source = n_source;
R.n_tsq = n_tsq;
R.n_missing = n_missing;
R.source_files = source_files;
R.channel = 'PFC fiber: 465A (GRAB-NE hSyn-NE2m) / 405A (isosbestic)';
if strcmp(src, 'mat')
    R.channel = [R.channel ' -- presumed; source .mat files do not record the store'];
end
end


function n = tsq_sample_count(store)
% Samples indexed for a float32 stream store: blocks x (block size in 32-bit words - 10 header words).
assert(store.dform == 0, 'expected float32 stream data (dform 0)');
ts = store.ts;
if iscell(ts), ts = [ts{:}]; end
n = double(numel(ts)) * (double(store.size) - 10);
end
