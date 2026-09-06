import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';

/// In-memory stand-in for [SecureStorageService] so the test never touches a
/// platform channel. Implements the public interface only.
class _InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> store = {};

  @override
  Future<String?> getApiKey(String providerId) async => store[providerId];

  @override
  Future<void> saveApiKey(String providerId, String key) async {
    store[providerId] = key;
  }

  @override
  Future<void> deleteApiKey(String providerId) async {
    store.remove(providerId);
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'museflow_settings_box_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'generates and persists an AES key when secure storage is empty',
    () async {
      final storage = _InMemorySecureStorage();

      final box = await openSettingsBox(storage);

      expect(Hive.isBoxOpen('settings'), isTrue);
      final stored = storage.store['hive_encryption_key'];
      expect(stored, isNotNull, reason: 'key must be persisted for reuse');
      expect(base64Decode(stored!), hasLength(32));

      // Encrypted box round-trips writes.
      await box.put('windowSize', {'width': 1200.0, 'height': 800.0});
      expect(box.get('windowSize'), {'width': 1200.0, 'height': 800.0});
    },
  );

  test('reuses the stored key instead of regenerating one', () async {
    final storage = _InMemorySecureStorage();
    // AES-256 cipher key: HiveAesCipher requires exactly 32 bytes.
    final existingBase64 = base64Encode(List<int>.filled(32, 7));
    storage.store['hive_encryption_key'] = existingBase64;

    final box = await openSettingsBox(storage);

    expect(
      storage.store['hive_encryption_key'],
      existingBase64,
      reason: 'an existing key must never be overwritten',
    );
    // The stored key must actually unlock the box for writes and reads.
    await box.put('windowSize', {'width': 1000.0, 'height': 700.0});
    expect(box.get('windowSize'), {'width': 1000.0, 'height': 700.0});
  });

  test('repeated calls return the already-open box instance', () async {
    final storage = _InMemorySecureStorage();

    final first = await openSettingsBox(storage);
    final second = await openSettingsBox(storage);

    expect(
      identical(first, second),
      isTrue,
      reason:
          'main() pre-opens the box; providers must reuse it, '
          'not open a second instance with a different cipher',
    );
  });

  test(
    'reduce-transparency preference round-trips the encrypted box',
    () async {
      final storage = _InMemorySecureStorage();
      final box = await openSettingsBox(storage);
      final repository = SettingsRepository(box);

      // Shipped default: glass ON.
      expect(repository.getReduceTransparency(), isFalse);

      await repository.saveReduceTransparency(true);
      expect(
        repository.getReduceTransparency(),
        isTrue,
        reason: 'the accessibility switch must survive an app restart',
      );

      // A fresh repository instance over the same (closed-and-reopened)
      // box simulates the next launch reading persisted state.
      await box.close();
      final reopened = await openSettingsBox(storage);
      final relaunched = SettingsRepository(reopened);
      expect(
        relaunched.getReduceTransparency(),
        isTrue,
        reason: 'value must be read back from encrypted storage, not memory',
      );

      await relaunched.saveReduceTransparency(false);
      expect(relaunched.getReduceTransparency(), isFalse);
    },
  );
}
