# Phase 13: Automation Test Harness - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers automated test infrastructure that validates MuseFlow's core creation flow without requiring a real API key. Three deliverables: (1) a `FakeAdapter` implementing the new `AIAdapter` abstract interface extracted from `OpenAIAdapter`, returning deterministic xianxia prose; (2) Dart standalone automation tests using `ProviderContainer` with overrides to verify the full business logic pipeline (manuscript CRUD → 100-chapter creation → AI generation → export → token audit); (3) Flutter integration tests driving the real widget tree through critical UI flows including error scenarios.

This phase does NOT add user-facing UI. It does NOT implement Claude or Ollama adapters. It does NOT replace the existing `flutter test` unit test suite. It does NOT set up CI/CD pipelines.

</domain>

<decisions>
## Implementation Decisions

### FakeAdapter 架构
- **D-01:** 从 `OpenAIAdapter` 提取 `AIAdapter` 抽象接口。`OpenAIAdapter implements AIAdapter`，`FakeAdapter implements AIAdapter`。`openaiAdapterProvider` 类型改为 `Provider<AIAdapter>`。这是本 phase 唯一需要修改的生产代码变更。
- **D-02:** 重构范围仅限 `OpenAIAdapter` + `providers.dart`（`openaiAdapterProvider` 类型变更）。不改动其他 adapter（Claude/Ollama 尚未实现）。
- **D-03:** FakeAdapter 支持可配置错误参数：`errorRate`（概率返回错误文本）、`errorText`（固定错误内容）、`emptyResponse`（返回空字符串）。正常模式返回确定性修仙题材文本（per UI-SPEC 契约）。默认构造无错误配置，错误测试传入配置参数。

### TEST-01 Dart 自动化脚本
- **D-04:** 混合方案 — 8 个分段测试 + 1 个端到端汇总测试。分段测试各自独立（共享 setUp），便于定位失败；E2E 测试验证完整流程的端到端正确性。
- **D-05:** 端到端汇总测试跑 100 章（创建文稿→100章→100次AI调用→导出→token审计验证），设置 5 分钟超时（`Timeout(Duration(minutes: 5))`）。
- **D-06:** 8 段分段测试：文稿 CRUD、章节 CRUD、章节排序、AI 生成单章、AI 批量生成、导出 Markdown、导出验证（内容+格式）、token 审计验证。
- **D-07:** 导出测试使用真实文件 + 临时目录（`Directory.systemTemp`），导出后读取文件内容验证字符串。不 mock 文件写入。

### TEST-02 Flutter 集成测试
- **D-08:** 覆盖 4 类错误场景：空状态/无配置、AI 返回异常内容、删除后导航、快速重复操作。
- **D-09:** 复用现有 `test/helpers/hive_test_helper.dart`（`setUpHiveTest` / `tearDownHiveTest`），集成测试和单元测试共用同一初始化逻辑。

### Claude's Discretion
Planners may choose implementation details for:
- `AIAdapter` 抽象接口的具体位置（建议 `lib/features/ai/domain/ai_adapter.dart`，与现有 `ai_exception.dart` 同目录）
- 8 段分段测试的具体函数命名和断言粒度
- FakeAdapter 错误参数的具体 API 设计（构造函数参数 vs 配置方法）
- E2E 测试中 100 章 AI 调用的并发策略（串行 vs 批量）
- 集成测试的错误场景测试函数数量和分组
- `test/automation/helpers/test_container.dart` 中 ProviderContainer 工厂的具体 override 列表

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 产品范围
- `.planning/ROADMAP.md` — Phase 13 目标、成功标准（3 条）、依赖（Phase 12）、v1.3 里程碑边界。
- `.planning/REQUIREMENTS.md` — TEST-01（Dart 脚本核心流程）、TEST-02（Flutter 集成测试 UI 节点）、TEST-03（FakeAdapter 可复现验证）。
- `.planning/PROJECT.md` — 核心产品价值（反AI味）、本地优先约束、技术栈（Flutter/Riverpod/Hive）。

### 现有设计契约
- `.planning/phases/13-automation-test-harness/13-UI-SPEC.md` — 测试性契约：Widget Finder 策略表、需添加的 Key 列表、FakeAdapter 输出契约（确定性修仙文本）、集成测试流程（TEST-02 六步序列）、断言模式、Token 估算公式、文件结构契约。**必须优先于 RESEARCH 中的示例代码。**
- `.planning/phases/13-automation-test-harness/13-RESEARCH.md` — 架构图、ProviderContainer override 模式、FakeAdapter 代码示例、Dart 脚本示例、集成测试示例、4 个常见陷阱、反模式列表。

