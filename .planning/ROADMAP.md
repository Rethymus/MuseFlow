# Roadmap: MuseFlow 灵韵

## Milestones

- ✅ **v1.0 MVP** — Phases 0–6 (shipped 2026-06-04)
- ✅ **v1.1 创作体验升级** — Phases 7–10 (shipped 2026-06-05)
- 🚧 **v1.2 多文稿架构** — Phase 11 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 0–6) — SHIPPED 2026-06-04</summary>

- [x] Phase 0: Technical Validation (3/3 plans) — completed 2026-06-01
- [x] Phase 1: App Shell + Editor + Capture UI (4/4 plans) — completed 2026-06-01
- [x] Phase 2: AI Provider + Capture Synthesis (3/3 plans) — completed 2026-06-02
- [x] Phase 3: Editor AI Toolbar (3/3 plans) — completed 2026-06-02
- [x] Phase 4: Knowledge Base + Skill System (5/5 plans) — completed 2026-06-04
- [x] Phase 5: Story Structure + Format + Export (4/4 plans) — completed 2026-06-04
- [x] Phase 6: Multi-Provider + Android Polish (3/3 plans) — completed 2026-06-04

</details>

### 🚧 v1.1 创作体验升级 (Shipped)

**Milestone Goal:** 在 v1.0 核心流程基础上，增加模板库降低冷启动门槛、引导流程让新用户快速上手、数据统计量化创作过程、故事弧可视化增强创作感知。

- [x] **Phase 7: 预设世界观模板库** — 14种小说类型模板，一键创建世界设定+角色原型，AI补全空白字段
- [x] **Phase 8: 开篇引导** — 首次启动4步向导，AI开篇生成器（3种风格），引导可中断恢复
- [x] **Phase 9: 写作数据统计** — 全球/项目数据面板，fl_chart图表，成就徽章，性能无感采集
- [x] **Phase 10: 故事弧可视化** — graphview交互式节点图，缩放平移，拖拽排列，缩略图导航

### 📋 v1.2 多文稿架构 (Planning)

**Milestone Goal:** 将 MuseFlow 从"单一编辑器"升级为"多文稿管理平台"，支持章节级编辑和多线程并行创作。

- [x] **Phase 11: 文稿库与章节管理** — 多文稿 CRUD、章节实体与导航、编辑器章节级切换、数据迁移、模板策略修订 (completed 2026-06-06)

## Phase Details

### Phase 7: 预设世界观模板库

**Goal**: 用户可以通过类型画廊快速选择世界观模板，一键创建完整的知识库实体，大幅降低新项目的冷启动门槛
**Depends on**: Phase 6 (v1.0 shipped — knowledge base domain entities exist)
**Requirements**: TMPL-01, TMPL-02, TMPL-03, TMPL-04, TMPL-05, TMPL-06
**Success Criteria** (what must be TRUE):

  1. User can browse a genre gallery showing 14 novel types (8 male-frequency + 6 female-frequency), each with icon, name, and brief description
  2. User can tap "Use Template" and get editable WorldSetting + CharacterCard prototype entities created in the knowledge base (not locked)
  3. User can preview template contents (world skeleton, character prototypes, foreshadowing patterns) before committing to creation
  4. AI fills in blank template fields based on user's story concept input, producing a customized starting point
  5. Each genre template includes 3 opening sample paragraphs and genre-specific foreshadowing arcs (e.g., xianxia: hidden bloodline → awakening → tribulation)

**Plans**: 3 executable plans created 2026-06-04

Plans:

- [x] 07-01: Template data model and bundled JSON assets
- [x] 07-02: Genre gallery UI with filtering and preview
- [x] 07-03: Template instantiation (WorldSetting + CharacterCard creation) and AI completion

### Phase 8: 开篇引导

