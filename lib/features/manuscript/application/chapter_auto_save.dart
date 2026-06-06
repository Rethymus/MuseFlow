import 'dart:async';

import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

/// Auto-save service for chapter document content.
///
/// Provides debounced save (2 seconds default) and immediate force-save.
/// Per D-19: Dual guarantee -- debounced save after last edit plus forced
/// save on chapter switch, navigation, and app lifecycle pause.
class ChapterAutoSave {
  final ChapterRepository _repository;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  String? _currentChapterId;
  String? _pendingMarkdown;
  bool _isDirty = false;

  ChapterAutoSave(
    this._repository, {
    this.debounceDuration = const Duration(seconds: 2),
  });

  /// Called when document content changes.
  ///
  /// Sets the dirty flag and starts (or restarts) the debounce timer.
  /// The content is flushed after [debounceDuration] of inactivity.
  void onDocumentChanged(String chapterId, String markdown) {
    _currentChapterId = chapterId;
    _pendingMarkdown = markdown;
    _isDirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _flush);
  }

  /// Forces an immediate save of any pending changes.
  ///
  /// Cancels the debounce timer and flushes synchronously.
  /// Call this before chapter switch, navigation, or app pause.
  Future<void> forceSave() async {
    _debounceTimer?.cancel();
    await _flush();
  }

  /// Flushes pending changes to the repository.
  ///
  /// Only writes if [_isDirty] is true and a chapter ID is set.
  /// Resets the dirty flag after successful write.
  Future<void> _flush() async {
    if (!_isDirty || _currentChapterId == null || _pendingMarkdown == null) {
      return;
    }
    _isDirty = false;
    await _repository.updateDocumentContent(
      _currentChapterId!,
      _pendingMarkdown!,
    );
  }

  /// Disposes the auto-save service.
  ///
  /// Per SC-4: Cancels the debounce timer and releases resources only.
  /// Does NOT perform an unawaited async flush -- persistence guarantee
  /// comes from explicit awaited [forceSave] calls before transitions
  /// (chapter switch, back navigation, etc.), not from dispose.
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
