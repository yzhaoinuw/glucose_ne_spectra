"""Spectral comparison, post-injection vs. baseline, on the first 5 h of each session.

Reads the ~20 Hz raw 465/405 traces from the first-5-h extraction (the
MATLAB fit stored there is not used) and writes CSVs and figures to
results/spectra_first5h/ (tracked in git), with the code commit in
provenance.txt.

    python -m spectra.run_first5h [--in-dir ...] [--out-dir ...]
"""

import argparse
import subprocess
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
import scipy.io

from . import core, plots
from .sessions import SESSIONS, windows

REPO = Path(__file__).resolve().parents[1]
MEASURES = ["465", "405", "465_indep_405", "dff_baseline_fit"]  # power measures
F_MIN, F_MAX, BINS_PER_DECADE = 0.01, 2.0, 16


def log_bins():
    n = int(np.ceil(np.log10(F_MAX / F_MIN) * BINS_PER_DECADE))
    return np.logspace(np.log10(F_MIN), np.log10(F_MAX), n + 1)


def bin_spectrum(f, p, edges):
    """Mean f and p within each log-spaced bin. At the low end the bins are
    narrower than the Welch resolution, so empty bins are dropped."""
    idx = np.digitize(f, edges) - 1
    keep = [i for i in range(len(edges) - 1) if np.any(idx == i)]
    return [(f[idx == i].mean(), p[idx == i].mean()) for i in keep]


def load(path):
    m = scipy.io.loadmat(path, squeeze_me=True)
    y = np.asarray(m["signal_465"], dtype=float)
    x = np.asarray(m["signal_405"], dtype=float)
    fs = float(m["fs"])
    t_min = (float(m["t0_s"]) + np.arange(y.size) / fs) / 60.0
    whole_slope = float(np.atleast_1d(m["fit_coef"])[0])  # the extraction's whole-5-h 405 fit
    return y, x, fs, t_min, whole_slope


def full_band(y, x, fs, t_min):
    """Whole-recording spectrograms of 465 and 405 and their sliding coherence,
    log-binned in frequency up to Nyquist (~10 Hz), for the full-band figures."""
    f, t, s465 = core.spectrogram(y, fs)
    _, _, s405 = core.spectrogram(x, fs)
    fc, tc, coh = core.sliding_coherence(y, x, fs)
    edges = core.log_bin_edges(f[1] - f[0], f[-1], per_decade=24)
    t0 = t_min[0]  # spectrogram times are from the first sample
    return dict(
        edges=edges,
        t_min=t0 + t / 60.0,
        s465=core.log_bin_rows(f, s465, edges),
        s405=core.log_bin_rows(f, s405, edges),
        tc_min=t0 + tc / 60.0,
        coh=core.log_bin_rows(fc, coh, edges),
    )


