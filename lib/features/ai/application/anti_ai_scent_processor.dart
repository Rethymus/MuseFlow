/// Anti-AI-scent post-processor.
///
/// Dual-layer processing system per AI-05 and AI-06:
/// 1. Auto-replacement phase: replaces banned Chinese AI cliches with synonyms
/// 2. Structural highlight phase: detects套话句式 and wraps with 【】 markers
///
/// Per D-09: Synonym map seeded with common Chinese AI cliches.
/// Per D-10: Structural patterns highlighted for manual review, not auto-replaced.
library;

/// Type of text highlight found during processing.
enum HighlightType {
  /// A banned word that was auto-replaced with a synonym or deleted.
  bannedWord,

  /// A structural pattern (套话句式) highlighted for manual review.
  structuralPattern,
}

/// A highlight location in the processed text.
class TextHighlight {
  /// Start position (inclusive) in the processed text.
  final int start;

  /// End position (exclusive) in the processed text.
  final int end;

  /// The original text that was found and highlighted/replaced.
  final String originalText;

  /// The type of highlight.
  final HighlightType type;

  const TextHighlight({
    required this.start,
    required this.end,
    required this.originalText,
    required this.type,
  });

  @override
  String toString() =>
      'TextHighlight(start: $start, end: $end, '
      'original: "$originalText", type: $type)';
}

/// Result of anti-AI-scent processing.
class ProcessingResult {
  /// The processed text after replacements and highlight markers.
  final String processedText;

  /// Locations of highlights in the processed text.
  final List<TextHighlight> highlights;

  const ProcessingResult({
    required this.processedText,
    required this.highlights,
  });
}

/// Post-processor that removes AI-scented patterns from Chinese text.
///
/// Processing has two phases:
/// 1. **Auto-replacement**: Banned phrases are replaced with synonyms
///    using boundary-aware matching (per Pitfall 5: checks surrounding
///    characters are punctuation, whitespace, or string boundary).
/// 2. **Structural highlighting**: Complex patterns (套话句式) are
///    wrapped with 【】 markers for the user to manually review.
///
/// Usage:
/// ```dart
/// final processor = AntiAIScentProcessor();
/// final result = processor.process(text, bannedPhrases: extraPhrases);
/// print(result.processedText);
/// for (final h in result.highlights) {
///   print('Found ${h.originalText} at ${h.start}-${h.end}');
/// }
/// ```
class AntiAIScentProcessor {
  /// The keys from the built-in synonym map, used to seed user's banned list.
  static List<String> get synonymKeys =>
      _synonymMap.keys.toList();

  /// Fixed synonym map for auto-replacement per D-09.
  /// Empty string values mean "delete the phrase".
  static const Map<String, String> _synonymMap = {
    '然而': '但是',
    '综上所述': '',
    '值得注意的是': '',
    '毫无疑问': '',
    '不可否认': '',
    '首先': '',
    '其次': '',
    '最后': '',
    '总的来说': '',
    '一方面': '',
    '另一方面': '',
    '总之': '',
    '显而易见': '',
    '不言而喻': '',
    '众所周知': '',
  };

  /// Structural pattern regexes per D-10.
  /// These are highlighted with 【】 markers, not auto-replaced.
  static final List<RegExp> _structuralPatterns = [
    RegExp(r'不仅[^，。！？\n]{1,20}而且'),
    RegExp(r'随着[^，。！？\n]{1,20}的发展'),
    RegExp(r'在[^，。！？\n]{1,20}中，[^，。！？\n]{1,20}发挥了重要作用'),
  ];

  /// Processes the given [text] and returns a [ProcessingResult].
  ///
  /// [bannedPhrases] are additional phrases to remove (appended to the
  /// built-in synonym map). These are deleted (empty replacement).
  ProcessingResult process(String text, {required List<String> bannedPhrases}) {
    if (text.isEmpty) {
      return const ProcessingResult(processedText: '', highlights: []);
    }

    var processedText = text;
    final highlights = <TextHighlight>[];

    // Phase 1: Auto-replacement
    processedText = _applyAutoReplacements(processedText, highlights);

    // Phase 1b: Additional banned phrases from parameter
    if (bannedPhrases.isNotEmpty) {
      processedText = _applyExtraBannedPhrases(
        processedText,
        bannedPhrases,
        highlights,
      );
    }

    // Phase 2: Structural pattern highlighting
    processedText = _applyStructuralHighlights(processedText, highlights);

    return ProcessingResult(
      processedText: processedText,
      highlights: highlights,
    );
  }

