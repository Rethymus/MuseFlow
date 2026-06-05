import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing [Manuscript] entities in a Hive box.
///
/// Provides CRUD operations with soft-delete and purge support.
/// [getAll] filters out soft-deleted manuscripts (deletedAt != null).
/// Use [getAllIncludingDeleted] for purge queries.
class ManuscriptRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  ManuscriptRepository(this._box);

  /// Adds a new manuscript to the box.
  ///
  /// If the manuscript has an empty [id], a new UUID is generated.
  /// Sets [createdAt] and [updatedAt] to now.
  /// Returns the manuscript with ID and timestamps assigned.
  Future<Manuscript> add(Manuscript manuscript) async {
    try {
      final id = manuscript.id.isEmpty ? _uuid.v4() : manuscript.id;
      final now = DateTime.now();
      final newManuscript = Manuscript(
        id: id,
        title: manuscript.title,
        description: manuscript.description,
        genre: manuscript.genre,
        targetWordCount: manuscript.targetWordCount,
        status: manuscript.status,
        worldSettingId: manuscript.worldSettingId,
        characterCardIds: manuscript.characterCardIds,
        createdAt: now,
        updatedAt: now,
        deletedAt: manuscript.deletedAt,
        coverLetter: manuscript.coverLetter,
      );
      await _box.put(id, newManuscript.toJson());
      return newManuscript;
    } catch (e) {
      throw StateError('Failed to save manuscript: $e');
    }
  }

  /// Returns all manuscripts excluding soft-deleted ones.
  ///
  /// Manuscripts with [deletedAt] != null are filtered out.
  List<Manuscript> getAll() {
    try {
      return _box.values
          .map((json) => Manuscript.fromJson(json as Map<String, dynamic>))
          .where((manuscript) => manuscript.deletedAt == null)
          .toList();
    } catch (e) {
      throw StateError('Failed to read manuscripts: $e');
    }
  }

  /// Returns all manuscripts including soft-deleted ones.
  ///
  /// Used by [ManuscriptPurgeService] to find expired deletions.
  List<Manuscript> getAllIncludingDeleted() {
    try {
      return _box.values
          .map((json) => Manuscript.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StateError('Failed to read manuscripts: $e');
    }
  }

  /// Returns a manuscript by its ID, or null if not found.
  Manuscript? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return Manuscript.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read manuscript $id: $e');
    }
  }

  /// Updates an existing manuscript.
  ///
  /// Sets [updatedAt] to the current time before persisting.
  Future<void> update(Manuscript manuscript) async {
    try {
      final updated = manuscript.copyWith(updatedAt: DateTime.now());
      await _box.put(manuscript.id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update manuscript ${manuscript.id}: $e');
    }
  }

  /// Hard-deletes a manuscript by its ID.
  ///
  /// Permanently removes the manuscript from the box.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete manuscript $id: $e');
    }
  }

  /// Soft-deletes a manuscript by setting [deletedAt] to now.
  ///
  /// The manuscript remains in the box but is filtered from [getAll].
  /// Use [hardDelete] for permanent removal.
  Future<void> softDelete(String id) async {
    try {
      final manuscript = getById(id);
      if (manuscript == null) return;
      final updated = manuscript.copyWith(deletedAt: DateTime.now());
      await _box.put(id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to soft-delete manuscript $id: $e');
    }
  }

  /// Hard-deletes a manuscript by its ID.
  ///
  /// Same as [delete] but named for clarity in purge contexts.
  Future<void> hardDelete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to hard-delete manuscript $id: $e');
    }
  }

  /// Hard-deletes all manuscripts with [deletedAt] older than [age].
  ///
  /// Used by [ManuscriptPurgeService] for 30-day auto-purge.
  Future<void> purgeOlderThan(Duration age) async {
    try {
      final cutoff = DateTime.now().subtract(age);
      final allManuscripts = getAllIncludingDeleted();
      for (final manuscript in allManuscripts) {
        if (manuscript.deletedAt != null &&
            manuscript.deletedAt!.isBefore(cutoff)) {
          await _box.delete(manuscript.id);
        }
      }
    } catch (e) {
      throw StateError('Failed to purge manuscripts: $e');
    }
  }
}
