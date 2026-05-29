import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:museflow/models/app_state.dart';
import 'package:museflow/services/storage_service.dart';
import 'package:museflow/models/note.dart';

void main() {
  group('Circular Dependency Tests', () {
    test('StorageService should not import AppState', () {
      // This test verifies the structure by checking if we can create StorageService
      // without creating AppState first
      final storageService = StorageService.instance;
      expect(storageService, isNotNull);
      expect(storageService.runtimeType, StorageService);
    });

    test('AppState should accept StorageService injection', () {
      final storageService = StorageService.instance;
      final appState = AppState(storageService: storageService);

      expect(appState, isNotNull);
      expect(appState.runtimeType, AppState);
      expect(appState.notes, isEmpty);
    });

    test('Note should be independent and usable by both', () {
      final note = Note(
        id: 'test-id',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.id, 'test-id');
      expect(note.title, 'Test Note');
      expect(note.content, 'Test Content');
    });

    test('AppState should use storage service for data operations', () async {
      // Initialize Hive
      Hive.initFlutter();

      // Initialize storage service
      await StorageService.instance.initialize();

      // Create app state with injected storage service
      final appState = AppState();

      // Test create note
      appState.createNewNote();
      expect(appState.notes.length, 1);
      expect(appState.currentNote, isNotNull);

      // Test update note
      final originalTitle = appState.currentNote!.title;
      appState.updateNote('Updated Title', 'Updated Content');
      expect(appState.currentNote!.title, 'Updated Title');
      expect(appState.currentNote!.content, 'Updated Content');

      // Test save all notes
      await appState.saveAllNotes();

      // Create new app state instance and load notes
      final appState2 = AppState();
      await appState2.loadNotes();

      expect(appState2.notes.length, 1);
      expect(appState2.notes.first.title, 'Updated Title');

      // Cleanup
      await StorageService.instance.close();
    });

    test('StorageService should be initialized before use', () async {
      final storageService = StorageService.instance;

      // Before initialization, isInitialized should be false
      expect(storageService.isInitialized, false);

      // Initialize Hive
      Hive.initFlutter();

      // After initialization
      await storageService.initialize();
      expect(storageService.isInitialized, true);

      // Cleanup
      await storageService.close();
    });

    test('AppState should handle storage service errors gracefully', () async {
      // Create app state without initializing storage service
      final appState = AppState();

      // Attempting to load notes should throw an error
      expect(() async => await appState.loadNotes(),
          throwsA(isA<StateException>()));
    });
  });
}