def analyse(in_dir):
    edges = log_bins()
    band_rows, bin_rows, fit_rows, full_rows, per_mouse = [], [], [], [], {}
    for s in SESSIONS:
        y, x, fs, t_min, whole_slope = load(in_dir / f"{s.folder}.mat")
        wins = windows(s, t_min[-1])
        base = (t_min >= wins[0][1]) & (t_min < wins[0][2])
        dff, slope, intercept = core.baseline_fit_dff(y, x, fs, base)
        fit_rows.append(
            dict(mouse=s.mouse, group=s.group, baseline_fit_slope=slope, baseline_fit_intercept=intercept)
        )
        spectra = {}
        for label, a, b in wins:
            m = (t_min >= a) & (t_min < b)
            f, sp = core.window_spectra(y[m], x[m], dff[m], fs)
            spectra[label] = sp
            common = dict(mouse=s.mouse, group=s.group, window=label, start_min=a, stop_min=b)
            for meas, p in sp.items():
                for lo, hi in core.BANDS:
                    band = f"{lo:g}-{hi:g} Hz"
                    if meas == "coherence":
                        mask = (f >= lo) & (f < hi)
                        val = float(np.mean(p[mask]))
                    else:
                        val = float(core.band_power(f, p, lo, hi))
                    band_rows.append(dict(common, measure=meas, band=band, value=val))
                for fc, v in bin_spectrum(f, p, edges):
                    bin_rows.append(dict(common, measure=meas, f_hz=fc, value=v))
        per_mouse[s.mouse] = dict(
            session=s,
            f=f,
            spectra=spectra,
            wins=wins,
            t_min=t_min,
            y=y,
            x=x,
            slope=slope,
            whole_slope=whole_slope,
            full_band=full_band(y, x, fs, t_min),
        )
        base_sp = spectra["baseline"]
        full_edges = core.log_bin_edges(f[1] - f[0], f[-1], per_decade=BINS_PER_DECADE)
        for meas in ["465", "405", "465_indep_405", "coherence"]:
            vals = core.log_bin_rows(f, base_sp[meas], full_edges)
            fc = core.log_bin_rows(f, f, full_edges)
            for c, v in zip(fc, vals):
                full_rows.append(dict(mouse=s.mouse, group=s.group, measure=meas, f_hz=c, value=v))
        print(
            f"{s.mouse:>4} {s.group:<7} baseline fit slope {slope:5.2f}; windows: "
            + ", ".join(w[0] for w in wins)
        )

    bands = pd.DataFrame(band_rows)
    bins = pd.DataFrame(bin_rows)
    for df in (bands, bins):
        keys = ["mouse", "measure"] + (["band"] if "band" in df else ["f_hz"])
        base = df[df.window == "baseline"].set_index(keys)["value"]
        ref = df.set_index(keys).index.map(base)
        is_coh = df.measure == "coherence"
        # power: log2 ratio to baseline; coherence: difference from baseline
        df["change_vs_baseline"] = np.where(is_coh, df.value - ref, np.log2(df.value / ref))
    return bands, bins, pd.DataFrame(fit_rows), pd.DataFrame(full_rows), per_mouse


def git_state():
    """Short HEAD hash, with "-dirty" if spectra/ has uncommitted changes."""
    run = lambda *a: subprocess.run(["git", *a], cwd=REPO, capture_output=True, text=True)
    try:
        head = run("rev-parse", "--short", "HEAD")
    except FileNotFoundError:
        return "unknown (git not available)"
    if head.returncode != 0:
        return "unknown (git not available)"
    dirty = run("status", "--porcelain", "--", "spectra").stdout.strip()
    return head.stdout.strip() + ("-dirty" if dirty else "")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--in-dir", type=Path, default=REPO / "outputs" / "ne_pfc_ds20_first5h")
    ap.add_argument("--out-dir", type=Path, default=REPO / "results" / "spectra_first5h")
    args = ap.parse_args(argv)
    for sub in ("per_mouse", "full_band"):
        (args.out_dir / sub).mkdir(parents=True, exist_ok=True)

    bands, bins, fits, full, per_mouse = analyse(args.in_dir)
    (args.out_dir / "provenance.txt").write_text(
        f"code commit: {git_state()}\ncreated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"input: {args.in_dir.relative_to(REPO) if args.in_dir.is_relative_to(REPO) else args.in_dir}\n"
        "script: python -m spectra.run_first5h\n"
    )
    bands.to_csv(args.out_dir / "band_power.csv", index=False)
    bins.to_csv(args.out_dir / "spectra_logbinned.csv", index=False)
    fits.to_csv(args.out_dir / "baseline_fits.csv", index=False)
    full.to_csv(args.out_dir / "full_band_baseline.csv", index=False)

    for mouse, d in per_mouse.items():
        name = f"{mouse.lstrip('#')}_{d['session'].group}.png"
        plots.per_mouse(d, args.out_dir / "per_mouse" / name)
        plots.full_band(d, args.out_dir / "full_band" / name)
    plots.full_band_summary(full, args.out_dir / "full_band_baseline.png")
    plots.raw_traces(per_mouse, args.out_dir / "raw_traces.png")
    plots.spectral_change(bins, MEASURES, args.out_dir / "spectral_change.png")
    plots.band_change(bands, MEASURES, args.out_dir / "band_change.png")
    plots.coherence_summary(bins, args.out_dir / "coherence.png")

    post = bands[(bands.window != "baseline") & bands.measure.isin(MEASURES)]
    table = (
        post.groupby(["measure", "band", "window", "group"], sort=False)["change_vs_baseline"]
        .mean()
        .unstack("group")
    )
    print("\nMean log2 change vs. baseline (glucose, saline):")
    print(table.round(2).to_string())
    print(f"\nWrote {args.out_dir}")


if __name__ == "__main__":
    main()
