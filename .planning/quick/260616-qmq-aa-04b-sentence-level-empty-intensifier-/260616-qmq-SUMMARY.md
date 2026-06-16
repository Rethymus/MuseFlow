---
phase: quick-260616-qmq
status: complete
quick_id: 260616-qmq
slug: aa-04b-sentence-level-empty-intensifier-
date: 2026-06-16
tests_added: 2
tests_total: 1647
analyze: 0
---

# AA-04b：句子级空洞强调词堆砌信号

## What
SentenceAiScentAnalyzer 加第 5 个信号 `空洞强调词堆砌`，句内 3+ 空洞强调词（真是/十分/非常/简直…）触发。喂编辑器「最可疑的句子」面板。

## Why
既有 4 句级信号（机械过渡词起句/AI套式/虚词占比/超长无断句）无一覆盖句内强调词堆砌——典型 AI 填充 tell。强调词是实词性程度副词，**非 functionChars**，故 function-ratio 信号（信号3）结构性漏检。正交性已验证：「她真是非常十分开心」functionChars 占比 2/8=0.25<0.4（信号3不触发）、无套式/过渡起句/<40字——4 信号全漏，唯独新信号能捕。

## Changes
- **lib/features/editor/application/sentence_ai_scent_analyzer.dart**
  - 新增 `emptyIntensifiers` Set（12 词：真是/简直/十分/非常/尤其/格外/颇为/相当/无比/极其/尤为/极为）。
  - `_score` 信号5：句内 hit 计数 ≥3 → +30（与 run-on 同档，单触发即 notable），reason '空洞强调词堆砌'。
- **test/features/editor/application/sentence_ai_scent_analyzer_test.dart**
  - 测试 1：3 强调词句 → 触发 + score≥notable + reasons 含'强调'。
  - 测试 2：1 强调词句 → 不触发（精度负向）。

## Verification
- `flutter analyze`：0。
- targeted 文件：11/11（2 新 + 既有句级测试零回归；hasNotable 人工文本精度测试仍通过）。
- 全量：**+1647 ~12，All tests passed**（baseline 1645 + 2，零回归）。
- 红线守住：既有 4 信号未触碰；强调词全测试集密度 0，无既有句误触发。

## Result
句子级 AI 味归因多一类，「最可疑的句子」面板对空洞填充更敏感。与 AA-06 整体叠词信号正交（不同词族、不同粒度、不同消费者）。
