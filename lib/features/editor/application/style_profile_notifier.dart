/// Style profile notifier — manages author style analysis state.
///
/// Provides Riverpod state for:
/// - Triggering style analysis on chapters
/// - Holding the current [AuthorStyleProfile]
/// - Exposing analysis progress and errors
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/application/style_analyzer.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/infrastructure/style_profile_repository.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

/// Immutable state for the style profile feature.
class StyleProfileState {
  /// The current style profile, or null if not yet analyzed.
  final AuthorStyleProfile? profile;

  /// Whether an analysis is currently in progress.
  final bool isAnalyzing;

  /// Error message, or null if no error.
  final String? error;

  /// Number of chapters included in the last analysis.
  final int analyzedChapterCount;

  const StyleProfileState({
    this.profile,
    this.isAnalyzing = false,
    this.error,
    this.analyzedChapterCount = 0,
  });

  StyleProfileState copyWith({
    AuthorStyleProfile? profile,
    bool? isAnalyzing,
    String? error,
    int? analyzedChapterCount,
  }) {
    return StyleProfileState(
      profile: profile ?? this.profile,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
      analyzedChapterCount: analyzedChapterCount ?? this.analyzedChapterCount,
    );
  }
}

/// Notifier for author style profile management.
///
/// Orchestrates style analysis: loads chapters, runs [StyleAnalyzer],
/// persists results via [StyleProfileRepository].
class StyleProfileNotifier extends Notifier<StyleProfileState> {
  final _analyzer = StyleAnalyzer();

  @override
  StyleProfileState build() => const StyleProfileState();

  /// Analyzes the author's writing style from all chapters of a manuscript.
  ///
  /// Loads the style profile from the repository first (for incremental
  /// updates), then re-analyzes all chapters and saves the result.
  Future<void> analyzeManuscript({
    required String manuscriptId,
    required List<Chapter> chapters,
  }) async {
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final StyleProfileRepository repository = await ref.read(
        styleProfileRepositoryProvider.future,
      );

      // Load existing profile for incremental context
      final existingProfile = repository.getByManuscript(manuscriptId);

      // Run analysis
      final profile = _analyzer.analyze(
        manuscriptId: manuscriptId,
        chapters: chapters,
        alreadyAnalyzed: existingProfile != null ? chapters : null,
      );

      // Save to repository
      await repository.save(profile);

      state = state.copyWith(
        profile: profile,
        isAnalyzing: false,
        analyzedChapterCount: profile.analyzedChapterCount,
      );
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: '风格分析失败：$e');
    }
  }

  /// Loads the saved style profile for a manuscript without re-analyzing.
  Future<void> loadProfile(String manuscriptId) async {
    try {
      final StyleProfileRepository repository = await ref.read(
        styleProfileRepositoryProvider.future,
      );
      final profile = repository.getByManuscript(manuscriptId);

      state = state.copyWith(
        profile: profile,
        error: null,
        analyzedChapterCount: profile?.analyzedChapterCount ?? 0,
      );
    } catch (e) {
      state = state.copyWith(error: '加载风格档案失败：$e');
    }
  }

  /// Clears the current style profile state.
  void clear() {
    state = const StyleProfileState();
  }
}

/// Provider for the style profile notifier.
final styleProfileNotifierProvider =
    NotifierProvider<StyleProfileNotifier, StyleProfileState>(
      StyleProfileNotifier.new,
    );
