/// Style deviation detector — compares AI text against AuthorStyleProfile.
///
/// Per Phase 19: Detects style deviations beyond keyword matching:
/// - Information density uniformity
/// - Emotion curve flatness
/// - Over-balanced descriptions
/// - Unnaturally perfect logic
///
/// Produces per-dimension deviation scores (0.0 = perfect match,
/// 1.0 = extreme deviation) with human-readable explanations.
library;

import 'package:museflow/features/editor/application/style_analysis_utils.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:museflow/features/editor/infrastructure/sentiment_lexicon.dart';

/// A single dimension's deviation result.
class DimensionDeviation {
  /// The style dimension being measured.
  final StyleDimension dimension;

  /// Deviation score 0.0 (perfect match) to 1.0 (extreme deviation).
  final double deviationScore;

  /// Human-readable explanation of the deviation in Chinese.
  final String explanation;

  /// The profile's reference value for this dimension.
  final double profileValue;

  /// The AI text's measured value for this dimension.
  final double textValue;

  const DimensionDeviation({
    required this.dimension,
    required this.deviationScore,
    required this.explanation,
    required this.profileValue,
    required this.textValue,
  });
}

/// Aggregate style deviation analysis result.
class StyleDeviationResult {
  /// Per-dimension deviations.
  final List<DimensionDeviation> deviations;

  /// Overall AI-scent score (0 = indistinguishable from author, 100 = pure AI).
  final int aiScentScore;

  /// Aggregate explanation in Chinese.
  final String summary;

  /// Whether the text has any significant deviations.
  final bool hasDeviations;

  /// The source text that was analyzed, for downstream sentence-level tooling.
  ///
  /// Defaults to an empty string when not provided (backward compatibility:
  /// no source text carried through).
  final String text;

  const StyleDeviationResult({
    required this.deviations,
    required this.aiScentScore,
    required this.summary,
    required this.hasDeviations,
    this.text = '',
  });
}

/// Detects style deviations between AI-generated text and author profile.
///
/// Uses the same analysis methods as [StyleAnalyzer] but compares against
/// the author's established style profile to detect AI patterns:
/// - Uniform sentence lengths (AI tendency toward equal-length sentences)
/// - Flat emotion curves (AI avoids emotional extremes)
/// - Over-balanced rhetoric (AI uses too many metaphors)
/// - High information density (AI packs too much meaning per sentence)
class StyleDeviationDetector {
  /// Threshold for flagging a dimension as deviated (0.0-1.0).
  static const double deviationThreshold = 0.3;

  /// Minimum CJK characters required for meaningful analysis.
  static const int _minChars = 10;

  /// Per-dimension weights in enum order. Values must sum to 1.
  final List<double> weights;

  /// Runtime threshold for per-dimension deviation flags.
  final double threshold;

  const StyleDeviationDetector({
    this.weights = const [0.2, 0.2, 0.15, 0.25, 0.2],
    this.threshold = deviationThreshold,
  }) : assert(threshold >= 0 && threshold <= 1);

  /// Analyzes AI text against the author's style profile.
  ///
  /// Returns a [StyleDeviationResult] with per-dimension scores and
  /// an overall AI-scent score.
  ///
  /// Returns null if the text is too short or the profile has insufficient data.
  StyleDeviationResult? analyze({
    required String text,
    required AuthorStyleProfile profile,
  }) {
    if (weights.length != StyleDimension.values.length) {
      throw ArgumentError.value(
        weights,
        'weights',
        'must contain one value per style dimension',
      );
    }
    if (StyleAnalysisUtils.cjkCharCount(text) < _minChars || !profile.hasData) {
      return null;
    }

    final deviations = <DimensionDeviation>[
      _analyzeSentenceLength(text, profile),
      _analyzeRhythm(text, profile),
      _analyzeVocabulary(text, profile),
      _analyzeRhetoric(text, profile),
      _analyzeEmotionalTone(text, profile),
    ];

    // Compute overall AI-scent score (weighted average of deviations)
    var weightedSum = 0.0;
    for (var i = 0; i < deviations.length; i++) {
      weightedSum += deviations[i].deviationScore * weights[i];
    }
    final aiScentScore = (weightedSum * 100).round().clamp(0, 100);

    // Check for significant deviations
    final hasDeviations = deviations.any((d) => d.deviationScore >= threshold);

    // Build summary
    final significantDeviations = deviations
        .where((d) => d.deviationScore >= threshold)
        .toList();
    final summary = _buildSummary(significantDeviations, aiScentScore);

    return StyleDeviationResult(
      deviations: deviations,
      aiScentScore: aiScentScore,
      summary: summary,
      hasDeviations: hasDeviations,
      text: text,
    );
  }

