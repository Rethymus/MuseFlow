---
quick_id: 260618-0ae
slug: fix-deviation-compliance-false-positive
status: in-progress
date: 2026-06-18
---

# 修复偏差检测把合规确认误报为偏差的假警报（真实 GLM key 暴露）

## 触发
真实 BigModel key E2E 复验 wma 重试修复（30 章 serial journey，30/30 生成、0 错误、重试修复验证通过）。journey 末尾偏差检测阶段跑在**真实 GLM 生成的 30 章文本**上，暴露确定性测试永远抓不到的产品质量 bug。

## 根因（已查清，真实 GLM journey 实证）
真实 GLM 把**合规确认**当成偏差返回，污染信号：
- Ch1 全部 11 条 `clear` 警告都是合规陈述——「林风没有学习其他峰的功法，**符合**…的设定」「文本中未提及火器，**符合**…」「**并未违反**…的设定」——零真实违背。
- 真实违规用「违背/违反」（Ch2+ 的 medium 警告），合规用「符合/未违反」——可精准区分。
- `deviation_detection_service._buildPrompt`（112-126）指令「检查…是否违背…只报告 medium 或 clear 级别的问题」——**未禁止报合规项**，LLM 把「我检查了，没违背」也当结果返回。
- `_parseResult`（128-148）只 `where(severity != low)`，**不识别合规语义** → 合规项以 clear/medium 漏进 warnings。

## 修复（双保险，与 wma「诊断黑箱」同族——真实 key 暴露、合成测试抓不到）
1. **prompt 强化**：显式「只报告**真实违背**设定的问题；符合 / 未违反 / 并未违反的**合规项不要报告**（那是正常，不是问题）」。保留既有「只报告 medium 或 clear」子串（既有测试 line 48 依赖）。
2. **parser 兜底**：`_parseResult` 增 `_isComplianceNoise(description)` 过滤——description 含合规标记（`符合|未违反|并未违反|没有违反|未违背`）且**不含**违规标记（`违背|违反`）则丢弃。防御真实 LLM 不守 prompt，与既有防御性 catch / `_parseResult` 容错哲学一致。

## 任务
- T1: RED 测试——喂 Ch1 真实合规响应 fixture（3 条合规 clear）断言 warnings 为空；mix 测试（1 真违规 + 1 合规）断言保留 1 条。→ pre-fix RED
- T2: prompt + parser 双修 → GREEN
- T3: targeted 偏差测试 + flutter analyze 0

## 验证（确定性，不烧 quota）
- RED：合规 fixture 返回 3 条 warnings（应为 0）；mix 返回 2 条（应为 1）。
- GREEN：合规 fixture → 0；mix → 1（保留真违规，丢合规）。
- 既有 4 测试零回归（含 prompt 含「只报告 medium 或 clear」断言）。
- analyze 0。
- 真实实证已捕获（journey Ch1 11 条合规误报 clear），不依赖重跑。
