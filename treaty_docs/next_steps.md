# Next Steps

Use this checklist alongside `work_log.md`.

## Currently Hot

Active threads — read these first to know what work is in flight:

- [NE extraction to .mat](#ne-extraction-to-mat-claude-opus-5-5): PFC-only full-rate traces for all 8 usable recordings are in `outputs/ne_pfc_fullrate/`. Open item: the fit window for the 13-h sessions.
- [Spectral analysis of NE oscillations](#spectral-analysis-of-ne-oscillations-claude-opus-5-5): the project's goal. Next: agree on method, bands and baseline/post windows with the user.

When an agent (or human) creates or significantly updates a thread/plan here, include model + version, effort/thinking mode, and token budget (if known) in parentheses after the thread name or at the end of the status line, using the same compact convention as `work_log.md`.

Other sections below are background or paused; treat them as reference unless a new request reopens them.

## NE extraction to .mat (claude-opus-5-5)

Status: done 2026-10-20. All 8 recordings extracted (SLURM job 31468026, 8.5 min, 1.8 GB)

Decisions (user, 2026-10-20): **PFC only**, **full sampling rate** (no smoothing/downsampling of ΔF/F, for spectral work), fit over the **whole recording**, reader = **`TDTbin2mat`** from the user's `preprocess_sleep_data` repo (vendored in `extraction/tdt/`).

Output: `outputs/ne_pfc_fullrate/<recording>.mat` + `qc/*.png` + `summary.csv`; format in `README.md`.

Remaining work:

- **Fit window for the 13-h sessions:** with the whole-recording fit, the FP1/FP2 baseline hour sits at about −8% / −13% ΔF/F, because 405 and 465 bleach differently over 13 h. That biases baseline-vs-post levels and power below about 0.001 Hz, but barely affects faster oscillations. Options: fit baseline + end segments (as the legacy `BL+end_fitting` outputs apparently did), fit only the first ~5 h to match the other sessions, or high-pass/detrend before spectral analysis. The user should decide.
- The user reviews the other QC figures in `outputs/ne_pfc_fullrate/qc/`.
- Optional later: OC fiber (`465C`/`405C`, 4 full tanks only); missing `.tev` files, if they can be recovered from the acquisition drive.

## Spectral analysis of NE oscillations (claude-opus-5-5)

Status: not started

Compare the NE power spectrum before vs. after the IP glucose (and saline) injection.

Constraints found during extraction:

- Usable band is **below about 1 Hz**. The TDT demodulator cuts at about 6 Hz, and above about 1–2 Hz the ΔF/F PSD equals the 405 control PSD. Decimating to about 10–20 Hz (anti-aliased) before spectral work is safe and makes everything ~50–100× smaller.
- The 405 control carries comparable low-frequency power (Subject1 shows a 405 bump near 0.5 Hz). Treat the 405 spectrum as a control for every NE spectral claim.
- The infraslow range (about 0.01–0.1 Hz) needs long windows. A 60-s Welch window gives about 0.017 Hz resolution, and the baseline is only about 60 min.

Open questions for the user:

- Method (Welch / multitaper / time-frequency), bands of interest, and the analysis windows (baseline vs. post-injection hours; the legacy injection times are hand-entered per mouse in the batch script).
- Which recordings are glucose vs. saline.

## Background / Paused

Sections below this line are older threads kept for context. They're not the current focus, but recording the state they were left in saves the next agent from re-deriving it.

### GitHub remote (claude-opus-5-5)

Done 2026-10-20. `origin` = `git@github.com:yzhaoinuw/glucose_ne_spectra.git` (private), `main` tracks `origin/main`. Push over SSH; there's no `gh` CLI on the cluster.
