# When is the NE level vs. slow-fluctuation correlation strongest? 13-h study (temporary note)

*2026-11-02. Code: `spectra/window_scan.py` (`python -m spectra.window_scan`); the commit is named in [`provenance.txt`](../results/window_scan_13h/provenance.txt). Results: [`results/window_scan_13h/`](../results/window_scan_13h/). A short working note for the PI's question after the draft figure; to be folded into a later 13-h report.*

## Question

Panel G of the draft figure correlates, across the 9 mice of the 13-h study, the NE level change after the injection with the change in slow NE fluctuations, both over +20–140 min. The PI asked at which time after the injection this correlation is most prominent, as an alternative to splitting the mice into responders and non-responders.

## What was tried

The measures are the same as panel G, each vs. the mouse's own baseline (5 min after the start to 3 min before the injection):

- **NE level:** mean raw 465, % change.
- **Slow fluctuations:** 0.01–0.05 Hz power of the 465 not shared with 405, log2 change.

1. **Sliding windows across mice.** Windows of 20, 30 and 60 min, moved in 5-min steps from +20 min (after the handling period) to the end of the recordings (~+240 min). In each window: Pearson r across all 9 mice and across the 6 glucose mice, with a 95% confidence interval, plus Spearman's rank correlation.
2. **A dip-free NE level.** The ~1-min NE dips pull the mean level down, so a mouse with fewer dips would show a higher level and less slow power by arithmetic alone. As a check, the NE level was also measured as the 90th percentile of 10-s means, which ignores the dips.
3. **Within each mouse over time.** Non-overlapping 20-min windows, 2 before the injection (inside the baseline) and 10–11 after (from +20 min), correlated within each mouse.
4. **Robustness of the panel G window.** Leaving out each mouse in turn, and the most extreme mice.

![Correlation over time](../results/window_scan_13h/correlation_over_time.png)

*Figure 1. A, B: r across mice for 60- and 30-min windows, plotted at the window centre. Black: all 9 mice, with its 95% CI (grey band); orange: the 6 glucose mice; dashed: all 9 with the dip-free NE level; diamond: the panel G window (+20–140 min as one window). Grey at left: the 20-min handling period, not used. C: each mouse's 20-min windows, with its own fitted line (orange: glucose, blue: saline).*

## Findings

- **No single window stands out. The correlation is strong at every time point.** Across all 9 mice, r ranges from −0.86 to −0.96 for 60-min windows, −0.81 to −0.96 for 30-min and −0.75 to −0.96 for 20-min (`scan_correlation.csv`). It is slightly strongest in the first hour (60-min window +20–80 min: r = −0.96) and slightly weakest around +2 to +2.5 h (window centres ~+120–150 min). These differences are well inside the uncertainty: with 9 mice, the 95% CI around r = −0.9 runs from about −0.6 to −0.98.
- **The panel G window is close to the best: r = −0.93** (−0.91 for the 6 glucose mice alone). Leaving out any one mouse gives −0.91 to −0.98. Without the 3 responders (#5, FP1, FP2), r is still −0.88 over the remaining 6 mice, so the relation is not only the responders against everyone else.
- **The dips don't explain it.** With the dip-free NE level, the correlation is as strong or stronger: −0.85 to −0.98 for 60-min windows, −0.98 in the panel G window.
- **Within each glucose mouse, the same relation holds over time.** Stretches with a higher NE level have less slow-fluctuation power: r = −0.66 to −0.88 in all 6 glucose mice (`within_mouse_r.csv`). This includes the poor responders. In #22, for example, NE falls and slow power rises.
- **Within saline mice it is weaker:** r = −0.29 (#2), −0.47 (#1), −0.66 (#33). Their NE level hardly moves (−7% to +0.5%), so there is little range in which to see a relation.

## Interpretation

The across-mouse correlation looks less like a property of one time window than like a coupling between NE level and slow NE fluctuations, which glucose responders move along the furthest. A possible reading is sleep vs. wake. In the literature, ~1-min NE oscillations are a feature of NREM sleep, and NE is higher during wake. On that reading, responders would sleep less after glucose. There is no EEG/EMG here to test this.

## Caveats

- **9 mice (6 glucose, 3 saline), descriptive.** Overlapping windows are not independent, and picking the strongest of many windows overstates it, so this note reports the range and the time course, not a best window.
- **Correlation, not direction.** The data don't show that high NE suppresses the oscillations, only that the two go together.
- **The NE level is raw 465.** It includes the slow bleaching of the signal over the session (405 falls 15–20% over the 5 h). A sensible 405 → 465 fit, the next planned analysis, would change the level axis, more so late in the session. This note should be redone with it.
- **Same baseline for both axes.** Both measures are changes vs. the same baseline window, so noise in a mouse's baseline moves both. The within-mouse result and the dip-free check argue against this being the main driver, but don't rule it out.
- **First pass of the within-mouse view.** A first version included the 0–20-min handling period. That made the saline mice look as strongly coupled as the glucose mice (r ≈ −0.7 to −0.8). Without it, saline is weaker, as reported above.

## Next

- Redo with the 405 → 465 fit, once one is chosen (separate 13-h analysis).
- If the time course goes into a figure, show panel A (or B) rather than a single best window.
