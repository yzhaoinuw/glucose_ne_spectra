from spectra.manuscript_figures import SPEC_RANGE, log_ticks, range_error


def test_log_ticks_default_range():
    assert log_ticks(*SPEC_RANGE) == [0.01, 0.02, 0.05, 0.1, 0.2]


def test_log_ticks_falls_back_to_ends():
    assert log_ticks(0.3, 0.45) == [0.3, 0.45]


def test_range_error():
    fs = 20.35
    assert range_error(0.01, 1.0, fs) is None
    assert range_error(0.01, fs / 2, fs) is None
    assert "LO < HI" in range_error(0.2, 0.1, fs)
    assert "at least" in range_error(0.001, 0.1, fs)
    assert "Nyquist" in range_error(0.01, 11.0, fs)
