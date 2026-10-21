# Next Steps

Use this checklist alongside `work_log.md`.

## Currently Hot

Active threads — read these first to know what work is in flight:

- [NE extraction to .mat](#ne-extraction-to-mat-claude-opus-5-5): waiting on the user's answers about channels, resolution, fit window and the `TDTbin2mat` location. Then write the extraction script and run it on the 8 usable recordings.

When an agent (or human) creates or significantly updates a thread/plan here, include model + version, effort/thinking mode, and token budget (if known) in parentheses after the thread name or at the end of the status line, using the same compact convention as `work_log.md`.

Other sections below are background or paused; treat them as reference unless a new request reopens them.

## NE extraction to .mat (claude-opus-5-5)

Status: blocked on user input

Extract a per-recording NE trace into one `.mat` file each, for the user's own downstream analyses. Follow the legacy preprocessing in `matlab_scripts/Pre_process_batch_and_analyse_Glucose_PFC_morning.m`, with these bugs fixed: use each recording's own sampling rate, actually apply the start trim, no `eval`-generated variable names, and label the output ΔF/F % rather than "z score".

Proposed plan:

- Linear 405→465 `polyfit` → smooth the fit → ΔF/F % = 100·(465 − fit)/fit → smooth → downsample ×100 (about 10 Hz).
- One `.mat` per recording containing `dff`, `time_min`, `fs`, the channel name, the fit coefficients and the source path. Also save a QC plot (raw vs. fit).
- 8 recordings can be extracted: 4 full tanks (PFC + OC) and 4 pre-extracted `.mat` (single fiber). See the README table.

Open questions for the user (asked 2026-10-20):

1. PFC only, or OC too?
2. Is ~10 Hz enough, or do we also need the full ~1 kHz trace? For a spectral analysis, the ×100 downsampling caps the spectrum at about 5 Hz, and the 1000-sample smoothing strongly attenuates anything above about 0.5 Hz.
3. Fit over the whole recording (default), or a baseline-only window?
4. Where is `TDTbin2mat`? Alternative: the Python `tdt` package (`tdt.read_block`) reads tanks directly, with no MATLAB needed.

Remaining work:

- Get the answers → write the script → run it under SLURM → check the QC plots against the old `.jpg` figures in each folder.

## Background / Paused

Sections below this line are older threads kept for context. They're not the current focus, but recording the state they were left in saves the next agent from re-deriving it.

### Spectral analysis of NE oscillations

This is the project's actual goal: compare the NE power spectrum before vs. after the glucose (and saline) injection. It's not started yet; it comes after extraction. Method choice (Welch / multitaper / wavelet), frequency bands and window length are undecided. See "Questions Worth Clarifying Later" in `project_overview.md`.

### GitHub remote (claude-opus-5-5)

Done 2026-10-20. `origin` = `git@github.com:yzhaoinuw/glucose_ne_spectra.git` (private), `main` tracks `origin/main`. Push over SSH; there's no `gh` CLI on the cluster.
