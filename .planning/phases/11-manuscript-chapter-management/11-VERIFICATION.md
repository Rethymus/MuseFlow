---
phase: 11-manuscript-chapter-management
verified: 2026-06-06T15:52:00Z
status: human_needed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/6
  gaps_closed:
    - "SC-2/SC-3: EditorWithSidebar now awaits ChapterNotifier.loadChapters(widget.manuscriptId) on entry and loads the first returned chapter."
    - "SC-4: Chapter switch, back navigation, and manuscript settings navigation now await _forceSaveAsync() before changing chapter/route; lifecycle uses handled best-effort save; ChapterAutoSave.dispose no longer performs unawaited flush."
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Open a manuscript with existing chapters on a real Windows/Android build and verify sidebar/editor visual state."
    expected: "Existing chapters appear immediately, the first chapter is active, and its content is visible without manual reload."
    why_human: "Visual layout, focus behavior, and native input/editor rendering cannot be fully proven by static code checks."
  - test: "Edit chapter content, switch chapters, open manuscript settings, return/back to library, then reopen the manuscript."
    expected: "The latest edits persist across each route/chapter transition, including the settings AppBar path."
    why_human: "End-to-end route timing and real editor persistence across actual app navigation need manual UAT despite automated focused tests passing."
  - test: "Pause/inactivate the app shortly after editing on target platforms."
    expected: "Best-effort lifecycle save does not crash or lose normally persisted content."
    why_human: "Flutter lifecycle callbacks are platform/runtime driven and not awaitable by framework contract."
---

# Phase 11: Manuscript Chapter Management Verification Report

