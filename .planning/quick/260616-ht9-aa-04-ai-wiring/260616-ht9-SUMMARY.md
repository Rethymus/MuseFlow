---
phase: quick-260616-ht9
plan: 01
subsystem: editor (anti-AI-scent presentation)
tags: [anti-ai-scent, editor, presentation, aa-04, wiring]
requires:
  - "260614-aa4 SentenceAiScentAnalyzer 纯逻辑已交付（9 测试全绿）"
  - "Phase 19 StyleDeviationDetector + StyleThermometerDashboard"
provides:
  - "StyleDeviationResult.text 字段（向后兼容，默认空串）"
  - "StyleThermometerDashboard 渲染「最可疑的句子」section（≤3 句 + 分数徽章 + reasons）"
  - "_SentenceAiScentSection / _SentenceScoreRow 私有 widget"
  - "3 widget 测试覆盖 section 三态（AI 套式句 / fresh 自然句 / 空文本）"
affects:
  - "lib/features/editor/application/style_deviation_detector.dart"
  - "lib/features/editor/presentation/style_thermometer_dashboard.dart"
  - "test/features/editor/sentence_ai_scent_panel_test.dart"
tech-stack:
  added: []
  patterns:
    - "TDD RED→GREEN（先写失败测试再加 section）"
    - "Single-responsibility StatelessWidget（_SentenceAiScentSection / _SentenceScoreRow）"
    - "复用既有 _scoreColor 着色函数（避免重复调色逻辑）"
    - "hasNotable gate 二次过滤（section 内部静默返回 SizedBox.shrink）"
    - "默认空串字段（向后兼容式扩展）"
key-files:
  created:
    - "test/features/editor/sentence_ai_scent_panel_test.dart"
  modified:
    - "lib/features/editor/application/style_deviation_detector.dart"
    - "lib/features/editor/presentation/style_thermometer_dashboard.dart"
decisions:
  - "StyleDeviationResult.text 用 `this.text = ''` 默认空串（非 required），保证全库零破坏，无需同步改 notifier/card"
  - "section 仅当 `result.text.isNotEmpty` 时挂载，且内部 `!hasNotable` 时返回 SizedBox.shrink（双重 gate）"
  - "reasons 用 Wrap 渲染（小字 + onSurfaceVariant），符合 dashboard 现有 bodySmall/labelSmall 视觉语言"
metrics:
  duration: "~15 min"
  completed: 2026-06-16
  tasks: 3/3
  files_changed: 3
  tests_added: 3
  tests_total: 1621
---

# Phase quick-260616-ht9 Plan 01: AA-04 句子级 AI 痕迹面板 wiring Summary

把已交付的纯逻辑 `SentenceAiScentAnalyzer`（260614-aa4）接入 `StyleThermometerDashboard`，让作者在「AI 痕迹分析」对话框里直接看到「最可疑的句子」+ 分数 + reasons —— 把 Phase 19 的整体温度计细化为句子级 actionable 反馈。

## What Changed

### Task 1 — `StyleDeviationResult` 加 text 字段（commit `a13c87e`）

`lib/features/editor/application/style_deviation_detector.dart`：
- 给 `StyleDeviationResult` 加 `final String text;`（带文档注释「The source text that was analyzed, for downstream sentence-level tooling.」），位置在 `hasDeviations` 之后
- 构造函数加 `this.text = ''`（默认空串，向后兼容：全库仅 2 处构造点，无外部直接构造）
- `analyze()` 返回处加 `text: text,`（`text` 是 analyze 的命名必填参数，已在作用域）
- notifier / card 零改动（透传 + 字段独立）

### Task 2 — Dashboard 加「最可疑的句子」section（commit `fe53b0d`，TDD）

