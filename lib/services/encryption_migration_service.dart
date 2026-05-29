import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/app_state.dart';
import 'secure_data_service.dart';
import 'secure_storage_service.dart';
import 'dart:convert';

/// Service for managing data migration from plaintext to encrypted storage.
///
/// This service handles the complex process of migrating existing user data
/// from unencrypted storage to encrypted storage, ensuring data integrity
/// and providing rollback capabilities if needed.
class EncryptionMigrationService {
  static final EncryptionMigrationService instance = EncryptionMigrationService._internal();
  factory EncryptionMigrationService() => instance;
  EncryptionMigrationService._internal() {
    _secureService = SecureDataService.instance;
    _secureStorage = SecureStorageService.instance;
  }

  late final SecureDataService _secureService;
  late final SecureStorageService _secureStorage;
  late Box<String> _migrationBox;

  // Migration state constants
  static const String _migrationStateKey = 'migration_state';
  static const String _migrationProgressKey = 'migration_progress';
  static const String _migrationBackupKey = 'migration_backup';
  static const String _migrationStartTimeKey = 'migration_start_time';
  static const String _migrationErrorKey = 'migration_error';

  /// Migration states
  static const String STATE_NOT_STARTED = 'not_started';
  static const String STATE_IN_PROGRESS = 'in_progress';
  static const String STATE_COMPLETED = 'completed';
  static const String STATE_FAILED = 'failed';
  static const String STATE_ROLLED_BACK = 'rolled_back';

  /// Initialize the migration service
  Future<void> initialize() async {
    _migrationBox = await Hive.openBox<String>('migration');
  }

  /// Get current migration state
  Future<String> getMigrationState() async {
    return await _migrationBox.get(_migrationStateKey) ?? STATE_NOT_STARTED;
  }

  /// Check if migration is needed
  Future<bool> isMigrationNeeded() async {
    final state = await getMigrationState();
    if (state == STATE_COMPLETED) {
      return false;
    }

    // Check if legacy data exists
    try {
      final legacyBox = await Hive.openBox<Note>('notes');
      final hasData = legacyBox.isNotEmpty;
      await legacyBox.close();
      return hasData;
    } catch (e) {
      return false;
    }
  }

