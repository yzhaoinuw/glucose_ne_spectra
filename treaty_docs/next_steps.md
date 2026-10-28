# Next Steps

Use this checklist alongside `work_log.md`.

## Currently Hot

Active threads — read these first to know what work is in flight:

- [Spectral analysis of NE oscillations](#spectral-analysis-of-ne-oscillations-claude-opus-5-5): the project's goal. Scope set 2026-10-27: **first 5 h of each recording**, PFC spectra only (NE level is secondary). First pass done 2026-10-27 (`spectra/`, option (c)); report in `reports/2026-10-27_first5h_ne_spectra.md`. Next: the user reviews the figures; decide on stats, the sleep-state confound and FP1/FP2 identity before any claim.
- [NE extraction to .mat](#ne-extraction-to-mat-claude-opus-5-5): v2 (~20 Hz) in `outputs/ne_pfc_ds20/`. First-5-h run done for all 9 mice; `spectra/` uses its raw traces, not its `dff`.

When an agent (or human) creates or significantly updates a thread/plan here, include model + version, effort/thinking mode, and token budget (if known) in parentheses after the thread name or at the end of the status line, using the same compact convention as `work_log.md`.

## Spectral analysis of NE oscillations (claude-opus-5-5)

Status: first pass 2026-10-27 (claude-opus-5-5, effort low). Method and outputs in README "Spectral analysis".

First-pass observations (descriptive, n = 6 vs. 3, not a result yet):

- **0.01–0.05 Hz:** the 465 power not shared with 405 drops about 3–9× in 3 of 6 glucose mice (#5, FP1, FP2) for ~2–3 h, and briefly in #3 (+20–80 min). #4 and #22 don't drop (#22 rises). All 3 saline mice stay between ÷1.0 and ×1.6. The responders are the mice whose 465 level rose most, and 2 of the 3 are the FP sessions whose identity is unresolved.
- **0.05–0.2 Hz:** the glucose drop in the not-shared part extends to ~0.1 Hz (÷1.5 on average over the first 2 h). **0.2–1 Hz:** near 0 in both groups. The early glucose peak at ~0.15 Hz (+20–80 min) is coherent with 405 (artifact or hemodynamic) and drops out.
- 465–405 baseline coherence is 0.4–0.9 at 0.05–1 Hz in most mice (low in #22 and #33), so most of the 465 power there is shared with 405.
- Infraslow NE oscillations are a NREM-sleep feature, so a drop may mean less sleep rather than a direct glucose effect on NE dynamics. No EEG; video scoring is the experimenter's suggestion.

Open: stats approach (per-mouse change, permutation or mixed model; n is small), whether to narrow the bands (e.g. around ~0.02 Hz), sleep scoring.

Frequency range 0.01–1 Hz now justified from the full band (report Methodology + Appendix A, 2026-10-27). Not yet decided: whether to drop or flag the 0.2–1 Hz band for #22 and #33, where it is close to noise.

Compare the PFC NE power spectrum after the IP injection with each mouse's own baseline, glucose vs. saline.

Decisions (user, 2026-10-27):

- **First 5 h of each recording only** (~09:00–14:00): ~1 h baseline, the injection at 59–67 min, ~4 h after. All light phase (lights 07–19), so lights-off and the 13-h end-of-session fit both drop out. Evening sessions are not used.
- **Spectra are the focus**; hour-scale NE level is secondary.
- **48-h study is out of scope** for now.

Cohort (session table in [`questions_for_experimenters.md`](../questions_for_experimenters.md)): glucose #3, #4, #5, #22, FP1, FP2; saline #1, #2, #33. Raw data now exists for all 9 (#2, #33, #5 recovered 2026-10-27). Pending the experimenter: whether FP2 ("#2") is a repeat mouse, plus exclusions, fasting/dose and fiber A = PFC (the 4 questions at the top of that file).

Windows: baseline = recording start → out-of-cage / injection; skip 20 min after the injection (handling spike, confirmed by the experimenter); then post-injection blocks to ~4 h. Compare post with the mouse's own baseline, then glucose vs. saline on that change.

Constraints found during extraction:

- Usable band is **below about 1 Hz**. Every recording rolls off steeply at about 6 Hz, and above about 1–2 Hz the ΔF/F PSD equals the 405 control PSD. ~20 Hz data is plenty.
- The 405 control carries comparable low-frequency power (Subject1 shows a 405 bump near 0.5 Hz). Treat the 405 spectrum as a control for every NE spectral claim.
- The baseline is only ~1 h: 2-min Welch windows (≈0.008 Hz resolution, ~60 half-overlapping segments) reach ~0.01 Hz, nothing slower. Detrend within windows; slow drift leaks into the lowest bins.
- Quick look (2026-10-26, not a result): 0.01–0.1 Hz ΔF/F power fell for ~3 h after glucose in FP1/FP2, but 405 fell too and FiberPhot22 morning didn't show it.

Defaults chosen for the first pass (user can revise): Welch 2-min segments, bands 0.01–0.05 / 0.05–0.2 / 0.2–1 Hz, 60-min blocks. Sleep state is a confound with no EEG here; the experimenter suggests scoring from video + NE.

## NE extraction to .mat (claude-opus-5-5)

Status: v1/v2 done 2026-10-20; first-5-h run for all 9 done 2026-10-27, fit method open

Decisions (user, 2026-10-20): **PFC only**; reader = **`TDTbin2mat`** from the user's `preprocess_sleep_data` repo (vendored in `extraction/tdt/`). v1 = full rate, whole-recording fit; v2 = ×50 → ~20.35 Hz, robust bisquare 405→465 fit (format in `README.md`).

Remaining work:

- **Recovered tanks** (done 2026-10-27): #2, #33 and #5 are in `pfc_recordings.m` as `'tank'` sources. #33's PFC signal is weak (465 ≈ 69, 405 ≈ 56 a.u.) and its 405 dips track the 465 dips.
- **First-5-h extraction** (ran 2026-10-27, `extract_ne_pfc_first5h.m`, job 2223801): all 9 ok, but the whole-window robust fit is biased by the post-injection 465 rise against a bleaching 405. Slopes: FP2 −1.26, #5 −0.23, FP1 −0.01, others 0.29–0.82. FP2's ΔF/F has ~10× v1's power at 0.05–1 Hz.
- **405 correction decided (user, 2026-10-27): option (c).** 465 and 405 are analysed side by side (coherence, the 405-independent part of 465), with a baseline-only-fit ΔF/F as a cross-check. That cross-check is also unreliable for #5 (baseline slope −0.16). Background: in 0.01–1 Hz, 465 and 405 correlate at r = 0.57–0.86 with slopes ~0.9–2.1, and whole-window slopes are below that everywhere.
- Optional later: OC fiber (`465C`/`405C`).

## Background / Paused

Sections below this line are older threads kept for context. They're not the current focus, but recording the state they were left in saves the next agent from re-deriving it.

### GitHub remote (claude-opus-5-5)

Done 2026-10-20. `origin` = `git@github.com:yzhaoinuw/glucose_ne_spectra.git` (**public**; anything committed is world-readable), `main` tracks `origin/main`. Push over SSH; there's no `gh` CLI on the cluster.
