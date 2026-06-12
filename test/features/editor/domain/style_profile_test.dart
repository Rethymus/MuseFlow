import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:museflow/features/editor/domain/style_sample.dart';
import 'package:museflow/features/editor/infrastructure/sentiment_lexicon.dart';

void main() {
  group('AuthorStyleProfile', () {
    test('should have default values', () {
      final profile = AuthorStyleProfile(manuscriptId: 'test-ms');
      expect(profile.manuscriptId, 'test-ms');
      expect(profile.analyzedChapterCount, 0);
      expect(profile.analyzedCharCount, 0);
      expect(profile.sampleParagraphs, isEmpty);
      expect(profile.hasData, isFalse);
    });

    test('should haveData when chapters >= 2 and chars >= 500', () {
      final profile = AuthorStyleProfile(
        manuscriptId: 'test-ms',
        analyzedChapterCount: 2,
        analyzedCharCount: 500,
      );
      expect(profile.hasData, isTrue);
    });

    test('should not haveData when chapters < 2', () {
      final profile = AuthorStyleProfile(
        manuscriptId: 'test-ms',
        analyzedChapterCount: 1,
        analyzedCharCount: 1000,
      );
      expect(profile.hasData, isFalse);
    });

    test('should not haveData when chars < 500', () {
      final profile = AuthorStyleProfile(
        manuscriptId: 'test-ms',
        analyzedChapterCount: 5,
        analyzedCharCount: 400,
      );
      expect(profile.hasData, isFalse);
    });

    test('should serialize to JSON and back', () {
      final profile = AuthorStyleProfile(
        manuscriptId: 'test-ms',
        analyzedChapterCount: 3,
        analyzedCharCount: 1200,
        sampleParagraphs: [
          StyleSample(
            chapterId: 'ch1',
            paragraphIndex: 0,
            text: '这是一段测试文字。',
            qualityScore: 0.85,
            dimensionScores: {StyleDimension.rhythm: 0.7},
          ),
        ],
      );
      final json = profile.toJson();
      final restored = AuthorStyleProfile.fromJson(json);
      expect(restored.manuscriptId, 'test-ms');
      expect(restored.analyzedChapterCount, 3);
      expect(restored.analyzedCharCount, 1200);
      expect(restored.sampleParagraphs.length, 1);
      expect(restored.sampleParagraphs.first.text, '这是一段测试文字。');
      expect(restored.sampleParagraphs.first.qualityScore, 0.85);
    });

    test('copyWith should preserve unchanged fields', () {
      final original = AuthorStyleProfile(
        manuscriptId: 'test-ms',
        analyzedChapterCount: 5,
        analyzedCharCount: 2000,
      );
      final updated = original.copyWith(analyzedChapterCount: 10);
      expect(updated.manuscriptId, 'test-ms');
      expect(updated.analyzedChapterCount, 10);
      expect(updated.analyzedCharCount, 2000);
    });
  });

  group('StyleDimension', () {
    test('should have correct labels', () {
      expect(StyleDimension.sentenceLength.label, '句式特征');
      expect(StyleDimension.rhythm.label, '节奏模式');
      expect(StyleDimension.vocabulary.label, '词汇特征');
      expect(StyleDimension.rhetoric.label, '修辞习惯');
      expect(StyleDimension.emotionalTone.label, '情感基调');
    });

    test('should interpret low rhythm score as varied', () {
      final interpretation = StyleDimension.rhythm.interpret(0.2);
      expect(interpretation, contains('变化丰富'));
    });

    test('should interpret high rhythm score as AI-like', () {
      final interpretation = StyleDimension.rhythm.interpret(0.9);
      expect(interpretation, contains('AI'));
    });

    test('should interpret vocabulary scores', () {
      expect(
        StyleDimension.vocabulary.interpret(0.1),
        contains('重复率高'),
      );
      expect(
        StyleDimension.vocabulary.interpret(0.5),
        contains('较为丰富'),
      );
    });
  });

  group('SentimentLexicon', () {
    test('should count positive words in text', () {
      final count = SentimentLexicon.countPositive('温暖阳光，春风拂面');
      expect(count, greaterThan(0));
    });

    test('should count negative words in text', () {
      final count = SentimentLexicon.countNegative('悲伤痛苦，孤独绝望');
      expect(count, greaterThan(0));
    });

    test('should return 0 for text with no sentiment words', () {
      final positive = SentimentLexicon.countPositive('今天去商店买东西');
      final negative = SentimentLexicon.countNegative('今天去商店买东西');
      expect(positive, 0);
      expect(negative, 0);
    });

    test('should compute warmth score correctly', () {
      // All positive → 1.0
      expect(SentimentLexicon.warmthScore(10, 0), 1.0);
      // All negative → 0.0
      expect(SentimentLexicon.warmthScore(0, 10), 0.0);
      // Equal → 0.5
      expect(SentimentLexicon.warmthScore(5, 5), 0.5);
    });

    test('should return neutral warmth for zero counts', () {
      expect(SentimentLexicon.warmthScore(0, 0), 0.5);
    });

    test('should classify tone correctly', () {
      // Low intensity + warm = 平静温和
      expect(SentimentLexicon.classifyTone(0.7, 0.2), '平静温和');
      // High intensity + warm = 热烈奔放
      expect(SentimentLexicon.classifyTone(0.8, 0.8), '热烈奔放');
      // High intensity + cold = 沉重压抑
      expect(SentimentLexicon.classifyTone(0.3, 0.8), '沉重压抑');
    });

    test('positive and negative word sets should have no duplicates', () {
      final positiveSet =
          SentimentLexicon.positiveWords.toSet();
      final positiveList = SentimentLexicon.positiveWords.toList();
      expect(positiveSet.length, positiveList.length);

      final negativeSet =
          SentimentLexicon.negativeWords.toSet();
      final negativeList = SentimentLexicon.negativeWords.toList();
      expect(negativeSet.length, negativeList.length);
    });
  });

  group('StyleSample', () {
    test('should serialize to JSON and back', () {
      const sample = StyleSample(
        chapterId: 'ch1',
        paragraphIndex: 2,
        text: '测试段落内容',
        qualityScore: 0.92,
        dimensionScores: {
          StyleDimension.rhythm: 0.8,
          StyleDimension.vocabulary: 0.7,
        },
      );

      final json = sample.toJson();
      final restored = StyleSample.fromJson(json);

      expect(restored.chapterId, 'ch1');
      expect(restored.paragraphIndex, 2);
      expect(restored.text, '测试段落内容');
      expect(restored.qualityScore, 0.92);
      expect(restored.dimensionScores[StyleDimension.rhythm], 0.8);
      expect(restored.dimensionScores[StyleDimension.vocabulary], 0.7);
    });

    test('equality should compare key fields', () {
      const a = StyleSample(
        chapterId: 'ch1',
        paragraphIndex: 0,
        text: 'same',
        qualityScore: 0.9,
      );
      const b = StyleSample(
        chapterId: 'ch1',
        paragraphIndex: 0,
        text: 'same',
        qualityScore: 0.9,
      );
      expect(a, equals(b));
    });
  });
}
