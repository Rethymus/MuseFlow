import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing [WorldSetting] entities in a Hive box.
///
/// Provides CRUD operations with search-by-name functionality.
/// All operations are wrapped in error handling to prevent silent failures.
class WorldSettingRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  WorldSettingRepository(this._box);

  /// Adds a new world setting to the box.
  ///
  /// If the setting has an empty [id], a new UUID is generated.
  /// Sets [createdAt] to now if not already set.
  /// Returns the setting with ID and timestamps assigned.
  /// Throws [StateError] if the write fails.
  Future<WorldSetting> add(WorldSetting setting) async {
    try {
      final id = setting.id.isEmpty ? _uuid.v4() : setting.id;
      final now = DateTime.now();
      final newSetting = WorldSetting(
        id: id,
        name: setting.name,
        description: setting.description,
        rules: setting.rules,
        factions: setting.factions,
        geography: setting.geography,
        techLevel: setting.techLevel,
        aliases: setting.aliases,
        createdAt: now,
      );
      await _box.put(id, newSetting.toJson());
      return newSetting;
    } catch (e) {
      throw StateError('Failed to save world setting: $e');
    }
  }

  /// Returns all world settings in the box.
  List<WorldSetting> getAll() {
    try {
      return _box.values
          .map((json) => WorldSetting.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StateError('Failed to read world settings: $e');
    }
  }

  /// Returns a world setting by its ID, or null if not found.
  WorldSetting? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return WorldSetting.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read world setting $id: $e');
    }
  }

  /// Updates an existing world setting.
  ///
  /// Sets [updatedAt] to the current time before persisting.
  /// Throws [StateError] if the write fails.
  Future<void> update(WorldSetting setting) async {
    try {
      final updated = setting.copyWith(updatedAt: DateTime.now());
      await _box.put(setting.id, updated.toJson());
    } catch (e) {
      throw StateError('Failed to update world setting ${setting.id}: $e');
    }
  }

  /// Deletes a world setting by its ID.
  ///
  /// Does not throw if the ID does not exist.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete world setting $id: $e');
    }
  }

  /// Searches world settings by name substring (case-insensitive).
  ///
  /// Matches against both [name] and all [aliases].
  List<WorldSetting> searchByName(String query) {
    try {
      final lowerQuery = query.toLowerCase();
      return getAll().where((setting) {
        if (setting.name.toLowerCase().contains(lowerQuery)) return true;
        return setting.aliases
            .any((alias) => alias.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      throw StateError('Failed to search world settings: $e');
    }
  }
}
