# Next Steps

Use this checklist alongside `work_log.md`.

## Currently Hot

Active threads — read these first to know what work is in flight:

- [Spectral analysis of NE oscillations](#spectral-analysis-of-ne-oscillations-claude-opus-5-5): the project's goal. Scope set 2026-10-27: **first 5 h of each recording**, PFC spectra only (NE level is secondary). Next: pull the 3 missing tanks from Rebeka's OneDrive, re-extract FP1/FP2 on their first 5 h, then build the spectral pipeline.
- [NE extraction to .mat](#ne-extraction-to-mat-claude-opus-5-5): v2 (~20 Hz) in `outputs/ne_pfc_ds20/`. Needs a first-5-h variant for the 13-h sessions plus the 3 recovered sessions.

When an agent (or human) creates or significantly updates a thread/plan here, include model + version, effort/thinking mode, and token budget (if known) in parentheses after the thread name or at the end of the status line, using the same compact convention as `work_log.md`.

## Spectral analysis of NE oscillations (claude-opus-5-5)

Status: scope decided 2026-10-27, not started (claude-opus-5-5, effort high)

Compare the PFC NE power spectrum after the IP injection with each mouse's own baseline, glucose vs. saline.

Decisions (user, 2026-10-27):

- **First 5 h of each recording only** (~09:00–14:00): ~1 h baseline, the injection at 59–67 min, ~4 h after. All light phase (lights 07–19), so lights-off and the 13-h end-of-session fit both drop out. Evening sessions are not used.
- **Spectra are the focus**; hour-scale NE level is secondary.
- **48-h study is out of scope** for now.

Cohort (session table in [`questions_for_experimenters.md`](../questions_for_experimenters.md)): glucose #3, #4, #5, #22, FP1, FP2; saline #1, #2, #33. Have raw data for all but #2, #33 and #5. Pending the experimenter: whether FP2 ("#2") is a repeat mouse, plus exclusions, fasting/dose and fiber A = PFC (the 4 questions at the top of that file).

Windows: baseline = recording start → out-of-cage / injection; skip 20 min after the injection (handling spike, confirmed by the experimenter); then post-injection blocks to ~4 h. Compare post with the mouse's own baseline, then glucose vs. saline on that change.

Constraints found during extraction:

- Usable band is **below about 1 Hz**. Every recording rolls off steeply at about 6 Hz, and above about 1–2 Hz the ΔF/F PSD equals the 405 control PSD. ~20 Hz data is plenty.
- The 405 control carries comparable low-frequency power (Subject1 shows a 405 bump near 0.5 Hz). Treat the 405 spectrum as a control for every NE spectral claim.
- The baseline is only ~1 h: 2-min Welch windows (≈0.008 Hz resolution, ~60 half-overlapping segments) reach ~0.01 Hz, nothing slower. Detrend within windows; slow drift leaks into the lowest bins.
- Quick look (2026-10-26, not a result): 0.01–0.1 Hz ΔF/F power fell for ~3 h after glucose in FP1/FP2, but 405 fell too and FiberPhot22 morning didn't show it.

Open for the user: method (Welch / multitaper / time-frequency), bands, block length. Sleep state is a confound with no EEG here; the experimenter suggests scoring from video + NE.

## NE extraction to .mat (claude-opus-5-5)

Status: v1/v2 done 2026-10-20; first-5-h variant and 3 recovered sessions to do

Decisions (user, 2026-10-20): **PFC only**; reader = **`TDTbin2mat`** from the user's `preprocess_sleep_data` repo (vendored in `extraction/tdt/`). v1 = full rate, whole-recording fit; v2 = ×50 → ~20.35 Hz, robust bisquare 405→465 fit (format in `README.md`).

Remaining work:

- **Missing tanks from OneDrive** (all confirmed present there, 2026-10-27): `.tev` for `Subject2-240321-093251_210324` (13-h, ~6–7 GB), `Subject33-240324-093611_morning`, `Subject5-240326-090337_morning` (+ its `.tsq`). Search by stamp (`240321-093251`, `240324-093611`, `240326-090337`); blocks are all named `Subject1-<stamp>` in tank `EliseFiber1-240321-092235`. Put them in `recovered_raw/<our folder>/`, keep filenames, and check that OneDrive's `.Tdx` matches ours. A plain SharePoint `download.aspx?UniqueId=…` link returns 403 without login cookies; the user plans to download via a browser on the cluster. The CTN script `transfer/fetch_missing_tev.sh` is superseded.
- **First-5-h extraction:** fit FP1/FP2 (and #2) on their first 5 h with the same whole-window fit as the 5-h mornings, so every mouse is processed the same way. v2's 13-h baseline + last-hour fit (doubtful since lights go off at 19:00) is then no longer used.
- Optional later: OC fiber (`465C`/`405C`).

## Background / Paused

Sections below this line are older threads kept for context. They're not the current focus, but recording the state they were left in saves the next agent from re-deriving it.

### GitHub remote (claude-opus-5-5)

Done 2026-10-20. `origin` = `git@github.com:yzhaoinuw/glucose_ne_spectra.git` (private), `main` tracks `origin/main`. Push over SSH; there's no `gh` CLI on the cluster.
