# Phase 11: 文稿库与章节管理 - Context

**Gathered:** 2026-06-06
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase transforms MuseFlow from a single-editor tool into a multi-manuscript management platform. It introduces `Manuscript` and `Chapter` domain entities, a manuscript library homepage (replacing the current editor-as-home), a left sidebar for chapter navigation within the editor, per-chapter SuperEditor documents with auto-save, chapter operations (split/merge/duplicate/reorder), and template integration that creates manuscript skeletons with preset chapters.

This phase does not add cloud sync, real-time collaboration, version history, or chapter-level AI operations beyond context injection. Manuscript cover customization is limited to a 2-character overlay on a genre-colored background.

</domain>

<decisions>
## Implementation Decisions

### 数据模型
- **D-01:** Each Chapter owns its own SuperEditor `Document` (serialized as JSON). Switching chapters loads a different Document into the editor. This enables clean separation of undo history and natural per-chapter persistence.
- **D-02:** Manuscript is a container entity that owns multiple Chapters via ordered list. Chapters are ordered by `sortOrder` (integer), not array position.
- **D-03:** Manuscript entity fields: `id`, `title`, `description`, `genre`, `targetWordCount`, `status` (构思中/写作中/已完成), `worldSettingId` (one WorldSetting), `characterCardIds` (many CharacterCards), `createdAt`, `updatedAt`, `deletedAt` (soft delete), `coverLetter` (max 2 chars for card display). All fields immutable with `copyWith`.
- **D-04:** Chapter entity fields: `id`, `manuscriptId`, `title`, `sortOrder`, `status` (草稿/初稿/精修/定稿), `wordCount` (computed, not stored), `documentJson` (SuperEditor Document serialized), `createdAt`, `updatedAt`. Immutable with `copyWith`.
- **D-05:** Chapter status transitions are guided but flexible — UI suggests next logical status (草稿→初稿→精修→定稿) but user can skip or set any status freely.

