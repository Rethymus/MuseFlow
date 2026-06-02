# Phase 3: Editor AI Toolbar - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can select text in the editor and get AI-powered actions via a floating toolbar: tone rewrite (语气改写), paragraph polish (文段润色), free-form edit (自由输入). AI modifications are shown as sentence-level inline diffs with accept/reject per sentence. Modified text is visually distinguished from human-written text via provenance tracking. Users can selectively undo AI modifications. Users can select previous paragraphs as reference context for AI operations.

**In scope:**
- Floating toolbar on text selection with three AI actions
- Inline diff display with sentence-level granularity and per-sentence accept/reject
- Text provenance tracking (Attribution-based blue highlight on AI-modified text)
- Selective undo for AI modifications (separate from document undo)
- Context anchor system (persistent + one-time reference paragraphs)
- PromptPipeline extension for editor AI operations (tone/polish/free-input prompts)
- Diff state management (leave-page warning for unresolved diffs)

**Out of scope:**
- Knowledge base auto-injection (Phase 4)
- Story structure tools (Phase 5)
- Claude API adapter (Phase 6)
- Per-provider model parameters (Phase 6)
- Format cleaning and export (Phase 5)

</domain>

<decisions>
## Implementation Decisions

### AI结果呈现方式（内联Diff）
- **D-01:** AI修改结果以句子级内联Diff展示在编辑器原文位置。删除的内容标红，新增的内容标绿。不是直接替换，也不是侧边预览——所见即所得但逐句可控。
- **D-02:** Diff粒度为句子级。小说改写以句子为最自然单位，每个句子独立高亮、独立接受/拒绝。词级太碎，段落级太粗。
- **D-03:** 接受/拒绝交互：选中高亮句子时浮现操作栏（类似浏览器选文弹出），显示「接受」「拒绝」按钮。不选中时只显示颜色差异，不遮挡文本。
- **D-04:** 未处理的Diff在用户切换页面或关闭文档时弹窗提醒「有 N 处未确认的AI修改」，要求用户处理后再离开。防止遗忘未处理的改动。

### 浮窗菜单交互
- **D-05:** 三个AI操作横排排列：「语气改写」「文段润色」「自由输入」。紧凑按钮式布局，类似浏览器选文弹出工具栏。
- **D-06:** 「自由输入」点击后在浮窗下方展开内嵌文本输入框。用户输入指令（如「改成第一人称」），回车触发AI。不离开选区上下文，不弹独立对话框。
- **D-07:** AI处理中，浮窗变为进度条+取消按钮。不遮挡编辑器其他区域。完成后进度条消失，Diff高亮出现。
- **D-08:** 浮窗紧贴选区下方，智能翻转——选区在屏幕顶部时浮窗出现在下方，选区在底部时浮窗出现在上方。

### 文本来源追踪（Provenance）
- **D-09:** AI修改的文字使用super_editor的Attribution系统加淡蓝半透明底色（`Colors.blue.withValues(alpha: 0.1)`）。在深色主题下不刺眼，和选中高亮区分开。
- **D-10:** Provenance标记在用户接受Diff后自动移除。最终文档中不含任何AI标记。不需要手动清除，不需要保留元数据。
- **D-11:** 编辑器状态栏显示「当前文档有 N 处AI修改待确认」。帮助作者追踪工作进度。

### 上下文锚点（Context Anchor）
- **D-12:** 混合模式：支持「持久锚点」和「一次性参考」两种。持久锚点持续生效直到手动移除；一次性参考在AI操作完成后自动清除。
- **D-13:** 锚点入口集成在浮窗菜单中——选中文字后浮窗增加「📌 设为上下文」按钮，点击后弹出选择：「持久锚点」或「本次参考」。
- **D-14:** 锚点段落在编辑器中用淡金色底色标记，段落左侧显示📌图标。持久锚点和一次性锚点用底色强度区分（持久更深，一次性更浅）。
- **D-15:** 锚点内容自动注入PromptPipeline的系统消息中，作为「参考上下文」section。用户无需手动操作，AI自动参考所有活跃锚点。

### AI操作Prompt设计
- **D-16:** 三个操作复用PromptPipeline架构，但使用不同的system prompt模板：
  - 语气改写：指令为调整叙事语气/风格，保持原文意思不变
  - 文段润色：指令为提升文字质量、增加文学性，可适度扩展
  - 自由输入：用户自定义指令，从浮窗内嵌输入框获取
- **D-17:** 每次AI操作的上下文包含：系统提示 + 反AI味persona + 禁用词列表 + 锚点上下文 + 选中文字 + 用户指令（自由输入时）。复用Phase 2的PromptPipeline + AntiAIScentProcessor。

