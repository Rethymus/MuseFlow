---
phase: quick-260616-ci2
plan: 01
subsystem: ai/application
tags: [paths, dialogue-act, prompt-pipeline, response-strategy, middleware]
requires:
  - 260614-ci1 (DialogueActClassifier + DialogueAct enum, pure logic, 9 tests)
  - lib/features/ai/application/prompt_pipeline.dart (PromptMiddleware contract, withDefaultMiddlewares)
provides:
  - "DialogueActMiddleware（首个 DialogueActClassifier 消费方，PATHs 响应策略路由）"
  - "四种 actionable 行为的中文响应策略注入（合并进 system 消息）"
affects:
  - 默认 prompt 管线：用户 refine instruction 现在按对话行为适配系统指令
tech-stack:
  added: []
  patterns:
    - "PromptMiddleware.apply 合并进 messages[0]（与 PersonaInjection/BannedList 一致，replaceSystemMessage）"
    - "no-op 三态守门：null/空 instruction、confidence==0、followUp"
key-files:
  created:
    - lib/features/ai/application/prompt_middlewares/dialogue_act_middleware.dart
    - test/features/ai/application/dialogue_act_middleware_test.dart
  modified:
    - lib/features/ai/application/prompt_pipeline.dart
decisions:
  - "merge（replaceSystemMessage 进 messages[0]）而非 addMessage：与 PersonaInjection/BannedList 架构约定一致，单一 system 消息，既有 order 测试无需改动即通过"
  - "followUp 不放策略 map：追问深入走默认深度（给更多细节是最安全的非破坏性响应），避免对每次模糊 refine 注入噪音"
  - "confidence==0 时 no-op：纯模糊无信号消息不注入，尊重 classifier 设计"
  - "middleware 紧随 SystemPromptMiddleware 之后注册：base 角色定义在前，行为适配在后，正交"
metrics:
  duration: ~12min
  completed: 2026-06-16
  tasks_completed: 3
  files_changed: 3
  tests_added: 11
  tests_total: 1632 passed / 12 skipped (基线 1621/12)
requirements:
  - CI-01-WIRING
---

# Phase quick-260616-ci2 Plan 01: CI-01 DialogueAct→响应策略路由 Summary

将已交付的纯逻辑 `DialogueActClassifier`（260614-ci1，全库零消费方）接入 prompt pipeline——新建 `DialogueActMiddleware`，读用户的 refine instruction，按 PATHs 对话行为（风格调整/内容探索/意图修订/内容注入）注入中文响应策略系统指令，让 AI 不再把每次 refine 一视同仁，而是按作者意图调整响应方式。

## What Changed

### `lib/features/ai/application/prompt_middlewares/dialogue_act_middleware.dart`（新建，~70 行）

- `class DialogueActMiddleware extends PromptMiddleware`，const 构造
- `static const Map<DialogueAct, String> _strategies`：4 个 actionable 行为的中文响应策略
  - `styleAdjustment` → 尊重风格偏好，仅调语气措辞，不改情节
  - `contentExploration` → 提供分支方向，标注为可选非定稿
  - `intentRevision` → 重新对齐真实意图，丢弃上一版
  - `injection` → 忠实融入所求内容，不删改既有主体
  - （`followUp` 故意缺席——追问深入走默认深度，避免噪音）
- `apply()` 三态 no-op 守门：
  1. `additionalInstruction` null/空/whitespace → no-op（首次 synthesis 无 refine）
  2. `confidence == 0` → no-op（纯模糊无信号，给深度是最安全默认）
  3. `_strategies[act] == null`（即 followUp）→ no-op
- 注入方式：**merge 进 messages[0]**（与 PersonaInjection/BannedList 一致）——`replaceSystemMessage(0, systemContent + '\n\n【响应策略·${label}】${strategy}')`；messages 空时退回 addMessage
- `_extractContent` helper 镜像既有两个 middleware

### `lib/features/ai/application/prompt_pipeline.dart`（+2 行）

- import 块（字母序）加 `dialogue_act_middleware.dart`（contrastive 与 dynamic 之间）
- `withDefaultMiddlewares` middlewares 列表：在 `SystemPromptMiddleware()` 之后插入 `const DialogueActMiddleware()`

### `test/features/ai/application/dialogue_act_middleware_test.dart`（新建，123 行）

11 测试，3 group：

