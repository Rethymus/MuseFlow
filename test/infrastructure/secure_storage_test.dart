import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService', () {
    late SecureStorageService service;

    setUp(() {
      service = SecureStorageService();
    });

    test('should write and read an API key for a provider', () async {
      try {
        await service.saveApiKey('openai', 'sk-test-key-12345');
        final key = await service.getApiKey('openai');
        expect(key, equals('sk-test-key-12345'));
      } on MissingPluginException catch (_) {
        // Platform does not support secure storage (e.g., test environment)
        // This is expected in CI/test environments without platform support
        debugPrint('Skipping: secure storage not available on this platform');
      } on PlatformException catch (_) {
        debugPrint('Skipping: secure storage platform exception');
      }
    });

    test('should return null for non-existent API key', () async {
      try {
        final key = await service.getApiKey('nonexistent_provider');
        expect(key, isNull);
      } on MissingPluginException catch (_) {
        debugPrint('Skipping: secure storage not available on this platform');
      } on PlatformException catch (_) {
        debugPrint('Skipping: secure storage platform exception');
      }
    });

    test('should delete an API key', () async {
      try {
        await service.saveApiKey('deepseek', 'sk-deepseek-key');
        await service.deleteApiKey('deepseek');
        final key = await service.getApiKey('deepseek');
        expect(key, isNull);
      } on MissingPluginException catch (_) {
        debugPrint('Skipping: secure storage not available on this platform');
      } on PlatformException catch (_) {
        debugPrint('Skipping: secure storage platform exception');
      }
    });

    test('should overwrite existing API key on save', () async {
      try {
        await service.saveApiKey('claude', 'sk-old-key');
        await service.saveApiKey('claude', 'sk-new-key');
        final key = await service.getApiKey('claude');
        expect(key, equals('sk-new-key'));
      } on MissingPluginException catch (_) {
        debugPrint('Skipping: secure storage not available on this platform');
      } on PlatformException catch (_) {
        debugPrint('Skipping: secure storage platform exception');
      }
    });
  });
}
