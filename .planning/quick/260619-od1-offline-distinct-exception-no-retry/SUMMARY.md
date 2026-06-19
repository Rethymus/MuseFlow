---
quick_id: 260619-od1
slug: offline-distinct-exception-no-retry
date: 2026-06-19
status: complete
commits: [df3b093]
---

# 离线异常类型化：distinct 消息 + 不重试（闭合 260619-cf1 延后项）

## 闭环

260619-cf1 交付了离线 fast-fail，但其 SUMMARY 明确记录延后项：「AINetworkException.userMessage
硬编码忽略 message 参数，故 distinct『离线』消息需新增异常类型（v1 不做，记为后续）」。

本次新增 sealed-邻接子类 `AIOfflineException extends AINetworkException`，闭合两个产品级缺陷：

1. **distinct 消息被吞**：UI catch 点用 `is AINetworkException` 类型分派 + 硬编码字符串
   （`userMessage` getter 全仓零消费方＝死代码）。离线异常被当普通网络错误 → 显示「网络连接失败」，
   用户分不清「离线」vs「端点挂了」，**削弱了离线检测的产品价值**。

2. **离线被重试 3 次**（synthesis_notifier retry 门仅排除 AIAuthException）：离线异常（AINetworkException
   子类）非 AIAuthException → 被当 transient 重试 3 次（2+4+8=14s backoff 浪费），违背 adapter 层确立的
   「离线是已知坏态不该重试」原则（gate 放 retryStream 外的同源理据）。

## 架构（多态是向后兼容的杠杆）

`class AIOfflineException extends AINetworkException`，distinct `userMessage` = 「当前处于离线状态，请检查网络连接」。
**多态保证向后兼容**：现有 `is/on AINetworkException` 兜底仍捕获（fetchModels 连接测试、provider_step_page 等
零改动）；零 exhaustive-switch 风险（全仓仅 statusCode int switch，无 type switch，grep 验证）。

改动 7 处：
| 文件 | 改动 |
|------|------|
| `ai_exception.dart` | +`AIOfflineException`（extends AINetworkException，distinct userMessage + 默认 message）|
| `openai_adapter.dart:217` + doc | throw `AIOfflineException()` 替 `AINetworkException('...')`；修正 _guardOnline/onlineCheck 两处 doc 引用 AINetworkException→AIOfflineException |
| `claude_adapter.dart:328` + doc | 对称 throw `AIOfflineException()`；doc 已引用 AIOfflineException |
| `synthesis_notifier.dart:295` | retry 门加 `e is AIOfflineException`（离线不重试）|
| `synthesis_notifier.dart:351` | `_handleStreamError` 加 `is AIOfflineException` 优先分支→distinct 消息 |
| `editor_ai_notifier.dart:525` | `_handleStreamError` 加 `is AIOfflineException` 优先分支 |
| `continuation_suggestion_notifier.dart:243` | `_mapError` 加 `is AIOfflineException` 优先分支 |

**门闸不变量复核**（owner 意识——同类问题排查）：`createStream` 组合为 `_guardOnline(retryStream(...))`，
`_guardOnline` 在 `yield* inner` 前 throw → retryStream 的 catch 永远收不到 AIOfflineException。
故 `_isRetryable` 的 `error is AINetworkException`（对 offline 为 true）**无害**——offline 根本到不了
retryStream。设计稳健，`_isRetryable` 无需排除 offline。

刻意不动（独立 UX 关注点，记后续）：`provider_management_notifier:249` + `provider_step_page:96`
的 `on AINetworkException`（连接测试本身就是连通性探测，离线消息语义次要；多态仍兜底捕获）。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze`（ai + editor 全域 + openai_adapter 单文件） | 0 issues |
| `ai_exception_test.dart`（NEW 3） | ✅ AIOfflineException isA<AINetworkException>/AIException（多态）+ userMessage 精确串 + 默认 message |
| `openai_adapter_test` + `claude_adapter_test`（断言强化） | ✅ predicate `is AIOfflineException`（原 `is AINetworkException && contains('离线')`）|
| `synthesis_retry_test` +1 | ✅ offline no-retry：error contains '离线' + retryCount==0 + callCount==1（确定性快无 backoff）+ 既有 6 retry 测试零回归 |
| `editor_ai_notifier_test` + `continuation_suggestion_test` 回归 | ✅ 46 GREEN（两改动文件零回归）|
| **真实 GLM API**（fragment_synthesis_test，--concurrency=1） | ✅ 4/4 GREEN——在线路径未破坏：[SYNTHESIS] 473 chars + 知识注入命中 [林风,清虚真人,苏雪晴,赵天磊] |

## 教训

- 同族延后项是最好的下一增量来源（上一轮 SUMMARY 的「记为后续」是精确 TODO）
- sealed 类加子类前先 grep exhaustive type-switch（此处零风险）
- 多态是向后兼容的杠杆：子类化 + 现有 `is 父类` 兜底＝零波及无关 catch 点
- 真实 API 验证 + 结构复核双保险：改异常类型后既跑真实 GLM（在线不抛 offline→happy path）又复核门闸不变量（offline 到不了 retryStream）
