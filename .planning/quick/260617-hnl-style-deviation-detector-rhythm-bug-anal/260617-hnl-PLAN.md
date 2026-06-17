---
phase: quick-260617-hnl
plan: 01
type: tdd
wave: 1
depends_on: []
files_modified:
  - test/features/editor/application/style_deviation_detector_test.dart
  - lib/features/editor/application/style_deviation_detector.dart
autonomous: true
requirements: [AA-CONSISTENCY]
tags: [anti-ai-scent, style-deviation, rhythm, dual-ruler, refactor]
status: ready-to-execute
---

# quick-260617-hnl: style_deviation_detector rhythm 维度双量尺门槛 bug

## 根因（orchestrator 已用 awk 精确确认，活跃 bug）

`StyleDeviationDetector._computeRhythmScore`（测量方，style_deviation_detector.dart:399）与
`StyleAnalyzer._computeRhythmScore`（基线构建方，style_analyzer.dart:143）公式完全一致
（avg/variance/stdDev/cv/`(1.0-(cv-0.3)/0.5).clamp`），**唯一差异是最低句数门槛**：

| 方 | 门槛 | 角色 |
|----|------|------|
| StyleAnalyzer | `if (lengths.length < 5) return 0.5;` | profile 基线（权威） |
| StyleDeviationDetector | `if (lengths.length < 3) return 0.5;` | AI 文本测量 |

**后果**：3-4 句 AI 文本，detector 用稀薄数据算出真实节奏方差分，去对比 analyzer 用 5+ 句稳健数据
构建的 `profile.rhythmScore`——稀薄测量 vs 稳健基线，rhythm 维度偏差分失真（反AI味核心信号）。
与 260617-f7l（emotionalTone 双量尺）同类，是双量尺消除战役第 5 维。

**附带确认（同一 awk 调查，本次不改）**：`_extractSentenceLengths` 与 `_computeRhetoricHabits`
两文件逻辑此刻一致（仅注释/括号/`_extractCjkChars` vs `_cjkCharCount` 方法名差异），非活跃 bug，
属未来漂移风险（可选后续：抽共享 StyleAnalysisUtils 模块）。

## 修复（单行 + 注释）

`style_deviation_detector.dart:400` `lengths.length < 3` → `< 5`，对齐 analyzer 基线门槛。
加注释：测量方须与基线方用同一"何时可计算节奏方差"规则，避免稀薄数据测量对比稳健基线
（260617-f7l 同源原理：测量 ruler == 基线 ruler）。

## TDD（先 RED）

新增 group `rhythm ruler consistency (260617-hnl)`，2 测试：

1. **T1（主防线）** "should return neutral rhythm for sub-threshold sentence counts, matching StyleAnalyzer"
   - 构造恰好 4 句的文本（句长刻意均匀，如 4 句各 12 CJK 字）
   - `detector.analyze` 后取 rhythm 维度 DimensionDeviation
   - 断言 `toneDev.textValue == 0.5`
   - reason：4 句 < 5 句稳健门槛，与 analyzer 一致返回中性；pre-fix detector `< 3` 会对 4 句算真实方差
     （均匀→cv≈0→rhythm≈1.0）→ ≠0.5 → RED；post-fix `< 5` → 0.5 → GREEN

2. **T2（护栏）** "should still compute rhythm for 5+ sentences"
   - 构造 6 句且句长高度均匀（如各 10 CJK 字）
   - 断言 `toneDev.textValue > 0.7`（均匀→AI 味→高 rhythm 分）
   - 确认改 `< 5` 没破坏 ≥5 句的正常计算路径

## 现有测试适配（按语义，不扭曲）

运行 detector 全量测试（当前 17 条，含 260617-f7l 的 2 条）。若 bumping 门槛导致某 fixture
（原本 3-4 句）rhythm textValue 从真实值变 0.5，进而 aiScentScore/explanation 变化使断言失败：
**优先扩写 fixture 到 ≥5 句**保持测试语义（而非放宽门槛）。每处调整加注释
`// rhythm 门槛统一后（260617-hnl）`。绝不删断言或改 tautology。

## 验证

- `flutter analyze` 0 issues
- `flutter test test/features/editor/application/style_deviation_detector_test.dart` 全绿（17+2=19）
- `flutter test test/features/editor/` editor feature 全量零回归
- grep 护栏：`grep -n "lengths.length <" lib/features/editor/application/style_deviation_detector.dart`
  → 应为 `< 5`（与 analyzer 一致）

## 执行入口（resume 用）

`/gsd:quick resume style-deviation-detector-rhythm-bug-anal`
或直接派发 gsd-executor（worktree 隔离）执行上述 TDD，预期 commit 序列：
- `test(quick-260617-hnl): add failing regression for rhythm ruler consistency`（RED）
- `fix(quick-260617-hnl): align detector rhythm threshold to analyzer baseline`（GREEN）

## 状态

**诊断完成，待执行**。因主会话上下文临界（77%）暂不派发 executor，留待新会话 resume，
避免 worktree 隔离任务半途耗尽上下文导致悬空 worktree。
