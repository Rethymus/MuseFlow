---
phase: 11-manuscript-chapter-management
plan: 04
subsystem: manuscript-presentation
tags: [editor, sidebar, chapter-navigation, auto-save, keyboard-shortcuts]
dependency_graph:
  requires: [11-02, 11-03]
  provides: [EditorWithSidebar, ChapterSidebar, ChapterSidebarRow, ChapterCreateDialog, ChapterRenameDialog, ChapterContextMenu]
  affects: [app.dart, editor_provider.dart, status_bar.dart]
tech_stack:
  added: [super_editor markdown serialization (built-in, not super_editor_markdown)]
  patterns: [ValueKey document switching, WidgetsBindingObserver lifecycle, ConsumerStatefulWidget]
key_files:
  created:
    - lib/features/manuscript/presentation/editor_with_sidebar.dart
    - lib/features/manuscript/presentation/chapter_sidebar.dart
    - lib/features/manuscript/presentation/chapter_sidebar_row.dart
    - lib/features/manuscript/presentation/chapter_create_dialog.dart
    - lib/features/manuscript/presentation/chapter_rename_dialog.dart
    - lib/features/manuscript/presentation/chapter_context_menu.dart
    - test/features/manuscript/presentation/chapter_sidebar_test.dart
    - test/features/manuscript/presentation/editor_with_sidebar_test.dart
  modified:
    - lib/features/editor/presentation/editor_provider.dart
    - lib/features/editor/presentation/status_bar.dart
    - lib/app.dart
decisions:
  - D-27: super_editor_markdown package is discontinued -- use super_editor built-in serialization instead (serializeDocumentToMarkdown, deserializeMarkdownToDocument)
  - D-28: ChapterAutoSave instance cached in local field to avoid ref.read in dispose (prevents "ref after unmount" error)
  - D-29: _loadInitialChapter uses setState to trigger rebuild after editor creation in postFrameCallback
metrics:
  duration: 16m
  tasks_completed: 2
  files_created: 8
  files_modified: 3
  tests_added: 9
  tests_passing: 906
  completed_date: 2026-06-06
---

# Phase 11 Plan 04: Editor with Chapter Sidebar Summary

EditorWithSidebar wrapping SuperEditor with chapter navigation sidebar, document switching with forced-save guarantees, auto-save integration, keyboard shortcuts, and status bar manuscript progress.

## Commits

| Hash | Message |
|------|---------|
| c9d5cd5 | feat(11-04): add chapter sidebar, row, create/rename dialogs, and context menu |
| 137f803 | feat(11-04): add EditorWithSidebar with document switching, auto-save, and keyboard shortcuts |

## Task Results

### Task 1: ChapterSidebar, ChapterSidebarRow, ChapterCreateDialog, ChapterRenameDialog, ChapterContextMenu

**Status:** Complete
**Commit:** c9d5cd5

- ChapterSidebar: ConsumerWidget with ReorderableListView, manuscript title header (20px w600), drag proxy with Material elevation, and "新建章节" OutlinedButton
- ChapterSidebarRow: title (14px, w400/w600) + word count (12px w500, onSurfaceVariant), active state with primary.withOpacity(0.15) background
- ChapterCreateDialog: title input with non-empty and max-100-char validation (T-11-07 mitigation)
- ChapterRenameDialog: pre-filled title input with same validation (T-11-05 mitigation)
- ChapterContextMenu: popup menu with rename, split, merge, duplicate, and destructive delete actions with correct enable/disable logic
- 6 widget tests passing

### Task 2: EditorWithSidebar with document switching, auto-save, keyboard shortcuts, extended StatusBar

**Status:** Complete
**Commit:** 137f803

- EditorWithSidebar: ConsumerStatefulWidget with WidgetsBindingObserver for app lifecycle save
- Document switching via ValueKey(_currentChapterId) pattern per RESEARCH.md Open Question 1
- Auto-save: ChapterAutoSave.onDocumentChanged with 2s debounce, forceSave on chapter switch, back navigation (PopScope), and app pause
- Keyboard shortcuts: Ctrl+Up (previous chapter), Ctrl+Down (next chapter), Ctrl+Shift+N (new chapter)
- StatusBar extended with optional currentWordCount/targetWordCount params showing "总字数: {current}/{target} 字"
- editor_provider.dart: added createEditorWithDocument function
- app.dart: replaced /manuscript/:id/editor placeholder with EditorWithSidebar
- 3 widget tests passing

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] super_editor_markdown import conflict**
- **Found during:** Task 2 implementation
- **Issue:** super_editor_markdown 0.2.0 (discontinued) conflicts with super_editor 0.3.0-dev which already includes the same serialization functions
- **Fix:** Removed super_editor_markdown import; used super_editor's built-in serializeDocumentToMarkdown and deserializeMarkdownToDocument
- **Files modified:** editor_with_sidebar.dart
- **Decision logged:** D-27

**2. [Rule 1 - Bug] ref.read in dispose causes StateError**
- **Found during:** Task 2 testing
- **Issue:** _forceSaveSync() and _cleanupEditor() called ref.read() during dispose, causing "Using ref when widget is about to be unmounted" error
- **Fix:** Cached ChapterAutoSave instance in local _autoSave field during initState; use cached reference in dispose instead of ref.read
- **Files modified:** editor_with_sidebar.dart
- **Decision logged:** D-28

**3. [Rule 1 - Bug] Editor not rendering after initial chapter load**
- **Found during:** Task 2 testing
- **Issue:** _loadInitialChapter called _loadChapter in postFrameCallback without setState, so Flutter did not rebuild the widget
- **Fix:** Wrapped _loadChapter call in setState() inside _loadInitialChapter
- **Files modified:** editor_with_sidebar.dart
- **Decision logged:** D-29

**4. [Rule 1 - Bug] ChapterContextMenu position used invalid type cast**
- **Found during:** Task 1 implementation
- **Issue:** Position parameter used Offset type with an unnecessary `as RelativeRect` cast; showMenu expects RelativeRect
- **Fix:** Changed position parameter to RelativeRect with a sensible default
- **Files modified:** chapter_context_menu.dart

**5. [Rule 1 - Bug] ReorderableDragStartListener used hardcoded index 0**
- **Found during:** Task 1 implementation
- **Issue:** Drag handle used `index: 0` instead of the actual list index
- **Fix:** Passed `index` from itemBuilder through _ChapterRowWrapper to ReorderableDragStartListener
- **Files modified:** chapter_sidebar.dart

## Verification Results

1. flutter test test/features/manuscript/presentation/ -- 9/9 passing
2. flutter test -- 906/906 passing (0 failures, 1 skip)
3. EditorWithSidebar file exists with ConsumerStatefulWidget, WidgetsBindingObserver, Shortcuts
4. ChapterSidebar file exists with ReorderableListView
5. All dialog files exist (create, rename, context menu)
6. editor_provider.dart has createEditorWithDocument function
7. status_bar.dart shows manuscript progress when context available (总字数 text present)
8. app.dart /manuscript/:id/editor route renders EditorWithSidebar (not placeholder)

## Self-Check: PASSED

All files exist. All commits verified. All tests passing.
