import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/application/logic_guardian_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/infrastructure/guardian_annotation_repository.dart';

/// State of a guardian check operation.
enum GuardianCheckState {
  /// No check in progress.
  idle,

  /// A check is currently running.
  checking,

  /// Check completed successfully with results.
  results,

  /// Check failed with an error.
  error,
}

/// State holder for the guardian check lifecycle.
class GuardianCheckResult {
  final GuardianCheckState state;
  final List<GuardianAnnotation> annotations;
  final String? errorMessage;

  const GuardianCheckResult({
    this.state = GuardianCheckState.idle,
    this.annotations = const [],
    this.errorMessage,
  });

  GuardianCheckResult copyWith({
    GuardianCheckState? state,
    List<GuardianAnnotation>? annotations,
    String? errorMessage,
  }) {
    return GuardianCheckResult(
      state: state ?? this.state,
      annotations: annotations ?? this.annotations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// AsyncNotifier managing [GuardianAnnotation] entities and check state.
///
/// Loads annotations from [GuardianAnnotationRepository] on build.
/// Provides check lifecycle management and annotation dismissal.
class GuardianNotifier extends AsyncNotifier<GuardianCheckResult> {
  @override
  Future<GuardianCheckResult> build() async {
    final repository = await ref.watch(
      guardianAnnotationRepositoryProvider.future,
    );
    final annotations = repository.getActive();
    return GuardianCheckResult(
      state: GuardianCheckState.idle,
      annotations: annotations,
    );
  }

  /// Sets the checking state (called by GuardianCheckService).
  void setChecking() {
    final current = state.asData?.value ?? const GuardianCheckResult();
    state = AsyncData(current.copyWith(state: GuardianCheckState.checking));
  }

  /// Sets results from a completed check.
  ///
  /// Persists new annotations to the repository and updates state.
  Future<void> setResults(List<GuardianAnnotation> annotations) async {
    final repository = await ref.read(
      guardianAnnotationRepositoryProvider.future,
    );
    for (final annotation in annotations) {
      await repository.add(annotation);
    }
    final current = state.asData?.value ?? const GuardianCheckResult();
    state = AsyncData(
      current.copyWith(
        state: GuardianCheckState.results,
        annotations: annotations,
      ),
    );
  }

  /// Sets an error state with a message.
  void setError(String message) {
    final current = state.asData?.value ?? const GuardianCheckResult();
    state = AsyncData(
      current.copyWith(state: GuardianCheckState.error, errorMessage: message),
    );
  }

  /// Resets to idle state.
  void resetToIdle() {
    final current = state.asData?.value ?? const GuardianCheckResult();
    state = AsyncData(
      current.copyWith(state: GuardianCheckState.idle, errorMessage: null),
    );
  }

  /// Dismisses an annotation by ID.
  Future<void> dismiss(String id) async {
    final repository = await ref.read(
      guardianAnnotationRepositoryProvider.future,
    );
    await repository.dismiss(id);
    ref.invalidateSelf();
  }

  /// Runs a logic consistency check on the given text.
  ///
  /// Builds bounded context from all knowledge sources, calls
  /// [LogicGuardianService], persists results, and exposes
  /// non-blocking error state.
  Future<void> checkLogic({
    required String text,
    required int currentChapter,
    String? nodeId,
    int? startOffset,
    int? endOffset,
  }) async {
    setChecking();
    try {
      final logicService = await ref.read(logicGuardianServiceProvider.future);
      final context = _buildContext(
        checkedText: text,
        currentChapter: currentChapter,
      );
      final annotations = await logicService.checkLogic(
        text: text,
        context: context,
        nodeId: nodeId,
        startOffset: startOffset,
        endOffset: endOffset,
      );
      await setResults(annotations);
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Runs a combined character + logic check on the current chapter.
  ///
  /// Builds context, calls both character consistency and logic guardian
  /// services, merges results, persists, and exposes non-blocking error state.
  Future<void> checkCurrentChapter({
    required String text,
    required int currentChapter,
    String? nodeId,
    int? startOffset,
    int? endOffset,
  }) async {
    setChecking();
    try {
      final allAnnotations = <GuardianAnnotation>[];

      // Character consistency check
      try {
        final characterService = await ref.read(
          guardianCheckServiceProvider.future,
        );
        final charResults = await characterService.checkCharacterConsistency(
          text: text,
          nodeId: nodeId,
          startOffset: startOffset,
          endOffset: endOffset,
        );
        allAnnotations.addAll(charResults);
      } catch (_) {
        // Character check failure is non-blocking; continue to logic check
      }

      // Logic consistency check
      try {
        final logicService = await ref.read(
          logicGuardianServiceProvider.future,
        );
        final context = _buildContext(
          checkedText: text,
          currentChapter: currentChapter,
        );
        final logicResults = await logicService.checkLogic(
          text: text,
          context: context,
          nodeId: nodeId,
          startOffset: startOffset,
          endOffset: endOffset,
        );
        allAnnotations.addAll(logicResults);
      } catch (_) {
        // Logic check failure is non-blocking
      }

      await setResults(allAnnotations);
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Builds a [GuardianContextBundle] from all available knowledge sources.
  GuardianContextBundle _buildContext({
    required String checkedText,
    required int currentChapter,
  }) {
    final builder = ref.read(guardianContextBuilderProvider);

    // Gather characters from notifier
    final characters =
        ref
            .read(characterCardNotifierProvider)
            .asData
            ?.value
            .cast<CharacterCard>() ??
        [];

    // Gather world settings from notifier
    final worldSettings =
        ref
            .read(worldSettingNotifierProvider)
            .asData
            ?.value
            .cast<WorldSetting>() ??
        [];

    // Gather plot nodes
    final plotNodes =
        ref.read(plotNodeNotifierProvider).asData?.value.cast<PlotNode>() ?? [];

    // Gather foreshadowing entries
    final foreshadowing =
        ref
            .read(foreshadowingNotifierProvider)
            .asData
            ?.value
            .cast<ForeshadowingEntry>() ??
        [];

    // Skill constraints are not yet available in the current codebase;
    // pass empty until skill infrastructure is merged from phase 04.
    const skillConstraints = <String>[];

    return builder.build(
      checkedText: checkedText,
      currentChapter: currentChapter,
      characters: characters,
      worldSettings: worldSettings,
      skillConstraints: skillConstraints,
      plotNodes: plotNodes,
      foreshadowingEntries: foreshadowing,
    );
  }
}
