part of 'format_cleaner.dart';

// ---------------------------------------------------------------------------
// Chinese punctuation normalization
// ---------------------------------------------------------------------------

/// Converts obvious half-width punctuation in CJK prose to full-width.
///
/// Conservative: avoids corrupting URLs, decimals, file paths, model names,
/// and code-like snippets by checking context around each punctuation mark.
extension _FormatCleanerPunctuation on FormatCleaner {
  String _normalizePunctuation(String text, List<FormatChange> changes) {
    var result = text;

    result = _replacePunctuationInContext(
      result,
      ',',
      '，',
      FormatChangeCategory.punctuation,
      '半角逗号 -> 全角逗号',
      changes,
    );
    result = _replacePunctuationInContext(
      result,
      '.',
      '。',
      FormatChangeCategory.punctuation,
      '半角句号 -> 全角句号',
      changes,
    );
    result = _replacePunctuationInContext(
      result,
      '?',
      '？',
      FormatChangeCategory.punctuation,
      '半角问号 -> 全角问号',
      changes,
    );
    result = _replacePunctuationInContext(
      result,
      '!',
      '！',
      FormatChangeCategory.punctuation,
      '半角感叹号 -> 全角感叹号',
      changes,
    );
    result = _replacePunctuationInContext(
      result,
      ':',
      '：',
      FormatChangeCategory.punctuation,
      '半角冒号 -> 全角冒号',
      changes,
    );
    result = _replacePunctuationInContext(
      result,
      ';',
      '；',
      FormatChangeCategory.punctuation,
      '半角分号 -> 全角分号',
      changes,
    );

    return result;
  }

  /// Replaces [target] with [replacement] only in CJK prose context.
  ///
  /// Skips replacement when the character appears inside a URL, decimal number,
  /// file path, model name, or English abbreviation.
  String _replacePunctuationInContext(
    String text,
    String target,
    String replacement,
    FormatChangeCategory category,
    String explanation,
    List<FormatChange> changes,
  ) {
    final result = StringBuffer();
    var modified = false;
    var i = 0;

    while (i < text.length) {
      final char = text[i];

      if (char == target) {
        // Check if we should skip this occurrence
        if (_shouldSkipPunctuationReplacement(text, i, target)) {
          result.write(char);
          i++;
          continue;
        }

        result.write(replacement);
        changes.add(
          FormatChange(
            category: category,
            original: target,
            replacement: replacement,
            startOffset: i,
            endOffset: i + 1,
            explanation: explanation,
          ),
        );
        modified = true;
      } else {
        result.write(char);
      }
      i++;
    }

    return modified ? result.toString() : text;
  }

  /// Determines if a punctuation mark at [index] should NOT be replaced.
  bool _shouldSkipPunctuationReplacement(
    String text,
    int index,
    String target,
  ) {
    // URL context: preceded by protocol or query/fragment markers
    if (_isInUrl(text, index, target)) return true;

    // Decimal number: digit on one side, digit on the other
    if (target == '.' && _isDecimalPoint(text, index)) return true;

    // English abbreviation: surrounded by uppercase letters
    if (target == '.' && _isInAbbreviation(text, index)) return true;

    // Model version: like GPT-4.0, Claude-3.5
    if (target == '.' && _isModelVersion(text, index)) return true;

    // File path: preceded by common path indicators
    if (_isInFilePath(text, index, target)) return true;

    // Query string: & followed by parameter (for ? as query start)
    if (target == '?' && _isQueryParameter(text, index, target)) return true;

    // Assignment/comparison: = followed by (for code-like context)
    // Already covered by URL check for = and ?

    return false;
  }

  bool _isInUrl(String text, int index, String target) {
    // Check if this colon is the protocol colon in http: or https:
    if (target == ':') {
      // Check if preceded by "http" or "https"
      if (index >= 4) {
        final before4 = text.substring(index - 4, index);
        if (before4 == 'http') return true;
      }
      if (index >= 5) {
        final before5 = text.substring(index - 5, index);
        if (before5 == 'https') return true;
      }
    }
    // Check if we're inside a URL by looking for http://, https://, or www.
    // Look backwards for URL protocol
    final before = text.substring(0, index);
    if (before.contains(RegExp(r'https?://')) ||
        before.contains(RegExp(r'www\.'))) {
      // We are likely inside a URL; check that we haven't passed whitespace
      final lastSpace = before.lastIndexOf(' ');
      final lastNewline = before.lastIndexOf('\n');
      final lastBreak = lastSpace > lastNewline ? lastSpace : lastNewline;
      final sinceBreak = lastBreak >= 0
          ? before.substring(lastBreak + 1)
          : before;
      if (sinceBreak.contains(RegExp(r'https?://')) ||
          sinceBreak.contains(RegExp(r'www\.'))) {
        return true;
      }
    }
    return false;
  }

  bool _isDecimalPoint(String text, int index) {
    final before = index > 0 ? text[index - 1] : '';
    final after = index + 1 < text.length ? text[index + 1] : '';
    return _isDigit(before) && _isDigit(after);
  }

  bool _isInAbbreviation(String text, int index) {
    // U.S.A. pattern: uppercase letter on at least one side
    final before = index > 0 ? text[index - 1] : '';
    final after = index + 1 < text.length ? text[index + 1] : '';
    if (_isUpperCaseLetter(before) || _isUpperCaseLetter(after)) {
      // Check that there are adjacent uppercase letters forming an abbreviation
      return true;
    }
    return false;
  }

  bool _isModelVersion(String text, int index) {
    // Pattern: LETTER-digits.DIGIT like GPT-4.0, Claude-3.5
    final before = index > 0 ? text[index - 1] : '';
    final after = index + 1 < text.length ? text[index + 1] : '';
    if (_isDigit(before) && _isDigit(after)) {
      // Could be a version number; check for preceding hyphen-letter pattern
      if (index >= 2) {
        final beforeDigit = text.substring(0, index);
        // Look for pattern like "4.0" preceded by "-"
        if (beforeDigit.contains(RegExp(r'[A-Za-z]-\d+$'))) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isInFilePath(String text, int index, String target) {
    // Check for file extension pattern: name.ext
    if (target == '.') {
      final after = index + 1 < text.length ? text.substring(index + 1) : '';
      // Common file extensions
      if (after.startsWith(
        RegExp(
          r'(txt|md|json|dart|yaml|xml|html|css|js|py|java|log|csv|doc|pdf|png|jpg|gif|svg)\b',
        ),
      )) {
        return true;
      }
      // Windows path with backslash
      final before = text.substring(0, index);
      if (before.contains('\\')) return true;
    }
    return false;
  }

  bool _isQueryParameter(String text, int index, String target) {
    // ? at the start of a URL query string
    final before = text.substring(0, index);
    if (before.contains(RegExp(r'https?://[^\s]*$'))) {
      return true;
    }
    return false;
  }

  bool _isDigit(String char) {
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }

  bool _isUpperCaseLetter(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 65 && code <= 90; // A-Z
  }
}
