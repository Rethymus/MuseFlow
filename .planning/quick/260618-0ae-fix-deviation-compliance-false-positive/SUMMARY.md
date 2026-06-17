---
quick_id: 260618-0ae
slug: fix-deviation-compliance-false-positive
status: complete
date: 2026-06-18
commit: 4b452d3
---

# 修复偏差检测把合规确认误报为偏差的假警报（真实 GLM key 暴露）

## 触发
真实 BigModel key E2E 复验 wma 重试修复：30 章 serial journey `All tests passed!`（exit 0，30/30 生成、0 错误、重试修复对真实 API 完全验证）。journey 末尾偏差检测阶段跑在**真实 GLM 生成的 30 章文本**上，`[DEVIATION] Warnings: 80 across 30 chapters`——其中大量是合规确认假警报，确定性测试（canned JSON）永远抓不到。

## 根因（PUA 铁律一：真实 journey 实证，不猜）
真实 GLM 把**合规确认**当成偏差返回，污染信号：
- Ch1 全部 11 条 `clear` 警告都是合规陈述——「林风没有学习其他峰的功法，**符合**…的设定」「文本中未提及火器，**符合**…」「**并未违反**…的设定」——零真实违背。
- 真实违规用「违背了/违反了」（Ch2+ 的 medium 警告），合规用「符合/未违反/并未违反」——可精准区分。
- `_buildPrompt`（112-126）指令「检查…是否违背…只报告 medium 或 clear」**未禁止报合规项**，LLM 把「我检查了，没违背」也当结果返回。
- `_parseResult`（128-148）只 `where(severity != low)`，**不识别合规语义** → 合规项以 clear/medium 漏进 warnings。

## 修复（双保险）
- **①prompt 强化**：显式「只报告【真实违背】设定的问题；符合/未违反/并未违反的合规项一律不要报告」。保留既有「只报告 medium 或 clear」子串（既有测试 line 48 依赖，零破坏）。
- **②parser 兜底**：`_isComplianceNoise(description)` 过滤——description 含合规标记（`符合|未违反|并未违反|没有违反|未违背`）且**不含**真违规标记（`违背|违反了`）则丢弃。关键：「违反了」（带"了"肯定句）≠「未违反/并未违反」（否定式），故 `_violationMarkers=违背|违反了` 精准区分——「并未违反」含子串"违反"但不带"了"→不触发违规标记→被合规标记正确丢弃。防御真实 LLM 不守 prompt，与既有防御性 catch / `_parseResult` 容错哲学一致。

## 验证（确定性，不烧 quota）
- TDD 2 RED→GREEN：①合规 fixture（Ch1 真实 3 条合规 clear）→ pre-fix 返回 3 / post-fix **空**；②mix（1 真违规「违背了」+ 1 合规「符合」）→ pre-fix 2 / post-fix **1**（保留真违规丢合规）。
- 既有 4 测试零回归（含 prompt 含「只报告 medium 或 clear」断言 + DeviationWarning 消费方）。
- `flutter analyze` **0 issues**（全量）。
- deviation service +6 / deviation widget +5 全绿。
- 真实实证已由 journey 捕获（Ch1 11 条合规误报 clear、80 warnings 全景），不依赖重跑。

## 暂留
- 仅修了 compliance-noise 这一类最明显的假警报；真实 GLM 偶发的「可能暗示…」（speculative、无合规/违规标记）仍会保留为 warning——属弱信号非噪音，故意不过滤（避免误杀真问题）。
- 与 wma「诊断黑箱」同族：真实 key 暴露、合成测试抓不到的 LLM 行为差异。
