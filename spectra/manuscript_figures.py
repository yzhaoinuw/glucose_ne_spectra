"""Candidate manuscript figures for the 13-h study, all with the fast-band 405 fit.

  * group_summary.png, panels A-D, glucose (n = 6) vs. saline (n = 3): A, NE level over time;
    B, C, slow fluctuations per block in PFC and OC; D, NE level vs. slow fluctuations across mice
    in the 60-min window where their correlation is strongest (window scan redone with the fitted
    level). Fitted NE level = 465 / control, with the control's scaling learned from the 0.2-1 Hz
    baseline (`core.fast_band_fit_dff`). Slow fluctuations keep the "465 not shared with 405"
    measure, which the fit report keeps for spectra.
  * mouse_<id>.png, one per mouse (PFC): the fitted NE signal (top) over its spectrogram (bottom),
    sharing the time axis.

Writes results/manuscript_figures/.

    python -m spectra.manuscript_figures

Custom spectrogram range: --freq LO HI (Hz) redraws only the per-mouse figures, into
results/manuscript_figures/spectrogram_<LO>-<HI>Hz/ (or --out-dir), leaving the default set as is:

    python -m spectra.manuscript_figures --freq 0.01 1

The lowest usable frequency is ~0.008 Hz (the 120-s segments); the highest is the Nyquist frequency,
~10 Hz. Above ~0.05 Hz the fitted signal still carries some 405 artifact after glucose (see the fit
report), and the recordings roll off above ~6 Hz.
"""

import argparse
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.ticker import NullFormatter
from scipy import ndimage

from . import core
from .draft_figure import BLOCK_MID, LABEL_NUDGE, RESULTS, fold_axis, mark_injection, panel_letter
from .plots import GROUP_COLOR, INK, INK2, MUTED, SPECTROGRAM_CMAP, SURFACE, patheffects, plt
from .run_first5h import REPO, git_state
from .sessions import POST_SKIP_MIN, SESSIONS
from .window_scan import FIGURE_LENGTH_MIN, IN_DIR, MEASURE, SCAN_END_MIN, SCAN_STEP_MIN, Mouse, correlate

OUT = REPO / "results" / "manuscript_figures"
GROUPS = {g: [s.mouse for s in SESSIONS if s.group == g] for g in ["glucose", "saline"]}
LABEL = {"glucose": "Glucose", "saline": "Saline"}
SLOW = "0.01-0.05 Hz"
SPEC_RANGE = (0.01, 0.2)  # Hz, default: the slow band (0.01-0.05) and the next band up
SLOW_EDGE = 0.05  # Hz
SPEC_STEP_S = 60.0  # spectrogram step; segments are core.SEG_S (120 s) long
TRACE_BIN_S = 1.0
SPEC_SMOOTH = 5  # spectrogram columns averaged (5 min), as Welch averages segments
NUDGE = {**LABEL_NUDGE, "#5": (-16, 4), "FP1": (5, -9)}  # panel D, keeps #5 clear of FP1


class FitMouse(Mouse):
    """A window-scan mouse that also gives the fitted NE level."""

    def __init__(self, s):
        super().__init__(s)
        t_min = self.t + s.injection_min
        self.base = (t_min >= 5.0) & (self.t < -3.0)  # = sessions.windows baseline
        _, self.gain = core.fast_band_fit_dff(self.y, self.x, self.fs, self.base)
        self.ratio = self.y / core.scaled_control(self.y, self.x, self.base, self.gain)
        self.base_ratio = self.ratio[self.base].mean()

    def fitted_level(self, m):
        return 100 * (self.ratio[m].mean() / self.base_ratio - 1)

    def measure(self, start, stop):
        r = super().measure(start, stop)
        if r is not None:
            r["level_fit_pct"] = self.fitted_level((self.t >= start) & (self.t < stop))
        return r


def scan(mice):
    rows = []
    for start in np.arange(POST_SKIP_MIN, SCAN_END_MIN - FIGURE_LENGTH_MIN + 1e-9, SCAN_STEP_MIN):
        for m in mice:
            r = m.measure(start, start + FIGURE_LENGTH_MIN)
            if r is not None:
                rows.append(dict(r, length_min=FIGURE_LENGTH_MIN))
    values = pd.DataFrame(rows)
    corr = pd.concat([correlate(values, lv) for lv in ["level_fit_pct", "level_mean_pct"]])
    corr = corr[corr.n == corr.n.max()]  # windows with all 9 mice
    return values, corr


def strongest(corr, level):
    d = corr[(corr.level == level) & (corr.subset == "all")].sort_values("pearson_r")
    best = d.iloc[0]
    return best.start_min, best.start_min + FIGURE_LENGTH_MIN, best.pearson_r


