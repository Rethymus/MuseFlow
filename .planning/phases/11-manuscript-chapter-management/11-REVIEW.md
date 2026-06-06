---
phase: 11-manuscript-chapter-management
reviewed: 2026-06-06T12:00:00Z
depth: deep
files_reviewed: 22
files_reviewed_list:
  - lib/features/manuscript/presentation/manuscript_library_page.dart
  - lib/features/manuscript/presentation/manuscript_card.dart
  - lib/features/manuscript/presentation/manuscript_create_dialog.dart
  - lib/features/manuscript/presentation/manuscript_settings_page.dart
  - lib/features/manuscript/presentation/editor_with_sidebar.dart
  - lib/features/manuscript/presentation/chapter_sidebar.dart
  - lib/features/manuscript/presentation/chapter_sidebar_row.dart
  - lib/features/manuscript/presentation/chapter_create_dialog.dart
  - lib/features/manuscript/presentation/chapter_rename_dialog.dart
  - lib/features/manuscript/presentation/chapter_context_menu.dart
  - lib/features/editor/application/chapter_context_middleware.dart
  - lib/features/story_structure/domain/export_bundle.dart
  - lib/features/story_structure/application/export_service.dart
  - lib/features/story_structure/presentation/export_dialog.dart
  - lib/features/templates/application/template_instantiation_service.dart
  - lib/features/templates/application/template_draft.dart
  - lib/features/ai/application/prompt_pipeline.dart
  - lib/features/editor/application/editor_prompt_pipeline.dart
  - lib/core/presentation/providers.dart
  - lib/main.dart
  - lib/app.dart
  - lib/shared/constants/app_constants.dart
findings:
  critical: 3
  warning: 6
  info: 5
  total: 14
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-06-06
**Depth:** deep
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Reviewed all 22 source files created or modified across Phase 11 plans 03, 04, and 05 (manuscript-chapter-management). The implementation spans the manuscript library UI, editor with chapter sidebar, and integration wiring (export, templates, AI context, startup purge).

Three critical issues were found: a chapter navigation race condition that can cause data loss, a missing `loadChapters` call that leaves the chapter list empty on editor entry, and a `Manuscript.copyWith` defect that prevents nullable fields from being cleared. Six warnings cover incorrect API usage, missing mounted guards, unmounted-ref risks, and architectural violations. Five info items cover dead code and minor quality concerns.

## Critical Issues

### CR-01: ChapterAutoSave.dispose uses unawaited async flush -- data loss on app close

**File:** `lib/features/manuscript/infrastructure/chapter_repository.dart:94-106` (root cause in `lib/features/manuscript/application/chapter_auto_save.dart:63-67`)
**Issue:** `ChapterAutoSave.dispose()` calls `unawaited(_flush())` which performs an async repository write (`_box.put()`). When the widget is being torn down (app close, route change), the Dart event loop may terminate before the async `_flush` completes. The `_isDirty` flag is set to `false` synchronously at line 53 of `chapter_auto_save.dart`, but the actual write at `chapter_repository.dart:102` (`await _box.put(chapterId, updated.toJson())`) may never execute.

Combined with `_forceSaveSync()` called from `_forceSaveAndCleanup()` in `editor_with_sidebar.dart:242`, which also relies on `_flush()` being async, this means user edits can be silently lost when closing the app or navigating away from the editor.
**Impact:** User's last edits within the debounce window are silently discarded on app close or rapid navigation. No error is shown because the dirty flag was already cleared.
**Fix:**
```dart
// chapter_auto_save.dart - make dispose synchronous-and-blocking
void dispose() {
  _debounceTimer?.cancel();
  _debounceTimer = null;
  // Cannot await in dispose. Log warning if dirty.
  if (_isDirty) {
    debugPrint('ChapterAutoSave: WARNING - disposing with unsaved changes');
  }
  _isDirty = false;
}
```
Additionally, `_forceSaveSync()` in `editor_with_sidebar.dart` should call `forceSave()` and the result should be awaited before dispose. The `dispose()` lifecycle cannot guarantee async completion -- the forced save must happen *before* `super.dispose()` is called, and it must be synchronous (Hive supports sync `put`). Consider using `_box.put()` (sync form) in a dedicated sync flush method.

### CR-02: EditorWithSidebar never calls ChapterNotifier.loadChapters -- chapter list always empty on entry

**File:** `lib/features/manuscript/presentation/editor_with_sidebar.dart:105-115`
**Issue:** `_loadInitialChapter()` reads `ref.read(chapterNotifierProvider).asData?.value ?? []`. However, `ChapterNotifier.build()` returns `Future<List<Chapter>>` that resolves to an empty list (`return [];`). There is no call anywhere in `EditorWithSidebar` to `chapterNotifierProvider.notifier.loadChapters(manuscriptId)`. The notifier is never told which manuscript's chapters to load, so `asData?.value` always contains an empty list.