### Claude's Discretion
- Diff高亮的具体颜色值和动画细节（红/绿的具体色值、过渡动画时长）
- 浮窗菜单的精确尺寸、圆角、阴影（Material 3风格一致即可）
- 句子分割算法的实现（中文句号、问号、感叹号、省略号作为句子边界）
- AI操作的streaming显示方式（是逐token显示还是等句子完成再显示）
- Provenance Attribution的具体命名和数据结构
- 锚点注入系统消息的具体格式和位置
- 浮窗智能翻转的触发阈值和动画
- 选中时浮现操作栏的精确位置和样式

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Definition
- `.planning/PROJECT.md` — Project vision, core value (反AI味是产品灵魂), constraints, key decisions
- `.planning/REQUIREMENTS.md` — Full v1 requirements; Phase 3 covers EDIT-02, EDIT-03, EDIT-05, EDIT-06, EDIT-07
- `.planning/ROADMAP.md` §Phase 3 — Success criteria (5 items), risks (floating toolbar positioning, selective undo complexity), plan list (03-01 to 03-03)
- `.planning/STATE.md` — Current project position (Phase 3, ready to plan)

### Architecture & Standards
- `CLAUDE.md` §Technology Stack — super_editor (editor), openai_dart (AI), Riverpod (state), Hive (storage)
- `CLAUDE.md` §Architecture — Four-layer architecture, AI adapter unified interface, PromptPipeline middleware design
- `.claude/rules/02-museflow-architecture.md` — Layer responsibilities, dependency direction constraints
- `.claude/rules/03-flutter-standards.md` — Immutability, Widget rules, Riverpod patterns, error handling

### Prior Phase Context
- `.planning/phases/00-technical-validation/00-CONTEXT.md` — Phase 0 decisions (editor selection, IME validation, streaming validation)
- `.planning/phases/01-app-shell-editor-capture-ui/01-CONTEXT.md` — Phase 1 decisions (sidebar nav, editor toolbar, capture UI)
- `.planning/phases/02-ai-provider-capture-synthesis/02-CONTEXT.md` — Phase 2 decisions (PromptPipeline, anti-AI-scent, synthesis flow)

### Existing Code (关键文件)
- `lib/features/editor/presentation/editor_page.dart` — EditorPage with EditorHolderNotifier, super_editor setup, keyboard shortcuts
- `lib/features/editor/presentation/editor_toolbar.dart` — Fixed formatting toolbar pattern (Bold/Italic/Heading/List)
- `lib/features/editor/presentation/editor_provider.dart` — `createDefaultEditor()` factory, Editor instance lifecycle
- `lib/features/ai/application/prompt_pipeline.dart` — PromptPipeline + PromptMiddleware + PromptContext (extensible middleware chain)
- `lib/features/ai/infrastructure/openai_adapter.dart` — OpenAIAdapter with streaming, error classification, client caching
- `lib/features/ai/application/anti_ai_scent_processor.dart` — Anti-AI-scent post-processing
- `lib/features/ai/presentation/synthesis_notifier.dart` — SynthesisNotifier pattern (streaming state management with Riverpod)
- `lib/features/ai/application/prompt_middlewares/` — SystemPromptMiddleware, PersonaInjectionMiddleware, BannedListMiddleware, UserContentMiddleware

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **PromptPipeline**: 完整的中间件链架构，可直接扩展新的editor-specific middleware（如ContextAnchorMiddleware）
- **OpenAIAdapter**: 流式API调用+错误分类，editor AI操作直接复用
- **AntiAIScentProcessor**: 反AI味后处理，editor AI操作的结果也应经过此处理器
- **BannedPhrasesNotifier**: 用户自定义禁用词列表，editor操作共享同一份配置
- **EditorHolderNotifier**: 跨widget暴露Editor实例，浮窗菜单需要访问editor来获取选区和执行替换
- **SynthesisNotifier模式**: Riverpod AsyncNotifier管理流式AI状态，editor AI操作可复用相同模式

### Established Patterns
- **Immutable entities with copyWith**: 所有domain对象不可变，Diff状态和锚点数据也应遵循
- **Riverpod AsyncNotifier**: 异步状态管理的标准模式
- **Hive TypeAdapters**: 持久化需要注册adapter（如锚点数据如果需要持久化）
- **Material 3 dark theme with indigo seed**: 浮窗菜单和Diff高亮需要适配此主题
- **Four-layer architecture**: 新代码遵循 domain → application → infrastructure → presentation

### Integration Points
- **EditorPage._editor**: 浮窗菜单需要读取editor的selection和document来获取选中文本
- **EditorToolbar**: 浮窗菜单和固定工具栏共存——选中文字时浮窗出现，固定工具栏始终在顶部
- **PromptPipeline.withDefaultMiddlewares()**: 扩展为支持editor-specific prompt模板
- **OpenAIAdapter.createStream()**: editor AI操作直接调用此方法
- **GoRouter**: 可能需要添加editor相关的路由守卫（未确认Diff离开提醒）
- **lib/features/editor/domain/**: 目前为空，Diff状态和锚点实体定义在这里
- **lib/features/editor/application/**: 目前为空，editor AI用例（ToneRewriteUseCase等）定义在这里

</code_context>

<specifics>
## Specific Ideas

- Diff体验应该像代码review工具（GitHub PR review）——逐句审阅，接受/拒绝清晰明确
- 浮窗菜单的交互应该像浏览器选文弹出——自然、不突兀、紧贴选区
- 上下文锚点是"持续参考"能力——作者写第三章时可以一直参考第一章的伏笔设定
- 反AI味是产品灵魂——editor AI操作必须经过AntiAIScentProcessor，和合成流程同等对待

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 3-Editor AI Toolbar*
*Context gathered: 2026-06-02*
