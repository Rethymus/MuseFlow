/// A single excerpt presented to the human evaluator in the blind-read test.
///
/// The human reads the text and judges whether it was AI-generated (true)
/// or human-written (false). humanVerdict is null until judged.
class BlindReadExcerpt {
  const BlindReadExcerpt({
    required this.text,
    required this.chapterId,
    required this.chapterIndex,
    this.humanVerdict,
  });

  /// The excerpt text to be evaluated.
  final String text;

  /// ID of the source chapter.
  final String chapterId;

  /// Index of the source chapter (1-based).
  final int chapterIndex;

  /// Human verdict: null = not yet judged, true = judged as AI, false = judged as human.
  final bool? humanVerdict;

  BlindReadExcerpt copyWith({
    String? text,
    String? chapterId,
    int? chapterIndex,
    bool? humanVerdict,
  }) {
    return BlindReadExcerpt(
      text: text ?? this.text,
      chapterId: chapterId ?? this.chapterId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      humanVerdict: humanVerdict ?? this.humanVerdict,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlindReadExcerpt &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          chapterId == other.chapterId &&
          chapterIndex == other.chapterIndex &&
          humanVerdict == other.humanVerdict;

  @override
  int get hashCode =>
      text.hashCode ^
      chapterId.hashCode ^
      chapterIndex.hashCode ^
      humanVerdict.hashCode;
}

/// Result of the blind-read anti-AI-scent evaluation.
///
/// Tracks excerpts with human verdicts and computes the overall score.
/// Score = correctCount / totalJudged. A lower score means better
/// anti-AI-scent (harder for humans to identify AI-generated content).
class BlindReadResult {
  BlindReadResult({
    required this.excerpts,
    required this.correctCount,
  });

  /// All excerpts presented, with their verdicts.
  final List<BlindReadExcerpt> excerpts;

  /// Number of correct human judgments.
  final int correctCount;

  /// Number of excerpts that have been judged (humanVerdict != null).
  int get totalJudged =>
      excerpts.where((e) => e.humanVerdict != null).length;

  /// Score = correctCount / totalJudged (0.0 to 1.0).
  /// Returns 0.0 if no excerpts have been judged.
  double get score =>
      totalJudged == 0 ? 0.0 : correctCount / totalJudged;

  BlindReadResult copyWith({
    List<BlindReadExcerpt>? excerpts,
    int? correctCount,
  }) {
    return BlindReadResult(
      excerpts: excerpts ?? this.excerpts,
      correctCount: correctCount ?? this.correctCount,
    );
  }
}
