import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';

/// AsyncNotifier managing the list of [ForeshadowingEntry] entities.
///
/// Loads entries from [ForeshadowingRepository] on build, exposes
/// [AsyncValue] for the presentation layer. CRUD methods delegate
/// to the repository and refresh state via [ref.invalidateSelf].
class ForeshadowingNotifier extends AsyncNotifier<List<ForeshadowingEntry>> {
  @override
  Future<List<ForeshadowingEntry>> build() async {
    final repository = await ref.watch(foreshadowingRepositoryProvider.future);
    return repository.getAll();
  }

  /// Adds a new foreshadowing entry and refreshes the state.
  Future<void> add(ForeshadowingEntry entry) async {
    final repository = await ref.read(foreshadowingRepositoryProvider.future);
    await repository.add(entry);
    ref.invalidateSelf();
  }

  /// Updates an existing foreshadowing entry and refreshes the state.
  Future<void> save(ForeshadowingEntry entry) async {
    final repository = await ref.read(foreshadowingRepositoryProvider.future);
    await repository.update(entry);
    ref.invalidateSelf();
  }

  /// Deletes a foreshadowing entry by ID and refreshes the state.
  Future<void> delete(String id) async {
    final repository = await ref.read(foreshadowingRepositoryProvider.future);
    await repository.delete(id);
    ref.invalidateSelf();
  }

  /// Marks an entry as resolved with the given resolved chapter.
  ///
  /// Finds the entry by ID, updates status and resolved chapter,
  /// then persists through the repository.
  Future<void> markResolved(String id, {required int resolvedChapter}) async {
    final repository = await ref.read(foreshadowingRepositoryProvider.future);
    final entry = repository.getById(id);
    if (entry == null) return;
    await repository.update(
      entry.copyWith(
        status: ForeshadowingStatus.resolved,
        resolvedChapter: resolvedChapter,
      ),
    );
    ref.invalidateSelf();
  }

  /// Marks an entry as abandoned.
  ///
  /// Finds the entry by ID, updates status, then persists.
  Future<void> markAbandoned(String id) async {
    final repository = await ref.read(foreshadowingRepositoryProvider.future);
    final entry = repository.getById(id);
    if (entry == null) return;
    await repository.update(
      entry.copyWith(status: ForeshadowingStatus.abandoned),
    );
    ref.invalidateSelf();
  }

  /// Computes reminders for the given chapter using the reminder service.
  ///
  /// Operates on the current in-memory state, so it works even if
  /// the async state is still loading (returns empty in that case).
  List<ForeshadowingReminder> remindersForChapter({
    required int currentChapter,
    required int defaultThreshold,
  }) {
    final entries = state.asData?.value ?? [];
    final service = ref.read(foreshadowingReminderServiceProvider);
    return service.findReminders(
      entries: entries,
      currentChapter: currentChapter,
      defaultThreshold: defaultThreshold,
    );
  }
}
