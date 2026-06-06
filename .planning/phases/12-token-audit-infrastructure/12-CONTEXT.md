# Phase 12: Token Audit Infrastructure - Context

**Gathered:** 2026-06-06
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers automatic token usage recording for every AI API call in MuseFlow. A `TokenAuditMiddleware` integrated into the existing PromptPipeline captures per-call token usage (input tokens, output tokens, model name, operation type, associated manuscript/chapter ID, timestamp) and persists it to an independent Hive box (`token_audit`). Users can view token consumption summaries (embedded in the existing WritingStatsPage) and detailed breakdowns (separate TokenAuditPage) with per-chapter and per-operation-type distributions.

This phase does NOT calculate monetary cost (deferred to Phase 16 REPORT-01). It does NOT require exact token counting via `stream_options` (estimation is sufficient per REQUIREMENTS.md Out of Scope). It does NOT add Anthropic or Ollama adapter support (only OpenAI-compatible adapter exists).

</domain>

<decisions>
## Implementation Decisions

### 拦截方式
- **D-01:** Token 用量通过 Pipeline 中间件捕获。在现有 PromptPipeline 中间件链中新增 `TokenAuditMiddleware`。调用方在构建 prompt 时传入操作类型和关联 ID 上下文，中间件在流完成后记录审计数据。不改 adapter 返回类型。

### UI 展示
- **D-02:** 两层 UI 结构：(1) WritingStatsPage 底部嵌入 Token 消耗摘要卡片（总输入 token、总输出 token、AI 调用次数），与现有统计共存一页；(2) 独立 TokenAuditPage 展示详细图表（按章分布、按操作类型分布）。统计页 AppBar 或摘要卡片提供跳转入口。

### 成本策略
- **D-03:** 本阶段只展示 token 数量和分布，不换算货币成本。AUDIT-03 的"总成本"在本阶段理解为"总 token 消耗量"。货币成本推算推迟到 Phase 16（REPORT-01）。

### 操作类型分类
- **D-04:** 4 组功能分组归类：
  - 整理类（synthesis）— 碎片捕捉→AI整理
  - 编辑类（rewrite + polish + freeInput）— 编辑器浮窗操作
  - 世界观类（skillGen + opening + deviationDetect）— Skill/开篇/偏离检测
  - 模板类（templateComplete）— 模板补全

### 关联 ID 设计
- **D-05:** manuscriptId + chapterId 双维度关联。所有 AI 调用至少关联 manuscriptId（文稿级）。章节上下文内的操作（编辑类、整理类）额外关联 chapterId。无章节上下文的调用（世界观类、模板类）仅关联 manuscriptId，chapterId 为 null。审计页面支持按文稿和按章节两个维度查看。

### 数据保留策略
- **D-06:** 审计记录设上限自动清理。超过上限时按时间顺序删除最旧记录，保留最新的记录。

### Claude's Discretion
- 清理上限条数（建议 10000 条，约 100 章 10 倍余量）
- TokenAuditMiddleware 具体实现方式（如何在 PromptPipeline 中间件链中捕获流完成后的 usage 数据）
- 操作类型的中文标签和枚举命名
- Token 估算方法：使用 API 响应中的 usage 字段（openai_dart 可能在流结束事件中返回），或回退到 TokenBudgetCalculator 文本估算
- TokenAuditPage 的具体图表类型（柱状图、饼图等）

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 产品范围
- `.planning/ROADMAP.md` — Phase 12 目标、成功标准（3 条）、依赖（Phase 11）、v1.3 里程碑边界。
- `.planning/REQUIREMENTS.md` — AUDIT-01（每次 AI 调用记录 token 用量）、AUDIT-02（持久化到独立 Hive box）、AUDIT-03（消耗总览页面）、Out of Scope（Token 精确计数 stream_options 不在本阶段 scope）。
- `.planning/PROJECT.md` — 核心产品价值、本地优先约束、技术栈（Flutter/Riverpod/Hive）、v1.3 目标（Token 消耗全程审计）。

