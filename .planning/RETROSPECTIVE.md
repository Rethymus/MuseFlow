# Retrospective: MuseFlow 灵韵

## Milestone: v1.0 — MVP

**Shipped:** 2026-06-04
**Phases:** 7 | **Plans:** 25
**Codebase:** 31K LOC Dart (18.7K source + 12.3K test)

### What Was Built

1. Editor spike — super_editor validated for CJK IME and 100K+ char documents
2. Full app shell — Windows desktop + Android, sidebar navigation, Hive/secure storage
3. Rich text editor — super_editor with formatting toolbar and large document support
4. AI provider system — OpenAI adapter, 5-stage PromptPipeline middleware chain, anti-AI-scent
5. Fragment capture → synthesis — Bullet-note mode, streaming AI synthesis, editable output
6. Floating AI toolbar — Selection-triggered, 3 actions, provenance tracking, selective undo, context anchors
7. Knowledge base + Skill system — Character cards, world settings, name-index auto-injection, AI world-building, skill enforcement
8. Story structure — Foreshadowing tracking, plot nodes, consistency guardian, logic loop detection
9. Format cleaning + export — Punctuation fixer, Markdown cleaner, typeset beautify, TXT/MD/JSON export
10. Multi-provider + Android — Claude preset, model parameters, responsive layout

### What Worked

- **Phase 0 spike-first approach** — Validating editor/IME/packages before any feature code de-risked the entire project. No late-stage editor migration needed.
- **Clean Architecture layers** — Domain → Application → Infrastructure → Presentation separation held up across 7 phases. No layer violations accumulated.
- **Riverpod + Freezed** — Code-gen based providers and immutable data classes scaled well. No state management regret.
- **TDD on critical paths** — AI adapter, PromptPipeline middleware, and format cleaner all developed test-first. Test-to-code ratio ~0.66 (12K test LOC / 19K source LOC).
- **Wave-based parallel execution** — Plans within phases grouped by dependency waves enabled parallel agent execution without conflicts.

### What Was Inefficient

- **SUMMARY.md quality inconsistency** — Some summaries extracted task-level details instead of milestone-level accomplishments. Auto-extraction from summaries produced poor MILESTONES.md entries that needed manual rewrite.
- **REQUIREMENTS.md checkbox drift** — Requirements were built but checkboxes not updated during execution. Required manual reconciliation at milestone close.
- **Phase 00/01 human testing gap** — Spike and app shell phases require physical Windows device testing (IME, startup speed, 300K document scrolling) that can't be done in WSL. These gaps persisted through the entire milestone.
- **No integration with real AI providers during development** — Tests used fakes/mocks exclusively. No end-to-end validation with actual OpenAI/Claude API calls.

### Patterns Established

- **EditorHolderNotifier pattern** — `Notifier<Editor?>` set in initState/cleared in dispose, works with StatefulShellRoute.indexedStack keeping editor mounted
- **PromptPipeline middleware chain** — 5 stages with const constructors, composable and testable
- **NameIndex entity matching** — In-memory name/alias matcher for auto-injection, deterministic and fast
- **Responsive breakpoint via AppConstants** — Single source of truth for sidebar/list layout switching
- **Wave-based dependency grouping** — Plans grouped into waves by dependency, enabling safe parallel execution

### Key Lessons

1. **Spike before build** — Phase 0 validated existential risks (editor, IME, packages) before committing code. This pattern should be repeated for any high-risk technology choice.
2. **Update tracking in real-time** — REQUIREMENTS.md checkboxes and ROADMAP plan counts should be updated during execution, not batched at milestone close.
3. **Human-testing items need early scheduling** — Physical device testing can't be deferred to the end; schedule it during or immediately after the relevant phase.
4. **Auto-extracted accomplishments need curation** — Raw task-level descriptions from SUMMARY.md don't make good milestone-level accomplishments. Manual curation is necessary.

### Cost Observations

- Model mix: Primarily Sonnet-tier (executor + verifier), some Opus for planning/architecture
- Sessions: ~8 sessions across 4 days
- Notable: Phase 4 (Knowledge Base) was the most complex with 5 plans and cross-cutting entity dependencies

---

## Milestone: v1.1 — 创作体验升级

**Shipped:** 2026-06-05
**Phases:** 4 | **Plans:** 17
**Codebase:** ~40K LOC Dart

### What Was Built

1. 预设世界观模板库 — 14 genre presets, gallery UI, one-click world+character creation, AI completion
2. 开篇引导 — 4-step first-run wizard, AI opening generator (3 styles), interruptible/resumable
3. 写作数据统计 — Global/project dashboards, fl_chart visualizations, achievement badges, debounced collection
4. 故事弧可视化 — graphview interactive graph, styled edges, color-coded nodes, drag persistence, minimap

### What Worked

- **Bundled JSON templates** — No API dependency, templates load instantly from assets, easy to extend
- **fl_chart for analytics** — mature Flutter charting library, LineChart/BarChart/PieChart all worked out of the box
- **graphview for story arc** — saved weeks vs custom Canvas implementation, interactive graph with zoom/pan
- **PageView for onboarding** — built-in Flutter widget, no extra dependency needed
- **Hive box for stats** — lightweight storage, 30s debatched writes, no performance impact on editor

### What Was Inefficient

- **REQUIREMENTS.md checkboxes still not updated during execution** — Same drift issue as v1.0. v1.1 requirements (TMPL, ONBD, STAT) remain unchecked despite being fully implemented.
- **Template prose quality unknown** — Bundled template content written by AI, no human literary review. Quality may not meet publication standards.
- **Phase 9/10 parallel opportunity missed** — Both depended only on v1.0 but were executed sequentially

