"""Figures for the first-5-h spectral comparison (static PNGs)."""

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib import patheffects  # noqa: E402
import numpy as np  # noqa: E402

# Reference palette (dataviz skill, light mode).
SURFACE, INK, INK2, MUTED, GRID, AXIS = "#fcfcfb", "#0b0b0b", "#52514e", "#898781", "#e1e0d9", "#c3c2b7"
GROUP_COLOR = {"glucose": "#2a78d6", "saline": "#eb6834"}  # categorical slots 1, 2
BLOCK_RAMP = ["#86b6ef", "#3987e5", "#1c5cab", "#0d366b"]  # ordinal blue, post blocks in time order
BASELINE_COLOR = INK2
TITLES = {
    "465": "465 (NE sensor)",
    "405": "405 (isosbestic control)",
    "465_indep_405": "465, part not shared with 405",
    "dff_baseline_fit": "ΔF/F, baseline-only fit (cross-check)",
    "coherence": "465–405 coherence",
}
# Set by the runner for non-PFC runs; stamped in the top-left corner of every figure.
FIBER_LABEL = ""

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


def _save(fig, path):
    if FIBER_LABEL:
        fig.text(0.005, 0.995, FIBER_LABEL, ha="left", va="top", fontsize=9, fontweight="bold", color=INK)
    fig.savefig(path, dpi=110)


