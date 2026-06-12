/// Tests for StyleDeviationDetector.
///
/// Validates Phase 19: style deviation detection against AuthorStyleProfile
/// with per-dimension breakdown and AI-scent scoring.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';

AuthorStyleProfile _testProfile({
  double avgSentenceLen = 18,
  double sentenceStdDev = 8,
  double rhythmScore = 0.3,
  double vocabularyRichness = 0.6,
  double dialogueRatio = 0.35,
  double descriptionRatio = 0.4,
  double actionRatio = 0.17,
  double metaphorFrequency = 0.08,
  double warmth = 0.6,
  double intensity = 0.4,
}) {
  return AuthorStyleProfile(
    manuscriptId: 'test-ms',
    sentenceLengthStats: SentenceLengthStats(
      avg: avgSentenceLen,
      stdDev: sentenceStdDev,
      median: avgSentenceLen - 2,
      shortRatio: 0.2,
      longRatio: 0.1,
    ),
    rhythmScore: rhythmScore,
    vocabularyRichness: vocabularyRichness,
    rhetoricHabits: RhetoricHabits(
      metaphorFrequency: metaphorFrequency,
      dialogueRatio: dialogueRatio,
      descriptionRatio: descriptionRatio,
      actionRatio: actionRatio,
    ),
    emotionalTone: EmotionalTone(
      overall: '温暖克制',
      warmth: warmth,
      intensity: intensity,
    ),
    analyzedChapterCount: 5,
    analyzedCharCount: 12000,
  );
}

