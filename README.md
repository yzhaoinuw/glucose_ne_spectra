# glucose_ne_spectra

[![Agent Collab Treaty](https://raw.githubusercontent.com/yzhaoinuw/agent_collab_treaty/main/assets/treaty-adopted.svg)](https://github.com/yzhaoinuw/agent_collab_treaty)

This repo analyzes fiber-photometry recordings of norepinephrine (NE) in the mouse prefrontal cortex after an intraperitoneal (IP) injection of glucose vs. saline. It looks for **shifts in the frequency of NE oscillations across the power spectrum** after the dose, relative to the pre-injection baseline.

- **Sensor:** GRAB-NE `hSyn-NE2m`. 465 nm excitation is the NE signal; 405 nm is the isosbestic (motion/bleaching) control.
- **Acquisition:** TDT Synapse, about 1017.3 Hz, with two fibers: **PFC** (`465A`/`405A`) and **OC** (`465C`/`405C`; occipital cortex, from memory of a meeting, to be confirmed with the experimenter).
- **Protocol:** one IP injection per mouse. Baseline from 09:00, injection at ~10:00, recording to 14:00 (the "morning" session), a 3-h break, then 17:00–22:00 (the "evening" session, ~7–12 h post-injection). The two 13-h sessions run the same protocol without the break. Lights are on 07:00–19:00, so each evening session and the last ~3 h of each 13-h session are in the dark. Source: the experimenter's summary deck (see [`questions_for_experimenters.md`](questions_for_experimenters.md)).

## Repo layout

| Path | What it is |
|---|---|
| `matlab_scripts/` | The lab's original MATLAB pipeline: ΔF/F preprocessing, hourly-bin stats and NE-"dip" detection. **Reference only.** The new analysis is written in Python. See `project_overview.md` for what each script does and its known bugs. |
| `AGENTS.md`, `project_overview.md`, `treaty_docs/` | Project documentation and work log ([Agent Collab Treaty](https://github.com/yzhaoinuw/agent_collab_treaty)). Start at `AGENTS.md`. |
| `extraction/` | MATLAB extraction of PFC NE ΔF/F from the raw recordings: v1 full-rate (`extract_ne_pfc.m`) and v2 ~20 Hz (`extract_ne_pfc_ds.m`), shared loader, SLURM wrappers, and the vendored TDT reader (`tdt/`) |
| `spectra/` (Python) | Spectral analysis, first 5 h; tests in `tests/` |

## Extracted NE traces

There are two versions. **Use v2 for analysis**; v1 is kept for comparison and for anything that needs the full rate.

| | v1 `outputs/ne_pfc_fullrate/` | v2 `outputs/ne_pfc_ds20/` (recommended) |
|---|---|---|
| Rate | ~1017 Hz (original) | ~20.35 Hz (×50, anti-aliased) |
| 405→465 fit | least squares, whole recording | robust (bisquare); 13-h sessions fit on baseline + last hour, 5-h sessions on the whole recording |
| Baseline offset in 13-h sessions | −8% (FP1), −13% (FP2) | ~0% |
| Size | 1.8 GB | 52 MB |
| Run | `sbatch extraction/run_extract_ne_pfc.sbatch` (~8 min) | `sbatch extraction/run_extract_ne_pfc_ds.sbatch` (~4 min) |

**`outputs/ne_pfc_ds20_first5h/`: use its raw `signal_465` / `signal_405` only, not its `dff`.** The spectral analysis reads the raw traces from it. Its whole-window fit is pulled by the post-injection NE rise: FP2 (−1.26), #5 (−0.23) and FP1 (−0.01) get negative 405 slopes, so 405 noise is added rather than removed. The v2 method run on the first 5 h of the 9 cohort sessions (6 glucose, 3 saline; mornings plus the first 5 h of the 13-h sessions). Every session is fitted over its whole 5-h window, so all mice are treated the same way. Run with `sbatch extraction/run_extract_ne_pfc_first5h.sbatch`. Each file also stores `max_h = 5` and `fiber`.

**`outputs/ne_oc_ds20_first5h/`:** the same run on the OC fiber (`465C`/`405C`), same format. Its whole-window fit is also negative for FP2, FP1 and #22; use the raw traces here too.

Run them all from the repo root after `mkdir -p outputs/logs`. Each writes one `.mat` per usable recording (gitignored), a QC figure per recording to `qc/`, and a `summary.csv`. The files are MATLAB v7, so `scipy.io.loadmat` reads them. Both versions share these variables:

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

**v2's long-session fit makes an assumption:** by fitting only the baseline and the last hour, it assumes NE is back to baseline ~12 h after the injection. That puts the 13-h baselines at 0, and their post-injection NE rise (about +11% FP1, +21% FP2 at 2–4 h) becomes visible. The 5-h sessions keep the whole-recording fit, because their end is only ~4 h post-injection. Caveat (2026-10-26): lights go off at 19:00, so the fitted last hour is in the dark (active) phase while the baseline is in the light. The data can't test the assumption: the fit-free 465/405 ratio drifts upward even in a saline session.

**Bandwidth:** every recording's spectrum rolls off steeply between about 6 and 10 Hz, in both 465 and 405. That's almost certainly the TDT demodulator's low-pass filter (Synapse's usual default is 6 Hz), though the actual setting hasn't been checked. Above about 1–2 Hz, the ΔF/F spectrum matches the 405 control spectrum, so the NE-specific content is below about 1 Hz.

## Spectral analysis (first 5 h)

`spectra/` compares each mouse's post-injection spectra with its own baseline. It doesn't depend on one 405→465 fit: 465 and 405 are analysed side by side.

```
conda activate glucose_ne_spectra
python -m spectra.run_first5h              # ~1 min; reads outputs/ne_pfc_ds20_first5h/, writes results/spectra_first5h/ (tracked)
python -m spectra.run_first5h --fiber oc   # OC side check: outputs/ne_oc_ds20_first5h/ -> results/spectra_first5h_oc/
```

- **Windows** (`spectra/sessions.py`): baseline = 5 min → injection − 3 min; skip 20 min after the injection; then 60-min blocks (+20–80, +80–140, +140–200, +200–end ≈ 35–40 min).
- **Spectra:** Welch, 2-min Hann segments, 50% overlap, linear detrend per segment (~0.008 Hz resolution). Each channel is expressed as % of its own window mean.
- **Measures:** the 465 and 405 spectra; the 465–405 coherence; **the part of 465 not shared with 405**, P465 × (1 − coherence): the 465 power left after removing what moves in step with 405 at each frequency (no 405 trace is subtracted); and, as a cross-check, ΔF/F with a robust fit on the baseline only.
- **Bands:** 0.01–0.05, 0.05–0.2, 0.2–1 Hz. Band power is reported as log2 change vs. baseline (coherence as a difference).
- **Outputs** (in `results/spectra_first5h/`, or `results/spectra_first5h_oc/` for OC, whose figures are labelled in the corner; committed; `provenance.txt` names the code commit): `band_power.csv`, `spectra_logbinned.csv`, `baseline_fits.csv`, `raw_traces.png` (raw 465 and 405 of all mice with the fitted 405 scaling), `band_change.png`, `spectral_change.png`, `coherence.png`, `per_mouse/*.png`; full band to ~10 Hz: `full_band_baseline.png` / `.csv` (baseline spectra and coherence, all mice) and `full_band/*.png` (spectrograms of 465 and 405 and sliding coherence per recording).

## Data

**The data is not in this repo.** The recordings live alongside the code on the lab cluster, at `/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Yue/GlucoseProjectFiberNE/` (about 20 GB), and are excluded by `.gitignore`. They are shared lab data, so treat them as read-only.

Each top-level `FiberPhot*/`, `FP*/` or `Subject*/` folder is one TDT recording session:

| File(s) | Contents |
|---|---|
| `*.tev` | Raw photometry samples, about 3.5 GB per session. **This is the actual signal.** |
| `*.tsq`, `*.Tbk`, `*.Tdx`, `*.tin`, `*.tnt` | TDT tank index and metadata |
| `StoresListing.txt` | Channel (store) names and sampling rates |
| `*_Cam1.avi` | Behavior video |
| `*_signal_465.mat`, `*_signal_405.mat` | Raw 465/405 traces pre-extracted to MATLAB, single fiber. Identical to `465A`/`405A` (checked 2026-10-28); no longer used |
| `*_BL+end_fitting_*.mat`, `*.jpg`, `*.fig` | Outputs from earlier MATLAB runs: normalized traces and figures |
| `Thumbs.db`, `desktop.ini` | Windows cruft |

### Which recordings have usable signal

| Recording folder | Mouse / session (group) | Raw signal available |
|---|---|---|
| `FiberPhot22_240324_morning` | 22, morning (glucose) | ✅ full tank, PFC + OC |
| `FiberPhot22_240324_evening` | 22, evening (glucose) | ✅ full tank, PFC + OC |
| `FiberPhot4_260324_morning` | 4, morning (glucose) | ✅ full tank, PFC + OC |
| `FiberPhot4_260324_evening` | 4, evening (glucose) | ✅ full tank, PFC + OC |
| `FP1_glucose_13hours_090424` | "#2.1", 13-h (glucose) | ✅ full tank, PFC + OC (`.tev` recovered 2026-10-28) |
| `FP2_glucose_13hours_100424` | "#2", 13-h (glucose) | ✅ full tank, PFC + OC (`.tev` recovered 2026-10-28) |
| `Subject1-240323-091543_morning` | 1, morning (**saline**) | ✅ full tank, PFC + OC (`.tev` recovered 2026-10-28) |
| `Subject3-240322-092543_morning` | 3, morning (glucose) | ✅ full tank, PFC + OC (`.tev` recovered 2026-10-28) |
| `Subject2-240321-093251_210324` | 2, 13-h (saline) | ✅ full tank, PFC + OC (`.tev` recovered 2026-10-27) |
| `Subject33-240324-093611_morning` | 33, morning (saline) | ✅ full tank, PFC + OC (`.tev` recovered 2026-10-27; weak PFC signal, 465 ≈ 69 a.u.) |
| `Subject5-240326-090337_morning` | 5, morning (glucose) | ✅ full tank, PFC + OC (whole folder recovered 2026-10-27) |
| `Subject1-240323-171604_evening` | 1, evening (saline) | ❌ `.tev` missing |
| `Subject3-240322-172818_evening` | 3, evening (glucose) | ❌ `.tev` missing |
| `Subject33-240324-174256_evening` | 33, evening (saline) | ❌ `.tev` and `.tsq` missing |
| `Subject5-240326-170315_evening` | 5, evening (glucose) | ❌ `.tev` and `.tsq` missing |

The seven recovered tanks (3 on 2026-10-27, 4 on 2026-10-28) came from the experimenter's OneDrive and were placed in their original folders; each `.tev` is exactly the size its `.tsq` index expects and reads in full with `TDTbin2mat`. The remaining missing files (evening sessions only, outside the analysis scope) may still exist on the original acquisition drive (`H:\Fiber photometry\Glucose\`). Groups and injection times come from the experimenter's lab journal (`glucose_study_digitized.xlsx`, kept locally). Folder and file names don't encode treatment: `GLU`/`glucose` names the study, and mouse 1's `5H_GLU_*` files are saline. Per-session injection times are in the session table of [`questions_for_experimenters.md`](questions_for_experimenters.md).