### Patterns Established

- **Genre enum with WCAG AA colors** — Systematic color mapping for genre cards, accessible contrast ratios
- **First-run detection via Hive** — `appSettings` box key for wizard state, simple and reliable
- **In-memory stats collector with debounced flush** — 30-second batch writes to Hive, editor performance unaffected
- **Graphview semantic styling** — Color by structural role, border by writing status, edge style by relationship type

### Key Lessons

1. **Parallelize independent phases** — Phases 9 and 10 both depended only on v1.0; running them in parallel could have saved ~1 day
2. **Update REQUIREMENTS.md during execution** — Checkbox drift is a recurring problem; need to enforce real-time updates
3. **Template quality needs human eyes early** — Don't wait until release to discover AI-written prose is inadequate

### Cost Observations

- Model mix: Balanced Sonnet/Sonnet execution, Opus for planning
- Sessions: ~4 sessions across 2 days
- Notable: Fastest milestone — 17 plans in 2 days

---

## Milestone: v1.2 — 多文稿架构

**Shipped:** 2026-06-06
**Phases:** 1 | **Plans:** 6
**Codebase:** ~49K LOC Dart (29K source + 20K test)
**Commits:** 76

### What Was Built

1. 文稿+章节领域模型 — Manuscript/Chapter entities, Hive TypeAdapters, Genre color presets, ChapterExport model
2. 完整 CRUD 仓储层 — Soft delete + 30-day purge, 2s debounced auto-save + forced save, chapter sort/split/merge/duplicate
3. 文稿库 UI — Genre-colored card grid, long-press context menu, create/settings dialogs, route wiring
4. 编辑器+章节侧边栏 — ValueKey document switching, lifecycle save, drag-reorder, chapter action dialogs
5. 全链路集成 — Chapter-aware export, template chapter skeleton, AI chapter context middleware, startup purge
6. Gap 闭环 — Force-save before transitions, chapter loading on editor entry, dispose-no-flush

### What Worked

- **TDD with explicit gap-closure wave** — Phase 11-06 dedicated to closing verification gaps (SC-2/SC-3/SC-4). Writing failing tests first, then fixing, ensured gaps were provably closed.
- **ConsumerStatefulWidget for local UI state** — Library page sort state managed locally without extra notifier, keeping provider graph lean
- **ValueKey document switching** — Each chapter document gets a unique key, forcing super_editor to rebuild with correct content on chapter switch
- **Sequential sortOrder recalculation** — On delete/reorder, compact sequential sort orders to prevent gaps and duplicates

### What Was Inefficient

- **super_editor_markdown package discontinued mid-phase** — D-27 decision to switch to built-in serialization caused Plan 04 rework
- **ChapterAutoSave lifecycle complexity** — Multiple iterations to get dispose/forceSave/lifecycle semantics right (WR-04, WR-05, CR-01)
- **5 gap-closure rounds (WR-01 to WR-05)** — Code review found 5 issues requiring fixes, indicating Plan 04's implementation was rushed

### Patterns Established

- **AsyncNotifier two-phase loading** — Repository returns empty initially, notifier loads from Hive asynchronously; UI renders skeleton then populates
- **Debounced auto-save with dirty flag** — Timer-based debounce with explicit dirty→clean state machine, forceSave awaited on transitions
- **WidgetsBindingObserver for lifecycle save** — Best-effort async save on app lifecycle changes (pause/inactive)
- **softDelete + 30-day cascade purge** — Manuscripts soft-deleted, auto-purged on startup after 30 days

### Key Lessons

1. **Check package maintenance status before integrating** — super_editor_markdown was abandoned; early detection would have saved rework
2. **Complex lifecycle interactions need explicit contract tests** — The 5 code-review findings in Phase 11 all involved save/dispose/lifecycle edge cases
3. **Gap-closure waves are effective** — Dedicated plan for closing verification gaps (11-06) with TDD approach was clean and provable
4. **Smaller milestones ship faster** — v1.2 (1 phase, 6 plans, 1 day) had less accumulation and was easier to verify

### Cost Observations

- Model mix: Sonnet for execution, Opus for code review and gap-closure planning
- Sessions: ~3 sessions across 1 day
- Notable: 76 commits in 1 day — high commit velocity due to code review findings and gap-closure iterations

---

## Cross-Milestone Trends

| Metric | v1.0 | v1.1 | v1.2 | Trend |
|--------|------|------|------|-------|
| Phases | 7 | 4 | 1 | Decreasing scope per milestone |
| Plans | 25 | 17 | 6 | Decreasing |
| Timeline (days) | 4 | 2 | 1 | Improving velocity |
| Source LOC | 18.7K | ~25K | 29.4K | Steady growth |
| Test LOC | 12.3K | ~15K | 20.1K | Test ratio improving |
| Commits | 173 | ~50 | 76 | Stable |
| Plans per day | 6.25 | 8.5 | 6 | Stable |

| Pattern | Adoption |
|---------|----------|
| TDD on critical paths | v1.0→v1.2: sustained, gap-closure TDD added in v1.2 |
| Wave-based execution | v1.0→v1.2: all phases use waves |
| REQUIREMENTS.md tracking | Persistent problem — still not updated during execution |
| Human device testing | Still deferred since v1.0 |
| Code review findings | v1.2: 5 findings (highest); gap-closure effective |