### 文稿库首页
- **D-06:** Manuscript library replaces the editor as the home screen (Branch 1 in StatefulShellRoute). Bottom nav "编辑器" label stays unchanged — the branch now renders the library page.
- **D-07:** Library layout is a card grid. Each card shows: genre-colored background with customizable cover letter (max 2 chars, default = first char of title), title, word count, target word count with progress bar, last edited time, status badge.
- **D-08:** Library supports multiple sort options: recent edit (default), creation date, title alphabetical. User can switch sort mode.
- **D-09:** Manuscript genres: preset list (reuse Phase 7's 14 novel types as base) + user can add custom genres. Genre list stored in Hive or app settings.
- **D-10:** Empty state: illustrated guide with step-by-step instructions ("创建你的第一部作品"). Empty manuscript (no chapters): illustrated guide with "添加第一个章节" CTA.

### 导航流程
- **D-11:** Two-level navigation: Library → tap manuscript card → enter Editor (full screen, bottom nav hidden) → AppBar back button returns to Library. No deep-linking between manuscripts within editor.
- **D-12:** Bottom navigation keeps all 6 items (Capture / Editor / Knowledge / Structure / Stats / Settings). When inside a manuscript's editor, the bottom nav is hidden and replaced with a back-to-library AppBar.

### 章节侧栏
- **D-13:** Left sidebar panel is always visible within the editor (not collapsible). Fixed width ~240-280px. Contains: manuscript title header, chapter list, "new chapter" button.
- **D-14:** Each chapter row in sidebar displays: title + right-aligned word count. Currently active chapter is visually highlighted (e.g., primary color background).
- **D-15:** Chapter reordering via drag & drop in sidebar. After drop, `sortOrder` values are recalculated. Use a drag-and-drop package or custom ReorderableListView.

### 章节操作
- **D-16:** Chapter operations: create (inline in sidebar), delete (with confirmation), rename (inline in sidebar), reorder (drag & drop), split (at cursor position into two chapters), merge (adjacent chapters into one), duplicate (clone content as new chapter).

### 文稿创建与元数据
- **D-17:** Two creation flows: (1) Quick create — dialog with title + genre selection, creates manuscript with one empty chapter. (2) Detailed create — full page with title, genre, description, target word count, linked WorldSetting/CharacterCard selection.
- **D-18:** Manuscript metadata editing via dedicated settings page (not inline dialog). Accessible from AppBar within the editor or from library card long-press menu.

### 自动保存与持久化
- **D-19:** Chapter content auto-saves with dual guarantee: (1) Debounced save (2-3 seconds after last edit) + (2) Forced save on chapter switch, back-to-library navigation, and app lifecycle pause. Uses the same 30s debatched Hive write pattern established in Phase 9 stats collection.

### 模板集成
- **D-20:** Template integration: when creating a manuscript from a template (Phase 7 genre templates), the system auto-creates: linked WorldSetting + CharacterCards (via existing TemplateInstantiationService) + preset chapter skeleton (e.g., 3 chapters with genre-appropriate titles). User can edit or remove any created entity.

### 删除策略
- **D-21:** Soft delete for manuscripts: `deletedAt` timestamp set on delete. Manuscripts with `deletedAt != null` are hidden from library but recoverable for 30 days. Auto-purge job (on app launch) permanently deletes manuscripts older than 30 days. Chapter content is deleted along with manuscript. Linked WorldSetting/CharacterCard entities are preserved (not deleted).
- **D-22:** Chapter deletion: immediate hard delete with confirmation dialog. Chapter content (Document JSON) is permanently removed. Adjacent chapters' sortOrder values are recalculated.

### 导出
- **D-23:** Export supports flexible selection: whole manuscript (all chapters concatenated or structured JSON) or user-selected chapters (multi-select). ExportBundle is updated to include chapter-level structure: `chapters: [{title, sortOrder, content}]` instead of flat `manuscriptText`.

### AI 上下文
- **D-24:** AI operations in the editor inject adjacent chapter summaries as context: previous chapter summary + current chapter full text + next chapter summary. Summaries are auto-generated from chapter content (first N characters or AI-generated). This extends the existing EditorPromptPipeline.

### 目标字数进度
- **D-25:** Manuscript word count progress is visualized as a progress bar in two places: (1) Library card (current total word count / target word count), (2) Editor status bar (per-manuscript progress). Total word count is aggregated from all chapter word counts in real-time.

### 键盘快捷键
- **D-26:** Chapter navigation keyboard shortcuts (e.g., Ctrl+Up/Down for prev/next chapter, Ctrl+Shift+N for new chapter). Shortcuts are customizable — user can modify or disable them in settings.

### Claude's Discretion
Planners may choose implementation details for:
- SuperEditor Document JSON serialization format (use SuperEditor's built-in `Document.fromJson`/`toJson`)
- Drag & drop package selection (e.g., `reorderable_grid_view` or custom `Draggable`/`DragTarget`)
- Genre color palette mapping (assign colors to the 14 preset genres)
- Soft delete auto-purge trigger mechanism (app startup vs periodic timer)
- Adjacent chapter summary generation (truncation vs AI-generated)
- Keyboard shortcut customization storage format (Hive settings box)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 产品范围
- `.planning/ROADMAP.md` — Phase 11 目标（多文稿 CRUD、章节实体与导航、编辑器章节级切换、数据迁移、模板策略修订）、成功标准、v1.2 里程碑边界。
- `.planning/REQUIREMENTS.md` — 现有需求定义（TMPL 系列模板需求将受模板整合影响）、Out of Scope 约束。
- `.planning/PROJECT.md` — 核心产品价值（反AI味）、本地优先约束、技术栈（Flutter/Riverpod/Hive）。

### 现有代码锚点
- `lib/features/editor/presentation/editor_page.dart` — 当前单一 SuperEditor 实例，需要改造为支持 Document 切换和侧栏布局。
- `lib/core/presentation/providers.dart` — 全局 Riverpod provider 注册中心，新增 Manuscript/Chapter providers 将在此注册。
- `lib/features/story_structure/domain/export_bundle.dart` — ExportBundle 需要改造为章节感知结构（当前为 flat `manuscriptText`）。
- `lib/core/domain/fragment.dart` — 现有 Fragment 实体模式参考（immutable, copyWith, toJson/fromJson）。
- `lib/core/domain/fragment_tag.dart` — FragmentTags.chapter 已存在，可作为 Chapter 命名参考。
- `lib/features/editor/presentation/editor_provider.dart` — 编辑器 AI 状态管理，需要扩展为章节感知。
- `lib/features/editor/application/editor_prompt_pipeline.dart` — AI 提示管道，需要扩展支持相邻章节摘要注入。
- `lib/app.dart` — 路由配置（StatefulShellRoute），需要修改 Branch 1 为文稿库→编辑器两级导航。
- `lib/main.dart` — Hive 初始化和 TypeAdapter 注册，新增 ManuscriptAdapter/ChapterAdapter。
- `lib/features/templates/infrastructure/world_template_repository.dart` — Phase 7 模板数据源，文稿创建流程需整合。
- `lib/features/templates/application/template_instantiation_service.dart` — 模板实例化服务，需扩展支持章节骨架创建。

### 技术参考
- `lib/features/stats/application/writing_stats_collector.dart` — 30s debatched Hive write 模式，章节自动保存可复用此模式。
- `lib/features/story_structure/infrastructure/node_position_repository.dart` — 位置数据与实体分离存储的模式参考。

</canonical_refs>

<code_context>
## Existing Code Insights

### 可复用资产
- `SuperEditor` + `Editor` 实例已在 `EditorPage` 中运行，支持 `Document` 的 `fromJson`/`toJson` 序列化。章节切换只需替换 editor 的 document。
- `EditorHolderNotifier` 暴露当前 Editor 实例供跨组件访问（如 synthesis 文本插入），章节切换时需要更新此引用。
- `ExportService` 和 `ExportBundle` 已建立导出管道，需要扩展为章节感知的导出格式。
- `TemplateInstantiationService` 已支持 WorldSetting + CharacterCard 创建，需要扩展为同时创建章节骨架。
- `FragmentTags.chapter = '章节'` 已定义章节标签常量。

### 已建立模式
- 实体不可变，使用 `copyWith` / `toJson` / `fromJson`，构造函数验证，Hive TypeAdapter 持久化。
- Riverpod AsyncNotifier 模式管理异步 CRUD 状态。
- Hive box 按实体类型分开（`fragments`, `character_cards`, `world_settings` 等），Manuscript 和 Chapter 应使用独立的 Hive box。
- 30s debatched 写入模式（Phase 9 stats），可复用于章节自动保存。
- Clean Architecture 四层分离（domain → application → infrastructure → presentation）。
- `StatefulShellRoute.indexedStack` 保持分支状态，但编辑器内导航需要使用 `GoRouter` 子路由而非新的 shell branch。

### 集成点
- 新增 `lib/features/manuscript/` 功能模块，遵循四层架构。
- Manuscript/Chapter providers 注册在 `lib/core/presentation/providers.dart`。
- 新增 Hive TypeAdapter 注册在 `lib/main.dart`。
- Branch 1 路由修改：library page（默认）→ editor page（子路由，传入 manuscriptId）。
- ExportBundle 改造：`manuscriptText` → `chapters: [{title, content}]` 结构。
- EditorPromptPipeline 扩展：注入相邻章节摘要。
- WritingStatsCollector 扩展：按章节采集字数数据。

</code_context>

<specifics>
## Specific Ideas

- 文稿库卡片封面：类型色背景 + 标题首字叠加（max 2 chars，用户可自定义）。
- 侧栏章节行：标题 + 右对齐字数，当前章节高亮。
- 章节状态：草稿→初稿→精修→定稿，引导式但允许跳过。
- 空状态设计：插图 + 步骤引导（类似 Phase 10 故事弧可视化的空状态风格）。
- 导航流：Library → 点击卡片 → 编辑器（底部导航隐藏）→ AppBar 返回 Library。
- 键盘快捷键：Ctrl+Up/Down 切换章节，Ctrl+Shift+N 新建章节，可自定义/禁用。
- 进度条显示位置：文稿库卡片 + 编辑器状态栏两处。

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 11-文稿库与章节管理*
*Context gathered: 2026-06-06*
