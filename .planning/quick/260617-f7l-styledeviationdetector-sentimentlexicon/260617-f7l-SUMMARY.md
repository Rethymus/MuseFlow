---
phase: quick-260617-f7l
plan: 01
subsystem: editor/style-deviation
tags: [anti-ai-scent, style-deviation, sentiment-lexicon, refactor, tdd]
requires:
  - lib/features/editor/infrastructure/sentiment_lexicon.dart (authoritative ruler, unchanged)
  - lib/features/editor/application/style_analyzer.dart (authoritative _computeEmotionalTone template, lines 254-272)
provides:
  - "StyleDeviationDetector._computeEmotionalTone unified with SentimentLexicon (single ruler for measurement + baseline)"
affects:
  - lib/features/editor/application/style_deviation_detector.dart
  - test/features/editor/application/style_deviation_detector_test.dart
tech-stack:
  added: []
  patterns:
    - "lexicon delegation — application-layer detector reuses infrastructure-layer SentimentLexicon const data class (same precedent as style_analyzer.dart:19)"
key-files:
  created: []
  modified:
    - lib/features/editor/application/style_deviation_detector.dart
    - test/features/editor/application/style_deviation_detector_test.dart
decisions:
  - "D-f7l-1: Unify the detector to the same SentimentLexicon ruler as StyleAnalyzer — single source of truth for warmth/intensity/classifyTone, eliminating inline-table drift."
  - "D-f7l-2: isFlat boundary shifted from 0.35–0.65 mid-band to intensity < 0.3 to match SentimentLexicon.intensityScore's semantic (emotionless text → intensity 0, not 0.5)."
  - "D-f7l-3: Rewrote flat-emotion test fixture to a 117-CJK zero-lexicon-match passage (pre-fix fixture was 83 CJK with 1 lexicon hit '阳光' that no longer triggered isFlat under the new ruler)."
metrics:
  duration: "~22 min"
  completed: "2026-06-17T03:37:00Z"
  tasks_completed: 3
  files_changed: 2
---

# Phase quick-260617-f7l Plan 01: Detector emotionalTone Lexicon Unification Summary

Eliminated StyleDeviationDetector's 42-word inline sentiment table + custom warmth/intensity/classifyTone formulas, delegating to the shared SentimentLexicon so the "measurement" ruler matches the profile-builder (StyleAnalyzer) "baseline" ruler byte-for-byte — closing the root cause of three prior bugs (260617-05c dup double-count, 260617-1uk bare 爱/恨 substring over-count + polarity inversion).

## What Changed

### Production code (lib/features/editor/application/style_deviation_detector.dart)

- Added `import 'package:museflow/features/editor/infrastructure/sentiment_lexicon.dart';` (same precedent as style_analyzer.dart:19 — both application-layer files depend on this const data class).
- Rewrote `_computeEmotionalTone(text)` to a 18-line delegate that mirrors StyleAnalyzer._computeEmotionalTone (style_analyzer.dart:254-272) byte-for-byte:
  - `SentimentLexicon.countPositive` / `countNegative` (indexOf loop — safe against bare-char substring over-count, the 260617-1uk bug class).
  - `SentimentLexicon.warmthScore(pos, neg)` (ratio `pos/(pos+neg)`, 0/0 → 0.5 neutral).
  - `SentimentLexicon.intensityScore(pos, neg, cjk)` (`<100 cjk` early-return 0.3; else `density/4` clamp 0–1).
  - `SentimentLexicon.classifyTone(warmth, intensity)` (8-class taxonomy).
- Deleted three private methods (~95 lines removed):
  - `_countPositiveSentiment` — 22-word inline Set + String.allMatches loop (substring-unsafe; this was the surface for the 260617-1uk bug).
  - `_countNegativeSentiment` — 20-word inline Set + String.allMatches loop.
  - `_classifyTone` — 5-class self-invented taxonomy (`平淡克制`/`热烈奔放`/`温暖柔和`/`冷峻深沉`/`张弛有度`) that diverged from SentimentLexicon's 8-class output.
