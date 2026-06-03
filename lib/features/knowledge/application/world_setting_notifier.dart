import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';

/// AsyncNotifier managing the list of [WorldSetting] entities.
///
/// Loads settings from [WorldSettingRepository] on build, exposes
/// [AsyncValue] for the presentation layer. CRUD methods delegate
/// to the repository and refresh state via [ref.invalidateSelf].
class WorldSettingNotifier extends AsyncNotifier<List<WorldSetting>> {
  @override
  Future<List<WorldSetting>> build() async {
    final repository =
        await ref.watch(worldSettingRepositoryProvider.future);
    return repository.getAll();
  }

  /// Adds a new world setting and refreshes the state.
  Future<void> add(WorldSetting setting) async {
    final repository =
        await ref.read(worldSettingRepositoryProvider.future);
    await repository.add(setting);
    ref.invalidateSelf();
  }

  /// Updates an existing world setting and refreshes the state.
  Future<void> save(WorldSetting setting) async {
    final repository =
        await ref.read(worldSettingRepositoryProvider.future);
    await repository.update(setting);
    ref.invalidateSelf();
  }

  /// Deletes a world setting by ID and refreshes the state.
  Future<void> delete(String id) async {
    final repository =
        await ref.read(worldSettingRepositoryProvider.future);
    await repository.delete(id);
    ref.invalidateSelf();
  }

  /// Filters the current state by a name substring query.
  ///
  /// Searches both name and aliases (case-insensitive).
  /// Returns an empty list if state is not loaded.
  List<WorldSetting> searchByName(String query) {
    final settings = state.asData?.value ?? [];
    final lowerQuery = query.toLowerCase();
    return settings.where((setting) {
      if (setting.name.toLowerCase().contains(lowerQuery)) return true;
      return setting.aliases
          .any((alias) => alias.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
