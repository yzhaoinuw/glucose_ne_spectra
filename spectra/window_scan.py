"""13-h study: when after the injection is the NE level vs. slow-fluctuation correlation
(draft figure, panel G) strongest?

Slides a window over the 4 h after the injection and, in each window, correlates across
mice the NE level change (raw 465 mean vs. baseline, as in panel G) with the change in
slow fluctuations (0.01-0.05 Hz, 465 power not shared with 405, log2 vs. baseline).
Also checks the same relation within each mouse over time, and with an NE level measure
that ignores the dips (90th percentile of 10-s means). Writes results/window_scan_13h/.

    python -m spectra.window_scan
"""

from datetime import datetime

import numpy as np
import pandas as pd
from scipy.stats import pearsonr, spearmanr

from . import core
from .plots import GROUP_COLOR, INK, MUTED, plt
from .run_first5h import REPO, git_state, load
from .sessions import POST_SKIP_MIN, SESSIONS, windows

IN_DIR = REPO / "outputs" / "ne_pfc_ds20_first5h"
OUT = REPO / "results" / "window_scan_13h"

SLOW = (0.01, 0.05)
MEASURE = "465_indep_405"
SCAN_LENGTHS_MIN = [20, 30, 60]
SCAN_STEP_MIN = 5.0
SCAN_END_MIN = 240.0  # recordings end ~4 h after the injection
WITHIN_LEN_MIN = 20.0
PRE_WINDOWS = [(-43.0, -23.0), (-23.0, -3.0)]  # inside every mouse's baseline
PANEL_G = (20.0, 140.0)
FIGURE_LENGTH_MIN = 60
FOLD_TICKS = [-4, -3, -2, -1, 0, 1, 2]  # log2, labelled as fold changes like the draft figure's panel G
FOLD_LABELS = ["÷16", "÷8", "÷4", "÷2", "1", "×2", "×4"]


def tenth_s_means(v, fs, width_s=10.0):
    n = int(round(width_s * fs))
    k = v.size // n
    return v[: k * n].reshape(k, n).mean(1)


def slow_power(y, x, fs):
    f, sp = core.window_spectra(y, x, y, fs)  # dff unused here
    return core.band_power(f, sp[MEASURE], *SLOW)


class Mouse:
    """One session's traces and baseline reference values."""

    def __init__(self, s):
        y, x, fs, t_min, _ = load(IN_DIR / f"{s.folder}.mat")
        _, a, b = windows(s, t_min[-1])[0]
        base = (t_min >= a) & (t_min < b)
        self.s, self.y, self.x, self.fs = s, y, x, fs
        self.t = t_min - s.injection_min
        self.base_mean = y[base].mean()
        self.base_p90 = np.percentile(tenth_s_means(y[base], fs), 90)
        self.base_slow = slow_power(y[base], x[base], fs)

    def measure(self, start, stop):
        m = (self.t >= start) & (self.t < stop)
        if m.sum() / self.fs / 60.0 < (stop - start) - 1.0:  # window runs past the recording
            return None
        y = self.y[m]
        return dict(
            mouse=self.s.mouse,
            group=self.s.group,
            start_min=start,
            stop_min=stop,
            level_mean_pct=100 * (y.mean() / self.base_mean - 1),
            level_p90_pct=100 * (np.percentile(tenth_s_means(y, self.fs), 90) / self.base_p90 - 1),
            slow_log2=float(np.log2(slow_power(y, self.x[m], self.fs) / self.base_slow)),
        )


def correlate(df, level):
    """Across-mouse r per window, for all mice and glucose mice only; with a Fisher 95% CI."""
    rows = []
    for (length, start), g in df.groupby(["length_min", "start_min"]):
        for subset, d in [("all", g), ("glucose", g[g.group == "glucose"])]:
            n = len(d)
            r = pearsonr(d[level], d.slow_log2)[0]
            z, se = np.arctanh(r), 1 / np.sqrt(n - 3)
            rows.append(
                dict(
                    level=level,
                    length_min=length,
                    start_min=start,
                    centre_min=start + length / 2,
                    subset=subset,
                    n=n,
                    pearson_r=r,
                    ci95_lo=np.tanh(z - 1.96 * se),
                    ci95_hi=np.tanh(z + 1.96 * se),
                    spearman_rho=spearmanr(d[level], d.slow_log2)[0],
                )
            )
    return pd.DataFrame(rows)