- Removed the misleading comment `// Simplified emotion analysis without sentiment lexicon dependency`.
- Net file delta: +47 / -95 (≈ -48 lines).
- Adapted `_analyzeEmotionalTone`'s `isFlat` boundary from `intensity > 0.35 && intensity < 0.65` to `intensity < 0.3`. Reason documented in code comment: pre-fix formula returned 0.5 (mid-band) for emotionless text; SentimentLexicon.intensityScore returns ~0 for the same input, so the semantic ("情感曲线平淡，缺乏起伏") correctly maps to `intensity < 0.3`. This also matches SentimentLexicon.classifyTone's own `intensity < 0.3 → 平静温和/冷静克制` cutoff, keeping detector and lexicon rulings consistent.

### Tests (test/features/editor/application/style_deviation_detector_test.dart)

Added new group `sentiment lexicon consistency (260617-f7l)` with two regression tests:

1. **`should compute emotionalTone using SentimentLexicon, not an inline table (lexicon-only words must register)`** — fixture uses 123-CJK text dense in lexicon-only positive words (温馨/慈爱/相伴/相守/携手/守护/依偎/微笑/春风/陪伴/并肩/庇护/兰花/碧空/花香/清风/鸟鸣/溪流/山峦/云朵/悠然/晨曦/暮色/繁星 — none of which appear in the pre-fix 22-word inline table). Pre-fix: 0 inline matches → intensity 0.5 (neutral baseline). Post-fix: 23 lexicon matches → intensity 1.0 (density band). Threshold `> 0.6` cleanly separates the two states.
2. **`should compute intensity via SentimentLexicon.intensityScore (same formula as StyleAnalyzer)`** — structural-equivalence guard asserting `toneDev.textValue` is within 1e-9 of `SentimentLexicon.intensityScore(countPositive, countNegative, cjkLen)`. Pre-fix detector's custom `(pos+neg)/(cjk*0.03+1)*0.5+0.5` formula diverges (0.716 vs expected 1.0).

Adjusted one pre-existing fixture ("should detect flat emotion curve (AI pattern)"): the original 83-CJK fixture contained the lexicon word '阳光' (1 hit) which under the new ruler produces intensity 0.3 (early-return) — not < 0.3, so isFlat no longer fired. Rewrote to a 117-CJK passage with zero lexicon matches so the density formula returns intensity 0 → isFlat fires → '平淡' branch as before. Fixture semantic ("emotionally flat AI-style text") preserved; only the surface prose changed.

Added file-level `import 'package:museflow/features/editor/infrastructure/sentiment_lexicon.dart';` to support the new test assertions.

## Deviations from Plan

### Auto-fixed Issues

None unexpected. The plan explicitly anticipated the isFlat boundary adaptation (Task 2 Step F.2) and the fixture-extension requirement (Task 1 action note about >=100 CJK). Both were applied as documented.

### Plan-anticipated adjustments applied

- **isFlat boundary adaptation** (Task 2 Step F.2): pre-fix 0.35–0.65 mid-band → post-fix `< 0.3`. Comment cites the lexicon-unification reason.
- **Flat-emotion fixture redesign**: original fixture no longer triggered the '平淡' branch under the new ruler; rewrote to 117-CJK zero-lexicon-match passage. Documented inline with `lexicon 统一后数值变化（260617-f7l）` marker per orchestrator hint #3.
- **Test 1 fixture threshold**: orchestrator hint #1 noted the >0.35 threshold wouldn't separate pre/post states because pre-fix intensity is 0.5 (not below 0.35). Used `> 0.6` instead — cleanly separates pre 0.5 from post 1.0.
- **Test 1 fixture size**: orchestrator hint #1 noted the default 34-CJK fixture would hit `intensityScore` early-return 0.3. Expanded to 123 CJK (>100) so the density formula runs.

## TDD Gate Compliance

- **RED commit**: `2a4c340` — `test(quick-260617-f7l): add failing regression for detector lexicon consistency` (2 new tests fail: 0.5 vs >0.6, 0.716 vs 1.0; existing 15 pass).
- **GREEN commit**: `49dc61c` — `fix(quick-260617-f7l): unify detector emotionalTone to SentimentLexicon` (17/17 GREEN).
- Order: RED precedes GREEN in git log ✓.

## Verification Results

