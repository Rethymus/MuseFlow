/// Sentence-level diff calculator for AI text modifications.
///
/// Compares original text with AI-generated text by splitting both into
/// sentences via [SentenceSegmenter] and pairing them by position.
library;

import 'package:museflow/features/editor/application/sentence_segmenter.dart';
import 'package:museflow/features/editor/domain/diff_state.dart';

/// Utility class for computing sentence-level diffs between original and AI text.
///
/// Uses [SentenceSegmenter] to split both texts into sentences, then aligns
/// similar sentences before emitting only the actual changes. This avoids
/// cascading false modifications when the AI inserts or removes a sentence.
class DiffCalculator {
  /// Calculates a [DiffResult] comparing [originalText] with [aiText].
  ///
  /// Parameters:
  /// - [originalText]: The text before AI modification
  /// - [aiText]: The AI-generated replacement text
  /// - [nodeId]: The document node ID containing the text
  /// - [startOffset]: Character offset where the original text starts in the node
  ///
  /// Returns a [DiffResult] with sentence-level diffs, all in [DiffStatus.pending].
  static DiffResult calculate(
    String originalText,
    String aiText,
    String nodeId,
    int startOffset,
  ) {
    final originalSentences = SentenceSegmenter.segment(originalText);
    final aiSentences = SentenceSegmenter.segment(aiText);

    final alignment = _alignSentences(originalSentences, aiSentences);
    final diffs = _buildDiffs(
      alignment,
      originalSentences,
      aiSentences,
      nodeId,
      startOffset,
    );

    return DiffResult(sentences: diffs, nodeId: nodeId);
  }

  static List<_AlignmentStep> _alignSentences(
    List<String> originalSentences,
    List<String> aiSentences,
  ) {
    final originalLength = originalSentences.length;
    final aiLength = aiSentences.length;
    final scores = List.generate(
      originalLength + 1,
      (_) => List<double>.filled(aiLength + 1, 0),
    );

    for (var i = 1; i <= originalLength; i++) {
      for (var j = 1; j <= aiLength; j++) {
        final similarity = _sentenceSimilarity(
          originalSentences[i - 1],
          aiSentences[j - 1],
        );
        final matchScore = similarity >= _minimumMatchSimilarity
            ? scores[i - 1][j - 1] + similarity
            : double.negativeInfinity;
        final deleteScore = scores[i - 1][j];
        final insertScore = scores[i][j - 1];

        scores[i][j] = [
          matchScore,
          deleteScore,
          insertScore,
        ].reduce((a, b) => a > b ? a : b);
      }
    }

    final steps = <_AlignmentStep>[];
    var i = originalLength;
    var j = aiLength;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final similarity = _sentenceSimilarity(
          originalSentences[i - 1],
          aiSentences[j - 1],
        );
        final matchScore = similarity >= _minimumMatchSimilarity
            ? scores[i - 1][j - 1] + similarity
            : double.negativeInfinity;
        if ((scores[i][j] - matchScore).abs() < _scoreEpsilon) {
          steps.add(_AlignmentStep(originalIndex: i - 1, aiIndex: j - 1));
          i--;
          j--;
          continue;
        }
      }

      if (i > 0 && (j == 0 || scores[i - 1][j] >= scores[i][j - 1])) {
        steps.add(_AlignmentStep(originalIndex: i - 1));
        i--;
      } else {
        steps.add(_AlignmentStep(aiIndex: j - 1));
        j--;
      }
    }

    return steps.reversed.toList();
  }

  static List<SentenceDiff> _buildDiffs(
    List<_AlignmentStep> alignment,
    List<String> originalSentences,
    List<String> aiSentences,
    String nodeId,
    int startOffset,
  ) {
    final diffs = <SentenceDiff>[];
    var offset = startOffset;

    for (var i = 0; i < alignment.length; i++) {
      final step = alignment[i];
      final originalIndex = step.originalIndex;
      final aiIndex = step.aiIndex;

      if (originalIndex != null && aiIndex != null) {
        final original = originalSentences[originalIndex];
        final ai = aiSentences[aiIndex];
        if (original != ai) {
          diffs.add(
            SentenceDiff(
              originalText: original,
              newText: ai,
              status: DiffStatus.pending,
              nodeId: nodeId,
              startOffset: offset,
              endOffset: offset + original.length,
            ),
          );
        }
        offset += original.length;
      } else if (originalIndex != null) {
        final original = originalSentences[originalIndex];
        final nextStep = i + 1 < alignment.length ? alignment[i + 1] : null;
        final nextAiIndex = nextStep?.aiIndex;
        if (nextStep?.originalIndex == null && nextAiIndex != null) {
          diffs.add(
            SentenceDiff(
              originalText: original,
              newText: aiSentences[nextAiIndex],
              status: DiffStatus.pending,
              nodeId: nodeId,
              startOffset: offset,
              endOffset: offset + original.length,
            ),
          );
          offset += original.length;
          i++;
          continue;
        }

        diffs.add(
          SentenceDiff(
            originalText: original,
            newText: null,
            status: DiffStatus.pending,
            nodeId: nodeId,
            startOffset: offset,
            endOffset: offset + original.length,
          ),
        );
        offset += original.length;
      } else if (aiIndex != null) {
        final nextStep = i + 1 < alignment.length ? alignment[i + 1] : null;
        final nextOriginalIndex = nextStep?.originalIndex;
        if (nextStep?.aiIndex == null && nextOriginalIndex != null) {
          final original = originalSentences[nextOriginalIndex];
          diffs.add(
            SentenceDiff(
              originalText: original,
              newText: aiSentences[aiIndex],
              status: DiffStatus.pending,
              nodeId: nodeId,
              startOffset: offset,
              endOffset: offset + original.length,
            ),
          );
          offset += original.length;
          i++;
          continue;
        }

        diffs.add(
          SentenceDiff(
            originalText: null,
            newText: aiSentences[aiIndex],
            status: DiffStatus.pending,
            nodeId: nodeId,
            startOffset: offset,
            endOffset: offset,
          ),
        );
      }
    }

    return diffs;
  }

  static double _sentenceSimilarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final lcs = _longestCommonSubsequenceLength(
      a.runes.toList(),
      b.runes.toList(),
    );
    final maxLength = a.runes.length > b.runes.length
        ? a.runes.length
        : b.runes.length;
    return lcs / maxLength;
  }

  static int _longestCommonSubsequenceLength(List<int> a, List<int> b) {
    final previous = List<int>.filled(b.length + 1, 0);
    final current = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        current[j] = a[i - 1] == b[j - 1]
            ? previous[j - 1] + 1
            : (previous[j] > current[j - 1] ? previous[j] : current[j - 1]);
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  static const _minimumMatchSimilarity = 0.3;
  static const _scoreEpsilon = 0.000001;
}

class _AlignmentStep {
  const _AlignmentStep({this.originalIndex, this.aiIndex});

  final int? originalIndex;
  final int? aiIndex;
}
