---
quick_id: 260619-ea2
slug: continuation-suggestion-real-glm
date: 2026-06-19
status: complete
---

# 续写建议真实 GLM 验证（闭合 LFIN-03 结构化 JSON 输出解析 gap）

## 触发：continuation_suggestion 独立 prompt + 结构化 JSON 解析，零真实覆盖

ea1 闭合 editor 润色路径后，穷尽侦察发现第二个独立 gap：`ContinuationSuggestionNotifier`
用**本地 `_buildMessages`**（非 EditorPromptPipeline），要求 LLM 输出**严格 JSON**（恰好 3 个续写方向
`[{direction,summary,keyPoints}]`），经 `_parseSuggestions` 解析。

**结构化 JSON 输出是 LLM 最脆弱的请求**——真实模型常包裹 markdown fence / 加前言 / 输出变形 JSON。
canned 测试喂完美形状字符串，证明不了 `_parseSuggestions`（strip ``` fence + 容错尾 prose）对真实输出的鲁棒性。
这是 LFIN-03 核心创意功能（引导式续写：AI 提3方向→用户选1→生成），且 ea1 后 editor/ 仅 ea1 一项真实覆盖。

## 方案：驱动真实 notifier 端到端（prompt→真实GLM→解析→state）

`activeAdapterProvider` 对 openai 类型（GLM）派生自 `openaiAdapterProvider`→journey_container 覆盖即可解析。
故测**全路径**：read continuationSuggestionNotifierProvider → generateSuggestions（fire-and-forget）→ 轮询 state
isLoading→false → 断言解析器扛过真实输出。

样本：修仙章节结尾带清晰 hook（古玉神秘/古老殿堂呼唤）→ GLM 有素材提3方向。

## 验证（证据）

- analyze 0
- **真实 GLM GREEN**：恰好 3 个格式良好方向——「神秘揭晓—揭开古玉神秘来历」「修炼成长—林风修炼古玉功法」
  「江湖纷争—卷入江湖挑战」；解析器扛过真实输出（error==null，无 markdown/fence 破坏）；方向各异且切题
- 无 key 优雅 skip（CI 安全）

## 教训

- **结构化 JSON 输出是 LLM 最脆弱面**——真实 API 验证解析器容错比 canned 完美字符串有价值得多
- **fire-and-forget notifier 用轮询 state 等待**（isLoading→false）是测异步 Riverpod notifier 的简洁模式
- 同族延伸：ea1（润色 prose）+ ea2（续写 JSON）覆盖 editor AI 两大独立 prompt 模式
