import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';

/// AsyncNotifier managing the list of [CharacterCard] entities.
///
/// Loads cards from [CharacterCardRepository] on build, exposes
/// [AsyncValue] for the presentation layer. CRUD methods delegate
/// to the repository and refresh state via [ref.invalidateSelf].
class CharacterCardNotifier extends AsyncNotifier<List<CharacterCard>> {
  @override
  Future<List<CharacterCard>> build() async {
    final repository = await ref.watch(characterCardRepositoryProvider.future);
    return repository.getAll();
  }

  /// Adds a new character card and refreshes the state.
  Future<void> add(CharacterCard card) async {
    final repository = await ref.read(characterCardRepositoryProvider.future);
    await repository.add(card);
    ref.invalidateSelf();
  }

  /// Updates an existing character card and refreshes the state.
  Future<void> save(CharacterCard card) async {
    final repository = await ref.read(characterCardRepositoryProvider.future);
    await repository.update(card);
    ref.invalidateSelf();
  }

  /// Deletes a character card by ID and refreshes the state.
  Future<void> delete(String id) async {
    final repository = await ref.read(characterCardRepositoryProvider.future);
    await repository.delete(id);
    ref.invalidateSelf();
  }

  /// Filters the current state by a name substring query.
  ///
  /// Searches both name and aliases (case-insensitive).
  /// Returns an empty list if state is not loaded.
  List<CharacterCard> searchByName(String query) {
    final cards = state.asData?.value ?? [];
    final lowerQuery = query.toLowerCase();
    return cards.where((card) {
      if (card.name.toLowerCase().contains(lowerQuery)) return true;
      return card.aliases.any(
        (alias) => alias.toLowerCase().contains(lowerQuery),
      );
    }).toList();
  }
}
