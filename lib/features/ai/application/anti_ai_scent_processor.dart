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

part 'anti_ai_scent_lexicon.dart';

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
  /// The keys from the built-in synonym map plus highlight-only phrases,
  /// used to seed user's banned list for the AI prompt layer.
  static List<String> get synonymKeys => [
    ..._synonymMap.keys,
    ..._highlightOnlyPhrases,
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

    // Phase 1c: Highlight-only phrases (common literary words —
    // highlight for author review, don't auto-replace)
    processedText = _applyHighlightOnlyPhrases(processedText, highlights);

    // Phase 2: Structural pattern highlighting
    processedText = _applyStructuralHighlights(processedText, highlights);

    // Build review signals on ORIGINAL text — detects AI patterns
    // even when Phase 1 auto-replaced some of them.
    final reviewSignals = _buildReviewSignals(text, highlights);

    return ProcessingResult(
      processedText: processedText,
      highlights: highlights,
      reviewSignals: reviewSignals,
    );
  }

  /// Applies auto-replacement from the fixed synonym map.
  /// Skips highlight-only phrases — those are handled separately.
  String _applyAutoReplacements(String text, List<TextHighlight> highlights) {
    var result = text;
    for (final entry in _synonymMap.entries) {
      final phrase = entry.key;
      // Highlight-only phrases are not auto-replaced
      if (_highlightOnlyPhrases.contains(phrase)) continue;
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

  /// Wraps highlight-only phrases with 【】 markers for author review.
  ///
  /// These phrases are too common in legitimate literature to auto-replace,
  /// but still flagged for the author to decide in context.
  String _applyHighlightOnlyPhrases(
    String text,
    List<TextHighlight> highlights,
  ) {
    var result = text;
    for (final phrase in _highlightOnlyPhrases) {
      var offset = 0;
      while (true) {
        final index = result.indexOf(phrase, offset);
        if (index == -1) break;

        // Boundary check: detect compound-word embedding (e.g., "然而"
        // inside "自然而然" where chars overlap). Uses character
        // overlap instead of simple CJK adjacency so that short
        // function words like "极其" in "这极其重要" still match.
        if (!_isAtValidBoundary(result, index, phrase.length)) {
          offset = index + 1;
          continue;
        }

        final marked = '【$phrase】';
        result =
            result.substring(0, index) +
            marked +
            result.substring(index + phrase.length);

        highlights.add(
          TextHighlight(
            start: index,
            end: index + marked.length,
            originalText: phrase,
            type: HighlightType.bannedWord,
          ),
        );

        offset = index + marked.length;
      }
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
  /// Uses phrase-content overlap detection:
  /// - "然而" in "自然而然" → blocked (`然` after match is IN phrase)
  /// - "极其" in "这极其重要" → allowed (`这`/`重` NOT in phrase)
  bool _isAtValidBoundary(String text, int index, int phraseLength) {
    if (index <= 0 && index + phraseLength >= text.length) return true;

    final beforeIsCjk = index > 0 && _isCjkChar(text[index - 1]);
    final afterIndex = index + phraseLength;
    final afterIsCjk = afterIndex < text.length && _isCjkChar(text[afterIndex]);

    if (!beforeIsCjk || !afterIsCjk) return true;

    // Both sides are CJK — check if adjacent chars appear IN the
    // phrase itself, which indicates compound-word embedding.
    final phrase = text.substring(index, index + phraseLength);
    if (phrase.contains(text[index - 1])) return false;
    if (phrase.contains(text[afterIndex])) return false;

    return true;
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

    // AA-05: count cliches per genre and name the dominant one so the
    // feedback is accurate for the author's actual register — a sci-fi
    // writer should not be told their 修仙 phrases repeat. Insertion order
    // sets tie-break priority (修仙 > 武侠 > 都市 > 科幻 > 玄幻): reduce
    // returns the earlier entry when counts are equal.
    final genreHits = <String, int>{
      '修仙': _countPhraseHits(text, _xianxiaCliches),
      '武侠': _countPhraseHits(text, _wuxiaCliches),
      '都市': _countPhraseHits(text, _urbanCliches),
      '科幻': _countPhraseHits(text, _scifiCliches),
      '玄幻': _countPhraseHits(text, _xuanhuanCliches),
    };
    final genreClicheCount = genreHits.values.fold(0, (a, b) => a + b);
    if (genreClicheCount >= 2) {
      final genreLabel = genreHits.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      signals.add(
        ReviewSignal(
          title: '类型文套句偏多',
          description: '$genreLabel常见短语重复出现，可能削弱作者自己的画面感。',
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

    final emotionalClicheCount = _countPhraseHits(text, _emotionalCliches);
    if (emotionalClicheCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '情感描写套路化',
          description: '情感表达使用了常见套话短语，建议替换为更贴合角色和场景的独特描写。',
          severity: emotionalClicheCount >= 4
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '$emotionalClicheCount 处',
        ),
      );
    }

    final descriptionFormulaCount = _countPhraseHits(
      text,
      _descriptionFormulas,
    );
    if (descriptionFormulaCount >= 2) {
      signals.add(
        ReviewSignal(
          title: '描写公式化',
          description: '场景描写使用了通用形容词组合，建议加入具体感官细节让画面更独特。',
          severity: ReviewSignalSeverity.medium,
          evidence: '$descriptionFormulaCount 处',
        ),
      );
    }

    // AA-06: manner-adverb stem over-reliance. Counts bare 叠词 softeners
    // (缓缓/微微/淡淡…) across the whole text — a distributional AI-register
    // tell the fixed-phrase synonym map cannot surface. ≥5 fires (paragraph-
    // scale progressText); ≥8 escalates to high.
    final mannerAdverbCount = _countPhraseHits(text, _mannerAdverbStems);
    if (mannerAdverbCount >= 5) {
      signals.add(
        ReviewSignal(
          title: '叠词/程度副词堆砌',
          description: '大量叠词/程度副词（缓缓/微微/淡淡…）堆砌是典型的AI叙述腔，建议精简或替换为更具体的动作与感官描写。',
          severity: mannerAdverbCount >= 8
              ? ReviewSignalSeverity.high
              : ReviewSignalSeverity.medium,
          evidence: '$mannerAdverbCount 次',
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
