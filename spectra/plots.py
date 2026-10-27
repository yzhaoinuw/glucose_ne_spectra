"""Figures for the first-5-h spectral comparison (static PNGs)."""

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

# Reference palette (dataviz skill, light mode).
SURFACE, INK, INK2, MUTED, GRID, AXIS = "#fcfcfb", "#0b0b0b", "#52514e", "#898781", "#e1e0d9", "#c3c2b7"
GROUP_COLOR = {"glucose": "#2a78d6", "saline": "#eb6834"}  # categorical slots 1, 2
BLOCK_RAMP = ["#86b6ef", "#3987e5", "#1c5cab", "#0d366b"]  # ordinal blue, post blocks in time order
BASELINE_COLOR = INK2
TITLES = {
    "465": "465 (NE sensor)",
    "405": "405 (isosbestic control)",
    "465_indep_405": "465, part not predicted by 405",
    "dff_baseline_fit": "ΔF/F, baseline-only fit (cross-check)",
    "coherence": "465–405 coherence",
}

plt.rcParams.update(
    {
        "figure.facecolor": SURFACE,
        "axes.facecolor": SURFACE,
        "savefig.facecolor": SURFACE,
        "axes.edgecolor": AXIS,
        "axes.labelcolor": INK2,
        "axes.titlecolor": INK,
        "axes.titlesize": 10,
        "axes.labelsize": 9,
        "xtick.color": MUTED,
        "ytick.color": MUTED,
        "xtick.labelsize": 8,
        "ytick.labelsize": 8,
        "text.color": INK,
        "axes.grid": True,
        "grid.color": GRID,
        "grid.linewidth": 0.6,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "legend.frameon": False,
        "legend.fontsize": 8,
        "lines.linewidth": 1.4,
        "font.size": 9,
    }
)


def _window_color(i):
    return BASELINE_COLOR if i == 0 else BLOCK_RAMP[min(i - 1, len(BLOCK_RAMP) - 1)]


def _post_windows(df):
    return [w for w in dict.fromkeys(df.window) if w != "baseline"]


def per_mouse(d, path):
    """Traces with windows shaded, and each spectral measure by window."""
    s, f, sp, wins = d["session"], d["f"], d["spectra"], d["wins"]
    fig, axs = plt.subplots(2, 3, figsize=(14, 7.5), constrained_layout=True)
    fig.suptitle(
        f"{s.mouse} ({s.group}), {s.folder}   injection +{s.injection_min:g} min, "
        f"baseline-only fit slope {d['slope']:.2f}",
        color=INK,
    )

    ax = axs[0, 0]
    t, y, x = d["t_min"], d["y"], d["x"]
    base = (t >= wins[0][1]) & (t < wins[0][2])
    step = max(1, int(round(1 / np.median(np.diff(t * 60)))))  # ~1 sample per s
    for i, (label, a, b) in enumerate(wins):
        ax.axvspan(a, b, color=_window_color(i), alpha=0.12, lw=0)
    ax.plot(t[::step], 100 * y[::step] / y[base].mean(), color=INK, lw=0.6, label="465")
    ax.plot(t[::step], 100 * x[::step] / x[base].mean(), color=MUTED, lw=0.6, label="405")
    ax.axvline(s.injection_min, color=INK2, ls=":", lw=1)
    ax.set_xlabel("time from recording start (min)")
    ax.set_ylabel("% of baseline mean")
    ax.set_title("Raw traces (shaded: analysis windows)")
    ax.legend(loc="lower left")

    panels = [
        (axs[0, 1], "465"),
        (axs[0, 2], "405"),
        (axs[1, 0], "coherence"),
        (axs[1, 1], "465_indep_405"),
        (axs[1, 2], "dff_baseline_fit"),
    ]
    keep = (f >= 0.008) & (f <= 2)
    for ax, meas in panels:
        for i, (label, _, _) in enumerate(wins):
            ax.plot(
                f[keep], sp[label][meas][keep], color=_window_color(i), lw=1.8 if i == 0 else 1.2, label=label
            )
        ax.set_xscale("log")
        if meas == "coherence":
            ax.set_ylim(0, 1)
            ax.set_ylabel("coherence")
        else:
            ax.set_yscale("log")
            ax.set_ylabel("PSD (%²/Hz)")
        ax.set_xlabel("frequency (Hz)")
        ax.set_title(TITLES[meas])
    axs[0, 1].legend(loc="lower left", title="window (from injection)", title_fontsize=8)
    fig.savefig(path, dpi=110)
    plt.close(fig)


