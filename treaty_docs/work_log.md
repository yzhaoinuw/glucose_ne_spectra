# Work Log

Prepend new session notes to the top of this file.

Rotation policy: the live log holds at most the **5 most recent unique calendar dates**. When a new date would push the file past 5 unique dates, move the oldest 5 dates as a chunk into a new file at `work_log_archive/work_log_<earliest>_to_<latest>.md`. The live file always holds at most 5 unique dates; each archive file always holds exactly 5.

If today's date already has a `## YYYY-MM-DD` header at the top, add a new `###` session subsection under it rather than starting a second `## YYYY-MM-DD` header for the same date.

Update this log at the end of any substantive work session unless the user explicitly asks not to document it. **The log records decisions about the project, not the content of the work produced** — the diff already says what changed. See [Work Log Discipline](treaty_conventions.md#work-log-discipline) for what counts as substantive and what to skip.

**Setting this up for the first time?** Leave this file empty. It starts accumulating from the next session. Backfilling it from git history produces exactly the "implemented function X" noise the log exists to avoid.

## 2026-10-23

### Recovering the missing .tev/.tsq files from the CTN drive (claude-opus-5-5)

- The 7 sessions without raw signal may exist in Rebeka's folder on the CTN J: drive (`J:\CTN\NedergaardLAB\Personal_folders\Rebeka\Glucose`). A labmate there (BlueHive user `vuntiet2`, in `dkell12_lab`) will run `transfer/fetch_missing_tev.sh` from Windows (Git Bash or WSL). Scope: the missing files only (7 `.tev`, 3 `.tsq`). The full tanks for FP1/FP2 and the Subject1/3 mornings are deferred.
- Files land in `recovered_raw/<session>/` (gitignored), not in the recording folders, which belong to `mgianne3`. Merging them in is the owner's call. The TDT reader will need these files next to the rest of each tank (e.g. symlinks under `outputs/`).
- Safe to re-run: each file goes over as `.part` and is renamed only after its SHA-256 matches the source, so a file with its final name is complete and gets skipped. scp can't resume partway through a file, so an interrupted file starts over.
- Source files are matched by recording stamp. One counts as the right recording only if the `.Tdx` next to it matches BlueHive's copy, so an unrelated file with the same stamp isn't picked up.
- Verification:
  - Local end-to-end test with stand-in ssh/scp: dry run, one forced interrupted copy that was retried, re-run skipping everything, `sha256sum -c` and `cmp` against the source.
  - `~/.local/venvs/treaty/bin/treaty validate .`

## 2026-10-21

### Experimenter's summary deck: design answers (claude-opus-5-5)

- Read `Summary_glucose_data_files.pptx` (E. Rebeka Kovács). Most content is figures; read via extracted slide images (no `markitdown`/`pdftoppm` on the cluster).
- Key correction: morning + evening sessions are **one experiment per mouse** (injection at 10:00, break 14–17, end 22:00), not two treatments. The `_sal_evening` variable names in the dip scripts mean the saline group's evening session, not "evening = saline". Treatment is now per mouse; the session table marks evenings "same as morning".
- Consequence: our 8 usable sessions are at most 6 mice, while her figures use 5 glucose + 3 saline. Per-mouse group assignment and exact injection times are only in her paper lab journal; added as new questions A1–A3.
- Her glucose group is near baseline at 9–12 h, loosely supporting v2's end-of-session fit assumption; not treated as confirmation, since 1 of 5 mice stays elevated.
- Logged a 48-h glucose/saline study with EEG/EMG (16 mice) on the J: drive as a candidate dataset; not requested yet.
- Gitignored `*.ppt`/`*.pptx`: lab presentations stay local, like the data.
- Verification:
  - `~/.local/venvs/treaty/bin/treaty validate .`

## 2026-10-20

### Glucose/saline mapping + questions for the experimenters (claude-opus-5-5)

- Treatment labels aren't in the recordings (`.tnt` notes empty, no TTL store). Confirmed glucose only from names: FP1/FP2 13-h, Subject1 and Subject3 morning (`5H_GLU_*`). FiberPhot4/22 morning are glucose only by the legacy morning script. The evening sessions are unlabeled. The `_sal_evening` variable names in the dip scripts hint at saline, but there's no mapping. Decided not to infer treatment from the traces, since that would bias the comparison.
- Found mouse-ID conflicts between folder and block names (`FiberPhot22_240324_morning` holds block `FiberPhot2_240324`; `Subject3-..._morning` holds `Subject1-240322-092543`). Added these to the questions.
- Wrote `questions_for_experimenters.md`: 16 prioritized questions (treatment/dose/design/injection times first, then mouse IDs, fibers, missing files, light cycle, sleep/EEG, acquisition settings, expectations) and a per-session fill-in table. The spectral analysis's treatment comparison waits on the answers.
- Verification:
  - `~/.local/venvs/treaty/bin/treaty validate .`

### v2 extraction: ~20 Hz + robust, segment-anchored fit (claude-opus-5-5)

- On request, made a second round of extraction with downsampling and a more robust fit. Downsampled ×50 (~20.35 Hz) with `resample` (anti-aliased). The Nyquist stays above the ~6 Hz roll-off, so nothing recorded is lost.
- **Tried and rejected: per-channel double-exponential bleaching fits + robust motion regression** (the pyPhotometry-style approach). On FP2 it made the baseline worse (−19.5% vs. v1's −12.7%): a monotonic bleach fit to 465 can't tell the hours-long post-glucose NE rise from bleaching, and robust weights don't help when the "outlier" lasts 4 h. On FiberPhot22 the motion slope came out at 2.8, which raised the ΔF/F noise floor ~10× above 0.3 Hz and shrank the 80–95 min NE dip. Not committed.
- **Adopted:** keep the legacy linear 405→465 mapping and the 1-s control smoothing, but fit robustly (bisquare `robustfit`). For sessions ≥ 10 h, fit only on baseline (< 50 min) + last 60 min, following the lab's earlier `BL+end_fitting` outputs. A prototype over all 8 showed a robust *whole-recording* fit barely differs from v1, so the fit window is what matters. 5-h sessions keep the whole-recording fit, because their end (~4 h post-injection) can't be assumed NE-neutral.
- Result: 13-h baselines go from −7.9 / −12.7% to −0.4 / +0.1%, and the 2–4 h post-injection level reads +11.5% (FP1) / +20.9% (FP2). Fit slopes fall from 1.47 / 2.43 to 0.76 / 1.39. The 5-h sessions change by ≤ 1.2 points. v2 and v1 PSDs are nearly identical, so the oscillation content isn't distorted.
- Refactored the loading/trim into `load_pfc_raw.m` + `pfc_recordings.m`, shared by v1 and v2. The refactored v1 reproduces the committed v1 output bit-for-bit (Subject1: `isequal` on dff, 465, t0, coefs).
- Softened the docs' "TDT cuts at 6 Hz" to an inference (a consistent roll-off in all recordings, matching Synapse's usual default). The filter setting itself hasn't been checked.
- The v2 run's `.mat` files record `git_commit = 8f11129`, the commit before the v2 code. The code that produced them is the next commit. AGENTS now says to commit before extraction runs.
- Verification:
  - Debug-node tests on FP2 + FiberPhot22 morning; QC figures inspected.
  - Full run: batch job 31468108 sat in `launch_failed_requeued_held` (a node failure on bhc0005; it never started) and was cancelled. Re-run with `srun -p debug ... extract_ne_pfc_ds`: all 8 ok, no warnings, 52 MB. Log in `outputs/logs/extract_ne_pfc_ds_debug.log`.
  - `~/.local/venvs/treaty/bin/treaty validate .`

### Full-rate PFC NE extraction (claude-opus-5-5)

- User decisions: PFC only; keep the original ~1017 Hz rate for spectral work; fit over the whole recording; use `TDTbin2mat` from the user's `preprocess_sleep_data` repo. It's vendored in `extraction/tdt/` together with `SEV2mat.m`, which `TDTbin2mat` calls unconditionally.
- Extraction stays in MATLAB (not Python) because the user supplied the MATLAB TDT reader and the legacy normalization is MATLAB. Python takes over at the analysis step.
- Kept the legacy normalization (linear 405→465 fit, fitted control smoothed with a 1000-sample `filtfilt` moving average) but dropped the legacy smoothing and ×100 downsampling of ΔF/F. Those act as a ~0.5 Hz low-pass. Raw 465/405 are saved alongside, so the user can re-normalize or use 405 as a spectral control.
- Found that the pre-extracted `*_signal_{465,405}.mat` arrays are exactly `round(fs)` = 1017 samples shorter than their `.tsq` index: the legacy 1-s trim was already applied. The script treats a shortfall as already trimmed, so all recordings start ~1 s in and none are trimmed twice. Those arrays have no `fs`; it's read from the `.tsq` with `TDTbin2mat(...,'HEADERS',1)`, which doesn't need the `.tev`.
- There is no TTL store in these tanks. The legacy "first TTL" cut was a stub, and as written (`signal(1017.25:end)`) it would have errored. It's now an explicit 1-s trim.
- Spectral finding from the QC PSDs: a hardware roll-off at about 6 Hz, and the ΔF/F PSD equals the 405 PSD above about 1–2 Hz. NE-specific content is below about 1 Hz. Recorded in `next_steps.md` as a constraint for the spectral analysis.
- Output saved as MATLAB v7 (not v7.3) so `scipy.io.loadmat` reads it directly; every variable is well under v7's 2 GB limit.
- Verification:
  - `srun -p debug ... extract_ne_pfc([], <scratch>, {'Subject1-240323-091543_morning','FiberPhot22_240324_morning'})`: both ok, ~50 s each, 2.9 GB peak RSS. The FiberPhot22 ΔF/F visually matches the legacy `raw+normalized_PFC_mouse22_morning.jpg`.
  - Full run: `sbatch extraction/run_extract_ne_pfc.sbatch` (job 31468026). COMPLETED in 8 min 21 s, all 8 ok and no warnings; 1.8 GB written. All 4 `.mat` sources showed `n_missing_vs_tsq = 1017`, all 4 tanks 0.
  - QC: the 13-h FP1/FP2 whole-recording fits leave the baseline hour offset at about −8% / −13% ΔF/F (405 and 465 bleach at different rates). The legacy outputs for these were named `BL+end_fitting`, which suggests a segment fit was used before. Flagged in `next_steps.md`; not changed, since the user chose the whole-recording default.
  - `~/.local/venvs/treaty/bin/treaty validate .`

### Repo setup: glucose_ne_spectra + treaty adoption (claude-opus-5-5)

- Made the existing data directory the repo root instead of moving the 20 GB of data into a `data/` subfolder. The recordings are a labmate's shared folders, and other people may reference those paths. `.gitignore` excludes them by folder pattern (`FiberPhot*/`, `FP[0-9]*/`, `Subject*/`) and by data extension.
- Moved the 13 MATLAB scripts into `matlab_scripts/` as reference only. The new analysis will be Python. The scripts' known bugs are catalogued in `project_overview.md`, so the port doesn't inherit them.
- Named the repo `glucose_ne_spectra`: descriptive over catchy, since it's an internal academic analysis repo, not a tool. The user rejected `sugar_rhythms` as too cute. It's snake_case to match the user's other repos.
- Data audit, carried over from the earlier session the same day: only 8 of 15 recordings have usable raw signal. 7 are missing the `.tev` file, including Subject5, which the legacy morning analysis used. Recorded in `README.md`.
- Spectral caveat noted for later: the legacy ×100 downsampling and 1000-sample smoothing effectively low-pass the trace to below about 0.5–1 Hz. This matters for the project's frequency-shift goal and is raised as an open question for extraction.
- Tooling: the cluster's default git (1.8) and Python (3.7) are too old for copier/treaty. Use `module load git/2.30.1`; the treaty CLI is in `~/.local/venvs/treaty/` (Python 3.12). No `gh` CLI or token exists, so the user must create the GitHub repo by hand; SSH push works.
- Verification:
  - `~/.local/venvs/treaty/bin/treaty validate .`
  - `git status --ignored` confirmed no recording folders or data files are tracked.

<!--
Each session entry follows this shape:

## YYYY-MM-DD

### Short title for what was done (model + version, effort/thinking mode, token budget if known)

- bullet describing what was added or changed
- another bullet — keep them high-level and user/agent-facing, not implementation play-by-play
- if relevant, intended profiling signal or measurement:
  - what to look for in logs / output
  - what numbers were observed
- Verification:
  - the exact command(s) that were actually run
  - what passed / what was confirmed

Model / effort / token info goes in the parentheses after the `###` title when available from the system. Use whatever the model or interface actually reports — do not estimate or hallucinate. Omit any field that the interface does not surface.

- **Model**: the version string the interface reports (e.g. `grok-4.3`, `gpt-4o`, `claude-opus-4-7`).
- **Effort / thinking mode**: the effort knob the interface reports (e.g. `high`, `low`, `extended thinking`). Omit if no such knob exists or its setting is not surfaced.
- **Token budget**: **output tokens for the session** (output + thinking/reasoning tokens for models that report them separately, e.g. Claude with extended thinking). This is the cleanest cross-agent proxy for "amount produced." Omit if the interface does not surface a count.

Purely human-driven work can use `(human)`. Mixed human + agent sessions can combine them, e.g. `(human + grok-4.3, high)`.

Keep the parenthetical compact. Examples:
- `(grok-4.3, high, ~18k out)`
- `(gpt-4o, high, ~22k out)`
- `(claude-opus-4-7, extended thinking, ~30k out)`
- `(grok-4.3, low)`

Newest entry goes on top. If the session did multiple distinct pieces of work, use multiple `###` subsections under one `##` date header.
-->
