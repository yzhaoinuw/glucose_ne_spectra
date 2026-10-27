"""The 9 cohort sessions and the analysis windows.

Injection times are minutes from recording start, from the experimenter's
notebook (session table in questions_for_experimenters.md).
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class Session:
    folder: str
    mouse: str
    group: str  # "glucose" or "saline"
    injection_min: float


SESSIONS = [
    Session("Subject3-240322-092543_morning", "#3", "glucose", 62.2),
    Session("FiberPhot4_260324_morning", "#4", "glucose", 60.6),
    Session("Subject5-240326-090337_morning", "#5", "glucose", 59.4),
    Session("FiberPhot22_240324_morning", "#22", "glucose", 58.9),
    Session("FP1_glucose_13hours_090424", "FP1", "glucose", 66.5),
    Session("FP2_glucose_13hours_100424", "FP2", "glucose", 59.9),
    Session("Subject1-240323-091543_morning", "#1", "saline", 60.2),
    Session("Subject2-240321-093251_210324", "#2", "saline", 60.1),
    Session("Subject33-240324-093611_morning", "#33", "saline", 60.8),
]

# Baseline: skip the start-up transient, stop before the mouse is taken out of
# the cage (the legacy out-of-cage times are 0-2 min before the injection).
BASELINE_START_MIN = 5.0
BASELINE_END_BEFORE_INJ_MIN = 3.0

# Post-injection: skip the handling spike, then fixed-length blocks.
POST_SKIP_MIN = 20.0
BLOCK_MIN = 60.0
MIN_BLOCK_MIN = 30.0  # drop a trailing partial block shorter than this


def windows(session, end_min):
    """Analysis windows as (label, start_min, stop_min), from recording start.

    Post-injection labels give minutes since the injection.
    """
    inj = session.injection_min
    out = [("baseline", BASELINE_START_MIN, inj - BASELINE_END_BEFORE_INJ_MIN)]
    start = POST_SKIP_MIN
    while True:
        stop = min(start + BLOCK_MIN, end_min - inj)
        if stop - start < MIN_BLOCK_MIN:
            break
        # A trailing partial block is labelled "-end" so labels match across mice.
        full = stop - start >= BLOCK_MIN - 1e-9
        label = f"+{start:.0f}-{start + BLOCK_MIN:.0f} min" if full else f"+{start:.0f} min-end"
        out.append((label, inj + start, inj + stop))
        start += BLOCK_MIN
    return out
