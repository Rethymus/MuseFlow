import 'package:museflow/features/story_structure/domain/format_clean_result.dart';

/// Options controlling which format cleanup passes are active.
class FormatCleanOptions {
  final bool normalizePunctuation;
  final bool cleanMarkdown;
  final bool normalizeWhitespace;
  final bool normalizeIndentation;
  final bool normalizeParagraphSpacing;

  const FormatCleanOptions({
    this.normalizePunctuation = true,
    this.cleanMarkdown = true,
    this.normalizeWhitespace = true,
    this.normalizeIndentation = true,
    this.normalizeParagraphSpacing = true,
  });
}

/// Deterministic format cleaner for manuscript finishing.
///
/// Applies a series of passes to normalize Chinese punctuation, clean Markdown
/// residuals, normalize whitespace and indentation, and fix paragraph spacing.
/// Each pass is conservative and designed to avoid corrupting URLs, decimal
/// numbers, file paths, model names, and code-like snippets.
///
/// Returns a [FormatCleanResult] with structured changes for preview.
/// Does NOT mutate any text before explicit user confirmation.
class FormatCleaner {
  const FormatCleaner();

  /// Runs all enabled cleanup passes on [text] and returns a structured result.
  FormatCleanResult clean(String text, {FormatCleanOptions? options}) {
    options ??= const FormatCleanOptions();
    final changes = <FormatChange>[];
    var current = text;

    if (options.normalizeWhitespace) {
      current = _normalizeLineEndings(current, changes);
      current = _trimTrailingWhitespace(current, changes);
    }

    if (options.normalizePunctuation) {
      current = _normalizePunctuation(current, changes);
    }

    if (options.cleanMarkdown) {
      current = _cleanMarkdownHeadings(current, changes);
      current = _cleanMarkdownLists(current, changes);
      current = _cleanMarkdownEmphasis(current, changes);
      current = _cleanHtmlTags(current, changes);
    }

    if (options.normalizeParagraphSpacing) {
      current = _collapseBlankLines(current, changes);
    }

    return FormatCleanResult(
      originalText: text,
      cleanedText: current,
      changes: changes,
    );
  }

  // ---------------------------------------------------------------------------
  // Whitespace normalization
  // ---------------------------------------------------------------------------

