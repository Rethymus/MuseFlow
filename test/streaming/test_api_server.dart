/// flutter_secure_storage verification test for Windows.
///
/// Validates TECH-04: API key secure storage on Windows.
/// Tests the write/read/delete cycle with flutter_secure_storage
/// to ensure API keys can be safely stored and retrieved.
///
/// Note: This test requires a real platform (Windows desktop with
/// Credential Manager). In test environments without a platform
/// implementation, the test SKIPS gracefully.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Secure Storage', () {
    test(
      'write, read, and delete a test value',
      () async {
        const storage = FlutterSecureStorage();
        const testKey = 'museflow_test_api_key';
        const testValue = 'sk-test-key-12345';

        try {
          // Write
          await storage.write(key: testKey, value: testValue);

          // Read back
          final readValue = await storage.read(key: testKey);
          expect(
            readValue,
            equals(testValue),
            reason: 'Read value should match written value',
          );

          // Delete
          await storage.delete(key: testKey);

          // Verify deleted
          final deletedValue = await storage.read(key: testKey);
          expect(
            deletedValue,
            isNull,
            reason: 'Value should be null after deletion',
          );

          // ignore: avoid_print
          print('--- Secure Storage Test ---');
          // ignore: avoid_print
          print('Platform: ${Platform.operatingSystem}');
          // ignore: avoid_print
          print('Write/Read/Delete cycle: PASS');
        } on MissingPluginException catch (_) {
          // Platform implementation not available in test environment
          // (e.g., running in WSL2 without Windows GUI). This is expected.
          markTestSkipped(
            'flutter_secure_storage platform plugin not available. '
            'Run on a real Windows desktop to validate TECH-04.',
          );
          return;
        } on PlatformException catch (e) {
          // Some platforms throw PlatformException if secure storage
          // is not configured (e.g., Linux without libsecret).
          markTestSkipped(
            'flutter_secure_storage platform error: ${e.message}. '
            'Run on a real Windows desktop to validate TECH-04.',
          );
          return;
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
