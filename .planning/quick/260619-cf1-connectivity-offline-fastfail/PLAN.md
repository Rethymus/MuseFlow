---
quick_id: 260619-cf1
slug: connectivity-offline-fastfail
date: 2026-06-19
status: complete
---

# 离线感知 fast-fail：接入 connectivity_plus（Phase 30.3）

## 触发：穷尽候选验证后的唯一干净缺口

用户要求"根据建议继续推进优化改进"。穷尽验证主流候选后自我纠正：
- DOCX 导出：**已完整实现+接线+测试**（roadmap Phase 29.4 过时）
- synthesis "TODO"（roadmap 30.1）：**已解决**（line 239-240 已实现）
- lib/ 全仓**零 TODO/FIXME/HACK**
- 重试去重（生产 client RetryPolicy）：**非 bug**——openai_dart 流式 `createStream`
  → `streamSseEvents` → `sendStream`（纯 HTTP send，line 268 注释"intentionally NOT"走
  retry），wma 是唯一重试层

唯一确认的**干净缺口**：`connectivity_plus ^7.0.0` 声明于 pubspec 但 lib/ 零使用
（dead weight）。对应 roadmap Phase 30.3「网络状态感知→离线禁用 AI」。对目标用户
（中国作者，GLM/OpenAI 端点网络波动）真有价值——离线时省掉 30s timeout + 不烧 quota。

## 方案

**架构**：适配器构造注入 `onlineCheck` 闸门（**不改 AIAdapter 接口**→零 test fake 影响），
providers_ai 的 `openaiAdapterProvider`/`claudeAdapterProvider` 单点注入 → 一处覆盖全部 9 个
`createStream` 调用点。

**核心设计约束**：
1. **pre-flight 放 retryStream 外**（openai）/ 流式链外（claude）——离线是已知坏态，
   不该被 wma 退避重试 3 次（违背 fast-fail、烧 quota）
2. **`_getOrCreateClient` 保持 eager**（守 quick-260618-1g4 的 isActive 不变量——1g4 正是
   把 client 创建延迟到订阅导致 isActive 失效的 bug）
3. **best-effort，永不误判阻断**：`isProbablyOffline` 仅 `ConnectivityResult.none` 独占为真；
   任何正传输 / 空结果 / 探针抛错 → online（flutter_test 无平台通道→MissingPluginException
   被 catch→false→gate 变 no-op，测试零破坏）

## 改动（6 文件）

| 文件 | 改动 |
|------|------|
| `lib/core/infrastructure/connectivity_service.dart` | 新建：ConnectivityService + ConnectivityProbe typedef，isProbablyOffline |
| `lib/core/presentation/providers_core.dart` | 加 connectivityServiceProvider |
| `lib/core/presentation/providers.dart` | 加 connectivity_service import（part 父库）|
| `lib/features/ai/infrastructure/openai_adapter.dart` | onlineCheck 字段+构造+createStream `_guardOnline(inner)` 包装 |
| `lib/features/ai/infrastructure/claude_adapter.dart` | 对称 onlineCheck + `_guardOnline` |
| `lib/core/presentation/providers_ai.dart` | 两 adapter provider 注入 onlineCheck |

注：`provider_management_notifier:280` 的 raw `OpenAIAdapter()`（连接测试探针）保持无 gate
——它本身就是连通性测试，加 gate 循环。

## 验证

- analyze 0（7 文件含 part-file 接线编译）
- connectivity_service_test 6 GREEN（none→offline / 7 种正传输+empty+抛错→online）
- openai_adapter_test +2 GREEN（offline fast-fail emitsError AINetworkException '离线' <5s /
  null-gate 向后兼容 isActive）
- claude_adapter_test +2 GREEN（对称）
- 回归：test/features/ai + test/core 327 GREEN / test/features/editor 317 GREEN（零回归）

## UX 说明

离线 fast-fail 抛 AINetworkException → 复用现有"网络连接失败"UX（synthesis_notifier:352 /
editor_ai_notifier catch AINetworkException→固定中文消息）。核心收益是**速度（瞬时 vs 30s
timeout）+ quota（零徒劳调用）**，消息保持一致。AINetworkException.userMessage 硬编码忽略
message 参数，故 distinct「离线」消息需新增异常类型（v1 不做，记为后续）。