def make_figure(corr, within, path):
    """A: across-mouse r over time (60-min windows, all 9 mice). B: within-mouse view, drawn with
    the same axes as the draft figure's panel G."""
    fig, ax = plt.subplots(1, 2, figsize=(11, 4.4))

    a = ax[0]
    d = corr[
        (corr.level == "level_mean_pct") & (corr.length_min == FIGURE_LENGTH_MIN) & (corr.subset == "all")
    ]
    d = d[d.n == d.n.max()]  # windows with all 9 mice
    a.plot(d.centre_min, d.pearson_r, "-o", ms=3, color=INK, lw=2)
    a.set(
        ylim=(-1, 0),
        xlim=(0, SCAN_END_MIN),
        xlabel="Window centre, min after injection",
        ylabel="Correlation r across the 9 mice",
        title=f"A. Across mice: panel G's r in {FIGURE_LENGTH_MIN}-min windows,\nslid in {SCAN_STEP_MIN:g}-min steps",
    )

    a = ax[1]
    for mouse, g in within.groupby("mouse", sort=False):
        c = GROUP_COLOR[g.group.iloc[0]]
        a.plot(g.level_mean_pct, g.slow_log2, "o", ms=4, color=c, alpha=0.6)
        k = np.polyfit(g.level_mean_pct, g.slow_log2, 1)
        xs = np.array([g.level_mean_pct.min(), g.level_mean_pct.max()])
        a.plot(xs, np.polyval(k, xs), color=c, lw=1.2)
    a.axhline(0, color=MUTED, lw=0.8)
    a.axvline(0, color=MUTED, lw=0.8)
    a.set_yticks(FOLD_TICKS, FOLD_LABELS)
    a.plot([], [], "o-", color=GROUP_COLOR["glucose"], label="glucose mouse")
    a.plot([], [], "o-", color=GROUP_COLOR["saline"], label="saline mouse")
    a.legend(loc="lower left", fontsize=8, frameon=False)
    a.set(
        xlabel=f"NE level change (%), {WITHIN_LEN_MIN:g}-min windows",
        ylabel=f"Slow-fluctuation power, {WITHIN_LEN_MIN:g}-min windows",
        title="B. Within each mouse: its 20-min windows over time\n(dots), with a fitted line per mouse",
    )
    fig.suptitle("13-h study, PFC: NE level vs. slow NE fluctuations (0.01–0.05 Hz)", color=INK, fontsize=11)
    fig.tight_layout()
    fig.savefig(path, dpi=130)
    plt.close(fig)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    mice = [Mouse(s) for s in SESSIONS]

    scan = []
    for length in SCAN_LENGTHS_MIN:
        for start in np.arange(POST_SKIP_MIN, SCAN_END_MIN - length + 1e-9, SCAN_STEP_MIN):
            for m in mice:
                r = m.measure(start, start + length)
                if r is not None:
                    scan.append(dict(r, length_min=length))
    scan = pd.DataFrame(scan)
    corr = pd.concat([correlate(scan, lv) for lv in ["level_mean_pct", "level_p90_pct"]])

    starts = PRE_WINDOWS + [
        (a, a + WITHIN_LEN_MIN) for a in np.arange(POST_SKIP_MIN, SCAN_END_MIN - WITHIN_LEN_MIN + 1e-9, 20.0)
    ]
    within = pd.DataFrame([r for m in mice for a, b in starts if (r := m.measure(a, b)) is not None])
    per_mouse = pd.DataFrame(
        [
            dict(
                mouse=mouse,
                group=g.group.iloc[0],
                n_windows=len(g),
                r_level_mean=pearsonr(g.level_mean_pct, g.slow_log2)[0],
                r_level_p90=pearsonr(g.level_p90_pct, g.slow_log2)[0],
            )
            for mouse, g in within.groupby("mouse", sort=False)
        ]
    )
    panel_g = pd.DataFrame([m.measure(*PANEL_G) for m in mice])

    scan.to_csv(OUT / "scan_values.csv", index=False)
    corr.to_csv(OUT / "scan_correlation.csv", index=False)
    within.to_csv(OUT / "within_mouse_values.csv", index=False)
    per_mouse.to_csv(OUT / "within_mouse_r.csv", index=False)
    panel_g.to_csv(OUT / "panel_g_window.csv", index=False)
    make_figure(corr, within, OUT / "correlation_over_time.png")
    (OUT / "provenance.txt").write_text(
        f"code commit: {git_state()}\ncreated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"input: {IN_DIR.relative_to(REPO)}\nscript: python -m spectra.window_scan\n"
    )

    full = corr[corr.n == corr.groupby(["level", "length_min", "subset"]).n.transform("max")]
    for (lv, length, sub), d in full.groupby(["level", "length_min", "subset"]):
        best = d.loc[d.pearson_r.idxmin()]
        print(
            f"{lv:15} {length:2d} min {sub:7}: r {d.pearson_r.min():+.2f} to {d.pearson_r.max():+.2f}; "
            f"strongest at centre +{best.centre_min:.0f} min"
        )
    print(per_mouse.round(2).to_string(index=False))
    for lv in ["level_mean_pct", "level_p90_pct"]:
        g = panel_g[panel_g.group == "glucose"]
        print(
            f"panel G window, {lv}: all r={pearsonr(panel_g[lv], panel_g.slow_log2)[0]:+.2f}, "
            f"glucose r={pearsonr(g[lv], g.slow_log2)[0]:+.2f}"
        )


if __name__ == "__main__":
    main()