def mean_sem(a):
    a = np.asarray(a, float)
    return a.mean(0), a.std(0, ddof=1) / np.sqrt(a.shape[0])


def group_labels(ax, x, ys, min_gap):
    """Direct labels at the line ends, pushed apart to at least min_gap (data units)."""
    placed = []
    for g, y in sorted(ys.items(), key=lambda kv: kv[1]):
        placed.append((g, max(y, placed[-1][1] + min_gap) if placed else y))
    for g, y in placed:
        ax.annotate(
            LABEL[g], (x, y), xytext=(6, 0), textcoords="offset points", va="center", fontsize=7.5, color=INK2
        )


def group_summary(mice, values, win, path):
    fig, axes = plt.subplots(1, 4, figsize=(16, 4.9), gridspec_kw=dict(wspace=0.42))
    by_mouse = {m.s.mouse: m for m in mice}

    # A: fitted NE level, mean ± SEM, 5-min bins
    ax = axes[0]
    edges = np.arange(-55.0, 236.0, 5.0)
    tt = edges[:-1] + 2.5
    ends = {}
    for g, names in GROUPS.items():
        rows = []
        for name in names:
            m = by_mouse[name]
            rows.append([m.fitted_level((m.t >= a) & (m.t < b)) for a, b in zip(edges[:-1], edges[1:])])
        mu, se = mean_sem(rows)
        ax.fill_between(tt, mu - se, mu + se, color=GROUP_COLOR[g], alpha=0.2, lw=0)
        ax.plot(tt, mu, color=GROUP_COLOR[g], lw=2)
        ends[g] = mu[-1]
    group_labels(ax, tt[-1], ends, 2.2)
    mark_injection(ax)
    ax.axhline(0, color=MUTED, lw=0.8)
    ax.set(
        title="NE level (465, fitted 405 removed)",
        xlabel="Minutes from injection",
        ylabel="% change from baseline",
        xlim=(-55, 285),
    )
    panel_letter(ax, "A")

    # B, C: slow-fluctuation power by block, PFC and OC (measure unchanged by the fit)
    for ax, fiber, letter in [(axes[1], "PFC", "B"), (axes[2], "OC", "C")]:
        bands = pd.read_csv(RESULTS[fiber] / "band_power.csv")
        bands = bands[(bands.measure == MEASURE) & (bands.band == SLOW) & bands.window.isin(BLOCK_MID)]
        ends = {}
        xs = list(BLOCK_MID.values())
        for g, names in GROUPS.items():
            wide = bands[bands.mouse.isin(names)].pivot(
                index="mouse", columns="window", values="change_vs_baseline"
            )[list(BLOCK_MID)]
            mu, se = mean_sem(wide.values)
            ax.errorbar(xs, mu, yerr=se, color=GROUP_COLOR[g], lw=2, marker="o", ms=5, capsize=3)
            ends[g] = mu[-1]
        group_labels(ax, xs[-1], ends, 0.35)
        mark_injection(ax)
        fold_axis(ax)
        ax.set(
            title=f"Slow NE fluctuations, {fiber} (0.01–0.05 Hz)",
            xlabel="Minutes from injection (block centre)",
            ylabel="Power vs. baseline" if letter == "B" else "",
            ylim=(-3.6, 1.8),
            xlim=(-45, 235),
        )
        panel_letter(ax, letter)

    # D: fitted NE level vs. slow fluctuations in the strongest window
    ax = axes[3]
    start, stop, r = win
    d = values[values.start_min == start]
    for g, names in GROUPS.items():
        dd = d[d.mouse.isin(names)]
        ax.scatter(dd.level_fit_pct, dd.slow_log2, s=42, color=GROUP_COLOR[g], zorder=3)
        for _, row in dd.iterrows():
            ax.annotate(
                row.mouse,
                (row.level_fit_pct, row.slow_log2),
                xytext=NUDGE.get(row.mouse, (5, 3)),
                textcoords="offset points",
                fontsize=7.5,
                color=INK2,
            )
    fold_axis(ax)
    ax.axvline(0, color=MUTED, lw=0.8)
    ax.set(
        title=f"NE level vs. slow fluctuations,\nstrongest window +{start:.0f}–{stop:.0f} min: r = {r:.2f}",
        xlabel=f"NE level change (fitted), +{start:.0f}–{stop:.0f} min (%)",
        ylabel=f"Slow-fluctuation power, +{start:.0f}–{stop:.0f} min",
        ylim=(-3.6, 1.8),
    )
    panel_letter(ax, "D")

    handles = [plt.Line2D([], [], color=GROUP_COLOR[g], lw=2, marker="o", ms=5) for g in GROUPS]
    fig.legend(
        handles,
        [f"{LABEL[g]} ({', '.join(GROUPS[g])})" for g in GROUPS],
        loc="lower center",
        ncol=2,
        bbox_to_anchor=(0.5, 0.0),
        fontsize=9,
    )
    fig.text(
        0.5,
        0.99,
        "13-h study, PFC unless marked; mean ± SEM (glucose n = 6, saline n = 3); "
        "grey band = injection and 20-min handling period. NE level: 405 scaling learned at 0.2–1 Hz "
        "in the baseline. Slow fluctuations: 465 not shared with 405.",
        ha="center",
        va="top",
        fontsize=8.5,
        color=INK2,
    )
    fig.subplots_adjust(left=0.05, right=0.97, top=0.82, bottom=0.2)
    fig.savefig(path, dpi=130)
    plt.close(fig)


