import numpy as np
import pytest

from spectra import core
from spectra.sessions import SESSIONS, windows

FS = 20.0


def _noise(n, seed):
    return np.random.default_rng(seed).standard_normal(n)


def test_psd_peak_at_sine_frequency():
    t = np.arange(int(3600 * FS)) / FS
    x = 100 + np.sin(2 * np.pi * 0.05 * t) + 0.1 * _noise(t.size, 0)
    f, p = core.psd(core.pct_of_mean(x), FS)
    assert f[np.argmax(p)] == pytest.approx(0.05, abs=0.01)


def test_band_power_matches_variance_of_band_limited_signal():
    t = np.arange(int(3600 * FS)) / FS
    x = np.sin(2 * np.pi * 0.1 * t)  # variance 0.5, all in the 0.05-0.2 band
    f, p = core.psd(x, FS)
    assert core.band_power(f, p, 0.05, 0.2) == pytest.approx(0.5, rel=0.05)


def test_independent_part_removes_shared_405_component():
    n = int(3600 * FS)
    shared, own = _noise(n, 1), _noise(n, 2)
    x405 = 200 + shared
    y465 = 300 + 1.5 * shared + own  # 465 = scaled 405 artifact + its own signal
    f, sp = core.window_spectra(y465, x405, np.zeros(n), FS)
    m = (f > 0.05) & (f < 1)
    # what's left should be the 465-only power, expressed as % of the 465 mean
    expected = core.psd(100 * own / 300, FS)[1]
    assert np.median(sp["465_indep_405"][m] / expected[m]) == pytest.approx(1, rel=0.15)
    assert np.median(sp["coherence"][m]) == pytest.approx(2.25 / 3.25, abs=0.05)


def test_baseline_fit_recovers_slope_despite_later_rise():
    n = int(3 * 3600 * FS)
    t_min = np.arange(n) / FS / 60
    x = 200 - 0.05 * t_min + _noise(n, 3)  # bleaching control
    y = 1.5 * x + 10 + 0.3 * _noise(n, 4)
    y = y + np.where(t_min > 60, 30.0, 0.0)  # post-injection rise the fit must not see
    dff, slope, _ = core.baseline_fit_dff(y, x, FS, t_min < 55)
    assert slope == pytest.approx(1.5, rel=0.02)
    assert abs(np.mean(dff[t_min < 55])) < 0.5


def test_windows_cover_baseline_and_four_post_blocks():
    for s in SESSIONS:
        wins = windows(s, 300.0)
        assert wins[0][0] == "baseline"
        assert wins[0][2] < s.injection_min
        assert wins[1][1] == pytest.approx(s.injection_min + 20)
        assert len(wins) == 5
        assert all(b - a >= 30 for _, a, b in wins)
