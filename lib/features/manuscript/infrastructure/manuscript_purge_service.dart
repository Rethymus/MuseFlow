import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

/// Service that permanently deletes soft-deleted manuscripts older than
/// a configurable retention period (default 30 days).
///
/// Called on app startup after Hive initialization. Cascades chapter
/// deletion before manuscript hard-deletion to maintain referential integrity.
///
/// Per D-21: Soft delete for manuscripts with `deletedAt` timestamp.
/// Manuscripts with `deletedAt != null` are hidden from library but
/// recoverable for 30 days. This service handles the permanent removal.
///
/// Usage:
/// ```dart
/// final purgeService = ManuscriptPurgeService(
///   manuscriptRepository: manuscriptRepo,
///   chapterRepository: chapterRepo,
/// );
/// await purgeService.purgeExpired(); // uses default 30-day retention
/// ```
///
/// The cascade deletion order ensures no orphaned chapters remain:
/// 1. Delete all chapters belonging to the expired manuscript
/// 2. Hard-delete the manuscript itself
class ManuscriptPurgeService {
  final ManuscriptRepository _manuscriptRepository;
  final ChapterRepository _chapterRepository;

  const ManuscriptPurgeService({
    required this._manuscriptRepository,
    required this._chapterRepository,
  });

  /// Permanently deletes manuscripts with [deletedAt] older than [retention].
  ///
  /// Deletes associated chapters first, then hard-deletes the manuscript.
  /// Default retention is 30 days per D-21.
  ///
  /// Returns the number of manuscripts purged (for logging/debugging).
  Future<int> purgeExpired({
    Duration retention = const Duration(days: 30),
  }) async {
    final cutoff = DateTime.now().subtract(retention);
    final manuscripts = _manuscriptRepository.getAllIncludingDeleted();
    var purgedCount = 0;

    for (final manuscript in manuscripts) {
      if (manuscript.deletedAt != null &&
          manuscript.deletedAt!.isBefore(cutoff)) {
        // Cascade: delete chapters first
        await _chapterRepository.deleteByManuscriptId(manuscript.id);
        // Then hard-delete the manuscript
        await _manuscriptRepository.hardDelete(manuscript.id);
        purgedCount++;
      }
    }

    return purgedCount;
  }
}
