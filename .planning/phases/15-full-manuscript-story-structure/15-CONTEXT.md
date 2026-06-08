# Phase 15: Full Manuscript & Story Structure - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

This is a **user journey validation phase**, not a feature-building phase. All features needed are already shipped (v1.0–v1.2): story structure management (foreshadowing tracking, logic loop detection, consistency guardian), format cleaning (punctuation, layout, markdown residue), three-format export (Markdown/TXT/JSON), and writing statistics (word count, AI usage rate, writing speed).

The phase delivers: (1) extending the Phase 14 xianxia manuscript from 30 chapters to 100 chapters using real GLM API generation with stage-specific prompts and previous-chapter summary injection, (2) validating story structure (foreshadowing, cross-chapter tracking, resolution) and Skill guardian deviation detection at 100-chapter scale, (3) full 100-chapter format cleaning with automated assertions (markdown residue, CJK punctuation, layout), (4) three-format export with multi-layer assertions (structure, content, metadata, file size), (5) writing statistics accuracy verification (word count, AI usage rate, writing speed) and token audit completeness (100 records).

This phase does NOT add new user-facing features. It does NOT build Claude or Ollama adapters. It does NOT modify existing editor, knowledge base, manuscript management, format cleaning, export, or statistics code beyond any bug fixes discovered during validation.

**Requirements covered:** JOURNEY-07 (story structure validation), JOURNEY-08 (format cleaning validation), JOURNEY-09 (three-format export validation), JOURNEY-10 (writing statistics validation).

</domain>

<decisions>
## Implementation Decisions

### 故事延续策略
- **D-01:** 三段式故事线 — 31-60章金丹期（含结丹失败/重来），61-90章元婴期（含劫难/心魔），91-100章飞升结局。前松后紧，中间有冲突高潮，适合验证伏笔埋设和回收。
- **D-02:** 经典冲突多线并进 — 结丹失败、同门算计、师姐被掳、门派大战、心魔劫、天劫。多冲突线适合验证伏笔系统的跨章跟踪能力。
- **D-03:** 复用 Phase 14 serial_generation_test 模式 + 阶段 prompt — 金丹期/元婴期/飞升期各自设定新场景 prompt。最小化脚本改动，阶段 prompt 提供情节方向。
- **D-04:** 前章摘要注入 — 每章生成时注入前一章摘要作为上下文，确保跨章连续性。100章规模需要比 Phase 14（仅知识库注入）更强的连续性保障。Phase 11 已有相邻章节摘要机制（AI 上下文注入）。

### 伏笔验证方式 (JOURNEY-07)
- **D-05:** 3-4 条主伏笔线 — 如神秘身世、师姐的秘密、门派禁地、远古法器。在30章前埋设，100章内全部回收。足以验证跨 70+ 章的伏笔跟踪能力。
- **D-06:** 自动化数据层测试 + 手动 UI 抽查 — Dart 测试脚本调用 ForeshadowingService API 创建/跟踪/解决伏笔，断言状态转换正确。同时手动抽查 UI 显示。
- **D-07:** 验证 Skill 守护偏离检测在 100 章规模下持续工作 — Phase 14 的 30 章有 87 次偏离警告。100 章偏离检测应持续触发，警告数量合理增长。

### 格式清洗验证 (JOURNEY-08)
- **D-08:** 全量清洗 + 三类核心断言 — 对 100 章全量执行格式清洗，自动化检查：(1) Markdown 语法残留（#、**、\`\`\`等符号），(2) 中英文标点混用（,与，混用），(3) 排版异常（连续空行、缺少段间距）。

### 导出验证 (JOURNEY-09)
- **D-09:** 全量导出 + 多层断言 — 三种格式全量导出，自动化验证：(1) Markdown 有正确的章节标题层级（# 第N章），(2) TXT 无 Markdown 语法残留，(3) JSON 包含完整元数据（章节标题、字数、时间戳），(4) 文件大小检查（100章应 3-5万字）。

### 统计验证 (JOURNEY-10)
- **D-10:** 三指标范围断言 — (1) 总字数在 3-5 万字范围内（±10%），(2) AI 使用率接近 100%（±5%），(3) 写作速度 > 0（只验证可计算）。
- **D-11:** Token 审计记录完整性 — 验证审计记录数量 ≥ 100 次（每章一次 AI 调用），总 input/output token 在合理范围。间接验证 Phase 12 基础设施在 100 章规模下的准确性。

