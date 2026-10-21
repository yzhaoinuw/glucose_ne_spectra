# Project Overview

This document orients a new agent (or human collaborator) to the codebase. It's the single most valuable artifact for getting useful work done quickly. Keep it current — when the active code path changes, update the relevant sections here.

## What This Repo Is

**glucose_ne_spectra** analyzes fiber-photometry recordings of norepinephrine (NE) in the mouse prefrontal cortex (PFC) before and after an intraperitoneal (IP) glucose injection, compared with saline. The goal is to find **changes in the frequency content of NE oscillations across the power spectrum** after a glucose dose, for example shifts in peak frequency or in band power relative to baseline.

The signal is recorded with the GRAB-NE sensor `hSyn-NE2m` on a TDT Synapse system: 465 nm excitation is the NE signal and 405 nm is the isosbestic control. Each recording is about 5 h (morning or evening), and two are about 13 h.

Current state: the lab's original **MATLAB pipeline is kept as reference** (`matlab_scripts/`). **Extraction** of full-rate PFC NE ΔF/F per recording is done in MATLAB (`extraction/`), because it uses the TDT reader. The **spectral analysis** will be in Python and isn't written yet.

## Active Runtime Path

### 0. Extraction (active)

Two versions share [`extraction/load_pfc_raw.m`](extraction/load_pfc_raw.m) (TSQ-based `fs`, start trim, provenance) and [`extraction/pfc_recordings.m`](extraction/pfc_recordings.m) (the 8 usable recordings):

- **v2, recommended:** [`extraction/extract_ne_pfc_ds.m`](extraction/extract_ne_pfc_ds.m) via [`run_extract_ne_pfc_ds.sbatch`](extraction/run_extract_ne_pfc_ds.sbatch). ×50 anti-aliased downsampling (~20.35 Hz). Robust (bisquare) linear 405→465 fit, using baseline + last hour for sessions ≥ 10 h and the whole recording otherwise. Output goes to `outputs/ne_pfc_ds20/`.
- **v1:** [`extraction/extract_ne_pfc.m`](extraction/extract_ne_pfc.m) via [`run_extract_ne_pfc.sbatch`](extraction/run_extract_ne_pfc.sbatch). Full rate, least-squares fit over the whole recording. Output goes to `outputs/ne_pfc_fullrate/`.
- Both read with the vendored [`extraction/tdt/TDTbin2mat.m`](extraction/tdt/TDTbin2mat.m), or load the pre-extracted `.mat` arrays where the `.tev` is gone. Both smooth the fitted control with a 1-s moving average and leave the ΔF/F unsmoothed. Output format is in `README.md`.

Below is the legacy MATLAB path that the extraction mirrors:

### 1. Entrypoint

[`matlab_scripts/Pre_process_batch_and_analyse_Glucose_PFC_morning.m`](matlab_scripts/Pre_process_batch_and_analyse_Glucose_PFC_morning.m)

- Batch-loads 6 morning PFC recordings with `TDTbin2mat` (TDT SDK; not in the repo).
- Fits 405 to 465 with a linear `polyfit`, smooths the fit with a 1000-sample moving average, and computes ΔF/F % = 100·(465 − fit)/fit. Then it smooths and downsamples ×100, to about 10 Hz.
- Uses hand-entered time points: baseline (about 0–60 min), injection at about 60 min plus a 20-min exclusion window, then post-injection hours 1, 2 and 3. It runs paired t-tests of baseline vs. each hour.

### 2. Main module

[`matlab_scripts/FP_preprocess.m`](matlab_scripts/FP_preprocess.m)

- A generic two-mouse preprocessing template, inherited from another lab. It contains several alternative detrending methods (exp2 + robust fit, split-half quadratic, exp1, intercept shift) and leftover optogenetics and tail-lift sections.

### 3. Dip analysis (legacy science, not the current goal)

