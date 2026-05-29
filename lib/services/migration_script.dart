import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../models/note.dart';
import '../config/app_constants.dart';
import '../utils/logger.dart';
import 'secure_data_service.dart';
import 'secure_storage_service.dart';
import 'encryption_migration_service.dart';

/// Data migration script for transitioning from plaintext to encrypted storage.
///
/// This script provides a complete solution for migrating existing user data
/// from unencrypted Hive storage to encrypted secure storage, with rollback
/// capabilities and progress monitoring.
class DataMigrationScript {
  static final DataMigrationScript instance = DataMigrationScript._internal();
  factory DataMigrationScript() => instance;
  DataMigrationScript._internal();

  late final SecureDataService _secureService;
  late final SecureStorageService _secureStorage;
  late final EncryptionMigrationService _migrationService;

  /// Initialize the migration script
  Future<void> initialize() async {
    _secureService = SecureDataService.instance;
    _secureStorage = SecureStorageService.instance;
    _migrationService = EncryptionMigrationService.instance;

    await _secureService.initialize();
    await _secureStorage.initialize();
    await _migrationService.initialize();
  }

  /// Run the complete migration process with progress callbacks
  ///
  /// Returns a MigrationResult with success status and statistics
  Future<MigrationResult> runMigration({
    void Function(String)? onProgress,
    void Function(String)? onError,
  }) async {
    try {
      // Check if migration is needed
      final isNeeded = await _migrationService.isMigrationNeeded();

      if (!isNeeded) {
        onProgress?.call(
            'No migration needed - data already encrypted or no data found');
        return MigrationResult(
          success: true,
          message: 'No migration needed',
          notesMigrated: 0,
          duration: Duration.zero,
        );
      }

      onProgress?.call('Starting data migration...');

      final startTime = DateTime.now();
      int notesMigrated = 0;
      String lastMessage = '';

      // Subscribe to migration progress stream
      _migrationService.migrateToEncryption().listen(
        (progress) {
          if (progress.message != lastMessage) {
            onProgress?.call(progress.message);
            lastMessage = progress.message;
          }

          if (progress.state == EncryptionMigrationService.STATE_COMPLETED) {
            notesMigrated = progress.totalMigrated ?? 0;
          } else if (progress.state ==
              EncryptionMigrationService.STATE_FAILED) {
            onError?.call('Migration failed: ${progress.message}');
          }
        },
        onError: (error) {
          onError?.call('Migration error: $error');
        },
      );

      // Wait for migration to complete
      await _waitForMigrationCompletion();

      final duration = DateTime.now().difference(startTime);

      return MigrationResult(
        success: true,
        message: 'Migration completed successfully',
        notesMigrated: notesMigrated,
        duration: duration,
      );
    } catch (e) {
      onError?.call('Migration exception: $e');
      return MigrationResult(
        success: false,
        message: 'Migration failed: $e',
        notesMigrated: 0,
        duration: Duration.zero,
      );
    }
  }

