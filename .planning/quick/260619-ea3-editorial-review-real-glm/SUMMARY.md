---
quick_id: 260619-ea3
slug: editorial-review-real-glm
date: 2026-06-19
status: complete
commits: [9faf867]
---

# CritiCS 编辑评审真实 GLM 验证（闭合第3条 LLM 结构化 JSON 输出解析 gap）

## 闭环

ea2 闭合续写路径后，穷尽侦察发现第3条同类 gap：`EditorialReviewService`（CritiCS 4维 LLM 评审，
情节/人物/文笔/节奏）要求**严格 JSON** 输出（每维 score/strengths/weaknesses/suggestions），经
`EditorialReview.parseFromLLM` 容错解析（strip ```json fence + 隔离首个 {...} + 优雅 degraded）。
与 ea2 同脆弱类——**LLM 结构化输出最易翻车**（markdown fence/前言/尾 prose/畸形括号），canned
`editorial_review_service_test` 喂完美 JSON via fake adapter 证明不了 `parseFromLLM` 对真实输出鲁棒性。
这是 EMNLP 2024 CritiCS 首个 LLM 驱动评审功能。用 GLM key 闭合。

## 方案（构造注入，最简洁——无需 ProviderContainer/journey_container）

`EditorialReviewService` 是构造注入（openAIAdapter/apiKey/baseUrl/model 直接传），故真实 GLM 测试
最简洁：`EditorialReviewService(openAIAdapter: OpenAIAdapter(), apiKey: GLM, baseUrl, model)` →
`reviewChapter(sampleChapter)` → 断言 `parseFromLLM` 扛过真实 JSON 输出。无需 ProviderContainer/journey
harness（区别于 ea2 走 notifier）。service 永不抛（degraded 兜底），故断言 `isDegraded==false`。

样本=修仙段落 ~330字（含情节/人物/文笔/节奏素材供4维评审）。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze` | 0 issues |
| 真实 GLM-4-flash | ✅ GREEN——4维合规评审：情节85/人物90/文笔80/节奏75（分数合理：人物最高节奏最低）；parseFromLLM 扛过真实输出 isDegraded=false |
| 断言 | ✅ isDegraded==false（解析器存活）/ dimensions==4 / 每维 score∈[0,100] + strengths/weaknesses 非空 / overallScore∈[0,100] |
| 无 key | ✅ 优雅 skip（CI 安全） |

## 教训

- **第三条 LLM 结构化输出路径**（ea2 续写 JSON + ea3 评审 JSON）——LLM 结构化输出是全产品最脆弱面，逐条真实 API 验证 parseFromLLM 容错最有价值
- **构造注入 service 的真实测试最简洁**——无需 ProviderContainer/override，直接 new + 调用（区别于 ref 注入的 notifier）
- **degraded 兜底是优雅设计**——service 永不抛，测试断言 isDegraded==false 即验证 happy path，失败时 degradedReason 自带诊断
