import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';

/// Repository for managing AIProvider entities in a Hive box.
///
/// Persists provider configurations (excluding API keys) to a Hive box
/// named 'ai_providers'. API keys are stored separately in SecureStorage.
class ProviderRepository {
  final Box<dynamic> _box;
  final SecureStorageService _secureStorage;

  ProviderRepository(this._box, this._secureStorage);

  /// Saves a provider to the Hive box.
  Future<void> save(AIProvider provider) async {
    await _box.put(provider.id, provider.toJson());
  }

  /// Returns all saved providers.
  List<AIProvider> getAll() {
    return _box.values
        .map(
          (dynamic json) =>
              AIProvider.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
  }

  /// Deletes a provider by ID.
  ///
  /// Also removes the associated API key from secure storage.
  Future<void> delete(String id) async {
    await _secureStorage.deleteApiKey(id);
    await _box.delete(id);
  }

  /// Returns a single provider by ID, or null if not found.
  AIProvider? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return AIProvider.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
