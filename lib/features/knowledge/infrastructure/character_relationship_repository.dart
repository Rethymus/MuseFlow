/// Hive-backed repository for [CharacterRelationship] entities.
///
/// Per Phase 21 (KNOW-02): Stores character-to-character relationships
/// in a Hive box, keyed by relationship ID. Supports full CRUD and
/// querying by character ID.
library;

import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/character_relationship.dart';

/// Repository for persisting [CharacterRelationship] entities.
///
/// Uses a Hive box with JSON-serialized maps. Each relationship is
/// stored under its `id` key. Supports querying relationships
/// involving a specific character.
class CharacterRelationshipRepository {
  final Box<dynamic> _box;

  CharacterRelationshipRepository(this._box);

  /// Returns all stored relationships.
  List<CharacterRelationship> getAll() {
    return _box.values
        .map(
          (json) => CharacterRelationship.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  /// Returns a relationship by its ID, or null if not found.
  CharacterRelationship? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return CharacterRelationship.fromJson(
      Map<String, dynamic>.from(json as Map),
    );
  }

  /// Returns all relationships involving the given character ID.
  ///
  /// Matches both `fromCharacterId` and `toCharacterId`, so the result
  /// includes relationships where the character is either the source
  /// or the target.
  List<CharacterRelationship> getForCharacter(String characterId) {
    return getAll()
        .where(
          (r) =>
              r.fromCharacterId == characterId ||
              r.toCharacterId == characterId,
        )
        .toList();
  }

  /// Returns the relationship between two specific characters, or null.
  CharacterRelationship? getBetween(String fromId, String toId) {
    return getAll()
        .where(
          (r) =>
              (r.fromCharacterId == fromId && r.toCharacterId == toId) ||
              (r.fromCharacterId == toId && r.toCharacterId == fromId),
        )
        .firstOrNull;
  }

  /// Adds a new relationship to the repository.
  ///
  /// Throws [StateError] if a relationship with the same ID already exists.
  Future<void> add(CharacterRelationship relationship) async {
    if (_box.containsKey(relationship.id)) {
      throw StateError('Relationship ${relationship.id} already exists');
    }
    await _box.put(relationship.id, relationship.toJson());
  }

  /// Updates an existing relationship in the repository.
  ///
  /// Throws [StateError] if no relationship with the given ID exists.
  Future<void> update(CharacterRelationship relationship) async {
    if (!_box.containsKey(relationship.id)) {
      throw StateError('Relationship ${relationship.id} not found');
    }
    await _box.put(relationship.id, relationship.toJson());
  }

  /// Deletes a relationship by its ID.
  ///
  /// Returns true if the relationship existed and was deleted.
  Future<bool> delete(String id) async {
    if (!_box.containsKey(id)) return false;
    await _box.delete(id);
    return true;
  }

  /// Deletes all relationships involving the given character ID.
  ///
  /// Returns the number of relationships deleted.
  Future<int> deleteForCharacter(String characterId) async {
    final toDelete = getForCharacter(characterId);
    for (final rel in toDelete) {
      await _box.delete(rel.id);
    }
    return toDelete.length;
  }
}
