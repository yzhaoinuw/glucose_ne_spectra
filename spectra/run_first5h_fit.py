"""13-h study, first 5 h, with a 405 -> 465 fit whose scaling is learned from the fast band.

The usual fit (one line 465 ~ a * 405 + b, least squares on the raw traces) fails here: over the
whole session it is dominated by 405 bleaching while 465 rises after glucose (scaling too small or
negative), and on the baseline hour by the ~1-min NE dips, which coincide with 405 dips (scaling too
large). Here the scaling is learned where 465 carries little NE: 0.2-1 Hz in the baseline, where
465 and 405 move together. The control is then that scaling applied to the whole 405 trace.

Writes the NE level per block (raw 465 vs. fitted dF/F), the fitted scalings and checks on them,
how the level depends on the scaling, and the band power of the fitted dF/F, to
results/spectra_first5h_fit/ (PFC) or results/spectra_first5h_fit_oc/ (OC).

    python -m spectra.run_first5h_fit [--fiber pfc|oc]
"""

import argparse
from datetime import datetime

import numpy as np
import pandas as pd

from . import core, plots
from .plots import GROUP_COLOR, INK, INK2, MUTED, plt
from .run_first5h import REPO, git_state, load
from .sessions import POST_SKIP_MIN, SESSIONS, windows

FIBERS = {
    "pfc": ("ne_pfc_ds20_first5h", "spectra_first5h_fit"),
    "oc": ("ne_oc_ds20_first5h", "spectra_first5h_fit_oc"),
}
MEASURES = ["dff_fastband_fit", "465_indep_405"]
PANEL_G = (20.0, 140.0)  # min after injection, the draft figure's level window
CHECK_BANDS = [
    (0.1, 1.0),
    (0.5, 1.0),
    (0.01, 0.05),
]  # other fast bands, to check the scaling; and the dip band
GAIN_GRID = np.round(np.arange(0.0, 1.21, 0.05), 2)
BIN_MIN = 1.0

plots.TITLES["dff_fastband_fit"] = "ΔF/F, fast-band fit"


def level_pct(y, ctrl, m, base):
    """NE level in window m vs. baseline, %: mean of 465 / control, relative to the baseline."""
    r = y / ctrl
    return 100.0 * (r[m].mean() / r[base].mean() - 1.0)