def log_ticks(lo, hi):
    """1-2-5 ticks inside [lo, hi]; the two ends if fewer than two fall inside."""
    ticks = [
        m * 10.0**e
        for e in range(int(np.floor(np.log10(lo))), int(np.ceil(np.log10(hi))) + 1)
        for m in (1, 2, 5)
    ]
    ticks = [float(f"{v:.3g}") for v in ticks if lo * (1 - 1e-9) <= v <= hi * (1 + 1e-9)]
    return ticks if len(ticks) >= 2 else [lo, hi]


def mouse_spectrogram(m, f_range=SPEC_RANGE):
    """Spectrogram of the fitted ratio 465 / control (% of each segment's mean, i.e. fitted dF/F
    units), averaged over SPEC_SMOOTH neighbouring segments, kept to the plotted range.
    Returns f, segment-centre times (min from injection), S[f, t]."""
    f, ts, S = core.spectrogram(m.ratio, m.fs, step_s=SPEC_STEP_S)
    S = ndimage.uniform_filter1d(S, SPEC_SMOOTH, axis=1, mode="nearest")
    keep = (f > f_range[0] / 2) & (f <= f_range[1] * 1.05)
    return f[keep], m.t[0] + ts / 60.0, S[keep]


def mouse_figure(m, spec, clim, path, f_range=SPEC_RANGE):
    """Fitted NE signal (top) over its spectrogram (bottom), sharing the time axis."""
    f, ts, S = spec
    fig = plt.figure(figsize=(10, 6))
    gs = fig.add_gridspec(2, 2, width_ratios=[1, 0.018], height_ratios=[1, 1.15], hspace=0.08, wspace=0.03)
    top = fig.add_subplot(gs[0, 0])
    bot = fig.add_subplot(gs[1, 0], sharex=top)

    n = int(round(TRACE_BIN_S * m.fs))
    k = m.ratio.size // n
    tb = m.t[: k * n].reshape(k, n).mean(1)
    yb = 100 * (m.ratio[: k * n].reshape(k, n).mean(1) / m.base_ratio - 1)
    top.plot(tb, yb, color=GROUP_COLOR[m.s.group], lw=0.6)
    mark_injection(top)
    top.axhline(0, color=MUTED, lw=0.8)
    top.set_ylabel(f"Fitted ΔF/F (%, {TRACE_BIN_S:g}-s means)")
    top.set_title(
        f"{m.s.mouse}, {m.s.group}, PFC: fitted NE signal and its spectrogram (405 scaling {m.gain:.2f})",
        loc="left",
    )
    top.tick_params(labelbottom=False)

    df = f[1] - f[0]
    dt = ts[1] - ts[0]
    mesh = bot.pcolormesh(
        np.r_[ts - dt / 2, ts[-1] + dt / 2],
        np.r_[f - df / 2, f[-1] + df / 2],
        np.log10(S),
        shading="flat",
        cmap=SPECTROGRAM_CMAP,
        vmin=clim[0],
        vmax=clim[1],
        rasterized=True,
    )
    bot.set_yscale("log")
    bot.set_ylim(*f_range)
    ticks = log_ticks(*f_range)
    bot.set_yticks(ticks, [f"{v:g}" for v in ticks])
    bot.yaxis.set_minor_formatter(NullFormatter())
    bot.grid(False)
    eff = [patheffects.withStroke(linewidth=2.4, foreground=INK)]
    bot.axvline(0, color=SURFACE, lw=1.1, path_effects=eff)
    if f_range[0] < SLOW_EDGE < f_range[1]:
        bot.axhline(SLOW_EDGE, color=SURFACE, lw=0.9, ls=(0, (4, 3)), path_effects=eff)
        bot.text(
            m.t[0] + 2,
            SLOW_EDGE * 0.93,
            "slow band below",
            color=SURFACE,
            fontsize=7.5,
            va="top",
            path_effects=eff,
        )
    bot.set(xlabel="Minutes from injection", ylabel="Frequency (Hz)", xlim=(m.t[0], m.t[-1]))
    cbar = fig.colorbar(mesh, cax=fig.add_subplot(gs[1, 1]))
    cbar.set_label("log10 power (%²/Hz)")
    fig.subplots_adjust(left=0.08, right=0.92, top=0.93, bottom=0.09)
    fig.savefig(path, dpi=150)
    plt.close(fig)


