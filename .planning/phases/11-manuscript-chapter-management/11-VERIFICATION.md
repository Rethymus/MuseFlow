---
phase: 11-manuscript-chapter-management
status: gaps_found
verified: 2026-06-06T02:18:25Z
score: 3/6
gaps:
  - truth: "SC-2/SC-3: User can manage existing chapters and the editor switches documents when selecting a chapter"
    status: failed
    reason: "EditorWithSidebar never calls ChapterNotifier.loadChapters(manuscriptId) on entry. ChapterNotifier.build() returns an empty list, so existing chapters are not loaded into the sidebar and _loadInitialChapter reads an empty provider state. Existing chapter content is inaccessible from the editor route."
    artifacts:
      - path: "lib/features/manuscript/presentation/editor_with_sidebar.dart"
        issue: "initState calls _loadInitialChapter(), but _loadInitialChapter only reads chapterNotifierProvider.asData and never triggers loadChapters(widget.manuscriptId)."
      - path: "lib/features/manuscript/application/chapter_notifier.dart"
        issue: "build() returns [] by design; loadChapters(manuscriptId) must be called by the editor or sidebar for data to flow."
    missing:
      - "Call ref.read(chapterNotifierProvider.notifier).loadChapters(widget.manuscriptId) during EditorWithSidebar initialization, then load the first chapter after the load completes."
  - truth: "SC-4: Chapter content auto-saves with debounced plus forced-save guarantees on chapter switch, navigation, and app lifecycle"
    status: failed
    reason: "Forced save is not guaranteed in dispose/lifecycle paths. _forceSaveSync invokes async forceSave without awaiting, and ChapterAutoSave.dispose uses unawaited(_flush()). Pending edits may be lost during route teardown or app close."
    artifacts:
      - path: "lib/features/manuscript/presentation/editor_with_sidebar.dart"
        issue: "_forceSaveSync() calls _autoSave?.forceSave() without awaiting; dispose calls _forceSaveAndCleanup(), which cannot guarantee persistence before cleanup."
      - path: "lib/features/manuscript/application/chapter_auto_save.dart"
        issue: "dispose() cancels the timer then calls unawaited(_flush()), so the Hive write may not complete before teardown."
    missing:
      - "Ensure forced saves are awaited before chapter switch/back navigation/app lifecycle transitions where possible, and avoid relying on unawaited async flush in dispose for the must-have guarantee."
---

# Phase 11: Manuscript Chapter Management Verification

## Summary

Phase 11 is partially implemented but does not achieve the full roadmap goal yet.

Verified codebase evidence shows substantive implementation for manuscript/chapter domain entities, Hive repositories, Riverpod notifiers, manuscript library routing, chapter-aware export, template chapter skeletons, AI chapter-context middleware, and startup purge. However, two core must-haves are not actually delivered in the running editor flow:

1. The chapter editor does not load existing manuscript chapters on entry, because `EditorWithSidebar` never calls `ChapterNotifier.loadChapters(widget.manuscriptId)`.
2. The auto-save guarantee is not satisfied for teardown/lifecycle paths because async flushes are launched without being awaited.

These are observable implementation/wiring gaps in the source files.

## Automated Checks

| Check | Result | Evidence |
| --- | --- | --- |
| Orchestrator Flutter tests | Passed | Orchestrator reported full suite passed: 925 passed, 1 skipped. |
| Schema drift | Passed | Orchestrator reported `drift_detected=false`. |
| Codebase drift | Non-blocking skip | Orchestrator reported skipped `no-structure-md`. |
| Code review | Issues found | `/home/re/code/MuseFlow/.planning/phases/11-manuscript-chapter-management/11-REVIEW.md` reports 3 critical, 6 warning, 5 info. CR-01 and CR-02 directly affect roadmap must-haves. |

## Must-Haves Verification

