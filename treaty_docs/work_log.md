# Work Log

Prepend new session notes to the top of this file.

Rotation policy: the live log holds at most the **5 most recent unique calendar dates**. When a new date would push the file past 5 unique dates, move the oldest 5 dates as a chunk into a new file at `work_log_archive/work_log_<earliest>_to_<latest>.md`. The live file always holds at most 5 unique dates; each archive file always holds exactly 5.

If today's date already has a `## YYYY-MM-DD` header at the top, add a new `###` session subsection under it rather than starting a second `## YYYY-MM-DD` header for the same date.

Update this log at the end of any substantive work session unless the user explicitly asks not to document it. **The log records decisions about the project, not the content of the work produced** — the diff already says what changed. See [Work Log Discipline](treaty_conventions.md#work-log-discipline) for what counts as substantive and what to skip.

**Setting this up for the first time?** Leave this file empty. It starts accumulating from the next session. Backfilling it from git history produces exactly the "implemented function X" noise the log exists to avoid.

## 2026-10-20

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