- `process_variable.m`, `analyze_and_save_dip_data{,_eve}.m`, `compare_saved_dip_data.m`, `compare_glucose_saline.m`, `plot_dips*.m`, `plot_and_highlight_dips*.m`. These detect "NE dips" (runs below mean − k·SD) and compare dip count, duration and depth between saline and glucose. `IsInInterval.m` is an unused utility.

## Repo Structure Map

```text
GlucoseProjectFiberNE/          # repo root == shared lab data directory
|- AGENTS.md
|- CLAUDE.md                    # Claude Code pointer -> AGENTS.md
|- project_overview.md
|- README.md                    # includes the data inventory
|- .gitignore                   # keeps all recordings / data files out of git
|- treaty_docs/
|  |- treaty_conventions.md
|  |- next_steps.md
|  |- work_log.md
|  |- work_log_archive/
|- matlab_scripts/              # legacy reference pipeline (13 .m files)
|- extraction/                  # active: NE dF/F extraction, v1 full-rate + v2 ~20 Hz (MATLAB + SLURM)
|  |- tdt/                      # vendored TDT SDK reader (TDTbin2mat, SEV2mat)
|- outputs/                     # gitignored: extracted traces, QC figures, SLURM logs
|- FiberPhot*/  FP[0-9]*/  Subject*/   # raw TDT recordings - gitignored, read-only
```

The Python package and tests are not created yet.

## What Looks Active vs. Legacy

This section and the next are the two maps that keep an agent from editing the wrong file. Use whichever fits this repo — most benefit from both.

Many repos accumulate parallel implementations during refactors; without an explicit map, an agent will frequently edit the superseded copy.

### Active / relevant now

- [`extraction/extract_ne_pfc_ds.m`](extraction/extract_ne_pfc_ds.m): v2 NE extraction, the one to use. [`extraction/extract_ne_pfc.m`](extraction/extract_ne_pfc.m) (v1, full rate) is kept for comparison.
- [`extraction/load_pfc_raw.m`](extraction/load_pfc_raw.m), [`extraction/pfc_recordings.m`](extraction/pfc_recordings.m), [`extraction/get_git_commit.m`](extraction/get_git_commit.m): shared helpers.
- [`extraction/tdt/`](extraction/tdt/): the TDT reader, vendored unmodified from the TDT SDK via the user's `preprocess_sleep_data` repo. Don't edit it; replace it with a newer SDK copy if needed.

### Likely older or secondary

