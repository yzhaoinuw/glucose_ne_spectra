# Work Log

Prepend new session notes to the top of this file.

Rotation policy: the live log holds at most the **5 most recent unique calendar dates**. When a new date would push the file past 5 unique dates, move the oldest 5 dates as a chunk into a new file at `work_log_archive/work_log_<earliest>_to_<latest>.md`. The live file always holds at most 5 unique dates; each archive file always holds exactly 5.

If today's date already has a `## YYYY-MM-DD` header at the top, add a new `###` session subsection under it rather than starting a second `## YYYY-MM-DD` header for the same date.

Update this log at the end of any substantive work session unless the user explicitly asks not to document it. **The log records decisions about the project, not the content of the work produced** — the diff already says what changed. See [Work Log Discipline](treaty_conventions.md#work-log-discipline) for what counts as substantive and what to skip.

## 2026-10-30

### First-6-h spectra for the 48-h study (claude-opus-5-5, effort low)

- User asked to go ahead with the spectra and to push. Reused `run_first5h.analyse` (sessions, window function and crop are now arguments) instead of a parallel pipeline; added `sessions48.py` and `run_48h_first6h.py`, which read sessions and injection times from the extraction's `summary.csv`.
- Windows as agreed: the hour before the injection (ending 3 min before), then the 5-h study's blocks +20–80 … +200–240 min. COM9 glucose baseline ends at 11:07. New figure: glucose minus saline within mouse.
- Finding: 1 of 6 glucose mice (COM9) shows the 5-h study's strong slow-band drop (÷9, then ÷3–4); the rest drop ÷1.5–2.1 in the first hour. Saline sessions drift down over the afternoon (÷2.1 by +200–240), in 405 too, so the report reads effects within mouse, not vs. baseline. COM9 is also the session with the doubtful injection time; its trace from 11:10 matches 5-h mouse #3's post-injection shape.
- Verification:
  - `black -l 110 --check spectra tests`; `python -m pytest -q tests` (11 passed)
  - `python -m spectra.run_48h_first6h` (commit `8d086e6`); inspected `raw_traces.png`, `band_change.png`, `paired_difference.png`, `per_mouse/COM9_glucose.png`
  - `python -m spectra.run_first5h` and `--fiber oc`: all CSVs unchanged
  - report numbers regenerated from `band_power.csv` / `paired_difference.csv`
  - `~/.local/venvs/treaty/bin/treaty validate .`

## 2026-10-29

### 48-h study brought into scope; all 14 mouse-sessions extracted (claude-opus-5-5, effort low)

- The user brought the 48-h study into scope, without waiting for the experimenter: the lab journal's sheet 2 gives mouse, sex, rig, fiber and injection time for every session, which is all extraction needs. It also answers questions 6 and most of 7.
- Plan agreed: extract the full 48 h, then run spectra first on the first ~6 h with the 5-h study's post-injection blocks, against the last hour before the injection (rather than the full 2 h, since the first hour may still include settling-in). Full 48 h in hourly bins comes second.
- Moved the v2 per-session processing into `process_ne_session.m`, shared by the 5-h and 48-h extractions, rather than copying it. The 5-h outputs (PFC and OC) are bit-identical after the change.
- Rig clocks: tank start times decode to ~03:00 EDT, but the journal and every block name with a time say ~09:00 (within 2–4 s of +6 h). The rig PCs' clocks were 6 h off; `extract_ne_48h` converts to the rig wall clock and checks block-name times where present. All injections land 116–144 min in, on the handling spike.
- Found a loader bug: one tank (June 3, RZ10-2) has 128 more 465C samples than 405C at the end. The loader's warning crashed, and its start-trim logic would have read the extra samples as a start shortfall (t0 off by 0.13 s). Now compared against the shorter store's index.
- COM9 glucose: the journal says 11:30 (tank-mate COM10 11:10, start time marked "(?)"), but its signal changes at 11:10 and not at 11:30. Kept the journal time in the files; the spectra baseline for COM9 should end before 11:10. Asked Rebeka (question 8).
- Verification:
  - `outputs/checks/refactor_check.m` (re-runs `extract_ne_pfc_first5h` for fibers A and C, compares with saved outputs): max difference 0 in every field, 18/18 sessions
  - `sbatch extraction/run_extract_ne_48h.sbatch` (job 2243867, commit `67ec3a4`): 14/14 ok, 47.9–48.1 h each
  - `outputs/ne_48h_ds20/qc/first6h_overview.png`, `may8_injection_zoom.png`; fiber A vs C correlation per tank ≤ 0.36 (465), so the two mice in a tank are independent
  - `~/.local/venvs/treaty/bin/treaty validate .`

### 48-h study tanks pulled and verified: 7 of 8 (claude-opus-5-5, effort low)

- The user is pulling the 48-h crossover tanks into `Yue/48H_GLU_FP/` and `Yue/48H_SAL_FP/`, outside this repo. Still out of scope for analysis; this was a data-intake check only. Inventory and caveats are in next steps.
- 7 tanks are complete and clean (4 saline, 3 glucose). The May 8 RZ10-2 glucose session (COM13/COM12) is missing its raw files: the download is a whole tank holding two 2-min test blocks from 2024-04-30 and, for the 48-h block, only her MATLAB plots (one 0 bytes). Not found anywhere under `BrainFlowZZZ/`. Asked Rebeka.
- Design read from folder names and tank clocks: each fiber is a different mouse (COM# = mouse ID, both PFC), 2 mice per rig, 4 tanks per condition = 8 mice. Unlike the 5-h study, A/C is not PFC/OC. For the May mice, A and C swap between the glucose and saline sessions, so extraction must map mouse to channel by COM per session.
- COM10's glucose fiber A is ~5× dimmer than other channels, but COM10 reads normally on fiber C in its saline session: likely the patch cord/rig, not the mouse.
- Two saline tanks carry "glucose" in their block names. Treated as the study name (as with `GLU` in the 5-h study); folder names and the 2–3-week gaps say saline. Confirming with Rebeka.
- Verification:
  - `.tsq` index vs `.tev` size for all 7 (`outputs/checks/tsq_vs_tev.py`): every index ends 40 bytes before EOF
  - full `TDTbin2mat` read of `465A/405A/465C/405C` (`outputs/checks/check_tank48.m`, debug-partition jobs; logs `outputs/logs/check_tank48_*.log`): sample counts match the index, no NaN/zeros/flat runs, 47.9–48.1 h

## 2026-10-28

### OC = occipital cortex, provisionally (claude-opus-5-5, effort low)

- No file names the OC site (deck says only "PFC and OC"; no coordinates). The user recalls the experimenter saying occipital cortex. Docs and report now say so, marked unconfirmed; question 4 for the experimenter now asks too.
- Why it matters: the report's "brain-wide" reading of the OC replication relies on OC being far from PFC. If OC turned out to be orbitofrontal, that reading would weaken.
- Verification:
  - `~/.local/venvs/treaty/bin/treaty validate .`

### OC fiber added; all 9 sessions read from tanks (claude-opus-5-5, effort low)

- User asked to proceed with steps 3–5 after a commit and push. The 4 recovered sessions now read from their tanks. PFC band power moved < 0.0001 log2, so the report's PFC numbers stand.
- Added OC as a `fiber` option on the existing extraction and a `--fiber` flag on `run_first5h`, rather than a parallel pipeline. OC goes to its own output and results folders, so PFC paths are unchanged.
- OC result, reported as a side check: the same 3 responders (#5, FP1, FP2) drop ÷2–8 in the slow band; #3's brief PFC drop is absent; no saline drop. The OC 405 control falls less after glucose than saline, so the drop isn't carried by 405. Framed in the report as pointing to a brain-wide or state change, which strengthens the sleep caveat.
- Verification:
  - `black -l 110 --check spectra tests`; `python -m pytest -q tests` (7 passed)
  - `sbatch extraction/run_extract_ne_pfc_first5h.sbatch` (job 2236729, 18/18 ok, commit `ee516dd`)
  - old vs new PFC first-5-h traces for the 4 sessions: r = 1.0000
  - `python -m spectra.run_first5h` and `--fiber oc`; inspected OC `band_change.png`, `per_mouse/5_glucose.png`
  - `~/.local/venvs/treaty/bin/treaty validate .`

### 4 recovered `.tev` files verified (claude-opus-5-5, effort low)

- The user pulled the 4 `.tev` files (#1, #3, FP1, FP2). All 4 are complete and clean, so OC raw data now covers all 9 mice.
- Fiber assignment is settled: the old `.mat` arrays are exactly `465A`/`405A` (fiber A = `FibPho1_PFC`), starting 1016 samples in. The PFC results so far used the right fiber.
- Verification:
  - byte sizes vs the expected-size table (all exact)
  - full `TDTbin2mat` read of `465A/405A/465C/405C`, script `outputs/checks/check_tev.m`, log `outputs/logs/check_tev_20261028.log`

### OC coverage: 4 tanks to pull (claude-opus-5-5, effort low)

- The user hadn't been told clearly that OC raw data exists for only 5 of 9 mice. #1, #3, FP1 and FP2 lack their `.tev`; their `StoresListing.txt` shows both fibers were recorded, with fiber A named `FibPho1_PFC`.
- The user will pull the 4 `.tev` files from Rebeka's OneDrive on 2026-10-29. Plan, expected byte sizes and the follow-up steps are in next steps.
- Verification:
  - `.tsq` stream-offset arithmetic, checked against #5's recovered `.tev` (exact match)
  - `~/.local/venvs/treaty/bin/treaty validate .`

### Rebeka's prior findings recorded (claude-opus-5-5, effort low)

- User asked to record the experimenter's findings. Re-read the deck (slides 4–10) instead of relying on the old one-line note. Added "Prior Findings" to `project_overview.md` and a 2-sentence Background to the report's Summary.
- Her result, as plotted: glucose ΔF/F above baseline at 1 h (**) and 2 h (*), n.s. from 3 h; saline n.s. throughout. The old note's "staying up ~3 h" overstated it. Her saline mean trace keeps its dips while the glucose mean is smooth, the time-domain view of our slow-band drop.
- Corrected the user's recollection in chat: the NE level rose after glucose, not saline.
- Literature check for the sleep caveat: Kjaerby 2022 and Osorio-Forero 2021 confirmed (infraslow ~50-s NE oscillation in NREM). Whether our dips occur in sleep is untested: no EEG.
- Fixed a stale `project_overview.md` line that said the spectral analysis wasn't written.
- Verification:
  - deck slide images inspected (image4, 5, 11, 26–34, 44)
  - `~/.local/venvs/treaty/bin/treaty validate .`

### Report proofreading: Summary wording, Figure 2 caption, viridis (claude-opus-5-5, effort low)

- User asked that claims of artifact be stated as suspicion unless known. The Summary now explains "shared" in plain terms (moves in lockstep with 405; coherence = fraction of 465 power predictable from 405) and says "suspect"/"strongly suspect".
- Dropped the measure qualifier from the first Summary finding. Raw 465 gives the same ÷4–9 for #5/FP1/FP2. #3's brief drop is mostly in the not-shared measure (raw ÷1.4), which Results now says.
- Spectrograms use viridis at the user's request (overrides the one-hue ramp default).
- Verification:
  - `black -l 110 --check spectra tests`
  - `python -m spectra.run_first5h`; inspected `full_band/5_glucose.png`
  - `~/.local/venvs/treaty/bin/treaty validate .`
