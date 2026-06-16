---
phase: quick-260616-sy1
plan: 01
subsystem: ai/presentation
tags: [anti-ai-scent, synthesis, review-signals, symmetry, product-soul]
status: complete
requires:
  - lib/features/ai/application/anti_ai_scent_processor.dart (ProcessingResult.reviewSignals)
  - lib/features/editor/application/editor_ai_notifier.dart (proven reviewSignals copyWith pattern)
  - lib/features/editor/presentation/status_bar.dart (_ReviewSignalSummary render pattern)
provides:
  - "SynthesisState.reviewSignals 字段（与 editor_ai_state.reviewSignals 对称）"
  - "合成面板「AI修改复查」摘要条（_SynthesisReviewSummary）"
affects:
  - 碎片→段落合成（产品核心流程）现可显示 8 类反AI味评审信号，与 editor 改写流程对称
tech-stack:
  added: []
  patterns:
    - "镜像 editor_ai_notifier._postProcess 的 reviewSignals copyWith"
    - "镜像 status_bar._ReviewSignalSummary 的 severity→color 渲染（独立私有 widget）"
    - "reviewSignals 非空才渲染（避免噪音）"
key-files:
  created:
    - test/features/ai/presentation/synthesis_panel_test.dart
  modified:
    - lib/features/ai/presentation/synthesis_notifier.dart
    - lib/features/ai/presentation/synthesis_panel.dart
    - test/features/ai/presentation/synthesis_notifier_test.dart
decisions:
  - "_SynthesisReviewSummary 独立私有 widget，不 import status_bar 的私有类——避免跨文件耦合，~50 行重复可接受"
  - "reviewSignals 用 `?? this.` 语义（与 highlights 一致），非 nullable 直接覆盖（与 error 一致）"
  - "reviewSignals 非空才渲染摘要条——干净文本不显示，避免噪音"
  - "synthesis_notifier 已 import anti_ai_scent_processor（line 19），ReviewSignal 类型直接可用"
metrics:
  duration: ~15min
  completed: 2026-06-16
  tasks_completed: 3
  files_changed: 4
  tests_added: 5
  tests_total: 1637 passed / 12 skipped (基线 1632/12)
requirements:
  - SY1-WIRING
---

# Phase quick-260616-sy1 Plan 01: synthesis 接入 AntiAIScent reviewSignals Summary

闭合产品核心流程（碎片→成文）的反AI味作者反馈缺口。`AntiAIScentProcessor.process()` 的 `result.reviewSignals` 此前在 synthesis 流程被 `_postProcess` 丢弃——editor 流程早已正确接入。本任务让两条流程对称。

## 诊断（PUA 证据先行，本会话核验）

| 流程 | processor 调用 | reviewSignals 接入 |
|------|---------------|-------------------|
| editor（`editor_ai_notifier.dart:255-277`） | ✅ | ✅ `copyWith(reviewSignals: [...result.reviewSignals, ...intentSignals])` → editor_ai_state → status_bar |
| synthesis（`synthesis_notifier.dart:319`） | ✅ | ❌ **只取 highlights，丢弃 reviewSignals；state 无字段；panel 不渲染** |

注：本会话初判 `AntiAIScentProcessor` "零消费方" 是错的（grep 异常），直接读文件确认它经 `antiAIScentProcessorProvider` 被 synthesis_notifier:315 消费。**真缺口是 reviewSignals 在 synthesis 流程被丢弃**，非 processor 死代码。

## What Changed

### `lib/features/ai/presentation/synthesis_notifier.dart`
- `SynthesisState` 加 `final List<ReviewSignal> reviewSignals;`（默认 const []），构造 + copyWith（`?? this.` 语义）
- `_postProcess`（state = copyWith）补 `reviewSignals: result.reviewSignals,`

### `lib/features/ai/presentation/synthesis_panel.dart`
- import `anti_ai_scent_processor.dart`（ReviewSignal / ReviewSignalSeverity）
- editing 分支改 Column：`_SynthesisReviewSummary`（仅 reviewSignals 非空时）+ `Expanded(TextField)`
- 新增私有 `_SynthesisReviewSummary`：取最高 severity 信号、high→error/medium→tertiary/low→onSurfaceVariant、淡色背景容器 + Tooltip(description+evidence)、显示「N 条AI修改复查：${title}」

### `test/features/ai/presentation/synthesis_notifier_test.dart`（+3 测）
- `reviewSignals should default to empty`
- `copyWith should update and preserve reviewSignals`（设置/保留/替换）
- `should expose reviewSignals after anti-AI-scent processing (SY-01)`——stream `'与此同时，他来了。就在这时，门开了。'`（2 转场套话触发 '转场套话偏多'），断言 `state.reviewSignals` 非空且含「转场套话」

### `test/features/ai/presentation/synthesis_panel_test.dart`（新建，+2 测）
- provider override 注入带 2 signals（medium+high）的 SynthesisState → 断言渲染「AI修改复查」+「结尾悬念公式化」（high 领衔）
- 空 signals → 断言不渲染（无噪音）

## 关键技术点

**信号在原文上算**：processor `_buildReviewSignals(text, ...)`（synthesis_notifier:619）传的是**原文** `text`，非 processedText。即便 transition cliches 被 auto-delete，信号仍在原文上触发——测试文本据此构造，2 hits ≥2 阈值。

**TDD 真红灯**：先写测试，编译失败（`No named parameter 'reviewSignals'`）——真 RED 非假绿；实现后 GREEN。

## Verification Outputs

### targeted（GREEN 确认）
```
00:14 +29: All tests passed!
```

### `flutter analyze`（全库）
```
Analyzing MuseFlow...
No issues found! (ran in 5.1s)
```

### 全量 `flutter test`
```
01:54 +1637 ~12: All tests passed!
```
（基线 1632 → 1637，+5 新增，零回归）

### 红线（`git status --short`）
```
 M lib/features/ai/presentation/synthesis_notifier.dart
 M lib/features/ai/presentation/synthesis_panel.dart
 M test/features/ai/presentation/synthesis_notifier_test.dart
?? test/features/ai/presentation/synthesis_panel_test.dart
```
**未触及** anti_ai_scent_processor / editor_ai_notifier / status_bar / prompt_pipeline。

## Deviations from Plan

无。实现与 PLAN 完全一致。dart format 重排了部分格式（import 顺序、`overrideWith` 换行），无逻辑变更。

## Known Stubs / Threat Flags

None。端到端真实：用户在合成面板「AI 整理」生成文本后，编辑区上方显示「N 条AI修改复查：${最高severity信号title}」+ Tooltip 详情，与 editor 改写流程对称。无 mock/placeholder。STRIDE 见 PLAN（纯本地状态/UI，无新增攻击面）。

## Self-Check: PASSED

- [x] SynthesisState.reviewSignals 字段贯通 _postProcess → state
- [x] synthesis_panel 渲染「AI修改复查」摘要（非空才显示）
- [x] 与 editor 流程对称性达成
- [x] 全库零回归（1637 tests），analyze 0，红线守住
