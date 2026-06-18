---
quick_id: 260618-vm1
slug: glm-ai-state-release-blocker-banned-phra
date: 2026-06-18
status: complete
commit: 1eb9f0d
files_changed:
  - test/features/ai/application/anti_ai_scent_real_glm_test.dart (new)
---

# 反 AI 味检测词库 — 真实 GLM 散文验证

## 交付 / What

新增 `anti_ai_scent_real_glm_test.dart`，闭合 STATE release blocker「Anti-AI-scent banned
phrase lists should be validated with broader real Chinese prose samples before release
sign-off」。反 AI 味是产品灵魂——既有 57 个 canned 测试用静态 fixture，从未对真实 LLM 产出
验证词库。本测试用真实 GLM-4-flash 生成 AI 散文，证明内部词库（synonymMap/structuralPatterns/
mannerAdverbStems/emptyIntensifiers/genre cliches）对真实模型产出确实 fire。

## 设计 / Design

- **显式 AI 风格 prompt**（叠词/程度副词/华丽结构）→ 真实 GLM 生成。烟测已证 GLM-4-flash 可靠
  产出 淡淡/微微/格外/颇为/仿佛/宛如（6/10 目标词命中），使"检测器触发"断言对模型非确定性鲁棒。
- `AntiAIScentProcessor().process(glmText, bannedPhrases: [])`——空 user 列表，纯测内部词库
  （blocker 所指"banned phrase lists"）。
- 断言：processedText 规范（非空 + ≤源+80，processor 只替换/标【】不膨胀）+ **检测器 fire**
  （highlights 或 reviewSignals 非空）+ 每 signal severity 合法 + debugPrint 信号明细。
- processor 纯函数，无需 Hive/ensureInitialized（无 HTTP mock 风险）。

## 证据 / Evidence（真实 GLM）

88 字散文「缓缓流淌的仙溪…淡淡云雾缭绕，仿佛置身于仙境之中…格外清新…颇为神秘，宛如一幅绝美画卷」→
**highlights=2, reviewSignals=1（[medium] 句长节奏过于整齐 76%）**。词库对真实 AI 散文确实 fire。

## 验证 / Verification

- `dart analyze` 新文件 → No issues found
- `flutter test .../anti_ai_scent_real_glm_test.dart`（GLM_API_KEY 注入）→ `+1 All tests passed!`
- `flutter analyze` 全仓 → No issues found (2.1s)
- 既有 `anti_ai_scent_test.dart` 57 测试 → All passed（纯新增零回归）

## 闭合 / Closes

STATE release blocker「banned phrase lists 应以真实中文散文验证」——词库现对真实 GLM 产出
持续可验证（CI 无 key skip，本地注入 key 即跑）。反 AI 味灵魂防线从静态 fixture 升级到真实 LLM 验证。

## 剩余 / Remaining

- 检测器 fire 频率随 prompt/模型变（本次仅 1 reviewSignal + 2 highlights）——若需更强信号覆盖，
  可扩 prompt 多样本或加 human-prose 对照（防误报方向，需真人散文样本，API 无法生成）。
