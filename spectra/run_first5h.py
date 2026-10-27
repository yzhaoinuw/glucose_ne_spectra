"""Spectral comparison, post-injection vs. baseline, on the first 5 h of each session.

Reads the ~20 Hz raw 465/405 traces from the first-5-h extraction (the
MATLAB fit stored there is not used) and writes CSVs and figures.

    python -m spectra.run_first5h [--in-dir ...] [--out-dir ...]
"""

import argparse
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
    return y, x, fs, t_min


def analyse(in_dir):
    edges = log_bins()
    band_rows, bin_rows, fit_rows, per_mouse = [], [], [], {}
    for s in SESSIONS:
        y, x, fs, t_min = load(in_dir / f"{s.folder}.mat")
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
            session=s, f=f, spectra=spectra, wins=wins, t_min=t_min, y=y, x=x, slope=slope
        )
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
    return bands, bins, pd.DataFrame(fit_rows), per_mouse


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--in-dir", type=Path, default=REPO / "outputs" / "ne_pfc_ds20_first5h")
    ap.add_argument("--out-dir", type=Path, default=REPO / "outputs" / "spectra_first5h")
    args = ap.parse_args(argv)
    (args.out_dir / "per_mouse").mkdir(parents=True, exist_ok=True)

    bands, bins, fits, per_mouse = analyse(args.in_dir)
    bands.to_csv(args.out_dir / "band_power.csv", index=False)
    bins.to_csv(args.out_dir / "spectra_logbinned.csv", index=False)
    fits.to_csv(args.out_dir / "baseline_fits.csv", index=False)

    for mouse, d in per_mouse.items():
        plots.per_mouse(d, args.out_dir / "per_mouse" / f"{mouse.lstrip('#')}_{d['session'].group}.png")
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
