import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
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
    final repository =
        await ref.watch(guardianAnnotationRepositoryProvider.future);
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
    final repository =
        await ref.read(guardianAnnotationRepositoryProvider.future);
    for (final annotation in annotations) {
      await repository.add(annotation);
    }
    final current = state.asData?.value ?? const GuardianCheckResult();
    state = AsyncData(current.copyWith(
      state: GuardianCheckState.results,
      annotations: annotations,
    ));
  }

  /// Sets an error state with a message.
  void setError(String message) {
    final current = state.asData?.value ?? const GuardianCheckResult();
    state = AsyncData(current.copyWith(
      state: GuardianCheckState.error,
      errorMessage: message,
    ));
  }

  /// Resets to idle state.
  void resetToIdle() {
    final current = state.asData?.value ?? const GuardianCheckResult();
    state = AsyncData(current.copyWith(
      state: GuardianCheckState.idle,
      errorMessage: null,
    ));
  }

  /// Dismisses an annotation by ID.
  Future<void> dismiss(String id) async {
    final repository =
        await ref.read(guardianAnnotationRepositoryProvider.future);
    await repository.dismiss(id);
    ref.invalidateSelf();
  }
}
