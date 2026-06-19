---
quick_id: 260619-od1
slug: offline-distinct-exception-no-retry
date: 2026-06-19
status: in-progress
---

# 离线异常类型化：distinct 消息 + 不重试（闭合 260619-cf1 延后项）

## 触发：上一轮自己记录的延后 + 新发现的离线重试 bug

260619-cf1 交付了离线 fast-fail（adapter 层 `_guardOnline` 抛 `AINetworkException('当前处于离线状态...')`），
但其 SUMMARY 明确记录延后项："AINetworkException.userMessage 硬编码忽略 message 参数，故
distinct「离线」消息需新增异常类型（v1 不做，**记为后续**）"。

侦察发现两个相关问题：

1. **distinct 消息被吞**：UI catch 点用 `is AINetworkException` 类型分派 + 硬编码字符串
   （`userMessage` getter 全仓零消费方＝死代码）。离线异常被当普通网络错误→显示"网络连接失败，
   请检查网络"，用户分不清"离线"vs"端点挂了"，**削弱了离线检测的产品价值**。

2. **离线被重试 3 次**（synthesis_notifier:295）：retry 门 `if (e is AIAuthException || retryAttempt >= maxRetries)`
   ——离线异常（AINetworkException 子类）非 AIAuthException→**被当 transient 重试 3 次**（2+4+8=14s
   backoff 浪费），违背 adapter 层确立的"离线是已知坏态不该重试"原则（gate 放 retryStream 外的同源理据）。
   editor_ai_notifier 无 retry 循环（仅终端 catch），不受影响。

## 方案（单一关注点：离线的类型化 + 正确处理，6 文件全是该概念表达）

新增 sealed-邻接 `AIOfflineException extends AINetworkException`（同库 ai_exception.dart）：
- **多态保证向后兼容**：现有 `is/on AINetworkException` 兜底仍捕获（fetchModels 连接测试、provider_step_page 等无需改）
- **distinct 消息**：`userMessage` = '当前处于离线状态，请检查网络连接'
- **零 exhaustive-switch 风险**：全仓仅 statusCode int switch，无 type switch（grep 验证）

改动 6 处：
| 文件 | 改动 |
|------|------|
| `lib/features/ai/domain/ai_exception.dart` | +`AIOfflineException`（extends AINetworkException，distinct userMessage）|
| `lib/features/ai/infrastructure/openai_adapter.dart:217` | throw `AIOfflineException()` 替 `AINetworkException('...')` |
| `lib/features/ai/infrastructure/claude_adapter.dart:328` | 对称 throw `AIOfflineException()` |
| `lib/features/ai/presentation/synthesis_notifier.dart:295` | retry 门加 `e is AIOfflineException`（离线不重试）|
| `lib/features/ai/presentation/synthesis_notifier.dart:351` | `_handleStreamError` 加 `is AIOfflineException` 优先分支→distinct 消息 |
| `lib/features/editor/application/editor_ai_notifier.dart:525` | `_handleStreamError` 加 `is AIOfflineException` 优先分支 |
| `lib/features/editor/application/continuation_suggestion_notifier.dart:243` | `_mapError` 加 `is AIOfflineException` 优先分支 |

刻意不动：`provider_management_notifier:249` `on AINetworkException`（连接测试本身就是连通性探测，离线消息语义次要；多态仍兜底捕获）——独立 UX 关注点，记后续。

## TDD（Red→Green）

Red（先写，AIOfflineException 不存在→编译失败）：
- `test/features/ai/domain/ai_exception_test.dart`（NEW）：AIOfflineException isA<AINetworkException>（多态）+ isA<AIException> + userMessage 精确串 + 默认 message
- `synthesis_retry_test.dart`：+`should not retry on AIOfflineException`（镜像 AIAuthException no-retry 测试；断言 error contains '离线' + retryCount==0 + callCount==1，确定性快无 backoff）
- `openai_adapter_test.dart:42` + `claude_adapter_test.dart:43`：predicate 强化为 `e is AIOfflineException`

Green：加类型 + 改 throw + 3 catch 点分支 + retry 门。

## 验证
- analyze 0（含 sealed 邻接子类编译）
- ai_exception_test 3 GREEN
- synthesis_retry_test 新 offline no-retry GREEN + 既有 retry 测试零回归
- openai/claude adapter offline 测试 GREEN（断言强化）
- editor_ai_notifier + continuation_suggestion 既有测试零回归（如 infra 允许加 offline 消息测试则加）
- 回归 test/features/ai + test/core + test/features/editor 零回归
- 独立 omc code-reviewer APPROVE（不自我批准）

## 教训
- 同族延后项是最好的下一增量来源（上一轮 SUMMARY 的"记为后续"是精确 TODO）
- sealed 类加子类前先 grep exhaustive type-switch（此处零风险）
- 多态是向后兼容的杠杆：子类化 + 现有 `is 父类` 兜底＝零波及无关 catch 点
