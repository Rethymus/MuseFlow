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

import 'dart:math';

import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';

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

  const StyleDeviationDetector();

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
    if (_extractCjkChars(text).length < _minChars || !profile.hasData) {
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
    final weights = [0.2, 0.25, 0.15, 0.2, 0.2];
    var weightedSum = 0.0;
    for (var i = 0; i < deviations.length; i++) {
      weightedSum += deviations[i].deviationScore * weights[i];
    }
    final aiScentScore = (weightedSum * 100).round().clamp(0, 100);

    // Check for significant deviations
    final hasDeviations = deviations.any(
      (d) => d.deviationScore >= deviationThreshold,
    );

    // Build summary
    final significantDeviations = deviations
        .where((d) => d.deviationScore >= deviationThreshold)
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

    final explanation = normalizedDev < deviationThreshold
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
    final textRhythm = _computeRhythmScore(lengths);

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

    final explanation = penaltyDev < deviationThreshold
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
    final cjkChars = _extractCjkChars(text);
    if (cjkChars.length < 20) {
      return DimensionDeviation(
        dimension: StyleDimension.vocabulary,
        deviationScore: 0.5,
        explanation: '文本过短，无法分析词汇',
        profileValue: profile.vocabularyRichness,
        textValue: 0.5,
      );
    }

    final uniqueChars = cjkChars.toSet().length;
    final textRichness = uniqueChars / cjkChars.length;
    // Normalize to 0-1 scale (same as StyleAnalyzer)
    final normalizedRichness = ((textRichness - 0.25) / 0.30).clamp(0.0, 1.0);

    final profileRichness = profile.vocabularyRichness;
    final diff = (normalizedRichness - profileRichness).abs();

    // If AI text is much richer than author, it might be using unusual words
    // If AI text is much less rich, it's being repetitive
    final normalizedDev = diff.clamp(0.0, 1.0);

    final explanation = normalizedDev < deviationThreshold
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
    if (normalizedDev < deviationThreshold) {
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

    // AI pattern: flat emotion curve (intensity near 0.5, low variance)
    final isFlat = textTone.intensity > 0.35 && textTone.intensity < 0.65;

    final effectiveDev = isFlat && profileTone.intensity.abs() > 0.2
        ? normalizedDev *
              1.3 // penalize flat emotion more
        : normalizedDev;

    String explanation;
    if (effectiveDev < deviationThreshold) {
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

  // ── Shared Analysis Utilities (mirrors StyleAnalyzer) ─────────────

  List<int> _extractSentenceLengths(String text) {
    final sentences = text.split(RegExp(r'[。！？；\n]+'));
    return sentences
        .map((s) => _extractCjkChars(s.trim()).length)
        .where((len) => len > 0)
        .toList();
  }

  double _computeRhythmScore(List<int> lengths) {
    if (lengths.length < 3) return 0.5;
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    if (avg == 0) return 0.5;
    final variance =
        lengths.map((l) => (l - avg) * (l - avg)).reduce((a, b) => a + b) /
        lengths.length;
    final stdDev = sqrt(variance);
    final cv = stdDev / avg;
    return (1.0 - (cv - 0.3) / 0.5).clamp(0.0, 1.0);
  }

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
    // Simplified emotion analysis without sentiment lexicon dependency
    final positiveCount = _countPositiveSentiment(text);
    final negativeCount = _countNegativeSentiment(text);
    final totalCjk = _extractCjkChars(text).length;

    final warmth = totalCjk > 0
        ? ((positiveCount - negativeCount) / (totalCjk * 0.05 + 1) * 0.5 + 0.5)
              .clamp(0.0, 1.0)
        : 0.5;
    final intensity = totalCjk > 0
        ? ((positiveCount + negativeCount) / (totalCjk * 0.03 + 1) * 0.5 + 0.5)
              .clamp(0.0, 1.0)
        : 0.5;

    return EmotionalTone(
      overall: _classifyTone(warmth, intensity),
      warmth: warmth,
      intensity: intensity,
    );
  }

  int _countPositiveSentiment(String text) {
    const positives = <String>{
      '温暖',
      '幸福',
      '快乐',
      '美好',
      '希望',
      '光明',
      '温柔',
      '甜蜜',
      '感动',
      '欣喜',
      '安宁',
      '喜悦',
      '欢笑',
      '灿烂',
      '明媚',
      '欢快',
      '欢喜',
      '安心',
      '满足',
      '欣慰',
      '爱',
      '喜欢',
      '珍惜',
    };
    var count = 0;
    for (final word in positives) {
      count += word.allMatches(text).length;
    }
    return count;
  }

  int _countNegativeSentiment(String text) {
    const negatives = <String>{
      '痛苦',
      '悲伤',
      '愤怒',
      '恐惧',
      '绝望',
      '孤独',
      '寒冷',
      '黑暗',
      '忧伤',
      '心碎',
      '不安',
      '焦虑',
      '失望',
      '悲痛',
      '寒心',
      '凄凉',
      '寂寞',
      '难过',
      '害怕',
      '恨',
      '厌恶',
    };
    var count = 0;
    for (final word in negatives) {
      count += word.allMatches(text).length;
    }
    return count;
  }

  String _classifyTone(double warmth, double intensity) {
    if (intensity < 0.3) return '平淡克制';
    if (warmth > 0.6 && intensity > 0.5) return '热烈奔放';
    if (warmth > 0.6) return '温暖柔和';
    if (warmth < 0.4) return '冷峻深沉';
    return '张弛有度';
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
    final cjkCount = _extractCjkChars(sentence).length;
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

  List<String> _extractCjkChars(String text) {
    return text.runes
        .where(
          (r) =>
              (r >= 0x4E00 && r <= 0x9FFF) ||
              (r >= 0x3400 && r <= 0x4DBF) ||
              (r >= 0x3000 && r <= 0x303F),
        )
        .map((r) => String.fromCharCode(r))
        .toList();
  }
}
