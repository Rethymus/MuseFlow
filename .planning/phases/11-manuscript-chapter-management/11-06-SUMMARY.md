---
phase: 11-manuscript-chapter-management
plan: 06
type: execute
wave: 6
gap_closure: true
tags: [sc-2, sc-3, sc-4, chapter-loading, auto-save, forced-save, tdd]
dependency_graph:
  requires: [11-05]
  provides: [chapter-loading-init, forced-save-guarantee]
  affects: [editor_with_sidebar, chapter_auto_save]
tech_stack:
  added: []
  patterns: [synchronous-fast-path-in-postFrameCallback, best-effort-async-save]
key_files:
  created: []
  modified:
    - lib/features/manuscript/presentation/editor_with_sidebar.dart
    - lib/features/manuscript/application/chapter_auto_save.dart
    - test/features/manuscript/presentation/editor_with_sidebar_test.dart
    - test/features/manuscript/application/chapter_auto_save_test.dart
decisions:
  - D-loadChapters-init: Call loadChapters in _loadInitialChapter postFrameCallback with synchronous fast-path for pre-populated state
  - D-dispose-no-flush: ChapterAutoSave.dispose only cancels timer; persistence guarantee comes from explicit awaited forceSave
  - D-lifecycle-best-effort: didChangeAppLifecycleState uses best-effort async save with catchError since Flutter does not await lifecycle callbacks
metrics:
  duration: 26m
  completed: 2026-06-06
  tasks: 2
  files: 4
---

# Phase 11 Plan 06: Gap Closure Summary

Load existing manuscript chapters on editor entry and enforce awaited forced-save guarantees per SC-2/SC-3/SC-4.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Async postFrameCallback caused SuperEditor crash in tests**
- **Found during:** Task 1 GREEN phase
- **Issue:** Using `async`/`await` inside `addPostFrameCallback` caused SuperEditor RenderObject mismatch in headless tests. The microtask-based timing after `await` placed SuperEditor creation in a different frame context.
- **Fix:** Used synchronous fast-path: call `loadChapters` (fire-and-forget), then immediately check `ref.read(chapterNotifierProvider).asData?.value` for pre-populated data. This matches the original synchronous pattern that worked with SuperEditor.
- **Files modified:** `editor_with_sidebar.dart`
- **Commit:** 7eb147a

## Decisions Made

- **D-loadChapters-init**: The `_loadInitialChapter` method calls `loadChapters(widget.manuscriptId)` synchronously in the postFrameCallback, then reads the current provider state. If chapters are already available (from `build()` returning data), the first chapter is loaded immediately. If not, `loadChapters` fetches from repository asynchronously and the provider state update triggers the listener path.
- **D-dispose-no-flush**: `ChapterAutoSave.dispose()` no longer calls `unawaited(_flush())`. The must-have persistence guarantee comes from explicit `await forceSave()` calls in `_switchChapter` and `_navigateBack`, not from dispose.
- **D-lifecycle-best-effort**: `didChangeAppLifecycleState` uses `_forceSaveBestEffort()` which fires the async save with `catchError` to prevent unhandled exceptions, since Flutter does not await lifecycle callbacks.

## Test Coverage

| Test File | Tests | Status |
|-----------|-------|--------|
| `test/features/manuscript/presentation/editor_with_sidebar_test.dart` | 4 | All pass |
| `test/features/manuscript/application/chapter_auto_save_test.dart` | 9 | All pass |

### Key Test Behaviors

- `loadChapters(manuscriptId)` is called during EditorWithSidebar initialization
- First chapter is loaded into editor when chapters exist
- Empty state shown but loadChapters still called when no chapters
- `ChapterAutoSave.dispose()` cancels debounce timer without flushing
- `forceSave()` is awaitable and returns after persistence completes
- Switching chapters saves pending changes for previous chapter

## Verification Results

- `flutter test test/features/manuscript/` -- 107 passed, 0 failed
- Static source gate: `unawaited(_flush())` no longer present in `chapter_auto_save.dart`
- Static source gate: `loadChapters(widget.manuscriptId)` present in `editor_with_sidebar.dart`

## Threat Surface Scan

No new security-relevant surface introduced. All changes are local UI state flow and local Hive-backed save timing. No network boundary, auth/session surface, secrets handling, or external input parser added.