### 现有代码锚点
- `lib/features/ai/infrastructure/openai_adapter.dart` — 需要提取 `AIAdapter` 接口。公共 API：`Stream<String> createStream({apiKey, baseUrl, model, messages, temperature, topP, maxTokens, onUsage})`。内部有 HTTPS 验证、客户端缓存、错误分类。
- `lib/core/presentation/providers.dart` — `openaiAdapterProvider`（line 183-185）需改为 `Provider<AIAdapter>`。所有下游服务通过此 provider 获取 adapter。
- `lib/features/ai/domain/ai_exception.dart` — 现有 AI 异常层级，FakeAdapter 可能需要抛出这些异常来测试错误处理。
- `lib/features/ai/presentation/synthesis_notifier.dart` — 碎片整理 AI 调用点（操作类型：synthesis）。
- `lib/features/editor/application/editor_ai_notifier.dart` — 编辑器 AI 操作调用点（操作类型：rewrite、polish、freeInput）。
- `lib/features/manuscript/infrastructure/manuscript_repository.dart` — 文稿持久化，TEST-01 通过 ProviderContainer 直接调用。
- `lib/features/manuscript/infrastructure/chapter_repository.dart` — 章节持久化，TEST-01 批量创建 100 章。
- `lib/features/stats/infrastructure/token_audit_repository.dart` — Token 审计记录读取，TEST-01 验证 FakeAdapter 调用被正确记录。
- `lib/features/story_structure/application/export_service.dart` — 导出服务，TEST-01 验证导出内容。使用 dart:io file writer。
- `test/helpers/hive_test_helper.dart` — 现有 Hive 测试助手（`setUpHiveTest` / `tearDownHiveTest`），集成测试复用。
- `integration_test/app_test.dart` — 现有集成测试入口，TEST-02 的参考。

### Key 添加目标（UI-SPEC 指定）
- `lib/features/manuscript/presentation/manuscript_create_dialog.dart` — 添加 `Key('manuscript_title')`, `Key('manuscript_genre')`
- 章节列表 Widget — 添加 `Key('add_chapter_button')`, `Key('chapter_title_field')`（具体文件由 executor 确定）
- `lib/features/editor/presentation/floating_toolbar.dart` — 添加 `Key('ai_synthesis_button')`
- 导出 Widget — 添加 `Key('export_button')`（具体文件由 executor 确定）

</canonical_refs>

<code_context>
## Existing Code Insights

### 可复用资产
- `hive_test_helper.dart` — `setUpHiveTest()`（临时目录初始化）和 `tearDownHiveTest()`（deleteFromDisk），TEST-01 和 TEST-02 共用。
- `openaiAdapterProvider` — Riverpod Provider 模式，通过 `overrideWithValue()` 替换为 FakeAdapter。
- `TokenAuditService` — Phase 12 审计基础设施，FakeAdapter 的 `onUsage` 回调会被自动记录，TEST-01 可验证审计数据。
- `WritingStatsCollector` — 30s debatched Hive 写入模式，测试中需等待写入完成或调用 forceFlush。
- `ExportService` — 章节感知导出（Markdown/JSON），TEST-01 验证导出格式和内容。
- `ManuscriptRepository` / `ChapterRepository` — Hive 持久化 CRUD，TEST-01 通过 ProviderContainer 直接操作。
- `integration_test/app_test.dart` — 现有集成测试入口，可参考其 ProviderScope override 模式。

### 已建立模式
- Riverpod AsyncNotifier 管理异步状态，测试通过 `container.read(provider.notifier)` 访问。
- ProviderContainer + overrides 实现依赖替换，无需 Widget 树（纯 Dart 测试）。
- 实体不可变，使用 `copyWith` / `toJson` / `fromJson`，Hive TypeAdapter 持久化。
- Clean Architecture 四层分离，测试帮助文件放在 `test/helpers/` 和 `test/automation/helpers/`。

### 集成点
- 新建 `lib/features/ai/domain/ai_adapter.dart` — `AIAdapter` 抽象接口。
- 修改 `lib/features/ai/infrastructure/openai_adapter.dart` — `implements AIAdapter`。
- 修改 `lib/core/presentation/providers.dart` — `openaiAdapterProvider` 类型变更。
- 新建 `test/automation/helpers/fake_adapter.dart` — FakeAdapter 实现。
- 新建 `test/automation/helpers/test_container.dart` — ProviderContainer 工厂。
- 新建 `test/automation/fixtures/` — 测试数据 fixture。
- 新建 `test/automation/core_flow_test.dart` — TEST-01（8 段 + 1 E2E）。
- 新建 `test/automation/helpers/fake_adapter_test.dart` — TEST-03（FakeAdapter 单元测试）。
- 新建/更新 `integration_test/` — TEST-02（UI 集成测试 + 错误场景）。
- 现有 Widget 文件添加 ValueKey（UI-SPEC 指定的 6 个 Key）。

</code_context>

<specifics>
## Specific Ideas

- `AIAdapter` 接口只包含 `createStream()` 方法签名，与 `OpenAIAdapter.createStream()` 完全一致。
- FakeAdapter 通过消息内容检测操作类型（synthesis/rewrite/polish/freeInput），返回对应的修仙题材固定文本。
- FakeAdapter 在流结束后显式调用 `onUsage` 回调，模拟 token 统计（中文 1 字 ≈ 2 tokens）。
- FakeAdapter 错误模式通过构造函数配置：`FakeAdapter(errorRate: 0.5, errorText: '网络异常')`。
- 8 段分段测试各自 `setUp` 创建独立 ProviderContainer + Hive 临时目录，`tearDown` 清理。
- E2E 测试使用 `Timeout(Duration(minutes: 5))`，创建文稿→100章→100次AI调用→导出→验证。
- 集成测试通过 `ProviderScope(overrides: [openaiAdapterProvider.overrideWithValue(FakeAdapter())])` 启动。
- 导出测试写入 `Directory.systemTemp.createTempSync()` 下的临时文件，断言后清理。
- 错误场景测试组：`group('Empty states', ...)`, `group('AI anomalies', ...)`, `group('Post-delete navigation', ...)`, `group('Rapid operations', ...)`。

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 13-Automation Test Harness*
*Context gathered: 2026-06-07*