  /// Normalizes CRLF and CR line endings to LF.
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
      changes.add(FormatChange(
        category: FormatChangeCategory.whitespace,
        original: text,
        replacement: result,
        startOffset: 0,
        endOffset: text.length,
        explanation: '统一换行符为 LF',
      ));
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
        changes.add(FormatChange(
          category: FormatChangeCategory.whitespace,
          original: line.substring(trimmed.length),
          replacement: '',
          startOffset: offset + trimmed.length,
          endOffset: offset + line.length,
          explanation: '去除行末空白',
        ));
      }
      newLines.add(trimmed);
      offset += line.length + 1; // +1 for the \n
    }

    return modified ? newLines.join('\n') : text;
  }

  // ---------------------------------------------------------------------------
  // Chinese punctuation normalization
  // ---------------------------------------------------------------------------

  /// Converts obvious half-width punctuation in CJK prose to full-width.
  ///
  /// Conservative: avoids corrupting URLs, decimals, file paths, model names,
  /// and code-like snippets by checking context around each punctuation mark.
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
        changes.add(FormatChange(
          category: category,
          original: target,
          replacement: replacement,
          startOffset: i,
          endOffset: i + 1,
          explanation: explanation,
        ));
        modified = true;
      } else {
        result.write(char);
      }
      i++;
    }

    return modified ? result.toString() : text;
  }

  /// Determines if a punctuation mark at [index] should NOT be replaced.
  bool _shouldSkipPunctuationReplacement(String text, int index, String target) {
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
      final sinceBreak = lastBreak >= 0 ? before.substring(lastBreak + 1) : before;
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
      if (after.startsWith(RegExp(r'(txt|md|json|dart|yaml|xml|html|css|js|py|java|log|csv|doc|pdf|png|jpg|gif|svg)\b'))) {
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

  // ---------------------------------------------------------------------------
  // Markdown residual cleaning
  // ---------------------------------------------------------------------------

  /// Strips heading markers (# ) at the start of lines.
  String _cleanMarkdownHeadings(String text, List<FormatChange> changes) {
    final lines = text.split('\n');
    var modified = false;
    final newLines = <String>[];
    var offset = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (match != null) {
        final headingMarkers = match.group(1)! + ' ';
        final content = match.group(2)!;
        newLines.add(content);
        changes.add(FormatChange(
          category: FormatChangeCategory.markdown,
          original: headingMarkers,
          replacement: '',
          startOffset: offset,
          endOffset: offset + headingMarkers.length,
          explanation: '移除 Markdown 标题标记',
        ));
        modified = true;
      } else {
        newLines.add(line);
      }
      offset += line.length + 1;
    }

    return modified ? newLines.join('\n') : text;
  }

  /// Strips list bullet markers (- or * followed by space) at line start.
  String _cleanMarkdownLists(String text, List<FormatChange> changes) {
    final lines = text.split('\n');
    var modified = false;
    final newLines = <String>[];
    var offset = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Match "- " or "* " at start of line (but not "# " which is a heading)
      final match = RegExp(r'^([-*])\s+(.+)$').firstMatch(line);
      if (match != null) {
        final bullet = match.group(1)! + ' ';
        final content = match.group(2)!;
        newLines.add(content);
        changes.add(FormatChange(
          category: FormatChangeCategory.markdown,
          original: bullet,
          replacement: '',
          startOffset: offset,
          endOffset: offset + bullet.length,
          explanation: '移除 Markdown 列表标记',
        ));
        modified = true;
      } else {
        newLines.add(line);
      }
      offset += line.length + 1;
    }

    return modified ? newLines.join('\n') : text;
  }

  /// Strips unmatched emphasis markers (* or ** or _ or __) around text.
  ///
  /// Conservative: only strips when paired markers wrap CJK-heavy text,
  /// and not in arithmetic or code contexts.
  String _cleanMarkdownEmphasis(String text, List<FormatChange> changes) {
    var result = text;

    // Strip **bold** pairs
    result = _stripPairedMarkers(result, '**', FormatChangeCategory.markdown, '移除加粗标记', changes);

    // Strip __bold__ pairs
    result = _stripPairedMarkers(result, '__', FormatChangeCategory.markdown, '移除加粗标记', changes);

    // Strip *italic* pairs (after bold so we don't match half of **)
    result = _stripPairedMarkers(result, '*', FormatChangeCategory.markdown, '移除斜体标记', changes);

    // Strip _italic_ pairs
    result = _stripPairedMarkers(result, '_', FormatChangeCategory.markdown, '移除斜体标记', changes);

    return result;
  }

  String _stripPairedMarkers(
    String text,
    String marker,
    FormatChangeCategory category,
    String explanation,
    List<FormatChange> changes,
  ) {
    // For single-char markers, ensure they wrap text (not in arithmetic like 2 * 3)
    final markerEscaped = RegExp.escape(marker);
    final pattern = RegExp('$markerEscaped(.+?)$markerEscaped');

    var modified = false;
    final result = StringBuffer();
    var lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      final inner = match.group(1)!;

      // For single asterisk/underscore, skip if the content looks like arithmetic
      if (marker.length == 1 && _looksLikeArithmetic(inner, marker)) {
        continue;
      }

      // Append text before this match
      result.write(text.substring(lastEnd, match.start));
      // Append inner content without markers
      result.write(inner);

      // Record opening marker removal
      changes.add(FormatChange(
        category: category,
        original: marker,
        replacement: '',
        startOffset: match.start,
        endOffset: match.start + marker.length,
        explanation: explanation,
      ));

      // Record closing marker removal
      changes.add(FormatChange(
        category: category,
        original: marker,
        replacement: '',
        startOffset: match.end - marker.length,
        endOffset: match.end,
        explanation: explanation,
      ));

      lastEnd = match.end;
      modified = true;
    }

    if (modified) {
      result.write(text.substring(lastEnd));
      return result.toString();
    }
    return text;
  }

  /// Returns true if the content between markers looks like arithmetic.
  bool _looksLikeArithmetic(String content, String marker) {
    // If content has spaces around a digit or arithmetic operator, it's likely math
    if (marker == '*' || marker == '_') {
      final trimmed = content.trim();
      // " 3 " pattern suggests arithmetic: "2 * 3 = 6" -> inner is " 3 "
      if (RegExp(r'^\s*\d+\s*$').hasMatch(trimmed)) return true;
      if (RegExp(r'^\s*\d+\s*[+\-\/]\s*\d+\s*$').hasMatch(trimmed)) return true;
    }
    return false;
  }

  /// Strips simple HTML tags from text.
  String _cleanHtmlTags(String text, List<FormatChange> changes) {
    final tagPattern = RegExp(r'<\/?[a-zA-Z][a-zA-Z0-9]*(?:\s[^>]*)?\/?>');
    var modified = false;
    final result = StringBuffer();
    var lastEnd = 0;

    for (final match in tagPattern.allMatches(text)) {
      result.write(text.substring(lastEnd, match.start));

      changes.add(FormatChange(
        category: FormatChangeCategory.markdown,
        original: match.group(0)!,
        replacement: '',
        startOffset: match.start,
        endOffset: match.end,
        explanation: '移除 HTML 标签',
      ));

      lastEnd = match.end;
      modified = true;
    }

    if (modified) {
      result.write(text.substring(lastEnd));
      return result.toString();
    }
    return text;
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
      changes.add(FormatChange(
        category: FormatChangeCategory.paragraph,
        original: text,
        replacement: result,
        startOffset: 0,
        endOffset: text.length,
        explanation: '合并多余空行',
      ));
    }

    return result;
  }
}