### Task 1 — RED

```
flutter test test/features/editor/application/style_deviation_detector_test.dart
→ 15 passed, 2 failed (expected RED)
```

Failure details (pre-fix detector behavior):
- T1: `Expected: a value greater than <0.6> / Actual: <0.5>` — inline 22-word table 0 matches on lexicon-only fixture → neutral-baseline 0.5.
- T2: `Expected: a numeric value within <1e-9> of <1.0> / Actual: <0.7159827213822894>` — pre-fix custom formula diverges from SentimentLexicon.intensityScore.

### Task 2 — GREEN + grep guardrails

```
flutter analyze lib/features/editor/application/style_deviation_detector.dart test/features/editor/application/style_deviation_detector_test.dart
→ No issues found!

flutter test test/features/editor/application/style_deviation_detector_test.dart
→ 17/17 All tests passed!
```

Grep guardrails:
- `grep -c "_countPositiveSentiment\|_countNegativeSentiment\|_classifyTone\|positives = \|negatives = " lib/.../style_deviation_detector.dart` → **0** ✓
- `grep -c "SentimentLexicon" lib/.../style_deviation_detector.dart` → **8** (1 import + countPositive + countNegative + warmthScore + intensityScore + classifyTone + 2 occurrences in isFlat adaptation comment) ✓ (>= 5 required)

### Task 3 — Full editor feature regression

```
flutter analyze   (full repo)
→ No issues found! (ran in 5.2s)

flutter test test/features/editor/
→ All tests passed! (287 tests)
```

Includes: style_analyzer_test (15), style_deviation_detector_test (17), and all downstream consumers of StyleDeviationResult (style_thermometer_dashboard widget tests, editor_ai_notifier tests, etc.). Zero regression.

## Known Stubs

None. No stub patterns introduced — `_computeEmotionalTone` is a complete delegate to a production lexicon.

## Threat Flags

None. The change reduces attack surface (2 inline word tables → 1 shared const data class). The threat register's T-f7l-02 (Information Disclosure — biased emotionalTone 偏差分 misleading the author) is mitigated as planned: single ruler eliminates drift.

## Suggested STATE.md Quick Tasks Completed Entry

```
| 260617-f7l | refactor 统一 StyleDeviationDetector emotionalTone 到 SentimentLexicon（消除双量尺漂移根因，闭合 260617-05c/1uk 同族 bug 链）：detector._computeEmotionalTone 改为镜像 StyleAnalyzer 实现——全部委托 SentimentLexicon.countPositive/countNegative/warmthScore/intensityScore/classifyTone（ indexOf 安全计数，杜绝裸单字子串过计）；删除 _countPositiveSentiment(22词)/_countNegativeSentiment(20词)/_classifyTone(5类自创) 三私有方法 + 内联 Set 字面量 + 自创公式（共 ~95 行）；application→infrastructure 依赖先例同 style_analyzer.dart:19；isFlat 边界从 0.35-0.65 中性带改为 <0.3 适配新公式语义（无情感词→intensity 0 而非 0.5，与 classifyTone <0.3→平静/冷静 截止一致）；2 RED→GREEN 回归测试（T1 lexicon-only 词强制 RED：123 CJK 命中 23 lexicon 独有词 0 内联 → post intensity 1.0 vs pre 0.5，门槛 >0.6 分离；T2 公式同源精确相等 closeTo(intensityScore,1e-9)）；flat-emotion fixture 重写为 117 CJK 零 lexicon 命中（pre-fix 83 CJK 含 '阳光' 不再触发 isFlat）；TDD RED→GREEN；analyze 0 / 17 detector + 287 editor feature 全量零回归 | 49dc61c | [260617-f7l-styledeviationdetector-sentimentlexicon](./quick/260617-f7l-styledeviationdetector-sentimentlexicon/) |
```

## Self-Check

- [x] `lib/features/editor/application/style_deviation_detector.dart` exists (modified in place).
- [x] `test/features/editor/application/style_deviation_detector_test.dart` exists (modified in place).
- [x] Commit `2a4c340` (RED) exists in git log.
- [x] Commit `49dc61c` (GREEN) exists in git log.

## Self-Check: PASSED
