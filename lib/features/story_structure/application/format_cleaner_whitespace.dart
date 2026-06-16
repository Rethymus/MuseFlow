part of 'format_cleaner.dart';

// ---------------------------------------------------------------------------
// Whitespace normalization
// ---------------------------------------------------------------------------

/// Normalizes CRLF and CR line endings to LF.
extension _FormatCleanerWhitespace on FormatCleaner {
  String _normalizeLineEndings(String text, List<FormatChange> changes) {
    if (!text.contains('\r')) return text;

    var result = text;
    // CRLF -> LF first, then standalone CR -> LF
    if (result.contains('\r\n')) {
      result = result.replaceAll('\r\n', '\n');
    }
    if (result.contains('\r')) {
      result = result.replaceAll('\r', '\n');
    }

    if (result != text) {
      changes.add(
        FormatChange(
          category: FormatChangeCategory.whitespace,
          original: text,
          replacement: result,
          startOffset: 0,
          endOffset: text.length,
          explanation: '统一换行符为 LF',
        ),
      );
    }

    return result;
  }

  /// Trims trailing whitespace from each line.
  String _trimTrailingWhitespace(String text, List<FormatChange> changes) {
    final lines = text.split('\n');
    var modified = false;
    final newLines = <String>[];
    var offset = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimRight();
      if (trimmed.length != line.length) {
        modified = true;
        changes.add(
          FormatChange(
            category: FormatChangeCategory.whitespace,
            original: line.substring(trimmed.length),
            replacement: '',
            startOffset: offset + trimmed.length,
            endOffset: offset + line.length,
            explanation: '去除行末空白',
          ),
        );
      }
      newLines.add(trimmed);
      offset += line.length + 1; // +1 for the \n
    }

    return modified ? newLines.join('\n') : text;
  }

  // ---------------------------------------------------------------------------
  // Paragraph spacing normalization
  // ---------------------------------------------------------------------------

  /// Collapses three or more consecutive blank lines into exactly one.
  String _collapseBlankLines(String text, List<FormatChange> changes) {
    // Pattern: 3 or more consecutive newlines (which means 2+ blank lines)
    final pattern = RegExp('\n{3,}');
    final match = pattern.firstMatch(text);

    if (match == null) return text;

    // Replace all occurrences of 3+ newlines with exactly 2 (one blank line)
    final result = text.replaceAll(pattern, '\n\n');

    if (result != text) {
      changes.add(
        FormatChange(
          category: FormatChangeCategory.paragraph,
          original: text,
          replacement: result,
          startOffset: 0,
          endOffset: text.length,
          explanation: '合并多余空行',
        ),
      );
    }

    return result;
  }
}
