# glucose_ne_spectra

[![Agent Collab Treaty](https://raw.githubusercontent.com/yzhaoinuw/agent_collab_treaty/main/assets/treaty-adopted.svg)](https://github.com/yzhaoinuw/agent_collab_treaty)

This repo analyzes fiber-photometry recordings of norepinephrine (NE) in the mouse prefrontal cortex after an intraperitoneal (IP) injection of glucose vs. saline. It looks for **shifts in the frequency of NE oscillations across the power spectrum** after the dose, relative to the pre-injection baseline.

- **Sensor:** GRAB-NE `hSyn-NE2m`. 465 nm excitation is the NE signal; 405 nm is the isosbestic (motion/bleaching) control.
- **Acquisition:** TDT Synapse, about 1017.3 Hz, with two fibers: **PFC** (`465A`/`405A`) and **OC** (`465C`/`405C`).
- **Protocol:** about 60 min baseline, IP injection, then about 4 h of recording. Two recordings are extended 13-h glucose sessions.

## Repo layout

| Path | What it is |
|---|---|
| `matlab_scripts/` | The lab's original MATLAB pipeline: ΔF/F preprocessing, hourly-bin stats and NE-"dip" detection. **Reference only.** The new analysis is written in Python. See `project_overview.md` for what each script does and its known bugs. |
| `AGENTS.md`, `project_overview.md`, `treaty_docs/` | Project documentation and work log ([Agent Collab Treaty](https://github.com/yzhaoinuw/agent_collab_treaty)). Start at `AGENTS.md`. |
| `extraction/` | MATLAB extraction of PFC NE ΔF/F from the raw recordings: v1 full-rate (`extract_ne_pfc.m`) and v2 ~20 Hz (`extract_ne_pfc_ds.m`), shared loader, SLURM wrappers, and the vendored TDT reader (`tdt/`) |
| *(coming)* Python package | Spectral analysis |

## Extracted NE traces

There are two versions. **Use v2 for analysis**; v1 is kept for comparison and for anything that needs the full rate.

| | v1 `outputs/ne_pfc_fullrate/` | v2 `outputs/ne_pfc_ds20/` (recommended) |
|---|---|---|
| Rate | ~1017 Hz (original) | ~20.35 Hz (×50, anti-aliased) |
| 405→465 fit | least squares, whole recording | robust (bisquare); 13-h sessions fit on baseline + last hour, 5-h sessions on the whole recording |
| Baseline offset in 13-h sessions | −8% (FP1), −13% (FP2) | ~0% |
| Size | 1.8 GB | 52 MB |
| Run | `sbatch extraction/run_extract_ne_pfc.sbatch` (~8 min) | `sbatch extraction/run_extract_ne_pfc_ds.sbatch` (~4 min) |

Run both from the repo root after `mkdir -p outputs/logs`. Each writes one `.mat` per usable recording (gitignored), a QC figure per recording to `qc/`, and a `summary.csv`. The files are MATLAB v7, so `scipy.io.loadmat` reads them. Both versions share these variables:

| Variable | Meaning |
|---|---|
| `dff` | PFC NE ΔF/F in %, unsmoothed |
| `signal_465`, `signal_405` | Raw signal and isosbestic control, same samples as `dff` |
| `fs` | Sampling rate (v1 ~1017.25 Hz, v2 ~20.35 Hz) |
| `t0_s` | Time of the first sample from recording start (~1 s); `t = t0_s + (0:N-1)/fs` |
| `fit_coef` | `[slope intercept]` of the 405→465 linear fit |
| v2 only: `control`, `fit_window`, `fit_window_min` | Fitted, smoothed 405 control; which samples the fit used (minutes) |
| provenance | `recording`, `source`, `source_files`, `channel`, `n_samples_*`, `git_commit`, … |

ΔF/F = 100·(465 − control)/control, where the control is the 405 mapped through the linear fit and smoothed with a 1-s moving average (the legacy pipeline's choice). The ΔF/F itself is not smoothed.

**v2's long-session fit makes an assumption:** by fitting only the baseline and the last hour, it assumes NE is back to baseline ~12 h after the injection. That puts the 13-h baselines at 0, and their post-injection NE rise (about +11% FP1, +21% FP2 at 2–4 h) becomes visible. The 5-h sessions keep the whole-recording fit, because their end is only ~4 h post-injection.

**Bandwidth:** every recording's spectrum rolls off steeply between about 6 and 10 Hz, in both 465 and 405. That's almost certainly the TDT demodulator's low-pass filter (Synapse's usual default is 6 Hz), though the actual setting hasn't been checked. Above about 1–2 Hz, the ΔF/F spectrum matches the 405 control spectrum, so the NE-specific content is below about 1 Hz.

## Data

**The data is not in this repo.** The recordings live alongside the code on the lab cluster, at `/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Yue/GlucoseProjectFiberNE/` (about 20 GB), and are excluded by `.gitignore`. They are shared lab data, so treat them as read-only.

Each top-level `FiberPhot*/`, `FP*/` or `Subject*/` folder is one TDT recording session:

| File(s) | Contents |
|---|---|
| `*.tev` | Raw photometry samples, about 3.5 GB per session. **This is the actual signal.** |
| `*.tsq`, `*.Tbk`, `*.Tdx`, `*.tin`, `*.tnt` | TDT tank index and metadata |
| `StoresListing.txt` | Channel (store) names and sampling rates |
| `*_Cam1.avi` | Behavior video |
| `*_signal_465.mat`, `*_signal_405.mat` | Raw 465/405 traces pre-extracted to MATLAB, single fiber, presumably PFC |
| `*_BL+end_fitting_*.mat`, `*.jpg`, `*.fig` | Outputs from earlier MATLAB runs: normalized traces and figures |
| `Thumbs.db`, `desktop.ini` | Windows cruft |

### Which recordings have usable signal

| Recording folder | Mouse / session | Raw signal available |
|---|---|---|
| `FiberPhot22_240324_morning` | 22, morning | ✅ full tank, PFC + OC |
| `FiberPhot22_240324_evening` | 22, evening | ✅ full tank, PFC + OC |
| `FiberPhot4_260324_morning` | 4, morning | ✅ full tank, PFC + OC |
| `FiberPhot4_260324_evening` | 4, evening | ✅ full tank, PFC + OC |
| `FP1_glucose_13hours_090424` | 1, 13-h glucose | ✅ `.mat` arrays, 1 fiber |
| `FP2_glucose_13hours_100424` | 2, 13-h glucose | ✅ `.mat` arrays, 1 fiber |
| `Subject1-240323-091543_morning` | 1, morning (5-h glucose) | ✅ `.mat` arrays, 1 fiber |
| `Subject3-240322-092543_morning` | 3, morning (5-h glucose) | ✅ `.mat` arrays, 1 fiber |
| `Subject1-240323-171604_evening` | 1, evening | ❌ `.tev` missing |
| `Subject2-240321-093251_210324` | 2 | ❌ `.tev` missing |
| `Subject3-240322-172818_evening` | 3, evening | ❌ `.tev` missing |
| `Subject33-240324-093611_morning` | 33, morning | ❌ `.tev` missing |
| `Subject33-240324-174256_evening` | 33, evening | ❌ `.tev` and `.tsq` missing |
| `Subject5-240326-090337_morning` | 5, morning | ❌ `.tev` and `.tsq` missing |
| `Subject5-240326-170315_evening` | 5, evening | ❌ `.tev` and `.tsq` missing |

The missing files may still exist on the original acquisition drive (`H:\Fiber photometry\Glucose\`). Which sessions are glucose and which are saline isn't fully recorded in the folder names; see [`questions_for_experimenters.md`](questions_for_experimenters.md), which is waiting on answers from the lab.
