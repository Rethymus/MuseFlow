---
phase: quick-260617-hnl
plan: 01
type: tdd
status: complete
subsystem: editor/style-deviation
tags: [anti-ai-scent, style-deviation, rhythm, dual-ruler, refactor]
requirements: [AA-CONSISTENCY]
depends_on: []
provides:
  - detector rhythm ruler aligned to analyzer baseline
affects:
  - lib/features/editor/application/style_deviation_detector.dart
key-files:
  modified:
    - lib/features/editor/application/style_deviation_detector.dart
    - test/features/editor/application/style_deviation_detector_test.dart
decisions:
  - "rhythm 门槛统一为 <5（与 StyleAnalyzer 同源），单行 + 注释，不抽共享 utils"
  - "0 个现有 fixture 需要扩写（全部用 ≥5 句或不强断 rhythm textValue）"
metrics:
  duration: ~6 min
  tasks: 2 (RED, GREEN)
  files: 2
  tests-added: 2
  tests-passing: 19/19 detector, 289/289 editor feature
---

# quick-260617-hnl: style_deviation_detector rhythm 维度双量尺门槛 bug Summary

StyleDeviationDetector `_computeRhythmScore` 最低句数门槛从 `< 3` 对齐到
StyleAnalyzer 的 `< 5`，闭合双量尺消除战役第 5 维（rhythm）—— 与已闭合的
260617-f7l（emotionalTone）同源原理：测量 ruler 必须 == 基线 ruler。

## What Changed

**单行 + 注释**（`lib/features/editor/application/style_deviation_detector.dart:406`）：

```dart
// Before:
if (lengths.length < 3) return 0.5;
// After (+ 8 行解释注释，引用 260617-f7l 同源原理):
if (lengths.length < 5) return 0.5;
```

rhythm 公式（avg/variance/stdDev/cv/`(1.0-(cv-0.3)/0.5).clamp`）两文件原本就
完全一致，唯一差异是这个门槛。pre-fix `< 3` 让 3-4 句 AI 文本用稀薄数据算出
真实节奏方差分（如 4 句均匀 → cv≈0 → rhythm≈1.0），去对比 analyzer 用 5+ 句
稳健数据构建的 `profile.rhythmScore`——稀薄测量 vs 稳健基线，rhythm 维度偏差分
失真（反AI味核心信号）。

## RED → GREEN Evidence

**RED（commit ff06779，test 文件）**：
- T1（主防线）"should return neutral rhythm for sub-threshold sentence counts,
  matching StyleAnalyzer"：4 句均匀长度（各 12 CJK 字），断言
  `rhythmDev.textValue == 0.5`。
  - 实际 RED 输出：`Expected: <0.5>  Actual: <1.0>` — pre-fix `< 3` 对 4 句
    算真实方差（均匀→cv≈0→rhythm=1.0），符合预测。
- T2（护栏）"should still compute rhythm for 5+ sentences"：6 句均匀长度，
  断言 `rhythmDev.textValue > 0.7`。pre-fix 与 post-fix 都通过（保证 < 5 没
  破坏 ≥5 句的正常路径）。
- 全部 17 个既有测试在 RED 阶段仍通过——pre-fix 门槛 bump 没在 RED 阶段
  造成任何 fixture 破坏。

**GREEN（commit 10fbae5，lib 文件）**：
- detector test 文件 19/19 全绿（17 既有 + 2 新增）。
- 0 个既有 fixture 需要扩写到 ≥5 句——所有既有 fixture 要么已用 ≥5 句，
  要么不强断 rhythm 维度的 textValue（例如 "should detect AI-uniform rhythm"
  fixture 用 5 句 + 断 explanation 含 '均匀'，没踩门槛变化）。

## Test / Analyze Counts

| 阶段 | 命令 | 结果 |
|------|------|------|
| RED | `flutter test test/features/editor/application/style_deviation_detector_test.dart` | 18 passed, 1 failed (T1, 如预期 RED) |
| GREEN | `flutter analyze` (changed files) | No issues found |
| GREEN | `flutter test test/features/editor/application/style_deviation_detector_test.dart` | 19/19 passed |
| GREEN | `flutter test test/features/editor/` (全量回归) | 289/289 passed, zero regression |

## Grep Guard

```bash
$ grep -n "lengths.length <" \
    lib/features/editor/application/style_deviation_detector.dart \
    lib/features/editor/application/style_analyzer.dart
lib/features/editor/application/style_deviation_detector.dart:406:    if (lengths.length < 5) return 0.5;
lib/features/editor/application/style_analyzer.dart:144:    if (lengths.length < 5) return 0.5;
```

两文件门槛一致（`< 5`），双量尺漂移已消除。

## Deviations from Plan

None — plan executed exactly as written. Plan 预测的"可能需要扩写 fixture 到
≥5 句"未触发：所有既有 fixture 都不踩门槛变化。

## Self-Check: PASSED

- [x] lib/features/editor/application/style_deviation_detector.dart 已修改（line 406）
- [x] test file 包含 `rhythm ruler consistency (260617-hnl)` group + 2 tests
- [x] RED commit ff06779 存在于 git log
- [x] GREEN commit 10fbae5 存在于 git log
- [x] grep guard 输出 `< 5`（detector + analyzer 一致）
