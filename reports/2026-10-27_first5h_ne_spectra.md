# PFC norepinephrine spectra after IP glucose vs. saline: first pass

*2026-10-27. Code: `spectra/` at commit `e3030e1`. Results: [`results/spectra_first5h/`](../results/spectra_first5h/).*

## Summary

**Goal.** Find out whether an IP glucose injection changes the frequency content of NE fluctuations in the prefrontal cortex (PFC), compared with saline and with each mouse's own pre-injection baseline. The data are fiber photometry with the GRAB-NE sensor.

**Findings.**

- **Slow NE fluctuations drop after glucose in about half the glucose mice.** In the 0.01–0.05 Hz band (periods of 20–100 s), the 465 power that the 405 control can't explain fell 3–9× for ~2–3 h in 3 of 6 glucose mice (#5, FP1, FP2). It fell briefly in a 4th (#3, first hour only). None of the 3 saline mice showed a drop.
- On average over the first 2 h after the injection, glucose mice lost about half their slow-band power (mean log2 change −1.13, ≈ 0.46×). Saline mice gained slightly (+0.32, ≈ 1.25×).
- **The effect is limited to slow frequencies.** It reaches about 0.1 Hz. From 0.2 to 1 Hz neither group changes.
- **Much of the raw 465 signal is shared with the 405 control** at 0.05–1 Hz (coherence 0.4–0.9 in most mice). An early glucose peak near 0.15 Hz is entirely shared with 405, so it is an artifact or blood-flow signal, not NE.
- This is a descriptive first pass with 6 vs. 3 mice and no statistics. The drop may reflect less sleep after glucose rather than a direct change in NE dynamics (see [Caveats](#caveats)).

## Dataset

The 9 mice of the glucose study have raw PFC signal. Fiber A (465A / 405A) is treated as PFC. The 465 nm channel is GRAB-NE (`hSyn-NE2m`); the 405 nm channel is the isosbestic control. The sampling rate is ~1017 Hz, and the extraction downsampled it to ~20.3 Hz with anti-aliasing. All 9 recordings start ~09:00 in the light phase (lights 07–19). Only **the first 5 h** of each are used: ~1 h of baseline, the injection, and ~4 h after.

| Mouse | Group | Dose (mL) | Injection (min into recording) | Recording | Raw source |
|---|---|---|---|---|---|
| #3 | glucose | 0.54 | 62.2 | 5 h | `.mat` arrays (pre-extracted) |
| #4 | glucose | 0.56 | 60.6 | 5 h | TDT tank |
| #5 | glucose | 0.60 | 59.4 | 5 h | TDT tank (recovered from OneDrive) |
| #22 | glucose | 0.58 | 58.9 | 5 h | TDT tank |
| FP1 | glucose | 0.52 | 66.5 | 13 h, first 5 h used | `.mat` arrays |
| FP2 | glucose | 0.60 | 59.9 | 13 h, first 5 h used | `.mat` arrays |
| #1 | saline | 0.52 | 60.2 | 5 h | `.mat` arrays |
| #2 | saline | 0.49 | 60.1 | 13 h, first 5 h used | TDT tank (recovered) |
| #33 | saline | 0.54 | 60.8 | 5 h | TDT tank (recovered) |

Groups, doses and injection times come from the experimenter's notebook. The three recovered tanks were checked against their index files and the experimenter's own plots. #33's PFC signal is weak: raw 465 ≈ 69 a.u., against ≈ 260–340 in the other two recovered tanks (#2, #5).

## Methodology

**No single 405 → 465 fit.** The usual correction fits 405 onto 465 and subtracts it. Here it fails. After the injection, 465 rises in several glucose mice while 405 slowly bleaches, and a fit over the whole window learns a slope that is too small or even negative (FP2 −1.26, #5 −0.23). Subtracting with a negative slope *adds* 405 noise. Fitting on the baseline alone is fragile too (#5: −0.16). So 465 and 405 are analysed side by side instead.

**Windows.** The baseline runs from 5 min after the start to 3 min before the injection, ~51–59 min, which skips the start-up transient and the handling. The 20 min after the injection are skipped (handling spike). Four post-injection blocks follow: +20–80, +80–140, +140–200 and +200 min to the 5-h mark (~34–41 min).

**Spectra.** Welch's method with 2-min Hann segments, 50% overlap and a linear detrend in each segment, giving ~0.008 Hz resolution. Before each window's spectrum, each channel is expressed as % of its own mean in that window, which removes slow bleaching of the overall level.

**Measures, per window.**

| Measure | What it is | Why |
|---|---|---|
| 465 power | spectrum of the NE-sensor channel | the raw signal |
| 405 power | spectrum of the isosbestic control | shows motion, blood-flow and bleaching changes |
| 465–405 coherence | how predictable 465 is from 405 at each frequency (0–1) | how much of 465 is shared with the control |
| **465 not predicted by 405** | P465 × (1 − coherence) | **main measure:** a regression on 405 done separately at each frequency, so no single slope is needed |
| ΔF/F, baseline-only fit | conventional ΔF/F, robust fit on the baseline only | cross-check against the usual approach |

**Bands and summary.** Bands are 0.01–0.05, 0.05–0.2 and 0.2–1 Hz. NE-specific content lies below ~1 Hz: above that, 465 and 405 spectra match. Changes are log2 ratios to the same mouse's baseline: −1 = half the power, +1 = double.

## Results

**Main measure: 465 power not predicted by 405, 0.01–0.05 Hz** (log2 change vs. baseline)

| Group | Mouse | +20–80 min | +80–140 min | +140–200 min | +200 min–end |
|---|---|---|---|---|---|
| glucose | #3 | −1.60 | −0.54 | −0.13 | +0.31 |
| glucose | #4 | −0.18 | +0.62 | +1.04 | +0.98 |
| glucose | #5 | **−2.35** | **−3.23** | **−1.97** | −0.68 |
| glucose | #22 | +0.91 | +1.04 | +1.48 | +2.21 |
| glucose | FP1 | **−2.45** | **−2.58** | −0.94 | −0.35 |
| glucose | FP2 | **−1.57** | **−1.61** | **−1.76** | −1.25 |
| saline | #1 | +0.70 | +0.36 | +0.56 | +0.64 |
| saline | #2 | −0.02 | +0.34 | +0.46 | +0.23 |
| saline | #33 | +0.12 | +0.40 | +0.62 | +0.62 |

**Group means, first 2 h after the injection** (+20–140 min, log2 change vs. baseline)

| Measure | Band | Glucose (n = 6) | Saline (n = 3) |
|---|---|---|---|
| 465 not predicted by 405 | 0.01–0.05 Hz | **−1.13** | +0.32 |
| | 0.05–0.2 Hz | −0.58 | +0.12 |
| | 0.2–1 Hz | −0.15 | +0.05 |
| 465 | 0.01–0.05 Hz | −1.15 | +0.17 |
| | 0.05–0.2 Hz | −0.08 | −0.07 |
| | 0.2–1 Hz | −0.61 | −0.18 |
| 405 (control) | 0.01–0.05 Hz | −0.86 | −0.14 |
| | 0.05–0.2 Hz | −0.27 | −0.34 |
| | 0.2–1 Hz | −0.89 | −0.29 |
| ΔF/F, baseline-only fit | 0.01–0.05 Hz | −0.63 | +0.38 |
| | 0.05–0.2 Hz | −0.00 | −0.06 |
| | 0.2–1 Hz | −0.50 | −0.20 |

Observations:

- The slow-band drop shows in every measure. It is largest in the 405-independent part of 465, so it isn't a leftover of the control channel.
- The 405 control also loses power in glucose mice, both slow and fast (0.2–1 Hz: −0.89). Raw 465 drops at 0.2–1 Hz too, but the 405-independent part doesn't (−0.15). The fast-band change is therefore shared with 405, not NE-specific.
- The responders (#5, FP1, FP2) are also the mice whose NE *level* rose most after glucose.

**Figures**

- [`band_change.png`](../results/spectra_first5h/band_change.png): band power per mouse and block, for all measures and bands.
- [`spectral_change.png`](../results/spectra_first5h/spectral_change.png): the full log2 change spectrum per block, individual mice and group means.
- [`coherence.png`](../results/spectra_first5h/coherence.png): group-mean 465–405 coherence by window.
- [`per_mouse/`](../results/spectra_first5h/per_mouse/): raw traces with the windows shaded, and every spectrum per window. [`5_glucose.png`](../results/spectra_first5h/per_mouse/5_glucose.png) shows the 0.15 Hz shared artifact being removed.
- Tables: [`band_power.csv`](../results/spectra_first5h/band_power.csv), [`spectra_logbinned.csv`](../results/spectra_first5h/spectra_logbinned.csv), [`baseline_fits.csv`](../results/spectra_first5h/baseline_fits.csv).

## Caveats

- **Small n, no statistics.** 6 glucose vs. 3 saline mice. The glucose response is split: 3 strong, 1 brief, 2 none.
- **Sleep state.** Infraslow (~0.02 Hz) NE oscillations are a feature of NREM sleep. Less slow power after glucose may mean the mice slept less, not that glucose changes NE dynamics directly. There is no EEG. The injection itself wakes the mouse, but saline mice don't show the drop.
- **Mouse identity.** FP1 and FP2 (2 of the 3 strong responders) are 13-h sessions recorded in April. Whether FP2 is a repeat of an earlier mouse is still an open question for the experimenter.
- **"Not predicted by 405" assumes 405 is a pure control.** If 405 partly picks up NE, which GRAB sensors can do near their isosbestic point, that measure removes some real NE signal. The raw 465 spectrum gives the same direction of effect, which limits this concern.
- **Fiber assignment.** Fiber A = PFC is assumed. For the `.mat`-only sessions (#1, #3, FP1, FP2), the store isn't recorded in the files.
- **Short baseline.** ~1 h limits the slowest reliable frequency to ~0.01 Hz and makes the baseline spectrum itself noisy.

## Next steps

1. **Statistics:** per-mouse changes, with a permutation test on glucose vs. saline or a mixed model across blocks. Report effect sizes; with n = 9, avoid leaning on p-values.
2. **Sleep scoring** from the videos (and NE), then compare spectra within matched states. This is the main confound.
3. **Narrow the band:** look at the ~0.02 Hz NREM NE oscillation peak directly (peak frequency and power), not just band power.
4. **Resolve FP1/FP2 identity and exclusions** with the experimenter (open questions in `questions_for_experimenters.md`).
5. **Relate level to spectrum:** test whether the size of the post-glucose NE level rise predicts the slow-band drop across mice.
6. Optional: repeat on the second fiber (OC) and check sensitivity to block length and segment length.
