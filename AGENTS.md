# Guidelines and Tips for Agents

This file is the first thing any agent (Claude, Codex, or other) should read when joining a session on this repo. It defines the runtime, the common tasks, the conventions, and the project-specific reminders.

**Keep this file lean — aim for under 150 lines.** It is a quick-reference map, not a manual: when a topic needs more than a few tight lines, put the detail in the doc it points to and link there instead of growing this file. Generic treaty mechanics already live in [`treaty_docs/treaty_conventions.md`](treaty_docs/treaty_conventions.md); keep this file for the answers specific to *this* project.

## Startup Rule

At the beginning of a new chat or agent session for this project, read this file first and do not automatically read every markdown file in the repository. Use the [Documentation](#documentation) map below to decide which other files are relevant to the current task.

## Runtime Environment

When running code, tests, or the application for this repository, use:

- **Python analysis env:** not created yet. When the first Python code lands, create a conda env (planned name `glucose_ne_spectra`, Python ≥ 3.10) and record the activation command here. Do not use the cluster's base Python, which is 3.7.
- **Git:** the system git is 1.8. Load a newer one first with `module load git/2.30.1`.
- **Treaty CLI:** installed in its own venv at `~/.local/venvs/treaty/`, run as `~/.local/venvs/treaty/bin/treaty`.
- **MATLAB** (extraction + reference scripts): `module load matlab` loads R2022b, the only enabled version. Don't pipe `module load` (e.g. `| tail`); that runs it in a subshell and `matlab` won't be on `PATH`. MATLAB needs a compute node: quick checks use `srun -p debug -A dkell12_lab -t 00:15:00 --mem=8G bash -lc 'module load matlab; matlab -nodisplay -batch "..."'`.
- **Heavy jobs** (reading the ~3.5 GB TDT tanks, spectral analysis over all recordings) go through SLURM (`sbatch`/`srun`), not the login node.

Typical startup:

```
module load git/2.30.1
# conda activate glucose_ne_spectra   # once the env exists
```

After activation, use that environment for commands such as the verification command below, the app launch, import checks, and one-off scripts.

## Common Tasks

Short recipes for the things you'll usually do in a session.

Re-run the NE extraction for all 8 usable recordings. v2 (~20 Hz, recommended) goes to `outputs/ne_pfc_ds20/`; v1 (full rate) goes to `outputs/ne_pfc_fullrate/`:

```
mkdir -p outputs/logs
sbatch extraction/run_extract_ne_pfc_ds.sbatch   # v2
sbatch extraction/run_extract_ne_pfc.sbatch      # v1
```

Commit before an extraction run: the outputs record `git rev-parse HEAD`.

SLURM here does not expand `%x` in `--output`. Name log files literally. If a job shows `launch_failed_requeued_held` in `squeue`, it never started: `scancel` it and resubmit, or run on `-p debug` with `srun` (≤ 1 h; both extractions fit).

Verify the repo is in good shape — the CI-equivalent check:

```
~/.local/venvs/treaty/bin/treaty validate .
```

Run the fuller / slower checks, if this repo has a longer pass:

```
# None yet. Add `pytest` here once Python code and tests exist.
```

Pre-flight checklist before committing:

- Formatter / linter is clean (matches the CI format job): none configured yet. Use `black` once Python code exists.
- Verification is green (matches the CI check job): `~/.local/venvs/treaty/bin/treaty validate .`
- `git status` shows no data files staged. Raw recordings and `.mat`/`.npy` outputs must stay out of git (see `.gitignore`).
- A new `treaty_docs/work_log.md` entry records the decisions made and the verification commands actually run — see [When To Update Treaty Docs](#when-to-update-treaty-docs).

If the change touches active modules, confirm imports still work. There are no smoke tests yet; add them with the first Python module.

## When To Update Treaty Docs

At the end of any substantive work session, prepend an entry to `treaty_docs/work_log.md` and bring `treaty_docs/next_steps.md` in line with it — unless the user asks you not to document it, says it is off the book, or the exchange was clearly trivial.

The rule that decides what goes in: **the work log records decisions about the project, not the content of the work produced.** The work itself is already in version control; the reasoning behind it is not. See [Work Log Discipline](treaty_docs/treaty_conventions.md#work-log-discipline) for what counts as substantive, what to skip, and how an entry is structured.

## Branch Handoff Discipline

Before switching away from an experimental or feature branch, fully resolve the work on that branch: confirm it holds all intended changes, that they are committed, and whether the user expects them merged, pushed, or intentionally parked.

Do not switch to the integration branch (`main`) or start new work elsewhere while important experimental-branch changes are only local, unmerged, or unverified. Pre-switch checks and the recovery procedure: [Branch Handoff](treaty_docs/treaty_conventions.md#branch-handoff).

## Updating The Treaty

Pulling upstream treaty refinements into this project is a maintainer's call — only do it when asked, and note it is distinct from updating `treaty_docs/work_log.md` / `treaty_docs/next_steps.md` content (above).

`treaty diff` shows this project's section-level drift from the template version it is pinned to; `treaty update --dry-run` previews the merge; `treaty update` applies it as a three-way merge and can leave conflict markers to resolve. Procedure: [Updating The Treaty](treaty_docs/treaty_conventions.md#updating-the-treaty).

## Documentation

Read these documents only as needed. The map below names each file and when it's worth opening.

- `treaty_docs/treaty_conventions.md` — the generic treaty mechanics: work-log criteria and structure, dated-entry and rotation rules, branch handoff, and how `treaty update` behaves. Maintained upstream — prefer not to edit it.
- `treaty_docs/work_log.md` and `treaty_docs/work_log_archive/` — recent implementation history, decisions, experiment outcomes, and verification breadcrumbs. Default to reading the two most recent dated entries; find anchors with `rg -n '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' treaty_docs/work_log.md`.
- `treaty_docs/next_steps.md` — unfinished work from previous sessions. The "Currently Hot" pointer at the top names the active threads; read it first.
- `project_overview.md` — codebase structure, for onboarding or when a task touches an unfamiliar area. "What Looks Active vs. Legacy" and "Authored vs. Derived" are the two maps to check before editing anything.
- `README.md` — user-facing setup, packaging, usage, and input-file expectations.
- `CONTRIBUTING.md` (if present) — collaboration workflow, branch/test expectations, documentation conventions.

The same anchor-grep pattern works for any structured Markdown doc in the repo — `grep -n '^## ' <file>` for the section map, then a targeted slice read rather than loading the whole file.

## Commit Message Guidelines

- A short title line.
- A short body with flat bullet points when a commit bundles several user-requested changes.
- Bullets describe high-level added or changed behavior, not implementation details. For feature commits, mention only the user-facing behavior.
- Do not mention tests, docs, project memory updates, or behind-the-scenes implementation in a feature commit message unless that internal work is itself the commit's main purpose.

## Git Ownership Note

If Git reports a "detected dubious ownership" warning for this repo, mark the repository as safe rather than changing OS-level ownership:

```
git config --global --add safe.directory <absolute path to this repo>
```

Use forward slashes on Windows (`C:/path/to/repo`); quote the path on macOS / Linux (`"$HOME/path/to/repo"`).

## Project-Specific Reminders

Add domain-specific gotchas here. These are the things that aren't obvious from reading the code and that an agent would otherwise have to learn the hard way. This section, plus Runtime Environment and Common Tasks above, is where your project's own conventions belong — adding sections here always merges cleanly on `treaty update`.

- **The data folders are shared lab data, owned by a labmate (`mgianne3`).** Never modify, move or delete anything inside the `FiberPhot*/`, `FP[0-9]*/` or `Subject*/` folders. Write derived outputs to `outputs/`, which is gitignored.
- **Never commit data.** The repo root is the data directory, about 20 GB in total. `.gitignore` blocks the recording folders and data extensions (`.tev`, `.mat`, `.avi`, `.npy`…); keep it that way.
- **`matlab_scripts/` is reference only.** It records the lab's original pipeline. Port its logic to Python; don't patch it unless asked. It has known bugs, listed in `project_overview.md`. Check that list before trusting any number it produced.
- **Scientific goal:** spectral analysis. Look for changes in NE oscillation frequency and power across the spectrum after an IP glucose dose, compared with saline and baseline. The old dip-counting analysis is background, not the target.
- **Channels:** `465A`/`405A` = fiber 1 (PFC); `465C`/`405C` = fiber 2 ("OC"). 465 nm is GRAB-NE (`hSyn-NE2m`); 405 nm is the isosbestic control. The sampling rate is about 1017.3 Hz. Read it from each recording; never hardcode it.
- **Downsampling limits the spectrum.** The legacy ×100 downsampling (to about 10 Hz) caps usable frequencies at about 5 Hz, and the 1000-sample moving-average smoothing strongly attenuates everything above about 0.5 Hz (its first null is near 1 Hz). Choose resolution and smoothing with the spectral question in mind.
- **Only some recordings have raw data.** See the data table in `README.md` before promising coverage for any mouse.