  /// Applies auto-replacement from the fixed synonym map.
  String _applyAutoReplacements(
    String text,
    List<TextHighlight> highlights,
  ) {
    var result = text;
    for (final entry in _synonymMap.entries) {
      final phrase = entry.key;
      final replacement = entry.value;

      result = _replaceBoundaryAware(
        result,
        phrase,
        replacement,
        highlights,
        HighlightType.bannedWord,
      );
    }
    return result;
  }

  /// Applies additional banned phrases from the parameter.
  String _applyExtraBannedPhrases(
    String text,
    List<String> bannedPhrases,
    List<TextHighlight> highlights,
  ) {
    var result = text;
    for (final phrase in bannedPhrases) {
      result = _replaceBoundaryAware(
        result,
        phrase,
        '', // Delete extra banned phrases
        highlights,
        HighlightType.bannedWord,
      );
    }
    return result;
  }

  /// Boundary-aware replacement per Pitfall 5.
  ///
  /// Only replaces [phrase] when it is bounded by:
  /// - String start/end, OR
  /// - Whitespace/newline, OR
  /// - Chinese punctuation (。，！？；：""''（）【】《》…)
  String _replaceBoundaryAware(
    String text,
    String phrase,
    String replacement,
    List<TextHighlight> highlights,
    HighlightType type,
  ) {
    if (phrase.isEmpty) return text;

    var result = text;
    // Find all non-overlapping occurrences
    var offset = 0;
    while (true) {
      final index = result.indexOf(phrase, offset);
      if (index == -1) break;

      // Boundary check per Pitfall 5: not embedded in a longer CJK word
      if (!_isAtValidBoundary(result, index, phrase.length)) {
        offset = index + 1;
        continue;
      }

      // Record highlight before replacement shifts positions
      highlights.add(TextHighlight(
        start: index,
        end: index + phrase.length,
        originalText: phrase,
        type: type,
      ));

      // Perform replacement
      result = result.substring(0, index) +
          replacement +
          result.substring(index + phrase.length);

      // Move offset past the replacement
      offset = index + replacement.length;
    }

    return result;
  }

  /// Checks if a code point is a CJK ideograph (potential word character).
  bool _isCjkChar(String char) {
    if (char.isEmpty) return false;
    final code = char.runes.first;
    return (code >= 0x4E00 && code <= 0x9FFF) ||
        (code >= 0x3400 && code <= 0x4DBF);
  }

  /// Checks whether a phrase occurrence at [index] in [text] has
  /// proper boundaries (not embedded in a longer word).
  ///
  /// Per Pitfall 5: A phrase is considered embedded in a longer word
  /// when BOTH the character before AND the character after are CJK
  /// ideographs. For example, "然而" in "自然而然" has "然" on both
  /// sides, so it's embedded. But "然而他" only has CJK after, so
  /// it's a valid standalone usage.
  bool _isAtValidBoundary(String text, int index, int phraseLength) {
    final beforeIsCjk =
        index > 0 && _isCjkChar(text[index - 1]);
    final afterIndex = index + phraseLength;
    final afterIsCjk =
        afterIndex < text.length && _isCjkChar(text[afterIndex]);

    // Only block when BOTH sides are CJK (phrase is embedded in a word)
    return !(beforeIsCjk && afterIsCjk);
  }

  /// Applies structural pattern highlighting with 【】 markers per D-10.
  String _applyStructuralHighlights(
    String text,
    List<TextHighlight> highlights,
  ) {
    var result = text;

    for (final pattern in _structuralPatterns) {
      var offset = 0;
      while (true) {
        final matches = pattern.allMatches(result, offset);
        final match = matches.firstOrNull;
        if (match == null) break;

        final matchedText = match.group(0)!;
        final start = match.start;
        final end = match.end;

        // Wrap with 【】 markers
        final marked = '【$matchedText】';
        result = result.substring(0, start) +
            marked +
            result.substring(end);

        highlights.add(TextHighlight(
          start: start,
          end: start + marked.length,
          originalText: matchedText,
          type: HighlightType.structuralPattern,
        ));

        // Move offset past the marked text
        offset = start + marked.length;
      }
    }

    return result;
  }
}
