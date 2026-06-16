---
phase: quick-260616-qmq
plan: 01
subsystem: editor/application
tags: [anti-ai-scent, sentence-level, intensifier, product-soul, aa-04]
status: complete
requires:
  - lib/features/editor/application/sentence_ai_scent_analyzer.dart (_score 4 signals, feeds 最可疑的句子 panel)
provides:
  - "SentenceAiScentAnalyzer 第 5 信号：空洞强调词堆砌（emptyIntensifiers 集合，3+/句触发）"
  - "句子级 AI 填充 tell 覆盖——4 既有信号（过渡起句/AI套式/虚词占比/超长无断句）的盲区"
affects:
  - 编辑器「最可疑的句子」面板多一类 AI 味归因；作者得精准到句的强调词堆砌反馈
tech-stack:
patterns:
  - "Sibling Set<String> emptyIntensifiers（2 字强调词）+ 句内 hit 计数，与 transitionStarts/functionChars 同位"
  - "阈值 ≥3 hit/句 → +30（与 run-on 同档，单触发即 notable）"
key-files:
  modified:
    - lib/features/editor/application/sentence_ai_scent_analyzer.dart
    - test/features/editor/application/sentence_ai_scent_analyzer_test.dart
decisions:
  - "正交性已验证：'她真是非常十分开心' 的 functionChars 占比 2/8=0.25<0.4（信号3不触发），无 AI 套式（信号2）、无过渡起句（信号1）、<40字（信号4）——4 信号全漏，唯独新信号能捕"
  - "强调词非 functionChars（真是/十分/非常 是实词性程度副词），故 function-ratio 信号结构性漏检"
  - "阈值 ≥3 hit/句保证精度：1-2 个强调词为正常修辞，3+ 为空洞填充；加负向测试锁定"
  - "回归安全：全测试集强调词密度 0（既有句均无），hasNotable 人工文本测试不受影响"
requirements:
  - AA04B-SENTENCE-INTENSIFIER
---

# AA-04b：句子级空洞强调词堆砌信号

## 背景
`SentenceAiScentAnalyzer._score` 现有 4 信号（机械过渡词起句/AI套式/虚词占比过高/超长无断句），喂「最可疑的句子」面板。无一覆盖**句内空洞强调词堆砌**（真是/十分/非常/简直…）——典型 AI 填充 tell。强调词是实词性程度副词，非 functionChars，故 function-ratio 信号（信号3）结构性漏检。

## Tasks
1. TDD（RED）：① 3 强调词句触发 + score≥notable + reasons 含'强调'；② 1 强调词句不触发（精度负向）。
2. GREEN：加 `emptyIntensifiers` Set（12 词）+ `_score` 信号5（≥3 hit → +30，reason '空洞强调词堆砌'）。
3. 验证：analyze 0 + targeted 全绿 + 全量 ≥1647（1645+2）零回归；红线：既有 4 信号不碰、hasNotable 人工文本测试不破。

## Verification
- analyze 0；targeted（2 新 + 既有句级测试）全绿；全量 ≥ 1647 零回归。
