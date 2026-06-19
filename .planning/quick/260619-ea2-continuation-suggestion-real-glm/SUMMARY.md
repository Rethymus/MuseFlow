---
quick_id: 260619-ea2
slug: continuation-suggestion-real-glm
date: 2026-06-19
status: complete
commits: [3f22b47]
---

# 续写建议真实 GLM 验证（闭合 LFIN-03 结构化 JSON 输出解析 gap）

## 闭环

ea1 闭合 editor 润色路径后，穷尽侦察发现第二个独立 gap：`ContinuationSuggestionNotifier` 用**本地
`_buildMessages`**（非 EditorPromptPipeline）要求 LLM 输出**严格 JSON**（恰好 3 个续写方向
`[{direction,summary,keyPoints}]`），经 `_parseSuggestions` 解析。**结构化 JSON 输出是 LLM 最脆弱面**——
真实模型常包裹 markdown fence / 加前言 / 变形 JSON，canned 测试喂完美字符串证明不了解析器对真实输出的鲁棒性。
这是 LFIN-03 核心创意功能（引导式续写）。用 GLM key 闭合。

## 方案（驱动真实 notifier 端到端）

`activeAdapterProvider` 对 openai 类型（GLM）派生自 `openaiAdapterProvider`→journey_container 覆盖即解析。
故测全路径：read continuationSuggestionNotifierProvider → generateSuggestions（fire-and-forget）→
轮询 state isLoading→false → 断言解析器扛过真实输出。样本=修仙章节结尾带清晰 hook（古玉神秘/古老殿堂呼唤）。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze` | 0 issues |
| 真实 GLM-4-flash | ✅ GREEN——恰好 3 个格式良好各异且切题方向：神秘揭晓（揭开古玉神秘来历）/ 修炼成长（林风修炼古玉功法）/ 江湖纷争（卷入江湖挑战）；解析器扛过真实输出 error==null |
| 断言 | ✅ error==null（解析器存活）/ suggestions.length==3 / 每个 direction+summary 非空 |
| 无 key | ✅ 优雅 skip（CI 安全） |

## 教训

- **结构化 JSON 输出是 LLM 最脆弱面**——真实 API 验证解析器容错（fence strip / 尾 prose 容忍）远比 canned 完美字符串有价值
- **fire-and-forget notifier 用轮询 state**（isLoading→false + deadline）是测异步 Riverpod notifier 的简洁模式
- **同族延伸**：ea1（润色 prose 自由文本）+ ea2（续写 JSON 结构化）覆盖 editor AI 两大独立 prompt 模式
