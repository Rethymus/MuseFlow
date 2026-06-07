# Phase 14: World-Building & First 30 Chapters - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

This is a **user journey validation phase**, not a feature-building phase. All features needed are already shipped (v1.0–v1.2): knowledge base, fragment capture, editor with floating toolbar, manuscript/chapter management, AI integration with knowledge injection and Skill guardian, opening guide, and template library.

The phase delivers: (1) a structured execution plan to create a xianxia world and write the first 30 chapters using MuseFlow, (2) automated scripts that drive the GLM API to generate chapter content, (3) manual spot-check validation of 4 key interaction areas (editor toolbar, knowledge injection + Skill guardian, opening guide 3 styles, chapter operations), (4) a structured issue log capturing bugs, UX friction, and missing needs discovered during the journey.

This phase does NOT add new user-facing features. It does NOT build Claude or Ollama adapters. It does NOT modify the existing editor, knowledge base, or manuscript management code beyond any bug fixes discovered during validation.

**Requirements covered:** JOURNEY-01 through JOURNEY-06 (6 requirements from REQUIREMENTS.md).

</domain>

<decisions>
## Implementation Decisions

### 验证执行方式
- **D-01:** 自动化为主 — 用自动化脚本创建文稿和 30 章骨架，手动抽查关键交互点。Phase 13 的自动化测试基础设施（ProviderContainer + FakeAdapter 模式）可复用，但内容生成改用真实 GLM API 替代 FakeAdapter。
- **D-02:** 真实 GLM API — AI 内容生成使用真实 GLM API（不用 FakeAdapter），用户已有 API Key。这能验证知识库自动注入效果、反AI味输出质量、Skill 守护偏离检测的真实表现。Token 审计（Phase 12）将记录真实消耗数据。
- **D-03:** 串行间隔调用 — 30 章 AI 内容逐章生成，每次调用间隔 2-3 秒避免 GLM API 限流。总计生成时间约 3-5 分钟。
- **D-04:** 遇错即停 — 任何一章 AI 调用失败立即停止整个流程并记录错误信息。不自动重试、不跳过失败章节。用户需排查问题后重新运行。
- **D-05:** 全量手动抽查 — 自动化跑完后，手动验证全部 4 个关键交互区域：编辑器浮窗操作（改写/润色/自由编辑）、知识库注入 + Skill 守护、开篇引导三种风格（场景/人物/悬念）、章节操作（排序/拆分/合并/复制/删除）。
- **D-06:** 结构化问题清单 — 执行过程中发现的问题记录到结构化文档，按分类（功能缺陷 / 体验摩擦 / 缺失需求）和严重程度（高/中/低）排序。为 Phase 16 痛点报告（REPORT-02）做准备。

### 世界观与故事策略
- **D-07:** 修仙模板 + 自定义补充 — 使用 Phase 7 已有的修仙预设模板创建世界观骨架（境界体系、门派设定等），手动补充自定义角色卡和 Skill 守护规则。兼顾效率和个性化。
- **D-08:** 3-4 个角色卡 — 主角（凡人少年）+ 2-3 个配角（师父、师姐/师弟、对手）。足以验证角色卡创建流程、知识库 NameIndex 角色名称识别注入、角色记忆守护的基本功能。
- **D-09:** 4-5 条 Skill 守护规则 — 配置覆盖境界体系约束、门派关系、能力限制、世界观禁忌等方面的 Skill 规则。验证 DeviationDetectionService 在连续 30 章创作中的偏离检测能力。
- **D-10:** 连贯故事线 — 30 章有连贯的修仙成长线（凡人→炼气→筑基）。最能验证知识库在跨章连续创作中的一致性保持、角色设定连续性、以及 Skill 守护的长期有效性。
- **D-11:** 每章 300-500 字 — 总计约 0.9-1.5 万字。超过 ROADMAP 的 "~100字"最低标准，能更有效地验证 AI 生成质量、反AI味效果、以及 Token 审计在真实规模下的表现。

