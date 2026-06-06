---
phase: 11-manuscript-chapter-management
reviewed: 2026-06-06T22:30:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/features/manuscript/presentation/editor_with_sidebar.dart
  - lib/features/manuscript/application/chapter_auto_save.dart
  - lib/features/manuscript/domain/manuscript.dart
  - lib/features/manuscript/domain/chapter.dart
  - lib/features/manuscript/infrastructure/manuscript_repository.dart
  - lib/features/manuscript/infrastructure/chapter_repository.dart
  - lib/features/manuscript/application/manuscript_notifier.dart
  - lib/features/manuscript/application/chapter_notifier.dart
  - lib/features/manuscript/presentation/manuscript_library_page.dart
  - lib/features/manuscript/presentation/chapter_sidebar.dart
  - test/features/manuscript/presentation/editor_with_sidebar_test.dart
  - test/features/manuscript/application/chapter_auto_save_test.dart
  - lib/core/presentation/providers.dart
findings:
  critical: 2
  warning: 5
  info: 4
  total: 11
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-06-06T22:30:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the full manuscript/chapter management feature including domain entities, repositories, notifiers, auto-save service, editor UI, and tests. The implementation is well-structured with clean architecture layering and proper Riverpod patterns. However, two critical bugs were found that risk data loss: a use-after-dispose pattern in auto-save initialization, and a state-wipe on chapter deletion due to the two-phase loading pattern. Several warnings address missing error propagation, sortOrder gaps, and edge cases in the editor lifecycle.

## Critical Issues

### CR-01: Use-after-dispose in _loadAutoSave -- auto-save silently fails to initialize

**File:** `lib/features/manuscript/presentation/editor_with_sidebar.dart:99-105`
**Issue:** The `_loadAutoSave` method checks `mounted` before calling `ref.read(chapterAutoSaveProvider.future).then(...)`, but the `.then` callback has no `mounted` check. If the widget is disposed between the `ref.read` call and the future's completion (e.g., rapid navigation away), the `.then` callback fires on a disposed widget, assigning `_autoSave` on dead state. Worse, `_autoSave` may remain `null` if the future completes after dispose, meaning `_forceSaveAndCleanup()` in `dispose()` (line 79) silently does nothing because `_autoSave?.forceSave()` is a no-op on null. This creates a window where user edits are never persisted.

**Fix:**
```dart
void _loadAutoSave() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ref.read(chapterAutoSaveProvider.future).then((autoSave) {
      if (!mounted) return; // Guard against dispose during async gap
      _autoSave = autoSave;
    });
  });
}
```

### CR-02: ChapterNotifier.delete wipes chapter list to empty, causing UI to flash empty state and lose in-memory chapters

**File:** `lib/features/manuscript/application/chapter_notifier.dart:45-49`
**Issue:** The `delete` method calls `ref.invalidateSelf()` which re-runs `build()`, which returns `Future<List<Chapter>>.value([])` (an empty list). The two-phase loading pattern means the state resets to empty, and `loadChapters` is never re-called by the notifier itself. The UI in `editor_with_sidebar.dart` line 450-463 tries to handle this by reading `chapterNotifierProvider` in a postFrameCallback after delete, but there is a race: `invalidateSelf()` triggers an async rebuild, and the postFrameCallback may read the empty intermediate state before rebuild completes, or the rebuild itself returns empty. This means after deleting a chapter, the user sees an empty sidebar that never repopulates until they manually navigate away and back.

Contrast with `add`, `save`, `reorder`, `duplicateChapter`, `splitChapter`, and `mergeChapters` -- all of which call `_refreshWith(repository, manuscriptId)` to properly reload from the repository. Only `delete` uses `invalidateSelf()`.

**Fix:**
```dart
Future<void> delete(String id) async {
  final repository =
      await ref.read(chapterRepositoryProvider.future);
  // Get manuscriptId before deleting so we can refresh
  final chapter = repository.getById(id);
  await repository.delete(id);
  if (chapter != null) {
    _refreshWith(repository, chapter.manuscriptId);
  } else {
    ref.invalidateSelf();
  }
}
```

## Warnings

### WR-01: ChapterNotifier.delete does not recalculate sortOrder, leaving gaps

