---
phase: 11-manuscript-chapter-management
slug: manuscript-chapter-management
status: audited
nyquist_compliant: true
wave_0_complete: true
gap_closure: true
validated: 2026-06-06
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (dart test) + Flutter analyzer |
| **Config file** | pubspec.yaml (dev_dependencies) |
| **Quick run command** | `flutter test test/features/manuscript/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds for focused Phase 11 suite |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test && flutter analyze`
- **Before `/gsd:verify-work`:** Full suite must be green, `flutter analyze` zero errors
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | SC-1 | — | Manuscript/Chapter entity immutability, serialization, defaults, validation, word count, genre colors | unit | `flutter test test/features/manuscript/domain/` | ✅ | ✅ green |
| 11-01-02 | 01 | 1 | SC-1 | — | Hive TypeAdapter registration for ManuscriptAdapter and ChapterAdapter | static | `flutter analyze lib/core/infrastructure/hive_adapters.dart lib/main.dart` | ✅ | ✅ covered |
| 11-02-01 | 02 | 2 | SC-2,SC-4 | — | Repository CRUD, soft delete, purge, chapter-scoped lookup, sort order | unit | `flutter test test/features/manuscript/infrastructure/ test/features/manuscript/application/manuscript_sort_test.dart` | ✅ | ✅ green |
| 11-02-02 | 02 | 2 | SC-2,SC-4 | T-11-03 | Notifier CRUD, chapter operations, auto-save debounce, force-save flush | unit | `flutter test test/features/manuscript/application/` | ✅ | ✅ green |
| 11-03-01 | 03 | 3 | SC-1 | — | Library page renders empty state, card grid, sort dropdown | widget | `flutter test test/features/manuscript/presentation/manuscript_library_page_test.dart` | ✅ | ✅ green |
| 11-03-02 | 03 | 3 | SC-1,SC-5 | T-11-01 | Create dialog/settings validation, card metadata rendering, navigation affordances | widget | `flutter test test/features/manuscript/presentation/` | ✅ | ✅ green |
| 11-04-01 | 04 | 4 | SC-2,SC-3 | — | Sidebar renders chapters, active highlight, new chapter action, reorder UI wiring | widget | `flutter test test/features/manuscript/presentation/chapter_sidebar_test.dart` | ✅ | ✅ green |
| 11-04-02 | 04 | 4 | SC-3,SC-4 | T-11-08 | Chapter switching, forced save, auto-save, keyboard shortcuts, EditorHolderNotifier update | unit+widget | `flutter test test/features/manuscript/presentation/editor_with_sidebar_test.dart test/features/manuscript/presentation/chapter_sidebar_test.dart` | ✅ | ✅ green |
| 11-05-01 | 05 | 5 | SC-5,SC-6 | — | Chapter-aware ExportBundle, Markdown/TXT/JSON export, template chapter skeletons | unit | `flutter test test/features/manuscript/domain/chapter_aware_export_test.dart test/features/templates/` | ✅ | ✅ green |
| 11-05-02 | 05 | 5 | SC-6,D-24 | T-11-10 | AI adjacent chapter context middleware, PromptContext chapter summaries, startup purge | unit+static | `flutter test test/features/manuscript/application/chapter_context_middleware_test.dart test/features/manuscript/application/template_chapter_test.dart` | ✅ | ✅ green |
| 11-06-01 | 06 | 6 | SC-2,SC-3 | T-11-06-01 | Editor entry calls `loadChapters(widget.manuscriptId)` and selects the first persisted chapter | widget+source | `flutter test test/features/manuscript/presentation/editor_with_sidebar_test.dart` | ✅ | ✅ green |
| 11-06-02 | 06 | 6 | SC-4 | T-11-06-02 | Forced save is awaitable on chapter switch/navigation; dispose does not rely on unawaited flush | unit+widget+source | `flutter test test/features/manuscript/application/chapter_auto_save_test.dart test/features/manuscript/presentation/editor_with_sidebar_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Requirement Coverage Summary

| Requirement | Coverage | Evidence |
|-------------|----------|----------|
| SC-1 | COVERED | Domain tests, manuscript library widget tests, card/settings/create validation tests |
| SC-2 | COVERED | Repository/notifier tests, sidebar tests, editor initial chapter-loading regression tests |
| SC-3 | COVERED | EditorWithSidebar chapter selection/loading tests and source gate for `loadChapters(widget.manuscriptId)` |
| SC-4 | COVERED | ChapterAutoSave debounce/force-save tests, editor awaited transition tests, source gate confirms no `unawaited(_flush())` |
| SC-5 | COVERED | Chapter-aware export tests and template instantiation tests |
| SC-6 | COVERED | PromptContext/ChapterContextMiddleware tests and template chapter skeleton tests |

---

## Wave 0 Requirements

These test files were scaffolded and are present after Phase 11 execution:

- [x] `test/features/manuscript/domain/manuscript_test.dart` — Manuscript entity roundtrip, coverLetter, equality, malformed JSON handling
- [x] `test/features/manuscript/domain/chapter_test.dart` — Chapter entity roundtrip, wordCount, equality, malformed JSON handling
- [x] `test/features/manuscript/domain/manuscript_genre_test.dart` — 14 presets, genreColor mapping, statuses
- [x] `test/features/manuscript/domain/chapter_export_test.dart` — ChapterExport serialization/equality
- [x] `test/features/manuscript/infrastructure/manuscript_repository_test.dart` — CRUD + soft delete + purge queries
- [x] `test/features/manuscript/infrastructure/chapter_repository_test.dart` — CRUD + manuscript-scoped queries
- [x] `test/features/manuscript/infrastructure/manuscript_purge_service_test.dart` — 30-day cascade purge
- [x] `test/features/manuscript/application/manuscript_notifier_test.dart` — Notifier CRUD + softDelete + search
- [x] `test/features/manuscript/application/chapter_notifier_test.dart` — Notifier CRUD + reorder + split + merge + duplicate
- [x] `test/features/manuscript/application/chapter_auto_save_test.dart` — Debounce + forceSave + dispose semantics
- [x] `test/features/manuscript/application/manuscript_sort_test.dart` — Sort comparator logic
- [x] `test/features/manuscript/presentation/manuscript_library_page_test.dart` — Card grid + empty state + sort + validation
- [x] `test/features/manuscript/presentation/manuscript_card_test.dart` — Genre cover + progress bar + status badge
- [x] `test/features/manuscript/presentation/chapter_sidebar_test.dart` — Reorderable list + active highlight
- [x] `test/features/manuscript/presentation/editor_with_sidebar_test.dart` — Chapter loading + forced save + auto-save lifecycle + navigation paths
- [x] `test/features/templates/application/template_instantiation_service_test.dart` — Template instantiation compatibility
- [x] `test/features/manuscript/application/template_chapter_test.dart` — Chapter skeleton creation from templates
- [x] `test/features/manuscript/application/chapter_context_middleware_test.dart` — Adjacent chapter context injection
- [x] `test/features/manuscript/domain/chapter_aware_export_test.dart` — Chapter-aware ExportBundle/ExportService behavior

*Existing infrastructure: `flutter test` runner, Hive test helpers, Riverpod provider overrides, Flutter widget tests.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drag-and-drop chapter reordering visual feedback | SC-2 | Gesture animation requires human eye | Open manuscript -> chapter list -> drag chapter -> verify smooth reorder animation |
| Genre-colored manuscript covers in library grid | SC-1 | Visual color correctness | Create manuscripts with different genres -> verify cover colors match genre |
| Editor sidebar chapter navigation UX | SC-3 | Sidebar interaction flow | Open manuscript -> click chapters in sidebar -> verify editor content switches |
| Keyboard shortcuts (Ctrl+Up/Down, Ctrl+Shift+N) | D-26 | Shortcut feel and platform key handling require human verification | Open manuscript editor -> press Ctrl+Up -> verify previous chapter selected |

---

## Validation Audit 2026-06-06

| Metric | Count |
|--------|-------|
| Requirements audited | 6 |
| Task verification rows audited | 12 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only retained | 4 |

### Automated Evidence

- `flutter test test/features/manuscript/ test/features/templates/application/template_instantiation_service_test.dart` — 123 tests passed.
- `flutter test test/features/manuscript/application/chapter_auto_save_test.dart test/features/manuscript/presentation/editor_with_sidebar_test.dart` — focused SC-2/SC-3/SC-4 gap-closure suite passed.
- `flutter test test/features/manuscript/` — manuscript feature suite completed successfully in background validation run.
- Source gate: `lib/features/ai/application/prompt_pipeline.dart` contains `previousChapterSummary` and `nextChapterSummary` fields.
- Source gate: `lib/features/manuscript/presentation/editor_with_sidebar.dart` contains `loadChapters(widget.manuscriptId)` and awaited `_forceSaveAsync()` transition paths.
- Source gate: `lib/features/manuscript/application/chapter_auto_save.dart` has no `unawaited(_flush())` match.

### Notes

Focused static analysis during audit surfaced style/lint findings in Phase 11-related files, but no missing automated verification coverage. These are quality cleanup items rather than Nyquist validation gaps.

---

## Validation Audit 2026-06-06 (Re-audit)

| Metric | Count |
|--------|-------|
| Requirements audited | 6 (SC-1 through SC-6) |
| Task verification rows audited | 12 |
| Test files on disk | 19/19 present |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only retained | 4 |

### Automated Evidence

- `flutter test test/features/manuscript/ test/features/templates/application/template_instantiation_service_test.dart` — **123 tests passed**.
- Source gate: `lib/features/manuscript/presentation/editor_with_sidebar.dart:119` contains `loadChapters(widget.manuscriptId)`. ✅
- Source gate: `lib/features/ai/application/prompt_pipeline.dart` contains `previousChapterSummary` and `nextChapterSummary` fields. ✅
- Source gate: `lib/features/manuscript/application/chapter_auto_save.dart` has no `unawaited(_flush())` match. ✅

### Conclusion

No new gaps discovered. Previous audit findings remain valid. All automated verification continues to pass. Phase 11 remains Nyquist-compliant.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused suites
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** audited 2026-06-06 — Phase 11 is Nyquist-compliant.
