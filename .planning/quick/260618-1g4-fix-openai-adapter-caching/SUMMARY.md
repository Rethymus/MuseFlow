---
slug: fix-openai-adapter-caching
quick_id: 260618-1g4
status: complete
created: 2026-06-18
completed: 2026-06-18
type: quick
---

# Fix openai_adapter client caching 测试回归 — Summary

## Outcome ✅

修复 2 个 clean HEAD 上即红的 openai_adapter client caching 测试，闭合 260618-1g3 遗留的预存失败。全 AI 目录 311 -2 → 313 -0 零失败。

## Root Cause

quick-260617-wma 可靠性重构把公共 `createStream` 的 `_attemptStream` 包进 `retryStream(() => _attemptStream(...))` 闭包。`OpenAIClient` 创建（`_getOrCreateClient`）被延迟到**首次流订阅**（async* 生成器惰性执行）。测试 fire-and-forget 调 `createStream` 不订阅 → `_getOrCreateClient` 永不执行 → `_client` 恒 null → `isActive`（`_client != null && !_disposed`）= false → 2 个 caching 测试（reuse / dispose-old）红。

## Fix（根因，非测试打补丁）

`createStream` 在 `_validateBaseUrl` 后 **eager** 调 `_getOrCreateClient(apiKey, baseUrl)`，还原回归前行为。`retryStream` factory 经 `_attemptStream` 的 `_getOrCreateClient`（同参幂等）复用缓存 client，retry 语义完全不变。

```dart
_validateBaseUrl(baseUrl);
_getOrCreateClient(apiKey, baseUrl);   // NEW: eager create+cache
return retryStream(() => _attemptStream(...));  // factory reuses cached client
```

## Why 根因修复 > 改测试

测试编码的缓存不变式（`isActive` 反映 createStream 后存在活跃 client）是合法的资源管理可见性需求。wma 重构（正确的可靠性改进）意外把它从 eager 变 lazy 是回归。还原 eager 是 2 行根因修复，无需重构测试或加 DI。

## Verification

- `openai_adapter_test + ai_resilience_test` → **30/30 passed**
- 全 AI 目录 `test/features/ai/` → **313/313 All tests passed**（311 -2 → 313 -0）
- `flutter analyze openai_adapter.dart` → No issues
- 真实 GLM journey（30 章连写大量 createStream 复用）此前已全过 → 实战复用本就正常，仅测试断言受回归影响

## kimi-webbridge 视觉验证（未成）

daemon 在线（10086）但 `list_tabs` 返回 **"no extension connected"**——证实记忆 `kimi-webbridge-requires-user-browser`：需用户浏览器+扩展活跃，自主会话无法驱动。视觉 UAT 改由 widget 测试（responsive 2/2、preset 15/15）替代。用户若开浏览器可后续补 GLM preset 卡片真机视觉验证。

## Files

- `lib/features/ai/infrastructure/openai_adapter.dart`（+9 行：eager _getOrCreateClient + 注释）