### Claude's Discretion
Planners may choose:
- 修仙故事的具体情节大纲（30 章每章的主题/情节点）
- 角色卡的具体字段内容（名字、性格、背景、能力等）
- Skill 守护规则的具体措辞和触发条件
- 自动化脚本的具体结构（是否复用 Phase 13 的 ProviderContainer 模式、脚本分段策略）
- 结构化问题清单的具体格式和存储位置
- 手动抽查的操作步骤清单（checklist 格式）
- 碎片捕捉验证的灵感碎片内容（子弹笔记模式输入什么碎片）
- 知识库注入验证的断言方式（如何判断角色名/设定是否被正确注入）

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 产品范围
- `.planning/ROADMAP.md` — Phase 14 目标、6 条成功标准（JOURNEY-01~06）、依赖（Phase 12 + 13）、v1.3 里程碑边界。
- `.planning/REQUIREMENTS.md` — JOURNEY-01（修仙模板世界观搭建）、JOURNEY-02（碎片捕捉→AI整理）、JOURNEY-03（开篇引导三种风格）、JOURNEY-04（30章 CRUD/排序/拆分/合并）、JOURNEY-05（逐章 AI 生成 + 知识库注入 + Skill 守护）、JOURNEY-06（编辑器浮窗 + 反AI味）。
- `.planning/PROJECT.md` — 核心产品价值（反AI味）、本地优先约束、技术栈（Flutter/Riverpod/Hive）、v1.3 目标（百章修仙超短篇小说 + token 消耗全程审计）。

### 前期阶段上下文
- `.planning/phases/13-automation-test-harness/13-CONTEXT.md` — FakeAdapter 实现、ProviderContainer override 模式、自动化脚本结构（8 段分段 + 1 E2E）、集成测试 Key 策略。**自动化脚本可复用此基础设施，但需将 FakeAdapter 替换为真实 OpenAIAdapter（配置 GLM baseUrl）。**
- `.planning/phases/12-token-audit-infrastructure/12-CONTEXT.md` — TokenAuditMiddleware 架构、审计数据持久化、操作类型分类（4 组）。**30 章真实 AI 调用将产生审计数据，可验证 Phase 12 的 token 跟踪在规模下的表现。**
- `.planning/phases/11-manuscript-chapter-management/11-CONTEXT.md` — Manuscript/Chapter 数据模型、章节 CRUD/排序/拆分/合并、自动保存机制、AI 上下文注入（相邻章节摘要）。**30 章管理验证基于此架构。**

### 现有代码锚点
- `test/automation/helpers/fake_adapter.dart` — FakeAdapter 实现（Phase 13），参考 AIAdapter 接口但不用于内容生成。真实调用使用 OpenAIAdapter 配置 GLM baseUrl。
- `test/automation/helpers/test_container.dart` — ProviderContainer 工厂（Phase 13），自动化脚本可复用此模式。
- `lib/features/ai/domain/ai_adapter.dart` — AIAdapter 抽象接口，OpenAIAdapter 和 FakeAdapter 都实现此接口。
- `lib/features/ai/infrastructure/openai_adapter.dart` — OpenAI 兼容适配器，支持自定义 baseUrl（用于配置 GLM API endpoint）。真实 AI 调用使用此适配器。
- `lib/features/ai/application/prompt_pipeline.dart` — PromptPipeline 中间件链，包含 AntiAIScentMiddleware、KnowledgeInjectionMiddleware、DeviationDetectionMiddleware、TokenAuditMiddleware。
- `lib/features/knowledge/application/knowledge_injection_middleware.dart` — 知识库自动注入中间件，通过 NameIndex 匹配角色名/设定关键词并注入上下文。
- `lib/features/knowledge/application/deviation_detection_service.dart` — Skill 守护偏离检测服务，检测 AI 生成内容是否偏离 Skill 文档定义的设定。
- `lib/features/knowledge/application/skill_generation_service.dart` — Skill 生成服务，用于创建 Skill 守护文档。
- `lib/features/knowledge/presentation/skill_generation_wizard.dart` — Skill 创建向导 UI，手动配置 Skill 规则的入口。
- `lib/features/knowledge/presentation/world_setting_form.dart` — 世界观设定表单，用于创建/编辑 WorldSetting。
- `lib/features/knowledge/presentation/character_card_form.dart` — 角色卡表单，用于创建/编辑 CharacterCard。
- `lib/features/knowledge/presentation/knowledge_base_page.dart` — 知识库主页，查看所有角色卡、设定集、Skill 文档。
- `lib/features/onboarding/application/opening_generator_service.dart` — 开篇生成服务，支持 3 种风格（场景切入/人物切入/悬念切入）。
- `lib/features/editor/application/editor_ai_notifier.dart` — 编辑器 AI 操作 Notifier，处理浮窗菜单的改写/润色/自由编辑。
- `lib/features/editor/presentation/floating_toolbar.dart` — 浮窗工具栏 Widget，选中文本时弹出。
- `lib/features/manuscript/infrastructure/manuscript_repository.dart` — 文稿持久化，30 章创建基于此 CRUD。
- `lib/features/manuscript/infrastructure/chapter_repository.dart` — 章节持久化，支持排序/拆分/合并。
- `lib/features/capture/` — 碎片捕捉模块，子弹笔记模式输入灵感碎片。
- `lib/features/ai/presentation/synthesis_notifier.dart` — 碎片整理 Notifier，将碎片通过 AI 整理成故事段落。
- `lib/features/templates/` — 预设模板库，包含修仙 preset world-building pack。
- `lib/core/presentation/providers.dart` — 全局 Riverpod provider 注册中心，包括 `openaiAdapterProvider`。
- `lib/stats/infrastructure/token_audit_repository.dart` — Token 审计记录读取，验证 30 章创作的 token 消耗数据。

