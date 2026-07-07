import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

/// AsyncNotifier managing the list of [Chapter] entities for a manuscript.
///
/// Uses a two-phase loading pattern: [build] returns an empty list,
/// and [loadChapters] loads chapters for a specific manuscriptId.
/// This avoids the need for a family provider while maintaining
/// manuscript-scoped chapter lists.
class ChapterNotifier extends AsyncNotifier<List<Chapter>> {
  @override
  Future<List<Chapter>> build() async {
    return [];
  }

  /// Loads chapters for [manuscriptId] ordered by [sortOrder].
  ///
  /// Call this when entering a manuscript's editor view.
  Future<void> loadChapters(String manuscriptId) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    final chapters = repository.getByManuscriptId(manuscriptId);
    state = AsyncData(chapters);
  }

  /// Adds a new chapter and refreshes the state.
  Future<void> add(Chapter chapter) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    // Capture the persisted chapter — repository.add assigns a real uuid when
    // the input id is empty; refresh MUST use the persisted id, not the
    // possibly-empty input id (MC-02 slice 4 trigger-surface completion).
    final persisted = await repository.add(chapter);
    _refreshWith(repository, chapter.manuscriptId);
    // MC-02 slice 4: refresh on the persisted chapter (real id + content).
    unawaited(_maybeRefreshSummary(persisted));
  }

  /// Updates an existing chapter and refreshes the state.
  Future<void> save(Chapter chapter) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    await repository.update(chapter);
    _refreshWith(repository, chapter.manuscriptId);
    // MC-02 slice 3 write-side: fire-and-forget AI summary refresh. NEVER
    // throws into save() — the saved chapter is persisted regardless.
    unawaited(_maybeRefreshSummary(chapter));
  }

  /// Fire-and-forget MC-02 summary refresh (slice 3+4). NEVER throws into the
  /// calling op.
  ///
  /// [force] bypasses the staleness check (calls [ChapterSummaryRefreshService.refresh]
  /// instead of refreshIfNeeded). Used by splitChapter/mergeChapters where the
  /// content was REPLACED, not grown — the staleness check would mark the
  /// original fresh (growth negative) and inject the now-factually-wrong
  /// whole-chapter summary on the next editor AI call (MC-02 slice 4 bug 1).
  ///
  /// Reliability posture (wma/0ae): the SERVICE rethrows AIException/StateError;
  /// HERE we catch+log+drop because this is an async side-effect, not the main
  /// save contract. A failed AI summary MUST NOT kill the user's chapter op.
  Future<void> _maybeRefreshSummary(
    Chapter chapter, {
    bool force = false,
  }) async {
    try {
      final service = await ref.read(
        chapterSummaryRefreshServiceProvider.future,
      );
      if (service == null) return; // no provider/apiKey/repo configured
      if (force) {
        await service.refresh(chapter);
      } else {
        await service.refreshIfNeeded(chapter);
      }
    } catch (e) {
      debugPrint('ChapterSummaryRefresh skipped for ${chapter.id}: $e');
    }
  }

  /// Fire-and-forget MC-02 orphan-summary cleanup (slice 4). NEVER throws into
  /// the calling delete/merge op.
  ///
  /// Used by delete(id) and mergeChapters(chapter2) to remove orphan
  /// ChapterSummary rows left behind when a chapter is destroyed — otherwise
  /// ChapterSummaryRepository.getByManuscriptId would return summaries for
  /// chapters that no longer exist (MC-02 slice 4 bug 2).
  Future<void> _deleteSummary(String chapterId) async {
    try {
      final service = await ref.read(
        chapterSummaryRefreshServiceProvider.future,
      );
      if (service == null) return; // no provider/apiKey/repo configured
      await service.deleteSummary(chapterId);
    } catch (e) {
      debugPrint('ChapterSummary delete skipped for $chapterId: $e');
    }
  }

  /// Deletes a chapter by ID and refreshes the state.
  Future<void> delete(String id) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    final chapter = repository.getById(id);
    await repository.delete(id);
    // MC-02 slice 4: orphan-summary cleanup — fire-and-forget, never throws
    // into delete().
    unawaited(_deleteSummary(id));
    if (chapter != null) {
      final chapters = repository.getByManuscriptId(chapter.manuscriptId);
      for (var i = 0; i < chapters.length; i++) {
        if (chapters[i].sortOrder != i) {
          await repository.update(chapters[i].copyWith(sortOrder: i));
        }
      }
      _refreshWith(repository, chapter.manuscriptId);
    } else {
      ref.invalidateSelf();
    }
  }

  /// Reorders chapters by moving the item at [oldIndex] to [newIndex].
  ///
  /// Recalculates all [sortOrder] values to be sequential (0, 1, 2, ...)
  /// after the reorder operation to prevent gap accumulation.
  Future<void> reorder(String manuscriptId, int oldIndex, int newIndex) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    final chapters = List<Chapter>.from(
      repository.getByManuscriptId(manuscriptId),
    );

    if (oldIndex < 0 ||
        oldIndex >= chapters.length ||
        newIndex < 0 ||
        newIndex >= chapters.length) {
      return;
    }

    final item = chapters.removeAt(oldIndex);
    chapters.insert(newIndex, item);

    // Recalculate sortOrder to sequential values
    for (var i = 0; i < chapters.length; i++) {
      final updated = chapters[i].copyWith(sortOrder: i);
      await repository.update(updated);
    }

    _refreshWith(repository, manuscriptId);
  }

  /// Duplicates a chapter with "(副本)" suffix and next sortOrder.
  ///
  /// Copies the title, content, and manuscriptId. The duplicate
  /// is placed at the end of the chapter list.
  Future<void> duplicateChapter(String chapterId) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    final existing = repository.getById(chapterId);
    if (existing == null) return;

    final chapters = repository.getByManuscriptId(existing.manuscriptId);
    final maxSortOrder = chapters.fold<int>(
      0,
      (max, c) => c.sortOrder > max ? c.sortOrder : max,
    );

    final now = DateTime.now();
    // Capture the persisted chapter — repository.add assigns a real uuid;
    // refresh MUST use the persisted id (MC-02 slice 4).
    final created = await repository.add(
      Chapter(
        id: '',
        manuscriptId: existing.manuscriptId,
        title: '${existing.title}(副本)',
        sortOrder: maxSortOrder + 1,
        documentContent: existing.documentContent,
        createdAt: now,
        updatedAt: now,
      ),
    );

    _refreshWith(repository, existing.manuscriptId);
    // MC-02 slice 4: refresh on the created duplicate (real id + content).
    unawaited(_maybeRefreshSummary(created));
  }

  /// Splits a chapter at a content boundary.
  ///
  /// Updates the current chapter with [beforeContent] and creates a new
  /// chapter with [afterContent] at the next sortOrder. All subsequent
  /// chapters are shifted to maintain sequential ordering.
  Future<void> splitChapter(
    String chapterId,
    String beforeContent,
    String afterContent,
  ) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    final existing = repository.getById(chapterId);
    if (existing == null) return;

    // Preserve the original sortOrder while updating content. The subsequent
    // shift uses that pre-update position so the new chapter can be inserted
    // immediately after the original without depending on update side effects.
    final originalSortOrder = existing.sortOrder;

    // Update original with beforeContent
    await repository.update(existing.copyWith(documentContent: beforeContent));
    // MC-02 slice 4: FORCE-refresh the original's summary. beforeContent is a
    // SUBSET (shorter); staleness check would mark the now-factually-wrong
    // whole-chapter summary "fresh" (growth negative) and re-inject it on the
    // next editor AI call.
    unawaited(
      _maybeRefreshSummary(
        existing.copyWith(documentContent: beforeContent),
        force: true,
      ),
    );

    // Get all chapters after updating to calculate sortOrder
    final chapters = repository.getByManuscriptId(existing.manuscriptId);
    final originalIndex = chapters.indexWhere((c) => c.id == chapterId);

    // Shift chapters after the original up by 1
    for (var i = chapters.length - 1; i > originalIndex; i--) {
      final chapter = chapters[i];
      await repository.update(
        chapter.copyWith(sortOrder: chapter.sortOrder + 1),
      );
    }

    // Create new chapter with afterContent inserted right after original
    final now = DateTime.now();
    // Capture the persisted chapter — refresh MUST use the persisted id.
    final created = await repository.add(
      Chapter(
        id: '',
        manuscriptId: existing.manuscriptId,
        title: '${existing.title} (续)',
        sortOrder: originalSortOrder + 1,
        documentContent: afterContent,
        createdAt: now,
        updatedAt: now,
      ),
    );

    _refreshWith(repository, existing.manuscriptId);
    // MC-02 slice 4: FORCE-refresh the new chapter's summary (new content).
    unawaited(_maybeRefreshSummary(created, force: true));
  }

  /// Merges two chapters by combining their content.
  ///
  /// The first chapter receives the combined content, the second is deleted.
  /// All subsequent chapters' sortOrder values are recalculated.
  Future<void> mergeChapters(String chapterId1, String chapterId2) async {
    final repository = await ref.read(chapterRepositoryProvider.future);
    final chapter1 = repository.getById(chapterId1);
    final chapter2 = repository.getById(chapterId2);
    if (chapter1 == null || chapter2 == null) return;

    // Combine content
    final combinedContent =
        '${chapter1.documentContent}\n\n${chapter2.documentContent}';
    await repository.update(
      chapter1.copyWith(documentContent: combinedContent),
    );

    // Delete second chapter
    await repository.delete(chapterId2);
    // MC-02 slice 4: orphan-summary cleanup for the deleted chapter2.
    unawaited(_deleteSummary(chapterId2));

    // Recalculate sortOrder for remaining chapters
    final chapters = repository.getByManuscriptId(chapter1.manuscriptId);
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].sortOrder != i) {
        await repository.update(chapters[i].copyWith(sortOrder: i));
      }
    }

    _refreshWith(repository, chapter1.manuscriptId);
    // MC-02 slice 4: FORCE-refresh chapter1's summary — content was replaced
    // (combined), not grown; staleness check would mark the old (chapter1-only)
    // summary fresh.
    unawaited(
      _maybeRefreshSummary(
        chapter1.copyWith(documentContent: combinedContent),
        force: true,
      ),
    );
  }

  /// Refreshes the state by reading the repository again.
  void _refreshWith(ChapterRepository repository, [String? manuscriptId]) {
    final effectiveManuscriptId =
        manuscriptId ?? (state.asData?.value ?? []).firstOrNull?.manuscriptId;
    if (effectiveManuscriptId == null) {
      ref.invalidateSelf();
      return;
    }
    final refreshed = repository.getByManuscriptId(effectiveManuscriptId);
    state = AsyncData(refreshed);
  }
}
