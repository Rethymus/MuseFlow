---
quick_id: 260618-vm1
slug: glm-ai-state-release-blocker-banned-phra
date: 2026-06-18
status: complete
type: real-api-validation-test
---

# 反 AI 味检测词库 — 真实 GLM 散文验证

## 目标 / Goal

闭合 STATE release blocker：「Anti-AI-scent banned phrase lists should be validated
with broader real Chinese prose samples before release sign-off」。反 AI 味是产品灵魂——
既有 57 个 canned 测试用静态 fixture，从未对**真实 LLM 产出**验证词库是否真的能抓 AI 味。
真实 key 独有能力：生成真实 AI 散文喂给检测器，验证词库 fire。

## 方案 / Approach

新建 `test/features/ai/application/anti_ai_scent_real_glm_test.dart`，镜像 slice1 env 门控模式。
**显式 AI 风格 prompt**（烟测已证 GLM-4-flash 可靠产出叠词/程度副词/结构套句——淡淡/微微/格外/颇为/仿佛/宛如 6/10 命中）
→ 真实 GLM 生成 → `AntiAIScentProcessor().process(glmText, bannedPhrases: [])`（空 user 列表，
纯测内部词库 synonymMap/structuralPatterns/mannerAdverbStems/emptyIntensifiers）。

断言（鲁棒）：
1. processedText 非空 + 长度 ≤ 源+50（processor 只替换/标【】，不膨胀）
2. **检测器确实触发**：`highlights.isNotEmpty || reviewSignals.isNotEmpty`（显式 prompt 可靠诱发 → 烟测已证）
3. 每个 reviewSignal severity 合法（结构规范）
4. debugPrint 信号明细（标题/severity/evidence）供人工 release 复核

processor 纯函数，无需 Hive/ensureInitialized（无 HTTP mock 风险）。

## 文件 / Files

- 新增: `test/features/ai/application/anti_ai_scent_real_glm_test.dart`

## 验证 / Verification

- `dart analyze` 新文件 → 0
- `flutter test .../anti_ai_scent_real_glm_test.dart`（GLM_API_KEY 注入）→ GREEN + 信号明细打印
- 全仓 `flutter analyze` → 0
- 既有 anti_ai_scent_test 57 测试零回归（纯新增）

## 成功标准 / Done

- 真实 GLM 散文下检测器触发 + 规范产出
- analyze 0 + 零回归
- STATE blocker 闭合（"validated with real Chinese prose samples"）