| Group | Test | 期望 |
|-------|------|------|
| no-op cases | null instruction | messages empty |
| no-op cases | empty instruction | messages empty |
| no-op cases | whitespace instruction | messages empty |
| no-op cases | "好的"（无信号 confidence 0） | messages empty |
| no-op cases | "为什么这么写"（followUp 有信号无策略） | messages empty |
| strategy injection | "改成口语风格" | 含「响应策略·风格调整」+「风格偏好」+ 1 条消息 |
| strategy injection | "如果换一种方向会怎样" | 含「内容探索」+「分支方向」 |
| strategy injection | "不对，我要的是紧张感" | 含「意图修订」+「真实意图」 |
| strategy injection | "加一段对话" | 含「内容注入」+「忠实融入」 |
| pipeline integration | withDefaultMiddlewares + 风格 refine | 含策略系统消息 |
| pipeline integration | 无 instruction | 不含「响应策略」（首次 synthesis 干净） |

## 关键架构决策

### merge 而非 addMessage（避免破坏既有约定）

初版用 `addMessage(ChatMessage.system(...))` 新增独立系统消息，撞上 `prompt_pipeline_test.dart: should apply middlewares in correct order`——该测试传 `additionalInstruction: '注意语气'`（"语气"是 styleAdjustment 信号）并断言 `messages.length == 2`。

调研发现 PersonaInjectionMiddleware + BannedListMiddleware **都用 `replaceSystemMessage(0, ...)` 合并进 messages[0]**（这是 system-layer middleware 的架构约定，单一 system 消息）。改为 merge 后：strategy 并入 messages[0]，既有 order 测试的 contains 断言仍成立，messages 仍 2 条——**零破坏通过**。

### followUp 故意无策略

PATHs 五行为何只 wire 四个？`followUp`（追问深入）的策略本质是"给更多深度"——这本来就是 synthesis 的默认行为。对每次含"为什么/展开"的 refine 注入一条策略系统消息是纯噪音。故 followUp 走 no-op，让默认深度行为自然生效。

## Verification Outputs

### `flutter test test/features/ai/application/dialogue_act_middleware_test.dart`
```
00:00 +11: All tests passed!
```

### `flutter test test/features/ai/application/dialogue_act_middleware_test.dart test/features/ai/application/prompt_pipeline_test.dart`（含原 order 测试）
```
00:00 +38: All tests passed!
```

### `flutter analyze`（全库）
```
Analyzing MuseFlow...
No issues found! (ran in 2.1s)
```

### 全量 `flutter test`
```
01:52 +1632 ~12: All tests passed!
```
（基线 1621 → 1632，+11 新增，零回归）

### 红线（`git diff --name-only`）
```
lib/features/ai/application/prompt_pipeline.dart          (+2 行)
lib/features/ai/application/prompt_middlewares/dialogue_act_middleware.dart  (新建)
test/features/ai/application/dialogue_act_middleware_test.dart              (新建)
```
**未触及** `dialogue_act_classifier.dart` / `domain/dialogue_act.dart` / `synthesis_notifier.dart`（纯消费，自动透传——synthesisNotifier.regenerate(instruction) → PromptContext.additionalInstruction → middleware 链，UI 无感）。

## Deviations from Plan

1. **apply 注入方式**：PLAN 初稿写 `addMessage`，实现时发现与 PersonaInjection/BannedList 的 merge 约定冲突（撞 order 测试），改为 `replaceSystemMessage` 合并进 messages[0]。这是对架构约定的遵循，比 PLAN 初稿更正确。
2. **测试数**：PLAN 写 8 测，实际 11 测（pipeline integration 拆为 2 个：注入 + 干净，覆盖更全）。

## Known Stubs

None。wiring 端到端真实：用户在 synthesis 面板 regenerate 输入 refine 文本 → DialogueActClassifier 分类 → middleware 注入策略 → LLM 收到行为适配指令。无 mock/placeholder。

## Threat Flags

None。无新增网络端点、无认证路径、无新依赖。STRIDE 分析见 PLAN `<threat_model>`：用户 instruction 只影响"响应策略措辞"这一中文系统消息，不改变代码执行路径；分类误导最坏情况是策略措辞不贴切，无安全影响。

## Self-Check: PASSED

- [x] `DialogueActMiddleware` 实现 PromptMiddleware，按 act 注入中文响应策略
- [x] 四种 no-op（null/空/confidence0/followUp）正确避免噪音
- [x] 管线注册紧随 SystemPromptMiddleware
- [x] merge 进 messages[0]，与 PersonaInjection/BannedList 约定一致
- [x] 全库零回归，analyze 0，1632 tests
- [x] 红线守住：classifier / dialogue_act.dart / synthesis_notifier 零改动