def analyse(in_dir):
    fits, levels, sens, band_rows, traces = [], [], [], [], {}
    for s in SESSIONS:
        y, x, fs, t, _ = load(in_dir / f"{s.folder}.mat")
        wins = windows(s, t[-1])
        base = (t >= wins[0][1]) & (t < wins[0][2])
        tt = t - s.injection_min
        post = (tt >= PANEL_G[0]) & (tt < PANEL_G[1])
        dff, gain = core.fast_band_fit_dff(y, x, fs, base)
        ctrl = core.scaled_control(y, x, base, gain)
        y0, x0 = y[base].mean(), x[base].mean()
        fits.append(
            dict(
                mouse=s.mouse,
                group=s.group,
                gain=gain,
                gain_post_20_140=core.fast_band_gain(y[post], x[post], fs),
                **{
                    f"gain_{lo:g}_{hi:g}_hz": core.fast_band_gain(y[base], x[base], fs, lo, hi)
                    for lo, hi in CHECK_BANDS
                },
                slope_raw_units=gain * y0 / x0,
                intercept_raw_units=y0 * (1 - gain),
                drop_405_pct_last_hour=100 * (x[tt >= 180].mean() / x0 - 1),
                drop_465_pct_last_hour=100 * (y[tt >= 180].mean() / y0 - 1),
            )
        )
        named = wins[1:] + [("+20-140 min", s.injection_min + PANEL_G[0], s.injection_min + PANEL_G[1])]
        for label, a, b in named:
            m = (t >= a) & (t < b)
            levels.append(
                dict(
                    mouse=s.mouse,
                    group=s.group,
                    window=label,
                    raw_465_pct=100 * (y[m].mean() / y0 - 1),
                    raw_405_pct=100 * (x[m].mean() / x0 - 1),
                    fitted_pct=level_pct(y, ctrl, m, base),
                )
            )
        for g in GAIN_GRID:
            c = core.scaled_control(y, x, base, g)
            sens.append(
                dict(mouse=s.mouse, group=s.group, gain=g, level_20_140_pct=level_pct(y, c, post, base))
            )
        for label, a, b in wins:
            m = (t >= a) & (t < b)
            f, sp = core.window_spectra(y[m], x[m], dff[m], fs)
            sp["dff_fastband_fit"] = sp.pop("dff_baseline_fit")
            for meas in MEASURES:
                for lo, hi in core.BANDS:
                    band_rows.append(
                        dict(
                            mouse=s.mouse,
                            group=s.group,
                            window=label,
                            measure=meas,
                            band=f"{lo:g}-{hi:g} Hz",
                            value=float(core.band_power(f, sp[meas], lo, hi)),
                        )
                    )
        n = int(round(BIN_MIN * 60 * fs))
        k = (t.size // n) * n
        r = y / ctrl
        traces[s.mouse] = dict(
            session=s,
            t=tt[:k].reshape(-1, n).mean(1),
            raw=100 * (y[:k].reshape(-1, n).mean(1) / y0 - 1),
            fitted=100 * (r[:k].reshape(-1, n).mean(1) / r[base].mean() - 1),
            gain=gain,
        )
        print(f"{s.mouse:>4} {s.group:<7} fast-band scaling {gain:.2f}")

    bands = pd.DataFrame(band_rows)
    ref = bands[bands.window == "baseline"].set_index(["mouse", "measure", "band"]).value
    bands["change_vs_baseline"] = np.log2(
        bands.value.values / ref.loc[list(zip(bands.mouse, bands.measure, bands.band))].values
    )
    return pd.DataFrame(fits), pd.DataFrame(levels), pd.DataFrame(sens), bands, traces


def fig_traces(traces, path):
    """Per mouse: raw 465 and fitted dF/F, both as % vs. baseline, 1-min means."""
    fig, axs = plt.subplots(3, 3, figsize=(13, 8.5), sharex=True, sharey=True, constrained_layout=True)
    for ax, d in zip(axs.flat, traces.values()):
        s = d["session"]
        ax.axvspan(0, POST_SKIP_MIN, color="#e1e0d9", alpha=0.6, lw=0)
        ax.axhline(0, color=INK2, lw=0.6)
        ax.plot(d["t"], d["raw"], color=MUTED, lw=1, label="raw 465")
        ax.plot(d["t"], d["fitted"], color=GROUP_COLOR[s.group], lw=1.3, label="fitted ΔF/F")
        ax.set_title(f"{s.mouse} ({s.group}), scaling {d['gain']:.2f}", fontsize=9)
    for ax in axs[:, 0]:
        ax.set_ylabel("% vs. baseline")
    for ax in axs[-1]:
        ax.set_xlabel("Minutes from injection")
    axs[0, 0].legend(loc="lower left")
    axs[0, 0].set_ylim(-30, 40)
    fig.suptitle("NE level, raw 465 (grey) vs. fast-band-fitted ΔF/F (colour), 1-min means", color=INK)
    fig.savefig(path, dpi=110)
    plt.close(fig)


def fig_sensitivity(sens, fits, path):
    """Level change over +20-140 min vs. the 405 scaling, one line per mouse."""
    fig, ax = plt.subplots(figsize=(6.5, 4.6), constrained_layout=True)
    ax.axhline(0, color=INK2, lw=0.8)
    for mouse, g in sens.groupby("mouse", sort=False):
        c = GROUP_COLOR[g.group.iloc[0]]
        ax.plot(g.gain, g.level_20_140_pct, color=c, lw=1.2)
        fit = fits.set_index("mouse").loc[mouse, "gain"]
        ax.plot(fit, np.interp(fit, g.gain, g.level_20_140_pct), "o", color=c, ms=6)
        ax.annotate(
            mouse,
            (g.gain.iloc[-1], g.level_20_140_pct.iloc[-1]),
            xytext=(4, 0),
            textcoords="offset points",
            fontsize=7.5,
            color=INK2,
            va="center",
        )
    ax.plot([], [], "-o", color=GROUP_COLOR["glucose"], label="glucose mouse")
    ax.plot([], [], "-o", color=GROUP_COLOR["saline"], label="saline mouse")
    ax.legend(loc="upper left")
    ax.set(
        xlabel="405 scaling (% of 465 per 1 % of 405); 0 = raw 465",
        ylabel="NE level change, +20–140 min (%)",
        title="NE level after the injection vs. the 405 scaling\n(dots: each mouse's fast-band scaling)",
        xlim=(0, GAIN_GRID[-1] + 0.12),
    )
    fig.savefig(path, dpi=130)
    plt.close(fig)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--fiber", choices=sorted(FIBERS), default="pfc")
    args = ap.parse_args(argv)
    in_name, out_name = FIBERS[args.fiber]
    in_dir, out = REPO / "outputs" / in_name, REPO / "results" / out_name
    out.mkdir(parents=True, exist_ok=True)

    fits, levels, sens, bands, traces = analyse(in_dir)
    fits.to_csv(out / "fits.csv", index=False)
    levels.to_csv(out / "level.csv", index=False)
    sens.to_csv(out / "scaling_sensitivity.csv", index=False)
    bands.to_csv(out / "band_power.csv", index=False)
    (out / "provenance.txt").write_text(
        f"code commit: {git_state()}\ncreated: {datetime.now():%Y-%m-%d %H:%M:%S}\nfiber: {args.fiber}\n"
        f"input: {in_dir.relative_to(REPO)}\nscript: python -m spectra.run_first5h_fit --fiber {args.fiber}\n"
    )
    fig_traces(traces, out / "level_traces.png")
    fig_sensitivity(sens, fits, out / "scaling_sensitivity.png")
    plots.band_change(bands, MEASURES, out / "band_change.png")

    pd.set_option("display.width", 200)
    print("\nScalings:\n", fits.round(2).to_string(index=False))
    print(
        "\nLevel (%):\n",
        levels.pivot(index="mouse", columns="window", values="fitted_pct").round(1).to_string(),
    )
    print(
        "\nRaw 465 (%):\n",
        levels.pivot(index="mouse", columns="window", values="raw_465_pct").round(1).to_string(),
    )
    post = bands[bands.window.isin(["+20-80 min", "+80-140 min"])]
    print(
        "\nMean log2 change, +20-140:\n",
        post.groupby(["measure", "band", "group"]).change_vs_baseline.mean().unstack().round(2).to_string(),
    )


if __name__ == "__main__":
    main()
