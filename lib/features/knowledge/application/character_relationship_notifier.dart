/// AsyncNotifier for managing [CharacterRelationship] entities.
///
/// Per Phase 21 (KNOW-02): Provides CRUD operations for character
/// relationships, including querying by character ID. State is the
/// full list of relationships for the current manuscript.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/character_relationship.dart';

/// Notifier for character relationship lifecycle management.
class CharacterRelationshipNotifier
    extends AsyncNotifier<List<CharacterRelationship>> {
  @override
  Future<List<CharacterRelationship>> build() async {
    final repository = await ref.watch(
      characterRelationshipRepositoryProvider.future,
    );
    return repository.getAll();
  }

  /// Adds a new relationship and refreshes state.
  Future<void> add(CharacterRelationship relationship) async {
    final repository = await ref.read(
      characterRelationshipRepositoryProvider.future,
    );
    await repository.add(relationship);
    ref.invalidateSelf();
  }

  /// Saves an existing relationship and refreshes state.
  Future<void> save(CharacterRelationship relationship) async {
    final repository = await ref.read(
      characterRelationshipRepositoryProvider.future,
    );
    await repository.update(relationship);
    ref.invalidateSelf();
  }

  /// Deletes a relationship by ID and refreshes state.
  Future<void> delete(String id) async {
    final repository = await ref.read(
      characterRelationshipRepositoryProvider.future,
    );
    await repository.delete(id);
    ref.invalidateSelf();
  }

  /// Returns relationships involving the given character.
  ///
  /// Works on in-memory state, so it works even when async state
  /// is still loading (returns empty in that case).
  List<CharacterRelationship> getForCharacter(String characterId) {
    final relationships = state.asData?.value ?? [];
    return relationships
        .where(
          (r) =>
              r.fromCharacterId == characterId ||
              r.toCharacterId == characterId,
        )
        .toList();
  }
}
