---
quick_id: 260618-rlo
slug: mc-02-refresh-glm-api-api
date: 2026-06-18
status: complete
type: real-api-integration-test
---

# MC-02 Refresh 写侧链路 — 真实 GLM API 集成测试

## 目标 / Goal

闭合 STATE「待真实API验证: refresh 触发链 (save→summarize→store→读 fresh)」的 headless 缺口。

slice 1 (`chapter_summarization_real_glm_test.dart`) 已证 `summarize()` 对真实 GLM 成立；
但 **MC-02 slice 3+4 的 refresh 全链路（决策→summarize→put 持久化→读回）+ 幂等性（二次调用不烧 quota）
从未对真实 GLM 验证** —— 既有 `chapter_summary_refresh_service_test.dart` T1-T9 全是 fake adapter，
STATE 明标此项为「待真实API验证，需浏览器/真机」（实际仅 UI wiring 需真机，服务层可 headless 验证）。

## 缺口证据 / Evidence

- `grep refreshIfNeeded` → 仅 2 个 fake 测试文件（无 `GLM_API_KEY`/`Platform.environment` 门控）
- 真实 key 已验证有效（智谱 GLM-4-flash，curl HTTP 200，2.1s）
- slice1 真实测试 GREEN（47 字摘要 / 300 字源）
- opening_guide journey 真实 GREEN（3 风格，38s）

## 方案 / Approach

新建 `test/features/manuscript/application/chapter_summary_refresh_service_real_glm_test.dart`，
镜像 slice1 模式：读 `GLM_API_KEY`/`GLM_BASE_URL`/`GLM_MODEL` env，无 key skip（CI 安全）。
用真实 `OpenAIAdapter` + 真实 Hive `ChapterSummaryRepository`（temp box）构造 `ChapterSummaryRefreshService`。

## 测试用例 / Cases

- **T1（首次刷新）**: `refreshIfNeeded(rich chapter, 无 stored)` → real GLM summarize → put 持久化
  - `outcome.refreshed == true`
  - content-faithful: summary 含主角「林风」（防幻觉）
  - bounded: summary.length < 250（soft 120，real LLM pad，0ae lesson）
  - compressed: summary.length < source*0.6（真压缩）
  - `sourceWordCount == chapter.wordCount`（staleness 契约）
  - repository 读回一致（summary 文本 + sourceWordCount + chapterId/manuscriptId）—— 证明持久化 round-trip
- **T2（幂等）**: 同章未变再次 `refreshIfNeeded` → stored fresh（wordCount==sourceWordCount→isStale false）→ fast-path
  - `outcome2.refreshed == false`（不烧第二次 quota）
  - `outcome2.summary.summary == T1 summary`（返回 stored）

## 文件 / Files

- 新增: `test/features/manuscript/application/chapter_summary_refresh_service_real_glm_test.dart`
- 复用 fixture: slice1 同款修仙章节（林风/古玉/赵天磊/苏雪晴/清虚真人，~370 non-blank chars）

## 验证 / Verification

- `flutter test test/features/manuscript/application/chapter_summary_refresh_service_real_glm_test.dart`（注入 GLM_API_KEY）→ GREEN
- `dart analyze` → 0 issues（全仓零回归）
- T2 幂等性确认：真实环境不浪费第二次 LLM 调用

## 成功标准 / Done

- 真实 GLM 下 T1+T2 GREEN ✅ (52-char summary / 300-char source; 幂等二次返回 stored)
- analyze 0
- STATE.md Quick Tasks 表新增一行，闭合「待真实API验证」

## 执行记录 / What actually happened (root cause)

首跑 T1/T2 全 `AIStreamException: HTTP 400`，但 slice1/curl 同 key 同 payload 全 200。
深挖（curl stream 对照 / openai_dart toJson dump / repro 隔离）排除：瞬态、限流、配额、请求格式
（openai_dart JSON `{model,messages,max_tokens}` 与 curl 字节一致）。

**根因 = flutter_test HTTP mock 陷阱**：初版 setUp 用 `helpers/hive_test_helper.dart` 的
`setUpHiveTest()`，它调 `TestWidgetsFlutterBinding.ensureInitialized()`，flutter_test 的 binding
随即安装 `HttpOverrides.global` 拦截**所有** HTTP 返回 400（日志原文 "all HTTP requests will
return status code 400, and no network request"）。slice1（不调 ensureInitialized）/ opening_guide
（real key 不调）/ curl 全不受影响 → 总 200；本测试调了 → 确定性 400。

**修复**：setUp 改用 `journey_container.dart` 模式——直接 `Hive.init(tempDir.path)` + `openBox`，
**不**调 ensureInitialized（显式 temp 路径不需 Flutter binding）。tearDown 手动 close+delete。
修复后 T1+T2 真实 GLM GREEN。

**可复用教训**：真实 API 测试禁用 `setUpHiveTest()`（其 ensureInitialized 触发 HTTP mock）；
需 Hive 时直接 `Hive.init(explicitTempPath)`，镜像 journey_container。journey_container.dart 早已
规避此坑（仅 local test key 才 ensureInitialized）。

**次要观察（未改，记录待评估）**：openai_dart 的 `ApiException` 对 GLM 400 `body:null`，
`classifyException`→`_safeDiagnostic` 只得 "HTTP 400 error"——provider 错误体黑箱（wma 加了
toString 但 body 仍丢）。若未来需诊断真实 GLM 拒因，需让 adapter 捕获响应体。本次非阻断。