def _grid(n):
    """Columns and rows for n small panels: 3 wide up to 9, else 4 wide."""
    ncols = 3 if n <= 9 else 4
    return ncols, -(-n // ncols)


def _window_color(i):
    return BASELINE_COLOR if i == 0 else BLOCK_RAMP[min(i - 1, len(BLOCK_RAMP) - 1)]


def _post_windows(df):
    return [w for w in dict.fromkeys(df.window) if w != "baseline"]


def per_mouse(d, path):
    """Traces with windows shaded, and each spectral measure by window."""
    s, f, sp, wins = d["session"], d["f"], d["spectra"], d["wins"]
    fig, axs = plt.subplots(2, 3, figsize=(14, 7.5), constrained_layout=True)
    fig.suptitle(
        f"{s.mouse} ({s.group}), {s.folder}   injection +{s.injection_min:.1f} min, "
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
    _save(fig, path)
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
    _save(fig, path)
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
    _save(fig, path)
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
    _save(fig, path)
    plt.close(fig)


SPECTROGRAM_CMAP = "viridis"  # user's choice for the time-frequency panels
ANALYSIS_RANGE = (0.01, 1.0)  # Hz
BAND_EDGES = (0.05, 0.2)  # Hz, inner edges of the three bands
F_PLOT = (0.008, 10.2)


def _stroked():
    """Light line with a dark outline, visible on both ends of the colour ramp."""
    return [patheffects.withStroke(linewidth=2.6, foreground=INK)]


def _mark_range(ax, vertical=False):
    """Shade the analysed range and dot the band edges on a frequency axis."""
    span, line = (ax.axhspan, ax.axhline) if vertical else (ax.axvspan, ax.axvline)
    span(*ANALYSIS_RANGE, color=GRID, alpha=0.45, lw=0, zorder=0)
    for e in BAND_EDGES:
        line(e, color=MUTED, lw=0.8, ls=":", zorder=1)


def _tf_panel(ax, t_min, edges, z, title, s, wins, **kw):
    dt = np.diff(t_min)
    t_edges = np.r_[t_min[0] - dt[0] / 2, t_min[:-1] + dt / 2, t_min[-1] + dt[-1] / 2]
    mesh = ax.pcolormesh(t_edges, edges, z, shading="flat", rasterized=True, **kw)
    ax.set_yscale("log")
    ax.set_ylim(*F_PLOT)
    ax.set_ylabel("frequency (Hz)")
    ax.set_title(title, loc="left")
    ax.grid(False)
    eff = _stroked()
    ax.axvline(s.injection_min, color=SURFACE, lw=1.2, path_effects=eff)
    ax.axvline(wins[0][1], color=SURFACE, lw=0.8, ls="--", path_effects=eff)
    ax.axvline(wins[0][2], color=SURFACE, lw=0.8, ls="--", path_effects=eff)
    ax.axvline(wins[1][1], color=SURFACE, lw=0.8, ls="--", path_effects=eff)
    for f0 in ANALYSIS_RANGE:
        ax.axhline(f0, color=SURFACE, lw=0.9, ls=(0, (4, 3)), path_effects=eff)
    return mesh


def full_band(d, path):
    """Whole-recording view up to ~10 Hz: 465 and 405 spectrograms, sliding
    465-405 coherence, and the baseline spectra and coherence."""
    s, wins, fb = d["session"], d["wins"], d["full_band"]
    f, base = d["f"], d["spectra"]["baseline"]
    fig = plt.figure(figsize=(14, 9.2), constrained_layout=True)
    gs = fig.add_gridspec(3, 3, width_ratios=[3.2, 0.09, 1.5])
    fig.suptitle(
        f"{s.mouse} ({s.group}), {s.folder}: full band to ~10 Hz "
        "(vertical: baseline, injection, end of 20-min skip; horizontal: 0.01 and 1 Hz)",
        color=INK,
    )
    lp = np.log10(np.concatenate([fb["s465"].ravel(), fb["s405"].ravel()]))
    vmin, vmax = np.percentile(lp, [1, 99.5])
    axs = [fig.add_subplot(gs[i, 0]) for i in range(3)]
    for ax, key, title in [(axs[0], "s465", "465 (NE sensor)"), (axs[1], "s405", "405 (isosbestic control)")]:
        mesh = _tf_panel(
            ax,
            fb["t_min"],
            fb["edges"],
            np.log10(fb[key]),
            title,
            s,
            wins,
            cmap=SPECTROGRAM_CMAP,
            vmin=vmin,
            vmax=vmax,
        )
    cb = fig.colorbar(mesh, cax=fig.add_subplot(gs[0:2, 1]))
    cb.set_label("log10 PSD (%²/Hz)", color=INK2)
    cb.outline.set_visible(False)
    mesh = _tf_panel(
        axs[2],
        fb["tc_min"],
        fb["edges"],
        fb["coh"],
        "465–405 coherence (20-min windows, 5-min steps)",
        s,
        wins,
        cmap=SPECTROGRAM_CMAP,
        vmin=0,
        vmax=1,
    )
    axs[2].set_xlabel("time from recording start (min)")
    for ax in axs:
        ax.set_xlim(fb["t_min"][0] - 1, fb["t_min"][-1] + 1)
    cb = fig.colorbar(mesh, cax=fig.add_subplot(gs[2, 1]))
    cb.set_label("coherence", color=INK2)
    cb.outline.set_visible(False)

    keep = (f >= F_PLOT[0]) & (f <= F_PLOT[1])
    ax = fig.add_subplot(gs[0:2, 2])
    _mark_range(ax)
    ax.plot(f[keep], base["465"][keep], color=INK, lw=1.2, label="465")
    ax.plot(f[keep], base["405"][keep], color=MUTED, lw=1.2, label="405")
    ax.plot(f[keep], base["465_indep_405"][keep], color=INK, lw=1.0, ls="--", label="465 not shared with 405")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlim(*F_PLOT)
    ax.set_ylabel("PSD (%²/Hz)")
    ax.set_title("Baseline spectra (shaded: 0.01–1 Hz)", loc="left")
    ax.legend(loc="lower left")
    ax = fig.add_subplot(gs[2, 2], sharex=ax)
    _mark_range(ax)
    ax.plot(f[keep], base["coherence"][keep], color=INK, lw=1.2)
    ax.set_ylim(0, 1)
    ax.set_xlabel("frequency (Hz)")
    ax.set_ylabel("coherence")
    ax.set_title("Baseline 465–405 coherence", loc="left")
    _save(fig, path)
    plt.close(fig)


def full_band_summary(full, path):
    """Baseline 465 and 405 spectra per mouse to ~10 Hz, and every mouse's coherence."""
    mice = list(dict.fromkeys(full.mouse))
    ncols, nrows = _grid(len(mice))
    fig = plt.figure(figsize=(13 if ncols == 3 else 17, 3 * nrows + 3), constrained_layout=True)
    gs = fig.add_gridspec(nrows + 1, ncols, height_ratios=[1] * nrows + [1.15])
    first = None
    for i, mouse in enumerate(mice):
        ax = fig.add_subplot(gs[i // ncols, i % ncols], sharex=first, sharey=first)
        first = first or ax
        m = full[full.mouse == mouse]
        _mark_range(ax)
        for meas, col, ls, lab in [
            ("465", INK, "-", "465"),
            ("405", MUTED, "-", "405"),
            ("465_indep_405", INK, "--", "465 not shared with 405"),
        ]:
            g = m[m.measure == meas]
            ax.plot(g.f_hz, g.value, color=col, ls=ls, lw=1.2 if ls == "-" else 1.0, label=lab)
        ax.set_xscale("log")
        ax.set_yscale("log")
        ax.set_xlim(*F_PLOT)
        ax.set_title(f"{mouse} ({m.group.iloc[0]})", loc="left")
        if i % ncols == 0:
            ax.set_ylabel("PSD (%²/Hz)")
        if i == 0:
            ax.legend(loc="lower left")
    ax = fig.add_subplot(gs[nrows, :])
    _mark_range(ax)
    for group, col in GROUP_COLOR.items():
        g = full[(full.measure == "coherence") & (full.group == group)]
        for k, (_, m) in enumerate(g.groupby("mouse", sort=False)):
            n = g.mouse.nunique()
            ax.plot(
                m.f_hz, m.value, color=col, lw=1.2, alpha=0.8, label=f"{group} (n={n})" if k == 0 else None
            )
    ax.set_xscale("log")
    ax.set_xlim(*F_PLOT)
    ax.set_ylim(0, 1)
    ax.set_xlabel("frequency (Hz)")
    ax.set_ylabel("465–405 coherence")
    ax.set_title("Baseline 465–405 coherence, every mouse", loc="left")
    ax.legend(loc="upper right")
    fig.suptitle(
        "Baseline spectra to ~10 Hz (shaded: analysed 0.01–1 Hz; dotted: band edges 0.05 and 0.2 Hz)",
        color=INK,
    )
    _save(fig, path)
    plt.close(fig)


def raw_traces(per_mouse, path, bin_s=10.0, span="first 5 h", fit_label="whole 5 h"):
    """Raw 465 and 405 for every mouse's analysed span, as % of the baseline mean,
    with the analysis windows shaded and the fitted 405 scaling in each title.
    fit_label names the extraction's own fit (fit_coef) in the titles."""
    ncols, nrows = _grid(len(per_mouse))
    fig, axs = plt.subplots(
        nrows, ncols, figsize=(14 if ncols == 3 else 17, 3.17 * nrows), sharex=True, constrained_layout=True
    )
    for ax in axs.flat[len(per_mouse) :]:
        ax.set_visible(False)
    for ax, d in zip(axs.flat, per_mouse.values()):
        s, wins, t, y, x = d["session"], d["wins"], d["t_min"], d["y"], d["x"]
        base = (t >= wins[0][1]) & (t < wins[0][2])
        n = max(1, int(round(bin_s / np.median(np.diff(t * 60)))))
        k = (t.size // n) * n
        tb = t[:k].reshape(-1, n).mean(axis=1)
        for i, (_, a, b) in enumerate(wins):
            ax.axvspan(a, b, color=_window_color(i), alpha=0.12, lw=0)
        for sig, col, lab in [(y, INK, "465 (NE sensor)"), (x, MUTED, "405 (control)")]:
            yb = sig[:k].reshape(-1, n).mean(axis=1)
            ax.plot(tb, 100 * yb / sig[base].mean(), color=col, lw=0.8, label=lab)
        ax.axhline(100, color=INK2, lw=0.6)
        ax.axvline(s.injection_min, color=INK2, ls=":", lw=1.2)
        ax.set_title(
            f"{s.mouse} ({s.group})\nfitted 405 scaling: {fit_label} {d['whole_slope']:.2f}, "
            f"baseline only {d['slope']:.2f}",
            loc="left",
            fontsize=9,
        )
    for ax in axs[:, 0]:
        ax.set_ylabel("% of baseline mean")
    for ax in axs.flat[max(0, len(per_mouse) - ncols) : len(per_mouse)]:
        ax.set_xlabel("time from recording start (min)")
        ax.xaxis.set_tick_params(labelbottom=True)
    axs[0, 0].legend(loc="lower left")
    fig.suptitle(
        f"Raw signals, {span} (10-s means). Dotted: injection; shaded: baseline (grey) and post-injection blocks (blue)",
        color=INK,
    )
    _save(fig, path)
    plt.close(fig)


def paired_difference(diff, measures, path):
    """Crossover: per mouse, (glucose change) - (saline change) in log2 band power,
    by post-injection block. Below 0: power fell more (or rose less) after glucose."""
    posts = list(dict.fromkeys(diff.window))
    band_list = list(dict.fromkeys(diff.band))
    fig, axs = plt.subplots(
        len(measures),
        len(band_list),
        figsize=(4 * len(band_list), 2.6 * len(measures)),
        sharex=True,
        sharey=True,
        constrained_layout=True,
        squeeze=False,
    )
    xs = np.arange(len(posts))
    for r, meas in enumerate(measures):
        for c, band in enumerate(band_list):
            ax = axs[r, c]
            sub = diff[(diff.measure == meas) & (diff.band == band)]
            for _, m in sub.groupby("animal", sort=False):
                v = m.set_index("window").glucose_minus_saline.reindex(posts).values
                ax.plot(xs, v, "o-", ms=4, lw=0.8, color=MUTED, mec=SURFACE, mew=0.6, alpha=0.9)
            mean = sub.groupby("window").glucose_minus_saline.mean().reindex(posts).values
            n = sub.animal.nunique()
            ax.plot(xs, mean, "-", color=GROUP_COLOR["glucose"], lw=2.2, label=f"mean (n={n} mice)")
            ax.axhline(0, color=INK2, lw=0.8)
            ax.set_xticks(xs, [p.replace(" min", "") for p in posts])
            if r == 0:
                ax.set_title(band)
            if c == 0:
                ax.set_ylabel(f"{TITLES[meas]}\nglucose − saline, log2", fontsize=8)
            if r == len(measures) - 1:
                ax.set_xlabel("minutes after injection")
    axs[0, 0].legend(loc="lower left")
    fig.suptitle("Within mouse: glucose session minus saline session, each vs. its own baseline (grey: mice)")
    _save(fig, path)
    plt.close(fig)
