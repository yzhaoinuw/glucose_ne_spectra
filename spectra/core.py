"""Spectral measures that don't depend on a single 405 -> 465 fit.

For each window we compute:
  * the 465 and 405 power spectra, each as % of its own window mean
  * the magnitude-squared coherence between 465 and 405
  * the 405-independent part of the 465 spectrum, P465 * (1 - coherence):
    the 465 power that 405 can't predict at that frequency. This is a
    frequency-domain regression, so the 405 weight is free at every
    frequency instead of being one slope for the whole recording.
And, as a cross-check, the spectrum of a dF/F made with a robust fit on the
pre-injection baseline only.
"""

import numpy as np
from scipy import signal
import statsmodels.api as sm

SEG_S = 120.0  # Welch segment: ~0.008 Hz resolution, ~25 segments per hour
BANDS = [(0.01, 0.05), (0.05, 0.2), (0.2, 1.0)]  # Hz


def pct_of_mean(x):
    """x as % deviation from its mean."""
    m = np.mean(x)
    return 100.0 * (x - m) / m


def _welch_args(fs, seg_s):
    n = int(round(seg_s * fs))
    return dict(fs=fs, window="hann", nperseg=n, noverlap=n // 2, detrend="linear")


def psd(x, fs, seg_s=SEG_S):
    """Welch PSD with a linear detrend inside each segment."""
    return signal.welch(x, **_welch_args(fs, seg_s))


def coherence(x, y, fs, seg_s=SEG_S):
    """Magnitude-squared coherence, same segments as psd()."""
    return signal.coherence(x, y, **_welch_args(fs, seg_s))


def band_power(f, p, lo, hi):
    """Integrated power in [lo, hi) Hz."""
    m = (f >= lo) & (f < hi)
    return np.trapezoid(p[m], f[m])


def robust_fit(x, y):
    """Bisquare robust linear fit y ~ slope * x + intercept (as in the MATLAB v2)."""
    res = sm.RLM(y, sm.add_constant(x), M=sm.robust.norms.TukeyBiweight()).fit()
    intercept, slope = res.params
    return slope, intercept


def baseline_fit_dff(y465, x405, fs, fit_mask, smooth_s=1.0):
    """dF/F (%) with the 405 fit learned on fit_mask only; control smoothed as in v2."""
    slope, intercept = robust_fit(x405[fit_mask], y465[fit_mask])
    w = max(1, int(round(smooth_s * fs)))
    control = signal.filtfilt(np.ones(w) / w, [1.0], slope * x405 + intercept)
    return 100.0 * (y465 - control) / control, slope, intercept


def _pct_detrend(seg):
    """Linear detrend of each segment, as % of that segment's mean."""
    return 100.0 * signal.detrend(seg, type="linear", axis=-1) / np.mean(seg, axis=-1, keepdims=True)


def spectrogram(x, fs, seg_s=SEG_S, step_s=60.0):
    """Time-frequency PSD (%²/Hz): Welch-style Hann segments, each detrended and
    scaled to % of its own mean. Returns f, segment-centre times (s), S[f, t]."""
    n, hop = int(round(seg_s * fs)), int(round(step_s * fs))
    return signal.spectrogram(
        x, fs=fs, window="hann", nperseg=n, noverlap=n - hop, detrend=_pct_detrend, scaling="density"
    )


def sliding_coherence(y, x, fs, win_s=1200.0, step_s=300.0, seg_s=SEG_S):
    """465-405 coherence in sliding windows. Returns f, window-centre times (s), C[f, t]."""
    n, hop = int(round(win_s * fs)), int(round(step_s * fs))
    starts = range(0, y.size - n + 1, hop)
    f = None
    cols = []
    for s in starts:
        f, c = coherence(y[s : s + n], x[s : s + n], fs, seg_s)
        cols.append(c)
    t = np.array([(s + n / 2) / fs for s in starts])
    return f, t, np.array(cols).T


def log_bin_edges(df, f_hi, per_decade=24):
    """Contiguous log-spaced bin edges from df/2 to f_hi, each at least df wide,
    so every bin holds at least one frequency of a grid with spacing df."""
    ratio = 10 ** (1 / per_decade)
    edges = [df / 2]
    while edges[-1] < f_hi:
        edges.append(min(max(edges[-1] * ratio, edges[-1] + df), f_hi))
    return np.array(edges)


def log_bin_rows(f, a, edges):
    """Mean of a's rows (frequency axis 0) within each bin of edges."""
    idx = np.digitize(f, edges) - 1
    return np.array([a[idx == i].mean(axis=0) for i in range(len(edges) - 1)])


def window_spectra(y465, x405, dff, fs, seg_s=SEG_S):
    """All spectral measures for one window. Returns f and a dict of arrays."""
    f, p465 = psd(pct_of_mean(y465), fs, seg_s)
    _, p405 = psd(pct_of_mean(x405), fs, seg_s)
    _, coh = coherence(y465, x405, fs, seg_s)
    _, pdff = psd(dff, fs, seg_s)
    return f, {
        "465": p465,
        "405": p405,
        "coherence": coh,
        "465_indep_405": p465 * (1.0 - coh),
        "dff_baseline_fit": pdff,
    }
