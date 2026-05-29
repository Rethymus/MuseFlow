import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import 'base_storage_service.dart';

class StorageService implements BaseStorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  Box<Note>? _notesBox;
  Box<String>? _settingsBox;

  bool get isInitialized => _notesBox != null && _settingsBox != null;

  Future<void> initialize() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NoteAdapter());
    }

    // Open boxes
    _notesBox = await Hive.openBox<Note>('notes');
    _settingsBox = await Hive.openBox<String>('settings');

    // Load default settings if not exist
    if (!_settingsBox!.containsKey('theme')) {
      await _settingsBox!.put('theme', 'system');
    }
  }

  Future<List<Note>> getAllNotes() async {
    _ensureInitialized();
    return _notesBox!.values.toList();
  }

  Future<void> saveNote(Note note) async {
    _ensureInitialized();
    await _notesBox!.put(note.id, note);
  }

  Future<void> saveAllNotes(List<Note> notes) async {
    _ensureInitialized();
    await _notesBox!.clear();
    for (final note in notes) {
      await _notesBox!.put(note.id, note);
    }
  }

  Future<void> deleteNote(String noteId) async {
    _ensureInitialized();
    await _notesBox!.delete(noteId);
  }

  Future<String> getSetting(String key) async {
    _ensureInitialized();
    return _settingsBox!.get(key, defaultValue: 'system')!;
  }

  Future<void> setSetting(String key, String value) async {
    _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  Future<void> close() async {
    await _notesBox?.close();
    await _settingsBox?.close();
    await Hive.close();
  }

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }
}
