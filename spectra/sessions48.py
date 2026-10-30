"""The 48-h study's mouse-sessions and their first-~6-h analysis windows.

Sessions and injection times come from the extraction's summary.csv
(extraction/recordings48.m, from the lab journal), so there is one source.

Windows match the 5-h study's post-injection blocks, so the two studies can be
compared block by block. The baseline is the last hour before the injection,
not the full ~2 h: the first hour may still hold the settling-in after hookup,
and one hour matches the 5-h study's baseline length.
"""

from dataclasses import dataclass
from pathlib import Path

import pandas as pd

from .sessions import BASELINE_END_BEFORE_INJ_MIN, BLOCK_MIN, POST_SKIP_MIN, Session

BASELINE_MIN = 60.0
LAST_BLOCK_END_MIN = 240.0  # 5-h study: its last block runs to the 5-h mark, ~4 h after the injection

# Baseline end, rig wall clock, where the journal injection time is in doubt.
# COM9 glucose: the journal says 11:30, but its signal changes at 11:10 (when its
# tank-mate COM10 was injected) and not at 11:30. Ending the baseline at 11:07
# is safe under either reading. Asked the experimenter (question 8).
BASELINE_END_CLOCK = {"COM9_glucose": "11:07"}

# Pairs side by side (glucose, saline), then the saline-only mice.
ORDER = ["COM9", "COM10", "COM14", "COM15", "COM16", "COM18", "COM12", "COM13"]


@dataclass(frozen=True)
class Session48(Session):
    animal: str = ""
    sex: str = ""
    baseline_end_min: float | None = None  # None: BASELINE_END_BEFORE_INJ_MIN before the injection


def load_sessions(in_dir):
    """Session48 records from <in_dir>/summary.csv, in ORDER (glucose before saline)."""
    df = pd.read_csv(Path(in_dir) / "summary.csv")
    bad = df[df.status != "ok"]
    if len(bad):
        raise ValueError(f"extraction failed for: {', '.join(bad.name)}")
    df["rank"] = df.mouse.map(ORDER.index) * 2 + (df.condition == "saline")
    out = []
    for r in df.sort_values("rank").itertuples():
        base_end = None
        if r.name in BASELINE_END_CLOCK:
            start = pd.Timestamp(r.rig_start)
            clock = pd.Timestamp(f"{start:%Y-%m-%d} {BASELINE_END_CLOCK[r.name]}")
            base_end = (clock - start).total_seconds() / 60.0
        out.append(
            Session48(
                folder=r.name,
                mouse=f"{r.mouse} {r.condition[:3]}",
                group=r.condition,
                injection_min=float(r.inj_min),
                animal=r.mouse,
                sex=r.sex,
                baseline_end_min=base_end,
            )
        )
    return out


def windows48(session, end_min):
    """Analysis windows as (label, start_min, stop_min) from recording start:
    the hour before the injection, then the 5-h study's post-injection blocks."""
    inj = session.injection_min
    base_end = session.baseline_end_min
    if base_end is None:
        base_end = inj - BASELINE_END_BEFORE_INJ_MIN
    out = [("baseline", base_end - BASELINE_MIN, base_end)]
    start = POST_SKIP_MIN
    while start < LAST_BLOCK_END_MIN:
        stop = min(start + BLOCK_MIN, LAST_BLOCK_END_MIN)
        if inj + stop > end_min:
            raise ValueError(f"{session.folder}: recording ends before +{stop:g} min")
        out.append((f"+{start:.0f}-{stop:.0f} min", inj + start, inj + stop))
        start = stop
    return out
