---
quick_id: 260619-ea1
slug: editor-ai-real-glm-polish
date: 2026-06-19
status: complete
commits: [7152bc9]
---

# editor AI 润色真实 GLM 验证（闭合 editor AI 路径零真实覆盖 gap）

## 闭环

gap-analysis-updated「真实剩余工作」#1 = Phase 25 真实 API E2E（标 ❌「需外部 key/网络，本环境不可执行」）。
穷尽侦察发现：synthesis 有 `fragment_synthesis_test`、manuscript 有章节摘要真实测试、反AI味有
`anti_ai_scent_real_glm_test`——**唯独 editor_ai 路径零真实 API 覆盖**（仅 canned `_FakeOpenAIAdapter`）。
editor_ai 是产品主交互面（润色/改写/续写），且反AI味 postProcessor 跑在 editor 输出上。本次用 GLM key
解锁，闭合此 gap。

## 方案（复用 harness，聚焦未覆盖风险点）

editor_ai_notifier 全量接线重（17 个 provider 依赖：editor state + undo + anchors）。但 editor_ai 的
真实 GLM 风险点已被分别覆盖（adapter 流式←fragment_synthesis / antiAIScent←anti_ai_scent_real_glm），
**唯一未覆盖的 editor 特有风险 = EditorPromptPipeline 的 12-middleware prompt 组装**。故镜像
fragment_synthesis：`EditorPromptPipeline().build(context)` → 真实 GLM `createStream` → 断言 prompt 有效。
复用既有 `createJourneyContainer`（提供 openaiAdapterProvider + GLM provider + key）而非重建。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze` | 0 issues |
| 真实 GLM-4-flash | ✅ GREEN——输入 44 字平铺 AI 味 → 输出 92 字文学化（"林风独立于青云峰巅，目光所及，尽是飘渺的云层。他心有所思，关于修炼的种种。一阵轻风拂过他的脸颊..."），句式多变，林风/青云峰/修炼/风/天空全保留 |
| 5 断言全过 | ✅ pipeline ≥2 messages / 输出非空>20字 / ≠输入（润色生效非回显）/ 含'林风'（语义保持）/ usage 捕获 / AntiAIScent.process 不崩 reviewSignals 合法 |
| 无 key | ✅ 优雅 skip（"GLM_API_KEY not set"，CI 安全，与既有 real_glm 同模式） |

## 教训

- **核心交互面的真实 API 覆盖是最后该留的盲区**——canned fake 无法暴露真实 LLM 输出质量（memory `deviation-compliance-false-positive` 印证真实 vs canned 鸿沟）
- **复用既有 harness + 聚焦未覆盖风险点**（editor 特有的 prompt 组装）而非硬接全量 notifier——ROI 最高
- **断言 prompt 有效性比断言"调用了"更有价值**：output≠input + 语义保持 是 prompt 真生效的信号