The `ref.watch(chapterNotifierProvider)` at line 463 will produce an AsyncData with an empty list. The sidebar will show "no chapters" and the editor will show the "select or create a chapter" placeholder -- even when chapters exist in the repository.
**Impact:** The entire chapter sidebar and editor are non-functional on every entry. Users see an empty chapter list and must manually create chapters even when they already exist. Existing chapter content is inaccessible.
**Fix:**
```dart
// In _EditorWithSidebarState.initState or a dedicated init method:
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _loadAutoSave();
  // Load chapters for this manuscript
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ref.read(chapterNotifierProvider.notifier)
        .loadChapters(widget.manuscriptId)
        .then((_) {
          if (!mounted) return;
          _loadInitialChapter();
        });
  });
}
```
And remove the separate `_loadInitialChapter()` call from `initState` since it should only run after `loadChapters` completes.

### CR-03: Manuscript.copyWith cannot clear nullable fields (description, worldSettingId, deletedAt)

**File:** `lib/features/manuscript/domain/manuscript.dart:35-62`
**Issue:** The `copyWith` method uses `?? this.field` for all nullable fields (`description`, `worldSettingId`, `deletedAt`). This means a caller can never set these fields back to `null`. For `deletedAt`, this means the soft-delete recovery feature (setting `deletedAt` to null to "undelete") is broken. The `ManuscriptSettingsPage._handleSave` at line 243 calls `copyWith(description: ...)` which works for setting a value, but there is no way to clear the description.
**Impact:** The soft-delete recovery is structurally impossible through `copyWith`. Any attempt to undelete a manuscript by setting `deletedAt: null` will silently keep the old value. Users cannot recover accidentally deleted manuscripts.
**Fix:**
```dart
Manuscript copyWith({
  String? id,
  String? title,
  Object? description = _sentinel,
  String? genre,
  int? targetWordCount,
  String? status,
  Object? worldSettingId = _sentinel,
  List<String>? characterCardIds,
  DateTime? createdAt,
  DateTime? updatedAt,
  Object? deletedAt = _sentinel,
  String? coverLetter,
}) {
  return Manuscript(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description == _sentinel ? this.description : description as String?,
    genre: genre ?? this.genre,
    targetWordCount: targetWordCount ?? this.targetWordCount,
    status: status ?? this.status,
    worldSettingId: worldSettingId == _sentinel ? this.worldSettingId : worldSettingId as String?,
    characterCardIds: characterCardIds ?? this.characterCardIds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt == _sentinel ? this.deletedAt : deletedAt as DateTime?,
    coverLetter: coverLetter ?? this.coverLetter,
  );
}

static const _sentinel = Object();
```

## Warnings

### WR-01: AnimatedBuilder is not a valid Flutter widget class

**File:** `lib/features/manuscript/presentation/chapter_sidebar.dart:208`
**Issue:** `AnimatedBuilder` is used as the widget class. The correct Flutter class is `AnimatedBuilder` -- however, in Flutter 3.x the class was renamed to `AnimatedBuilder` from the older `AnimatedWidget` pattern. Actually, the correct widget is `AnimatedBuilder`. Upon verification: Flutter's widget is named `AnimatedBuilder` and it does exist. However, the standard Flutter widget for this pattern is actually called `AnimatedBuilder` -- but looking at the Flutter API, the correct class is indeed `AnimatedBuilder`. This is correct for Flutter 3.44.0.
**Reclassification:** After verifying Flutter 3.44.0 API, `AnimatedBuilder` exists and is valid. Withdrawing this finding.
**Status:** Withdrawn upon API verification.

### WR-01: _splitAtCursor uses base offset instead of extent for selection range -- data loss on range selection