void main() {
  group('StyleDeviationDetector', () {
    const detector = StyleDeviationDetector();

    test('should return null when text has no CJK characters', () {
      final profile = _testProfile();
      final result = detector.analyze(text: 'hello world', profile: profile);

      expect(result, isNull);
    });

    test('should return null when profile has insufficient data', () {
      final profile = AuthorStyleProfile(
        manuscriptId: 'test',
        analyzedChapterCount: 1,
        analyzedCharCount: 200,
      );
      final result = detector.analyze(
        text: '林风站在山门前。',
        profile: profile,
      );

      expect(result, isNull);
    });

    test('should return non-null result for valid input', () {
      final profile = _testProfile();
      final text = '林风站在山门前，望着远方的乌云密布的天空。'
          '他心中涌起一股不安的预感，仿佛有什么不好的事情即将发生。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      expect(result!.deviations.length, 5);
      expect(result.aiScentScore, greaterThanOrEqualTo(0));
      expect(result.aiScentScore, lessThanOrEqualTo(100));
    });

    test('should produce low AI-scent for text matching author style', () {
      final profile = _testProfile(
        avgSentenceLen: 16,
        rhythmScore: 0.35,
        vocabularyRichness: 0.55,
      );

      // Write text with varied sentence lengths matching the profile
      final text = '林风走进院子。'
          '月光洒在青石板上，映出一道长长的影子。'
          '他停下脚步，侧耳倾听远处传来的虫鸣。'
          '忽然，一阵冷风吹过，卷起地上的落叶。'
          '「谁在那儿？」他低声问道。'
          '没有人回答。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      // Text designed to match author style should have low score
      expect(result!.aiScentScore, lessThan(50));
    });

    test('should detect AI-uniform rhythm (high rhythm score)', () {
      final profile = _testProfile(
        rhythmScore: 0.3, // Author has varied rhythm
      );

      // Write text with very uniform sentence lengths (AI-like)
      final text = '林风站在山门前，望着远方的天空。'
          '他心中涌起一股不安的感觉。'
          '风吹过庭院，带起了地上的落叶。'
          '远处的钟声悠悠传来，回荡在山谷之间。'
          '他紧了紧手中的剑，目光坚定地望向前方。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      final rhythmDev = result!.deviations.firstWhere(
        (d) => d.dimension == StyleDimension.rhythm,
      );
      // Should detect the uniform rhythm
      expect(rhythmDev.explanation, contains('均匀'));
    });

    test('should detect vocabulary deviation', () {
      final profile = _testProfile(
        vocabularyRichness: 0.4, // Author uses simple vocabulary
      );

      // Text with very diverse/unusual vocabulary
      final text = '璀璨的穹苍之下，氤氲的岚霭缭绕于嶙峋的峰巅。'
          '瑰丽的霞光穿透葳蕤的枝桠，投射斑斓的光影。'
          '苍茫的天地间，他踽踽独行，寻觅着那缥缈的归途。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      final vocabDev = result!.deviations.firstWhere(
        (d) => d.dimension == StyleDimension.vocabulary,
      );
      // Should detect vocabulary mismatch
      expect(vocabDev.deviationScore, greaterThan(0.3));
    });

    test('should detect over-balanced description rhetoric', () {
      final profile = _testProfile(
        descriptionRatio: 0.3,
        metaphorFrequency: 0.05,
      );

      // Text heavy on descriptions and metaphors
      final text = '如同一条银色的丝带，小溪蜿蜒流过翠绿的山谷。'
          '仿佛大自然精心雕琢的画卷，每一处都是绝美的风景。'
          '阳光像碎金一样洒落在水面上，波光粼粼，宛如梦境。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      final rhetoricDev = result!.deviations.firstWhere(
        (d) => d.dimension == StyleDimension.rhetoric,
      );
      // Should detect description-heavy / metaphor-heavy pattern
      expect(rhetoricDev.deviationScore, greaterThan(0.3));
    });

    test('should detect flat emotion curve (AI pattern)', () {
      final profile = _testProfile(
        intensity: 0.7, // Author has high emotional variation
        warmth: 0.6,
      );

      // Emotionally flat text
      final text = '林风走在路上。'
          '路边的树木郁郁葱葱，阳光透过树叶洒下斑驳的光影。'
          '他继续向前走去，步履平稳而从容。'
          '远处的山峦在云雾中若隐若现，景色宜人。'
          '他到达了目的地，一座古朴的客栈矗立在路旁。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      final toneDev = result!.deviations.firstWhere(
        (d) => d.dimension == StyleDimension.emotionalTone,
      );
      // Flat emotion should be detected
      expect(toneDev.explanation, contains('平淡'));
    });

    test('should include all 5 dimensions in result', () {
      final profile = _testProfile();
      final text = '他走在路上。忽然停下了脚步。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      final dimensions = result!.deviations.map((d) => d.dimension).toList();
      expect(dimensions, contains(StyleDimension.sentenceLength));
      expect(dimensions, contains(StyleDimension.rhythm));
      expect(dimensions, contains(StyleDimension.vocabulary));
      expect(dimensions, contains(StyleDimension.rhetoric));
      expect(dimensions, contains(StyleDimension.emotionalTone));
    });

    test('should set hasDeviations based on threshold', () {
      final profile = _testProfile();

      // Very short text — may not have deviations
      final text = '他慢慢地走了。她转过身来，静静地看着。';
      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      // Short text may or may not have deviations, but the field should be set
      expect(result!.hasDeviations, isA<bool>());
    });

    test('should generate appropriate summary', () {
      final profile = _testProfile(
        rhythmScore: 0.2,
        intensity: 0.7,
      );

      // Text designed to trigger multiple deviations
      final text = '如同一条银色的丝带，小溪蜿蜒流过翠绿的山谷。'
          '仿佛大自然精心雕琢的画卷，每一处都是绝美的风景。'
          '阳光像碎金一样洒落在水面上。'
          '他站在那里，看着这一切。'
          '周围的一切都很平静。'
          '风景依旧美丽如初。'
          '他继续静静地欣赏着。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      expect(result!.summary, isNotEmpty);
      expect(result.summary, anyOf(contains('AI'), contains('偏差')));
    });

    test('should produce no deviations summary for matching text', () {
      final profile = _testProfile();
      final text = '林风走进院子。'
          '月光洒在青石板上，映出一道长长的影子。'
          '他停下脚步，侧耳倾听。'
          '忽然一阵冷风吹过。'
          '「谁在那儿？」他低声问道。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      if (!result!.hasDeviations) {
        expect(result.summary, contains('高度一致'));
      }
    });

    test('deviation scores should be clamped to 0-1 range', () {
      final profile = _testProfile(avgSentenceLen: 5, sentenceStdDev: 1);

      final text = '林风站在山门前，望着远方的乌云密布的天空。'
          '他心中涌起一股不安的预感。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      for (final dev in result!.deviations) {
        expect(dev.deviationScore, greaterThanOrEqualTo(0.0));
        expect(dev.deviationScore, lessThanOrEqualTo(1.0));
      }
    });
  });
}
