/// Chinese sentence segmentation utility.
///
/// Splits Chinese text on sentence-ending punctuation boundaries:
/// period (。), exclamation (！), question mark (？), and ellipsis (…).
///
/// Handles edge cases:
/// - Double ellipsis (……) is treated as a single boundary
/// - Punctuation is preserved at the end of each segment
/// - Empty input returns an empty list
/// - Text without punctuation returns a single-element list
library;

/// Utility class for segmenting Chinese text into sentences.
///
/// Uses a stateful parser approach (not naive regex) to handle
/// consecutive punctuation and double ellipsis correctly.
abstract class SentenceSegmenter {
  SentenceSegmenter._();

  /// Segments [text] into individual sentences.
  ///
  /// Splits on sentence-ending punctuation (。！？…) while preserving
  /// the punctuation at the end of each segment. Consecutive identical
  /// sentence-ending punctuation (e.g., ！！！, ……) is grouped as a single
  /// boundary and kept intact.
  ///
  /// Returns an empty list for empty input.
  static List<String> segment(String text) {
    if (text.isEmpty) return [];

    final sentences = <String>[];
    final buffer = StringBuffer();
    final punctuationBuffer = StringBuffer();
    final runes = text.runes.toList();

    for (var i = 0; i < runes.length; i++) {
      final char = String.fromCharCode(runes[i]);

      if (_isSentenceEnd(char)) {
        punctuationBuffer.write(char);

        // Check if the NEXT character is the same sentence-ending punctuation.
        // If so, keep accumulating (e.g., ！！！ or …… stays as one group).
        final nextChar = i + 1 < runes.length
            ? String.fromCharCode(runes[i + 1])
            : null;
        if (nextChar != null && nextChar == char && _isSentenceEnd(nextChar)) {
          continue; // More of the same punctuation coming
        }

        // End of the punctuation group -- flush with buffer
        sentences.add(buffer.toString() + punctuationBuffer.toString());
        buffer.clear();
        punctuationBuffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Remaining text without trailing punctuation
    if (buffer.isNotEmpty) {
      sentences.add(buffer.toString());
    }

    return sentences;
  }

  /// Checks if a character is a sentence-ending punctuation mark.
  static bool _isSentenceEnd(String char) {
    return char == '。' || char == '！' || char == '？' || char == '…';
  }
}
