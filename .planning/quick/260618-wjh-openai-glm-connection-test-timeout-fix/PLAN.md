---
quick_id: 260618-wjh
slug: openai-glm-connection-test-timeout-fix
date: 2026-06-18
status: in-progress
---

# OpenAI/GLM 连接测试 timeout 修复

## 背景（真实 API key 验证后发现）

用真实 GLM key（70fff...）跑 Phase 25 真实 API E2E 时，代码审计发现：
`provider_service.dart:_testOpenAIConnection` 用 `OpenAIClient.withApiKey(apiKey, baseUrl)`
构造客户端，而该工厂**不暴露 timeout 参数**，落到 `OpenAIConfig` 默认值
`timeout: Duration(minutes: 10)`（openai_dart config.dart:88）。

对比 `_testClaudeConnection` 显式设 `timeout: const Duration(seconds: 30)`
（provider_service.dart:150）。GLM preset 走 `AiProviderType.openai`，所以
用户在 Provider 配置页点"测试连接"，若 baseUrl 死/慢，OpenAI 路径会挂 **10 分钟**，
Claude 路径 30s 返回。这是真实 API 验证才暴露的 UX 一致性 gap。

## 修复

1. 给 `testConnection` / `_testOpenAIConnection` / `_testClaudeConnection` 加可注入
   `timeout` 参数，默认 `const Duration(seconds: 30)`（对齐 Claude 现有行为）。
2. OpenAI 路径改用 `OpenAIClient(config: OpenAIConfig(authProvider, baseUrl, timeout: timeout))`
   替代 `withApiKey` 工厂。
3. Claude 路径用注入的 `timeout` 替代硬编码 30s（默认值不变，行为等价）。

## 回归测试（TDD）

黑盒 `ServerSocket`（accept 连接但永不响应）+ 短 timeout（1s）：
- 调 `testConnection(baseUrl: http://127.0.0.1:PORT/v1, type: openai, timeout: 1s)`
- 断言抛 `AINetworkException`
- 断言耗时 < 10s（证明 1s timeout 生效，非 10 分钟默认）

## 验收

- analyze 0
- 新测试 GREEN（原 RED：timeout 参数不存在 → 编译失败）
- provider_service_test 全量零回归
- 全仓零回归

## 文件

- `lib/features/ai/application/provider_service.dart`（修复）
- `test/features/ai/application/provider_service_test.dart`（回归测试）
