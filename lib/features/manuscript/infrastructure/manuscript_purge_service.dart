import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

/// Service that permanently deletes soft-deleted manuscripts older than
/// a configurable retention period (default 30 days).
///
/// Called on app startup after Hive initialization. Cascades chapter
/// deletion before manuscript hard-deletion to maintain referential integrity.
class ManuscriptPurgeService {
  final ManuscriptRepository _manuscriptRepository;
  final ChapterRepository _chapterRepository;

  const ManuscriptPurgeService({
    required ManuscriptRepository manuscriptRepository,
    required ChapterRepository chapterRepository,
  })  : _manuscriptRepository = manuscriptRepository,
        _chapterRepository = chapterRepository;

  /// Permanently deletes manuscripts with [deletedAt] older than [retention].
  ///
  /// Deletes associated chapters first, then hard-deletes the manuscript.
  /// Default retention is 30 days per D-21.
  Future<void> purgeExpired({Duration retention = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(retention);
    final manuscripts = _manuscriptRepository.getAllIncludingDeleted();

    for (final manuscript in manuscripts) {
      if (manuscript.deletedAt != null &&
          manuscript.deletedAt!.isBefore(cutoff)) {
        // Cascade: delete chapters first
        await _chapterRepository.deleteByManuscriptId(manuscript.id);
        // Then hard-delete the manuscript
        await _manuscriptRepository.hardDelete(manuscript.id);
      }
    }
  }
}
