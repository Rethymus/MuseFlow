/// Style analyzer service — analyzes chapter text to build an [AuthorStyleProfile].
///
/// Computes five style dimensions from the author's existing chapters:
/// 1. Sentence length distribution (avg, std dev, median, short/long ratios)
/// 2. Rhythm/burstiness (sentence length variation)
/// 3. Vocabulary richness (unique CJK character ratio)
/// 4. Rhetoric habits (dialogue, description, action, metaphor ratios)
/// 5. Emotional tone (warmth, intensity via sentiment lexicon)
///
/// Also extracts top-quality paragraphs as [StyleSample]s for few-shot injection.
library;

import 'dart:math';

import 'package:museflow/features/editor/application/lexical_signature_extractor.dart';
import 'package:museflow/features/editor/application/style_analysis_utils.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:museflow/features/editor/domain/style_sample.dart';
import 'package:museflow/features/editor/infrastructure/sentiment_lexicon.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

// Shared ruler: CJK/sentence-length/rhythm/vocabulary math now lives in
// [StyleAnalysisUtils]. Both StyleAnalyzer (baseline) and
// StyleDeviationDetector (measurement) call it — see PLAN quick-260617-jgd.

/// Analyzes author writing style from chapters.
///
/// Produces an [AuthorStyleProfile] with quantified metrics across five
/// dimensions and a curated list of high-quality paragraph samples.
class StyleAnalyzer {
  /// Minimum CJK characters required in a chapter to include in analysis.
  static const int _minChapterChars = 100;

  /// Minimum characters for a paragraph to be considered as a style sample.
  static const int _minSampleChars = 50;

  /// Maximum characters for a style sample paragraph.
  static const int _maxSampleChars = 500;

  /// Number of top paragraphs to extract as style samples.
  static const int _topSampleCount = 5;

  StyleAnalyzer();

  /// Analyzes the given chapters and returns a complete [AuthorStyleProfile].
  ///
  /// Chapters with fewer than [_minChapterChars] CJK characters are skipped.
  /// Returns a default profile if no chapters qualify.
  AuthorStyleProfile analyze({
    required String manuscriptId,
    required List<Chapter> chapters,
    List<Chapter>? alreadyAnalyzed,
  }) {
    final qualifying = chapters
        .where((c) => _cjkCharCount(c.documentContent) >= _minChapterChars)
        .toList();

    if (qualifying.isEmpty) {
      return AuthorStyleProfile(
        manuscriptId: manuscriptId,
        analyzedChapterCount: 0,
        analyzedCharCount: 0,
      );
    }

    // Collect all text for aggregate analysis
    final allText = qualifying.map((c) => c.documentContent).join('\n\n');
    final totalCjk = _cjkCharCount(allText);

    // Analyze each dimension
    final sentenceLengths = _extractSentenceLengths(allText);
    final sentenceStats = _computeSentenceStats(sentenceLengths);
    final rhythmScore = _computeRhythmScore(sentenceLengths);
    final vocabularyRichness = _computeVocabularyRichness(allText);
    final rhetoricHabits = _computeRhetoricHabits(allText);
    final emotionalTone = _computeEmotionalTone(allText);

    // Extract top quality paragraphs as style samples
    final samples = _extractTopSamples(qualifying, totalCjk);

    // Extract author characteristic n-gram vocabulary from all analyzed text.
    final lexicalSignature = LexicalSignatureExtractor.extract(allText);

    // Determine if we should merge with existing profile (incremental update)
    final analyzedCount = alreadyAnalyzed?.length ?? 0;

    return AuthorStyleProfile(
      manuscriptId: manuscriptId,
      sentenceLengthStats: sentenceStats,
      rhythmScore: rhythmScore,
      vocabularyRichness: vocabularyRichness,
      rhetoricHabits: rhetoricHabits,
      emotionalTone: emotionalTone,
      lexicalSignature: lexicalSignature,
      analyzedChapterCount: qualifying.length + analyzedCount,
      analyzedCharCount: totalCjk,
      lastAnalyzedAt: DateTime.now(),
      sampleParagraphs: samples,
    );
  }

  // ── Dimension 1: Sentence Length ──────────────────────────────────────

  /// Splits text into sentences by Chinese/standard punctuation and returns
  /// the CJK character count of each sentence.
  ///
  /// Delegates to [StyleAnalysisUtils] — the shared ruler.
  List<int> _extractSentenceLengths(String text) =>
      StyleAnalysisUtils.extractSentenceLengths(text);

