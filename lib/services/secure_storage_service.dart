import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../utils/logger.dart';
import 'secure_data_service.dart';
import 'base_storage_service.dart';

/// Secure storage service that provides encrypted data persistence.
///
/// This service extends the functionality of the basic storage service
/// with transparent encryption/decryption of sensitive user data.
///
/// All note content and titles are automatically encrypted before storage
/// and decrypted upon retrieval, providing a seamless experience while
/// ensuring data security.
class SecureStorageService implements BaseStorageService {
  static final SecureStorageService instance = SecureStorageService._internal();
  factory SecureStorageService() => instance;
  SecureStorageService._internal() {
    _secureService = SecureDataService.instance;
  }

  late final SecureDataService _secureService;
  late Box<Map<String, dynamic>> _notesBox;
  late Box<String> _settingsBox;
  late Box<String> _migrationBox;

  // Encryption migration tracking
  static const String _migrationKey = 'encryption_migration_completed';
  static const String _encryptionVersionKey = 'encryption_version';
  static const int _currentEncryptionVersion = 1;

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  /// Initialize the secure storage service
  ///
  /// Must be called before any other operations. This will:
  /// 1. Initialize the underlying encryption service
  /// 2. Open Hive boxes with proper adapters
  /// 3. Check if data migration is needed
  @override
  Future<void> initialize() async {
    await _secureService.initialize();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NoteAdapter());
    }

    // Open boxes
    _notesBox = await Hive.openBox<Map<String, dynamic>>('notes_secure');
    _settingsBox = await Hive.openBox<String>('settings');
    _migrationBox = await Hive.openBox<String>('migration');

    // Check if migration is needed
    await _checkAndPerformMigration();
    _isInitialized = true;
  }

  /// Check if legacy data migration is needed and perform it
  Future<void> _checkAndPerformMigration() async {
    final migrationCompleted =
        _migrationBox.get(_migrationKey) ?? 'false';

    if (migrationCompleted == 'false') {
      await _migrateLegacyData();
    }
  }

  /// Migrate legacy plaintext data to encrypted storage
  Future<void> _migrateLegacyData() async {
    try {
      // Try to open legacy notes box
      final legacyNotesBox = await Hive.openBox<Note>('notes');

      if (legacyNotesBox.isEmpty) {
        // No legacy data to migrate
        await _migrationBox.put(_migrationKey, 'true');
        await _migrationBox.put(
            _encryptionVersionKey, _currentEncryptionVersion.toString());
        return;
      }

      // Migrate all notes
      final notes = legacyNotesBox.values.toList();
      for (final note in notes) {
        await saveNote(
          Note(
            id: note.id,
            title: note.title,
            content: note.content,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
            tags: note.tags,
          ),
        );
      }

      // Clear legacy box after successful migration
      await legacyNotesBox.clear();

      // Mark migration as complete
      await _migrationBox.put(_migrationKey, 'true');
      await _migrationBox.put(
          _encryptionVersionKey, _currentEncryptionVersion.toString());

      Logger.info(
          'Successfully migrated ${notes.length} notes to encrypted storage',
          tag: 'MIGRATION');
    } catch (e) {
      Logger.error('Error during data migration: $e',
          tag: 'MIGRATION', error: e);
      // Don't rethrow - allow app to continue
    }
  }

  /// Get all notes with automatic decryption
  @override
  Future<List<Note>> getAllNotes() async {
    try {
      final encryptedNotes = _notesBox.values.toList();

      if (encryptedNotes.isEmpty) {
        return [];
      }

      // Decrypt all notes
      final decryptedNotes = _secureService.batchDecryptNotes(encryptedNotes);

      // Convert to Note objects
      return decryptedNotes.map((data) {
        return Note(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          createdAt: DateTime.parse(data['created_at'] as String),
          updatedAt: DateTime.parse(data['updated_at'] as String),
          tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }).toList();
    } on SecurityException catch (e) {
      // Log the security error for debugging
      Logger.debug('SecurityException in getAllNotes: ${e.message}');

      // Re-throw as a more user-friendly exception
      throw StorageException(
        'Unable to load your notes due to a security error. '
        'This may be due to corrupted data or encryption key mismatch. '
        'Please try restarting the app or contact support if the issue persists.',
        originalError: e,
      );
    } catch (e) {
      // Handle other unexpected errors
      Logger.debug('Unexpected error in getAllNotes: $e');
      throw StorageException(
        'An unexpected error occurred while loading notes.',
        originalError: e,
      );
    }
  }

  /// Save a note with automatic encryption
  @override
  Future<void> saveNote(Note note) async {
    try {
      final encryptedData = _secureService.encryptNoteData(
        noteId: note.id,
        title: note.title,
        content: note.content,
      );

      await _notesBox.put(note.id, {
        'id': note.id,
        'title': encryptedData['title']!,
        'content': encryptedData['content']!,
        'created_at': note.createdAt.toIso8601String(),
        'updated_at': note.updatedAt.toIso8601String(),
        'tags': note.tags,
        'is_encrypted': true,
        'algorithm': encryptedData['algorithm'],
      });
    } on SecurityException catch (e) {
      // Log the security error for debugging
      Logger.debug('SecurityException in saveNote: ${e.message}');

      // Re-throw as a more user-friendly exception
      throw StorageException(
        'Unable to save your note due to a security error. '
        'The encryption process failed. Please try again or contact support if the issue persists.',
        originalError: e,
      );
    } catch (e) {
      // Handle other unexpected errors
      Logger.debug('Unexpected error in saveNote: $e');
      throw StorageException(
        'An unexpected error occurred while saving the note.',
        originalError: e,
      );
    }
  }

  /// Delete a note by ID
  @override
  Future<void> deleteNote(String noteId) async {
    try {
      await _notesBox.delete(noteId);
    } catch (e) {
      // Log the error for debugging
      Logger.debug('Error in deleteNote: $e');
      throw StorageException(
        'An error occurred while deleting the note.',
        originalError: e,
      );
    }
  }

  /// Get a setting value
  @override
  Future<String> getSetting(String key,
      {String defaultValue = 'system'}) async {
    return _settingsBox.get(key, defaultValue: defaultValue)!;
  }

  /// Set a setting value
  @override
  Future<void> setSetting(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  /// Save all notes (delegates to bulkSaveNotes)
  @override
  Future<void> saveAllNotes(List<Note> notes) async {
    await bulkSaveNotes(notes);
  }

  /// Search notes with decryption support
  ///
  /// Decrypts notes and performs client-side search on the decrypted content.
  Future<List<Note>> searchNotes(String query) async {
    try {
      final allNotes = await getAllNotes();

      if (query.isEmpty) {
        return allNotes;
      }

      final lowerQuery = query.toLowerCase();

      return allNotes.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.content.toLowerCase().contains(lowerQuery);
      }).toList();
    } on StorageException {
      // Re-throw StorageException as-is (already formatted)
      rethrow;
    } catch (e) {
      // Handle other unexpected errors
      Logger.debug('Unexpected error in searchNotes: $e');
      throw StorageException(
        'An error occurred while searching notes.',
        originalError: e,
      );
    }
  }

  /// Get notes by tag with decryption support
  Future<List<Note>> getNotesByTag(String tag) async {
    try {
      final allNotes = await getAllNotes();

      return allNotes.where((note) {
        return note.tags.contains(tag);
      }).toList();
    } on StorageException {
      // Re-throw StorageException as-is (already formatted)
      rethrow;
    } catch (e) {
      // Handle other unexpected errors
      Logger.debug('Unexpected error in getNotesByTag: $e');
      throw StorageException(
        'An error occurred while filtering notes by tag.',
        originalError: e,
      );
    }
  }

  /// Bulk save notes with optimized encryption
  Future<void> bulkSaveNotes(List<Note> notes) async {
    try {
      // Batch encrypt all notes
      final encryptedNotes = _secureService.batchEncryptNotes(
        notes
            .map((note) => {
                  'id': note.id,
                  'title': note.title,
                  'content': note.content,
                  'created_at': note.createdAt.toIso8601String(),
                  'updated_at': note.updatedAt.toIso8601String(),
                  'tags': note.tags,
                })
            .toList(),
      );

      // Save all encrypted notes
      for (final encryptedNote in encryptedNotes) {
        await _notesBox.put(encryptedNote['id'] as String, encryptedNote);
      }
    } on SecurityException catch (e) {
      // Log the security error for debugging
      Logger.debug('SecurityException in bulkSaveNotes: ${e.message}');

      // Re-throw as a more user-friendly exception
      throw StorageException(
        'Unable to save notes due to a security error. '
        'The encryption process failed. Please try again or contact support if the issue persists.',
        originalError: e,
      );
    } catch (e) {
      // Handle other unexpected errors
      Logger.debug('Unexpected error in bulkSaveNotes: $e');
      throw StorageException(
        'An unexpected error occurred while saving notes.',
        originalError: e,
      );
    }
  }

  /// Export notes in decrypted format
  ///
  /// Returns notes in their original, unencrypted format for export purposes.
  Future<List<Map<String, dynamic>>> exportNotes() async {
    try {
      final notes = await getAllNotes();

      return notes
          .map((note) => {
                'id': note.id,
                'title': note.title,
                'content': note.content,
                'created_at': note.createdAt.toIso8601String(),
                'updated_at': note.updatedAt.toIso8601String(),
                'tags': note.tags,
              })
          .toList();
    } on StorageException {
      // Re-throw StorageException as-is (already formatted)
      rethrow;
    } catch (e) {
      // Handle other unexpected errors
      Logger.debug('Unexpected error in exportNotes: $e');
      throw StorageException(
        'An error occurred while exporting notes.',
        originalError: e,
      );
    }
  }

  /// Import notes with encryption
  ///
  /// Takes plain text notes and encrypts them during import.
  Future<void> importNotes(List<Map<String, dynamic>> notesData) async {
    try {
      final notes = notesData.map((data) {
        return Note(
          id: data['id'] as String? ?? const Uuid().v4(),
          title: data['title'] as String,
          content: data['content'] as String,
          createdAt: DateTime.parse(data['created_at'] as String),
          updatedAt: DateTime.parse(data['updated_at'] as String),
          tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }).toList();

      await bulkSaveNotes(notes);
    } on StorageException {
      // Re-throw StorageException as-is (already formatted)
      rethrow;
    } catch (e) {
      // Handle other unexpected errors
      Logger.debug('Unexpected error in importNotes: $e');
      throw StorageException(
        'An error occurred while importing notes.',
        originalError: e,
      );
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final totalNotes = _notesBox.length;
    final settingsCount = _settingsBox.length;

    return {
      'total_notes': totalNotes,
      'settings_count': settingsCount,
      'encryption_enabled': true,
      'migration_completed': _migrationBox.get(_migrationKey) ?? 'false',
      'encryption_version':
          _migrationBox.get(_encryptionVersionKey) ?? '0',
    };
  }

  /// Clear all data (use with caution)
  Future<void> clearAllData() async {
    await _notesBox.clear();
    await _settingsBox.clear();
    await _migrationBox.clear();
  }

  /// Close all boxes and clean up resources
  @override
  Future<void> close() async {
    await _notesBox.close();
    await _settingsBox.close();
    await _migrationBox.close();
    await _secureService.dispose();
  }
}

/// Custom exception for storage-related errors
class StorageException implements Exception {
  /// User-friendly error message
  final String message;

  /// The original error that caused this exception
  final Object? originalError;

  /// Stack trace from the original error
  final StackTrace? stackTrace;

  StorageException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('StorageException: $message');
    if (originalError != null) {
      buffer.writeln('\nOriginal error: $originalError');
    }
    if (stackTrace != null && stackTrace != StackTrace.empty) {
      buffer.writeln('\nStack trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}