| # | Must-have | Status | Evidence |
| --- | --- | --- | --- |
| 1 | User can create, view, edit, soft-delete manuscripts from a library homepage with genre-colored cards | Verified | `lib/app.dart` routes Branch 1 `/editor` to `ManuscriptLibraryPage`; `ManuscriptLibraryPage` watches `manuscriptNotifierProvider`, renders empty state/grid/sort/FAB, and long-press delete calls `softDelete`; `ManuscriptRepository.getAll()` filters `deletedAt == null`. |
| 2 | User can create, rename, reorder, split, merge, duplicate, and delete chapters within a manuscript | Failed | The operations exist in `ChapterNotifier` and UI handlers, but the editor route never loads chapters for the manuscript. `ChapterNotifier.build()` returns `[]`, and `EditorWithSidebar._loadInitialChapter()` only reads the current empty provider state. Existing chapters are therefore not available to manage on editor entry. |
| 3 | Editor switches chapter documents when user selects a different chapter in the left sidebar | Failed | `_switchChapter()` can force-save and load a chapter if `chapterNotifierProvider` already contains chapters, but no code in `EditorWithSidebar` calls `loadChapters(widget.manuscriptId)`. The sidebar/editor starts from an empty list even when repository data exists. |
| 4 | Chapter content auto-saves with debounced plus forced-save guarantees on chapter switch, navigation, and app lifecycle | Failed | `ChapterAutoSave` implements debounce and `forceSave`, but `EditorWithSidebar._forceSaveSync()` calls `forceSave()` without awaiting and `ChapterAutoSave.dispose()` uses `unawaited(_flush())`. This does not guarantee persistence during dispose/app close. |
| 5 | Manuscript creation from template auto-creates WorldSetting + CharacterCards + chapter skeleton | Verified | `TemplateInstantiationService` injects `ChapterRepository`; `TemplateDraft` has `manuscriptId` and `chapterTitles`; `saveDraft()` creates `Chapter` skeletons when `draft.manuscriptId != null`. |
| 6 | Export supports chapter-aware structure with per-chapter content, not only flat manuscriptText | Verified | `ExportBundle` has `List<ChapterExport> chapters`; `ExportService.buildMarkdown()` sorts chapters and emits `## {title}` headers; `buildTxt()` emits chapter-separated output; `ExportDialog` displays chapter count when chapters are present. |

**Score:** 3/6 roadmap must-haves verified.

## Requirement Traceability

Phase 11 is not mapped to numbered v1.1 requirements in `/home/re/code/MuseFlow/.planning/REQUIREMENTS.md`; Phase 11 belongs to v1.2 and is governed by the six roadmap success criteria in `/home/re/code/MuseFlow/.planning/ROADMAP.md`.

| Requirement / Success Criterion | Status | Evidence |
| --- | --- | --- |
| SC-1: Manuscript library CRUD | Verified | Domain/repository/notifier/UI/routing evidence listed above. |
| SC-2: Chapter operations | Failed | Operations exist, but editor data-flow does not load existing chapters. |
| SC-3: Editor chapter switching | Failed | Switching implementation exists but is disconnected from repository-loaded data on entry. |
| SC-4: Auto-save guarantees | Failed | Async forced saves are not awaited in teardown/lifecycle paths. |
| SC-5: Template creates chapter skeleton | Verified | `TemplateInstantiationService.saveDraft()` creates chapters for `draft.manuscriptId`. |
| SC-6: Chapter-aware export | Verified | `ExportBundle.chapters` and `ExportService.buildMarkdown()` implemented. |

## Gaps

### Gap 1: Editor never loads existing chapters

`EditorWithSidebar.initState()` calls `_loadAutoSave()` and `_loadInitialChapter()`. `_loadInitialChapter()` reads the current provider state and returns if it is empty. But `ChapterNotifier.build()` returns an empty list and requires an explicit `loadChapters(String manuscriptId)` call. No such call exists in `EditorWithSidebar`. As a result, users entering `/manuscript/:id/editor` see no existing chapters and cannot access existing chapter content.

### Gap 2: Forced-save guarantee is not met

`ChapterAutoSave.forceSave()` is asynchronous, but `EditorWithSidebar._forceSaveSync()` calls it without awaiting. `ChapterAutoSave.dispose()` also uses `unawaited(_flush())`. This contradicts the must-have that forced saves are guaranteed on navigation/app lifecycle/teardown.

## Human Verification

Human testing is recommended after the gaps are fixed:

1. Open a manuscript with existing chapters and confirm the sidebar loads them immediately.
2. Edit chapter content, switch chapters, return to library, reopen the manuscript, and confirm edits persisted.
3. Pause/close the app shortly after editing and confirm the latest content is not lost.
4. Verify the visual layout of the manuscript card grid, chapter sidebar, active chapter highlight, and export dialog on Windows/Android form factors.

These are not replacing the automated gaps above; they are post-fix UAT checks.

## Verdict

**Status: gaps_found**

Phase 11 should not be treated as goal-complete until the editor chapter-loading data flow and forced-save guarantee are fixed. The codebase contains substantial Phase 11 implementation, but the current editor route does not actually deliver existing chapter navigation/switching and does not meet the auto-save guarantee.

---

_Verified: 2026-06-06T02:18:25Z_
_Verifier: Claude (gsd-verifier)_