**Phase Goal:** 将 MuseFlow 从单一编辑器升级为多文稿管理平台，支持文稿 CRUD、章节实体与导航、编辑器章节级切换、数据迁移和模板策略修订
**Verified:** 2026-06-06T15:52:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure commit `f66e916 fix(11): force-save before opening manuscript settings`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can create, view, edit, soft-delete manuscripts from a library homepage with genre-colored cards | VERIFIED | `ManuscriptLibraryPage` renders library UI and routes cards to `/manuscript/{id}/editor`; library context menu routes to settings and calls `manuscriptNotifierProvider.notifier.softDelete(manuscript.id)`. `ManuscriptRepository.softDelete` sets deletion state and `getAll()` filters deleted manuscripts. |
| 2 | User can create, rename, reorder, split, merge, duplicate, and delete chapters within a manuscript | VERIFIED | `ChapterNotifier` implements `add`, `save`, `delete`, `reorder`, `duplicateChapter`, `splitChapter`, and `mergeChapters`; `delete` refreshes by manuscript and recalculates sort order. `EditorWithSidebar` wires create/rename/context menu/delete/split/merge/duplicate actions to the notifier. |
| 3 | Editor switches chapter documents when user selects a different chapter in the left sidebar | VERIFIED | Previous gap closed. `EditorWithSidebar._loadInitialChapter()` awaits `ref.read(chapterNotifierProvider.notifier).loadChapters(widget.manuscriptId)`, checks `mounted`, reads loaded chapters, and loads `chapters.first`. `ChapterSidebar.onChapterTap` is wired to `_switchChapter`; `_switchChapter` awaits `_forceSaveAsync()` before `_loadChapter(newChapter)`. |
| 4 | Chapter content auto-saves with debounced + forced-save guarantees on chapter switch, navigation, and app lifecycle | VERIFIED | `ChapterAutoSave.forceSave()` cancels debounce and awaits `_flush()`, which awaits `ChapterRepository.updateDocumentContent`. `ChapterAutoSave.dispose()` only cancels the timer. `EditorWithSidebar._switchChapter`, `_navigateBack`, and `_openSettings` await `_forceSaveAsync()` before changing chapter/route; lifecycle pause/inactive calls `_forceSaveBestEffort()` with `catchError` because Flutter does not await lifecycle callbacks. |
| 5 | Manuscript creation from template auto-creates WorldSetting + CharacterCards + chapter skeleton | VERIFIED | `TemplateInstantiationService` has `ChapterRepository` injection and creates `Chapter` skeletons from `draft.chapterTitles` when `draft.manuscriptId != null`. |
| 6 | Export supports chapter-aware structure with per-chapter content, not only flat manuscriptText | VERIFIED | `ExportBundle` includes `List<ChapterExport> chapters`; `ExportService.buildMarkdown` emits chapter-aware Markdown; export pipeline retains legacy flat bundle compatibility. |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/features/manuscript/presentation/editor_with_sidebar.dart` | Editor route chapter-loading data flow and awaited forced-save transitions | VERIFIED | Exists, substantive, wired. Contains awaited initial `loadChapters`, first-chapter load, `_switchChapter`, `_navigateBack`, and `_openSettings` awaited forced-save paths. |
| `lib/features/manuscript/application/chapter_auto_save.dart` | Debounced and forced chapter persistence without unawaited dispose flush | VERIFIED | Exists, substantive, wired to `ChapterRepository.updateDocumentContent`; no `unawaited(_flush())` remains. |
| `test/features/manuscript/presentation/editor_with_sidebar_test.dart` | Regression coverage for initial chapter loading and first chapter selection | VERIFIED | Focused test run passed. Tests cover load call, async empty-start first-chapter load, empty result state, and title rendering. |
| `test/features/manuscript/application/chapter_auto_save_test.dart` | Regression coverage for forced-save/dispose semantics | VERIFIED | Focused test run passed. Tests cover immediate `forceSave`, dispose without flushing, awaitable persistence, and debounce behavior. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `EditorWithSidebar` | `ChapterNotifier.loadChapters` | Initialization post-frame callback | WIRED | Manual verification confirms `await ref.read(chapterNotifierProvider.notifier).loadChapters(widget.manuscriptId)` before reading state; SDK regex check missed because call spans lines. |
| `EditorWithSidebar` | `ChapterAutoSave.forceSave` | `_forceSaveAsync()` on controllable transitions | WIRED | `_switchChapter`, `_navigateBack`, and `_openSettings` all await `_forceSaveAsync()`. AppBar settings button calls `_openSettings`. |
| `ChapterAutoSave` | `ChapterRepository` | `_flush()` | WIRED | `_flush()` awaits `_repository.updateDocumentContent(chapterId, markdown)` and only clears dirty state after successful write when pending content still matches. |
| `ChapterSidebar` | `EditorWithSidebar._switchChapter` | `onChapterTap: _switchChapter` | WIRED | Sidebar taps invoke the async switch path that saves current chapter before loading the selected chapter. |
| `ManuscriptLibraryPage` | `EditorWithSidebar`/settings routes | `context.go('/manuscript/...')` | WIRED | Library cards route to editor; settings route exists in `app.dart`. Editor AppBar settings path now saves first. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `EditorWithSidebar` | `chapters` / `_currentChapterId` / `_editor` | `ChapterNotifier.loadChapters(widget.manuscriptId)` → `ChapterRepository.getByManuscriptId(manuscriptId)` → `state = AsyncData(chapters)` | Yes | FLOWING |
| `ChapterSidebar` | rendered chapter rows | `ref.watch(chapterNotifierProvider)` after editor load | Yes | FLOWING |
| `ChapterAutoSave` | `_pendingMarkdown` | `serializeDocumentToMarkdown(_editor!.document)` from editor listeners/forced-save paths | Yes | FLOWING |
| `ExportService` | `bundle.chapters` | `ExportBundle.chapters` populated with `ChapterExport` objects | Yes | FLOWING |
| `TemplateInstantiationService` | chapter skeletons | `TemplateDraft.chapterTitles` + `ChapterRepository.add` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Focused gap-closure regression tests | `cd /home/re/code/MuseFlow && flutter test --no-pub test/features/manuscript/application/chapter_auto_save_test.dart test/features/manuscript/presentation/editor_with_sidebar_test.dart` | 14 tests passed | PASS |
| Full Flutter suite | Not rerun by verifier; user/orchestrator supplied current evidence | User supplied current evidence: full `flutter test` passed after settings save fix with 930 passed, 1 skipped | PASS (external evidence) |
| Initial test attempt from worktree with absolute test paths | `flutter test --no-pub /home/re/code/MuseFlow/test/...` | Flutter tool crash: `Bad state: No element`; rerun from project root passed | INFO |

### Probe Execution

No phase probes were declared or found for Phase 11. Step 7c skipped.

### Requirements Coverage

`/home/re/code/MuseFlow/.planning/REQUIREMENTS.md` is absent in this v1.2 milestone context; Phase 11 is governed by ROADMAP success criteria and plan `requirements: [SC-*]` fields.

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SC-1 | 11-03 | Manuscript library CRUD/card grid | SATISFIED | Library UI, card navigation, create dialog, settings page, soft delete path implemented. |
| SC-2 | 11-02, 11-04, 11-06 | Chapter CRUD and management within manuscript | SATISFIED | `ChapterNotifier` operations plus sidebar/context-menu wiring; editor now loads manuscript chapters on entry. |
| SC-3 | 11-04, 11-06 | Editor switches chapter documents via sidebar selection | SATISFIED | `ChapterSidebar.onChapterTap` → `_switchChapter` → awaited save → `_loadChapter(newChapter)` with `ValueKey(_currentChapterId)`. |
| SC-4 | 11-02, 11-04, 11-06 | Debounced + forced-save guarantees | SATISFIED | `forceSave()` awaited on switch/back/settings; lifecycle best-effort with handled errors; dispose no longer unawaitedly flushes. |
| SC-5 | 11-05 | Template creates world/characters/chapter skeleton | SATISFIED | Template instantiation creates chapter skeletons via `ChapterRepository`. |
| SC-6 | 11-05 | Chapter-aware export | SATISFIED | `ExportBundle.chapters` and chapter-aware export service implemented. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/features/manuscript/application/chapter_notifier.dart` | 14 | `return []` | INFO | Deliberate two-phase provider loading; editor now explicitly calls `loadChapters`, so not a stub. |
| `lib/features/manuscript/presentation/editor_with_sidebar.dart` | 480-482 | `return null` on non-text split selection | INFO | Intentional guard: split aborts and shows SnackBar for non-text positions. |
| `lib/features/manuscript/presentation/editor_with_sidebar.dart` | 565-566 | Quick insert unavailable comment | INFO | Existing editor shortcut placeholder outside Phase 11 success criteria; no blocker for manuscript/chapter management. |
| `test/features/manuscript/application/chapter_auto_save_test.dart` | 112-114 | Stale contradictory comment | WARNING | Comment says dispose flushes but current assertions elsewhere verify dispose does not flush. Test behavior still covers must-have; comment should be cleaned in a future maintenance pass. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the reverified phase files.

