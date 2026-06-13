import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/style_analyzer.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

Chapter _makeChapter({
  required String id,
  required String content,
  String title = 'Test Chapter',
  int order = 0,
}) {
  return Chapter(
    id: id,
    manuscriptId: 'test-ms',
    title: title,
    sortOrder: order,
    documentContent: content,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  late StyleAnalyzer analyzer;

  setUp(() {
    analyzer = StyleAnalyzer();
  });

  group('StyleAnalyzer.analyze', () {
    test('should return default profile for empty chapter list', () {
      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [],
      );
      expect(profile.manuscriptId, 'test-ms');
      expect(profile.analyzedChapterCount, 0);
      expect(profile.hasData, isFalse);
    });

    test('should skip chapters with fewer than 100 CJK chars', () {
      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: '短'),
        ],
      );
      expect(profile.analyzedChapterCount, 0);
      expect(profile.hasData, isFalse);
    });

    test('should analyze chapters with sufficient CJK content', () {
      const baseText = '林风站在山巅，目光扫过无际的云海。'
          '他的心中充满了复杂的情感，既有对未来的期待，也有对过去的留恋。'
          '远处传来一声鹤鸣，划破了黎明的寂静。'
          '「师尊，弟子已经准备好了。」他低声说道。'
          '微风拂过他的衣袍，带来一丝凉意。'
          '这一刻，天地之间仿佛只剩他一人。';
      final longText = baseText * 10;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: longText),
        ],
      );

      expect(profile.analyzedChapterCount, 1);
      expect(profile.analyzedCharCount, greaterThan(100));
    });

    test('should compute sentence length stats', () {
      const baseText = '林风站在山巅。'
          '目光扫过无际的云海。'
          '他的心中充满了复杂的情感。'
          '「师尊，弟子已经准备好了。」';
      final text = baseText * 30;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text),
        ],
      );

      expect(profile.sentenceLengthStats.avg, greaterThan(0));
      expect(profile.sentenceLengthStats.stdDev, greaterThanOrEqualTo(0));
      expect(profile.sentenceLengthStats.median, greaterThan(0));
    });

    test('should compute rhythm score between 0 and 1', () {
      const baseText = '林风站在山巅，目光扫过无际的云海。'
          '他的心中充满了复杂的情感。';
      final text = baseText * 20;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text),
        ],
      );

      expect(profile.rhythmScore, greaterThanOrEqualTo(0.0));
      expect(profile.rhythmScore, lessThanOrEqualTo(1.0));
    });

    test('should compute vocabulary richness', () {
      // Use diverse text segments to ensure non-zero unique character ratio
      const segments = [
        '修仙之途漫漫兮，求道之心坚如铁。',
        '灵气充盈天地间，万物生灭皆有道。',
        '少年林风立于崖顶，衣袂飘扬若仙人临世。',
        '他深深呼吸，感受着体内真元缓缓流转。',
        '远处青山叠翠，溪水潺潺绕过古木参天。',
        '师父曾言：大道无形，生育天地；大道无情，运行日月。',
        '忽然间，一道惊雷劈开了苍穹，风雨骤至。',
        '林风握紧手中长剑，眼神如星辰般璀璨。',
        '修炼之人最忌心浮气躁，需静心凝神方可悟道。',
        '悬崖边的一株孤松，历经千载风霜依然挺拔。',
      ];
      final text = segments.join('\n');

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text),
        ],
      );

      expect(profile.vocabularyRichness, greaterThan(0));
      expect(profile.vocabularyRichness, lessThanOrEqualTo(1.0));
    });

    test('should compute rhetoric habits', () {
      const baseText = '林风说：「今日天气不错。」'
          '他走在青石路上，看着路边的花花草草。'
          '天空蔚蓝如洗，云朵洁白似棉。'
          '「师尊，我要下山历练。」林风道。';
      final text = baseText * 15;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text),
        ],
      );

      expect(profile.rhetoricHabits.dialogueRatio, greaterThanOrEqualTo(0));
      expect(profile.rhetoricHabits.descriptionRatio, greaterThanOrEqualTo(0));
    });

    test('should compute emotional tone', () {
      const baseText = '温暖的阳光洒满大地，带来了幸福和希望。'
          '他微笑着看着远方的山峦，心中充满了感恩。'
          '这是一个美好的清晨，一切都很宁静祥和。';
      final text = baseText * 15;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text),
        ],
      );

      expect(profile.emotionalTone.overall, isNotEmpty);
      expect(profile.emotionalTone.warmth, greaterThanOrEqualTo(0));
      expect(profile.emotionalTone.warmth, lessThanOrEqualTo(1));
      expect(profile.emotionalTone.intensity, greaterThanOrEqualTo(0));
      expect(profile.emotionalTone.intensity, lessThanOrEqualTo(1));
    });

    test('should extract style samples from qualifying paragraphs', () {
      const para = '林风站在山巅，目光扫过无际的云海。'
          '他的心中充满了复杂的情感，既有对未来的期待，也有对过去的留恋。'
          '远处传来一声鹤鸣，划破了黎明的寂静。'
          '微风吹过他的衣袍，带来一丝凉意。'
          '这一刻，天地之间仿佛只剩他一人，孤独而坚定。';
      final paragraphs = List.generate(8, (_) => para).join('\n\n');

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: paragraphs),
        ],
      );

      expect(profile.sampleParagraphs.isNotEmpty, isTrue);
      expect(profile.sampleParagraphs.length, lessThanOrEqualTo(5));
      for (final sample in profile.sampleParagraphs) {
        expect(sample.chapterId, 'ch1');
        expect(sample.qualityScore, greaterThan(0));
        expect(sample.text, isNotEmpty);
      }
    });

    test('should analyze multiple chapters', () {
      const baseText = '林风站在山巅，目光扫过无际的云海。'
          '他的心中充满了复杂的情感。'
          '这一刻，天地之间仿佛只剩他一人。';
      final text = baseText * 20;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text, order: 0),
          _makeChapter(id: 'ch2', content: text, order: 1),
          _makeChapter(id: 'ch3', content: text, order: 2),
        ],
      );

      expect(profile.analyzedChapterCount, 3);
      expect(profile.hasData, isTrue);
    });

    test('should handle mixed content with Chinese and punctuation', () {
      const baseText = '「师尊，弟子已经准备好了。」林风跪在石台上，'
          '目光坚定地看着面前的老者。'
          '老者微微点头，说道：「去吧，记住为师的教诲。」';
      final text = baseText * 20;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text),
        ],
      );

      expect(profile.analyzedChapterCount, 1);
      expect(profile.rhetoricHabits.dialogueRatio, greaterThan(0));
    });

    test('profile should be serializable round-trip', () {
      const baseText = '温暖的阳光洒满大地，带来了幸福和希望。'
          '林风说：「今日天气不错，我们去山上走走吧。」'
          '天空蔚蓝如洗，云朵洁白似棉花糖。';
      final text = baseText * 20;

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: text),
        ],
      );

      final json = profile.toJson();
      final restored = AuthorStyleProfile.fromJson(json);

      expect(restored.manuscriptId, profile.manuscriptId);
      expect(restored.analyzedChapterCount, profile.analyzedChapterCount);
      expect(restored.rhythmScore, profile.rhythmScore);
      expect(restored.vocabularyRichness, profile.vocabularyRichness);
      expect(restored.emotionalTone.overall, profile.emotionalTone.overall);
    });

    test('should populate lexicalSignature from chapters with repeated terms', () {
      // Two chapters, each >= 100 CJK chars, totaling >= 500 chars, with
      // the characteristic term "剑意" repeated to dominate the n-gram ranking.
      const charSeed = '剑意凌厉剑意冲霄剑意纵横剑意不绝剑意浩荡。'
          '林风立于崖顶，衣袂飘扬若仙人临世，眼神如星辰般璀璨。';
      final chapterContent = charSeed * 6; // well over 100 chars, repeats 剑意

      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [
          _makeChapter(id: 'ch1', content: chapterContent, order: 0),
          _makeChapter(id: 'ch2', content: chapterContent, order: 1),
        ],
      );

      expect(profile.hasData, isTrue);
      expect(profile.lexicalSignature.isEmpty, isFalse);
      expect(profile.lexicalSignature.topTerms, isNotEmpty);
    });

    test('should produce empty lexicalSignature for empty chapter list', () {
      final profile = analyzer.analyze(
        manuscriptId: 'test-ms',
        chapters: [],
      );
      expect(profile.lexicalSignature.isEmpty, isTrue);
    });
  });
}
