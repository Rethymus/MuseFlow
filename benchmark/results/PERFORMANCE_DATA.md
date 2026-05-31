# Performance Data -- Editor Benchmark Results

**Date:** 2026-06-01
**Environment:** Flutter 3.44.0 / Dart 3.12.0 / Windows (WSL2)
**Methodology:** SchedulerBinding.addTimingsCallback for frame timing capture

---

## Methodology

### Measurement Approach
- Each editor loads Chinese text at 4 sizes: 10K, 50K, 100K, 300K characters
- Text is generated deterministically via `TestTextGenerator(seed: 42)` -- identical input for both editors
- After loading, a programmatic scroll from top to bottom is triggered via `ScrollController.animateTo`
- Frame timings are captured via `SchedulerBinding.instance.addTimingsCallback`
- Each frame's total span (build + raster) is recorded

### Metrics
- **Avg Frame Time**: Mean total frame duration across all captured frames
- **P95 Frame Time**: 95th percentile frame duration (represents worst-case for 95% of frames)
- **Max Frame Time**: Single worst frame duration
- **Jank Frames**: Count of frames exceeding 16ms (60fps threshold)
- **Total Frames**: Total captured frames during scroll

### Document Sizes
| Size | Characters | Approx Paragraphs | Description |
|------|-----------|-------------------|-------------|
| 10K | 10,000 | ~35 | Baseline -- should be smooth on any editor |
| 50K | 50,000 | ~170 | Medium -- typical chapter length |
| 100K | 100,000 | ~340 | Threshold per ROADMAP success criteria |
| 300K | 300,000 | ~1,000 | Target per EDIT-04 (300K+ chars at 60fps) |

---

## super_editor 0.3.0-dev.20

**PENDING -- Requires manual run on Windows desktop**

To run:
```bash
cd benchmark/super_editor_app
flutter run -d windows
```
Then click "Benchmark 10K", "Benchmark 50K", "Benchmark 100K", "Benchmark 300K" buttons.

### Results

| Size | Avg (ms) | P95 (ms) | Max (ms) | Jank Frames | Total Frames |
|------|----------|----------|----------|-------------|--------------|
| 10K | -- | -- | -- | -- | -- |
| 50K | -- | -- | -- | -- | -- |
| 100K | -- | -- | -- | -- | -- |
| 300K | -- | -- | -- | -- | -- |

### Observations
*(Fill in after running: text rendering correctness, scroll smoothness, any crashes or visual artifacts)*

---

## appflowy_editor 6.2.0

**PENDING -- Requires manual run on Windows desktop**

To run:
```bash
cd benchmark/appflowy_editor_app
flutter run -d windows
```
Then click "Benchmark 10K", "Benchmark 50K", "Benchmark 100K", "Benchmark 300K" buttons.

### Results

| Size | Avg (ms) | P95 (ms) | Max (ms) | Jank Frames | Total Frames |
|------|----------|----------|----------|-------------|--------------|
| 10K | -- | -- | -- | -- | -- |
| 50K | -- | -- | -- | -- | -- |
| 100K | -- | -- | -- | -- | -- |
| 300K | -- | -- | -- | -- | -- |

### Observations
*(Fill in after running: text rendering correctness, scroll smoothness, any crashes or visual artifacts)*

---

## Known Issues from Research

### super_editor
- **#2588** (open): IME candidate window appears in wrong position on Windows
- **#2728** (open): Chinese IME composing crash when deleting at end of text
- **#2534** (open): "Chinese layout is very ugly" -- rendering issues

### appflowy_editor
- **#696** (open, P0): Sogou input produces garbled character order -- showstopper for Sogou Pinyin
- Depends on `provider` package (architectural overlap with Riverpod, but internal only)
- Transitive `file_picker` dependency

---

## Performance Score Calculation

After data is collected, each editor receives a performance score (1-5):

| Score | Criteria |
|-------|----------|
| 5 | All sizes < 16ms avg, < 32ms max, zero crashes |
| 4 | 100K+ < 16ms avg, 300K < 24ms avg, zero crashes |
| 3 | 100K < 16ms avg, 300K < 32ms avg, may have minor jank |
| 2 | 50K+ shows visible jank, 300K borderline usable |
| 1 | Crashes or freezes at 100K+ characters |

*Performance scores will be filled in after manual benchmark execution.*