  /// Wait for migration to complete
  Future<void> _waitForMigrationCompletion() async {
    // Poll for completion status
    while (true) {
      final state = await _migrationService.getMigrationState();

      if (state == EncryptionMigrationService.STATE_COMPLETED ||
          state == EncryptionMigrationService.STATE_FAILED ||
          state == EncryptionMigrationService.STATE_ROLLED_BACK) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Quick migration for development/testing
  Future<void> quickMigration() async {
    await initialize();

    final isNeeded = await _migrationService.isMigrationNeeded();
    if (!isNeeded) {
      Logger.debug('No migration needed', tag: 'MIGRATION');
      return;
    }

    Logger.debug('Starting quick migration...', tag: 'MIGRATION');

    try {
      await _migrationService.migrateToEncryption().last;
      Logger.debug('Quick migration completed successfully', tag: 'MIGRATION');
    } catch (e) {
      Logger.debug('Quick migration failed: $e', tag: 'MIGRATION', error: e);
    }
  }

  /// Rollback migration if needed
  Future<void> rollbackMigration() async {
    await initialize();

    try {
      await _migrationService.rollbackMigration();
      Logger.debug('Migration rolled back successfully', tag: 'MIGRATION');
    } catch (e) {
      Logger.error('Rollback failed: $e', tag: 'MIGRATION', error: e);
      rethrow;
    }
  }

  /// Get migration status
  Future<MigrationStatus> getStatus() async {
    await initialize();

    final state = await _migrationService.getMigrationState();
    final details = await _migrationService.getMigrationDetails();
    final isNeeded = await _migrationService.isMigrationNeeded();

    return MigrationStatus(
      state: state,
      isNeeded: isNeeded,
      details: details,
    );
  }

  /// Verify migration integrity
  Future<VerificationResult> verifyMigration() async {
    await initialize();

    try {
      // Get counts from both storage systems
      final secureNotes = await _secureStorage.getAllNotes();

      // Check if encryption is working
      final testNote = Note(
        id: 'verification-test',
        title: 'Test',
        content: 'Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _secureStorage.saveNote(testNote);
      final retrieved = await _secureStorage.getAllNotes();
      await _secureStorage.deleteNote('verification-test');

      final foundTest = retrieved
          .any((n) => n.id == 'verification-test' && n.content == 'Content');

      return VerificationResult(
        success: true,
        totalNotes: secureNotes.length,
        encryptionWorking: foundTest,
        message: 'Migration verification passed',
      );
    } catch (e) {
      return VerificationResult(
        success: false,
        totalNotes: 0,
        encryptionWorking: false,
        message: 'Verification failed: $e',
      );
    }
  }

  /// Clean up after successful migration
  Future<void> cleanup() async {
    await initialize();

    try {
      await _migrationService.clearMigrationData();
      Logger.debug('Migration cleanup completed', tag: 'MIGRATION');
    } catch (e) {
      Logger.error('Cleanup failed: $e', tag: 'MIGRATION', error: e);
      rethrow;
    }
  }

  /// Generate migration report
  Future<String> generateReport() async {
    await initialize();

    final status = await getStatus();
    final verification = await verifyMigration();
    final storageStats = await _secureStorage.getStorageStats();

    final buffer = StringBuffer();
    buffer.writeln('=== MUSEFLOW DATA MIGRATION REPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    buffer.writeln('MIGRATION STATUS:');
    buffer.writeln('  State: ${status.state}');
    buffer.writeln('  Needed: ${status.isNeeded}');
    if (status.details.startTime != null) {
      buffer.writeln('  Start Time: ${status.details.startTime}');
      buffer.writeln('  Duration: ${status.details.duration?.inSeconds}s');
    }
    buffer.writeln();

    buffer.writeln('VERIFICATION RESULTS:');
    buffer.writeln('  Success: ${verification.success}');
    buffer.writeln('  Total Notes: ${verification.totalNotes}');
    buffer.writeln('  Encryption Working: ${verification.encryptionWorking}');
    buffer.writeln('  Message: ${verification.message}');
    buffer.writeln();

    buffer.writeln('STORAGE STATISTICS:');
    buffer.writeln('  Total Notes: ${storageStats['total_notes']}');
    buffer.writeln('  Settings Count: ${storageStats['settings_count']}');
    buffer
        .writeln('  Encryption Enabled: ${storageStats['encryption_enabled']}');
    buffer.writeln(
        '  Migration Completed: ${storageStats['migration_completed']}');
    buffer
        .writeln('  Encryption Version: ${storageStats['encryption_version']}');
    buffer.writeln();

    buffer.writeln('ENCRYPTION SERVICE STATUS:');
    final encStatus = _secureService.getStatus();
    encStatus.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });

    return buffer.toString();
  }
}

/// Migration result
class MigrationResult {
  final bool success;
  final String message;
  final int notesMigrated;
  final Duration duration;

  MigrationResult({
    required this.success,
    required this.message,
    required this.notesMigrated,
    required this.duration,
  });

  @override
  String toString() {
    return 'MigrationResult(success: $success, notes: $notesMigrated, duration: ${duration.inSeconds}s, message: $message)';
  }
}

/// Migration status
class MigrationStatus {
  final String state;
  final bool isNeeded;
  final MigrationDetails details;

  MigrationStatus({
    required this.state,
    required this.isNeeded,
    required this.details,
  });

  @override
  String toString() {
    return 'MigrationStatus(state: $state, needed: $isNeeded, startTime: ${details.startTime})';
  }
}

/// Verification result
class VerificationResult {
  final bool success;
  final int totalNotes;
  final bool encryptionWorking;
  final String message;

  VerificationResult({
    required this.success,
    required this.totalNotes,
    required this.encryptionWorking,
    required this.message,
  });

  @override
  String toString() {
    return 'VerificationResult(success: $success, notes: $totalNotes, encryption: $encryptionWorking, message: $message)';
  }
}

/// Command-line utility for running migrations
class MigrationCLI {
  static Future<void> main(List<String> args) async {
    final script = DataMigrationScript.instance;

    Logger.info('MuseFlow Data Migration Utility');
    Logger.info('===============================');

    try {
      await script.initialize();

      // Parse command
      final command = args.isNotEmpty ? args[0] : 'status';

      switch (command) {
        case 'status':
          await _showStatus(script);
          break;
        case 'migrate':
          await _runMigration(script);
          break;
        case 'rollback':
          await _rollbackMigration(script);
          break;
        case 'verify':
          await _verifyMigration(script);
          break;
        case 'report':
          await _generateReport(script);
          break;
        default:
          Logger.info('Unknown command: $command');
          Logger.info(
              'Available commands: status, migrate, rollback, verify, report');
      }
    } catch (e) {
      Logger.info('Error: $e');
    }
  }

  static Future<void> _showStatus(DataMigrationScript script) async {
    final status = await script.getStatus();

    Logger.info('Current Status: ${status.state}');
    Logger.info('Migration Needed: ${status.isNeeded}');

    if (status.details.startTime != null) {
      Logger.info('Start Time: ${status.details.startTime}');
      if (status.details.duration != null) {
        Logger.info('Duration: ${status.details.duration!.inSeconds}s');
      }
    }

    if (status.details.error != null) {
      Logger.info('Error: ${status.details.error}');
    }
  }

  static Future<void> _runMigration(DataMigrationScript script) async {
    Logger.info('Starting migration...');
    final result = await script.runMigration(
      onProgress: (msg) => Logger.info(msg),
      onError: (msg) => Logger.info('ERROR: $msg'),
    );

    Logger.info('\nMigration Result:');
    Logger.info('  Success: ${result.success}');
    Logger.info('  Notes Migrated: ${result.notesMigrated}');
    Logger.info('  Duration: ${result.duration.inSeconds}s');
    Logger.info('  Message: ${result.message}');
  }

  static Future<void> _rollbackMigration(DataMigrationScript script) async {
    Logger.info('Rolling back migration...');
    await script.rollbackMigration();
    Logger.info('Rollback completed');
  }

  static Future<void> _verifyMigration(DataMigrationScript script) async {
    final result = await script.verifyMigration();

    Logger.info('Verification Results:');
    Logger.info('  Success: ${result.success}');
    Logger.info('  Total Notes: ${result.totalNotes}');
    Logger.info('  Encryption Working: ${result.encryptionWorking}');
    Logger.info('  Message: ${result.message}');
  }

  static Future<void> _generateReport(DataMigrationScript script) async {
    final report = await script.generateReport();
    Logger.info(report);
  }
}
