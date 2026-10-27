function summary = extract_ne_pfc_first5h(data_root, out_dir)
%EXTRACT_NE_PFC_FIRST5H  v2 dF/F on the first 5 h of each cohort session.
%
%   The analysis window for the spectral study: ~1 h baseline, the injection
%   at 59-67 min, ~4 h after, all in the light phase. Every session, 5-h or
%   13-h, is cropped to 5 h and fitted over that whole window, so all 9 mice
%   are processed the same way. Evening sessions are out of scope.
%
%   Writes to outputs/ne_pfc_ds20_first5h/ by default.

here = fileparts(mfilename('fullpath'));
repo_root = fileparts(here);
if nargin < 1 || isempty(data_root), data_root = repo_root; end
if nargin < 2 || isempty(out_dir),   out_dir = fullfile(repo_root, 'outputs', 'ne_pfc_ds20_first5h'); end

cohort = {
    'Subject3-240322-092543_morning'   % #3  glucose
    'FiberPhot4_260324_morning'        % #4  glucose
    'Subject5-240326-090337_morning'   % #5  glucose
    'FiberPhot22_240324_morning'       % #22 glucose
    'FP1_glucose_13hours_090424'       % FP1 glucose
    'FP2_glucose_13hours_100424'       % FP2 glucose
    'Subject1-240323-091543_morning'   % #1  saline
    'Subject2-240321-093251_210324'    % #2  saline
    'Subject33-240324-093611_morning'  % #33 saline
    };
summary = extract_ne_pfc_ds(data_root, out_dir, cohort, [], 5);
end
