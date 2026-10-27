# Questions for the Experimenters

For the people who ran the glucose fiber-photometry recordings (the tanks name Rebeka and Elise), March–April 2024.

**What we're doing:** comparing the frequency and power of NE oscillations in PFC (GRAB-NE, `hSyn-NE2m`) before and after an IP glucose injection, against saline and the pre-injection baseline. The recordings don't record treatment, injection time or mouse details, so we need these answers before we can make that comparison.

Questions are in priority order. Section A blocks the analysis.

## Answered so far (Rebeka's summary deck, received 2026-10-21)

Source: `Summary_glucose_data_files.pptx` in the repo root (gitignored), by E. Rebeka Kovács.

- **Design (Q3):** one injection per mouse. Morning + evening are **one experiment**: baseline from 09:00, IP saline or glucose at 10:00, recording to 14:00, a break 14:00–17:00, then recording 17:00–22:00. The evening session is ~7–12 h post-injection, **not** a second dose or a separate control. The 13-h sessions are the same protocol with no break.
- **Injection time (Q4):** ~10:00, i.e. ~60 min into the morning / 13-h recording. Exact timestamps per mouse are in her paper lab journal, left at CTN.
- **Groups:** her PFC figures use **5 glucose and 3 saline mice**, with time points at baseline, 1–3 h and 8–12 h post-injection. The deck doesn't say which mouse is in which group.
- **Fibers (Q7, partly):** this study recorded PFC and OC in every mouse. OC is still undefined.
- **Her result (Q15):** glucose raised the PFC NE level at 1 h (paired test, \*\*), staying up ~3 h and back near baseline by 8 h; saline was n.s. She cites Levin 1991 (plasma NE rises after IP glucose).
- **Back to baseline by ~12 h (Q16):** her glucose group mean is near baseline at 9–12 h, which loosely supports the v2 fit. One of the 5 mice is still elevated (~+8 z) at 11–12 h.
- **Where the rest lives:** `J:\CTN\NedergaardLAB\Personal_folders\Rebeka\Glucose\` holds this study (`5H_13H_Glucose_Saline`), her `Analyses` folder with processed per-animal data, and several more presentations.

New, from the deck:

- **A 48-h study** (`48H_FP+EEG_Glucose+Saline`, same J: folder; not on the cluster): PFC NE only, glucose and saline, n = 4 per group per sex (16 mice). Habituation from 15:00 the day before, baseline 09:00, injection 11:00, recording ends 46 h after. It also has **unscored EEG/EMG**; the EEG–photometry sync TTL exists for only about half the files (which ones is in the lab journal). She warns that the "bump" in her processed 48-h traces is a fitting artifact of the long recording.

## Answered by Rebeka's notebook table (received 2026-10-26)

Source: `glucose_study_digitized.xlsx` in the repo root (gitignored), her digitized lab journal. One sheet covers the 5+5-h / 13-h study, one the 48-h study.

- **Groups (A1, Q1):** glucose = mice #3, #4, #5, #22, FP1, FP2; saline = #1, #2, #33. Mouse **#1 is saline**, even though its files are named `5H_GLU_*`: "GLU" names the study, not the treatment. The legacy morning glucose script uses exactly the 6 glucose mice, which agrees.
- **Injection times (Q4):** clock times for every mouse. On the `.tsq` clock (Copenhagen time: UTC+1 in March, UTC+2 in April), every start and stop in the sheet matches the recording to the minute. Injection is at 59–62 min into the morning / 13-h recording, 66.5 min for FP1. The evening sessions start ~7.0 h after injection (7.2 h for #22). The legacy "out of cage" times fall 0–2 min before these injections.
- **Dose (Q2, partly):** 20 µL/g body weight for both glucose and saline (0.49–0.60 mL). All mice are male, 24.5–30 g.
- **Mouse IDs (Q6):** #22 is "new #2", so the `FiberPhot2_240324` block is mouse 22. The sheet's only mouse on 22 Mar is #3, so the `Subject1-240322-092543` block is mouse 3. #4 = RZ10-1, #5 = RZ10-2. FP1 = "#2.1" and FP2 = "#2", so neither is Subject1.
- **Subject2 is a 13-h session** (09:33–22:50, saline). It is the only 13-h saline recording, and its `.tev` is missing.
- **48-h study:** a **crossover of 8 mice** (4 male COM9/10/12/13, 4 female COM14/15/16/18). Each mouse got glucose first and saline 2–3 weeks later (males 8 and 29 May 2024, females 3 and 17 June 2024), injected ~11:00–11:30. That is 8 mice in both conditions, not 16 mice. Rig (R210-1/-2) and fiber (A/C) are listed per session, and a mouse's fiber can change between its two sessions. Male glucose start times are marked "9:00(?)".

What this means for us: of the 8 sessions with raw data, **only Subject1 morning is saline** (1 mouse, baseline + 4 h after injection). The other saline sessions (#2, #33, #1 evening) are all missing their `.tev`. So the saline comparison depends on recovering those files.

Still open:

- **A1. Is FP2 ("#2") the original #2 (saline on 21 Mar), the "new #2" (#22, glucose on 24 Mar), or a new mouse?** And is FP1 ("#2.1") a new mouse? Her figures use 5 glucose mice, but the table lists 6 glucose IDs, so one may be a repeat or excluded.
- **A2. Could someone copy the J: `Glucose` folder to the cluster?** Mainly the 48-h data (FP + EEG), the `Analyses` folder and the presentations. Plus the 7 missing `.tev`/`.tsq` files, which now hold 3 of our 4 saline sessions.
- **A3. Lab journal:** which 48-h files have the EEG–photometry TTL? Glucose concentration (to give the dose in g/kg)?
- Still unanswered from below: fasting / blood glucose (Q5), which fiber is PFC for each 5-h mouse and what OC is (Q7), known problems (Q10), LED modulation frequencies and demodulator low-pass (Q14).

## Answered by Rebeka by message (2026-10-26)

- **Light cycle (Q11):** lights on 07:00–19:00, off 19:00–07:00. Baseline and the morning session are all in the light. **Lights go off ~1–2 h into each evening session and ~9.7–9.9 h into the 13-h sessions**, so the last 3 h of every long recording are in the dark (active) phase.
- **Sleep / EEG (Q12):** EEG/EMG exists only for the 48-h study. For the 5+5-h / 13-h study, she suggests scoring sleep from the video plus the NE trace.
- **Handling (Q13):** at most 1 min out of the recording chamber, then back into the same chamber. Food and water were available. The legacy 20-min post-injection exclusion came from looking at the NE trace: handling and injection cause a spike.
- **Acquisition (Q14, partly):** settings did not change between sessions. LED power: 405 nm at 10–20 µW, 465 nm at 20–30 µW. Modulation frequencies and the demodulator filter need Verena to check the rig protocols at CTN.

## A. Treatment and timing (blocking)

1. **Please fill in the session table below.** For each session: glucose or saline, the injection time, and the mouse ID.
2. **Dose:** glucose dose (g/kg), concentration and injected volume. Saline volume. Were these the same in the 5-h and 13-h experiments?
3. **Design:** did each mouse get both glucose and saline? If so, in what order, and how far apart? Most mice were recorded in the morning (~09:00) and again in the evening (~17:00) on the same day. Was the evening session a saline control, a second glucose dose, or something else? If glucose was given in the morning, could it still be affecting the evening session?
4. **Injection time:** the tanks have no TTL or note marking the injection. The old analysis script has hand-entered times for 6 morning sessions (injection at ~60–67 min, a "taken out of cage" time just before it). Where did those times come from, and which mouse is each one? Do you have injection times for the evening and 13-h sessions? If there's no record, can the injection be seen in the camera video (`*_Cam1.avi`)?
5. **Fasting and blood glucose:** were the mice fasted before the injection, and for how long? Was blood glucose measured? If so, please send the values and when they were taken.

## B. Mice and recordings

6. **Mouse identity.** Some names conflict:
   - The `FiberPhot22_240324_morning` folder holds a block named `FiberPhot2_240324`. Is this mouse 22 or mouse 2?
   - The `Subject3-240322-092543_morning` folder holds a block named `Subject1-240322-092543`. Is this mouse 3 or mouse 1?
   - Are `FP1`/`FP2` in the 13-h sessions the same mice as `Subject1`/`Subject2`? Are mice 4 and 22 different animals from mice 1–5?

   A master list with each mouse's ID, sex, age, weight, virus and fiber coordinates would solve this.
7. **Fibers:** we assume fiber 1 (`465A`/`405A`) is PFC and fiber 2 (`465C`/`405C`) is "OC". What region is OC? For the sessions that were saved only as single-fiber `.mat` arrays, which fiber are they from? Was fiber placement checked by histology, and should any mouse be excluded?
8. **Missing raw data:** 7 sessions are missing their `.tev` data file (3 are also missing the `.tsq`). This includes Subject5 morning, which the old glucose analysis used. Do these files exist somewhere else, such as the acquisition PC (`H:\Fiber photometry\Glucose\`)? The full tanks for FP1/FP2 13-h and Subject1/Subject3 morning would also give us the second fiber.
   - Missing `.tev`: Subject1 evening, Subject2 (210324), Subject3 evening, Subject33 morning
   - Missing `.tev` and `.tsq`: Subject33 evening, Subject5 morning, Subject5 evening
9. **Other sessions:** are there more glucose or saline recordings that aren't in this folder? We currently have usable data from only 8 sessions, and possibly only 2 saline sessions.
10. **Known problems:** were there any sessions with cable disconnects, a mouse that got tangled, fiber damage, or anything else we should exclude or watch for?

## C. Conditions during recording

11. **Light cycle:** what time do lights go on and off in the recording room? Were lights on or off during the 13-h sessions, and did they change partway through? NE oscillations depend strongly on sleep state and time of day.
12. **Sleep and behavior:** was EEG/EMG recorded alongside photometry? If not, is the video good enough to score sleep/wake or movement? Slow NE oscillations in cortex track sleep, so glucose effects on sleep could look like effects on NE.
13. **Handling:** how long was each mouse out of its home cage for the injection? Was it put back in the same cage? Did the mice have food and water during the recording? The old script excludes 20 min after the injection; is that the window you'd recommend?
14. **Acquisition settings:** in Synapse, what were the LED modulation frequencies, LED powers and the demodulator low-pass filter? We see a cutoff near 6 Hz in every recording. Did any of these change between sessions?

## D. Expectations

15. **Hypothesis:** what effect of glucose on NE did you expect or see? Is there a time window you expect to matter most (for example the first hour, or 2–4 h after injection)? Did the earlier dip analysis lead to any conclusion?
16. **13-h sessions:** do you expect NE to return to baseline by about 12 h after the injection? Our normalization of these sessions currently assumes it does.

## Session table

| Folder | Mouse ID | Date | Group | Dose (mL) | Injection (clock / into recording) | Raw data |
|---|---|---|---|---|---|---|
| `Subject2-240321-093251_210324` | #2 | 21 Mar 2024 | saline | 0.49 | 10:33 / +60.1 min (13-h session) | missing |
| `Subject3-240322-092543_morning` | #3 (block says 1) | 22 Mar 2024 | glucose | 0.54 | 10:28 / +62.2 min | ✅ |
| `Subject3-240322-172818_evening` | #3 | 22 Mar 2024 | glucose | | starts 7.01 h after | missing |
| `Subject1-240323-091543_morning` | #1 | 23 Mar 2024 | **saline** | 0.52 | 10:16 / +60.2 min | ✅ |
| `Subject1-240323-171604_evening` | #1 | 23 Mar 2024 | saline | | starts 7.00 h after | missing |
| `FiberPhot22_240324_morning` | #22 = "new #2" (block says 2) | 24 Mar 2024 | glucose | 0.58 | 10:40 / +58.9 min | ✅ |
| `FiberPhot22_240324_evening` | #22 | 24 Mar 2024 | glucose | | starts 7.22 h after | ✅ |
| `Subject33-240324-093611_morning` | #33 = "new #3" | 24 Mar 2024 | saline | 0.54 | 10:37 / +60.8 min | missing |
| `Subject33-240324-174256_evening` | #33 | 24 Mar 2024 | saline | | evening start 17:42 (folder stamp) | missing |
| `FiberPhot4_260324_morning` | #4 (RZ10-1) | 26 Mar 2024 | glucose | 0.56 | 09:59 / +60.6 min | ✅ |
| `FiberPhot4_260324_evening` | #4 | 26 Mar 2024 | glucose | | starts 6.99 h after | ✅ |
| `Subject5-240326-090337_morning` | #5 (RZ10-2) | 26 Mar 2024 | glucose | 0.60 | 10:03 / ~+59.4 min (folder stamp) | missing |
| `Subject5-240326-170315_evening` | #5 | 26 Mar 2024 | glucose | | evening start 17:03 (folder stamp) | missing |
| `FP1_glucose_13hours_090424` | "#2.1" | 9 Apr 2024 | glucose | 0.52 | 10:27 / +66.5 min | ✅ |
| `FP2_glucose_13hours_100424` | "#2" (which #2? A1) | 10 Apr 2024 | glucose | 0.60 | 10:04 / +59.9 min | ✅ |

Filled from Rebeka's table (2026-10-26). "Into recording" is measured from the `.tsq` start time; injection clock times have 1-min precision. Evening rows give the evening start's offset after the morning injection.