  DimensionDeviation _analyzeSentenceLength(
    String text,
    AuthorStyleProfile profile,
  ) {
    final lengths = _extractSentenceLengths(text);
    if (lengths.isEmpty) {
      return DimensionDeviation(
        dimension: StyleDimension.sentenceLength,
        deviationScore: 0.5,
        explanation: '文本过短，无法分析句式',
        profileValue: profile.sentenceLengthStats.avg,
        textValue: 0,
      );
    }

    final textAvg = lengths.reduce((a, b) => a + b) / lengths.length;
    final profileAvg = profile.sentenceLengthStats.avg;

    // Deviation is proportional to the difference relative to the author's
    // standard deviation (z-score-like)
    final diff = (textAvg - profileAvg).abs();
    final profileStdDev = profile.sentenceLengthStats.stdDev;
    final normalizedDev = profileStdDev > 0
        ? (diff / (profileStdDev * 2 + profileAvg * 0.3)).clamp(0.0, 1.0)
        : 0.0;

    final explanation = normalizedDev < threshold
        ? '句式长度与作者风格一致'
        : normalizedDev > 0.6
        ? '句式长度明显偏离作者习惯'
              '（作者均${profileAvg.toStringAsFixed(1)}字，'
              '当前${textAvg.toStringAsFixed(1)}字）'
        : '句式长度略有偏差'
              '（作者均${profileAvg.toStringAsFixed(1)}字，'
              '当前${textAvg.toStringAsFixed(1)}字）';

    return DimensionDeviation(
      dimension: StyleDimension.sentenceLength,
      deviationScore: normalizedDev,
      explanation: explanation,
      profileValue: profileAvg,
      textValue: textAvg,
    );
  }

  DimensionDeviation _analyzeRhythm(String text, AuthorStyleProfile profile) {
    final lengths = _extractSentenceLengths(text);
    final textRhythm = StyleAnalysisUtils.computeRhythmScore(lengths);

    // Author's rhythm is stored directly in profile
    final profileRhythm = profile.rhythmScore;

    // Deviation: how different is the text's rhythm from the author's
    final diff = (textRhythm - profileRhythm).abs();
    final normalizedDev = diff.clamp(0.0, 1.0);

    // High rhythm in text but low in author = AI-uniform text
    // Low rhythm in text but high in author = text is actually more varied than author (good)
    // Only penalize if text is MORE uniform than author
    final penaltyDev = textRhythm > profileRhythm
        ? normalizedDev
        : normalizedDev * 0.3; // less penalty for being more varied

    final explanation = penaltyDev < threshold
        ? '节奏变化与作者风格一致'
        : textRhythm > profileRhythm
        ? '节奏过于均匀，缺乏长短变化（AI常见特征）'
        : '节奏变化略大于作者习惯';

    return DimensionDeviation(
      dimension: StyleDimension.rhythm,
      deviationScore: penaltyDev,
      explanation: explanation,
      profileValue: profileRhythm,
      textValue: textRhythm,
    );
  }

  DimensionDeviation _analyzeVocabulary(
    String text,
    AuthorStyleProfile profile,
  ) {
    // Vocabulary richness is computed via the shared ruler
    // [StyleAnalysisUtils.computeVocabularyRichness] — identical formula
    // AND identical <50-CJK-char neutral-band threshold as the analyzer's
    // baseline builder. Pre-fix detector held its own inline copy of this
    // formula+threshold, which drifted twice (260617-j0z: <20 vs <50).
    // Delegating to StyleAnalysisUtils makes the measurement side call the
    // SAME function as the baseline side (structural dual-ruler fix,
    // PLAN quick-260617-jgd).
    final normalizedRichness = StyleAnalysisUtils.computeVocabularyRichness(
      text,
    );

    // The util returns neutral 0.5 for sub-threshold (<50 CJK) text. Map
    // that to the detector's "too short to analyze" branch.
    final cjkCount = StyleAnalysisUtils.cjkCharCount(text);
    if (cjkCount < 50) {
      return DimensionDeviation(
        dimension: StyleDimension.vocabulary,
        deviationScore: 0.5,
        explanation: '文本过短，无法分析词汇',
        profileValue: profile.vocabularyRichness,
        textValue: 0.5,
      );
    }

    final profileRichness = profile.vocabularyRichness;
    final diff = (normalizedRichness - profileRichness).abs();

    // If AI text is much richer than author, it might be using unusual words
    // If AI text is much less rich, it's being repetitive
    final normalizedDev = diff.clamp(0.0, 1.0);

    final explanation = normalizedDev < threshold
        ? '词汇丰富度与作者风格一致'
        : normalizedRichness > profileRichness
        ? '词汇过于华丽，偏离作者朴实风格'
        : '词汇重复度偏高，变化不足';

    return DimensionDeviation(
      dimension: StyleDimension.vocabulary,
      deviationScore: normalizedDev,
      explanation: explanation,
      profileValue: profileRichness,
      textValue: normalizedRichness,
    );
  }

