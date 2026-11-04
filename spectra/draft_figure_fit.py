"""Draft figure panels D-G for the 13-h study, redrawn with the fast-band 405 fit and two groups.

Changes from `spectra.draft_figure`:
  * NE level (panels D and G, x) is fitted: 465 / control, with the control's scaling learned from
    the 0.2-1 Hz baseline (`core.fast_band_fit_dff`). Slow fluctuations (E, F, G y) keep the
    "465 not shared with 405" measure, which the fit report keeps for spectra.
  * Panel G uses the 60-min window where the NE level vs. slow-fluctuation correlation (all 9 mice)
    is strongest, found by redoing the window scan with the fitted level.
  * Groups are glucose (n = 6) vs. saline (n = 3); no responder split.

Writes results/figure_draft_fit/.

    python -m spectra.draft_figure_fit
"""

from datetime import datetime

import numpy as np
import pandas as pd

from . import core
from .draft_figure import BLOCK_MID, LABEL_NUDGE, RESULTS, fold_axis, mark_injection, panel_letter
from .plots import GROUP_COLOR, INK2, MUTED, plt
from .run_first5h import REPO, git_state
from .sessions import POST_SKIP_MIN, SESSIONS
from .window_scan import FIGURE_LENGTH_MIN, IN_DIR, MEASURE, SCAN_END_MIN, SCAN_STEP_MIN, Mouse, correlate

OUT = REPO / "results" / "figure_draft_fit"
GROUPS = {g: [s.mouse for s in SESSIONS if s.group == g] for g in ["glucose", "saline"]}
LABEL = {"glucose": "Glucose", "saline": "Saline"}
SLOW = "0.01-0.05 Hz"
NUDGE = {**LABEL_NUDGE, "#5": (-16, 4), "FP1": (5, -9)}  # panel G, keeps #5 clear of FP1


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


def make_figure(mice, values, win, path):
    fig, axes = plt.subplots(1, 4, figsize=(16, 4.9), gridspec_kw=dict(wspace=0.42))
    by_mouse = {m.s.mouse: m for m in mice}

    # D: fitted NE level, mean ± SEM, 5-min bins
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
    panel_letter(ax, "D")

    # E, F: slow-fluctuation power by block, PFC and OC (measure unchanged by the fit)
    for ax, fiber, letter in [(axes[1], "PFC", "E"), (axes[2], "OC", "F")]:
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
            ylabel="Power vs. baseline" if letter == "E" else "",
            ylim=(-3.6, 1.8),
            xlim=(-45, 235),
        )
        panel_letter(ax, letter)

    # G: fitted NE level vs. slow fluctuations in the strongest window
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
    panel_letter(ax, "G")

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
        "DRAFT: 13-h study, PFC unless marked; mean ± SEM (glucose n = 6, saline n = 3); "
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


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    mice = [FitMouse(s) for s in SESSIONS]
    values, corr = scan(mice)
    win = strongest(corr, "level_fit_pct")
    raw = strongest(corr, "level_mean_pct")

    values.round(4).to_csv(OUT / "scan_values.csv", index=False)
    corr.round(4).to_csv(OUT / "scan_correlation.csv", index=False)
    make_figure(mice, values, win, OUT / "draft_figure_fit_DtoG.png")
    (OUT / "provenance.txt").write_text(
        f"code commit: {git_state()}\ncreated: {datetime.now():%Y-%m-%d %H:%M:%S}\n"
        f"input: {IN_DIR.relative_to(REPO)}, {RESULTS['PFC'].relative_to(REPO)}, "
        f"{RESULTS['OC'].relative_to(REPO)}\nscript: python -m spectra.draft_figure_fit\n"
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
