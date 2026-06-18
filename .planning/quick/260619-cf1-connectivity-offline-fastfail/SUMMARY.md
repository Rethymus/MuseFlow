---
quick_id: 260619-cf1
slug: connectivity-offline-fastfail
date: 2026-06-19
status: complete
commits: [cf76664]
---

# 离线感知 fast-fail：接入 connectivity_plus（Phase 30.3）

## 闭环

`connectivity_plus ^7.0.0` 此前声明于 pubspec 但 lib/ 零使用（dead weight）→ 本次接入，
闭合 roadmap Phase 30.3「网络状态感知→离线禁用 AI」。AI 调用在设备确证离线时**瞬时
fast-fail**（AINetworkException），而非等满网络 timeout——对目标用户（中国作者，GLM/OpenAI
端点网络波动）省掉 30s 卡顿 + 零徒劳 quota 烧。

## 候选穷尽与自我纠正（为何选此项）

用户要求"根据建议推进优化"。穷尽验证主流候选后否决多个：
- **DOCX 导出**：grep 发现已完整实现+接线+测试（`buildDocxBytes` + export_dialog DOCX 段 +
  `story_structure_page.dart:436` dartBinaryFileWriter + export_service_test）→ roadmap Phase 29.4 过时
- **synthesis "TODO"**（roadmap 30.1）：line 239-240 已实现
- **lib/ 全仓零 TODO/FIXME/HACK**
- **重试去重**（生产 client RetryPolicy 叠加 wma）：读 openai_dart 6.1.0 源码一锤定音——
  `createStream`→`streamSseEvents`→`sendStream`（纯 HTTP send，streaming_resource.dart:268
  注释"intentionally NOT"走 retry），**流式完全绕过 SDK retry，无双重重试 bug**；wma 是唯一
  重试层（其存在的正确理由）

`connectivity_plus` 是穷尽后**唯一确认的干净缺口**（声明未用）。

## 架构

适配器构造注入 `onlineCheck` 闸门（**不改 AIAdapter 接口**→零 test fake 影响），`providers_ai`
的 openai/claude adapter provider 单点注入 → 覆盖全部 9 个 `createStream` 调用点。

三个 load-bearing 设计约束（审查 APPROVE 全部确认）：
1. **pre-flight 放 retryStream/流式链外**——离线是已知坏态，不该被退避重试 3 次（烧 quota 违背 fast-fail）
2. **`_getOrCreateClient` 保持 eager**——守 quick-260618-1g4 的 isActive 不变量（1g4 正是延迟 client 创建致 isActive 失效的 bug）
3. **best-effort 永不误判**——`isProbablyOffline` 仅 `ConnectivityResult.none` 独占为真；空/抛错/任何正传输→online

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze`（7 文件含 part-file 接线编译） | 0 issues |
| connectivity_service_test | ✅ 6 GREEN（none→offline / wifi·mobile·ethernet·vpn·bluetooth·satellite·other→online / 空列表→online / `[none,vpn]` 混合→online / 探针抛错→online）|
| openai_adapter_test +2 | ✅ offline fast-fail emitsError AINetworkException('离线') <5s（证明瞬时非 timeout）/ null-gate 向后兼容 isActive true |
| claude_adapter_test +2 | ✅ 对称 |
| 回归 test/features/ai + test/core | ✅ 327 GREEN（~1 预存 env-gated skip）|
| 回归 test/features/editor | ✅ 317 GREEN |

## 独立审查（code-reviewer，不自我批准）

**APPROVE**，零 BLOCKER/MAJOR。六个焦点维度全部 PASS：gate 在 retryStream 外 / `_guardOnline`
throws before `yield* inner` / isActive 不变量（eager client 在 onlineCheck 分支前）/ flutter_test
无通道→catch MissingPluginException→false no-op / never-false-block（`every(==none)` 非 `contains`）/
Riverpod fresh-read 无泄漏。

## 已知非对称（审查 MINOR，刻意保留）

`provider_management_notifier.dart:280` 的 `fetchModels()` 用 bare `OpenAIAdapter()`（无 gate）
调 `fetchModelList`——模型选择器离线时等 5s timeout（fetchModelList 自带 5s timeout + D-08 静默
fallback 返 `[]`，UX 安全）。**pre-existing，非本次引入**。流式高频作者路径已 gate（核心价值），
模型选择器低频+已有兜底；wiring 它是独立关注点（违反"一次一关注点"），记为后续可选增强。
`fetchModelList` 走独立 HTTP 路径不经 createStream，故 gate 本就不作用于它（结构性非对称，非疏漏）。

## UX 说明

离线 fast-fail 抛 AINetworkException → 复用现有"网络连接失败"UX（synthesis_notifier:352 /
editor_ai_notifier catch AINetworkException→固定中文消息）。核心收益是**速度 + quota**，消息一致。
`AINetworkException.userMessage` 硬编码忽略 message 参数，故 distinct「离线」消息需新增异常类型
（v1 不做，记为后续）。

## 教训

- roadmap/gap 文档落后于代码——逐项 grep 验证真实状态而非信 wishlist（DOCX/synthesis/重试三项均被否决）
- 跨切面基础设施关注（离线）放适配器构造注入是单一咽喉解；改 AIAdapter 接口会波及所有 test fake，避之
