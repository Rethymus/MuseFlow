---
phase: quick-260617-jgd
plan: 01
subsystem: editor/style-analysis
tags: [anti-ai-scent, style-deviation, dual-ruler, refactor, dedup, drift-prevention]
status: complete
requires:
  - SentimentLexicon (already shared by both consumers since 260617-f7l)
provides:
  - StyleAnalysisUtils (single ruler for CJK/sentence-length/rhythm/vocabulary)
affects:
  - lib/features/editor/application/style_analyzer.dart
  - lib/features/editor/application/style_deviation_detector.dart
tech-stack:
  added: []
  patterns:
    - static utility class delegation (single source of truth)
key-files:
  created:
    - lib/features/editor/application/style_analysis_utils.dart
    - test/features/editor/application/style_analysis_utils_test.dart
  modified:
    - lib/features/editor/application/style_analyzer.dart
    - lib/features/editor/application/style_deviation_detector.dart
decisions:
  - delegate-then-delete-duplicate (vs. inline-replace): kept private method
    signatures in analyzer for compile stability; deleted detector duplicates
    outright since detector's call sites were few and direct
  - vocabulary <50 threshold branch preserved in detector post-delegation:
    util internally returns 0.5 for <50, but detector's branch sets a custom
    DimensionDeviation shape (explanation/profileValue/textValue=0.5) — the
    branch stays as the public contract for too-short text
  - did NOT merge _computeRhetoricHabits or _computeEmotionalTone per plan
    (rhetoric returns a value object with classification heuristics, emotional
    already delegates to SentimentLexicon — both deferred to future optional)
metrics:
  duration: ~12min
  completed: 2026-06-17T06:18:00Z
  tasks: 2
  files: 4
  commits: 2
---

# quick-260617-jgd: 抽 StyleAnalysisUtils 根治双量尺漂移复发 — Summary

提取共享的 CJK/句长/rhythm/vocab 计算到 `StyleAnalysisUtils`，使测量方 (StyleDeviationDetector) 和基线方 (StyleAnalyzer) 调用同一个权威函数，从结构上消灭"两份副本单边改动导致偏差分漂移"的整类复发 bug。

## What Changed

### New file — `lib/features/editor/application/style_analysis_utils.dart`
纯 Dart `static` 工具类，4 个公开方法（5 含 `cjkCharCount`）：

- `extractCjkChars(String)` / `cjkCharCount(String)` — rune 范围 0x4E00-9FFF / 0x3400-4DBF / 0x3000-303F
- `extractSentenceLengths(String)` — 正则 `[。！？；\n]+` 切分，过滤空段
- `computeRhythmScore(List<int>)` — CV 公式 + `<5` 句门槛 + `avg==0` 门槛（hnl 锁定值）
- `computeVocabularyRichness(String)` — type-token ratio + `<50` 字门槛（j0z 锁定值）

每行实现逐字搬自 analyzer 的 pre-refactor 私有方法（analyzer 是权威方）。

### Rewire — `style_analyzer.dart`
5 处私有方法 (`_extractCjkChars` / `_cjkCharCount` / `_extractSentenceLengths` / `_computeRhythmScore` / `_computeVocabularyRichness`) 全部改为一行委托 `StyleAnalysisUtils`；删除 analyzer 内部已无引用的 `_extractCjkChars`。`_computeSentenceStats` 仍用 `dart:math.sqrt`，故 import 保留。

### Rewire — `style_deviation_detector.dart` (结构性根治)
detector **不再持有自己的尺子**：
- 删除 `_computeRhythmScore` 副本 (~16 行)
- 删除 `_extractSentenceLengths` 副本 → 改委托
- 删除 `_extractCjkChars` 副本 → 所有 4 个调用点改 `StyleAnalysisUtils.cjkCharCount/extractCjkChars`
- `_analyzeVocabulary` 内联的 richness 公式 → 替换为 `StyleAnalysisUtils.computeVocabularyRichness(text)` 调用；`<50` 字门槛分支保留（util 内部已返回 0.5，但 detector 需要构造带 explanation 的 `DimensionDeviation`）
- 删除无用的 `dart:math` import
- `_computeEmotionalTone` / `_computeRhetoricHabits` 按 PLAN 不动

净 LOC：detector -61 行（重复逻辑消除）。

