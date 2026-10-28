# Work Log

Prepend new session notes to the top of this file.

Rotation policy: the live log holds at most the **5 most recent unique calendar dates**. When a new date would push the file past 5 unique dates, move the oldest 5 dates as a chunk into a new file at `work_log_archive/work_log_<earliest>_to_<latest>.md`. The live file always holds at most 5 unique dates; each archive file always holds exactly 5.

If today's date already has a `## YYYY-MM-DD` header at the top, add a new `###` session subsection under it rather than starting a second `## YYYY-MM-DD` header for the same date.

Update this log at the end of any substantive work session unless the user explicitly asks not to document it. **The log records decisions about the project, not the content of the work produced** — the diff already says what changed. See [Work Log Discipline](treaty_conventions.md#work-log-discipline) for what counts as substantive and what to skip.

## 2026-10-28

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