</canonical_refs>

<code_context>
## Existing Code Insights

### 可复用资产
- **Phase 13 自动化基础设施** — `test/automation/helpers/test_container.dart`（ProviderContainer 工厂）、`test/automation/helpers/fake_adapter.dart`（AIAdapter 接口参考）、`test/automation/core_flow_test.dart`（8 段分段测试模式）。自动化脚本可复用这些模式，但将 FakeAdapter 替换为 OpenAIAdapter 配置 GLM endpoint。
- **PromptPipeline 中间件链** — 已包含 KnowledgeInjectionMiddleware + DeviationDetectionMiddleware + AntiAIScentMiddleware + TokenAuditMiddleware。真实 AI 调用时所有中间件自动工作，可端到端验证。
- **修仙预设模板** — Phase 7 交付的 preset world-building pack，包含修仙世界观骨架。通过 TemplateInstantiationService 创建。
- **TokenAuditService** — Phase 12 审计基础设施，真实 GLM API 调用会被自动记录。
- **知识库 NameIndex** — 角色名称/设定关键词的实时匹配注入机制，已在 Phase 6 交付。
- **Skill 守护系统** — DeviationDetectionService + SkillDocument + SkillActivationToggle，已在 Phase 8 交付。
- **开篇引导服务** — OpeningGeneratorService 支持 3 种风格，已在 Phase 9 交付。
- **hive_test_helper.dart** — 测试环境 Hive 初始化，自动化脚本复用。

### 已建立模式
- Riverpod ProviderContainer + overrides 实现依赖替换（Phase 13 模式）。
- OpenAIAdapter 支持自定义 baseUrl，可用于配置 GLM API（openai_dart 的 OpenAI 兼容端点能力）。
- 实体不可变 + copyWith + Hive TypeAdapter 持久化。
- Clean Architecture 四层分离，自动化测试帮助文件在 `test/automation/helpers/`。
- 30s debatched Hive 写入模式（Phase 9 stats），Token 审计也使用此模式。

### 集成点
- 自动化脚本需配置 GLM API baseUrl + apiKey，通过 `openaiAdapterProvider` override 注入。
- 世界观搭建：修仙模板 → TemplateInstantiationService → WorldSetting + CharacterCard + SkillDocument 创建。
- 章节创建：ManuscriptRepository.create → ChapterRepository.create × 30。
- AI 内容生成：每章通过 SynthesisNotifier 或直接调用 OpenAIAdapter.createStream，PromptPipeline 自动注入知识库 + Skill 守护 + 反AI味 + Token 审计。
- 手动抽查：编辑器浮窗（FloatingToolbar）、知识库注入效果（DeviationWarningWidget）、开篇引导（OpeningGeneratorService）、章节操作（排序/拆分/合并 UI）。
- 问题记录：结构化清单文档，存放在 phase 目录或 `.planning/` 下。

</code_context>

<specifics>
## Specific Ideas

- 自动化脚本基于 Phase 13 的 ProviderContainer 模式，但将 `openaiAdapterProvider.overrideWithValue(FakeAdapter())` 改为真实 OpenAIAdapter 配置 GLM baseUrl + apiKey。
- GLM API 使用 openai_dart 的 OpenAI 兼容端点（`https://open.bigmodel.cn/api/paas/v4` 或用户指定的 endpoint）。
- 30 章串行生成，每次调用间隔 2-3 秒（`await Future.delayed(Duration(seconds: 2))`）。
- 故事线：凡人少年入门→炼气期修行→筑基突破，经典修仙成长线。
- 角色卡：主角 + 师父 + 师姐/师弟 + 对手，验证多角色知识库注入。
- Skill 守护规则示例：主角不能使用火系法术（初期）、世界观不存在枪械、门派等级森严不可逾越、丹药等级限制等。
- 结构化问题清单格式：`{分类, 严重程度, 标题, 复现步骤, 期望行为, 实际行为, 截图/日志}`。
- Token 审计数据在 30 章生成后自动可用，可提前验证 Phase 12 基础设施的准确性。

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 14-World-Building & First 30 Chapters*
*Context gathered: 2026-06-07*