### 从 Phase 14 继承的决策（不重复编号）
- 自动化为主 + 手动抽查关键交互点（Phase 14 D-01）
- 真实 GLM API 生成内容（Phase 14 D-02）
- 串行间隔调用 2-3 秒，遇错即停（Phase 14 D-03/D-04）
- 结构化问题清单（Phase 14 D-06）
- 修仙世界观 + 角色卡 + Skill 守护规则不变（Phase 14 D-07/08/09）
- 每章 300-500 字，enforceD11Bounds 后处理（Phase 14 D-11）

### Claude's Discretion
Planners may choose:
- 三段式故事的具体情节大纲（金丹期/元婴期/飞升期每阶段的具体章数分配和情节节点）
- 3-4 条主伏笔线的具体内容（身世、秘密、禁地、法器的具体设定）
- 阶段 prompt 的具体措辞（金丹期/元婴期/飞升期的新场景描述）
- 前章摘要的生成方式（调用 AI 生成摘要 vs 简单截取前 N 字）
- 格式清洗断言的正则表达式细节
- 导出 JSON 元数据的具体字段验证列表
- 自动化测试脚本的具体结构和分段策略
- 伏笔 UI 抽查的具体操作步骤

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 产品范围
- `.planning/ROADMAP.md` — Phase 15 目标、4 条成功标准（JOURNEY-07~10）、依赖（Phase 14）、v1.3 里程碑边界。
- `.planning/REQUIREMENTS.md` — JOURNEY-07（故事结构验证：伏笔埋设→跨章跟踪→填坑）、JOURNEY-08（格式清洗：标点/排版/Markdown残留）、JOURNEY-09（三格式导出：Markdown/TXT/JSON）、JOURNEY-10（写作统计：字数/AI使用率/写作速度）。
- `.planning/PROJECT.md` — 核心产品价值（反AI味）、本地优先约束、技术栈（Flutter/Riverpod/Hive）、v1.3 目标（百章修仙超短篇小说 + token 消耗全程审计）。

### 前期阶段上下文
- `.planning/phases/14-world-building-first-30-chapters/14-CONTEXT.md` — Phase 14 验证策略、GLM API 配置、30章生成脚本模式、enforceD11Bounds 后处理、手动/自动化抽查范围、结构化问题清单格式。**Phase 15 的 70 章生成直接复用此脚本模式。**
- `.planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` — Phase 14 发现的 6 个问题（含 1 个已关闭高严重级），修复方案和验证证据。**Phase 15 应检查这些问题是否在 100 章规模下复现。**
- `.planning/phases/14-world-building-first-30-chapters/14-VERIFICATION.md` — Phase 14 验证结果：6/6 成功标准通过、13 个必需产物、12 个关键链接验证。**Phase 15 延续此验证框架到 100 章。**
- `.planning/phases/13-automation-test-harness/13-CONTEXT.md` — FakeAdapter、ProviderContainer override 模式、Dart 自动化脚本结构（8 段分段 + 1 E2E）、集成测试 Key 策略。**Phase 15 自动化测试复用此基础设施。**
- `.planning/phases/12-token-audit-infrastructure/12-CONTEXT.md` — TokenAuditMiddleware 架构、审计数据持久化、操作类型分类（4 组）。**100 章真实 AI 调用产生 100 条审计记录，验证 Phase 12 基础设施的规模表现。**

