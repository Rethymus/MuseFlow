---
quick_id: 260618-rlo
slug: mc-02-refresh-glm-api-api
date: 2026-06-18
status: complete
commit: dbde38a
files_changed:
  - test/features/manuscript/application/chapter_summary_refresh_service_real_glm_test.dart (new)
---

# MC-02 Refresh 写侧链路 — 真实 GLM API 集成测试

## 交付 / What

新增 `chapter_summary_refresh_service_real_glm_test.dart`，闭合 STATE「待真实API验证:
refresh 触发链 (save→summarize→store→读 fresh)」headless 缺口。真实 GLM-4-flash 下：

- **T1**（首次刷新）：`refreshIfNeeded(rich chapter, 无 stored)` → 真实 GLM summarize → put 持久化
  → `refreshed==true` + 含主角「林风」(content-faithful) + <250 字 (bounded) + <源 60% (compressed)
  + `sourceWordCount==chapter.wordCount` + repository 读回一致（证明 write→store→read round-trip）。
  实测：52 字摘要 / 300 字源。
- **T2**（幂等）：同章未变再次 `refreshIfNeeded` → stored fresh（wordCount==sourceWordCount→isStale false）
  → `refreshed==false` 返回 stored，**不烧第二次 quota**（rapid-autosave / 重开的配额安全保证）。

镜像 slice1 `chapter_summarization_real_glm_test.dart`：读 `GLM_API_KEY`/`GLM_BASE_URL`/`GLM_MODEL` env，
无 key skip（CI 永不烧 quota）。既有 fake 决策树测试 T1-T9 不变。

## 根因深挖（30 分钟诊断，值得记录）

首跑 T1/T2 全 `AIStreamException: HTTP 400`，但 slice1/curl 同 key 同 payload 全 200。逐项排除：
瞬态 ❌（稳定复现）、限流/配额 ❌（curl 10/10 全 200）、请求格式 ❌（openai_dart `toJson()`
`{model,messages,max_tokens}` 与 curl 字节一致）。

**根因 = flutter_test HTTP mock 陷阱**：初版 setUp 用 `helpers/hive_test_helper.dart` 的
`setUpHiveTest()` → 调 `TestWidgetsFlutterBinding.ensureInitialized()` → flutter_test binding
安装 `HttpOverrides.global` 拦截**所有** HTTP 返回 400（日志原文 "all HTTP requests will return
status code 400, and no network request"）。slice1 / opening_guide（real key）/ curl 全不调
ensureInitialized → 总 200；本测试调了 → 确定性 400。

**修复**：setUp 改用 `journey_container.dart` 模式——直接 `Hive.init(tempDir.path)` + `openBox`，
不调 ensureInitialized（显式 temp 路径不需 Flutter binding）。修复后 T1+T2 真实 GLM GREEN。

## 验证 / Evidence

- `flutter test .../chapter_summary_refresh_service_real_glm_test.dart`（GLM_API_KEY 注入）→ `+2: All tests passed!`（6s）
- `dart analyze` 新文件 → No issues found
- `flutter analyze` 全仓 → No issues found (5.3s) 零回归
- `flutter test test/features/manuscript/application/` → `+61 ~3: All tests passed!`（3 skip = 2 新真实测试 + slice1 无 key）

## 教训 / Lessons

1. **真实 API 测试禁用 `setUpHiveTest()`**（其 `ensureInitialized` 触发 HTTP mock 拦截真实调用）。
   需 Hive 时直接 `Hive.init(explicitTempPath)`，镜像 `journey_container.dart`（早已规避此坑，
   仅 local test key 才 ensureInitialized）。
2. **openai_dart 对 GLM 400 的 `ApiException.body` 为 null** → `classifyException`→`_safeDiagnostic`
   只得 "HTTP 400 error"，provider 拒因黑箱（wma 加了 toString 但 body 仍丢）。本次靠 curl 对照破案；
   待评估后续：让 adapter 捕获响应体，使真实 provider 错误可诊断。

## 闭合 / Closes

STATE「待真实API验证: refresh 触发链」headless 半环。MC-02 服务层全链路（决策→summarize→persist→
读回 + 幂等）现对真实 GLM 持续可验证。剩余仅 UI wiring 真机 UAT（不在 headless 范围）。
