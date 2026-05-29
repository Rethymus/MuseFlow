import '../models/note.dart';

/// Abstract base class for storage services.
///
/// Defines the common interface shared by [StorageService] and
/// [SecureStorageService] so that either implementation can be
/// injected into consumers such as [AppState].
abstract class BaseStorageService {
  bool get isInitialized;
  Future<void> initialize();
  Future<List<Note>> getAllNotes();
  Future<void> saveNote(Note note);
  Future<void> saveAllNotes(List<Note> notes);
  Future<void> deleteNote(String noteId);
  Future<String> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<void> close();
}