  DimensionDeviation _analyzeRhetoric(String text, AuthorStyleProfile profile) {
    final habits = _computeRhetoricHabits(text);
    final profileHabits = profile.rhetoricHabits;

    // Compare each ratio
    final diffs = [
      (habits.dialogueRatio - profileHabits.dialogueRatio).abs(),
      (habits.descriptionRatio - profileHabits.descriptionRatio).abs(),
      (habits.actionRatio - profileHabits.actionRatio).abs(),
      (habits.metaphorFrequency - profileHabits.metaphorFrequency).abs(),
    ];

    final avgDiff = diffs.reduce((a, b) => a + b) / diffs.length;
    final normalizedDev = (avgDiff * 3).clamp(
      0.0,
      1.0,
    ); // amplify for sensitivity

    // Check for specific AI patterns: over-balanced descriptions
    final descriptionHeavy =
        habits.descriptionRatio > profileHabits.descriptionRatio + 0.15;
    final metaphorHeavy =
        habits.metaphorFrequency > profileHabits.metaphorFrequency + 0.1;

    String explanation;
    if (normalizedDev < threshold) {
      explanation = '修辞手法与作者风格一致';
    } else if (descriptionHeavy) {
      explanation =
          '描写比重过高'
          '（作者${(profileHabits.descriptionRatio * 100).toStringAsFixed(0)}%，'
          '当前${(habits.descriptionRatio * 100).toStringAsFixed(0)}%）';
    } else if (metaphorHeavy) {
      explanation =
          '比喻修辞过多，偏向AI华丽风格'
          '（作者${(profileHabits.metaphorFrequency * 100).toStringAsFixed(0)}%，'
          '当前${(habits.metaphorFrequency * 100).toStringAsFixed(0)}%）';
    } else {
      explanation = '修辞比例与作者习惯存在偏差';
    }

    return DimensionDeviation(
      dimension: StyleDimension.rhetoric,
      deviationScore: normalizedDev,
      explanation: explanation,
      profileValue: profileHabits.metaphorFrequency,
      textValue: habits.metaphorFrequency,
    );
  }

  DimensionDeviation _analyzeEmotionalTone(
    String text,
    AuthorStyleProfile profile,
  ) {
    final textTone = _computeEmotionalTone(text);
    final profileTone = profile.emotionalTone;

    // Compare warmth and intensity
    final warmthDiff = (textTone.warmth - profileTone.warmth).abs();
    final intensityDiff = (textTone.intensity - profileTone.intensity).abs();
    final avgDiff = (warmthDiff + intensityDiff) / 2;
    final normalizedDev = (avgDiff * 2).clamp(0.0, 1.0);

    // AI pattern: flat emotion curve (low sentiment-word density).
    // lexicon 统一后数值变化（260617-f7l）: SentimentLexicon.intensityScore
    // returns ~0 for text with no sentiment words (density 0/4), unlike the
    // pre-fix custom formula which returned 0.5 (neutral-band baseline).
    // The isFlat semantic — "情感曲线平淡，缺乏起伏" — correctly maps to LOW
    // intensity under the new ruler, so the boundary shifts from the old
    // 0.35–0.65 mid-band to a single < 0.3 threshold (matches
    // SentimentLexicon.classifyTone's own "intensity < 0.3 → 平静/冷静"
    // cutoff, keeping detector and lexicon rulings consistent).
    final isFlat = textTone.intensity < 0.3;

    final effectiveDev = isFlat && profileTone.intensity.abs() > 0.2
        ? normalizedDev *
              1.3 // penalize flat emotion more
        : normalizedDev;

    String explanation;
    if (effectiveDev < threshold) {
      explanation = '情感基调与作者风格一致';
    } else if (isFlat) {
      explanation = '情感曲线过于平淡，缺乏起伏（AI常见特征）';
    } else if (textTone.intensity > profileTone.intensity + 0.15) {
      explanation = '情感表达过于浓烈，偏离作者克制风格';
    } else {
      explanation = '情感基调与作者习惯存在偏差';
    }

    return DimensionDeviation(
      dimension: StyleDimension.emotionalTone,
      deviationScore: effectiveDev.clamp(0.0, 1.0),
      explanation: explanation,
      profileValue: profileTone.intensity,
      textValue: textTone.intensity,
    );
  }