  /// Start migration process
  ///
  /// Returns a stream of progress updates (0.0 to 1.0)
  Stream<MigrationProgress> migrateToEncryption() async* {
    try {
      // Update state to in progress
      await _migrationBox.put(_migrationStateKey, STATE_IN_PROGRESS);
      await _migrationBox.put(_migrationStartTimeKey, DateTime.now().toIso8601String());
      await _migrationBox.delete(_migrationErrorKey);

      yield MigrationProgress(state: STATE_IN_PROGRESS, progress: 0.0, message: 'Starting migration...');

      // Open legacy box
      final legacyBox = await Hive.openBox<Note>('notes');
      final totalNotes = legacyBox.length;

      if (totalNotes == 0) {
        await _migrationBox.put(_migrationStateKey, STATE_COMPLETED);
        yield MigrationProgress(state: STATE_COMPLETED, progress: 1.0, message: 'No data to migrate');
        return;
      }

      // Create backup
      yield MigrationProgress(state: STATE_IN_PROGRESS, progress: 0.1, message: 'Creating backup...');
      await _createBackup(legacyBox);

      // Migrate notes in batches
      final batchSize = 10;
      final batches = (totalNotes / batchSize).ceil();
      final notes = legacyBox.values.toList();
      int migratedCount = 0;

      for (int i = 0; i < batches; i++) {
        final start = i * batchSize;
        final end = ((i + 1) * batchSize).clamp(0, totalNotes);
        final batch = notes.sublist(start, end);

        // Encrypt and save batch
        await _migrateBatch(batch);

        migratedCount += batch.length;
        final progress = 0.1 + (0.8 * (migratedCount / totalNotes));

        yield MigrationProgress(
          state: STATE_IN_PROGRESS,
          progress: progress,
          message: 'Migrated $migratedCount of $totalNotes notes',
        );

        // Small delay to avoid blocking UI
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Verify migration
      yield MigrationProgress(state: STATE_IN_PROGRESS, progress: 0.9, message: 'Verifying migration...');
      final verified = await _verifyMigration(totalNotes);

      if (!verified) {
        throw MigrationException('Migration verification failed');
      }

      // Clear legacy data after successful verification
      yield MigrationProgress(state: STATE_IN_PROGRESS, progress: 0.95, message: 'Cleaning up...');
      await legacyBox.clear();
      await legacyBox.close();

      // Mark migration as complete
      await _migrationBox.put(_migrationStateKey, STATE_COMPLETED);
      await _migrationBox.put(_migrationProgressKey, '1.0');

      yield MigrationProgress(
        state: STATE_COMPLETED,
        progress: 1.0,
        message: 'Migration completed successfully',
        totalMigrated: totalNotes,
      );

    } catch (e) {
      // Handle migration failure
      await _migrationBox.put(_migrationStateKey, STATE_FAILED);
      await _migrationBox.put(_migrationErrorKey, e.toString());

      yield MigrationProgress(
        state: STATE_FAILED,
        progress: 0.0,
        message: 'Migration failed: $e',
      );
    }
  }

  /// Create backup of existing data
  Future<void> _createBackup(Box<Note> legacyBox) async {
    final notes = legacyBox.values.toList();
    final backupData = notes.map((note) => {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'tags': note.tags,
    }).toList();

    await _migrationBox.put(_migrationBackupKey, jsonEncode(backupData));
  }

  /// Migrate a batch of notes to encrypted storage
  Future<void> _migrateBatch(List<Note> notes) async {
    for (final note in notes) {
      await _secureStorage.saveNote(note);
    }
  }

  /// Verify migration was successful
  Future<bool> _verifyMigration(int expectedCount) async {
    try {
      final migratedNotes = await _secureStorage.getAllNotes();
      return migratedNotes.length == expectedCount;
    } catch (e) {
      return false;
    }
  }

  /// Rollback migration from backup
  ///
  /// Restores the original plaintext data from backup if migration fails
  Future<void> rollbackMigration() async {
    try {
      final backupJson = await _migrationBox.get(_migrationBackupKey);
      if (backupJson == null) {
        throw MigrationException('No backup found');
      }

      final backupData = jsonDecode(backupJson) as List<dynamic>;

      // Restore to legacy storage
      final legacyBox = await Hive.openBox<Note>('notes');
      await legacyBox.clear();

      for (final item in backupData) {
        final note = Note(
          id: item['id'] as String,
          title: item['title'] as String,
          content: item['content'] as String,
          createdAt: DateTime.parse(item['created_at'] as String),
          updatedAt: DateTime.parse(item['updated_at'] as String),
          tags: (item['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        );
        await legacyBox.put(note.id, note);
      }

      // Clear encrypted storage
      await _secureStorage.clearAllData();

      // Update state
      await _migrationBox.put(_migrationStateKey, STATE_ROLLED_BACK);

    } catch (e) {
      throw MigrationException('Rollback failed: $e');
    }
  }

  /// Get migration details
  Future<MigrationDetails> getMigrationDetails() async {
    final state = await getMigrationState();
    final startTime = await _migrationBox.get(_migrationStartTimeKey);
    final error = await _migrationBox.get(_migrationErrorKey);
    final progress = await _migrationBox.get(_migrationProgressKey);

    return MigrationDetails(
      state: state,
      startTime: startTime != null ? DateTime.parse(startTime) : null,
      error: error,
      progress: progress != null ? double.tryParse(progress) : null,
    );
  }

  /// Clear migration data (after successful verification)
  Future<void> clearMigrationData() async {
    final state = await getMigrationState();
    if (state != STATE_COMPLETED) {
      throw MigrationException('Cannot clear migration data: migration not completed');
    }

    await _migrationBox.delete(_migrationBackupKey);
    await _migrationBox.delete(_migrationStartTimeKey);
    await _migrationBox.delete(_migrationErrorKey);
    await _migrationBox.delete(_migrationProgressKey);
  }

  /// Manual trigger for re-migration
  ///
  /// Use this only if you need to re-encrypt data with new keys
  Future<void> forceReMigration() async {
    final state = await getMigrationState();

    // Clear migration state to allow re-migration
    await _migrationBox.put(_migrationStateKey, STATE_NOT_STARTED);
    await _migrationBox.delete(_migrationBackupKey);

    // Regenerate encryption keys
    await _secureService.regenerateKeys();

    // Start new migration
    await migrateToEncryption().first;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _migrationBox.close();
  }
}

/// Migration progress information
class MigrationProgress {
  final String state;
  final double progress;
  final String message;
  final int? totalMigrated;

  MigrationProgress({
    required this.state,
    required this.progress,
    required this.message,
    this.totalMigrated,
  });

  @override
  String toString() {
    return 'MigrationProgress(state: $state, progress: $progress, message: $message, totalMigrated: $totalMigrated)';
  }
}

/// Migration details
class MigrationDetails {
  final String state;
  final DateTime? startTime;
  final String? error;
  final double? progress;

  MigrationDetails({
    required this.state,
    this.startTime,
    this.error,
    this.progress,
  });

  Duration? get duration {
    if (startTime == null) return null;
    return DateTime.now().difference(startTime!);
  }

  @override
  String toString() {
    return 'MigrationDetails(state: $state, startTime: $startTime, error: $error, progress: $progress, duration: $duration)';
  }
}

/// Custom exception for migration errors
class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);

  @override
  String toString() => 'MigrationException: $message';
}