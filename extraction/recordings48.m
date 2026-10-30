function T = recordings48()
%RECORDINGS48  Mouse-sessions of the 48-h study with raw data, from the lab journal.
%
%   T = recordings48()   % table, one row per mouse-session
%
%   Source: glucose_study_digitized.xlsx, sheet 2 ("GLUCOSE STUDY | 48 hours").
%   Each tank holds two mice, one per fiber; both fibers are PFC. COM# is the
%   mouse ID. The fiber of a mouse can change between sessions, so the mapping
%   is per session. The folder name also states it, e.g. COM10(A)_COM9(C);
%   extract_ne_48h checks the two agree.
%
%   folder   tank block folder, relative to the Yue/ folder next to this repo
%   inj      injection, rig wall-clock time (journal); see extract_ne_48h for the clock
%
%   Missing: 2024-05-08 glucose, rig RZ10-2, COM13 (A) / COM12 (C): only plots
%   were found, no raw files (asked the experimenter 2026-10-29).

G1 = '48H_GLU_FP/48H_Glucose_RZ10-1_COM10(A)_COM9(C)';
G2 = '48H_GLU_FP/48H_glucose_females_RZ10-1_240603_COM14(A)_COM15(C)';
G3 = '48H_GLU_FP/48H_glucose_females_RZ10-2_050624_COM18(A)_COM16(C)';
S1 = '48H_SAL_FP/48H_saline_RZ10_2_COM9(A)_COM10(C)';
S2 = '48H_SAL_FP/48H_saline_RZ10-1_290524_COM12(A)_COM13(C)';
S3 = '48H_SAL_FP/48H_sal_females_RZ10_2_COM14(A)_COM15(C)_170624';
S4 = '48H_SAL_FP/48H_RZ10_1_saline_females_COM18(A)_COM16(C)_170624';

%    mouse    sex       condition  date          rig       fiber folder inj      weight_g dose_ml
c = {
    'COM10', 'male',   'glucose', '2024-05-08', 'RZ10-1', 'A', G1, '11:10', 27.3, 0.54
    'COM9',  'male',   'glucose', '2024-05-08', 'RZ10-1', 'C', G1, '11:30', 31.5, 0.62
    'COM14', 'female', 'glucose', '2024-06-03', 'RZ10-1', 'A', G2, '11:06', 20.4, 0.41
    'COM15', 'female', 'glucose', '2024-06-03', 'RZ10-1', 'C', G2, '11:07', 21.6, 0.43
    'COM18', 'female', 'glucose', '2024-06-03', 'RZ10-2', 'A', G3, '11:03', 19.6, 0.39
    'COM16', 'female', 'glucose', '2024-06-03', 'RZ10-2', 'C', G3, '11:05', 21.7, 0.43
    'COM9',  'male',   'saline',  '2024-05-29', 'RZ10-2', 'A', S1, '11:01', 35.4, 0.71
    'COM10', 'male',   'saline',  '2024-05-29', 'RZ10-2', 'C', S1, '11:02', 29.4, 0.59
    'COM12', 'male',   'saline',  '2024-05-29', 'RZ10-1', 'A', S2, '11:03', 27.5, 0.55
    'COM13', 'male',   'saline',  '2024-05-29', 'RZ10-1', 'C', S2, '11:04', 32.3, 0.65
    'COM14', 'female', 'saline',  '2024-06-17', 'RZ10-2', 'A', S3, '11:01', 21.8, 0.44
    'COM15', 'female', 'saline',  '2024-06-17', 'RZ10-2', 'C', S3, '11:00', 23.7, 0.47
    'COM18', 'female', 'saline',  '2024-06-17', 'RZ10-1', 'A', S4, '11:03', 21.2, 0.42
    'COM16', 'female', 'saline',  '2024-06-17', 'RZ10-1', 'C', S4, '11:02', 23.8, 0.48
    };
T = cell2table(c, 'VariableNames', ...
    {'mouse', 'sex', 'condition', 'date', 'rig', 'fiber', 'folder', 'inj', 'weight_g', 'dose_ml'});
T.name = strcat(T.mouse, '_', T.condition);
end