**Goal**: 新用户首次启动时通过4步向导快速体验完整创作流程，老用户可随时在编辑器中使用AI开篇生成器
**Depends on**: Phase 7 (reuses TemplateRepository for wizard's genre selection step)
**Requirements**: ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05, ONBD-06
**Success Criteria** (what must be TRUE):

  1. On fresh install, app automatically detects first-run state (via Hive appSettings key) and launches the onboarding wizard
  2. User completes a 4-step flow (pick genre → create world → create character → AI opening), and each step delivers tangible value (not just explanation screens)
  3. User can skip any step or exit the wizard entirely, and partial progress is persisted so they can resume later
  4. AI opening generator is accessible outside the wizard (from editor), generating 3 distinct opening styles (scene-led, character-led, suspense-led)
  5. User can select one of the 3 generated openings and insert it directly into the editor for refinement

**Plans**: 5 executable plans created 2026-06-04
**UI hint**: yes

Plans:
**Wave 1**

- [x] 08-01: First-run detection and progress persistence (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 08-02: Wizard host + genre step (wave 2, depends on 08-01)
- [x] 08-03: World + character steps + entity creation (wave 2, depends on 08-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 08-04: OpeningVariant model + OpeningGeneratorService (wave 3, depends on 08-01)
- [x] 08-05: OpeningStepPage + OpeningGeneratorSheet + toolbar button + wizard wiring (wave 3, depends on 08-01, 08-02, 08-03, 08-04)

### Phase 9: 写作数据统计

**Goal**: 用户可以通过全球面板和项目面板查看量化创作数据（字数、速度、AI使用率），并获得里程碑成就徽章激励
**Depends on**: Phase 6 (v1.0 shipped — editor and AI pipeline exist for data collection)
**Requirements**: STAT-01, STAT-02, STAT-03, STAT-04, STAT-05, STAT-06
**Success Criteria** (what must be TRUE):

  1. After an editing session, the global stats page shows accurate total word count, writing days, AI assist ratio, and session count
  2. Charts render correctly — line chart for speed trend, bar chart for daily words, pie chart for AI usage ratio (via fl_chart)
  3. Editing performance is unaffected by stats collection (in-memory counters with 30-second debatched Hive writes)
  4. Achievement badges appear when milestones are reached (first 1K/10K/50K words, 7/30/100 consecutive writing days)
  5. User can clear all writing statistics from the settings page

**Plans**: 5 plans (4 executable + 1 gap closure) created 2026-06-04/05
**UI hint**: yes

Plans:

**Wave 1**

- [x] 09-01: Stats data model, Hive storage, and in-memory collector service (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 09-02: Global and project stats pages with fl_chart visualizations (wave 2, depends on 09-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 09-03: Achievement badge system and settings clear action (wave 3, depends on 09-01, 09-02)

**Gap Closure** *(from VERIFICATION.md)*

- [x] 09-04: Fix navigation destination count assertions (5 → 6) in test/app/ tests
- [x] 09-05: Fix navigation test router structure (add stats branch, update settings assertion)

### Phase 10: 故事弧可视化

**Goal**: 用户可以看到基于现有PlotNode数据的交互式故事弧节点图，通过视觉方式理解和管理剧情结构
**Depends on**: Phase 6 (v1.0 shipped — PlotNode domain entity exists)
**Requirements**: VIZO-01, VIZO-02, VIZO-03, VIZO-04, VIZO-05, VIZO-06
**Success Criteria** (what must be TRUE):

  1. An interactive graph renders from existing PlotNode data using graphview, with smooth zoom and pan via InteractiveViewer
  2. Edges visually distinguish relationship types — directed solid lines for causation, thin gray lines for association, dashed lines for foreshadowing
  3. Nodes are color-coded by structural role (setup/development/turning point/climax/resolution) and bordered by writing status
  4. User can tap a node to inline-edit its title, structural role, and writing status without leaving the graph view
  5. User can drag nodes to rearrange positions, with position changes persisted to storage; a minimap widget helps navigate large graphs

**Plans**: 3 executable plans created 2026-06-05
**UI hint**: yes

Plans:

**Wave 1**

- [x] 10-01: NodePosition data layer, graphview install, and semantic color utilities (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 10-02: Interactive graph UI with styled nodes/edges, inline editing, and tab integration (wave 2, depends on 10-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 10-03: Node drag with position persistence and minimap overlay (wave 3, depends on 10-01, 10-02)

### Phase 11: 文稿库与章节管理

**Goal**: 将 MuseFlow 从单一编辑器升级为多文稿管理平台，支持文稿 CRUD、章节实体与导航、编辑器章节级切换、数据迁移和模板策略修订
**Depends on**: Phase 10 (v1.1 shipped — editor and knowledge base domain entities exist)
**Success Criteria** (what must be TRUE):

  1. User can create, view, edit, soft-delete manuscripts from a library homepage (card grid with genre-colored covers)
  2. User can create, rename, reorder (drag & drop), split, merge, duplicate, and delete chapters within a manuscript
  3. Editor switches chapter documents when user selects a different chapter in the left sidebar
  4. Chapter content auto-saves with debounced + forced-save guarantees (on chapter switch, navigation, app lifecycle)
  5. Manuscript creation from template auto-creates WorldSetting + CharacterCards + chapter skeleton
  6. Export supports chapter-aware structure (per-chapter content, not flat manuscriptText)

**Plans**: 5 executable plans created 2026-06-06

Plans:
**Wave 1** *(foundation)*

- [x] 11-01: Domain entities (Manuscript, Chapter, Genre, ChapterExport) + Hive TypeAdapters + super_editor_markdown install (wave 1)

**Wave 2** *(services)*

- [x] 11-02: Repositories, notifiers, auto-save service, purge service, sort utility, provider registration (wave 2, depends on 11-01)

**Wave 3** *(library UI + routing)*

- [x] 11-03: ManuscriptLibraryPage, ManuscriptCard, ManuscriptCreateDialog, ManuscriptSettingsPage, route wiring (wave 3, depends on 11-02)

**Wave 4** *(editor + sidebar)*

- [x] 11-04: EditorWithSidebar, ChapterSidebar, chapter dialogs, document switching, auto-save integration (wave 4, depends on 11-02, 11-03)

**Wave 5** *(integration)*

- [x] 11-05: ExportBundle chapters, template chapter skeleton, AI chapter context, StatusBar progress, purge startup (wave 5, depends on 11-04)

## Progress

**Execution Order:**
Phases execute in numeric order: 7 → 8 → 9 → 10 → 11
Note: Phases 9 and 10 are independent of each other (both depend only on v1.0). They can run in parallel if desired.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 0. Technical Validation | v1.0 | 3/3 | Complete | 2026-06-01 |
| 1. App Shell + Editor + Capture | v1.0 | 4/4 | Complete | 2026-06-01 |
| 2. AI Provider + Synthesis | v1.0 | 3/3 | Complete | 2026-06-02 |
| 3. Editor AI Toolbar | v1.0 | 3/3 | Complete | 2026-06-02 |
| 4. Knowledge Base + Skills | v1.0 | 5/5 | Complete | 2026-06-04 |
| 5. Story Structure + Export | v1.0 | 4/4 | Complete | 2026-06-04 |
| 6. Multi-Provider + Android | v1.0 | 3/3 | Complete | 2026-06-04 |
| 7. 预设世界观模板库 | v1.1 | 3/3 | Implemented; manual template prose review pending | 2026-06-04 |
| 8. 开篇引导 | v1.1 | 5/5 | Complete | 2026-06-04 |
| 9. 写作数据统计 | v1.1 | 5/5 | Complete   | 2026-06-05 |
| 10. 故事弧可视化 | v1.1 | 4/4 | Complete    | 2026-06-05 |
| 11. 文稿库与章节管理 | v1.2 | 5/5 | Complete   | 2026-06-06 |
