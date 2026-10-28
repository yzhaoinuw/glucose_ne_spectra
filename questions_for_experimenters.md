# Questions for the Experimenters

For the people who ran the glucose fiber-photometry recordings (Rebeka and Elise), March–April 2024.

**What we're doing:** comparing the frequency and power of NE oscillations in PFC (GRAB-NE, `hSyn-NE2m`) before and after an IP glucose injection, against saline. We use the **first 5 hours of each recording**: ~1 h baseline, the injection, then ~4 h after. All of that is in the light phase. The 48-h study is out of scope for now.

## Last open questions

Rebeka: thank you, your deck, notebook table and answers covered almost everything. These four are all that's left.

1. **Which mice are FP1 and FP2?** The notebook lists FP2 as "#2" and FP1 as "#2.1". Is FP2 the original #2 (saline, 21 Mar), the "new #2" (#22, glucose, 24 Mar), or a different mouse? Is FP1 a new mouse? Your PFC figures use 5 glucose mice, but the notebook lists 6 glucose IDs (#3, #4, #5, #22, FP1, FP2), so we want to know whether one is a repeat.
2. **Exclusions:** should any mouse or session be left out, for example a misplaced fiber on histology, a cable disconnect or a tangled mouse?
3. **Fasting and dose:** were the mice fasted before the injection, and for how long? Was blood glucose measured? If so, what were the values and when were they taken? What was the glucose concentration? We have the volume (20 µL/g) but need the concentration to give the dose in g/kg.
4. **Fiber A = PFC?** In the 5-h and 13-h mice, is fiber A (`465A`/`405A`) always PFC? (We checked the pre-extracted `*_signal_465.mat` / `*_signal_405.mat` files against the recovered tanks: they are fiber A. The tanks name fiber A `FibPho1_PFC`.) And is "OC" (fiber C) the occipital cortex? Where exactly is that fiber?

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
