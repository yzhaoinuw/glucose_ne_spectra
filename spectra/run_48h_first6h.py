"""Spectral comparison for the 48-h study, first ~6 h: post-injection vs. baseline,
and glucose vs. saline within mouse (crossover).

Same method as the 5-h study (run_first5h.analyse), on the ~20 Hz raw 465/405
traces of the 48-h extraction (outputs/ne_48h_ds20/), cropped to 4 h after the
injection. Windows in sessions48. Writes CSVs and figures to
results/spectra_48h_first6h/, with the code commit in provenance.txt.

    python -m spectra.run_48h_first6h [--in-dir ...] [--out-dir ...]
"""

import argparse
from datetime import datetime
from pathlib import Path

import pandas as pd

from . import plots
from .run_first5h import MEASURES, REPO, analyse, git_state
from .sessions48 import LAST_BLOCK_END_MIN, load_sessions, windows48

PAIRED_MEASURES = ["465", "465_indep_405"]


def paired_difference(bands, sessions):
    """Per mouse with both sessions: glucose change minus saline change, per measure, band and block."""
    animal = {s.mouse: s.animal for s in sessions}
    post = bands[(bands.window != "baseline") & (bands.measure != "coherence")].copy()
    post["animal"] = post.mouse.map(animal)
    wide = post.pivot_table(
        index=["animal", "measure", "band", "window"],
        columns="group",
        values="change_vs_baseline",
        sort=False,
    ).dropna()
    wide["glucose_minus_saline"] = wide.glucose - wide.saline
    return wide.reset_index()


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--in-dir", type=Path, default=REPO / "outputs" / "ne_48h_ds20")
    ap.add_argument("--out-dir", type=Path, default=REPO / "results" / "spectra_48h_first6h")
    args = ap.parse_args(argv)
    plots.FIBER_LABEL = "48-h study, first 6 h (PFC)"
    for sub in ("per_mouse", "full_band"):
        (args.out_dir / sub).mkdir(parents=True, exist_ok=True)

    sessions = load_sessions(args.in_dir)
    for s in sessions:
        if s.baseline_end_min is not None:
            print(
                f"{s.mouse}: baseline ends at {s.baseline_end_min:.1f} min (injection {s.injection_min:.1f})"
            )
    bands, bins, fits, full, per_mouse = analyse(
        args.in_dir, sessions, windows48, crop_min=lambda s: s.injection_min + LAST_BLOCK_END_MIN + 1
    )
    diff = paired_difference(bands, sessions)
    for df in (bands, bins, fits, full):
        df.insert(1, "animal", df.mouse.map({s.mouse: s.animal for s in sessions}))

    (args.out_dir / "provenance.txt").write_text(
        f"code commit: {git_state()}\ncreated: {datetime.now():%Y-%m-%d %H:%M:%S}\nfiber: pfc (A or C per mouse)\n"
        f"input: {args.in_dir.relative_to(REPO) if args.in_dir.is_relative_to(REPO) else args.in_dir}\n"
        f"script: python -m spectra.run_48h_first6h\n"
    )
    bands.to_csv(args.out_dir / "band_power.csv", index=False)
    bins.to_csv(args.out_dir / "spectra_logbinned.csv", index=False)
    fits.to_csv(args.out_dir / "baseline_fits.csv", index=False)
    full.to_csv(args.out_dir / "full_band_baseline.csv", index=False)
    diff.to_csv(args.out_dir / "paired_difference.csv", index=False)

    for d in per_mouse.values():
        name = f"{d['session'].folder}.png"
        plots.per_mouse(d, args.out_dir / "per_mouse" / name)
        plots.full_band(d, args.out_dir / "full_band" / name)
    plots.full_band_summary(full, args.out_dir / "full_band_baseline.png")
    plots.raw_traces(
        per_mouse, args.out_dir / "raw_traces.png", span="first ~6 h", fit_label="48-h extraction"
    )
    plots.spectral_change(bins, MEASURES, args.out_dir / "spectral_change.png")
    plots.band_change(bands, MEASURES, args.out_dir / "band_change.png")
    plots.coherence_summary(bins, args.out_dir / "coherence.png")
    plots.paired_difference(diff, PAIRED_MEASURES, args.out_dir / "paired_difference.png")

    post = bands[(bands.window != "baseline") & bands.measure.isin(MEASURES)]
    table = (
        post.groupby(["measure", "band", "window", "group"], sort=False)["change_vs_baseline"]
        .mean()
        .unstack("group")
    )
    print("\nMean log2 change vs. baseline (glucose, saline):")
    print(table.round(2).to_string())
    paired = diff[diff.measure.isin(PAIRED_MEASURES)].groupby(["measure", "band", "window"], sort=False)
    summary = paired.glucose_minus_saline.agg(
        mean="mean", n_mice="size", n_below_0=lambda v: int((v < 0).sum())
    )
    print("\nWithin mouse, glucose minus saline (log2):")
    print(summary.round(2).to_string())
    print(f"\nWrote {args.out_dir}")


if __name__ == "__main__":
    main()
