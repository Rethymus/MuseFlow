import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

/// AsyncNotifier managing the list of [Manuscript] entities.
///
/// Loads manuscripts from [ManuscriptRepository] on build, filtering out
/// soft-deleted items. CRUD methods delegate to the repository and refresh
/// state via [ref.invalidateSelf].
class ManuscriptNotifier extends AsyncNotifier<List<Manuscript>> {
  @override
  Future<List<Manuscript>> build() async {
    final repository = await ref.watch(manuscriptRepositoryProvider.future);
    return repository.getAll();
  }

  /// Creates a new manuscript with one empty chapter.
  ///
  /// Delegates to [ManuscriptRepository.add] for the manuscript and
  /// [ChapterRepository.add] for the initial chapter.
  Future<void> create(Manuscript manuscript) async {
    final manuscriptRepo =
        await ref.read(manuscriptRepositoryProvider.future);
    final chapterRepo = await ref.read(chapterRepositoryProvider.future);

    final saved = await manuscriptRepo.add(manuscript);

    // Create one empty chapter
    final now = DateTime.now();
    await chapterRepo.add(
      Chapter(
        id: '',
        manuscriptId: saved.id,
        title: '第一章',
        sortOrder: 0,
        documentContent: '',
        createdAt: now,
        updatedAt: now,
      ),
    );

    ref.invalidateSelf();
  }

  /// Updates an existing manuscript and refreshes the state.
  Future<void> save(Manuscript manuscript) async {
    final repository =
        await ref.read(manuscriptRepositoryProvider.future);
    await repository.update(manuscript);
    ref.invalidateSelf();
  }

  /// Soft-deletes a manuscript by ID and refreshes the state.
  ///
  /// Sets [deletedAt] via the repository. The manuscript remains
  /// recoverable for 30 days.
  Future<void> softDelete(String id) async {
    final repository =
        await ref.read(manuscriptRepositoryProvider.future);
    await repository.softDelete(id);
    ref.invalidateSelf();
  }

  /// Permanently deletes manuscripts older than 30 days and refreshes.
  ///
  /// Cascades chapter deletion before manuscript hard-deletion.
  Future<void> purgeDeleted() async {
    final manuscriptRepo =
        await ref.read(manuscriptRepositoryProvider.future);
    final chapterRepo = await ref.read(chapterRepositoryProvider.future);

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final allManuscripts = manuscriptRepo.getAllIncludingDeleted();

    for (final manuscript in allManuscripts) {
      if (manuscript.deletedAt != null &&
          manuscript.deletedAt!.isBefore(cutoff)) {
        await chapterRepo.deleteByManuscriptId(manuscript.id);
        await manuscriptRepo.hardDelete(manuscript.id);
      }
    }

    ref.invalidateSelf();
  }

  /// Filters the current state by a title substring query.
  ///
  /// Case-insensitive search. Returns an empty list if state is not loaded.
  List<Manuscript> searchByTitle(String query) {
    final manuscripts = state.asData?.value ?? [];
    final lowerQuery = query.toLowerCase();
    return manuscripts
        .where((m) => m.title.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