### Human Verification Required

#### 1. Existing Chapter Visual Load UAT

**Test:** Open a manuscript with existing chapters on a real Windows/Android build and inspect the sidebar/editor.
**Expected:** Existing chapters appear immediately, first chapter is active, and its persisted content is visible without manual reload.
**Why human:** Visual layout, active highlight, editor focus, and native rendering require manual UAT.

#### 2. Route Transition Persistence UAT

**Test:** Edit chapter content, switch chapters, press the AppBar settings button, navigate back to the library, then reopen.
**Expected:** Latest edits persist across chapter switch, settings navigation, and library navigation.
**Why human:** Static/code tests prove awaited calls exist; full user-route timing should still be validated manually on a running app.

#### 3. Lifecycle Persistence UAT

**Test:** Edit content, pause/inactivate the app shortly afterward on target platforms.
**Expected:** Best-effort save path does not crash and normally persisted content is retained.
**Why human:** Flutter lifecycle delivery is platform/runtime dependent and not awaitable.

### Gaps Summary

No automated blocker gaps remain. The prior two verification gaps are closed:

1. `EditorWithSidebar` now loads chapters from `ChapterRepository` through `ChapterNotifier.loadChapters(widget.manuscriptId)` on editor entry and selects the first loaded chapter.
2. Forced-save coverage now includes chapter switch, back navigation, and the AppBar settings route via awaited `_forceSaveAsync()`. `ChapterAutoSave.dispose()` no longer relies on unawaited async flushes.

Because manual visual/platform UAT remains, final status is `human_needed` rather than `passed`.

---

_Verified: 2026-06-06T15:52:00Z_
_Verifier: Claude (gsd-verifier)_
