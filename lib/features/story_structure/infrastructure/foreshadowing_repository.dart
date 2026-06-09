import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing [ForeshadowingEntry] entities in a Hive box.
///
/// Provides CRUD operations following the same pattern as CharacterCardRepository.
/// All operations are wrapped in error handling to prevent silent failures.
class ForeshadowingRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  ForeshadowingRepository(this._box);

  /// Adds a new foreshadowing entry to the box.
  ///
  /// If the entry has an empty [id], a new UUID is generated.
  /// Sets [createdAt] to now if not already set.
  /// Returns the entry with ID and timestamps assigned.
  /// Throws [StateError] if the write fails.
  Future<ForeshadowingEntry> add(ForeshadowingEntry entry) async {
    try {
      final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
      final now = DateTime.now();
      final newEntry = ForeshadowingEntry(
        id: id,
        title: entry.title,
        mode: entry.mode,
        status: entry.status,
        plantedChapter: entry.plantedChapter,
        targetResolutionChapter: entry.targetResolutionChapter,
        resolvedChapter: entry.resolvedChapter,
        sourceExcerpt: entry.sourceExcerpt,
        sourceLocation: entry.sourceLocation,
        notes: entry.notes,
        linkedPlotNodeIds: entry.linkedPlotNodeIds,
        createdAt: now,
      );
      await _box.put(id, newEntry.toJson());
      return newEntry;
    } catch (e) {
      throw StateError('Failed to save foreshadowing entry: $e');
    }
  }

  /// Returns all foreshadowing entries in the box.
  List<ForeshadowingEntry> getAll() {
    try {
      return _box.values
          .map(
            (json) => ForeshadowingEntry.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw StateError('Failed to read foreshadowing entries: $e');
    }
  }

  /// Returns a foreshadowing entry by its ID, or null if not found.
  ForeshadowingEntry? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return ForeshadowingEntry.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read foreshadowing entry $id: $e');
    }
  }

  /// Updates an existing foreshadowing entry.
  ///
  /// Sets [updatedAt] to the current time before persisting.
  /// Throws [StateError] if the write fails.
  Future<void> update(ForeshadowingEntry entry) async {
    try {
      final updated = entry.copyWith(updatedAt: DateTime.now());
      await _box.put(entry.id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update foreshadowing entry ${entry.id}: $e');
    }
  }

  /// Deletes a foreshadowing entry by its ID.
  ///
  /// Does not throw if the ID does not exist.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete foreshadowing entry $id: $e');
    }
  }
}
