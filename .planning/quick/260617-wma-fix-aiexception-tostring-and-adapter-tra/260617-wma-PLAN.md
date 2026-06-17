---
quick_id: 260617-wma
slug: fix-aiexception-tostring-and-adapter-tra
status: in-progress
date: 2026-06-17
---

# 修复真实 GLM API 暴露的可靠性双缺口

## 根因（已查清，真实 BigModel key 实证）
真实 GLM journey 第 6 章 AIStreamException 杀死整批 30 章生成。探针同时间窗 8 连发全过（550-770 字符）→ 确诊**瞬时错误**（5xx/连接抖动/SSE 解析），非限流（会是 AIRateLimitException）非鉴权。

## 缺口 1 — AIException.toString() 诊断黑箱
- `lib/features/ai/domain/ai_exception.dart`：sealed AIException 有 message 字段但不 override toString → 错误日志全 "Instance of 'AIStreamException'"，openai_adapter._safeDiagnostic 脱敏诊断全丢。
- 修：AIException 基类加 `toString() => '$runtimeType: $message'`。纯代码零行为变更。

## 缺口 2 — adapter 层瞬断零重试
- 9 调用方走 `adapter.createStream`，仅 synthesis_notifier 自带重试，其余 8 个 + journey 零重试。
- 修：OpenAIAdapter 抽出 `static retryStream(factory, {maxRetries, backoff})`——async* 生成器，仅当【零 token 已发射】且【可重试：AIRateLimit/AINetwork/AIStream】时退避重试（默认 maxRetries=3，100/200/400ms 测试友好），发射过 token 或不可重试（AIAuth）直接透传。createStream 委托 retryStream。
- 收敛重试到单一咽喉（与「单一量尺」原则一致），9 调用方 + journey 全部受益。

## 任务
- T1: AIException.toString + 测试（RED→GREEN）
- T2: OpenAIAdapter.retryStream + createStream 委托 + 测试（RED→GREEN）
- T3: 真实 GLM smoke 回归 + flutter analyze 0

## 验证（确定性，不烧 quota）
- toString：catch 断言 toString.contains(message)
- retryStream：factory 失败 2 次后成功→yield 'ok'/调用 3 次；AIAuthException→不重试 1 次抛；已发射 token 后失败→不重试抛；maxRetries 耗尽→抛
- 真实 GLM smoke（GLM_API_KEY env）回归仍过；analyze 0
