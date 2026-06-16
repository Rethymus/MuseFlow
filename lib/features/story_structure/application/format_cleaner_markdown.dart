part of 'format_cleaner.dart';

// ---------------------------------------------------------------------------
// Markdown residual cleaning
// ---------------------------------------------------------------------------

/// Strips heading markers (# ) at the start of lines.
extension _FormatCleanerMarkdown on FormatCleaner {
  String _cleanMarkdownHeadings(String text, List<FormatChange> changes) {
    final lines = text.split('\n');
    var modified = false;
    final newLines = <String>[];
    var offset = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (match != null) {
        final headingMarkers = '${match.group(1)!} ';
        final content = match.group(2)!;
        newLines.add(content);
        changes.add(
          FormatChange(
            category: FormatChangeCategory.markdown,
            original: headingMarkers,
            replacement: '',
            startOffset: offset,
            endOffset: offset + headingMarkers.length,
            explanation: '移除 Markdown 标题标记',
          ),
        );
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
        final bullet = '${match.group(1)!} ';
        final content = match.group(2)!;
        newLines.add(content);
        changes.add(
          FormatChange(
            category: FormatChangeCategory.markdown,
            original: bullet,
            replacement: '',
            startOffset: offset,
            endOffset: offset + bullet.length,
            explanation: '移除 Markdown 列表标记',
          ),
        );
        modified = true;
      } else {
        newLines.add(line);
      }
      offset += line.length + 1;
    }

    return modified ? newLines.join('\n') : text;
  }

  /// Strips fenced code block markers while preserving contained prose.
  String _cleanMarkdownCodeFences(String text, List<FormatChange> changes) {
    if (!text.contains('```')) return text;

    final pattern = RegExp(r'```(?:[^`\n]*)?\n?([\s\S]*?)```');
    var modified = false;
    final result = StringBuffer();
    var lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      result.write(text.substring(lastEnd, match.start));
      final inner = match.group(1) ?? '';
      result.write(inner);

      changes.add(
        FormatChange(
          category: FormatChangeCategory.markdown,
          original: match.group(0)!,
          replacement: inner,
          startOffset: match.start,
          endOffset: match.end,
          explanation: '移除 Markdown 代码围栏',
        ),
      );

      lastEnd = match.end;
      modified = true;
    }

    if (modified) {
      result.write(text.substring(lastEnd));
      return result.toString();
    }

    return text.replaceAllMapped('```', (match) {
      changes.add(
        FormatChange(
          category: FormatChangeCategory.markdown,
          original: '```',
          replacement: '',
          startOffset: match.start,
          endOffset: match.end,
          explanation: '移除 Markdown 代码围栏',
        ),
      );
      return '';
    });
  }

  /// Strips unmatched emphasis markers (* or ** or _ or __) around text.
  ///
  /// Conservative: only strips when paired markers wrap CJK-heavy text,
  /// and not in arithmetic or code contexts.
  String _cleanMarkdownEmphasis(String text, List<FormatChange> changes) {
    var result = text;

    // Strip **bold** pairs
    result = _stripPairedMarkers(
      result,
      '**',
      FormatChangeCategory.markdown,
      '移除加粗标记',
      changes,
    );

    // Strip __bold__ pairs
    result = _stripPairedMarkers(
      result,
      '__',
      FormatChangeCategory.markdown,
      '移除加粗标记',
      changes,
    );

    // Strip *italic* pairs (after bold so we don't match half of **)
    result = _stripPairedMarkers(
      result,
      '*',
      FormatChangeCategory.markdown,
      '移除斜体标记',
      changes,
    );

    // Strip _italic_ pairs
    result = _stripPairedMarkers(
      result,
      '_',
      FormatChangeCategory.markdown,
      '移除斜体标记',
      changes,
    );

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
      changes.add(
        FormatChange(
          category: category,
          original: marker,
          replacement: '',
          startOffset: match.start,
          endOffset: match.start + marker.length,
          explanation: explanation,
        ),
      );

      // Record closing marker removal
      changes.add(
        FormatChange(
          category: category,
          original: marker,
          replacement: '',
          startOffset: match.end - marker.length,
          endOffset: match.end,
          explanation: explanation,
        ),
      );

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

      changes.add(
        FormatChange(
          category: FormatChangeCategory.markdown,
          original: match.group(0)!,
          replacement: '',
          startOffset: match.start,
          endOffset: match.end,
          explanation: '移除 HTML 标签',
        ),
      );

      lastEnd = match.end;
      modified = true;
    }

    if (modified) {
      result.write(text.substring(lastEnd));
      return result.toString();
    }
    return text;
  }
}