def spectral_change(bins, measures, path):
    """log2(post / baseline) vs. frequency: rows = measure, columns = post block."""
    posts = _post_windows(bins)
    fig, axs = plt.subplots(
        len(measures),
        len(posts),
        figsize=(3.4 * len(posts), 2.5 * len(measures)),
        sharex=True,
        sharey=True,
        constrained_layout=True,
    )
    for r, meas in enumerate(measures):
        for c, w in enumerate(posts):
            ax = axs[r, c]
            sub = bins[(bins.measure == meas) & (bins.window == w)]
            for group, col in GROUP_COLOR.items():
                g = sub[sub.group == group]
                for _, m in g.groupby("mouse"):
                    ax.plot(m.f_hz, m.change_vs_baseline, color=col, lw=0.7, alpha=0.35)
                mean = g.groupby("f_hz").change_vs_baseline.mean()
                n = g.mouse.nunique()
                ax.plot(mean.index, mean.values, color=col, lw=2, label=f"{group} mean (n={n})")
            ax.axhline(0, color=INK2, lw=0.8)
            ax.axvline(1.0, color=MUTED, lw=0.8, ls=":")
            ax.set_xscale("log")
            ax.set_ylim(-3, 3)
            if r == 0:
                ax.set_title(f"{w} after injection", color=INK)
            if c == 0:
                ax.set_ylabel(f"{TITLES[meas]}\nlog2 change vs. baseline", fontsize=8)
            if r == len(measures) - 1:
                ax.set_xlabel("frequency (Hz)")
    axs[0, 0].legend(loc="lower left")
    fig.suptitle(
        "Spectral change after injection (thin: individual mice; dotted: ~1 Hz upper limit of NE content)"
    )
    fig.savefig(path, dpi=110)
    plt.close(fig)


def band_change(bands, measures, path):
    """Band-power change per mouse and block: rows = measure, columns = band."""
    posts = _post_windows(bands)
    band_list = list(dict.fromkeys(bands.band))
    fig, axs = plt.subplots(
        len(measures),
        len(band_list),
        figsize=(4 * len(band_list), 2.5 * len(measures)),
        sharex=True,
        sharey=True,
        constrained_layout=True,
    )
    xs = np.arange(len(posts))
    for r, meas in enumerate(measures):
        for c, band in enumerate(band_list):
            ax = axs[r, c]
            sub = bands[(bands.measure == meas) & (bands.band == band) & (bands.window != "baseline")]
            for k, (group, col) in enumerate(GROUP_COLOR.items()):
                g = sub[sub.group == group]
                off = -0.12 if k == 0 else 0.12
                for _, m in g.groupby("mouse"):
                    v = m.set_index("window").change_vs_baseline.reindex(posts).values
                    ax.plot(xs + off, v, "o", ms=4.5, color=col, mec=SURFACE, mew=0.8, alpha=0.85)
                mean = g.groupby("window").change_vs_baseline.mean().reindex(posts).values
                ax.plot(xs + off, mean, "-", color=col, lw=2, label=f"{group} mean (n={g.mouse.nunique()})")
            ax.axhline(0, color=INK2, lw=0.8)
            ax.set_xticks(xs, [p.replace(" min", "") for p in posts])
            if r == 0:
                ax.set_title(band)
            if c == 0:
                ax.set_ylabel(f"{TITLES[meas]}\nlog2 change vs. baseline", fontsize=8)
            if r == len(measures) - 1:
                ax.set_xlabel("minutes after injection")
    axs[0, 0].legend(loc="lower left")
    fig.suptitle("Band power after injection vs. each mouse's baseline (dots: mice)")
    fig.savefig(path, dpi=110)
    plt.close(fig)


def coherence_summary(bins, path):
    """Group-mean 465-405 coherence by window."""
    groups = list(GROUP_COLOR)
    fig, axs = plt.subplots(1, len(groups), figsize=(10, 3.6), sharey=True, constrained_layout=True)
    sub = bins[bins.measure == "coherence"]
    wins = list(dict.fromkeys(sub.window))
    for ax, group in zip(axs, groups):
        g = sub[sub.group == group]
        for i, w in enumerate(wins):
            mean = g[g.window == w].groupby("f_hz").value.mean()
            ax.plot(mean.index, mean.values, color=_window_color(i), lw=1.8 if i == 0 else 1.2, label=w)
        ax.set_xscale("log")
        ax.set_ylim(0, 1)
        ax.set_xlabel("frequency (Hz)")
        ax.set_title(f"{group} (n={g.mouse.nunique()})")
    axs[0].set_ylabel("465–405 coherence (group mean)")
    axs[0].legend(loc="lower left", title="window (from injection)", title_fontsize=8)
    fig.suptitle("How much of the 465 signal moves with 405")
    fig.savefig(path, dpi=110)
    plt.close(fig)
