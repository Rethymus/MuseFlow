---
quick_id: 260619-od2
slug: offline-message-source-retry-predicate
date: 2026-06-19
status: complete
---

# 离线消息单一真源 + retry 谓词防御性收紧（od1 独立审查 MINOR 修复）

## 触发：od1 (df3b093) 独立 code-reviewer 的 2 个 MINOR（HIGH confidence，非行为）

od1 交付了 `AIOfflineException` 类型化。独立 omc code-reviewer 判定 **APPROVE**（零 BLOCKER/MAJOR），
但标记 2 个 MINOR 质量项，本任务闭合它们：

1. **MINOR：`userMessage` 死代码 + 漂移风险**。3 个 UI error-mapper（synthesis/editor_ai/
   continuation）硬编码 offline 字符串字面量 `'当前处于离线状态，请检查网络连接'`，而非读
   `e.userMessage` → `AIOfflineException.userMessage` getter 零生产消费方＝死代码。这正是
   od1 想消除的漂移缺陷的同类——离线消息现在存在于 getter + 3 份重复字面量两处，会漂移。

2. **MINOR：`_isRetryable` 可读性/防御性**。谓词 `error is AINetworkException` 传递性匹配
   offline（返回 true），依赖「gate 在 retryStream 外」的外部不变量使 offline 永不到达。
   若未来重构把 gate 移入 retryStream，会静默回退 offline 成 3× 重试，谓词不会报警。

## 方案（纯 refactor，零行为变更）

| # | 文件 | 改动 |
|---|------|------|
| MINOR-1 | `synthesis_notifier.dart` / `editor_ai_notifier.dart` / `continuation_suggestion_notifier.dart` | offline 分支字面量 → `e.userMessage`（字面量==getter 零行为变更；其余 Auth/RateLimit/Network/Stream 分支留字面量——其 getter 持短形式供 provider_service 连接测试用，mismatch 故意）|
| MINOR-2 | `openai_adapter.dart` `_isRetryable` | `error is AINetworkException` → `error is AINetworkException && error is! AIOfflineException` + 注释说明 no-retry-offline 契约在代码层显式 |

claude_adapter 无 `_isRetryable`/retryStream（不做 adapter 层重试）→ MINOR-2 仅 openai 单边，非对称是真实的。

## 验证（证据）

- analyze 0（ai + editor 全域）
- ai_exception_test 3 + openai/claude adapter + synthesis_retry_test（含 offline no-retry 断言 `state.error contains '离线'`——e.userMessage 含'离线'流过确认）+ editor_ai + continuation 全量 104 GREEN 零回归
- 行为保持：offline 字面量==getter 零变更；_isRetryable 收紧后 AIRateLimit/AIStream/AINetwork 仍 true→仍重试

## 教训

- 独立审查（不自批准）能浮出作者盲区——od1 自己写时没注意到 userMessage getter 成死代码
- 防御性收紧 > 注释：让不变量在代码层显式正确，而非依赖外部 wiring 文档
- 同类问题排查延伸：审查发现一处死代码就 grep 全部 mapper，统一修
