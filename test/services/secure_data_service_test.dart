import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/services/secure_data_service.dart';

void main() {
  late SecureDataService secureService;

  setUp(() async {
    secureService = SecureDataService.instance;
    // Note: In real tests, you might want to use dependency injection
    // to provide a mock secure storage. For simplicity, we're using
    // the real implementation which will generate test keys.
  });

  group('SecureDataService Initialization', () {
    test('should initialize successfully', () async {
      await secureService.initialize();

      final status = secureService.getStatus();
      expect(status['initialized'], isTrue);
      expect(status['algorithm'], 'AES-256-GCM');
      expect(status['key_size'], 32);
    });

    test('should have correct encryption parameters', () async {
      await secureService.initialize();

      final status = secureService.getStatus();
      expect(status['key_derivation'], 'PBKDF2-HMAC-SHA256');
      expect(status['iterations'], 10000);
      expect(status['iv_length'], 12);
    });
  });

  group('Data Encryption', () {
    setUp(() async {
      await secureService.initialize();
    });

    test('should encrypt plain text data', () {
      const plainText = 'This is a secret message';
      final encrypted = secureService.encrypt(plainText);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(plainText));
      expect(encrypted.length, greaterThan(20)); // Base64 encoded with IV
    });

    test('should decrypt encrypted data correctly', () {
      const plainText = 'Another secret message';
      final encrypted = secureService.encrypt(plainText);
      final decrypted = secureService.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('should handle unicode characters correctly', () {
      const plainText = '你好世界 🎵 MuseFlow';
      final encrypted = secureService.encrypt(plainText);
      final decrypted = secureService.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('should handle empty strings', () {
      const plainText = '';
      final encrypted = secureService.encrypt(plainText);
      final decrypted = secureService.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('should handle large text content', () {
      final plainText = 'A' * 10000; // 10KB of data
      final encrypted = secureService.encrypt(plainText);
      final decrypted = secureService.decrypt(encrypted);

      expect(decrypted, equals(plainText));
      expect(decrypted.length, equals(10000));
    });

    test('should handle special characters', () {
      const plainText = '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`';
      final encrypted = secureService.encrypt(plainText);
      final decrypted = secureService.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });
  });

  group('Note Data Encryption', () {
    setUp(() async {
      await secureService.initialize();
    });

    test('should encrypt note data with metadata', () {
      const noteId = 'test-note-123';
      const title = 'My Secret Note';
      const content = 'This is confidential content';

      final encrypted = secureService.encryptNoteData(
        noteId: noteId,
        title: title,
        content: content,
      );

      expect(encrypted, containsPair('title', isA<String>()));
      expect(encrypted, containsPair('content', isA<String>()));
      expect(encrypted, containsPair('algorithm', 'AES-256-GCM'));
      expect(encrypted, containsPair('created_at', isA<String>()));
      expect(encrypted['title'], isNot(equals(title)));
      expect(encrypted['content'], isNot(equals(content)));
    });

    test('should decrypt note data correctly', () {
      const noteId = 'test-note-456';
      const title = 'Important Note';
      const content = 'Confidential information here';

      final encrypted = secureService.encryptNoteData(
        noteId: noteId,
        title: title,
        content: content,
      );

      final decrypted = secureService.decryptNoteData(
        noteId: noteId,
        encryptedTitle: encrypted['title']!,
        encryptedContent: encrypted['content']!,
      );

      expect(decrypted['title'], equals(title));
      expect(decrypted['content'], equals(content));
    });

    test('should use data-specific salts for different notes', () {
      const note1Id = 'note-1';
      const note2Id = 'note-2';
      const content = 'Same content';

      final encrypted1 = secureService.encrypt(content, dataId: note1Id);
      final encrypted2 = secureService.encrypt(content, dataId: note2Id);

      // Same content should produce different ciphertext due to different salts
      expect(encrypted1, isNot(equals(encrypted2)));
    });

    test('should handle notes with long titles and content', () {
      const noteId = 'long-note';
      final title = 'A' * 200;
      final content = 'B' * 5000;

      final encrypted = secureService.encryptNoteData(
        noteId: noteId,
        title: title,
        content: content,
      );

      final decrypted = secureService.decryptNoteData(
        noteId: noteId,
        encryptedTitle: encrypted['title']!,
        encryptedContent: encrypted['content']!,
      );

      expect(decrypted['title'], equals(title));
      expect(decrypted['content'], equals(content));
      expect(decrypted['title']?.length, equals(200));
      expect(decrypted['content']?.length, equals(5000));
    });
  });

  group('Batch Operations', () {
    setUp(() async {
      await secureService.initialize();
    });

    test('should encrypt multiple notes efficiently', () {
      final notes = List.generate(
          100,
          (i) => {
                'id': 'note-$i',
                'title': 'Note $i Title',
                'content': 'Note $i Content',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'tags': <String>[],
              });

      final encryptedNotes = secureService.batchEncryptNotes(notes);

      expect(encryptedNotes.length, equals(100));
      expect(
          encryptedNotes.every((note) => note['is_encrypted'] == true), isTrue);
      expect(encryptedNotes.every((note) => note['title'] is String), isTrue);
      expect(encryptedNotes.every((note) => note['content'] is String), isTrue);
    });

    test('should decrypt multiple notes efficiently', () {
      final notes = List.generate(
          50,
          (i) => {
                'id': 'note-$i',
                'title': 'Original Title $i',
                'content': 'Original Content $i',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'tags': <String>[],
              });

      final encryptedNotes = secureService.batchEncryptNotes(notes);
      final decryptedNotes = secureService.batchDecryptNotes(encryptedNotes);

      expect(decryptedNotes.length, equals(50));

      for (int i = 0; i < 50; i++) {
        expect(decryptedNotes[i]['title'], equals('Original Title $i'));
        expect(decryptedNotes[i]['content'], equals('Original Content $i'));
        expect(decryptedNotes[i]['is_encrypted'], isFalse);
      }
    });

    test('should handle mixed encrypted and unencrypted data', () {
      final notes = [
        {
          'id': 'encrypted-1',
          'title': secureService.encrypt('Encrypted Title',
              dataId: 'encrypted-1_title'),
          'content': secureService.encrypt('Encrypted Content',
              dataId: 'encrypted-1_content'),
          'is_encrypted': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'plain-1',
          'title': 'Plain Title',
          'content': 'Plain Content',
          'is_encrypted': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];

      final decrypted = secureService.batchDecryptNotes(notes);

      expect(decrypted.length, equals(2));
      expect(decrypted[0]['title'], equals('Encrypted Title'));
      expect(decrypted[1]['title'], equals('Plain Title'));
    });
  });

  group('Security Features', () {
    setUp(() async {
      await secureService.initialize();
    });

    test('should throw SecurityException on invalid decryption', () {
      const invalidCipher = 'invalid-base64-data';

      expect(
        () => secureService.decrypt(invalidCipher),
        throwsA(isA<SecurityException>()),
      );
    });

    test('should verify encryption integrity', () {
      const originalText = 'Verify this text';
      final encrypted = secureService.encrypt(originalText);
      final isValid = secureService.verifyEncryption(originalText, encrypted);

      expect(isValid, isTrue);
    });

    test('should detect tampered data', () {
      const originalText = 'Original text';
      final encrypted = secureService.encrypt(originalText);

      // Tamper with the encrypted data
      final tampered = encrypted.substring(0, encrypted.length - 2) + 'XX';
      final isValid = secureService.verifyEncryption(originalText, tampered);

      expect(isValid, isFalse);
    });

    test('should generate unique salts for different operations', () {
      const sameText = 'Same text';
      final encrypted1 = secureService.encrypt(sameText, dataId: 'operation1');
      final encrypted2 = secureService.encrypt(sameText, dataId: 'operation2');

      expect(encrypted1, isNot(equals(encrypted2)));

      // Both should decrypt to the same original text
      expect(secureService.decrypt(encrypted1, dataId: 'operation1'),
          equals(sameText));
      expect(secureService.decrypt(encrypted2, dataId: 'operation2'),
          equals(sameText));
    });
  });

  group('Performance and Memory', () {
    setUp(() async {
      await secureService.initialize();
    });

    test('should handle batch encryption without memory leaks', () async {
      final notes = List.generate(
          1000,
          (i) => {
                'id': 'note-$i',
                'title': 'Performance Test Note $i',
                'content': 'A' * 1000, // 1KB per note
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'tags': <String>[],
              });

      final stopwatch = Stopwatch()..start();
      final encrypted = secureService.batchEncryptNotes(notes);
      stopwatch.stop();

      expect(encrypted.length, equals(1000));
      expect(stopwatch.elapsedMilliseconds,
          lessThan(5000)); // Should complete in < 5 seconds

      // Verify decryption works
      final decrypted = secureService.batchDecryptNotes(encrypted);
      expect(decrypted.length, equals(1000));
      expect(decrypted[0]['content']?.length, equals(1000));
    });

    test('should clear cache without affecting operations', () async {
      await secureService.initialize();

      // Perform operation before cache clear
      final encrypted1 = secureService.encrypt('Before cache clear');
      expect(secureService.decrypt(encrypted1), equals('Before cache clear'));

      // Clear cache
      secureService.clearCache();

      // Re-initialize should work
      await secureService.initialize();

      final encrypted2 = secureService.encrypt('After cache clear');
      expect(secureService.decrypt(encrypted2), equals('After cache clear'));
    });
  });

  group('Error Handling', () {
    test('should throw error when decrypting before initialization', () {
      final freshService = SecureDataService.instance;

      expect(
        () => freshService.decrypt('some-encrypted-data'),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw error when encrypting before initialization', () {
      final freshService = SecureDataService.instance;

      expect(
        () => freshService.encrypt('some data'),
        throwsA(isA<StateError>()),
      );
    });

    test('should handle malformed encrypted data gracefully', () async {
      await secureService.initialize();

      final malformedData = [
        '', // Empty
        'abc', // Too short
        'invalid!@#', // Invalid base64 characters
      ];

      for (final data in malformedData) {
        expect(
          () => secureService.decrypt(data),
          throwsA(isA<Exception>()),
        );
      }
    });
  });

  group('Key Management', () {
    setUp(() async {
      await secureService.initialize();
    });

    test('should regenerate keys successfully', () async {
      // Encrypt data with original keys
      const originalText = 'Data with original keys';
      final encrypted1 = secureService.encrypt(originalText);
      expect(secureService.decrypt(encrypted1), equals(originalText));

      // Regenerate keys
      await secureService.regenerateKeys();

      // Old data should no longer decrypt correctly
      expect(
        () => secureService.decrypt(encrypted1),
        throwsA(isA<Exception>()),
      );

      // New encryption should work with new keys
      final encrypted2 = secureService.encrypt(originalText);
      expect(secureService.decrypt(encrypted2), equals(originalText));
    });

    test('should maintain key consistency across operations', () async {
      await secureService.initialize();

      const testData = 'Consistency test data';
      final encrypted1 = secureService.encrypt(testData);
      final encrypted2 = secureService.encrypt(testData);

      // Same data with same default parameters might produce different ciphertext
      // due to random IV generation, but both should decrypt correctly
      expect(secureService.decrypt(encrypted1), equals(testData));
      expect(secureService.decrypt(encrypted2), equals(testData));
    });
  });

  group('Integration Tests', () {
    setUp(() async {
      await secureService.initialize();
    });

    test('should handle realistic note workflow', () async {
      // Simulate creating, updating, and accessing notes
      const noteId = 'realistic-note-123';

      // Create note
      final originalTitle = 'Initial Title';
      final originalContent = 'Initial content for the note';
      final encrypted1 = secureService.encryptNoteData(
        noteId: noteId,
        title: originalTitle,
        content: originalContent,
      );

      // Verify can decrypt
      final decrypted1 = secureService.decryptNoteData(
        noteId: noteId,
        encryptedTitle: encrypted1['title']!,
        encryptedContent: encrypted1['content']!,
      );
      expect(decrypted1['title'], equals(originalTitle));
      expect(decrypted1['content'], equals(originalContent));

      // Update note
      final updatedTitle = 'Updated Title';
      final updatedContent = 'Updated content with more information';
      final encrypted2 = secureService.encryptNoteData(
        noteId: noteId,
        title: updatedTitle,
        content: updatedContent,
      );

      // Verify updated content
      final decrypted2 = secureService.decryptNoteData(
        noteId: noteId,
        encryptedTitle: encrypted2['title']!,
        encryptedContent: encrypted2['content']!,
      );
      expect(decrypted2['title'], equals(updatedTitle));
      expect(decrypted2['content'], equals(updatedContent));
      expect(decrypted2['content'], isNot(contains(originalContent)));
    });

    test('should handle multi-language content', () async {
      await secureService.initialize();

      final multiLangContent = '''
English: Hello World
Chinese: 你好世界
Japanese: こんにちは世界
Korean: 안녕하세요 세계
Arabic: مرحبا بالعالم
Russian: Привет мир
Emoji: 🎵 🎶 🎼 🎹
Special: ∀∑∏∫√∞≈≠±×÷
''';

      final encrypted = secureService.encrypt(multiLangContent);
      final decrypted = secureService.decrypt(encrypted);

      expect(decrypted, equals(multiLangContent));
      expect(decrypted, contains('你好世界'));
      expect(decrypted, contains('🎵'));
      expect(decrypted, contains('∏'));
    });
  });
}