def mouse_figures(mice, f_range, out_dir):
    """One figure per mouse, all on one colour scale (1st-99.5th percentile of the plotted range)."""
    specs = {m.s.mouse: mouse_spectrogram(m, f_range) for m in mice}
    pooled = np.concatenate(
        [np.log10(S[(f >= f_range[0]) & (f <= f_range[1])]).ravel() for f, _, S in specs.values()]
    )
    clim = tuple(np.percentile(pooled, [1, 99.5]))
    for m in mice:
        mouse_figure(m, specs[m.s.mouse], clim, out_dir / f"mouse_{m.s.mouse.lstrip('#')}.png", f_range)


def range_error(lo, hi, fs):
    """Why [lo, hi] Hz can't be drawn, or None if it can."""
    f_min, f_max = 1.0 / core.SEG_S, fs / 2
    if not 0 < lo < hi:
        return f"need 0 < LO < HI, got {lo:g} {hi:g}"
    if lo < f_min:
        return f"LO must be at least {f_min:.4f} Hz (1 / the {core.SEG_S:g}-s segment), got {lo:g}"
    if hi > f_max:
        return f"HI must be at most {f_max:.2f} Hz (the Nyquist frequency), got {hi:g}"
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument(
        "--freq",
        nargs=2,
        type=float,
        metavar=("LO", "HI"),
        help=f"spectrogram range in Hz; draws only the per-mouse figures (default {SPEC_RANGE[0]:g} "
        f"{SPEC_RANGE[1]:g}, with all figures)",
    )
    ap.add_argument("--out-dir", help="output folder for a custom range (default: a subfolder named by it)")
    args = ap.parse_args()
    if args.freq and (err := range_error(*args.freq, fs=np.inf)):  # fail fast; HI is checked once fs is known
        ap.error(err)

    mice = [FitMouse(s) for s in SESSIONS]
    if args.freq:
        f_range = tuple(args.freq)
        if err := range_error(*f_range, fs=min(m.fs for m in mice)):
            ap.error(err)
        out = Path(args.out_dir) if args.out_dir else OUT / f"spectrogram_{f_range[0]:g}-{f_range[1]:g}Hz"
        out.mkdir(parents=True, exist_ok=True)
        mouse_figures(mice, f_range, out)
        (out / "provenance.txt").write_text(
            f"code commit: {git_state()}\ncreated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
            f"input: {IN_DIR.relative_to(REPO)}\n"
            f"script: python -m spectra.manuscript_figures --freq {f_range[0]:g} {f_range[1]:g}\n"
        )
        print(f"Wrote {len(mice)} per-mouse figures, {f_range[0]:g}-{f_range[1]:g} Hz, to {out}")
        return

    OUT.mkdir(parents=True, exist_ok=True)
    mouse_figures(mice, SPEC_RANGE, OUT)
    values, corr = scan(mice)
    win = strongest(corr, "level_fit_pct")
    raw = strongest(corr, "level_mean_pct")

    values.round(4).to_csv(OUT / "scan_values.csv", index=False)
    corr.round(4).to_csv(OUT / "scan_correlation.csv", index=False)
    group_summary(mice, values, win, OUT / "group_summary.png")
    (OUT / "provenance.txt").write_text(
        f"code commit: {git_state()}\ncreated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"input: {IN_DIR.relative_to(REPO)}, {RESULTS['PFC'].relative_to(REPO)}, "
        f"{RESULTS['OC'].relative_to(REPO)}\nscript: python -m spectra.manuscript_figures\n"
    )

    d = corr[corr.subset == "all"].pivot(index="start_min", columns="level", values="pearson_r")
    print("across-mouse r per 60-min window (all 9 mice):")
    print(d.round(2).to_string())
    print(f"strongest, fitted level: +{win[0]:.0f}-{win[1]:.0f} min, r = {win[2]:+.2f}")
    print(f"strongest, raw 465:      +{raw[0]:.0f}-{raw[1]:.0f} min, r = {raw[2]:+.2f}")
    g = values[values.start_min == win[0]][["mouse", "group", "level_fit_pct", "level_mean_pct", "slow_log2"]]
    print(g.round(2).to_string(index=False))
    print({m.s.mouse: round(m.gain, 3) for m in mice})


if __name__ == "__main__":
    main()