  SentenceLengthStats _computeSentenceStats(List<int> lengths) {
    if (lengths.isEmpty) {
      return const SentenceLengthStats();
    }

    final sorted = List<int>.from(lengths)..sort();
    final n = lengths.length;
    final avg = lengths.reduce((a, b) => a + b) / n;
    final variance =
        lengths.map((l) => (l - avg) * (l - avg)).reduce((a, b) => a + b) / n;
    final stdDev = variance > 0 ? sqrt(variance) : 0.0;
    final median = n.isOdd
        ? sorted[n ~/ 2].toDouble()
        : ((sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2).toDouble();
    final shortRatio = lengths.where((l) => l < 15).length / n;
    final longRatio = lengths.where((l) => l > 40).length / n;

    return SentenceLengthStats(
      avg: avg,
      stdDev: stdDev,
      median: median,
      shortRatio: shortRatio,
      longRatio: longRatio,
    );
  }

  // ── Dimension 2: Rhythm/Burstiness ────────────────────────────────────

  /// Computes rhythm score (0.0 = very varied/bursty, 1.0 = very uniform).
  ///
  /// Delegates to [StyleAnalysisUtils] — the shared ruler.
  double _computeRhythmScore(List<int> lengths) =>
      StyleAnalysisUtils.computeRhythmScore(lengths);

  // ── Dimension 3: Vocabulary Richness ─────────────────────────────────

  /// Computes vocabulary richness (0.0 = repetitive, 1.0 = very diverse).
  ///
  /// Delegates to [StyleAnalysisUtils] — the shared ruler.
  double _computeVocabularyRichness(String text) =>
      StyleAnalysisUtils.computeVocabularyRichness(text);

  // ── Dimension 4: Rhetoric Habits ─────────────────────────────────────

  /// Estimates rhetoric ratios by detecting text patterns.
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
        descriptionCount++; // metaphors are also descriptive
      } else if (_isAction(trimmed)) {
        actionCount++;
      } else if (_isDescription(trimmed)) {
        descriptionCount++;
      }
    }

    if (totalAnalyzed == 0) {
      return const RhetoricHabits();
    }

    return RhetoricHabits(
      dialogueRatio: dialogueCount / totalAnalyzed,
      descriptionRatio: descriptionCount / totalAnalyzed,
      actionRatio: actionCount / totalAnalyzed,
      metaphorFrequency: metaphorCount / totalAnalyzed,
    );
  }

  bool _isDialogue(String sentence) {
    // Chinese dialogue markers: 「」 "" ：said patterns
    return sentence.contains('「') ||
        sentence.contains('」') ||
        sentence.contains('"') ||
        sentence.contains('"') ||
        RegExp(r'[一-鿿]{1,4}(说|道|喊|叫|问|答|笑|怒|骂|吼|嘀咕|嘟囔|喃喃)').hasMatch(sentence);
  }

  bool _isAction(String sentence) {
    // Action verbs at sentence start
    return RegExp(
      r'^[一-鿿]{1,3}(走|跑|跳|打|踢|抓|握|挥|抬|举|放|推|拉|扯|砍|刺|挥|转|回|看|盯|望|瞥|听|闻)',
    ).hasMatch(sentence.trim());
  }

  bool _isDescription(String sentence) {
    // Description indicators: adjectives, location/time setup
    final cjkCount = _cjkCharCount(sentence);
    final adjCount = RegExp(r'[一-鿿]{2}(的|地|得)').allMatches(sentence).length;
    return adjCount >= 2 || (cjkCount > 20 && adjCount >= 1);
  }

  bool _hasMetaphor(String sentence) {
    // Metaphor/simile markers: 像...一样, 如同, 仿佛, 宛如, 犹如, 似
    return sentence.contains('像') ||
        sentence.contains('如同') ||
        sentence.contains('仿佛') ||
        sentence.contains('宛如') ||
        sentence.contains('犹如') ||
        sentence.contains('似的') ||
        sentence.contains('一般');
  }

  // ── Dimension 5: Emotional Tone ───────────────────────────────────────

  EmotionalTone _computeEmotionalTone(String text) {
    final positiveCount = SentimentLexicon.countPositive(text);
    final negativeCount = SentimentLexicon.countNegative(text);
    final totalCjk = _cjkCharCount(text);

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

  // ── Style Sample Extraction ───────────────────────────────────────────

  /// Extracts top-quality paragraphs from chapters as [StyleSample]s.
  ///
  /// Paragraphs are scored by a composite of dimension metrics.
  /// The [_topSampleCount] highest-scoring paragraphs are returned.
  List<StyleSample> _extractTopSamples(List<Chapter> chapters, int totalCjk) {
    final candidates = <_ParagraphCandidate>[];

    for (final chapter in chapters) {
      final paragraphs = chapter.documentContent.split(RegExp(r'\n\s*\n'));
      for (var i = 0; i < paragraphs.length; i++) {
        final text = paragraphs[i].trim();
        final cjkLen = _cjkCharCount(text);
        if (cjkLen < _minSampleChars || cjkLen > _maxSampleChars) continue;

        final score = _scoreParagraph(text);
        candidates.add(
          _ParagraphCandidate(
            chapterId: chapter.id,
            paragraphIndex: i,
            text: text,
            score: score,
          ),
        );
      }
    }

    // Sort by score descending, take top N
    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates
        .take(_topSampleCount)
        .map(
          (c) => StyleSample(
            chapterId: c.chapterId,
            paragraphIndex: c.paragraphIndex,
            text: c.text,
            qualityScore: c.score,
            dimensionScores: _computeDimensionScores(c.text),
          ),
        )
        .toList();
  }

  /// Scores a paragraph's quality for style sampling.
  ///
  /// Composite score based on:
  /// - Sentence length variety (0.25)
  /// - Vocabulary richness (0.25)
  /// - Emotional expressiveness (0.25)
  /// - Rhetoric diversity (0.25)
  double _scoreParagraph(String text) {
    final sentenceLens = _extractSentenceLengths(text);
    final rhythm = _computeRhythmScore(sentenceLens);
    final vocab = _computeVocabularyRichness(text);
    final tone = _computeEmotionalTone(text);
    final rhetoric = _computeRhetoricHabits(text);

    // Rhythm: lower score = more varied = better
    final rhythmQuality = 1.0 - rhythm;
    // Vocab: higher = better
    final vocabQuality = vocab;
    // Tone expressiveness: moderate intensity is ideal
    final toneExpressiveness =
        1.0 - (tone.intensity - 0.4).abs(); // peak at 0.4-0.6
    // Rhetoric diversity: balanced mix is ideal
    final rhetoricSum =
        rhetoric.dialogueRatio +
        rhetoric.descriptionRatio +
        rhetoric.actionRatio +
        rhetoric.metaphorFrequency;
    final rhetoricDiversity = (rhetoricSum > 0 && rhetoricSum < 0.95)
        ? 1.0
        : rhetoricSum;

    return (rhythmQuality * 0.25) +
        (vocabQuality * 0.25) +
        (toneExpressiveness * 0.25) +
        (rhetoricDiversity * 0.25);
  }

  Map<StyleDimension, double> _computeDimensionScores(String text) {
    final sentenceLens = _extractSentenceLengths(text);
    return {
      StyleDimension.sentenceLength: _sentenceLengthScore(sentenceLens),
      StyleDimension.rhythm: _computeRhythmScore(sentenceLens),
      StyleDimension.vocabulary: _computeVocabularyRichness(text),
      StyleDimension.rhetoric: _computeRhetoricHabits(text).metaphorFrequency,
      StyleDimension.emotionalTone: _computeEmotionalTone(text).intensity,
    };
  }

  double _sentenceLengthScore(List<int> lengths) {
    if (lengths.isEmpty) return 0.5;
    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    // Normalize: avg 10-15 chars = short (1.0), 25+ = long (0.0)
    return ((25 - avg) / 15).clamp(0.0, 1.0);
  }

  // ── CJK Character Utilities ──────────────────────────────────────────

  /// Counts CJK characters (Chinese, Japanese, Korean) in text.
  ///
  /// Delegates to [StyleAnalysisUtils] — the shared ruler.
  static int _cjkCharCount(String text) =>
      StyleAnalysisUtils.cjkCharCount(text);
}

/// Internal candidate for paragraph scoring.
class _ParagraphCandidate {
  final String chapterId;
  final int paragraphIndex;
  final String text;
  final double score;

  const _ParagraphCandidate({
    required this.chapterId,
    required this.paragraphIndex,
    required this.text,
    required this.score,
  });
}
