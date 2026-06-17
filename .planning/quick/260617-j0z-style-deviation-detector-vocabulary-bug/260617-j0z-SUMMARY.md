---
phase: quick-260617-j0z
plan: 01
status: complete
subsystem: editor/anti-ai-scent
tags: [anti-ai-scent, style-deviation, vocabulary, dual-ruler, tdd]
requires:
  - StyleDeviationDetector._analyzeVocabulary
  - StyleAnalyzer._computeVocabularyRichness (baseline authority)
provides:
  - Unified vocabulary ruler (detector == analyzer <50 threshold)
affects:
  - vocabulary DimensionDeviation for 20-49 char AI text
tech-stack:
  added: []
  patterns:
    - "measurement ruler == baseline ruler (dual-ruler elimination, 260617-hnl/f7l 同源原理)"
key-files:
  created: []
  modified:
    - lib/features/editor/application/style_deviation_detector.dart
    - test/features/editor/application/style_deviation_detector_test.dart
decisions:
  - "Aligned detector vocabulary threshold to analyzer (<50) instead of relaxing test threshold; preserves test semantics."
metrics:
  duration: ~6 min
  tasks: 2 (TDD RED + GREEN)
  files: 2
---

# quick-260617-j0z: style_deviation_detector vocabulary 双量尺门槛 bug Summary

单行修复 `StyleDeviationDetector._analyzeVocabulary` 的最低字数门槛（`<20` → `<50`），与基线构建方 `StyleAnalyzer._computeVocabularyRichness` 对齐，闭合双量尺消除战役第 6 维（vocabulary）。

## 根因（活跃 bug）

两方公式完全一致——unique CJK 字符 type-token ratio 经 `((ratio - 0.25) / 0.30).clamp(0.0, 1.0)` 归一化。唯一差异是最低字数门槛：

| 方 | 门槛（pre-fix） | 角色 |
|----|----|----|
| `StyleAnalyzer._computeVocabularyRichness` (style_analyzer.dart:167) | `< 50` → `return 0.5` | profile 基线（权威） |
| `StyleDeviationDetector._analyzeVocabulary` (style_deviation_detector.dart:224) | `< 20` → `textValue: 0.5` | AI 文本测量 |

**后果**：20-49 字 AI 文本，detector 用稀薄样本算出真实词汇丰富度分（小样本 type-token 方差大），去对比 analyzer 用 50+ 字稳健数据构建的 `profile.vocabularyRichness`——稀薄测量 vs 稳健基线，vocabulary 维度偏差分失真（反AI味核心信号）。

**同族同源**：与 260617-hnl（rhythm 双量尺 `<3` vs `<5`）、260617-f7l（emotionalTone 双量尺）完全同类——测量 ruler 与基线 ruler 的"何时可计算"门槛不一致。

## 修复（单行 + 注释）

`style_deviation_detector.dart:224` `cjkChars.length < 20` → `< 50`，加注释引用 hnl/f7l 同源原理：测量方须与基线方用同一"何时可计算词汇丰富度"规则，避免稀薄样本测量对比稳健基线。

## TDD RED→GREEN 证据

### RED（commit 19797a4）

新增 group `vocabulary ruler consistency (260617-j0z)` 共 2 测试。

**T1（主防线）** "should return neutral vocabulary for sub-threshold char counts, matching StyleAnalyzer":
- 构造恰好 30 个 CJK 字（全部不同，type-token ratio = 1.0）：`春风拂过青石板巷尾飘来桂花香我独自漫步那座老旧的小桥流水人家`
- 30 字 ≥ 10（顶层守卫 `_minChars = 10`），通过顶层、进入 `_analyzeVocabulary`
- 断言 `vocabDev.textValue == 0.5`
- **Pre-fix RED**：`< 20` → 30 ≥ 20 算真实丰富度 → ratio 1.0 → normalizedRichness 1.0 → textValue 1.0 ≠ 0.5
  ```
  Expected: <0.5>
    Actual: <1.0>
  ```
- **Post-fix GREEN**：`< 50` → 30 < 50 → 中性 0.5（与 analyzer 同源）

**T2（护栏）** "should still compute vocabulary for 50+ chars":
- 构造 63 个 CJK 字高多样（ratio ≈ 0.94 → normalizedRichness 1.0）：`春风拂过青石板巷尾飘来阵阵桂花清香独自漫步那座老旧的小桥流水人家两岸杨柳依依远山在暮色里渐渐隐去几只归鸟掠过天际霞光映照着村庄`
- 断言 `vocabDev.textValue > 0.6`
- pre-fix 和 post-fix 都通过（证明 `< 50` 门槛没破坏 ≥50 字的正常计算路径）

### GREEN（commit 84e7c27）

单行 + 注释：`< 20` → `< 50`。

## 测试 / analyze 计数

| 阶段 | 文件 / 套件 | 结果 |
|----|----|----|
| pre-RED baseline | detector test (19) | 19/19 pass |
| RED | detector test (19+2=21) | 20/21 — T1 FAILS as expected (1.0 ≠ 0.5), T2 passes |
| GREEN | detector test (21) | 21/21 pass |
| GREEN | `flutter analyze` | 0 issues |
| GREEN | editor feature full suite (`test/features/editor/`) | 291/291 pass — zero regression |

## 现有 fixture 适配

**0 处需适配**。本计划执行中没有改写任何既有测试 fixture——detector test file 中所有 19 条既有测试的 fixture 都是 ≥50 字（vocabulary 守卫在 20-49 字区间内无任何 fixture 落点），门槛 bump 从 `< 20` → `< 50` 没有触发任何 cascade。每个 fixture 的原始语义保持不变。

## grep 护栏结果

```
=== detector ===
230:    if (cjkChars.length < 50) {
=== analyzer ===
167:    if (cjkChars.length < 50) return 0.5;
```

两文件 vocabulary 门槛均 `< 50`，dual-ruler 消除。

## Self-Check: PASSED

- [x] `lib/features/editor/application/style_deviation_detector.dart` — line 230: `< 50` (FOUND)
- [x] `lib/features/editor/application/style_analyzer.dart` — line 167: `< 50` (FOUND, unchanged)
- [x] `test/features/editor/application/style_deviation_detector_test.dart` — group `vocabulary ruler consistency (260617-j0z)` (FOUND)
- [x] commit `19797a4` (RED) — `git log --oneline | grep 19797a4` (FOUND)
- [x] commit `84e7c27` (GREEN) — `git log --oneline | grep 84e7c27` (FOUND)
