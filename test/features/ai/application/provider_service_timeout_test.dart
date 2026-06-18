// Regression test for the OpenAI/GLM connection-test timeout (quick-260618-wjh).
//
// Real-API validation (with a live GLM key, AiProviderType.openai) surfaced that
// `ProviderService._testOpenAIConnection` constructed the client via
// `OpenAIClient.withApiKey`, whose OpenAIConfig default `timeout` is
// `Duration(minutes: 10)` (openai_dart config.dart). A user clicking "Test
// Connection" against a dead/slow baseUrl would therefore hang for up to ten
// minutes, while the Claude path returned in 30s. This test pins the fix: the
// connection test must respect an injected (bounded) timeout, not the 10-minute
// default.
//
// Uses [setUpHiveForNetworkTest] (NOT setUpHiveTest) so flutter_test's HTTP
// mock is never installed and the black-hole ServerSocket receives a genuine
// connection — mirroring the real-API test isolation pattern in
// chapter_summary_refresh_service_real_glm_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/features/ai/application/provider_service.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('ProviderService.testConnection timeout', () {
    late Box<dynamic> box;
    late _InMemorySecureStorage secureStorage;
    late ProviderRepository repository;
    late ProviderService service;

    setUp(() async {
      await setUpHiveForNetworkTest();
      box = await Hive.openBox<dynamic>('ai_providers_timeout_test');
      secureStorage = _InMemorySecureStorage();
      repository = ProviderRepository(box, secureStorage);
      service = ProviderService(repository, secureStorage);
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test(
      'OpenAI/GLM path bounds the connection test by the injected timeout, not '
      'the 10-minute default (black-hole server)',
      () async {
        // Black-hole server: accepts the TCP connection but never sends an HTTP
        // response. Before the fix the client waited OpenAIConfig's default
        // Duration(minutes: 10); after the fix the injected 1s timeout fires and
        // the stall is classified as AINetworkException.
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final sub = server.listen((socket) {
          // Accept and hold the connection open without ever responding.
        });

        final stopwatch = Stopwatch()..start();
        try {
          await service.testConnection(
            apiKey: 'black-hole-key',
            baseUrl: 'http://${server.address.host}:${server.port}/v1',
            type: AiProviderType.openai,
            model: 'gpt-4o-mini',
            timeout: const Duration(seconds: 1),
          );
          fail('testConnection should throw on a non-responsive server');
        } on AINetworkException {
          // Expected — the bounded timeout surfaced as a network error.
        } finally {
          stopwatch.stop();
          await sub.cancel();
          await server.close();
        }

        // Proves the 1s injected timeout fired, not the 10-minute default.
        expect(
          stopwatch.elapsed,
          lessThan(const Duration(seconds: 15)),
          reason: 'connection test must respect the injected timeout, not the '
              '10-minute OpenAI default',
        );
      },
    );
  });
}

/// In-memory implementation of SecureStorageService for testing (mirrors the
/// one in provider_service_test.dart).
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
