/// Anti-AI-scent post-processor.
///
/// Dual-layer processing system per AI-05 and AI-06:
/// 1. Auto-replacement phase: replaces banned Chinese AI cliches with synonyms
/// 2. Structural highlight phase: detects套话句式 and wraps with 【】 markers
///
/// Per D-09: Synonym map seeded with common Chinese AI cliches.
/// Per D-10: Structural patterns highlighted for manual review, not auto-replaced.
library;

import 'dart:math' as math;

/// Type of text highlight found during processing.
enum HighlightType {
  /// A banned word that was auto-replaced with a synonym or deleted.
  bannedWord,

  /// A structural pattern (套话句式) highlighted for manual review.
  structuralPattern,
}

/// Severity of an author-facing AI-scent review signal.
enum ReviewSignalSeverity {
  /// Low-risk note for author awareness.
  low,

  /// Medium-risk signal that deserves review before accepting AI text.
  medium,

  /// High-risk signal that can make the output feel template-like.
  high,
}

/// A deterministic review signal that explains why AI output may need
/// author attention before being accepted.
class ReviewSignal {
  /// Human-readable title for the signal.
  final String title;

  /// Concrete explanation of the detected pattern.
  final String description;

  /// Severity for prioritizing author review.
  final ReviewSignalSeverity severity;

  /// Optional evidence value shown to users/tests, e.g. "7 次".
  final String evidence;

  const ReviewSignal({
    required this.title,
    required this.description,
    required this.severity,
    required this.evidence,
  });
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

  /// Author-facing review signals for structural AI-scent risk.
  final List<ReviewSignal> reviewSignals;

  const ProcessingResult({
    required this.processedText,
    required this.highlights,
    this.reviewSignals = const [],
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
  static List<String> get synonymKeys => _synonymMap.keys.toList();

  /// Fixed synonym map for auto-replacement per D-09.
  /// Empty string values mean "delete the phrase".
  static const Map<String, String> _synonymMap = {
    '然而': '但是',
    '综上所述': '',
    '值得注意的是': '',
    '总而言之': '',
    '需要指出的是': '',
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

  static const List<String> _transitionCliches = [
    '与此同时',
    '就在这时',
    '不料',
    '忽然',
    '突然',
    '下一刻',
    '片刻之后',
  ];

  static const List<String> _xianxiaCliches = [
    '灵气涌动',
    '磅礴的力量',
    '眼中闪过一丝',
    '不由得',
    '倒吸一口凉气',
    '周身气息',
    '体内灵力',
    '剑气纵横',
  ];

  static const List<String> _formulaicEndings = [
    '一场更大的风暴',
    '真正的考验',
    '才刚刚开始',
    '等待着他',
    '命运的齿轮',
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

    final reviewSignals = _buildReviewSignals(processedText, highlights);

    return ProcessingResult(
      processedText: processedText,
      highlights: highlights,
      reviewSignals: reviewSignals,
    );
  }

  /// Applies auto-replacement from the fixed synonym map.
  String _applyAutoReplacements(String text, List<TextHighlight> highlights) {
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
      highlights.add(
        TextHighlight(
          start: index,
          end: index + phrase.length,
          originalText: phrase,
          type: type,
        ),
      );

      // Perform replacement
      result =
          result.substring(0, index) +
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
    final beforeIsCjk = index > 0 && _isCjkChar(text[index - 1]);
    final afterIndex = index + phraseLength;
    final afterIsCjk = afterIndex < text.length && _isCjkChar(text[afterIndex]);

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
        result = result.substring(0, start) + marked + result.substring(end);

        highlights.add(
          TextHighlight(
            start: start,
            end: start + marked.length,
            originalText: matchedText,
            type: HighlightType.structuralPattern,
          ),
        );

        // Move offset past the marked text
        offset = start + marked.length;
      }
    }

    return result;
  }

  List<ReviewSignal> _buildReviewSignals(
    String text,
    List<TextHighlight> highlights,
  ) {
    final signals = <ReviewSignal>[];
    final transitionCount = _countPhraseHits(text, _transitionCliches);
    if (transitionCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '转场套话偏多',
          description: '连续使用常见转场词会让段落显得机械，建议作者手动调整节奏。',
          severity: transitionCount >= 4
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '$transitionCount 次',
        ),
      );
    }

    final genreClicheCount = _countPhraseHits(text, _xianxiaCliches);
    if (genreClicheCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '类型文套句偏多',
          description: '修仙常见短语重复出现，可能削弱作者自己的画面感。',
          severity: genreClicheCount >= 4
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '$genreClicheCount 次',
        ),
      );
    }

    final endingCount = _countPhraseHits(text, _formulaicEndings);
    if (endingCount > 0) {
      signals.add(
        ReviewSignal(
          title: '结尾悬念公式化',
          description: '章节收束出现常见钩子句式，采纳前建议改成更贴合当前人物选择的结尾。',
          severity: ReviewSignalSeverity.medium,
          evidence: '$endingCount 处',
        ),
      );
    }

    final sentenceLengths = _sentenceLengths(text);
    final rhythmScore = _sentenceRhythmUniformity(sentenceLengths);
    if (rhythmScore >= 0.72 && sentenceLengths.length >= 4) {
      signals.add(
        ReviewSignal(
          title: '句长节奏过于整齐',
          description: '多句长度接近会形成 AI 式匀速叙述，可穿插短句、动作或停顿。',
          severity: rhythmScore >= 0.85
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '${(rhythmScore * 100).round()}%',
        ),
      );
    }

    final structuralCount = highlights
        .where((h) => h.type == HighlightType.structuralPattern)
        .length;
    if (structuralCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '结构化句式重复',
          description: '多个句子被标记为套话结构，建议逐句确认是否符合角色和场景。',
          severity: ReviewSignalSeverity.medium,
          evidence: '$structuralCount 处',
        ),
      );
    }

    return signals;
  }

  int _countPhraseHits(String text, List<String> phrases) {
    var count = 0;
    for (final phrase in phrases) {
      var offset = 0;
      while (true) {
        final index = text.indexOf(phrase, offset);
        if (index == -1) break;
        count++;
        offset = index + phrase.length;
      }
    }
    return count;
  }

  List<int> _sentenceLengths(String text) {
    return text
        .split(RegExp(r'[。！？!?；;\n]+'))
        .map((s) => s.replaceAll(RegExp(r'\s+'), '').length)
        .where((length) => length >= 4)
        .toList();
  }

  double _sentenceRhythmUniformity(List<int> lengths) {
    if (lengths.length < 4) return 0;
    final average = lengths.reduce((a, b) => a + b) / lengths.length;
    if (average == 0) return 0;
    final variance =
        lengths
            .map((length) {
              final diff = length - average;
              return diff * diff;
            })
            .reduce((a, b) => a + b) /
        lengths.length;
    final coefficientOfVariation = math.sqrt(variance) / average;
    return (1 - coefficientOfVariation).clamp(0, 1);
  }
}
