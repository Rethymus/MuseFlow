---
quick_id: 260619-ea1
slug: editor-ai-real-glm-polish
date: 2026-06-19
status: complete
---

# editor AI 润色真实 GLM 验证（闭合 editor AI 路径零真实覆盖 gap）

## 触发：editor_ai 是核心 AI 消费方但零真实 API 覆盖

gap-analysis-updated「真实剩余工作」#1 = Phase 25 真实 API E2E（标 ❌「需外部 key/网络，本环境不可执行」）。
穷尽侦察真实覆盖现状后发现：synthesis 路径有 `fragment_synthesis_test`（真实 GLM）、manuscript 路径有
章节摘要真实测试、反AI味有 `anti_ai_scent_real_glm_test`——**唯独 editor_ai 路径零真实 API 覆盖**，
仅 canned `_FakeOpenAIAdapter`（editor_ai_notifier_test 17 个 provider 依赖，全量接线重）。

editor_ai 是产品的**主交互面**（润色/改写/续写），且反AI味 postProcessor 跑在 editor 输出上——这是
真实 GLM-vs-canned 行为最可能分歧的核心路径（memory `deviation-compliance-false-positive` 印证真实
LLM 输出与 canned 鸿沟）。

## 方案：复用既有 harness，验证 editor 特有风险点

不接全量 17-dep notifier（editor state + undo + anchors 重）——editor_ai 的真实 GLM 风险点已被分别
覆盖（adapter 流式←fragment_synthesis / antiAIScent←anti_ai_scent_real_glm），**唯一未覆盖的 editor
特有风险 = EditorPromptPipeline 的 12-middleware prompt 组装**。故镜像 fragment_synthesis 模式：
`EditorPromptPipeline().build(context)` → 真实 GLM `createStream` → 断言 prompt 有效。

`createJourneyContainer`（既有 harness）提供 openaiAdapterProvider + GLM provider + key，复用而非重建。

## TDD/验证（Red→Green，env-gated）

`test/features/editor/application/editor_ai_real_glm_test.dart`（NEW），5 断言：
1. `pipeline.build` 输出 ≥2 messages（system+user，middleware 未丢）
2. 输出非空 substantive（>20 字）
3. 输出 ≠ 输入（润色生效非回显——验证 operation 指令被遵守）
4. 含 protagonist 名（语义保持——润色核心契约）
5. usage 捕获（editor 每操作审计，onUsage 必触发真实完成）
6. `AntiAIScentProcessor.process(output)` 不崩（验证 editor postProcess 路径处理真实输出，reviewSignals 合法 List）

skip: `GLM_API_KEY==null`（CI 安全，与既有 real_glm 测试同模式）。

## 验证（证据）

- analyze 0
- **真实 GLM GREEN**：输入 44 字平铺 AI 味 → 输出 92 字文学化（"林风独立于青云峰巅，目光所及，尽是飘渺的云层..."，句式多变，林风/青云峰/修炼/风/天空全保留）——prompt 有效 + 语义保持
- 无 key 优雅 skip（"All tests skipped"，CI 安全）

## 教训

- 核心交互面的真实 API 覆盖是最后该留的盲区——canned fake 无法暴露真实 LLM 输出质量
- 复用既有 harness（journey_container）+ 聚焦未覆盖风险点（editor 特有的 prompt 组装），而非硬接全量 notifier——ROI 最高
- 真实 GLM 验证 prompt 有效性比断言"调用了"更有价值：output≠input + 语义保持 是 prompt 真有效的信号
