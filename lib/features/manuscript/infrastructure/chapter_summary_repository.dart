import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';

/// Repository for [ChapterSummary] entities in a Hive box (MC-02 slice 2).
///
/// A summary is stored **keyed by [ChapterSummary.chapterId]** — the
/// chapter→summary relation is 1:1 (one latest summary per chapter), so the
/// chapter id is the natural primary key. This makes [getByChapterId] an O(1)
/// box lookup and `put` an upsert (writing a new summary for a chapter
/// overwrites the previous one), mirroring how [ChapterSummarizationService]
/// would refresh a stale summary.
///
/// Staleness is *not* decided here — see [ChapterSummaryStalenessChecker].
/// This repository only persists and retrieves; the caller decides freshness.
class ChapterSummaryRepository {
  ChapterSummaryRepository(this._box);

  final Box<dynamic> _box;

  /// Persists [summary], keyed by its [ChapterSummary.chapterId].
  ///
  /// Overwrites any previously stored summary for the same chapter (1:1
  /// upsert). Returns the summary as stored.
  Future<ChapterSummary> put(ChapterSummary summary) async {
    try {
      await _box.put(summary.chapterId, summary.toJson());
      return summary;
    } catch (e) {
      throw StateError(
        'Failed to save chapter summary for ${summary.chapterId}: $e',
      );
    }
  }

  /// Returns the stored summary for [chapterId], or null if none exists.
  ChapterSummary? getByChapterId(String chapterId) {
    try {
      final json = _box.get(chapterId);
      if (json == null) return null;
      return ChapterSummary.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (e) {
      throw StateError('Failed to read chapter summary $chapterId: $e');
    }
  }

  /// Returns all summaries belonging to [manuscriptId].
  List<ChapterSummary> getByManuscriptId(String manuscriptId) {
    try {
      return _box.values
          .map(
            (json) =>
                ChapterSummary.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .where((summary) => summary.manuscriptId == manuscriptId)
          .toList();
    } catch (e) {
      throw StateError(
        'Failed to read summaries for manuscript $manuscriptId: $e',
      );
    }
  }

  /// Deletes the stored summary for [chapterId], if any.
  Future<void> delete(String chapterId) async {
    try {
      await _box.delete(chapterId);
    } catch (e) {
      throw StateError('Failed to delete chapter summary $chapterId: $e');
    }
  }
}
