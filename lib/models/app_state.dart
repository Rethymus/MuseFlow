import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'note.dart';
import '../services/storage_service.dart';
import '../services/base_storage_service.dart';

class AppState extends ChangeNotifier {
  final BaseStorageService _storageService;
  final List<Note> _notes = [];
  Note? _currentNote;

  AppState({BaseStorageService? storageService})
      : _storageService = storageService ?? StorageService.instance;

  List<Note> get notes => _notes;
  Note? get currentNote => _currentNote;

  Future<void> loadNotes() async {
    try {
      final loadedNotes = await _storageService.getAllNotes();
      _notes.clear();
      _notes.addAll(loadedNotes);
      notifyListeners();
    } catch (e) {
      Logger.debug('Error loading notes: $e');
      rethrow;
    }
  }

  void createNewNote() {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Note',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notes.add(newNote);
    _currentNote = newNote;
    notifyListeners();
  }

  void selectNote(Note note) {
    _currentNote = note;
    notifyListeners();
  }

  void updateNote(String title, String content) {
    if (_currentNote != null) {
      _currentNote = _currentNote!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );

      // Update in list
      final index = _notes.indexWhere((n) => n.id == _currentNote!.id);
      if (index != -1) {
        _notes[index] = _currentNote!;
      }

      notifyListeners();
    }
  }

  Future<void> saveCurrentNote() async {
    if (_currentNote != null) {
      try {
        await _storageService.saveNote(_currentNote!);
        Logger.debug('Note saved: ${_currentNote!.id}');
      } catch (e) {
        Logger.debug('Error saving note: $e');
        rethrow;
      }
    }
  }

  Future<void> saveAllNotes() async {
    try {
      await _storageService.saveAllNotes(_notes);
      Logger.debug('All notes saved');
    } catch (e) {
      Logger.debug('Error saving notes: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _storageService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      if (_currentNote?.id == noteId) {
        _currentNote = null;
      }
      notifyListeners();
      Logger.debug('Note deleted: $noteId');
    } catch (e) {
      Logger.debug('Error deleting note: $e');
      rethrow;
    }
  }

  Future<void> saveBeforeExit() async {
    try {
      await saveAllNotes();
      await _storageService.close();
      Logger.debug('Application saved and closed successfully');
    } catch (e) {
      Logger.debug('Error during save before exit: $e');
      rethrow;
    }
  }

  // 设置相关方法
  Future<String> getSetting(String key) async {
    return await _storageService.getSetting(key);
  }

  Future<void> setSetting(String key, String value) async {
    await _storageService.setSetting(key, value);
  }
}