- Everything in [`matlab_scripts/`](matlab_scripts/) is reference only. Known bugs, so don't trust its numbers blindly:
  - The TTL/start trim is ignored in the batch loop: it uses uncut `signal_465_all{i}`, and `TTL_onset = 1` is stubbed.
  - Plots label ΔF/F % as "dF/F (z score)". The z-score is computed but never used.
  - The Bonferroni correction is applied twice (p × 5 *and* compared against 0.05/5), and significance stars are placed on the wrong pairs.
  - The dip statistics pool individual dips across mice, which is pseudo-replication. The rank-sum fallback condition is inverted.
  - The dip threshold is inconsistent: 1.5 SD in the analysis, 2 SD in `plot_dips`, 1.3 SD in `limited_view`.
  - `compare_glucose_saline.m` calls the missing `single_variable_dip_analysis`. `plot_dips_with_highlighting.m` declares the wrong function name. The 3-h plot is titled "2 Hours".
  - Paths are hardcoded to Windows `H:\`. Variables like `ds_delta465_eve_filt5` and `ds_delta465_sal_evening_filt2` refer to evening and saline scripts that aren't in this folder.

## Authored vs. Derived

The other axis: which files are written by hand, and which are regenerated from something else. Editing a derived file is worse than editing a legacy one — the change looks like it worked, then silently disappears the next time the generator runs.

Applies to any repo with codegen, migrations, lockfiles, compiled assets, extracted state, or build output.

### Authored — hand-edit these

- `AGENTS.md`, `project_overview.md`, `README.md`, `treaty_docs/next_steps.md`, `treaty_docs/work_log.md`, and (later) the Python source.

### Derived — never hand-edit; regenerate instead

- `treaty_docs/treaty_conventions.md` is maintained upstream by the treaty template. Refresh it with `treaty update`.
- `.copier-answers.yml` is written by `treaty init`/`treaty update`.
- The `.jpg`/`.fig`/`.mat` files *inside* the recording folders are old MATLAB outputs, not inputs. They're useful only as a visual sanity check against new results.
- `outputs/ne_pfc_ds20/` (v2) and `outputs/ne_pfc_fullrate/` (v1) are regenerated by `sbatch extraction/run_extract_ne_pfc_ds.sbatch` and `sbatch extraction/run_extract_ne_pfc.sbatch`. Their source of truth is the raw recordings plus the matching script.

## Tests And Fixtures

No tests yet. A cheap fixture for future smoke tests is `Subject1-240323-091543_morning/5H_GLU_FP1_signal_{465,405}.mat`, a pre-extracted raw signal of about 640 MB that loads without the TDT reader.

## User Data Expectations

- **Full TDT tanks** contain `.tev` (signal), `.tsq` (index), `.Tbk/.Tdx/.tin/.tnt` and `StoresListing.txt`. Read them with `TDTbin2mat` (MATLAB) or the Python `tdt` package (`tdt.read_block`). Stores: `465A`, `405A` (PFC) and `465C`, `405C` (OC).
- **Pre-extracted arrays:** `*_signal_465.mat` / `*_signal_405.mat` hold raw single-fiber `single` row vectors, presumably PFC, with **no sampling rate saved**. Read the rate from the recording's `.tsq` (`TDTbin2mat(path,'HEADERS',1)` works without the `.tev`). They are exactly `round(fs)` samples (1 s) shorter than the `.tsq` index, because the legacy 1-s start trim was already applied. The extraction accounts for this so it doesn't trim twice. The `FP*_12h_BL+end_fitting_*.mat` files are already-normalized outputs from an earlier run.
- Only 8 of 15 recordings have usable raw signal. The table is in `README.md`.
- **There is no TTL/epoc store** in these tanks. The legacy "first TTL" cut is just a fixed 1-s trim.
- **Effective bandwidth:** a steep roll-off at about 6 Hz in both channels of every recording (almost certainly the TDT demodulator's low-pass filter; setting not verified), and above about 1–2 Hz the ΔF/F PSD matches the 405 PSD. NE-specific spectral content is therefore below about 1 Hz. Downsampling to about 10–20 Hz with a proper anti-alias filter loses nothing for the spectral analysis.

## Practical Mental Model

If you only want to understand the current product, read files in this order:

1. [`README.md`](README.md): goal and data inventory
2. [`treaty_docs/next_steps.md`](treaty_docs/next_steps.md): what's in flight
3. [`matlab_scripts/Pre_process_batch_and_analyse_Glucose_PFC_morning.m`](matlab_scripts/Pre_process_batch_and_analyse_Glucose_PFC_morning.m): the reference preprocessing
4. A recording's `StoresListing.txt`: channel names and rates

## Questions Worth Clarifying Later

Not blockers, just places where intent would help future agents:

- Which recordings are glucose and which are saline? The folder names mostly don't say. The 13-h FP1/FP2 sessions and the `5H_GLU_*` files are glucose; the rest needs confirming from the lab.
- Is the OC (fiber 2) signal part of the analysis, or PFC only?
- Do the missing `.tev` files (Subject1 evening, Subject2, Subject3 evening, Subject33, Subject5) exist elsewhere, for example on the original `H:\Fiber photometry\Glucose\` drive?
- What spectral method and frequency bands are of interest (Welch PSD, multitaper, wavelet / time-frequency)? And what is the slowest oscillation that matters? That sets the window length.
