# PFC norepinephrine spectra after IP glucose vs. saline: first pass

*2026-10-27. Code: `spectra/`; the commit is named in [`provenance.txt`](../results/spectra_first5h/provenance.txt). Results: [`results/spectra_first5h/`](../results/spectra_first5h/).*

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

**Frequency range: 0.01–1 Hz.** The ~20 Hz traces carry frequencies up to ~10 Hz. Figure 1 shows each mouse's baseline spectrum over that whole range. [Appendix A](#appendix-a-full-band-view-of-each-recording) shows the full spectrogram of every recording.

![Baseline 465 and 405 spectra to 10 Hz for each mouse, and every mouse's 465–405 coherence](../results/spectra_first5h/full_band_baseline.png)

*Figure 1. Baseline spectra (top 3×3: 465 black, 405 grey, 465 not predicted by 405 dashed) and 465–405 coherence (bottom; blue glucose, orange saline), 0.008–10 Hz. Shaded: the analysed 0.01–1 Hz; dotted: the band edges at 0.05 and 0.2 Hz. Data: [`full_band_baseline.csv`](../results/spectra_first5h/full_band_baseline.csv).*

- **Why stop at 1 Hz.** From ~0.8–1.2 Hz upward, the 465 spectrum goes flat: it has hit the noise floor (Table A1). Coherence with 405 falls to 0.02–0.04 there, the level expected from pure chance with ~54 baseline segments. A flat spectrum that is uncorrelated between the two channels is what independent detector noise looks like. Nothing above ~1 Hz can be resolved in either channel. From ~6 Hz both channels roll off steeply. The full-rate (~1017 Hz) data show the same roll-off, so it comes from the acquisition's demodulator low-pass filter, not from our downsampling. The only shared structure above 1 Hz is artifact: a ~2–4 Hz trace in #5 from +30 to +90 min (likely breathing or movement) and a steady ~8 Hz band in #2 (likely heartbeat; a mouse's heart beats ~8–10 times a second). The GRAB-NE signal also takes seconds to decay after NE falls, which smooths out faster NE changes.
- **Why stop at 0.01 Hz.** The 2-min Welch segment sets the frequency resolution to 1/120 s ≈ 0.008 Hz. The lowest bin, 0.008 Hz, is less than one cycle per segment. Longer segments would reach lower frequencies but give fewer segments: a ~55-min baseline yields ~54 two-min segments at 50% overlap, and fewer segments means noisier spectra. Below ~0.01 Hz, bleaching and slow drift dominate anyway, and the per-segment linear detrend removes them.

**Bands.** The 0.01–1 Hz range is split into three bands. They were set before the analysis, at roughly even log spacing, and not tuned afterwards. The full change spectra (Figure 3) check that the band edges hide nothing.

- **0.01–0.05 Hz (periods of 20–100 s): the target band.** It contains the infraslow NE oscillation of NREM sleep, at ~0.02 Hz (~50-s cycles; Osorio-Forero et al. 2021, Kjaerby et al. 2022). It is also the most NE-specific part of these recordings. In 8 of 9 mice, it is the only range where 465 has more power than 405 (log2 ratio +0.5 to +3.0; FP1 −0.34), and it has the lowest 465–405 coherence in most mice (0.45–0.79; Table A1).
- **0.05–0.2 Hz: transition.** Coherence climbs from the slow band to its plateau.
- **0.2–1 Hz: shared band.** In 7 mice, 465 here is mostly shared with 405 (coherence 0.72–0.92), so only the part not predicted by 405 is read for NE. #22 and #33 have low coherence here (0.36, 0.16), for different reasons. In #22, 405 is close to its noise floor across 0.05–1 Hz. In #33, the weak recording, 465 sits only ~2× above its own high floor from ~0.2 Hz up. In both mice, this band is closer to noise than in the others.

**Summary measure.** Changes are log2 ratios to the same mouse's baseline: −1 = half the power, +1 = double.

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

![Band-power change per mouse and post-injection block, for each measure and band](../results/spectra_first5h/band_change.png)

*Figure 2. Band-power change vs. each mouse's baseline. Rows: measure; columns: band; dots: mice; lines: group means (blue glucose, orange saline). The glucose drop is in the 0.01–0.05 Hz column. It is clearest in row 3 (465 not predicted by 405) and fades by +200 min.*

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

![log2 change spectrum per post-injection block, individual mice and group means](../results/spectra_first5h/spectral_change.png)

*Figure 3. The change spectrum without bands: log2 change vs. baseline at each frequency, 0.01–2 Hz. Rows: measure; columns: post-injection block; thin lines: mice; thick: group means. Row 3 (465 not predicted by 405) shows the glucose drop below ~0.1 Hz in the first two blocks. The +20–80 min peak near 0.15 Hz in rows 1, 2 and 4 is absent from row 3, because it is shared with 405.*

![Group-mean 465–405 coherence by window](../results/spectra_first5h/coherence.png)

*Figure 4. Group-mean 465–405 coherence by window. Most of the 465 signal at 0.05–1 Hz moves with 405, before and after the injection.*

