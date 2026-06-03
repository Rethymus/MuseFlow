import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing [CharacterCard] entities in a Hive box.
///
/// Provides CRUD operations with search-by-name functionality.
/// All operations are wrapped in error handling to prevent silent failures.
class CharacterCardRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  CharacterCardRepository(this._box);

  /// Adds a new character card to the box.
  ///
  /// If the card has an empty [id], a new UUID is generated.
  /// Sets [createdAt] to now if not already set.
  /// Returns the card with ID and timestamps assigned.
  /// Throws [StateError] if the write fails.
  Future<CharacterCard> add(CharacterCard card) async {
    try {
      final id = card.id.isEmpty ? _uuid.v4() : card.id;
      final now = DateTime.now();
      final newCard = CharacterCard(
        id: id,
        name: card.name,
        personality: card.personality,
        appearance: card.appearance,
        backstory: card.backstory,
        aliases: card.aliases,
        createdAt: now,
      );
      await _box.put(id, newCard.toJson());
      return newCard;
    } catch (e) {
      throw StateError('Failed to save character card: $e');
    }
  }

  /// Returns all character cards in the box.
  List<CharacterCard> getAll() {
    try {
      return _box.values
          .map((json) => CharacterCard.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StateError('Failed to read character cards: $e');
    }
  }

  /// Returns a character card by its ID, or null if not found.
  CharacterCard? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return CharacterCard.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read character card $id: $e');
    }
  }

  /// Updates an existing character card.
  ///
  /// Sets [updatedAt] to the current time before persisting.
  /// Throws [StateError] if the write fails.
  Future<void> update(CharacterCard card) async {
    try {
      final updated = card.copyWith(updatedAt: DateTime.now());
      await _box.put(card.id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update character card ${card.id}: $e');
    }
  }

  /// Deletes a character card by its ID.
  ///
  /// Does not throw if the ID does not exist.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete character card $id: $e');
    }
  }

  /// Searches character cards by name substring (case-insensitive).
  ///
  /// Matches against both [name] and all [aliases].
  List<CharacterCard> searchByName(String query) {
    try {
      final lowerQuery = query.toLowerCase();
      return getAll().where((card) {
        if (card.name.toLowerCase().contains(lowerQuery)) return true;
        return card.aliases
            .any((alias) => alias.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      throw StateError('Failed to search character cards: $e');
    }
  }
}
