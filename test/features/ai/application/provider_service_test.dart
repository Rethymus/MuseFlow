import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/features/ai/application/provider_service.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('ProviderService', () {
    late Box<dynamic> box;
    late _InMemorySecureStorage secureStorage;
    late ProviderRepository repository;
    late ProviderService service;

    setUp(() async {
      await setUpHiveTest();
      box = await Hive.openBox<dynamic>('ai_providers_test');
      secureStorage = _InMemorySecureStorage();
      repository = ProviderRepository(box, secureStorage);
      service = ProviderService(repository, secureStorage);
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test('should create a provider and save API key', () async {
      final provider = await service.createProvider(
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        apiKey: 'sk-test-key',
      );

      expect(provider.name, 'OpenAI');
      expect(provider.baseUrl, 'https://api.openai.com/v1');
      expect(provider.type, AiProviderType.openai);
      expect(provider.model, 'gpt-4o-mini');
      expect(provider.isActive, false);
      expect(provider.id, isNotEmpty);

      // Verify API key was saved
      final apiKey = await secureStorage.getApiKey(provider.id);
      expect(apiKey, 'sk-test-key');

      // Verify provider was persisted
      final saved = repository.getById(provider.id);
      expect(saved, isNotNull);
    });

    test('should never persist API keys in the provider Hive box', () async {
      const originalKey = 'sk-secret-that-must-not-enter-hive';
      const rotatedKey = 'sk-rotated-secret-that-must-not-enter-hive';

      final provider = await service.createProvider(
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        apiKey: originalKey,
      );

      final rawAfterCreate = Map<String, dynamic>.from(
        box.get(provider.id) as Map,
      );
      expect(rawAfterCreate.containsKey('apiKey'), isFalse);
      expect(rawAfterCreate.containsKey('key'), isFalse);
      expect(rawAfterCreate.values, isNot(contains(originalKey)));

      await service.updateApiKey(provider.id, rotatedKey);

      final rawAfterRotation = Map<String, dynamic>.from(
        box.get(provider.id) as Map,
      );
      expect(rawAfterRotation.containsKey('apiKey'), isFalse);
      expect(rawAfterRotation.containsKey('key'), isFalse);
      expect(rawAfterRotation.values, isNot(contains(originalKey)));
      expect(rawAfterRotation.values, isNot(contains(rotatedKey)));
      expect(await secureStorage.getApiKey(provider.id), rotatedKey);
    });

    test(
      'does not persist provider metadata when API key save fails',
      () async {
        final failingStorage = _FailingSaveSecureStorage();
        final failingRepository = ProviderRepository(box, failingStorage);
        final failingService = ProviderService(
          failingRepository,
          failingStorage,
        );

        await expectLater(
          failingService.createProvider(
            name: 'OpenAI',
            baseUrl: 'https://api.openai.com/v1',
            type: AiProviderType.openai,
            model: 'gpt-4o-mini',
            apiKey: 'sk-unavailable-storage',
          ),
          throwsA(isA<StateError>()),
        );

        expect(failingRepository.getAll(), isEmpty);
        expect(box.values, isEmpty);
      },
    );

    test('removes API key if provider metadata save fails', () async {
      final cleanupStorage = _InMemorySecureStorage();
      final failingRepository = _FailingSaveProviderRepository(
        box,
        cleanupStorage,
      );
      final failingService = ProviderService(failingRepository, cleanupStorage);

      await expectLater(
        failingService.createProvider(
          name: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          type: AiProviderType.openai,
          model: 'gpt-4o-mini',
          apiKey: 'sk-cleanup-on-failure',
        ),
        throwsA(isA<StateError>()),
      );

      expect(cleanupStorage._store, isEmpty);
      expect(box.values, isEmpty);
    });

    test(
      'preserves metadata save error when API key cleanup also fails',
      () async {
        final cleanupStorage = _FailingDeleteSecureStorage();
        final failingRepository = _FailingSaveProviderRepository(
          box,
          cleanupStorage,
        );
        final failingService = ProviderService(
          failingRepository,
          cleanupStorage,
        );

        await expectLater(
          failingService.createProvider(
            name: 'OpenAI',
            baseUrl: 'https://api.openai.com/v1',
            type: AiProviderType.openai,
            model: 'gpt-4o-mini',
            apiKey: 'sk-cleanup-delete-fails',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'metadata storage unavailable',
            ),
          ),
        );

        expect(
          cleanupStorage._store.values,
          contains('sk-cleanup-delete-fails'),
        );
        expect(box.values, isEmpty);
      },
    );

    test('should update an existing provider', () async {
      final provider = await service.createProvider(
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4',
        apiKey: 'sk-key',
      );

      final updated = provider.copyWith(name: 'Updated');
      await service.updateProvider(updated);

      final retrieved = repository.getById(provider.id);
      expect(retrieved!.name, 'Updated');
    });

    test('should delete a provider and its API key', () async {
      final provider = await service.createProvider(
        name: 'ToDelete',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.custom,
        model: 'model',
        apiKey: 'sk-delete-key',
      );

      await service.deleteProvider(provider.id);

      expect(repository.getById(provider.id), isNull);
      final apiKey = await secureStorage.getApiKey(provider.id);
      expect(apiKey, isNull);
    });

    test('preserves provider metadata when API key deletion fails', () async {
      final failingDeleteStorage = _FailingDeleteSecureStorage();
      final retryableRepository = ProviderRepository(box, failingDeleteStorage);
      final retryableService = ProviderService(
        retryableRepository,
        failingDeleteStorage,
      );

      final provider = await retryableService.createProvider(
        name: 'RetryableDelete',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.custom,
        model: 'model',
        apiKey: 'sk-delete-retry-key',
      );

      await expectLater(
        retryableService.deleteProvider(provider.id),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'secure storage delete unavailable',
          ),
        ),
      );

      expect(retryableRepository.getById(provider.id), isNotNull);
      expect(
        await failingDeleteStorage.getApiKey(provider.id),
        'sk-delete-retry-key',
      );
    });

    test('should set active provider and deactivate others', () async {
      final p1 = await service.createProvider(
        name: 'First',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4',
        apiKey: 'sk-key1',
      );
      final p2 = await service.createProvider(
        name: 'Second',
        baseUrl: 'https://api.test2.com/v1',
        type: AiProviderType.deepseek,
        model: 'deepseek-chat',
        apiKey: 'sk-key2',
      );

      // Activate first provider
      await service.setActiveProvider(p1.id);
      expect(repository.getById(p1.id)!.isActive, true);
      expect(repository.getById(p2.id)!.isActive, false);

      // Activate second provider -- first should deactivate
      await service.setActiveProvider(p2.id);
      expect(repository.getById(p1.id)!.isActive, false);
      expect(repository.getById(p2.id)!.isActive, true);
    });

    test('should return all providers', () async {
      await service.createProvider(
        name: 'P1',
        baseUrl: 'https://p1.com/v1',
        type: AiProviderType.openai,
        model: 'm1',
        apiKey: 'k1',
      );
      await service.createProvider(
        name: 'P2',
        baseUrl: 'https://p2.com/v1',
        type: AiProviderType.deepseek,
        model: 'm2',
        apiKey: 'k2',
      );

      final all = service.getAllProviders();
      expect(all.length, 2);
    });

    test('should return the active provider', () async {
      final p = await service.createProvider(
        name: 'Active',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4',
        apiKey: 'sk-key',
      );

      expect(service.getActiveProvider(), isNull);

      await service.setActiveProvider(p.id);
      final active = service.getActiveProvider();
      expect(active, isNotNull);
      expect(active!.id, p.id);
    });

    test('should return null active provider when none active', () {
      expect(service.getActiveProvider(), isNull);
    });

    test('should retrieve API key for a provider', () async {
      final provider = await service.createProvider(
        name: 'KeyTest',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4',
        apiKey: 'sk-my-secret-key',
      );

      final apiKey = await service.getApiKey(provider.id);
      expect(apiKey, 'sk-my-secret-key');
    });

    test('does not create orphan API keys for missing providers', () async {
      await expectLater(
        service.updateApiKey('missing-provider', 'sk-orphan-key'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('provider not found'),
          ),
        ),
      );

      expect(await service.getApiKey('missing-provider'), isNull);
      expect(secureStorage._store, isEmpty);
    });

    test(
      'testConnection should accept type parameter for all provider types',
      () async {
        final types = AiProviderType.values;
        for (final type in types) {
          try {
            await service.testConnection(
              apiKey: 'test-key',
              baseUrl: 'https://api.example.com/v1',
              type: type,
              model: 'test-model',
            );
          } on AINetworkException {
            // Expected — no real server running in tests
          } catch (_) {
            // Other network errors are acceptable in test environment
          }
        }
      },
    );
  });

  group('AIException', () {
    test('AIAuthException has correct user message', () {
      const exc = AIAuthException();
      expect(exc.userMessage, 'API Key 无效，请检查设置');
    });

    test('AIRateLimitException has correct user message', () {
      const exc = AIRateLimitException();
      expect(exc.userMessage, '请求太快，请稍后再试');
    });

    test('AINetworkException has correct user message', () {
      const exc = AINetworkException();
      expect(exc.userMessage, '网络连接失败');
    });

    test('AIStreamException has correct user message', () {
      const exc = AIStreamException();
      expect(exc.userMessage, '生成中断，可继续编辑或重试');
    });

    test('exceptions are sealed -- can be exhaustively switched', () {
      final exceptions = <AIException>[
        const AIAuthException(),
        const AIRateLimitException(),
        const AINetworkException(),
        const AIStreamException(),
      ];

      for (final exc in exceptions) {
        final message = switch (exc) {
          AIAuthException() => exc.userMessage,
          AIRateLimitException() => exc.userMessage,
          AINetworkException() => exc.userMessage,
          AIStreamException() => exc.userMessage,
        };
        expect(message, isNotEmpty);
      }
    });
  });
}

/// In-memory implementation of SecureStorageService for testing.
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

class _FailingSaveSecureStorage extends _InMemorySecureStorage {
  @override
  Future<void> saveApiKey(String providerId, String key) async {
    throw StateError('secure storage unavailable');
  }
}

class _FailingDeleteSecureStorage extends _InMemorySecureStorage {
  @override
  Future<void> deleteApiKey(String providerId) async {
    throw StateError('secure storage delete unavailable');
  }
}

class _FailingSaveProviderRepository extends ProviderRepository {
  _FailingSaveProviderRepository(super.box, super.secureStorage);

  @override
  Future<void> save(AIProvider provider) async {
    throw StateError('metadata storage unavailable');
  }
}
