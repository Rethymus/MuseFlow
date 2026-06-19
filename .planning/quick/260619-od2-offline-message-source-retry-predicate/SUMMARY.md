---
quick_id: 260619-od2
slug: offline-message-source-retry-predicate
date: 2026-06-19
status: complete
commits: [445c13f]
---

# 离线消息单一真源 + retry 谓词防御性收紧（闭合 od1 审查 MINOR）

## 闭环

od1 (df3b093) 独立 omc code-reviewer 判定 **APPROVE**（零 BLOCKER/MAJOR），标记 2 个 MINOR（HIGH confidence，
非行为质量项）。本任务作为 od1 的质量收尾，闭合两者——纯 refactor，零行为变更。

## 改动（4 文件 +12/-5）

**MINOR-1：offline 消息单一真源**。3 个 UI error-mapper（synthesis/editor_ai/continuation）的 offline
分支从硬编码字面量 `'当前处于离线状态，请检查网络连接'` 改读 `e.userMessage`。闭合 od1 自身引入的
漂移缺陷——`AIOfflineException.userMessage` getter 此前零生产消费方＝死代码，离线消息同时存在于
getter + 3 份重复字面量两处。字面量==getter 值，**零行为变更**。其余 Auth/RateLimit/Network/Stream
分支保留字面量：其 getter 持更短形式供 `provider_service` 连接测试结果用（`provider_service_test:203`
断言 `AINetworkException.userMessage=='网络连接失败'`），mismatch 是故意的（不同 UI 上下文长度需求）。
synthesis_notifier offline 分支加注释说明此设计。

**MINOR-2：`_isRetryable` 防御性收紧**。openai_adapter 谓词 `error is AINetworkException`（传递性匹配
offline 返回 true）→ `error is AINetworkException && error is! AIOfflineException`。让 no-retry-offline
契约在**代码层显式正确**，而非依赖「gate 在 retryStream 外」的外部不变量（od1 已验证此不变量成立，
但未来重构移 gate 入 retryStream 会静默回退 offline 成 3× 重试，收紧后谓词直接拒掉）。claude_adapter
无 `_isRetryable`/retryStream（不做 adapter 层重试）→ 单边，非对称是真实的。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze`（ai + editor 全域） | 0 issues |
| ai_exception_test 3 + openai/claude adapter + synthesis_retry_test（含 offline no-retry `state.error contains '离线'`）+ editor_ai + continuation | ✅ 104 GREEN 零回归 |
| 行为保持确认 | offline 字面量==getter 零变更；_isRetryable 收紧后 AIRateLimit/AIStream/AINetwork 仍 true→仍重试 |

## 教训

- **独立审查浮出作者盲区**：od1 自己写时没注意到 `userMessage` getter 成死代码——这正是「不自批准」的价值
- **防御性收紧 > 注释**：让不变量在代码层显式正确，而非依赖外部 wiring 文档（万一重构移 gate，谓词直接拒）
- **同类问题排查延伸**：审查发现一处死代码即 grep 全部 mapper 统一处理
