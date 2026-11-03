# Questions for the Experimenters

For the people who ran the glucose fiber-photometry recordings (Rebeka and Elise), March–April 2024.

**What we're doing:** comparing the frequency and power of NE oscillations in PFC (GRAB-NE, `hSyn-NE2m`) before and after an IP glucose injection, against saline. We use the **first 5 hours of each recording**: ~1 h baseline, the injection, then ~4 h after. All of that is in the light phase. The 48-h study is now being analysed the same way: its first ~6 h first (2 h baseline, the injection at ~11:00, ~4 h after), then the full 48 h.

## Last open questions

Answered by Rebeka on 2026-11-03: all mice in the 5-h/13-h study are different animals (so FP1 and FP2 are new mice); no mouse or session was excluded, and fiber placement was not checked (the brains went to HPLC); the mice were not fasted and blood glucose was not measured; fiber A is always PFC and fiber C always OC.

Still open:

3. **Glucose concentration:** we have the volume (20 µL/g) but need the concentration of the glucose solution (e.g. 10% or 20% w/v) to give the dose in g/kg.
4. **Where is the OC fiber?** Is "OC" the occipital cortex, and where exactly is that fiber?

## 48-h study (asked 2026-10-29)

We're collecting the 48-h crossover tanks. 7 of 8 are here and complete.

