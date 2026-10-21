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

Still open after the deck — new questions:

- **A1. Which mouse is glucose and which is saline?** Morning + evening are the same mouse, so our 8 usable sessions are at most 6 mice (22, 4, FP1, FP2, 1, 3), fewer if FP1/FP2 are Subject1/2. Her figures use 8 mice. Which of her 8 are ours, and which group is each in?
- **A2. Could someone copy the J: `Glucose` folder to the cluster?** Mainly the 48-h data (FP + EEG), the `Analyses` folder and the presentations.
- **A3. Lab journal:** could the relevant pages (injection timestamps, TTL availability for the 48-h files) be photographed or transcribed?

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

Please fill in what you know; "?" is fine.

| Folder | Mouse ID | Date | Glucose / saline | Dose | Injection time (clock or min into recording) | Fasted? | Notes |
|---|---|---|---|---|---|---|---|
| `FiberPhot22_240324_morning` | 22? (block says 2) | 24 Mar 2024 | glucose? | | ~? | | |
| `FiberPhot22_240324_evening` | 22? | 24 Mar 2024 | same as morning | | | | |
| `FiberPhot4_260324_morning` | 4 | 26 Mar 2024 | glucose? | | | | |
| `FiberPhot4_260324_evening` | 4 | 26 Mar 2024 | same as morning | | | | |
| `FP1_glucose_13hours_090424` | FP1 | 9 Apr 2024 | glucose | | | | |
| `FP2_glucose_13hours_100424` | FP2 | 10 Apr 2024 | glucose | | | | |
| `Subject1-240323-091543_morning` | 1 | 23 Mar 2024 | glucose | | | | |
| `Subject1-240323-171604_evening` | 1 | 23 Mar 2024 | same as morning | | | | raw data missing |
| `Subject2-240321-093251_210324` | 2 | 21 Mar 2024 | ? | | | | raw data missing |
| `Subject3-240322-092543_morning` | 3? (block says 1) | 22 Mar 2024 | glucose | | | | |
| `Subject3-240322-172818_evening` | 3 | 22 Mar 2024 | same as morning | | | | raw data missing |
| `Subject33-240324-093611_morning` | 33 | 24 Mar 2024 | ? | | | | raw data missing |
| `Subject33-240324-174256_evening` | 33 | 24 Mar 2024 | same as morning | | | | raw data missing |
| `Subject5-240326-090337_morning` | 5 | 26 Mar 2024 | glucose? | | | | raw data missing |
| `Subject5-240326-170315_evening` | 5 | 26 Mar 2024 | same as morning | | | | raw data missing |

"glucose?" means the old morning glucose script includes the session but nothing in the recording confirms it. Plain "glucose" is confirmed by a folder or file name.