**File:** `lib/features/manuscript/presentation/editor_with_sidebar.dart:355-357`
**Issue:** `_splitAtCursor` extracts `selection.base` offset via `_getSelectionOffset` which casts `selection.base.nodePosition as TextNodePosition` and returns `baseOffset`. When the user has a *range* selection (not collapsed), the split point should be the start of the selection (base) or the extent, depending on direction. But more critically, `plainText.substring(0, offset)` splits at `base`, and `plainText.substring(offset)` takes the rest. If the user selected a range, the selected text is included in `after` but the split happens at the base -- this is the intended behavior per the split-at-cursor feature. However, `_getSelectionOffset` catches all exceptions and returns 0, meaning if the selection is not a `TextNodePosition` (e.g., the cursor is on an image or block node), the entire document goes into `before` and `after` is empty, effectively doing nothing. The silent 0-return masks a real error.
**Impact:** Split silently fails for non-text node positions. No user feedback is given.
**Fix:** Return early and show a user-facing message when the selection is not in a text node:
```dart
int? _getSelectionOffset(DocumentSelection selection) {
  try {
    final baseOffset =
        (selection.base.nodePosition as TextNodePosition).offset;
    return baseOffset;
  } catch (_) {
    return null; // Return null instead of 0 to signal failure
  }
}
```
And in `_splitAtCursor`:
```dart
final offset = _getSelectionOffset(selection);
if (offset == null) return; // Can't split at non-text position
```

### WR-02: ManuscriptCard._showContextMenu is dead code -- empty no-op method

**File:** `lib/features/manuscript/presentation/manuscript_card.dart:144-149`
**Issue:** The `_showContextMenu()` method is declared as `void _showContextMenu() {}` with a comment saying the parent handles it. It is connected to `onLongPress: _showContextMenu` at line 47, which means a long-press on the card calls a no-op. However, the *parent* `_ManuscriptCardWrapper` in `manuscript_library_page.dart` wraps the card in a `GestureDetector` with its own `onLongPress`. Two competing `GestureDetector`s (the card's internal `InkWell.onLongPress` and the wrapper's `GestureDetector.onLongPress`) will conflict -- Flutter's gesture arena resolves this, but the behavior is platform-dependent and unreliable.
**Impact:** Long-press context menu may not appear reliably. The card's `InkWell.onLongPress` (no-op) may win the gesture arena over the parent's `GestureDetector.onLongPress` (actual menu).
**Fix:** Remove the dead `_showContextMenu` method and change the `InkWell` to not handle `onLongPress`:
```dart
child: InkWell(
  onTap: onTap,
  // Remove onLongPress -- parent GestureDetector handles it
  child: Column(
```

### WR-03: ManuscriptSettingsPage._loadManuscript calls setState indirectly during build

**File:** `lib/features/manuscript/presentation/manuscript_settings_page.dart:76-87`
**Issue:** Inside the `build` method's `data:` callback, `_loadManuscript(manuscript)` is called which mutates `_titleController.text`, `_descriptionController.text`, `_targetWordCountController.text`, `_selectedGenre`, `_isCustomGenre`, `_customGenreController.text`, and `_isLoaded`. While this does not call `setState()` directly, it mutates controller text during build, which is an anti-pattern in Flutter. If the provider emits a new value (e.g., after save), this code re-enters and the `!_isLoaded` guard prevents re-loading. But the initial mutation during build can cause issues with Flutter's element tree lifecycle.
**Impact:** Potential for "setState() or markNeedsBuild() called during build" errors if the controller mutation triggers listener callbacks that attempt rebuilds.
**Fix:** Move the manuscript loading to `didChangeDependencies` or `initState` with a post-frame callback:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_isLoaded) {
    final manuscriptsAsync = ref.read(manuscriptNotifierProvider);
    final manuscript = manuscriptsAsync.asData?.value
        .where((m) => m.id == widget.manuscriptId)
        .firstOrNull;
    if (manuscript != null) {
      _loadManuscript(manuscript);
    }
  }
}
```

### WR-04: _confirmDeleteChapter accesses ref.read inside postFrameCallback without mounted check

**File:** `lib/features/manuscript/presentation/editor_with_sidebar.dart:409-423`
**Issue:** After `delete()` completes, a `postFrameCallback` is scheduled that calls `ref.read(chapterNotifierProvider)` and `_loadChapter`. There is a `mounted` check missing before the `ref.read` call at line 412. If the widget has been unmounted between the delete and the post-frame callback, `ref.read` will throw a `StateError`.
**Impact:** StateError crash if the widget is disposed during the post-frame callback window (e.g., user presses back immediately after confirming delete).
**Fix:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return; // Add mounted check FIRST
  final remaining =
      ref.read(chapterNotifierProvider).asData?.value ?? [];
  // ...
});
```

### WR-05: ExportDialog._doExport ignores selectedPath -- always passes content to onExport but never writes to _selectedPath