**File:** `lib/features/manuscript/application/chapter_notifier.dart:45-49`
**Issue:** After deleting a chapter, the remaining chapters retain their original `sortOrder` values, which may have gaps (e.g., 0, 2, 3 after deleting the chapter at sortOrder=1). While the current `getByManuscriptId` sorts by `sortOrder` so the display order is correct, gaps will compound over time and could cause issues with `splitChapter` (which inserts at `existing.sortOrder + 1`) and `reorder`. The `mergeChapters` method recalculates sequential sortOrders, but `delete` does not.

**Fix:** Add sortOrder recalculation after deletion, similar to `mergeChapters`:
```dart
// After repository.delete(id):
final chapters = repository.getByManuscriptId(chapter.manuscriptId);
for (var i = 0; i < chapters.length; i++) {
  if (chapters[i].sortOrder != i) {
    await repository.update(chapters[i].copyWith(sortOrder: i));
  }
}
```

### WR-02: splitChapter shifts sortOrder after update, but getAtById may return stale data

**File:** `lib/features/manuscript/application/chapter_notifier.dart:119-161`
**Issue:** In `splitChapter`, line 130 calls `repository.update(existing.copyWith(documentContent: beforeContent))` which also sets `updatedAt = DateTime.now()`. Then line 135 calls `repository.getByManuscriptId(...)` to get the fresh list. The `getByManuscriptId` reads from the Hive box, so the updated chapter should be present. However, the `originalIndex` lookup on line 136-137 uses `indexWhere((c) => c.id == chapterId)` which is correct. The potential issue is that the shift loop on lines 140-145 shifts all chapters after `originalIndex` by +1, but the newly created chapter on line 148-159 uses `existing.sortOrder + 1` -- which is the ORIGINAL chapter's sortOrder before any shift. If the original was at sortOrder=0 and there was a chapter at sortOrder=1, the shift moves 1->2, and the new chapter gets sortOrder=1. This is actually correct. However, if the `existing` object was fetched before the `update` call (line 126), its `sortOrder` field is the old value, which is fine since `update` does not change `sortOrder`. No bug here, but the code is fragile and depends on `update` not touching `sortOrder`.

**Fix:** Document this invariant clearly, or explicitly use `existing.sortOrder` from the pre-update object to make intent obvious.

### WR-03: Manuscript.copyWith cannot set nullable fields back to null

**File:** `lib/features/manuscript/domain/manuscript.dart:35-63`
**Issue:** The `copyWith` method uses `deletedAt ?? this.deletedAt` semantics. Once `deletedAt` is set to a non-null value, it is impossible to "un-delete" a manuscript by calling `copyWith(deletedAt: null)` because `null ?? this.deletedAt` evaluates to `this.deletedAt`. This is a well-known Dart pattern limitation. While the current codebase only uses `softDelete` (setting deletedAt) and `hardDelete` (removing entirely), not "recover", any future un-delete/restore feature will silently fail.

**Fix:** Use a sentinel pattern for nullable fields that need to be clearable:
```dart
Manuscript copyWith({
  // ...
  Object? deletedAt = _sentinel,
}) {
  return Manuscript(
    // ...
    deletedAt: deletedAt == _sentinel ? this.deletedAt : deletedAt as DateTime?,
  );
}
```

### WR-04: _getSelectionOffset silently returns 0 on non-text selection -- split produces wrong content

**File:** `lib/features/manuscript/presentation/editor_with_sidebar.dart:480-488`
**Issue:** `_getSelectionOffset` catches any exception from casting `nodePosition` to `TextNodePosition` and returns 0. If the cursor is in a non-text node (e.g., an image block, horizontal rule), the split will use offset 0, meaning `_splitAtCursor` will split at the very beginning of the document. This silently produces a chapter with empty "before" content and the entire document as "after" content, which is likely not what the user intended.

**Fix:** Return null or a special sentinel when the selection is not in a text node, and have `_splitAtCursor` show a user-facing error or abort the split:
```dart
int? _getSelectionOffset(DocumentSelection selection) {
  try {
    final baseOffset =
        (selection.base.nodePosition as TextNodePosition).offset;
    return baseOffset;
  } catch (_) {
    return null;
  }
}
```

