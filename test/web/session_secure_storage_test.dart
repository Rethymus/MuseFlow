@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:web/web.dart' as web;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    web.window.localStorage.clear();
    web.window.sessionStorage.clear();
  });

  tearDown(() {
    web.window.localStorage.clear();
    web.window.sessionStorage.clear();
  });

  test('provider keys use sessionStorage and not localStorage', () async {
    final service = SecureStorageService();

    await service.saveApiKey('browser-provider', 'sk-browser-session');

    expect(
      web.window.sessionStorage.getItem(
        'FlutterSecureStorage.api_key_browser-provider',
      ),
      isNotNull,
    );
    expect(
      web.window.localStorage.getItem(
        'FlutterSecureStorage.api_key_browser-provider',
      ),
      isNull,
    );
    expect(await service.getApiKey('browser-provider'), 'sk-browser-session');
  });

  test(
    'settings encryption key remains persistent outside temporary mode',
    () async {
      final service = SecureStorageService();

      await service.saveApiKey(
        'hive_encryption_key',
        'persistent-settings-key',
      );

      expect(
        web.window.localStorage.getItem(
          'FlutterSecureStorage.api_key_hive_encryption_key',
        ),
        isNotNull,
      );
      expect(
        web.window.sessionStorage.getItem(
          'FlutterSecureStorage.api_key_hive_encryption_key',
        ),
        isNull,
      );
    },
  );
}