5. *(Rebeka 2026-11-03: she doesn't have the raw files; she is uploading the `.mat` files, for COM12 only `ds_sec_signal` and `signals`. The raw files may be on the J-drive at CTN.)* **Missing raw files, May 8 RZ10-2 glucose (COM13/COM12):** the folder `48H_Glucose_RZ10-2_COM13(A)_COM12(C)` holds the tank `EliseFiber_EEG_timings-240430-184810`. Its block `Subject1-240508-090610_COM13(Fib1)_COM12(Fib2)` has only your MATLAB plots (`COM12_PFC_raw+normalized.jpg` is 0 bytes), with no `.tev/.tsq/.Tbk/.Tdx/.tin/.tnt`. The other two blocks are 2-min tests from 30 Apr. Do you have the raw files (~19.7 GB `.tev`), e.g. on the rig PC?
6. *(Answered by the lab journal, sheet 2, and confirmed by Rebeka 2026-11-03: both are saline.)* **Saline sessions named "glucose":** `48H_RZ10_1_saline_females_COM18(A)_COM16(C)_170624` (block `..._48HGlucose_170624`) and `48H_saline_RZ10-1_290524_COM12(A)_COM13(C)` (block `..._48H_glucose_RZ10-1_290524`). We read "glucose" as the study name and these as saline. Correct?
7. *(Answered by Rebeka 2026-11-03: COM# is one mouse with one PFC fiber. EEG/EMG was recorded on the Viewpoint system, `.exp` files in `48H_FP+EEG_Glucose+Saline/48H_GLU_EEG` and `48H_SAL_EEG`; not sleep scored, but some folders hold sdreamer predictions.)* **COM = mouse?** We read COM# as the mouse ID, one mouse per fiber, both fibers in PFC. In May, mice switch fiber between sessions (e.g. COM10 on A for glucose, on C for saline). Correct? And where is the EEG/EMG? None of the tanks has EEG/EMG channels.

8. **COM9's glucose injection time (May 8, RZ10-1):** the journal gives 11:30 for COM9 and 11:10 for its tank-mate COM10, and marks that day's start time "9:00(?)". COM9's signal has an injection-like change at 11:10 (465 up, 405 down, like COM10's) and nothing at 11:30. Was COM9 injected at 11:10?

**Not needed anymore:** the LED modulation frequencies and demodulator filter (the earlier question for Verena). We only analyze frequencies below ~1 Hz, well under the ~6 Hz cutoff we see.

## Sessions in the analysis

From Rebeka's notebook table. Injection times are measured from the start of each recording. Sessions marked "OneDrive" are missing their raw `.tev` here, and we'll copy them from Rebeka's OneDrive.

| Folder | Mouse | Date | Group | Dose (mL) | Injection (clock / into recording) | Raw data |
|---|---|---|---|---|---|---|
| `Subject2-240321-093251_210324` | #2 | 21 Mar 2024 | saline | 0.49 | 10:33 / +60.1 min (13-h session; first 5 h used) | OneDrive |
| `Subject3-240322-092543_morning` | #3 (block says 1) | 22 Mar 2024 | glucose | 0.54 | 10:28 / +62.2 min | ✅ |
| `Subject1-240323-091543_morning` | #1 | 23 Mar 2024 | **saline** | 0.52 | 10:16 / +60.2 min | ✅ |
| `FiberPhot22_240324_morning` | #22 = "new #2" (block says 2) | 24 Mar 2024 | glucose | 0.58 | 10:40 / +58.9 min | ✅ |
| `Subject33-240324-093611_morning` | #33 = "new #3" | 24 Mar 2024 | saline | 0.54 | 10:37 / +60.8 min | OneDrive |
| `FiberPhot4_260324_morning` | #4 (RZ10-1) | 26 Mar 2024 | glucose | 0.56 | 09:59 / +60.6 min | ✅ |
| `Subject5-240326-090337_morning` | #5 (RZ10-2) | 26 Mar 2024 | glucose | 0.60 | 10:03 / ~+59.4 min (folder stamp) | OneDrive |
| `FP1_glucose_13hours_090424` | "#2.1" (question 1) | 9 Apr 2024 | glucose | 0.52 | 10:27 / +66.5 min (first 5 h used) | ✅ |
| `FP2_glucose_13hours_100424` | "#2" (question 1) | 10 Apr 2024 | glucose | 0.60 | 10:04 / +59.9 min (first 5 h used) | ✅ |

That's 6 glucose and 3 saline mice. The evening sessions (17:00–22:00, ~7 h after the injection, partly after lights-off) are not used.

## What we've learned so far

Sources: Rebeka's summary deck (`Summary_glucose_data_files.pptx`, 2026-10-21), her digitized notebook (`glucose_study_digitized.xlsx`, 2026-10-26) and her written answers (2026-10-26). The two files are kept locally in the repo root and are gitignored.

- **Design:** one IP injection per mouse (glucose or saline, 20 µL/g) at ~10:00. Baseline from ~09:00, recording to 14:00, a break, then 17:00–22:00 in the same mouse. The 13-h sessions are the same protocol without the break. All 5+5-h / 13-h mice are male, 24.5–30 g.
- **Groups:** glucose = #3, #4, #5, #22, FP1, FP2; saline = #1, #2, #33. `GLU`/`glucose` in file names names the study, not the treatment: mouse 1's `5H_GLU_*` files are saline.
- **Injection times:** a clock time for every mouse, from the notebook. On the `.tsq` clock (Copenhagen time), every start and stop in the notebook matches the recording to the minute. The old script's "out of cage" times fall 0–2 min before the injections.
- **Mouse IDs:** the `FiberPhot2_240324` block is mouse 22 ("new #2"); the `Subject1-240322-092543` block is mouse 3. #4 = RZ10-1, #5 = RZ10-2.
- **Handling:** at most 1 min out of the recording chamber, then back into the same chamber. Food and water were available. The 20-min exclusion after the injection covers the handling/injection spike visible in the NE trace, so we keep it.
- **Light cycle:** lights on 07:00–19:00. The first 5 hours are all in the light.
- **Sleep:** no EEG/EMG in this study (only in the 48-h study). Sleep could be scored from the video plus the NE trace.
- **Acquisition:** settings were the same for every session. LED power was 10–20 µW at 405 nm and 20–30 µW at 465 nm.
- **Her result:** glucose raised the PFC NE level at 1 h and 2 h (n.s. from 3 h); saline was n.s. Details in `project_overview.md` (Prior Findings).
- **48-h study (not used now):** a crossover of 8 mice (4 male, 4 female), each given glucose and then saline 2–3 weeks later, with unscored EEG/EMG. It is on Rebeka's OneDrive / the CTN J: drive.
