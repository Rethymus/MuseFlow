import '../utils/logger.dart';
import '../config/app_constants.dart';
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../models/note.dart';
import 'secure_storage_service.dart';
import 'encryption_performance_monitor.dart';

/// Encrypted application state manager that provides secure data handling.
///
/// This service extends the functionality of the basic AppState with
/// transparent encryption/decryption of all user data, providing a seamless
/// experience while ensuring data security.
class EncryptedAppState extends ChangeNotifier {
  final SecureStorageService _storageService;
  final EncryptionPerformanceMonitor _performanceMonitor;

  final List<Note> _notes = [];
  Note? _currentNote;
  bool _isLoading = false;
  String? _errorMessage;

  EncryptedAppState({
    SecureStorageService? storageService,
    EncryptionPerformanceMonitor? performanceMonitor,
  })  : _storageService = storageService ?? SecureStorageService.instance,
        _performanceMonitor =
            performanceMonitor ?? EncryptionPerformanceMonitor.instance;

  List<Note> get notes => _notes;
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize the encrypted state manager
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _storageService.initialize();
      await loadNotes();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all notes with automatic decryption
  Future<void> loadNotes() async {
    _setLoading(true);
    try {
      final result = await _performanceMonitor.measureOperation(
        operation: 'load_notes',
        operationFn: () => _storageService.getAllNotes(),
      );

      _notes.clear();
      _notes.addAll(result);
      notifyListeners();

      Logger.debug('Loaded ${_notes.length} encrypted notes');
    } catch (e) {
      _setError('Failed to load notes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new note
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

  /// Select a note for editing
  void selectNote(Note note) {
    _currentNote = note;
    notifyListeners();
  }

  /// Update the current note's content
  void updateNote(String title, String content) {
    if (_currentNote != null) {
      _currentNote!.title = title;
      _currentNote!.content = content;
      _currentNote!.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// Save the current note with encryption
  Future<void> saveCurrentNote() async {
    if (_currentNote == null) return;

    _setLoading(true);
    try {
      await _performanceMonitor.measureOperation(
        operation: 'save_note',
        operationFn: () => _storageService.saveNote(_currentNote!),
        dataSize: _currentNote!.title.length + _currentNote!.content.length,
      );

      _currentNote!.updatedAt = DateTime.now();
      notifyListeners();

      Logger.debug('Saved note: ${_currentNote!.id}');
    } catch (e) {
      _setError('Failed to save note: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save all notes with encryption
  Future<void> saveAllNotes() async {
    _setLoading(true);
    try {
      await _performanceMonitor.measureOperation(
        operation: 'bulk_save_notes',
        operationFn: () => _storageService.bulkSaveNotes(_notes),
        dataSize: _notes.fold<int>(
            0, (sum, note) => sum + note.title.length + note.content.length),
      );

      notifyListeners();
      Logger.debug('Saved all ${_notes.length} notes');
    } catch (e) {
      _setError('Failed to save notes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a note
  Future<void> deleteNote(Note note) async {
    _setLoading(true);
    try {
      await _performanceMonitor.measureOperation(
        operation: 'delete_note',
        operationFn: () => _storageService.deleteNote(note.id),
      );

      _notes.remove(note);
      if (_currentNote == note) {
        _currentNote = _notes.isNotEmpty ? _notes.first : null;
      }

      notifyListeners();
      Logger.debug('Deleted note: ${note.id}');
    } catch (e) {
      _setError('Failed to delete note: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Search notes with decryption
  Future<List<Note>> searchNotes(String query) async {
    _setLoading(true);
    try {
      final results = await _performanceMonitor.measureOperation(
        operation: 'search_notes',
        operationFn: () => _storageService.searchNotes(query),
      );

      return results;
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get notes by tag
  Future<List<Note>> getNotesByTag(String tag) async {
    _setLoading(true);
    try {
      final results = await _performanceMonitor.measureOperation(
        operation: 'get_notes_by_tag',
        operationFn: () => _storageService.getNotesByTag(tag),
      );

      return results;
    } catch (e) {
      _setError('Failed to get notes by tag: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Import notes with encryption
  Future<void> importNotes(List<Map<String, dynamic>> notesData) async {
    _setLoading(true);
    try {
      await _performanceMonitor.measureOperation(
        operation: 'import_notes',
        operationFn: () => _storageService.importNotes(notesData),
      );

      await loadNotes(); // Reload to show imported notes
      Logger.debug('Imported ${notesData.length} notes');
    } catch (e) {
      _setError('Import failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Export notes in decrypted format
  Future<List<Map<String, dynamic>>> exportNotes() async {
    _setLoading(true);
    try {
      return await _performanceMonitor.measureOperation(
        operation: 'export_notes',
        operationFn: () => _storageService.exportNotes(),
      );
    } catch (e) {
      _setError('Export failed: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get performance statistics
  PerformanceStats getPerformanceStats() {
    return _performanceMonitor.getStatistics();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Save and clean up before exit
  Future<void> saveBeforeExit() async {
    await saveAllNotes();
    await _storageService.close();
    _performanceMonitor.dispose();
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    Logger.debug(error);
    notifyListeners();
  }
}

/// Factory for creating encrypted app state instances
class EncryptedAppStateFactory {
  static EncryptedAppState create() {
    return EncryptedAppState();
  }

  static EncryptedAppState createWithMonitors() {
    return EncryptedAppState(
      performanceMonitor: EncryptionPerformanceMonitor.instance,
    );
  }
}
