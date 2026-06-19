---
quick_id: 260619-ea3
slug: editorial-review-real-glm
date: 2026-06-19
status: complete
---

# CritiCS 编辑评审真实 GLM 验证（闭合第3条 LLM 结构化 JSON 输出解析 gap）

## 触发：EditorialReviewService 严格 JSON + parseFromLLM 容错，零真实覆盖

ea2 闭合续写路径后穷尽侦察第3条同类 gap：`EditorialReviewService`（CritiCS 4维 LLM 评审）要求严格
JSON（情节/人物/文笔/节奏 × score/strengths/weaknesses/suggestions）→ `EditorialReview.parseFromLLM`
容错解析。与 ea2 同脆弱类（LLM 结构化输出最易翻车）。canned 测试喂完美 JSON via fake adapter 证明不了
解析器对真实输出鲁棒性。EMNLP 2024 CritiCS 首个 LLM 驱动评审功能。

## 方案（构造注入，最简洁）

`EditorialReviewService` 构造注入（openAIAdapter/apiKey/baseUrl/model 直接传）→ 真实测试无需
ProviderContainer/journey_container（区别于 ea2 走 notifier ref）。`EditorialReviewService(openAIAdapter: OpenAIAdapter(), apiKey, baseUrl, model)` → reviewChapter → 断言 parseFromLLM 扛过真实输出。service 永不抛（degraded 兜底），断言 isDegraded==false。

## 验证（证据）

- analyze 0
- 真实 GLM GREEN：4维合规（情节85/人物90/文笔80/节奏75，分数合理），parseFromLLM 扛过真实输出 isDegraded=false
- 无 key 优雅 skip

## 教训

- 第三条 LLM 结构化输出路径（ea2 续写 + ea3 评审）——LLM 结构化输出是全产品最脆弱面，逐条真实验证容错最有价值
- 构造注入 service 真实测试最简洁（无需 ProviderContainer/override，区别于 ref 注入 notifier）
- degraded 兜底是优雅设计——service 永不抛，断言 isDegraded==false 即验证 happy path