`lib/features/editor/presentation/style_thermometer_dashboard.dart`：
- 顶部 import `sentence_ai_scent_analyzer.dart`
- `build()` 末尾：`if (result.text.isNotEmpty) ...[ SizedBox(16), _SentenceAiScentSection(text: result.text) ]`
- 新增 `_SentenceAiScentSection`（StatelessWidget + const 构造）：
  - 调用 `const SentenceAiScentAnalyzer().analyze(text, maxSentences: 3)`
  - `!hasNotable` 返回 `SizedSection.shrink()`（双重 gate 避免噪音）
  - 标题 `Text('最可疑的句子', titleSmall + bold)` —— 测试断言锚点
  - 每句渲染 `_SentenceScoreRow`
- 新增 `_SentenceScoreRow`（StatelessWidget）：
  - Row：Expanded 句子片段（bodySmall，maxLines 2，ellipsis）+ 分数徽章 Container（圆角 12，背景 `_scoreColor(score).withValues(alpha: 0.15)`，前景 `_scoreColor(score)` + bold）
  - reasons：Wrap 渲染，labelSmall + onSurfaceVariant，fontSize 11

### 测试新增（commit `fe53b0d`）

`test/features/editor/sentence_ai_scent_panel_test.dart`（3 widget 测试）：
1. **should render sentence section when text has AI-tell sentence** — `"不仅如此，而且在这个快速发展的时代，一切都显得尤为重要。"` → `find.text('最可疑的句子')` findsOneWidget + `find.text('AI套式句式')` findsWidgets
2. **should not render sentence section when text is fresh and natural** — `"他推开门，看见她在窗边。风很大。"` → findsNothing（hasNotable false）
3. **should not render sentence section when text is empty** — `""` → findsNothing

## Verification Outputs

### Task 1 — `flutter analyze`（detector + notifier + card）
```
Analyzing 3 items...
No issues found! (ran in 1.2s)
```

### Task 2 — `flutter test test/features/editor/sentence_ai_scent_panel_test.dart`
```
00:00 +1: should render sentence section when text has AI-tell sentence
00:00 +2: should not render sentence section when text is fresh and natural
00:00 +3: should not render sentence section when text is empty
00:00 +3: All tests passed!
```
RED 阶段先确认测试 1 失败（section 不存在），GREEN 后三测全绿。

### Task 3 — 全量回归
```
Analyzing MuseFlow...
No issues found! (ran in 3.1s)
---ANALYZE---
01:54 +1621 ~12: All tests passed!
```
- `flutter analyze`: **0 issues**
- `flutter test`: **1621 passed** (1618 baseline + 3 新增，符合 ≥1621 目标)，12 个 skip 为既有

### 红线守卫
- `git diff --name-only HEAD~2 HEAD` 仅含 3 文件：
  - `lib/features/editor/application/style_deviation_detector.dart`
  - `lib/features/editor/presentation/style_thermometer_dashboard.dart`
  - `test/features/editor/sentence_ai_scent_panel_test.dart`
- **`lib/features/editor/application/sentence_ai_scent_analyzer.dart` 零改动**（仍是 200 行原状）
- dashboard 379 行（< 400 上限）

## Deviations from Plan

None — plan 执行完全按 3 task 原文。`find.textContaining().or()` 链式断言在 plan `<action>` 内已预先提示不存在，按 plan 指引改用 `find.text('AI套式句式')` 单独断言，无 deviation。

## Auth Gates

None.

## Known Stubs

None。section 完整接入真实 analyzer，无 placeholder/TODO/mock 数据。

## Threat Flags

None。`<threat_model>` 中 T-ht9-01 / T-ht9-02 / T-ht9-03 全部 `accept`，section 渲染路径已按 mitigation 实现（maxSentences=3 限制 UI 行数，ellipsis 截断，无新增网络/信任边界）。

## Self-Check: PASSED

- 文件存在：
  - FOUND: lib/features/editor/application/style_deviation_detector.dart
  - FOUND: lib/features/editor/presentation/style_thermometer_dashboard.dart
  - FOUND: test/features/editor/sentence_ai_scent_panel_test.dart
- 提交存在：
  - FOUND: a13c87e (feat(editor): AA-04 StyleDeviationResult 加 text 字段)
  - FOUND: fe53b0d (feat(editor): AA-04 句子级 AI 痕迹面板)
- 测试 1621 全绿，analyze 0 issues