### 现有代码锚点
- `test/journey/serial_generation_test.dart` — Phase 14 的 30 章串行生成测试，Phase 15 的 70 章生成脚本以此为基础扩展（改起始章节 + 阶段 prompt + 前章摘要注入）。
- `test/journey/helpers/journey_container.dart` — Phase 14 的测试容器工厂（ProviderContainer + Hive 初始化 + GLM API 配置），Phase 15 复用。
- `test/journey/helpers/d11_bounds.dart` — enforceD11Bounds 后处理函数，100 章生成同样需要 D-11 合规。
- `test/journey/full_journey_test.dart` — Phase 14 的端到端全流程测试（世界构建→碎片→开篇→30章生成→持久化→Token审计），Phase 15 扩展到 100 章。
- `test/journey/automated_ui_evidence_test.dart` — Phase 14 的自动化 UI 证据测试（编辑器操作/反AI味/知识注入/开篇风格/章节操作），Phase 15 扩展验证范围。
- `lib/features/story_structure/application/format_cleaner.dart` — FormatCleaner 服务，JOURNEY-08 格式清洗验证调用此服务。
- `lib/features/story_structure/domain/format_clean_result.dart` — 清洗结果实体，断言检查的数据结构。
- `lib/features/story_structure/application/export_service.dart` — ExportService 三格式导出，JOURNEY-09 导出验证调用此服务。
- `lib/features/story_structure/domain/export_bundle.dart` — 导出包实体，包含章节标题结构和元数据。
- `lib/features/manuscript/domain/chapter_export.dart` — 章节导出模型。
- `lib/features/stats/application/writing_stats_collector.dart` — 写作统计收集器（30s debatched Hive 写入），JOURNEY-10 验证其准确性。
- `lib/features/stats/presentation/writing_stats_page.dart` — 写作统计页面，展示字数/AI使用率/写作速度。
- `lib/features/stats/domain/stats_snapshot.dart` — 统计快照实体。
- `lib/features/stats/domain/writing_unit_counter.dart` — 写作单元计数器。
- `lib/features/stats/infrastructure/token_audit_repository.dart` — Token 审计记录读取，JOURNEY-10 验证 100 条审计记录完整性。
- `lib/features/ai/application/prompt_pipeline.dart` — PromptPipeline 中间件链（KnowledgeInjectionMiddleware + DeviationDetectionMiddleware + AntiAIScentMiddleware + TokenAuditMiddleware），100 章生成时全部中间件自动工作。
- `lib/features/ai/infrastructure/openai_adapter.dart` — OpenAI 兼容适配器，真实 GLM API 调用使用此适配器。
- `lib/core/presentation/providers.dart` — 全局 Riverpod provider 注册中心。
- `lib/features/manuscript/infrastructure/manuscript_repository.dart` — 文稿持久化。
- `lib/features/manuscript/infrastructure/chapter_repository.dart` — 章节持久化（CRUD/排序/拆分/合并）。

### 故事结构相关
- `lib/features/story_structure/` — 故事结构模块（伏笔跟踪、逻辑闭环检测、一致性守护）。Phase 5 交付，Phase 15 在 100 章规模下验证。
- `lib/features/knowledge/application/deviation_detection_service.dart` — Skill 守护偏离检测服务，Phase 15 验证 100 章偏离检测持续工作。
- `lib/features/ai/application/anti_ai_scent_processor.dart` — 反AI味处理器，Phase 14 已验证移除 3 个 AI 味短语，100 章持续验证。

</canonical_refs>

<code_context>
## Existing Code Insights

### 可复用资产
- **Phase 14 全套 journey 测试脚本** — `test/journey/serial_generation_test.dart`（30章串行生成）、`test/journey/full_journey_test.dart`（端到端全流程）、`test/journey/automated_ui_evidence_test.dart`（5项自动化UI证据）、`test/journey/helpers/`（journey_container、d11_bounds）。Phase 15 直接复用和扩展。
- **Phase 13 自动化基础设施** — `test/automation/helpers/test_container.dart`（ProviderContainer 工厂）、`test/automation/helpers/fake_adapter.dart`（FakeAdapter）、`test/helpers/hive_test_helper.dart`（Hive 测试初始化）。
- **FormatCleaner 服务** — Phase 5 交付，支持标点修复、排版美化、Markdown残留清理。JOURNEY-08 直接调用。
- **ExportService** — Phase 5 交付，支持 Markdown/TXT/JSON 三格式导出。JOURNEY-09 直接调用。
- **WritingStatsCollector** — Phase 9 交付，30s debatched Hive 写入。JOURNEY-10 验证其 100 章数据准确性。
- **TokenAuditRepository** — Phase 12 交付，独立 Hive box 存储审计记录。JOURNEY-10 验证 100 条记录完整性。
- **PromptPipeline 中间件链** — 已包含 KnowledgeInjectionMiddleware + DeviationDetectionMiddleware + AntiAIScentMiddleware + TokenAuditMiddleware。100 章生成时全部自动工作。
- **enforceD11Bounds** — Phase 14 后处理函数，确保每章 300-500 字。100 章生成同样需要。