## Dedup Evidence (双量尺漂移战役闭合)

| 维度 | pre-refactor 状态 | post-refactor 状态 |
|------|------------------|------------------|
| CJK 抽取 | detector:508 自带副本 vs analyzer:380 自带副本 | **双方委托** `StyleAnalysisUtils.extractCjkChars` |
| 句长抽取 | detector:391 vs analyzer:102 | **双方委托** `StyleAnalysisUtils.extractSentenceLengths` |
| Rhythm 评分 | detector:399 (`<3`→`<5` hnl 修) vs analyzer:143 (`<5`) | **双方委托** `StyleAnalysisUtils.computeRhythmScore` |
| Vocab 丰富度 | detector 内联 (`<20`→`<50` j0z 修) vs analyzer:165 (`<50`) | **双方委托** `StyleAnalysisUtils.computeVocabularyRichness` |
| 情感基调 | 已同源 SentimentLexicon (f7l 闭合) | 不动 |
| 修辞习惯 | 两份独立副本 | **未合并**（PLAN 明示可选） |

**结构性根因消灭**：未来若任一方再尝试改 rhythm/vocab/CJK 公式，grep 不到副本——只能改 util，另一方自动跟随。漂移从"需要人盯每个维度"降级为"结构上不可能"。

## Grep Proof (detector 不再自带 ruler)

```text
$ grep -n "_computeRhythmScore\|computeVocabularyRichness\|_extractCjkChars" \
    lib/features/editor/application/style_deviation_detector.dart
224:    // [StyleAnalysisUtils.computeVocabularyRichness] — identical formula
231:    final normalizedRichness = StyleAnalysisUtils.computeVocabularyRichness(text);
```

只有 1 个 call site（委托），**零** 自定义实现。pre-refactor 同 grep 会显示 3 个独立定义。

detector 全部委托点（8 处）：
```
100:  StyleAnalysisUtils.cjkCharCount(text)
188:  StyleAnalysisUtils.computeRhythmScore(lengths)
231:  StyleAnalysisUtils.computeVocabularyRichness(text)
235:  StyleAnalysisUtils.cjkCharCount(text)
405:  StyleAnalysisUtils.extractSentenceLengths(text)  (via _extractSentenceLengths delegate)
451:  StyleAnalysisUtils.cjkCharCount(text)
483:  StyleAnalysisUtils.cjkCharCount(sentence)
```

analyzer 全部委托点（4 处）：
```
110: StyleAnalysisUtils.extractSentenceLengths(text)
144: StyleAnalysisUtils.computeRhythmScore(lengths)
152: StyleAnalysisUtils.computeVocabularyRichness(text)
357: StyleAnalysisUtils.cjkCharCount(text)
```

## Test / Analyze Counts

| Gate | Pre-rewire | Post-rewire | Result |
|------|-----------|-------------|--------|
| `flutter analyze` | 0 issues | **0 issues** | preserved |
| `style_analysis_utils_test.dart` | n/a (new) | **23/23 passed** | NEW unit tests lock authoritative impl |
| `test/features/editor/application/` | n/a | **207/207 passed** (detector 21 + analyzer + util 23 + others) | preserved |
| `test/features/editor/` | 291+ baseline | **314/314 passed** | zero regression |

**Zero behavior change verified** — every existing detector + analyzer test (including the 5 prior campaign regression guards 05c/1uk/f7l/hnl/j0z) still passes against the delegated implementation.

## Commits

- `73b17d5` — `refactor(quick-260617-jgd): 抽 StyleAnalysisUtils 共享 CJK/句长/rhythm/vocab 计算` (new util + 23 tests)
- `cd04183` — `refactor(quick-260617-jgd): detector/analyzer 委托 StyleAnalysisUtils，删重复副本` (net -61 LOC)

## Deviations from Plan

None — plan executed exactly as written. Two minor execution-time decisions documented in frontmatter (`decisions`).

## Self-Check: PASSED

- `lib/features/editor/application/style_analysis_utils.dart` — FOUND
- `test/features/editor/application/style_analysis_utils_test.dart` — FOUND
- Commit `73b17d5` — FOUND
- Commit `cd04183` — FOUND
- `flutter analyze` 0 issues — FOUND
- editor feature 314 tests pass — FOUND
