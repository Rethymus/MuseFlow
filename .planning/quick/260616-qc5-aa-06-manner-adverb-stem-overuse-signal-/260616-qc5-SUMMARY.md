---
phase: quick-260616-qc5
status: complete
quick_id: 260616-qc5
slug: aa-06-manner-adverb-stem-overuse-signal-
date: 2026-06-16
tests_added: 2
tests_total: 1645
analyze: 0
---

# AA-06：叠词/程度副词堆砌信号（分布性 AI 寄存器过度依赖）

## What
新增第 8 个 review signal `叠词/程度副词堆砌`，覆盖 `_buildReviewSignals` 此前缺失的**叠词 softener 词干分布性过度使用**——中文 AI 文本最典型 tell 之一。

## Why
既有 7 个信号（转场/类型/结尾/句长/结构/情感/描写）全基于**固定短语**或**句长节奏**。`_synonymMap`（20 类 200+ 条）只捕固定短语（"缓缓说道"）；但作者/AI 在任意动词上反复用同一批叠词（缓缓起身/缓缓推门/缓缓抬手）时，无信号反馈。这是与固定短语正交的**分布性寄存器过度依赖**失败模式——反AI味产品灵魂的真实缺口。

## Changes
- **lib/features/ai/application/anti_ai_scent_processor.dart**
  - 新增 `_mannerAdverbStems`（10 裸 2 字叠词词干：缓缓/微微/淡淡/轻轻/深深/默默/静静/渐渐/隐隐/悄悄），doc 注释点明与 synonym map 的正交性。
  - `_buildReviewSignals` 末尾加 count 信号：≥5 fire / ≥8 high，evidence '$count 次'。阈值校准于 `process()` 粒度（editor_ai_notifier:256 的 `progressText`，单次 AI 输出段落级）。
- **test/features/ai/application/anti_ai_scent_test.dart**
  - 测试 1：6 词干密集文本 → 触发 + medium（<8 high 阈值），evidence 含 '次'。
  - 测试 2：1 词干稀疏自然文本 → 不触发（精度负向，防阈值回归误报）。

## Orthogonality / precision verification
- 10 词干全为 2 字叠词，互不子串重叠。
- 与 synonym map 正交：synonym map 捕固定短语，本信号捕裸词干跨任意动词——不同失败模式。
- 回归安全：全测试集最大词干密度 1/行（既有用 缓缓/微微 短语的测试各仅 1-2 词干 < 5 阈值），无既有测试误触发；全测试集无 `reviewSignals.length`/`hasLength` 断言。

## Verification
- `flutter analyze`：No issues found (0)。
- targeted 文件：57/57 全绿（2 新 AA-06 + 既有信号测试零回归）。
- 全量 `flutter test`：**+1645 ~12，All tests passed**（baseline 1643 + 2，零回归）。
- 红线守住：既有 7 信号未触碰；信号标题与现有无冲突。

## Result
反AI味信号矩阵补全分布性寄存器维度。任何类型创作（genre-agnostic）得叠词堆砌反馈。
