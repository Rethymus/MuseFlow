import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_testing/hive_testing.dart';
import 'package:museflow/services/secure_storage_service.dart';
import 'package:museflow/services/secure_data_service.dart';
import 'package:museflow/models/app_state.dart';
import 'package:museflow/models/note.dart';

void main() {
  group('SecureStorageService Tests', () {
    late SecureStorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      Hive.registerAdapter(NoteAdapter());

      // Initialize secure service
      await SecureDataService.instance.initialize();

      // Initialize storage service
      storageService = SecureStorageService.instance;
      await storageService.initialize();
    });

    tearDownAll(() async {
      await storageService.close();
      await Hive.close();
    });

    group('Basic Operations', () {
      test('should save and retrieve notes with encryption', () async {
        const noteId = 'test-note-1';
        final note = Note(
          id: noteId,
          title: 'Encrypted Test Note',
          content: 'This content should be encrypted',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: ['test', 'encrypted'],
        );

        await storageService.saveNote(note);

        final retrievedNotes = await storageService.getAllNotes();
        final retrievedNote = retrievedNotes.firstWhere((n) => n.id == noteId);

        expect(retrievedNote.title, equals('Encrypted Test Note'));
        expect(retrievedNote.content, equals('This content should be encrypted'));
        expect(retrievedNote.tags, contains('test'));
      });

      test('should handle empty note list', () async {
        await storageService.clearAllData();

        final notes = await storageService.getAllNotes();

        expect(notes, isEmpty);
      });

      test('should delete notes', () async {
        const noteId = 'delete-test-note';
        final note = Note(
          id: noteId,
          title: 'Note to Delete',
          content: 'This will be deleted',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await storageService.saveNote(note);
        await storageService.deleteNote(noteId);

        final notes = await storageService.getAllNotes();
        expect(notes.any((n) => n.id == noteId), isFalse);
      });

      test('should update existing notes', () async {
        const noteId = 'update-test-note';
        final originalNote = Note(
          id: noteId,
          title: 'Original Title',
          content: 'Original content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await storageService.saveNote(originalNote);

        final updatedNote = Note(
          id: noteId,
          title: 'Updated Title',
          content: 'Updated content',
          createdAt: originalNote.createdAt,
          updatedAt: DateTime.now(),
        );

        await storageService.saveNote(updatedNote);

        final notes = await storageService.getAllNotes();
        final retrievedNote = notes.firstWhere((n) => n.id == noteId);

        expect(retrievedNote.title, equals('Updated Title'));
        expect(retrievedNote.content, equals('Updated content'));
      });
    });

    group('Batch Operations', () {
      test('should save multiple notes efficiently', () async {
        await storageService.clearAllData();

        final notes = List.generate(50, (i) => Note(
          id: 'batch-note-$i',
          title: 'Batch Note $i',
          content: 'Content for batch note $i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: ['batch', 'test'],
        ));

        final stopwatch = Stopwatch()..start();
        await storageService.bulkSaveNotes(notes);
        stopwatch.stop();

        final retrievedNotes = await storageService.getAllNotes();

        expect(retrievedNotes.length, equals(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should be fast
        expect(retrievedNotes.every((n) => n.tags.contains('batch')), isTrue);
      });

      test('should handle large batch operations', () async {
        await storageService.clearAllData();

        final notes = List.generate(200, (i) => Note(
          id: 'large-batch-$i',
          title: 'Large Batch Note $i',
          content: 'A' * 1000, // 1KB per note
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await storageService.bulkSaveNotes(notes);

        final retrievedNotes = await storageService.getAllNotes();

        expect(retrievedNotes.length, equals(200));
        expect(retrievedNotes.every((n) => n.content.length == 1000), isTrue);
      });
    });

    group('Search Operations', () {
      setUp(() async {
        await storageService.clearAllData();

        final notes = [
          Note(
            id: 'search-1',
            title: 'Search Test Note',
            content: 'Content about searching',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Note(
            id: 'search-2',
            title: 'Another Note',
            content: 'Search functionality is great',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Note(
            id: 'search-3',
            title: 'Unrelated Note',
            content: 'No search terms here',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await storageService.bulkSaveNotes(notes);
      });

      test('should search notes by content', () async {
        final results = await storageService.searchNotes('search');

        expect(results.length, greaterThan(0));
        expect(results.any((n) => n.content.contains('search')), isTrue);
      });

      test('should search notes by title', () async {
        final results = await storageService.searchNotes('Search Test');

        expect(results.length, equals(1));
        expect(results.first.title, equals('Search Test Note'));
      });

      test('should handle empty search queries', () async {
        final results = await storageService.searchNotes('');
        final allNotes = await storageService.getAllNotes();

        expect(results.length, equals(allNotes.length));
      });

      test('should return empty for non-existent terms', () async {
        final results = await storageService.searchNotes('nonexistentterm12345');

        expect(results, isEmpty);
      });
    });

    group('Tag Operations', () {
      setUp(() async {
        await storageService.clearAllData();

        final notes = [
          Note(
            id: 'tag-1',
            title: 'Work Note',
            content: 'Meeting notes',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: ['work', 'important'],
          ),
          Note(
            id: 'tag-2',
            title: 'Personal Note',
            content: 'Personal reminders',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: ['personal'],
          ),
          Note(
            id: 'tag-3',
            title: 'Another Work Note',
            content: 'Project updates',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: ['work', 'project'],
          ),
        ];

        await storageService.bulkSaveNotes(notes);
      });

      test('should get notes by tag', () async {
        final workNotes = await storageService.getNotesByTag('work');

        expect(workNotes.length, equals(2));
        expect(workNotes.every((n) => n.tags.contains('work')), isTrue);
      });

      test('should handle non-existent tags', () async {
        final results = await storageService.getNotesByTag('nonexistent');

        expect(results, isEmpty);
      });
    });

    group('Import/Export Operations', () {
      test('should export notes in plain text', () async {
        await storageService.clearAllData();

        final notes = [
          Note(
            id: 'export-1',
            title: 'Export Test Note',
            content: 'Content to export',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 2),
            tags: ['export'],
          ),
        ];

        await storageService.bulkSaveNotes(notes);

        final exported = await storageService.exportNotes();

        expect(exported.length, equals(1));
        expect(exported.first['title'], equals('Export Test Note'));
        expect(exported.first['content'], equals('Content to export'));
        expect(exported.first['tags'], contains('export'));
      });

      test('should import notes with encryption', () async {
        await storageService.clearAllData();

        final importData = [
          {
            'id': 'import-1',
            'title': 'Imported Note',
            'content': 'Imported content',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'tags': ['imported'],
          },
        ];

        await storageService.importNotes(importData);

        final notes = await storageService.getAllNotes();

        expect(notes.length, equals(1));
        expect(notes.first.title, equals('Imported Note'));
        expect(notes.first.content, equals('Imported content'));
        expect(notes.first.tags, contains('imported'));
      });

      test('should handle batch import', () async {
        await storageService.clearAllData();

        final importData = List.generate(20, (i) => {
          'id': 'import-batch-$i',
          'title': 'Batch Import $i',
          'content': 'Content $i',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'tags': ['batch-import'],
        });

        await storageService.importNotes(importData);

        final notes = await storageService.getAllNotes();

        expect(notes.length, equals(20));
        expect(notes.every((n) => n.tags.contains('batch-import')), isTrue);
      });
    });

    group('Settings Operations', () {
      test('should save and retrieve settings', () async {
        await storageService.setSetting('theme', 'dark');
        final theme = await storageService.getSetting('theme');

        expect(theme, equals('dark'));
      });

      test('should return default value for non-existent settings', () async {
        final value = await storageService.getSetting('nonexistent', defaultValue: 'default');

        expect(value, equals('default'));
      });

      test('should update existing settings', () async {
        await storageService.setSetting('font_size', '14');
        await storageService.setSetting('font_size', '16');

        final fontSize = await storageService.getSetting('font_size');

        expect(fontSize, equals('16'));
      });
    });

    group('Storage Statistics', () {
      test('should provide accurate statistics', () async {
        await storageService.clearAllData();

        final notes = List.generate(10, (i) => Note(
          id: 'stats-$i',
          title: 'Stats Note $i',
          content: 'Content $i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await storageService.bulkSaveNotes(notes);
        await storageService.setSetting('test', 'value');

        final stats = await storageService.getStorageStats();

        expect(stats['total_notes'], equals(10));
        expect(stats['encryption_enabled'], isTrue);
        expect(stats['settings_count'], greaterThan(0));
      });
    });

    group('Data Integrity', () {
      test('should maintain data consistency across operations', () async {
        const noteId = 'consistency-test';
        final originalNote = Note(
          id: noteId,
          title: 'Consistency Test',
          content: 'Testing data consistency',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: ['consistency', 'test'],
        );

        await storageService.saveNote(originalNote);

        // Retrieve multiple times to ensure consistency
        for (int i = 0; i < 5; i++) {
          final notes = await storageService.getAllNotes();
          final retrieved = notes.firstWhere((n) => n.id == noteId);

          expect(retrieved.title, equals(originalNote.title));
          expect(retrieved.content, equals(originalNote.content));
          expect(retrieved.tags, containsAll(originalNote.tags));
        }
      });

      test('should handle concurrent operations', () async {
        await storageService.clearAllData();

        // Create multiple concurrent save operations
        final futures = List.generate(20, (i) {
          return storageService.saveNote(Note(
            id: 'concurrent-$i',
            title: 'Concurrent Note $i',
            content: 'Content $i',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        });

        await Future.wait(futures);

        final notes = await storageService.getAllNotes();
        expect(notes.length, equals(20));
      });
    });

    group('Error Handling', () {
      test('should handle invalid note data gracefully', () async {
        // This test ensures the service can handle various edge cases
        final edgeCaseNotes = [
          Note(
            id: 'empty-note',
            title: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Note(
            id: 'long-content',
            title: 'A' * 500,
            content: 'B' * 10000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Note(
            id: 'special-chars',
            title: '!@#\$%^&*()',
            content: 'Special: \\n\\t\\r',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        for (final note in edgeCaseNotes) {
          await storageService.saveNote(note);
        }

        final notes = await storageService.getAllNotes();
        expect(notes.length, equals(3));
        expect(notes.any((n) => n.id == 'empty-note'), isTrue);
        expect(notes.any((n) => n.id == 'long-content'), isTrue);
        expect(notes.any((n) => n.id == 'special-chars'), isTrue);
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () async {
        await storageService.clearAllData();

        // Create 1000 notes
        final notes = List.generate(1000, (i) => Note(
          id: 'perf-$i',
          title: 'Performance Note $i',
          content: 'A' * 500, // 500 bytes per note
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final saveStopwatch = Stopwatch()..start();
        await storageService.bulkSaveNotes(notes);
        saveStopwatch.stop();

        final loadStopwatch = Stopwatch()..start();
        final loadedNotes = await storageService.getAllNotes();
        loadStopwatch.stop();

        expect(loadedNotes.length, equals(1000));
        expect(saveStopwatch.elapsedMilliseconds, lessThan(10000)); // < 10s for 1000 notes
        expect(loadStopwatch.elapsedMilliseconds, lessThan(5000)); // < 5s to load
      });

      test('should maintain performance with encryption overhead', () async {
        await storageService.clearAllData();

        const iterations = 100;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          await storageService.saveNote(Note(
            id: 'perf-enc-$i',
            title: 'Encryption Perf $i',
            content: 'Content' * 100, // 700 bytes
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }

        stopwatch.stop();

        // Average time per note should be reasonable (< 100ms per note)
        final avgTimePerNote = stopwatch.elapsedMilliseconds / iterations;
        expect(avgTimePerNote, lessThan(100));
      });
    });
  });
}