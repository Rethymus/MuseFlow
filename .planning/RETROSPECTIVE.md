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
