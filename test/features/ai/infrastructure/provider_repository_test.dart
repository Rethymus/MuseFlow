import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('ProviderRepository', () {
    late Box<dynamic> box;
    late ProviderRepository repository;

    setUp(() async {
      await setUpHiveTest();
      box = await Hive.openBox<dynamic>('ai_providers_test');
      // Use a mock SecureStorageService that stores in memory
      repository = ProviderRepository(box, _InMemorySecureStorage());
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    final testProvider = AIProvider(
      id: 'test-provider-1',
      name: 'Test Provider',
      baseUrl: 'https://api.test.com/v1',
      type: AiProviderType.openai,
      model: 'gpt-4o-mini',
      createdAt: DateTime(2026, 6, 2),
    );

    test('should save and retrieve a provider', () async {
      await repository.save(testProvider);
      final retrieved = repository.getById('test-provider-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, testProvider.id);
      expect(retrieved.name, testProvider.name);
      expect(retrieved.baseUrl, testProvider.baseUrl);
      expect(retrieved.type, testProvider.type);
      expect(retrieved.model, testProvider.model);
    });

    test('should return all saved providers', () async {
      await repository.save(testProvider);
      final provider2 = AIProvider(
        id: 'test-provider-2',
        name: 'Second Provider',
        baseUrl: 'https://api.deepseek.com/v1',
        type: AiProviderType.deepseek,
        model: 'deepseek-chat',
        createdAt: DateTime(2026, 6, 2),
      );
      await repository.save(provider2);

      final all = repository.getAll();
      expect(all.length, 2);
      expect(all.any((p) => p.id == 'test-provider-1'), true);
      expect(all.any((p) => p.id == 'test-provider-2'), true);
    });

    test('should return empty list when no providers saved', () {
      final all = repository.getAll();
      expect(all, isEmpty);
    });

    test('should delete a provider by ID', () async {
      await repository.save(testProvider);
      expect(repository.getAll().length, 1);

      await repository.delete('test-provider-1');
      expect(repository.getAll(), isEmpty);
      expect(repository.getById('test-provider-1'), isNull);
    });

    test('should return null for non-existent provider', () {
      final result = repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('should update existing provider on save', () async {
      await repository.save(testProvider);
      final updated = testProvider.copyWith(name: 'Updated Name');
      await repository.save(updated);

      final retrieved = repository.getById('test-provider-1');
      expect(retrieved!.name, 'Updated Name');
    });
  });
}

/// In-memory implementation of SecureStorageService for testing.
/// Avoids platform channel dependency in test environment.
class _InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> saveApiKey(String providerId, String key) async {
    _store[providerId] = key;
  }

  @override
  Future<String?> getApiKey(String providerId) async {
    return _store[providerId];
  }

  @override
  Future<void> deleteApiKey(String providerId) async {
    _store.remove(providerId);
  }
}