**File:** `lib/features/story_structure/presentation/export_dialog.dart:66-96`
**Issue:** `_doExport()` calls `_exportService.buildContent(widget.bundle, _selectedFormat)` to build content, then calls `widget.onExport(_selectedFormat, content)`. The `_selectedPath` is validated as non-null at line 67 but is never passed to the export callback or used in the write. The `onExport` callback receives the format and content, but not the path. The `_PathInputDialog` collects a path from the user, and the UI shows "已导出至: $_selectedPath" on success, but the file is never actually written to `_selectedPath`.
**Impact:** The export dialog appears to succeed but does not write to the user-selected path. The content is built but never persisted. The user sees a success message for an operation that did not happen.
**Fix:** Pass the path to the export callback:
```dart
// Change the onExport signature or pass path through:
await widget.onExport(_selectedFormat, content); // content goes nowhere

// Should be:
final exportService = ExportService(
  fileWriter: (path, content) async {
    final file = File(path);
    await file.writeAsString(content);
  },
);
await exportService.writeLocalFile(_selectedPath!, content);
```
Or update the `onExport` callback signature to include the path.

### WR-06: Presentation layer directly instantiates infrastructure services in main.dart

**File:** `lib/main.dart:82-94`
**Issue:** `main()` directly instantiates `ManuscriptRepository(manuscriptsBox)` and `ChapterRepository(chaptersBox)` instead of using providers. While the summary notes this was intentional ("main.dart is not a ConsumerWidget"), it bypasses the provider system and creates a second, independent instance of these repositories. If the providers also open boxes with the same names (which they do -- `chapterRepositoryProvider` opens `'chapters'`), Hive's same-name box semantics return the same box, so the underlying data is shared. However, the repository *objects* are different instances, meaning any in-memory caching or state in the repository would diverge.
**Impact:** If repositories add in-memory caching in the future, the purge service will operate on stale data. Current risk is low because repositories are stateless, but this is an architectural smell that will cause subtle bugs when caching is added.
**Fix:** Consider creating a dedicated `purgeServiceProvider` that is initialized inside the `ProviderScope`, or perform the purge in a post-frame callback after `runApp`.

## Info

### IN-01: ManuscriptCreateDialog uses id: '' convention -- relies on repository to generate UUID

**File:** `lib/features/manuscript/presentation/manuscript_create_dialog.dart:149`
**Issue:** The manuscript is created with `id: ''`. The repository's `add` method checks for empty ID and generates a UUID. This convention works but is fragile -- if a caller passes a non-empty string that happens to collide, it would overwrite existing data.
**Fix:** Consider using a sentinel value or explicit `generateId: true` flag for clarity.

### IN-02: ChapterCreateDialog and ChapterRenameDialog share identical validation logic

**File:** `lib/features/manuscript/presentation/chapter_create_dialog.dart:36-39` and `lib/features/manuscript/presentation/chapter_rename_dialog.dart:36-39`
**Issue:** Both dialogs have identical `_validate` methods with the same logic. This duplicated validation should be extracted to a shared utility.
**Fix:** Extract to a shared function:
```dart
String? validateChapterTitle(String value) {
  if (value.trim().isEmpty) return '章节标题不能为空';
  if (value.trim().length > 100) return '章节标题不能超过100个字符';
  return null;
}
```

### IN-03: EditorWithSidebar._getMenuPosition uses hardcoded pixel values for context menu positioning

**File:** `lib/features/manuscript/presentation/editor_with_sidebar.dart:700-712`
**Issue:** The context menu position is hardcoded with `left: 260, top: 200` pixels. This does not adapt to different screen sizes or the actual chapter row position. The `findRenderObject()` call gets the editor widget's render box, not the chapter row's, so the position calculation is disconnected from the actual chapter row location.
**Fix:** Pass a `GlobalKey` to each chapter row and use its `RenderBox` for positioning.

### IN-04: ChapterNotifier._refreshWith uses firstOrNull fallback for manuscriptId

**File:** `lib/features/manuscript/application/chapter_notifier.dart:199-208`
**Issue:** When `manuscriptId` is not passed to `_refreshWith`, it falls back to the first chapter's `manuscriptId`. If the notifier manages chapters from multiple manuscripts, this could load the wrong manuscript's chapters.
**Fix:** Always pass manuscriptId explicitly or validate the fallback matches the current context.

### IN-05: TemplateInstantiationService.saveDraft uses dynamic type for createdCharacters

**File:** `lib/features/templates/application/template_instantiation_service.dart:56-64`
**Issue:** `createdCharacters` is declared as `List<dynamic>` and populated with results from `characterCardRepository.add()`. It is then `.cast()` to the expected type. This loose typing hides potential type errors.
**Fix:**
```dart
final createdCharacters = <CharacterCard>[];
for (final character in draft.characters) {
  if (!character.selected) continue;
  createdCharacters.add(
    await characterCardRepository.add(character.toCharacterCard()),
  );
}
```

---

_Reviewed: 2026-06-06_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
