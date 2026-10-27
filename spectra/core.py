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
