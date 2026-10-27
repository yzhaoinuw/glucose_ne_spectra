function recs = pfc_recordings(only)
%PFC_RECORDINGS  Recordings with usable raw PFC signal (see README "Which recordings have usable signal").
%
%   recs = pfc_recordings()          % all, as an n x 3 cell: {folder, source, mat prefix}
%   recs = pfc_recordings({'FiberPhot4_260324_morning'})   % subset
%
%   source 'tank': full TDT tank, read 465A/405A with TDTbin2mat
%   source 'mat' : no .tev; raw single-fiber arrays pre-extracted to
%                  <prefix>_signal_{465,405}.mat (presumed PFC = 465A/405A, the
%                  channels the legacy batch script used)

recs = {
    'FiberPhot22_240324_morning',      'tank', ''
    'FiberPhot22_240324_evening',      'tank', ''
    'FiberPhot4_260324_morning',       'tank', ''
    'FiberPhot4_260324_evening',       'tank', ''
    'FP1_glucose_13hours_090424',      'mat',  '13H_GLU_FP1'
    'FP2_glucose_13hours_100424',      'mat',  '13H_GLU_FP2'
    'Subject1-240323-091543_morning',  'mat',  '5H_GLU_FP1'
    'Subject3-240322-092543_morning',  'mat',  '5H_GLU_FP3'
    'Subject2-240321-093251_210324',   'tank', ''    % .tev recovered 2026-10-27
    'Subject33-240324-093611_morning', 'tank', ''    % .tev recovered 2026-10-27
    'Subject5-240326-090337_morning',  'tank', ''    % tank recovered 2026-10-27
    };
if nargin >= 1 && ~isempty(only)
    recs = recs(ismember(recs(:,1), only), :);
    assert(~isempty(recs), 'None of the requested recordings are in the list.');
end
end