### 现有代码锚点
- `lib/features/ai/infrastructure/openai_adapter.dart` — 当前唯一 AI 适配器。`createStream()` 只流式输出文本 delta，API 响应中的 usage 数据被丢弃。中间件需在流完成后捕获 usage。
- `lib/features/ai/application/prompt_pipeline.dart` — 现有 PromptPipeline 中间件链（AntiAIScentMiddleware、KnowledgeInjectionMiddleware、DeviationDetectionMiddleware）。TokenAuditMiddleware 将加入此链。
- `lib/features/ai/application/token_budget_calculator.dart` — 现有 token 估算工具（中文 1.8x、ASCII 0.25x），可用于回退估算。
- `lib/features/stats/application/writing_stats_collector.dart` — 30s debatched Hive 写入模式，可复用于审计记录写入。
- `lib/features/stats/presentation/writing_stats_page.dart` — 现有统计页面，Token 消耗摘要卡片将嵌入此页底部。
- `lib/features/stats/presentation/charts/ai_usage_pie_chart.dart` — 现有 AI 使用比例饼图（human vs AI 字数），审计页面的操作类型分布图可参考此实现。
- `lib/features/stats/domain/stats_snapshot.dart` — 现有统计数据快照实体，Token 审计数据需要独立的快照或聚合模型。
- `lib/core/presentation/providers.dart` — 全局 Riverpod provider 注册中心，Token 审计相关 provider 将在此注册。

### AI 调用点（需传入操作类型上下文）
- `lib/features/ai/presentation/synthesis_notifier.dart` — 碎片整理（操作类型：整理类）
- `lib/features/editor/application/editor_ai_notifier.dart` — 编辑器 AI 操作（操作类型：编辑类）
- `lib/features/onboarding/application/opening_generator_service.dart` — 开篇生成（操作类型：世界观类）
- `lib/features/knowledge/application/skill_generation_service.dart` — Skill 生成（操作类型：世界观类）
- `lib/features/knowledge/application/deviation_detection_service.dart` — 偏离检测（操作类型：世界观类）
- `lib/features/templates/application/template_completion_service.dart` — 模板补全（操作类型：模板类）

</canonical_refs>

<code_context>
## Existing Code Insights

### 可复用资产
- `PromptPipeline` 已有中间件链架构，新增 `TokenAuditMiddleware` 可直接接入。中间件按顺序处理 system prompt，audit 中间件可在链末尾包装整个 AI 调用。
- `WritingStatsCollector` 的 30s debatched 写入模式可直接复用于审计记录批量写入。
- `TokenBudgetCalculator` 可作为回退方案估算 token 数（当 API 响应不返回 usage 时）。
- `WritingStatsPage` 的 `_SummaryWrap` + `_ChartSection` 布局模式可直接复用嵌入 token 摘要卡片。
- `fl_chart` 包已引入（AIUsagePieChart 使用），Token 审计详情页的分布图可直接使用。
- `StatsSnapshot` 实体模式（immutable, copyWith）可作为 Token 审计聚合数据模型的参考。

### 已建立模式
- Hive box 按实体类型分开（Phase 9/11 模式），Token 审计应使用独立 box（如 `token_audit`）。
- Riverpod AsyncNotifier 管理异步状态，Token 审计 Notifier 应遵循此模式。
- Clean Architecture 四层分离，审计 domain 实体在 `lib/features/stats/domain/` 或新建 `lib/features/token_audit/domain/`。
- 实体不可变，使用 `copyWith` / `toJson` / `fromJson`、Hive TypeAdapter 持久化。

### 集成点
- TokenAuditMiddleware 需要修改 PromptPipeline 接口，接受操作类型和关联 ID 参数。
- 各 AI 调用方（6 处 notifier/service）需要传入操作类型和关联 ID。
- WritingStatsPage 需要新增 token 摘要卡片和跳转入口。
- 新增路由：TokenAuditPage（独立详情页）。
- Hive TypeAdapter 注册在 `lib/main.dart`。
- 新 provider 注册在 `lib/core/presentation/providers.dart`。

</code_context>

<specifics>
## Specific Ideas

- 中间件在 PromptPipeline 链中运行，调用方传入操作类型枚举和关联 ID（manuscriptId, chapterId?）。
- 审计记录写入采用与 WritingStatsCollector 相同的 30s debatched 模式，避免频繁 Hive 写入。
- 统计页摘要卡片显示：总输入 token、总输出 token、AI 调用次数，类似现有的 `_SummaryWrap` 布局。
- 审计详情页使用 fl_chart 展示按章节分布（柱状图）和按操作类型分布（饼图）。
- 操作类型分组：整理类、编辑类、世界观类、模板类 — 4 组，在 UI 展示时可折叠展开到具体操作。

</specifics>

<deferred>
## Deferred Ideas

- **货币成本计算** — 推迟到 Phase 16（REPORT-01），届时需要模型价格表和成本推算逻辑。
- **Token 精确计数（stream_options）** — Out of Scope，估算值对本里程碑足够。

</deferred>

---

*Phase: 12-Token Audit Infrastructure*
*Context gathered: 2026-06-06*