![Mouse #5: raw traces with windows, and each spectral measure by window](../results/spectra_first5h/per_mouse/5_glucose.png)

*Figure 5. Mouse #5 (glucose), the clearest responder. Top left: raw traces with the analysis windows shaded. Then each measure's spectrum per window (grey: baseline; blue, light to dark: post-injection blocks). In raw 465 and 405, the first post-injection block has a peak near 0.15 Hz. The 465 not predicted by 405 has no such peak, only the drop below ~0.1 Hz.*

Other outputs: per-mouse figures for all 9 mice in [`per_mouse/`](../results/spectra_first5h/per_mouse/), and the tables [`band_power.csv`](../results/spectra_first5h/band_power.csv), [`spectra_logbinned.csv`](../results/spectra_first5h/spectra_logbinned.csv) and [`baseline_fits.csv`](../results/spectra_first5h/baseline_fits.csv).

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

## Appendix A: full-band view of each recording

Each figure below covers one recording's first 5 h up to ~10 Hz:

- **Left, top two rows:** spectrograms of 465 and 405. These use the same 2-min Hann segments as the analysis, in 1-min steps; each segment is detrended and expressed as % of its own mean. Frequencies are averaged into log-spaced bins (24 per decade). Both rows share one colour scale.
- **Left, bottom row:** 465–405 coherence in sliding 20-min windows (5-min steps). With ~19 segments per window, the no-correlation level is ~0.05.
- **Right:** the baseline spectra and coherence at full resolution.
- **Lines:** vertical lines mark the baseline window, the injection (solid) and the end of the 20-min post-injection skip. Horizontal lines mark 0.01 and 1 Hz.

**Table A1.** Baseline 465–405 coherence by band, the 465/405 power ratio in the slow band, and the frequency above which 465 stays within 2× of its noise floor (its 2–5 Hz median). Computed from [`full_band_baseline.csv`](../results/spectra_first5h/full_band_baseline.csv).

| Mouse | Group | Coherence 0.01–0.05 Hz | 0.05–0.2 Hz | 0.2–1 Hz | 2–6 Hz | log2(465/405), 0.01–0.05 Hz | 465 at noise floor above |
|---|---|---|---|---|---|---|---|
| #3 | glucose | 0.53 | 0.91 | 0.92 | 0.04 | +0.80 | 1.2 Hz |
| #4 | glucose | 0.57 | 0.68 | 0.72 | 0.03 | +0.86 | 0.9 Hz |
| #5 | glucose | 0.45 | 0.77 | 0.84 | 0.03 | +0.89 | 0.9 Hz |
| #22 | glucose | 0.79 | 0.52 | 0.36 | 0.02 | +2.98 | 0.8 Hz |
| FP1 | glucose | 0.71 | 0.87 | 0.92 | 0.02 | −0.34 | 1.2 Hz |
| FP2 | glucose | 0.71 | 0.80 | 0.87 | 0.03 | +0.47 | 1.0 Hz |
| #1 | saline | 0.52 | 0.81 | 0.92 | 0.04 | +1.02 | 1.2 Hz |
| #2 | saline | 0.61 | 0.81 | 0.92 | 0.04 | +2.17 | 1.2 Hz |
| #33 | saline | 0.75 | 0.42 | 0.16 | 0.02 | +0.93 | 1.4 Hz* |

\* #33's floor is high and slopes gently from ~0.2 Hz, so the 2× rule places it late. By eye, its 465 is near the floor from ~0.2 Hz (see A.9).

What the spectrograms show across recordings:

- Above ~1 Hz, both channels are featureless apart from the artifacts named in [Methodology](#methodology): a shared, drifting ~2–4 Hz trace in #5 from ~+30 to +90 min, and a steady shared ~8 Hz band in #2.
- Below 1 Hz, power changes over time in both channels together. These are the broadband vertical stripes, likely movement. The coherence row shows how much of each change 405 shares.
- Coherence at 0.05–1 Hz stays high across the whole session in most mice. The shared component is not a baseline-only feature.

### A.1 #3 (glucose)
![#3 full-band view](../results/spectra_first5h/full_band/3_glucose.png)

### A.2 #4 (glucose)
![#4 full-band view](../results/spectra_first5h/full_band/4_glucose.png)

### A.3 #5 (glucose)
![#5 full-band view](../results/spectra_first5h/full_band/5_glucose.png)

### A.4 #22 (glucose)
![#22 full-band view](../results/spectra_first5h/full_band/22_glucose.png)

### A.5 FP1 (glucose)
![FP1 full-band view](../results/spectra_first5h/full_band/FP1_glucose.png)

### A.6 FP2 (glucose)
![FP2 full-band view](../results/spectra_first5h/full_band/FP2_glucose.png)

### A.7 #1 (saline)
![#1 full-band view](../results/spectra_first5h/full_band/1_saline.png)

### A.8 #2 (saline)
![#2 full-band view](../results/spectra_first5h/full_band/2_saline.png)

### A.9 #33 (saline)
![#33 full-band view](../results/spectra_first5h/full_band/33_saline.png)

## References

- Osorio-Forero A, et al. (2021). Noradrenergic circuit control of non-REM sleep substates. *Current Biology* 31:5009–5023.
- Kjaerby C, et al. (2022). Memory-enhancing properties of sleep depend on the oscillatory amplitude of norepinephrine. *Nature Neuroscience* 25:1059–1070.
