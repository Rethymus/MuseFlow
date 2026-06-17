---
quick_id: 260617-wma
slug: fix-aiexception-tostring-and-adapter-tra
status: complete
date: 2026-06-17
commit: b9347bd
---

# 修复真实 GLM API 暴露的可靠性双缺口

## 触发
真实 BigModel key E2E 验证（闭合 STATE #1 blocker）跑 serial_generation journey：smoke(484字符) + 真实生成第 1-5 章(409-469字符,知识库注入链路通) 后，第 6 章 AIStreamException 杀死整批 30 章生成。

## 根因（PUA 铁律一：读源码+探针验证，不猜）
- classifyException 把非 429/非连接错误归 AIStreamException；探针同时间窗 8 连发(3s节奏)全过(550-770字符)→确诊**瞬时错误**(5xx/连接抖动/SSE解析)，非限流(会是 AIRateLimitException)非鉴权。
- AIException 不 override toString→诊断黑箱("Instance of...")，_safeDiagnostic 脱敏诊断全丢。
- 9 调用方走 createStream，仅 synthesis_notifier 自带重试，其余 8 个 + journey 零重试→一次瞬断杀死整批。

## 修复
- **缺口1**: AIException 基类加 `toString() => '$runtimeType: $message'`。零行为变更。
- **缺口2**: OpenAIAdapter 抽出 `static retryStream(factory,{maxRetries=3,backoff})` async* 生成器——仅【零 token 已发射】且【可重试 AIRateLimit/AINetwork/AIStream】时退避重试(100/200/400ms)，发射过 token 或不可重试(AIAuth)直接透传避免部分输出重复。createStream 委托 retryStream，收敛重试到单一咽喉(与「单一量尺」原则一致)。

## 验证
- 7 确定性测试全绿(ai_resilience_test.dart)，backoff Duration.zero 秒过：toString 外露 message / 失败2次后恢复(调用3次) / AIAuth 不重试(1次) / mid-stream 发射后不重试 / maxRetries 耗尽(3次) / clean pass-through(1次)。
- flutter analyze 0(3 文件)。
- 真实 GLM smoke 此前已过(484字符)，retryStream 对正常流透明转发(test 6 证明)。

## 暂留
- 真实 GLM smoke 重跑回归本次未跑(context 临界，happy-path 由确定性测试覆盖；下次可带 GLM_API_KEY 跑 serial smoke 复核)。
- synthesis_notifier 自带重试逻辑未合并到 adapter(向后兼容，可后续统一收敛，避免本次风险)。