### 已建立模式
- Riverpod ProviderContainer + overrides 实现依赖替换（Phase 13/14 模式）。
- 串行 GLM API 调用 + 2-3 秒间隔 + 遇错即停（Phase 14 D-03/D-04）。
- enforceD11Bounds 句子边界截断后处理（Phase 14 D-11）。
- 结构化问题清单格式：`{分类, 严重程度, 标题, 复现步骤, 期望行为, 实际行为, 截图/日志}`。
- Clean Architecture 四层分离，自动化测试帮助文件在 `test/journey/` 和 `test/automation/`。
- 实体不可变 + copyWith + Hive TypeAdapter 持久化。

### 集成点
- 70 章生成脚本：基于 `serial_generation_test.dart`，改起始章节为 31，添加阶段 prompt + 前章摘要注入。
- 格式清洗测试：调用 `FormatCleaner` 对 100 章全量清洗，断言三类核心问题。
- 导出测试：调用 `ExportService` 对 100 章三格式导出，断言结构/内容/元数据。
- 统计验证：读取 `WritingStatsCollector` 和 `TokenAuditRepository` 数据，范围断言。
- 伏笔验证：调用故事结构模块 API（ForeshadowingService），断言 3-4 条伏笔线状态转换。
- 偏离检测验证：检查 100 章生成的偏离警告数量合理增长。

</code_context>

<specifics>
## Specific Ideas

- 三段式故事结构：金丹期（31-60章，30章）含结丹失败/重来等冲突，元婴期（61-90章，30章）含劫难/心魔，飞升结局（91-100章，10章）。经典修仙成长线。
- 阶段 prompt 策略：每进入新阶段（金丹/元婴/飞升）时，用特殊 prompt 设定新场景和冲突方向，中间章节基于前章摘要 + 知识库生成。
- 前章摘要注入：每章生成前，获取前一章内容的前 N 字或通过 AI 生成摘要，注入到当前章的 prompt 上下文中。Phase 11 已有相邻章节摘要机制可参考。
- 3-4 条主伏笔线：如主角神秘身世（第1-5章埋设，第90-95章回收）、师姐的秘密（第10-15章埋设，第70-80章回收）、门派禁地（第20-25章埋设，第85-90章回收）、远古法器（第30章左右埋设，第95-100章回收）。
- 格式清洗三类断言：(1) Markdown 残留 regex：`/[#*`\[\]]/`，(2) 中英标点混用 regex：`/[a-zA-Z][,.;!?]/`，(3) 排版异常：连续 3+ 空行。
- 导出多层断言：Markdown 文件包含 100 个 `# ` 章节标题行，TXT 文件不包含 Markdown 语法字符，JSON 文件包含 `chapters` 数组且长度为 100，文件总大小在 30,000-50,000 字符范围。
- 统计范围断言：总字数 27,000-55,000（100章×300-500×±10%），AI 使用率 95-100%，Token 审计记录 ≥ 100 条。

</specifics>

<deferred>
## Deferred Ideas

以下想法在讨论中提出，但超出 Phase 15 的验证边界。记录供后续阶段或独立任务规划。

- **完整小说包** — 100章手稿 + 章节标题 + 全书简介 + 角色关系图 + 世界观设定摘要，放入 `docs/sample-novel/` 作为 MuseFlow 实战案例展示。属于 Phase 16 之后的产出整理或独立的内容发布任务。
- **中英文双语 README** — README.md（中文）+ README_EN.md（英文），产品经理视角激情推广风格（"让AI帮你写好故事，但读者看不出AI痕迹"），互相链接跳转，格式符合 GitHub 规范。属于项目展示/营销层面，独立于 v1.3 验证里程碑。
- **全功能自动化截图** — 使用 WSL2 现有环境通过自动化流程（Flutter integration_test + 截图 capture）捕获所有关键功能运行截图，绕过 IME 限制。Phase 14 的 automated_ui_evidence_test 已证明自动化可绕过 IME 限制。截图用于 README 展示。
- **同步到远程仓库** — 将完整小说包、双语 README、功能截图同步到 GitHub 远程仓库。属于发布流程，独立规划。

</deferred>

---

*Phase: 15-Full Manuscript & Story Structure*
*Context gathered: 2026-06-08*
