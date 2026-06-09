/// Sentence-level diff calculator for AI text modifications.
///
/// Compares original text with AI-generated text by splitting both into
/// sentences via [SentenceSegmenter] and pairing them by position.
library;

import 'package:museflow/features/editor/application/sentence_segmenter.dart';
import 'package:museflow/features/editor/domain/diff_state.dart';

/// Utility class for computing sentence-level diffs between original and AI text.
///
/// Uses [SentenceSegmenter] to split both texts into sentences, then pairs
/// them by index. For equal sentence counts, produces 1:1 modifications.
/// For unequal counts, extra sentences become insertions or deletions.
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

    final diffs = <SentenceDiff>[];
    var offset = startOffset;

    final maxLen = originalSentences.length > aiSentences.length
        ? originalSentences.length
        : aiSentences.length;

    for (var i = 0; i < maxLen; i++) {
      final hasOriginal = i < originalSentences.length;
      final hasAi = i < aiSentences.length;

      if (hasOriginal && hasAi) {
        // Modification: both original and AI sentences exist
        final orig = originalSentences[i];
        final ai = aiSentences[i];
        diffs.add(
          SentenceDiff(
            originalText: orig,
            newText: ai,
            status: DiffStatus.pending,
            nodeId: nodeId,
            startOffset: offset,
            endOffset: offset + orig.length,
          ),
        );
        offset += orig.length;
      } else if (hasOriginal) {
        // Deletion: original sentence has no AI counterpart
        final orig = originalSentences[i];
        diffs.add(
          SentenceDiff(
            originalText: orig,
            newText: null,
            status: DiffStatus.pending,
            nodeId: nodeId,
            startOffset: offset,
            endOffset: offset + orig.length,
          ),
        );
        offset += orig.length;
      } else {
        // Insertion: AI sentence has no original counterpart
        final ai = aiSentences[i];
        diffs.add(
          SentenceDiff(
            originalText: null,
            newText: ai,
            status: DiffStatus.pending,
            nodeId: nodeId,
            startOffset: offset,
            endOffset: offset + ai.length,
          ),
        );
        offset += ai.length;
      }
    }

    return DiffResult(sentences: diffs, nodeId: nodeId);
  }
}
