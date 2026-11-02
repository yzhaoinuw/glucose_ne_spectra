"""Draft paper figure for the 5-h study: example mice plus responder / non-responder / saline means.

Responders are chosen by the rise in raw 465 (NE level) after the injection,
a measure separate from the slow-fluctuation drop that the figure then shows.
Reads the first-5-h extractions and the results of `spectra.run_first5h`
(PFC and OC); writes results/figure_draft/.

    python -m spectra.draft_figure
"""

from pathlib import Path

import numpy as np
import pandas as pd

from . import core, plots
from .plots import INK, INK2, MUTED, plt
from .run_first5h import REPO, git_state, load
from .sessions import SESSIONS

OUT = REPO / "results" / "figure_draft"
PFC_DIR = REPO / "outputs" / "ne_pfc_ds20_first5h"
RESULTS = {"PFC": REPO / "results" / "spectra_first5h", "OC": REPO / "results" / "spectra_first5h_oc"}

# Groups, from the NE level rise over +20-140 min (responder_split.csv).
GROUPS = {
    "responder": ["#5", "FP1", "FP2"],
    "non-responder": ["#3", "#4", "#22"],
    "saline": ["#1", "#2", "#33"],
}
LABEL = {
    "responder": "Glucose, NE responders",
    "non-responder": "Glucose, poor/no NE response",
    "saline": "Saline",
}
SHORT = {"responder": "NE responders", "non-responder": "poor/no response", "saline": "Saline"}
EXAMPLE_TITLE = {
    "responder": "glucose, NE responder",
    "non-responder": "glucose, poor/no NE response",
    "saline": "saline",
}
LABEL_NUDGE = {"#2": (5, -10)}  # panel G, keeps #2 clear of #4
COLOR = {"responder": "#2a78d6", "non-responder": "#1baf7a", "saline": "#eb6834"}  # categorical slots 1, 3, 2
EXAMPLES = [("#5", "responder"), ("#4", "non-responder"), ("#1", "saline")]

SLOW = "0.01-0.05 Hz"
MEASURE = "465_indep_405"
LEVEL_WIN = (20.0, 140.0)  # min after injection, = the report's first two blocks
CLOSEUP = [("before", -45.0), ("after", 90.0)]  # close-up starts, min from injection; same for every mouse
CLOSEUP_MIN = 20.0
BLOCK_MID = {"baseline": -30.0, "+20-80 min": 50.0, "+80-140 min": 110.0, "+140-200 min": 170.0}
FOLD_TICKS = [-3, -2, -1, 0, 1, 2]
FOLD_LABELS = ["÷8", "÷4", "÷2", "1", "×2", "×4"]


def group_of(mouse):
    return next(g for g, ms in GROUPS.items() if mouse in ms)


def load_all():
    """Raw traces per mouse: dict mouse -> (y465, x405, fs, t_rel_min, baseline mask)."""
    out = {}
    for s in SESSIONS:
        y, x, fs, t_min, _ = load(PFC_DIR / f"{s.folder}.mat")
        t = t_min - s.injection_min
        base = (t_min > 5.0) & (t < -3.0)
        out[s.mouse] = (y, x, fs, t, base)
    return out


def binned(t, v, width_s, fs):
    n = int(round(width_s * fs))
    k = v.size // n
    return t[: k * n].reshape(k, n).mean(1), v[: k * n].reshape(k, n).mean(1)


def responder_table(traces):
    bands = pd.read_csv(RESULTS["PFC"] / "band_power.csv")
    slow = bands[(bands.measure == MEASURE) & (bands.band == SLOW)]
    rows = []
    for s in SESSIONS:
        y, x, fs, t, base = traces[s.mouse]
        post = (t > LEVEL_WIN[0]) & (t < LEVEL_WIN[1])
        m = slow[(slow.mouse == s.mouse) & slow.window.isin(["+20-80 min", "+80-140 min"])]
        rows.append(
            dict(
                mouse=s.mouse,
                treatment=s.group,
                group=group_of(s.mouse),
                ne_level_change_pct=100 * (y[post].mean() / y[base].mean() - 1),
                slow_band_log2_change=m.change_vs_baseline.mean(),
            )
        )
    return pd.DataFrame(rows)


def mean_sem(a):
    a = np.asarray(a, float)
    return a.mean(0), a.std(0, ddof=1) / np.sqrt(a.shape[0])


def fold_axis(ax):
    ax.set_yticks(FOLD_TICKS, FOLD_LABELS)
    ax.axhline(0, color=MUTED, lw=0.8)


