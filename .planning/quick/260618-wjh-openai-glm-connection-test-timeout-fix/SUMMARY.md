---
quick_id: 260618-wjh
slug: openai-glm-connection-test-timeout-fix
date: 2026-06-18
status: complete
commits: []
---

# OpenAI/GLM 连接测试 timeout 修复

## 触发：真实 API key 验证才发现的 UX gap

用用户提供的真实 GLM key（70fff...）跑 Phase 25 真实 API E2E（解锁 gap 分析里
标注「❌ 需外部 key/网络，本环境不可执行」的 P0 阻塞项）。GLM 全流程可用后，
代码审计发现 `_testOpenAIConnection` 用 `OpenAIClient.withApiKey`（不暴露 timeout），
落到 `OpenAIConfig` 默认 `timeout: Duration(minutes: 10)`——用户点"测试连接"遇
死/慢 baseUrl 会等 **10 分钟**，而 Claude 路径 30s 返回。GLM preset 走 openai 类型，
直接受影响。

## 修复

`lib/features/ai/application/provider_service.dart`：
- `testConnection` / `_testOpenAIConnection` / `_testClaudeConnection` 加可注入
  `timeout` 参数，默认 `Duration(seconds: 30)`（对齐 Claude 现有行为，默认值不变）。
- OpenAI 路径改用 `OpenAIClient(config: OpenAIConfig(authProvider, baseUrl, timeout, retryPolicy))`
  替代 `withApiKey` 工厂。
- **额外改进**：连接测试客户端设 `RetryPolicy(maxRetries: 0)`——"测试连接"按钮
  本就该单次快速探测，不该退避重试 4 次（这也让超时行为确定性可测）。
- Claude 路径用注入 timeout 替代硬编码 30s（默认值不变，行为等价）。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze`（2 改动文件） | 0 issues |
| 新回归测试 `provider_service_timeout_test.dart` | ✅ +1 GREEN（黑盒 ServerSocket + 1s 注入 timeout，1s 内抛 AINetworkException，证明非 10 分钟默认） |
| 全量 `provider_service_test.dart` | ✅ 14/14 全过（签名变更零回归——现有 testConnection 测试走默认 30s） |

测试隔离关键：新测试用 `setUpHiveForNetworkTest()`（非 `setUpHiveTest`）避开
flutter_test HTTP mock 对 localhost 真实连接的拦截——同 journey 真实 API 测试隔离模式。

## Phase 25 真实 API E2E 顺带验证（本次 GLM key 解锁）

- GLM streaming smoke ✅（537 chars）
- Fragment synthesis 真实 ✅（419/486 chars）
- Opening guide 三切入变体 ✅（场景/人物/悬念）
- 100-chapter 导出 ✅（MD/TXT/JSON 合法）
- 30-chapter knowledge injection + Skill guardian ✅（deviation 检测在真实 GLM 输出上正常触发）
- full_journey 100 章：真实 GLM 输出上偏差检测正常触发（世界观禁忌/境界体系/火系法术等 DEVIATION）

## 发现的测试基础设施问题（非产品 bug，记录待办）

`flutter test test/journey/` 三个重型真实 GLM 测试（30章+guardian / 100章+guardian /
31-100章+stage）**并发**跑会饱和 GLM API，致 serial_generation "30 chapters" 撞穿其
20 分钟 timeout 注解（line 142）超时 `[E]`。根因=并发真实 API 饱和，非产品回归
（journey 启动于本次修复之前，且用 adapter 不经 testConnection）。
**可操作洞察**：真实 API journey 验证应用 `flutter test test/journey/ --concurrency=1`
或分文件串行，避免 GLM 饱和超时。
