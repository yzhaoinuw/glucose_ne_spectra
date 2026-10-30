import pandas as pd
import pytest

from spectra.sessions48 import load_sessions, windows48


def _summary(tmp_path, rows):
    cols = ["name", "mouse", "sex", "condition", "rig_start", "inj_min", "status"]
    pd.DataFrame(rows, columns=cols).to_csv(tmp_path / "summary.csv", index=False)
    return load_sessions(tmp_path)


def test_windows_last_hour_baseline_and_5h_study_blocks(tmp_path):
    (s,) = _summary(
        tmp_path, [["COM14_glucose", "COM14", "female", "glucose", "2024-06-03 09:05:40", 120.0, "ok"]]
    )
    wins = windows48(s, end_min=48 * 60)
    assert wins[0] == ("baseline", 57.0, 117.0)
    assert [w[0] for w in wins[1:]] == ["+20-80 min", "+80-140 min", "+140-200 min", "+200-240 min"]
    assert wins[1][1:] == (140.0, 200.0) and wins[-1][1:] == (320.0, 360.0)


def test_com9_glucose_baseline_ends_at_11_07_rig_clock(tmp_path):
    (s,) = _summary(
        tmp_path, [["COM9_glucose", "COM9", "male", "glucose", "2024-05-08 09:05:58", 144.0333, "ok"]]
    )
    base = windows48(s, end_min=48 * 60)[0]
    assert base[2] == pytest.approx(121.0 + 2 / 60)  # 11:07:00 - 09:05:58
    assert base[2] - base[1] == pytest.approx(60.0)


def test_sessions_ordered_as_pairs_and_unique_labels(tmp_path):
    rows = [
        ["COM9_saline", "COM9", "male", "saline", "2024-05-29 08:59:43", 121.3, "ok"],
        ["COM12_saline", "COM12", "male", "saline", "2024-05-29 08:59:33", 123.5, "ok"],
        ["COM9_glucose", "COM9", "male", "glucose", "2024-05-08 09:05:58", 144.0, "ok"],
    ]
    ss = _summary(tmp_path, rows)
    assert [s.folder for s in ss] == ["COM9_glucose", "COM9_saline", "COM12_saline"]
    assert len({s.mouse for s in ss}) == 3


def test_failed_extraction_is_refused(tmp_path):
    with pytest.raises(ValueError, match="COM16_glucose"):
        _summary(
            tmp_path,
            [["COM16_glucose", "COM16", "female", "glucose", "2024-06-03 09:06:55", 118.1, "FAILED"]],
        )