def mark_injection(ax):
    ax.axvspan(0, 20, color="#e1e0d9", alpha=0.6, lw=0)
    ax.axvline(0, color=INK2, lw=0.8, ls=":")


def end_labels(ax, x, ys, min_gap):
    """Direct labels at the line ends, pushed apart to at least min_gap (data units)."""
    items = sorted(ys.items(), key=lambda kv: kv[1])
    placed = []
    for g, y in items:
        y = max(y, placed[-1][1] + min_gap) if placed else y
        placed.append((g, y))
    for g, y in placed:
        ax.annotate(
            SHORT[g], (x, y), xytext=(6, 0), textcoords="offset points", va="center", fontsize=7.5, color=INK2
        )


def panel_letter(ax, s):
    ax.text(-0.14, 1.06, s, transform=ax.transAxes, fontsize=12, fontweight="bold", va="bottom")


def make_figure(traces, table, path):
    fig = plt.figure(figsize=(14, 15.5))
    outer = fig.add_gridspec(2, 1, height_ratios=[3, 1.15], hspace=0.28)
    top = outer[0].subgridspec(3, 3, hspace=0.5, wspace=0.25)
    bottom = outer[1].subgridspec(1, 4, wspace=0.42)
    spectra = pd.read_csv(RESULTS["PFC"] / "spectra_logbinned.csv")

    for col, (mouse, g) in enumerate(EXAMPLES):
        y, x, fs, t, base = traces[mouse]
        title = f"{mouse}: {EXAMPLE_TITLE[g]}"
        # A: whole first 5 h
        ax = fig.add_subplot(top[0, col])
        tb, yb = binned(t, 100 * y / y[base].mean(), 10.0, fs)
        _, xb = binned(t, 100 * x / x[base].mean(), 10.0, fs)
        ax.plot(tb, xb, color=MUTED, lw=0.6, label="405 (control)")
        ax.plot(tb, yb, color=COLOR[g], lw=0.6, label="465 (NE)")
        mark_injection(ax)
        ax.set(title=title, xlabel="Minutes from injection", ylim=(70, 130), xlim=(tb[0], tb[-1]))
        ax.set_ylabel("% of baseline (10-s means)" if col == 0 else "")
        if col == 0:
            ax.legend(loc="lower left", ncol=2)
            panel_letter(ax, "A")
        # B: 10-min close-ups before and after, stacked
        ax = fig.add_subplot(top[1, col])
        for i, (name, start) in enumerate(CLOSEUP):
            m = (t >= start) & (t < start + CLOSEUP_MIN)
            seg = core.pct_of_mean(y[m])
            k = int(round(fs))  # 1-s moving average
            seg = np.convolve(seg, np.ones(k) / k, mode="same")[k:-k]
            tt = t[m][k:-k] - start
            ax.plot(tt, seg - 25 * i, color=MUTED if i == 0 else COLOR[g], lw=0.8)
            when = "Before: −45 to −25 min" if i == 0 else "After: +90 to +110 min"
            ax.text(0.2, 9 - 25 * i, when, fontsize=7.5, color=INK2)
        ax.set(xlim=(0, CLOSEUP_MIN), ylim=(-40, 12), yticks=[], xlabel="Minutes into 20-min close-up")
        ax.plot([CLOSEUP_MIN - 0.3] * 2, [-38, -28], color=INK, lw=1.2)
        ax.text(CLOSEUP_MIN - 0.4, -33, "10%", ha="right", va="center", fontsize=7.5)
        ax.grid(False)
        if col == 0:
            ax.set_ylabel("465, % of window mean (1-s smoothed)")
            panel_letter(ax, "B")
        # C: spectra, baseline vs first post block
        ax = fig.add_subplot(top[2, col])
        d = spectra[(spectra.mouse == mouse) & (spectra.measure == MEASURE)]
        for win, c, lab in [("baseline", MUTED, "Baseline"), ("+20-80 min", COLOR[g], "+20–80 min")]:
            w = d[d.window == win]
            ax.loglog(w.f_hz, w.value, color=c, lw=1.6, label=lab)
        ax.axvspan(0.01, 0.05, color="#e1e0d9", alpha=0.5, lw=0)
        ax.set(xlim=(0.015, 1.0), xlabel="Frequency (Hz)")
        ax.set_ylabel("465 power not shared with 405" if col == 0 else "")
        ax.legend(loc="lower left")
        if col == 0:
            panel_letter(ax, "C")

    # D: NE level, mean ± SEM, 5-min bins
    ax = fig.add_subplot(bottom[0])
    ends = {}
    for g, mice in GROUPS.items():
        edges = np.arange(-55.0, 236.0, 5.0)
        rows = []
        for mouse in mice:
            y, x, fs, t, base = traces[mouse]
            pct = 100 * (y / y[base].mean() - 1)
            rows.append([pct[(t >= a) & (t < b)].mean() for a, b in zip(edges[:-1], edges[1:])])
        mu, se = mean_sem(rows)
        tt = edges[:-1] + 2.5
        ax.fill_between(tt, mu - se, mu + se, color=COLOR[g], alpha=0.2, lw=0)
        ax.plot(tt, mu, color=COLOR[g], lw=2, label=LABEL[g])
        ends[g] = mu[-1]
    end_labels(ax, tt[-1], ends, 2.2)
    mark_injection(ax)
    ax.axhline(0, color=MUTED, lw=0.8)
    ax.set(title="NE level (raw 465)", xlabel="Minutes from injection", ylabel="% change from baseline")
    ax.set_xlim(-55, 290)
    panel_letter(ax, "D")

    # E, F: slow-fluctuation power by block, PFC and OC
    for i, (fiber, letter) in enumerate([("PFC", "E"), ("OC", "F")]):
        ax = fig.add_subplot(bottom[1 + i])
        bands = pd.read_csv(RESULTS[fiber] / "band_power.csv")
        bands = bands[(bands.measure == MEASURE) & (bands.band == SLOW) & bands.window.isin(BLOCK_MID)]
        ends = {}
        for g, mice in GROUPS.items():
            wide = bands[bands.mouse.isin(mice)].pivot(
                index="mouse", columns="window", values="change_vs_baseline"
            )
            wide = wide[list(BLOCK_MID)]
            mu, se = mean_sem(wide.values)
            xs = list(BLOCK_MID.values())
            ax.errorbar(xs, mu, yerr=se, color=COLOR[g], lw=2, marker="o", ms=5, capsize=3, label=LABEL[g])
            ends[g] = mu[-1]
        end_labels(ax, xs[-1], ends, 0.35)
        mark_injection(ax)
        fold_axis(ax)
        ax.set(
            title=f"Slow NE fluctuations, {fiber} (0.01–0.05 Hz)",
            xlabel="Minutes from injection (block centre)",
            ylim=(-3.6, 1.8),
            xlim=(-45, 235),
        )
        ax.set_ylabel("Power vs. baseline" if i == 0 else "")
        panel_letter(ax, letter)

    # G: how responders are chosen
    ax = fig.add_subplot(bottom[3])
    for g in GROUPS:
        d = table[table.group == g]
        ax.scatter(d.ne_level_change_pct, d.slow_band_log2_change, s=42, color=COLOR[g], zorder=3)
        for _, r in d.iterrows():
            ax.annotate(
                r.mouse,
                (r.ne_level_change_pct, r.slow_band_log2_change),
                xytext=LABEL_NUDGE.get(r.mouse, (5, 3)),
                textcoords="offset points",
                fontsize=7.5,
                color=INK2,
            )
    fold_axis(ax)
    ax.axvline(0, color=MUTED, lw=0.8)
    ax.set(
        title="Responders chosen by NE level (x),\nthen their slow fluctuations (y)",
        xlabel="NE level change, +20–140 min (%)",
        ylabel="Slow-fluctuation power, +20–140 min",
        ylim=(-3.6, 1.8),
    )
    panel_letter(ax, "G")

    handles = [plt.Line2D([], [], color=COLOR[g], lw=2, marker="o", ms=5) for g in GROUPS]
    fig.legend(
        handles,
        [f"{LABEL[g]} ({', '.join(GROUPS[g])})" for g in GROUPS],
        loc="lower center",
        ncol=3,
        bbox_to_anchor=(0.5, 0.005),
        fontsize=9,
    )
    fig.text(
        0.5,
        0.995,
        "DRAFT: 5-h study, PFC unless marked; mean ± SEM, n = 3 per group; grey band = injection "
        "and 20-min handling period",
        ha="center",
        va="top",
        fontsize=9,
        color=INK2,
    )
    fig.subplots_adjust(left=0.06, right=0.97, top=0.965, bottom=0.06)
    fig.savefig(path, dpi=110)
    plt.close(fig)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    traces = load_all()
    table = responder_table(traces)
    table.round(3).to_csv(OUT / "responder_split.csv", index=False)
    print(table.round(2).to_string(index=False))
    make_figure(traces, table, OUT / "draft_figure.png")
    (OUT / "provenance.txt").write_text(
        f"code commit: {git_state()}\nscript: python -m spectra.draft_figure\n"
    )
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
