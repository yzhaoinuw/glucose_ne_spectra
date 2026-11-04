"""Step-by-step walk through the fast-band 405 -> 465 fit for one mouse (see spectra/README.md).

Prints the intermediate values of each step of run_first5h_fit's fit, plus the scalings that
ordinary least squares would give, and draws the fast-band fit to
results/spectra_first5h_fit[_oc]/fit_walkthrough_<mouse>.png.

    python -m spectra.fit_walkthrough [--mouse "#5"] [--fiber pfc|oc]
"""

import argparse

import numpy as np
from scipy import signal

from . import core
from .plots import GROUP_COLOR, INK2, MUTED, plt
from .run_first5h import REPO, load
from .run_first5h_fit import FIBERS, PANEL_G, level_pct
from .sessions import SESSIONS, windows


def pct_slope(x405, y465):
    """Ordinary least-squares slope of 465 on 405, both as fractions of their own mean."""
    return float(np.polyfit(x405 / x405.mean() - 1, y465 / y465.mean() - 1, 1)[0])


def walk(mouse, fiber):
    s = next(s for s in SESSIONS if s.mouse == mouse)
    in_name, out_name = FIBERS[fiber]
    y, x, fs, t, whole_slope = load(REPO / "outputs" / in_name / f"{s.folder}.mat")
    print(f"Step 0, load: {y.size} samples at {fs:.3f} Hz, {t[0]:.2f}-{t[-1]:.1f} min")
    print(f"  injection at {s.injection_min} min")

    wins = windows(s, t[-1])
    base = (t >= wins[0][1]) & (t < wins[0][2])
    y0, x0 = y[base].mean(), x[base].mean()
    print(f"Step 1, windows: baseline {wins[0][1]:.1f}-{wins[0][2]:.1f} min")
    print(f"  baseline means: 465 = {y0:.1f}, 405 = {x0:.1f} (raw TDT units)")

    # Steps 2-4 repeat core.fast_band_gain line by line, to show the intermediate values.
    yn, xn = y[base] / y0, x[base] / x0
    lo, hi = core.FAST_BAND
    sos = signal.butter(4, [lo, hi], btype="band", fs=fs, output="sos")
    yy, xx = signal.sosfiltfilt(sos, yn), signal.sosfiltfilt(sos, xn)
    gain = float(np.dot(xx, yy) / np.dot(xx, xx))
    assert np.isclose(gain, core.fast_band_gain(y[base], x[base], fs))
    print(f"Step 2, each channel / its mean: sd 465 {yn.std() * 100:.2f}%, 405 {xn.std() * 100:.2f}%")
    print(
        f"Step 3, band-pass {lo:g}-{hi:g} Hz: sd 465 {yy.std() * 100:.3f}%, 405 {xx.std() * 100:.3f}%, "
        f"correlation {np.corrcoef(xx, yy)[0, 1]:.2f}"
    )
    print(f"Step 4, slope through zero = scaling = {gain:.3f}")
    print(
        f"  for contrast, least squares without the band-pass: baseline {pct_slope(x[base], y[base]):.2f}, "
        f"whole 5 h {pct_slope(x, y):.2f}; the extraction's robust whole-5-h fit "
        f"{whole_slope * x0 / y0:.2f} (% units)"
    )

    ctrl = core.scaled_control(y, x, base, gain)
    print(f"Step 5, control = {y0:.1f} * (1 + {gain:.3f} * (405 / {x0:.1f} - 1))")
    print(f"  as a raw line: a = {gain * y0 / x0:.3f}, b = {y0 * (1 - gain):.1f}")

    dff, _ = core.fast_band_fit_dff(y, x, fs, base)
    print(f"Step 6, dF/F: baseline mean {dff[base].mean():+.2f}%")

    tt = t - s.injection_min
    post = (tt >= PANEL_G[0]) & (tt < PANEL_G[1])
    print(
        f"Step 7, level +{PANEL_G[0]:g}-{PANEL_G[1]:g} min: raw 405 {100 * (x[post].mean() / x0 - 1):+.1f}%, "
        f"control {100 * (ctrl[post].mean() / y0 - 1):+.1f}%, raw 465 {100 * (y[post].mean() / y0 - 1):+.1f}%, "
        f"fitted {level_pct(y, ctrl, post, base):+.1f}%"
    )

    path = REPO / "results" / out_name / f"fit_walkthrough_{mouse.lstrip('#')}.png"
    fig_fast_band(xx, yy, gain, fs, s, path)
    print(f"Figure: {path.relative_to(REPO)}")


def fig_fast_band(xx, yy, gain, fs, s, path):
    """Left: one minute of the band-passed baseline. Right: 465 vs. 405 with the fitted slope."""
    c = GROUP_COLOR[s.group]
    fig, axs = plt.subplots(1, 2, figsize=(11, 4.2), constrained_layout=True)
    seg = slice(int(10 * 60 * fs), int(11 * 60 * fs))  # 10-11 min into the baseline window
    ts = np.arange(seg.stop - seg.start) / fs
    axs[0].plot(ts, 100 * xx[seg], color=MUTED, lw=1, label="405")
    axs[0].plot(ts, 100 * yy[seg], color=c, lw=1.2, label="465")
    axs[0].set(
        xlabel="Seconds (1 min of baseline)",
        ylabel="% of own mean, 0.2–1 Hz",
        title=f"{s.mouse}: fast fluctuations, 465 follows 405",
    )
    axs[0].legend(loc="lower right")
    k = slice(None, None, 10)
    axs[1].plot(100 * xx[k], 100 * yy[k], ".", ms=2, color=c, alpha=0.3)
    g = np.array([100 * xx.min(), 100 * xx.max()])
    axs[1].plot(g, gain * g, color="k", lw=1.5, label=f"fitted slope = scaling = {gain:.2f}")
    axs[1].plot(g, g, "--", color=INK2, lw=1, label="slope 1 (465 ÷ 405)")
    axs[1].set(
        xlabel="405 fast fluctuation (%)",
        ylabel="465 fast fluctuation (%)",
        title="Whole baseline, every 10th sample",
    )
    axs[1].legend(loc="upper left")
    fig.savefig(path, dpi=120)
    plt.close(fig)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--mouse", default="#5", choices=[s.mouse for s in SESSIONS])
    ap.add_argument("--fiber", choices=sorted(FIBERS), default="pfc")
    args = ap.parse_args(argv)
    walk(args.mouse, args.fiber)


if __name__ == "__main__":
    main()
