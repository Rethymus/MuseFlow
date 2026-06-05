# Phase 9 Research — 写作数据统计

## Scope

Phase 9 adds local-only writing analytics: global totals, current-document/project detail, charts, achievement badges, and a settings clear action. It must not make editor typing feel slower.

## Current Code Facts

| Area | Finding | Implication |
|------|---------|-------------|
| Editor | `lib/features/editor/presentation/editor_page.dart` owns a `super_editor` `Editor` and exposes it through `editorProvider`. | Stats collection should observe editor/document changes from presentation/application code, not replace editor internals. |
| AI insertion | `SynthesisNotifier.confirmAndInsert()` inserts AI text with `InsertPlainTextAtCaretRequest`. Opening insertion uses dedicated helper files from Phase 8. | AI-assisted word counts can be tracked at AI operation boundaries rather than by parsing provenance in every keystroke. |
| Storage | `lib/core/presentation/providers.dart` opens Hive boxes through `FutureProvider`s and repositories. | Add `writing_stats` and `daily_writing_stats` boxes through the same provider style. |
| Settings | `lib/features/settings/presentation/settings_page.dart` is a simple `ConsumerWidget` with storage/about sections. | Add a clear-stats tile/dialog here in Plan 09-03. |
| Routing | `AppConstants` has routes for editor, capture, settings, knowledge, story structure, onboarding. | Add a stats route constant and route entry; use existing app shell navigation pattern. |
| Charts | `pubspec.yaml` does not include `fl_chart` yet. | Plan 09-02 must add `fl_chart` dependency and chart widgets. |
| Project model | No manuscript/project/chapter domain exists yet in `lib/features`. | Use `projectId`/`documentId` as nullable/defaulted fields; per-project panel means current editor document scope for v1.1. |

## Recommended Architecture

Create a new feature package: `lib/features/stats/`.

| Layer | Files | Purpose |
|-------|-------|---------|
| domain | `writing_session.dart`, `daily_writing_stats.dart`, `achievement_badge.dart`, `stats_snapshot.dart` | Immutable data models and deterministic calculations. |
| infrastructure | `writing_stats_repository.dart` | Hive-backed persistence and clear-all operation. |
| application | `writing_stats_collector.dart`, `writing_stats_notifier.dart`, `achievement_service.dart` | Debounced collection, derived dashboard state, badge unlock logic. |
| presentation | `writing_stats_page.dart`, `project_stats_page.dart`, `stats_summary_card.dart`, chart widgets, badge widgets | UI surfaces. |

## Collection Strategy

Use low-overhead in-memory counters:

1. Capture a baseline plain-text length when the editor page initializes.
2. Listen to document changes or schedule lightweight snapshots from the editor lifecycle.
3. Compute word/character delta from plain text, not from rich attribution traversal per keystroke.
4. Accumulate deltas in `WritingStatsCollector` memory.
5. Flush to Hive on a 30-second debounce and when editor page disposes/app lifecycle pauses.

For Chinese writing, count CJK characters plus non-CJK word tokens. Name the metric `wordCount` in UI because requirements say 字数, but implement helper as deterministic `countWritingUnits(String text)`.

## AI Assist Ratio

Track AI usage at operation boundaries:

| Source | Event |
|--------|-------|
| `SynthesisNotifier.confirmAndInsert()` | Record inserted AI text length and one AI insertion count. |
| Phase 8 opening insertion helper | Record generated opening text length and one AI insertion count. |
| Future editor AI operations | Reuse collector API: `recordAiInsertion(text)`. |

Compute ratio as `aiInsertedUnits / max(totalWrittenUnits, 1)`, clamped to `0..1`.

## Hive Shape

Use simple `Map<String, dynamic>` serialization instead of generated adapters unless existing code requires typed adapters. Existing repositories mostly store dynamic boxes for feature data.

Suggested boxes:

| Box | Key | Value |
|-----|-----|-------|
| `writing_stats` | `global` | aggregate map for total words, AI words, sessions, first/last dates |
| `writing_stats` | `project:<id>` | aggregate map for current/future project scope |
| `daily_writing_stats` | `yyyy-mm-dd` | daily words, AI words, session count, minutes |
| `achievement_badges` | badge id | unlocked timestamp + current progress |

## Chart Requirements

Use `fl_chart`:

| Requirement | Widget |
|-------------|--------|
| speed trend | `LineChart` over last 14/30 writing days words-per-minute or words-per-session |
| daily words | `BarChart` over last 14/30 calendar days |
| AI usage ratio | `PieChart` AI vs human units |

Charts should render empty states when no data exists. Do not crash on zero totals.

## Risks

| Risk | Mitigation |
|------|------------|
| Editor jank from text traversal | Debounce snapshots; keep synchronous work small; only flush every 30s. |
| Inflated counts from document reload or AI insertion | Track deltas from previous snapshot and separate AI insertion events. Clamp negative deltas to revision events, not written words. |
| Missing project model | Store nullable/default `projectId` and isolate current editor stats behind a repository method that can be migrated later. |
| Privacy concerns | Keep all stats local in Hive and provide clear-all action. |

## Plan Split

| Plan | Focus | Requirements |
|------|-------|--------------|
| 09-01 | Domain, repository, collector, provider wiring, AI insertion hooks | STAT-01, STAT-02, STAT-05 |
| 09-02 | Dashboard routes and `fl_chart` visualizations | STAT-01, STAT-02, STAT-03 |
| 09-03 | Achievement badges and settings clear action | STAT-04, STAT-06 |
