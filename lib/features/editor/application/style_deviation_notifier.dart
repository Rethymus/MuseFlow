/// Notifier for running style deviation analysis on AI output text.
///
/// Wraps [StyleDeviationDetector] in a Riverpod notifier so the UI can
/// reactively display deviation results.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';
import 'package:museflow/features/editor/application/style_profile_notifier.dart';

/// State for the style deviation analysis flow.
class StyleDeviationState {
  /// The latest deviation result, or null when no analysis has been run.
  final StyleDeviationResult? result;

  /// Whether analysis is in progress.
  final bool isAnalyzing;

  const StyleDeviationState({
    this.result,
    this.isAnalyzing = false,
  });

  StyleDeviationState copyWith({
    StyleDeviationResult? result,
    bool? isAnalyzing,
  }) {
    return StyleDeviationState(
      result: result ?? this.result,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}

/// Notifier that analyzes AI text against the author's style profile.
class StyleDeviationNotifier extends Notifier<StyleDeviationState> {
  static const _detector = StyleDeviationDetector();

  @override
  StyleDeviationState build() => const StyleDeviationState();

  /// Analyzes AI-generated text against the current author style profile.
  ///
  /// Returns immediately with the result. If the profile has insufficient
  /// data or the text is too short, [result] will be null.
  void analyzeText(String text) {
    final profile = ref.read(styleProfileNotifierProvider).profile;
    if (profile == null || !profile.hasData) {
      state = const StyleDeviationState();
      return;
    }

    final result = _detector.analyze(text: text, profile: profile);
    state = StyleDeviationState(result: result);
  }

  /// Clears the current deviation result.
  void reset() {
    state = const StyleDeviationState();
  }
}

/// Provider for the style deviation notifier.
final styleDeviationNotifierProvider =
    NotifierProvider<StyleDeviationNotifier, StyleDeviationState>(
  StyleDeviationNotifier.new,
);