### WR-05: ChapterAutoSave._flush resets _isDirty before await -- concurrent onDocumentChanged during flush can lose data

**File:** `lib/features/manuscript/application/chapter_auto_save.dart:49-58`
**Issue:** In `_flush`, line 53 sets `_isDirty = false` before the `await` on line 54. If `onDocumentChanged` is called between lines 53 and 54 (i.e., while `_repository.updateDocumentContent` is in progress), the new dirty content will be written to `_pendingMarkdown` and `_isDirty` will be set back to `true`. The timer will also be started. This is actually safe in Dart's single-threaded model because `await` yields to the event loop and `onDocumentChanged` would be a separate event. The real concern is: if the timer is started during flush and the flush completes, the timer's `_flush` call will find `_isDirty = true` and write again -- this is correct behavior (coalescing). No data loss here, but the early `_isDirty = false` before the write completes means a crash during `updateDocumentContent` would lose the dirty flag, and the pending content would be lost forever.

**Fix:** Move `_isDirty = false` after the await:
```dart
Future<void> _flush() async {
  if (!_isDirty || _currentChapterId == null || _pendingMarkdown == null) {
    return;
  }
  final markdown = _pendingMarkdown!;
  final chapterId = _currentChapterId!;
  await _repository.updateDocumentContent(chapterId, markdown);
  _isDirty = false;
}
```

## Info

### IN-01: Test comment contradicts test behavior (line 113-114)

**File:** `test/features/manuscript/application/chapter_auto_save_test.dart:113-114`
**Issue:** The comment says "Content should NOT have been persisted (dispose cancels timer, flushes)" but then says "Actually, dispose calls forceSave which flushes, so content IS persisted. The test verifies dispose doesn't crash and timer is cleaned up." The final assertion only checks `chapter, isNotNull` which is always true. This test does not actually verify any meaningful behavior.

**Fix:** Clean up the contradictory comment. The test should assert a specific expected state rather than just `isNotNull`.

### IN-02: _InMemoryTestBox uses shared static instance across test runs

**File:** `test/features/manuscript/presentation/editor_with_sidebar_test.dart:171`
**Issue:** `_NoOpChapterRepository` creates a `static final _inMemoryTestBox = _InMemoryTestBox()`. This means all test instances share the same box. While the current tests don't write meaningful data to it, this is a latent bug: if any test writes to the box, subsequent tests will see that data. The `late` keyword on `box` in `chapter_auto_save_test.dart` is correct (creates fresh boxes per test), but the editor widget tests share this static box.

**Fix:** Make the box per-instance rather than static:
```dart
class _NoOpChapterRepository extends ChapterRepository {
  _NoOpChapterRepository() : super(_InMemoryTestBox());
}
```

### IN-03: EditorWithSidebar exceeds 800-line project standard

**File:** `lib/features/manuscript/presentation/editor_with_sidebar.dart`
**Issue:** At 846 lines, this file exceeds the project's 800-line maximum stated in `.claude/rules/03-flutter-standards.md`. The recommended size is 200-400 lines. The file mixes editor management, chapter operations, keyboard shortcuts, and helper utilities in a single widget.

**Fix:** Extract keyboard shortcut intents (lines 797-823) and `_SelectionLeadersLayerBuilder` (lines 829-845) into a separate file. Consider extracting chapter operations (_showCreateChapterDialog, _showRenameDialog, _handleContextMenuAction, etc.) into a separate mixin or controller class.

### IN-04: Chapter.wordCount getter uses non-standard regex for Chinese word count

**File:** `lib/features/manuscript/domain/chapter.dart:31-33`
**Issue:** The `wordCount` getter counts all non-whitespace characters (`documentContent.replaceAll(RegExp(r'\s'), '').length`). For Chinese text this is reasonable (character count is the standard metric), but for mixed Chinese-English text it counts each English letter individually rather than counting English words. A 100-word English paragraph would count as ~500 "words". The comment says "counts characters excluding whitespace, which is the standard metric for Chinese text" which is accurate for pure Chinese, but the app may have mixed-language content.

**Fix:** Document this limitation clearly, or implement a mixed-mode counter that counts Chinese characters individually and English words by whitespace boundaries.

---

_Reviewed: 2026-06-06T22:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
