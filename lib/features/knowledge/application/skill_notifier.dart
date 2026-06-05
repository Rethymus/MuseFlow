import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';

class SkillGenerationState {
  final String progressText;
  final SkillDocument? document;
  final String? error;

  const SkillGenerationState({
    this.progressText = '',
    this.document,
    this.error,
  });

  SkillGenerationState copyWith({
    String? progressText,
    SkillDocument? document,
    String? error,
  }) {
    return SkillGenerationState(
      progressText: progressText ?? this.progressText,
      document: document ?? this.document,
      error: error,
    );
  }
}

class SkillGenerationNotifier extends AsyncNotifier<SkillGenerationState> {
  bool _cancelled = false;

  @override
  Future<SkillGenerationState> build() async => const SkillGenerationState();

  Future<void> generateSkill(String conceptDescription, String skillName) async {
    _cancelled = false;
    state = const AsyncData(SkillGenerationState());
    try {
      final service = await ref.read(skillGenerationServiceProvider.future);
      final repository = await ref.read(skillRepositoryProvider.future);
      final buffer = StringBuffer();

      await for (final token in service.generateSkillStream(conceptDescription)) {
        if (_cancelled) return;
        buffer.write(token);
        state = AsyncData(SkillGenerationState(progressText: buffer.toString()));
      }

      final parsed = service.parseSkillDocument(
        name: skillName,
        description: conceptDescription,
        rawContent: buffer.toString(),
      );
      final saved = await repository.add(parsed);
      ref.invalidate(skillListNotifierProvider);
      ref.invalidate(nameIndexServiceProvider);
      state = AsyncData(
        SkillGenerationState(
          progressText: buffer.toString(),
          document: saved,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void cancel() {
    _cancelled = true;
  }

  Future<void> saveEdited(SkillDocument document) async {
    final repository = await ref.read(skillRepositoryProvider.future);
    await repository.update(document);
    ref.invalidate(skillListNotifierProvider);
    ref.invalidate(nameIndexServiceProvider);
    state = AsyncData(SkillGenerationState(document: document));
  }
}

class SkillListNotifier extends AsyncNotifier<List<SkillDocument>> {
  @override
  Future<List<SkillDocument>> build() async {
    final repository = await ref.watch(skillRepositoryProvider.future);
    return repository.getAll();
  }

  Future<void> toggleActive(String id) async {
    final repository = await ref.read(skillRepositoryProvider.future);
    final document = repository.getById(id);
    if (document == null) return;
    await repository.setActive(id, !document.isActive);
    ref.invalidate(skillEnforcementMiddlewareProvider);
    ref.invalidate(nameIndexServiceProvider);
    ref.invalidateSelf();
  }

  Future<void> save(SkillDocument document) async {
    final repository = await ref.read(skillRepositoryProvider.future);
    await repository.update(document);
    ref.invalidate(nameIndexServiceProvider);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repository = await ref.read(skillRepositoryProvider.future);
    await repository.delete(id);
    ref.invalidate(nameIndexServiceProvider);
    ref.invalidateSelf();
  }
}

class DeviationNotifier extends AsyncNotifier<DeviationResult> {
  @override
  Future<DeviationResult> build() async => const DeviationResult(warnings: []);

  Future<void> checkDeviations(String text) async {
    final repository = await ref.read(skillRepositoryProvider.future);
    final activeSkills = repository.getActive();
    if (activeSkills.isEmpty || text.trim().isEmpty) {
      state = const AsyncData(DeviationResult(warnings: []));
      return;
    }
    final service = await ref.read(deviationDetectionServiceProvider.future);
    final result = await service.detectDeviations(text, activeSkills);
    state = AsyncData(result);
  }

  void dismissWarning(int index) {
    final current = state.asData?.value ?? const DeviationResult(warnings: []);
    if (index < 0 || index >= current.warnings.length) return;
    final warnings = [...current.warnings]..removeAt(index);
    state = AsyncData(DeviationResult(warnings: warnings));
  }

  void clearAll() {
    state = const AsyncData(DeviationResult(warnings: []));
  }
}