  String _buildSummary(
    List<DimensionDeviation> significantDeviations,
    int aiScentScore,
  ) {
    if (significantDeviations.isEmpty) {
      return 'AI 文本风格与作者高度一致，AI痕迹低。';
    }

    final buffer = StringBuffer();
    if (aiScentScore >= 70) {
      buffer.write('AI 痕迹较明显：');
    } else if (aiScentScore >= 40) {
      buffer.write('AI 痕迹中等：');
    } else {
      buffer.write('AI 痕迹较轻：');
    }

    for (var i = 0; i < significantDeviations.length && i < 3; i++) {
      if (i > 0) buffer.write('；');
      buffer.write(significantDeviations[i].dimension.label);
    }
    if (significantDeviations.length > 3) {
      buffer.write('等');
    }
    buffer.write('维度存在偏差。');

    return buffer.toString();
  }

  // ── Shared Analysis Utilities (delegates to StyleAnalysisUtils) ───
  //
  // The detector no longer holds its OWN ruler for CJK extraction, sentence-
  // length extraction, rhythm scoring, or vocabulary richness. All four
  // delegate to [StyleAnalysisUtils] — the same function the analyzer
  // (baseline side) calls. This structurally eliminates the dual-ruler
  // drift class (PLAN quick-260617-jgd, closing 05c/1uk/f7l/hnl/j0z).

  List<int> _extractSentenceLengths(String text) =>
      StyleAnalysisUtils.extractSentenceLengths(text);

  RhetoricHabits _computeRhetoricHabits(String text) {
    final sentences = text.split(RegExp(r'[。！？\n]+'));
    var dialogueCount = 0;
    var descriptionCount = 0;
    var actionCount = 0;
    var metaphorCount = 0;
    var totalAnalyzed = 0;

    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      totalAnalyzed++;

      if (_isDialogue(trimmed)) {
        dialogueCount++;
      } else if (_hasMetaphor(trimmed)) {
        metaphorCount++;
        descriptionCount++;
      } else if (_isAction(trimmed)) {
        actionCount++;
      } else if (_isDescription(trimmed)) {
        descriptionCount++;
      }
    }

    if (totalAnalyzed == 0) return const RhetoricHabits();

    return RhetoricHabits(
      dialogueRatio: dialogueCount / totalAnalyzed,
      descriptionRatio: descriptionCount / totalAnalyzed,
      actionRatio: actionCount / totalAnalyzed,
      metaphorFrequency: metaphorCount / totalAnalyzed,
    );
  }

  EmotionalTone _computeEmotionalTone(String text) {
    // Unified with StyleAnalyzer._computeEmotionalTone — both rulers now
    // share SentimentLexicon for warmth/intensity/classifyTone, so the
    // detector's "measurement" is byte-for-byte consistent with the
    // profile-builder's "baseline". This eliminates the inline-table drift
    // that caused 3 prior bugs (260617-05c dup double-count, 260617-1uk
    // bare 爱/恨 substring over-count + polarity inversion).
    final positiveCount = SentimentLexicon.countPositive(text);
    final negativeCount = SentimentLexicon.countNegative(text);
    final totalCjk = StyleAnalysisUtils.cjkCharCount(text);

    final warmth = SentimentLexicon.warmthScore(positiveCount, negativeCount);
    final intensity = SentimentLexicon.intensityScore(
      positiveCount,
      negativeCount,
      totalCjk,
    );
    final overall = SentimentLexicon.classifyTone(warmth, intensity);

    return EmotionalTone(
      overall: overall,
      warmth: warmth,
      intensity: intensity,
    );
  }

  bool _isDialogue(String sentence) {
    return sentence.contains('「') ||
        sentence.contains('」') ||
        sentence.contains('"') ||
        sentence.contains('"') ||
        RegExp(r'[一-鿿]{1,4}(说|道|喊|叫|问|答|笑|怒|骂|吼|嘀咕|嘟囔|喃喃)').hasMatch(sentence);
  }

  bool _isAction(String sentence) {
    return RegExp(
      r'^[一-鿿]{1,3}(走|跑|跳|打|踢|抓|握|挥|抬|举|放|推|拉|扯|砍|刺|挥|转|回|看|盯|望|瞥|听|闻)',
    ).hasMatch(sentence.trim());
  }

  bool _isDescription(String sentence) {
    final cjkCount = StyleAnalysisUtils.cjkCharCount(sentence);
    final adjCount = RegExp(r'[一-鿿]{2}(的|地|得)').allMatches(sentence).length;
    return adjCount >= 2 || (cjkCount > 20 && adjCount >= 1);
  }

  bool _hasMetaphor(String sentence) {
    return sentence.contains('像') ||
        sentence.contains('如同') ||
        sentence.contains('仿佛') ||
        sentence.contains('宛如') ||
        sentence.contains('犹如') ||
        sentence.contains('似的') ||
        sentence.contains('一般');
  }
}
