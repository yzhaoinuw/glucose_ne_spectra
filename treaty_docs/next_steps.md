# Next Steps

Use this checklist alongside `work_log.md`.

## Currently Hot

Active threads — read these first to know what work is in flight:

- [Spectral analysis of NE oscillations](#spectral-analysis-of-ne-oscillations-claude-opus-5-5): the project's goal. Scope set 2026-10-27: **first 5 h of each recording**, PFC spectra only (NE level is secondary). First pass done 2026-10-27 (`spectra/`, option (c)); report in `reports/2026-10-27_first5h_ne_spectra.md`. Next: the user reviews the figures; decide on stats, the sleep-state confound and FP1/FP2 identity before any claim.
- [Pull the 4 missing `.tev` files](#pull-the-4-missing-tev-files-claude-opus-5-5): done 2026-10-28. All 9 sessions read from tanks; OC side check in the report (same 3 responders as PFC). Open only: the experimenter confirming fiber A = PFC (question 4).
- [NE extraction to .mat](#ne-extraction-to-mat-claude-opus-5-5): v2 (~20 Hz) in `outputs/ne_pfc_ds20/`. First-5-h run done for all 9 mice; `spectra/` uses its raw traces, not its `dff`.

- [48-h study](#48-h-study-claude-opus-5-5): in scope since 2026-10-29. All 14 mouse-sessions extracted; first-6-h spectra done 2026-10-30 (`reports/2026-10-30_48h_first6h_ne_spectra.md`): 1 of 6 glucose mice (COM9) responds strongly. Next: the user reviews; decide on the full 48 h. Missing: May 8 RZ10-2 glucose (COM13/COM12), asked Rebeka.

When an agent (or human) creates or significantly updates a thread/plan here, include model + version, effort/thinking mode, and token budget (if known) in parentheses after the thread name or at the end of the status line, using the same compact convention as `work_log.md`.

## 48-h study (claude-opus-5-5)

Status: in scope since 2026-10-29 (user's call). 7 of 8 tanks verified; all 14 mouse-sessions with raw data extracted (claude-opus-5-5, effort low). 6 mice have both conditions (COM9, COM10 male; COM14, COM15, COM16, COM18 female); COM12 and COM13 have saline only.

Extraction: `sbatch extraction/run_extract_ne_48h.sbatch` -> `outputs/ne_48h_ds20/<mouse>_<condition>.mat`, ~8 min. Session table with journal metadata in `extraction/recordings48.m`; each file stores `inj_min`. QC: `outputs/ne_48h_ds20/qc/`, including `first6h_overview.png` (all 14, ±injection).

Plan agreed with the user:

- [x] **First pass, spectra on the first ~6 h** (2026-10-30, `python -m spectra.run_48h_first6h`, report `reports/2026-10-30_48h_first6h_ne_spectra.md`), to compare block by block with the 5-h study: the same post-injection blocks (+20–80, +80–140, +140–200, +200–240 min) against the **last hour before the injection** (the first hour may still hold the settling-in after hookup). Same measures as `spectra/` (raw 465/405, coherence). Glucose vs saline within mouse is now possible (crossover).
- [x] **COM9 glucose baseline:** ends at 11:07 (`spectra/sessions48.py`), before 11:10, not at the journal's 11:30. Its signal shows an injection-like change at 11:10 and nothing at 11:30 (`qc/may8_injection_zoom.png`); asked Rebeka (question 8).
- [ ] **User to review the first-6-h report.** COM9 is the only strong responder, and it is the session with the doubtful injection time. Saline sessions drift down over the afternoon, so read effects within mouse.
- [ ] **Second pass, the full 48 h** in hourly bins, glucose vs. saline at the same clock time. Spans 2 dark phases, so sleep/activity is a bigger confound than in the 5-h data, with no EEG to control for it.
- [ ] dF/F in these files uses the long-session fit (first 50 min + last hour) and assumes NE is back to baseline at 48 h. Use the raw traces for spectra, as in the 5-h study.

The user downloads the tanks into `Yue/48H_GLU_FP/` and `Yue/48H_SAL_FP/` (outside this repo, next to it). Check each new one with `outputs/checks/tsq_vs_tev.py <folder>` and `check_tank48('<folder>')` in a debug-partition `sbatch` job (32 GB); this session's own allocation was too small for `srun`.

Each fiber is a different mouse (COM# = mouse ID, both PFC). Fiber per mouse changes between sessions, so map by COM, not by A/C.

| Mouse (A / C) | Glucose session | Saline session |
|---|---|---|
| COM10 / COM9 → COM9 / COM10 | 2024-05-08, RZ10-1, `48H_GLU_FP/48H_Glucose_RZ10-1_COM10(A)_COM9(C)` ✅ (fiber A ~5× dim) | 2024-05-29, RZ10-2, `48H_SAL_FP/48H_saline_RZ10_2_COM9(A)_COM10(C)` ✅ |
| COM13 / COM12 → COM12 / COM13 | 2024-05-08, RZ10-2, `Yue/48H_Glucose_RZ10-2_COM13(A)_COM12(C)` ❌ **raw files missing** (plots only) | 2024-05-29, RZ10-1, `48H_SAL_FP/48H_saline_RZ10-1_290524_COM12(A)_COM13(C)` ✅ |
| COM14 / COM15 (female) | 2024-06-03, RZ10-1, `48H_GLU_FP/48H_glucose_females_RZ10-1_240603_COM14(A)_COM15(C)` ✅ | 2024-06-17, RZ10-2, `48H_SAL_FP/48H_sal_females_RZ10_2_COM14(A)_COM15(C)_170624` ✅ |
| COM18 / COM16 (female) | 2024-06-03, RZ10-2, `48H_GLU_FP/48H_glucose_females_RZ10-2_050624_COM18(A)_COM16(C)` ✅ | 2024-06-17, RZ10-1, `48H_SAL_FP/48H_RZ10_1_saline_females_COM18(A)_COM16(C)_170624` ✅ |

Open:

- [ ] COM13/COM12 glucose block `Subject1-240508-090610` (tank `EliseFiber_EEG_timings-240430-184810`): `.tev` (~19.7 GB) and its `.tsq/.Tbk/.Tdx/.tin/.tnt/StoresListing.txt`. Asked Rebeka 2026-10-29 (questions file, 48-h section).
- [x] The two saline tanks whose block names say "glucose" are saline (lab journal, sheet 2).
- [ ] No tank has EEG/EMG stores, although the study had EEG/EMG. Find where it was recorded before planning sleep scoring.
- Folder name `..._RZ10-2_050624_...` vs tank date 2024-06-03: likely the end date (day-first), not a mismatch.

## Pull the 4 missing .tev files (claude-opus-5-5)

Status: done 2026-10-28 (claude-opus-5-5, effort low). Kept here for the record until the next rotation.

#1, #3, FP1 and FP2 have no raw signal file (`.tev`), only single-fiber `.mat` arrays. Their tanks recorded both fibers (`465A/405A` = `FibPho1_PFC`, `465C/405C` = `FibPho2`, per `StoresListing.txt`), and the rest of each tank (`.tsq`, `.Tbk`, `.Tdx`, …) is present.

Why: OC (fiber 2) is now raw for only 5 of 9 mice (#4, #22, #5, #2, #33), and none of the strong PFC responders except #5. With these files, OC covers all 9. It also shows which store the old `.mat` arrays came from (report caveat "Fiber assignment"), and all 9 can go through the same tank extraction.

**User:** download from Rebeka's OneDrive and place each file in its folder, next to its `.tsq`, as with the 2026-10-27 recovery. The folders are the labmate's shared data, so agents don't write there.

| Mouse | Folder | File | Expected size (bytes) |
|---|---|---|---|
| #1 (saline) | `Subject1-240323-091543_morning/` | `EliseFiber1-240321-092235_Subject1-240323-091543.tev` | 2,052,608,120 |
| #3 (glucose) | `Subject3-240322-092543_morning/` | `EliseFiber1-240321-092235_Subject1-240322-092543.tev` | 2,071,849,080 |
| FP1 (glucose) | `FP1_glucose_13hours_090424/` | `Rebeka_FP3-240409-091839_FP1_glucose_090424.tev` | 5,383,655,544 |
| FP2 (glucose) | `FP2_glucose_13hours_100424/` | `Rebeka_FP3-240410-084359_FP2_glucose_13hours_100424.tev` | 5,349,994,616 |

Total ~15 GB. Each expected size is the `.tsq`'s last stream offset plus 40 B; the same rule matches #5's recovered `.tev` to the byte. A file of exactly that size is complete.

**Agent, once the files are in:**

1. ~~Check each size against the table, then read it in full with `TDTbin2mat`.~~ Done: sizes exact; all 4 stores match the `.tsq` count, no NaN or zeros, longest flat run ≤ 33 samples; starts match `StoresListing.txt`.
2. ~~Compare the old `.mat` arrays with `465A`/`465C`.~~ Done: identical to `465A`/`405A` (max diff 0, offset 1016 samples), so fiber A. Not `465C` (r 0.91–0.98).
3. ~~Switch the 4 sessions to the tank source.~~ Done; PFC results unchanged (< 0.0001 log2).
4. ~~Add OC to the extraction and `spectra/`.~~ Done: `outputs/ne_oc_ds20_first5h/`, `run_first5h --fiber oc` -> `results/spectra_first5h_oc/`.
5. ~~Update README and report.~~ Done: report section "Side check: the OC fiber".

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
- OC fiber (`465C`/`405C`): extracted for the first-5-h cohort only (2026-10-28); the full-recording v1/v2 runs are still PFC only.

## Background / Paused

Sections below this line are older threads kept for context. They're not the current focus, but recording the state they were left in saves the next agent from re-deriving it.

### GitHub remote (claude-opus-5-5)

Done 2026-10-20. `origin` = `git@github.com:yzhaoinuw/glucose_ne_spectra.git` (**public**; anything committed is world-readable), `main` tracks `origin/main`. Push over SSH; there's no `gh` CLI on the cluster.
