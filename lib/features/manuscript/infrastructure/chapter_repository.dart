import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing [Chapter] entities in a Hive box.
///
/// Provides CRUD operations with manuscript-scoped queries and
/// document content updates for auto-save.
class ChapterRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  ChapterRepository(this._box);

  /// Adds a new chapter to the box.
  ///
  /// If the chapter has an empty [id], a new UUID is generated.
  /// Sets [createdAt] and [updatedAt] to now.
  /// Returns the chapter with ID and timestamps assigned.
  Future<Chapter> add(Chapter chapter) async {
    try {
      final id = chapter.id.isEmpty ? _uuid.v4() : chapter.id;
      final now = DateTime.now();
      final newChapter = Chapter(
        id: id,
        manuscriptId: chapter.manuscriptId,
        title: chapter.title,
        sortOrder: chapter.sortOrder,
        status: chapter.status,
        documentContent: chapter.documentContent,
        createdAt: now,
        updatedAt: now,
      );
      await _box.put(id, newChapter.toJson());
      return newChapter;
    } catch (e) {
      throw StateError('Failed to save chapter: $e');
    }
  }

  /// Returns all chapters in the box.
  List<Chapter> getAll() {
    try {
      return _box.values
          .map((json) => Chapter.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw StateError('Failed to read chapters: $e');
    }
  }

  /// Returns a chapter by its ID, or null if not found.
  Chapter? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return Chapter.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (e) {
      throw StateError('Failed to read chapter $id: $e');
    }
  }

  /// Returns chapters filtered by [manuscriptId], sorted by [sortOrder] ascending.
  ///
  /// Used by [ChapterNotifier] to load chapters for a specific manuscript.
  List<Chapter> getByManuscriptId(String manuscriptId) {
    try {
      return _box.values
          .map((json) => Chapter.fromJson(Map<String, dynamic>.from(json as Map)))
          .where((chapter) => chapter.manuscriptId == manuscriptId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (e) {
      throw StateError('Failed to read chapters for manuscript $manuscriptId: $e');
    }
  }

  /// Updates an existing chapter.
  ///
  /// Sets [updatedAt] to the current time before persisting.
  Future<void> update(Chapter chapter) async {
    try {
      final updated = chapter.copyWith(updatedAt: DateTime.now());
      await _box.put(chapter.id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update chapter ${chapter.id}: $e');
    }
  }

  /// Updates only the [documentContent] and [updatedAt] fields.
  ///
  /// Optimized for auto-save: reads the current entity, applies only
  /// the content change, and writes back. Avoids full entity rewrite.
  Future<void> updateDocumentContent(String chapterId, String markdown) async {
    try {
      final existing = getById(chapterId);
      if (existing == null) return;
      final updated = existing.copyWith(
        documentContent: markdown,
        updatedAt: DateTime.now(),
      );
      await _box.put(chapterId, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update document content for chapter $chapterId: $e');
    }
  }

  /// Deletes a chapter by its ID.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete chapter $id: $e');
    }
  }

  /// Deletes all chapters belonging to [manuscriptId].
  ///
  /// Used by [ManuscriptPurgeService] for cascade deletion when
  /// purging a soft-deleted manuscript.
  Future<void> deleteByManuscriptId(String manuscriptId) async {
    try {
      final chapters = getByManuscriptId(manuscriptId);
      for (final chapter in chapters) {
        await _box.delete(chapter.id);
      }
    } catch (e) {
      throw StateError('Failed to delete chapters for manuscript $manuscriptId: $e');
    }
  }
}
