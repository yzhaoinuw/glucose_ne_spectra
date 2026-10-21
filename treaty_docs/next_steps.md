# Next Steps

Use this checklist alongside `work_log.md`.

## Currently Hot

Active threads — read these first to know what work is in flight:

- [NE extraction to .mat](#ne-extraction-to-mat-claude-opus-5-5): v2 (~20 Hz, robust baseline+end fit for the 13-h sessions) is the recommended output in `outputs/ne_pfc_ds20/`. Open: the user confirms v2's fit-window assumption.
- [Spectral analysis of NE oscillations](#spectral-analysis-of-ne-oscillations-claude-opus-5-5): the project's goal. Next: agree on method, bands and baseline/post windows with the user.

When an agent (or human) creates or significantly updates a thread/plan here, include model + version, effort/thinking mode, and token budget (if known) in parentheses after the thread name or at the end of the status line, using the same compact convention as `work_log.md`.

Other sections below are background or paused; treat them as reference unless a new request reopens them.

## NE extraction to .mat (claude-opus-5-5)

Status: done 2026-10-20 (v1 and v2); awaiting the user's sign-off on v2's fit assumption

Decisions (user, 2026-10-20): **PFC only**; reader = **`TDTbin2mat`** from the user's `preprocess_sleep_data` repo (vendored in `extraction/tdt/`). First round (v1): full rate, whole-recording fit. Second round (v2), on request: downsample and make the fit more robust.

Outputs (format in `README.md`):

- **v2 `outputs/ne_pfc_ds20/` (recommended):** ×50 → ~20.35 Hz; robust bisquare 405→465 fit; sessions ≥ 10 h fit on baseline (< 50 min) + last 60 min, shorter ones on the whole recording.
- v1 `outputs/ne_pfc_fullrate/`: full rate, least-squares whole-recording fit. Kept for comparison and full-rate checks.

Remaining work:

- **The user confirms v2's assumption** that NE is back to baseline in the last hour of the 13-h sessions (~12 h post-injection). The experimenter's glucose group mean is near baseline at 9–12 h, which loosely supports it, but 1 of her 5 mice is still elevated at 11–12 h. If not, the alternatives are a baseline-only fit (poorly constrained over 13 h) or treating hour-scale levels as unidentifiable and analysing only oscillations.
- For the 5-h sessions, v2 still uses the whole-recording fit, so a sustained NE change over the session is partly absorbed. It's small in practice: baseline offsets were 0.5–3%.
- Optional later: OC fiber (`465C`/`405C`, 4 full tanks only); missing `.tev` files, if they can be recovered from the acquisition drive; check the TDT demodulator filter setting to confirm the ~6 Hz roll-off.

## Spectral analysis of NE oscillations (claude-opus-5-5)

Status: not started

Compare the NE power spectrum before vs. after the IP glucose (and saline) injection.

Constraints found during extraction:

- Usable band is **below about 1 Hz**. Every recording rolls off steeply at about 6 Hz, presumably the TDT demodulator's low-pass (setting not verified), and above about 1–2 Hz the ΔF/F PSD equals the 405 control PSD. Decimating to about 10–20 Hz (anti-aliased) before spectral work is safe and makes everything ~50–100× smaller.
- The 405 control carries comparable low-frequency power (Subject1 shows a 405 bump near 0.5 Hz). Treat the 405 spectrum as a control for every NE spectral claim.
- The infraslow range (about 0.01–0.1 Hz) needs long windows. A 60-s Welch window gives about 0.017 Hz resolution, and the baseline is only about 60 min.

Open questions for the user:

- Method (Welch / multitaper / time-frequency), bands of interest, and the analysis windows (baseline vs. post-injection hours; the legacy injection times are hand-entered per mouse in the batch script).
- Design is now known (experimenter's deck, 2026-10-21): one injection per mouse at ~10:00 (~60 min into the morning / 13-h recording); the evening session is the same experiment at ~7–12 h post-injection. So analysis windows can be baseline (0–60 min), early post (1–4 h, morning) and late post (7–12 h, evening).
- **Still blocked:** which mouse is glucose vs. saline, and exact injection times. Both are in the experimenter's paper lab journal at CTN. Our usable data is at most 6 mice. See "Answered so far" and A1–A3 in [`questions_for_experimenters.md`](../questions_for_experimenters.md).
- **Possible new data:** a 48-h glucose/saline study (16 mice, PFC NE + unscored EEG/EMG) on the J: drive, not on the cluster. Larger n and EEG for sleep-state control; worth asking for a copy.

## Background / Paused

Sections below this line are older threads kept for context. They're not the current focus, but recording the state they were left in saves the next agent from re-deriving it.

### GitHub remote (claude-opus-5-5)

Done 2026-10-20. `origin` = `git@github.com:yzhaoinuw/glucose_ne_spectra.git` (private), `main` tracks `origin/main`. Push over SSH; there's no `gh` CLI on the cluster.
