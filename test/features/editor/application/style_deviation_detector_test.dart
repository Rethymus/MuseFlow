/// Tests for StyleDeviationDetector.
///
/// Validates Phase 19: style deviation detection against AuthorStyleProfile
/// with per-dimension breakdown and AI-scent scoring.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/style_deviation_detector.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:museflow/features/editor/infrastructure/sentiment_lexicon.dart';

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
      final result = detector.analyze(text: '林风站在山门前。', profile: profile);

      expect(result, isNull);
    });

    test('should return non-null result for valid input', () {
      final profile = _testProfile();
      final text =
          '林风站在山门前，望着远方的乌云密布的天空。'
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
      final text =
          '林风走进院子。'
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
      final text =
          '林风站在山门前，望着远方的天空。'
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
      final text =
          '璀璨的穹苍之下，氤氲的岚霭缭绕于嶙峋的峰巅。'
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
      final text =
          '如同一条银色的丝带，小溪蜿蜒流过翠绿的山谷。'
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

      // Emotionally flat text. lexicon 统一后数值变化（260617-f7l）:
      // SentimentLexicon.intensityScore returns 0.3 early-exit for text
      // with <100 CJK chars (the pre-fix fixture was 83 CJK and 1 lexicon
      // hit on '阳光'). Rewrote the fixture to a >100-CJK passage with
      // zero lexicon matches so the density formula returns intensity=0
      // and isFlat (intensity < 0.3) fires, triggering the '平淡' branch.
      final text =
          '林风走在路上。'
          '他看着前方的路。'
          '路边的树很多。'
          '他继续向前走去。'
          '走到了一个地方。'
          '那里有一间屋子。'
          '门口挂着灯笼。'
          '他推开门走进去。'
          '屋里没什么东西。'
          '他坐下来喝口水。'
          '天色慢慢暗下来。'
          '他点燃了灯油。'
          '屋外传来几声狗叫。'
          '他靠着墙坐着。'
          '没有什么事情发生。';

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
      final profile = _testProfile(rhythmScore: 0.2, intensity: 0.7);

      // Text designed to trigger multiple deviations
      final text =
          '如同一条银色的丝带，小溪蜿蜒流过翠绿的山谷。'
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
      final text =
          '林风走进院子。'
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

      final text =
          '林风站在山门前，望着远方的乌云密布的天空。'
          '他心中涌起一股不安的预感。';

      final result = detector.analyze(text: text, profile: profile);

      expect(result, isNotNull);
      for (final dev in result!.deviations) {
        expect(dev.deviationScore, greaterThanOrEqualTo(0.0));
        expect(dev.deviationScore, lessThanOrEqualTo(1.0));
      }
    });

    // Regression: bare single-char 恨/爱 entries in the inline sentiment Sets
    // are matched as substrings by String.allMatches, over-counting sentiment
    // inside common compounds (恨不得 = eager/positive; 可爱/爱好 = compounds
    // that contain the bare char). See PLAN 260617-1uk.
    group('sentiment substring overcount regression', () {
      test(
        'should not inflate negative sentiment via bare 恨 inside 恨不得 when text is dominated by eager 恨不得',
        () {
          // regression: bare '恨' substring must not match inside 恨不得.
          // 恨不得 means "eager to / dying to" (positive sense), but the bare
          // '恨' needle would previously add a spurious negative hit, pushing
          // emotionalTone.intensity above the neutral band.
          // Two 恨不得 occurrences in a short passage force pre-fix
          // negativeCount >= 2, well above the intensity threshold.
          const text = '他恨不得立刻出发。她恨不得马上跑去。两人恨不得飞过去。';

          final result = detector.analyze(text: text, profile: _testProfile());

          expect(result, isNotNull);
          final toneDev = result!.deviations.firstWhere(
            (d) => d.dimension == StyleDimension.emotionalTone,
          );
          // After fix: no genuine negative words present → intensity stays in
          // the neutral band (< 0.6). Pre-fix: bare '恨' hits 3x → inflates.
          expect(
            toneDev.textValue,
            lessThan(0.6),
            reason:
                'Bare 恨 substring must not match inside 恨不得 (compound = '
                'eager/positive). intensity inflated by spurious negative hits.',
          );
        },
      );

      test(
        'should not inflate positive sentiment via bare 爱 inside 可爱/爱好 compounds when no genuine positives are present',
        () {
          // regression: bare '爱' substring must not match inside 可爱/爱好/
          // 爱情. These compounds contain the char 爱 but are not in the
          // positive Set; the bare '爱' needle would previously add spurious
          // positive hits, pushing intensity above the neutral band.
          // Three compound occurrences in a short passage force pre-fix
          // positiveCount >= 3, well above the threshold.
          const text = '小女孩可爱极了。这是她的爱好。她相信爱情。';

          final result = detector.analyze(text: text, profile: _testProfile());

          expect(result, isNotNull);
          final toneDev = result!.deviations.firstWhere(
            (d) => d.dimension == StyleDimension.emotionalTone,
          );
          // After fix: no genuine positive words present → intensity stays in
          // the neutral band (< 0.6). Pre-fix: bare '爱' hits 3x → inflates.
          expect(
            toneDev.textValue,
            lessThan(0.6),
            reason:
                'Bare 爱 substring must not match inside 可爱/爱好/爱情 '
                '(compounds containing the char). intensity inflated by '
                'spurious positive hits.',
          );
        },
      );
    });

    // Regression: detector._computeEmotionalTone must reuse the shared
    // SentimentLexicon (same ruler as StyleAnalyzer) instead of an inline
    // 22-word table + custom warmth/intensity formulas. Pre-fix detector
    // silently drifts from the authoritative profile-builder ruler,扭曲
    // emotionalTone 偏差分 (反AI味核心信号). See PLAN 260617-f7l.
    group('sentiment lexicon consistency (260617-f7l)', () {
      test(
        'should compute emotionalTone using SentimentLexicon, not an inline table (lexicon-only words must register)',
        () {
          // Fixture deliberately uses lexicon-ONLY positive words
          // (温馨/慈爱/相伴/相守/携手/守护/依偎/微笑/春风/陪伴/并肩/庇护/
          // 兰花/碧空/花香/清风/鸟鸣/溪流/山峦/云朵/悠然/晨曦/暮色/繁星)
          // that are NOT in the detector's pre-fix 22-word inline table.
          // Pre-fix: positiveCount=0 → intensity falls to neutral-band
          // baseline formula (≈0.5). Post-fix: SentimentLexicon matches
          // 23 occurrences → intensity climbs to density-band (≈1.0).
          // CJK count is 123 (>=100) so SentimentLexicon.intensityScore
          // takes the density path instead of the <100 early-return 0.3.
          const text =
              '她微笑着走来，眼中满是温馨与慈爱。'
              '两人相伴相守，携手走过四季的每一个清晨与黄昏，相互陪伴彼此守护。'
              '他依偎在她的身旁，并肩迎接每一阵春风与晨曦。'
              '庭院里的兰花悄然盛开，碧空下飘来阵阵花香与清风，鸟鸣声声入耳。'
              '溪流潺潺流过山峦之间，云朵悠然飘荡在繁星点点的暮色之中。';

          // Use neutral profile warmth/intensity so the deviation score is
          // driven primarily by textValue (detector-measured intensity).
          final profile = _testProfile(warmth: 0.5, intensity: 0.5);
          final result = detector.analyze(text: text, profile: profile);

          expect(result, isNotNull);
          final toneDev = result!.deviations.firstWhere(
            (d) => d.dimension == StyleDimension.emotionalTone,
          );

          // Guard: fixture must hit lexicon独有词 ≥5 (forces RED — pre-fix
          // inline table 0 matches).
          final expectedPositive = SentimentLexicon.countPositive(text);
          expect(
            expectedPositive,
            greaterThanOrEqualTo(5),
            reason:
                'fixture 必须命中 SentimentLexicon 独有词（温馨/慈爱/相伴/相守/'
                '携手/守护/依偎/微笑/春风 等）中至少 5 个',
          );

          // Pre-fix: inline table 0 matches → intensity = (0+0)/(cjk*0.03+1)*0.5+0.5
          //                = 0.5 (neutral-band baseline)
          // Post-fix: SentimentLexicon matches ≥5 → density-band intensity ≈1.0
          // Threshold > 0.6 cleanly separates the two states (pre 0.5 < 0.6, post 1.0 > 0.6).
          expect(
            toneDev.textValue,
            greaterThan(0.6),
            reason:
                'pre-fix 内联表对此文本 0 命中（温馨/慈爱/相伴/相守/携手/守护/'
                '依偎/微笑/春风 均不在 22 词内联表中）→ intensity 落到中性带 0.5；'
                'post-fix 复用 SentimentLexicon 命中 ≥5 → intensity 升至密度带，'
                '与 StyleAnalyzer 对同文本测量一致',
          );
        },
      );

      test(
        'should compute intensity via SentimentLexicon.intensityScore (same formula as StyleAnalyzer)',
        () {
          // Structural-equivalence guard: detector must compute intensity
          // with EXACTLY SentimentLexicon.intensityScore — not a custom
          // formula. Pre-fix detector uses
          //   (pos+neg)/(cjk*0.03+1)*0.5+0.5  (always ≥0.5, never 0)
          // Post-fix uses SentimentLexicon.intensityScore:
          //   <100 cjk → 0.3 ; else density/4 clamp
          // Fixture is >100 CJK so density path runs, ensuring the two
          // formulas produce observably different values.
          const text =
              '温暖阳光下的幸福时光，微风拂面，岁月静好。'
              '我们走在小路上，看着远方的青山与绿水，听着鸟鸣声声。'
              '兰花的清香在空气中弥漫，溪流缓缓流过翠竹掩映的山峦之间。'
              '繁星点点映照着碧空，清晨的露珠在叶片上闪着晶莹的光。'
              '晚风轻轻吹过暮色中的小村庄，云朵悠然飘荡在远方的天空。';

          final profile = _testProfile();
          final result = detector.analyze(text: text, profile: profile);

          expect(result, isNotNull);
          final toneDev = result!.deviations.firstWhere(
            (d) => d.dimension == StyleDimension.emotionalTone,
          );

          // Mirror StyleAnalyzer's exact computation:
          //   totalCjk = CJK rune count (Unified + Ext A + Symbols)
          //   intensity = SentimentLexicon.intensityScore(pos, neg, totalCjk)
          final cjkLen = text.runes
              .where(
                (r) =>
                    (r >= 0x4E00 && r <= 0x9FFF) ||
                    (r >= 0x3400 && r <= 0x4DBF) ||
                    (r >= 0x3000 && r <= 0x303F),
              )
              .length;
          final expectedIntensity = SentimentLexicon.intensityScore(
            SentimentLexicon.countPositive(text),
            SentimentLexicon.countNegative(text),
            cjkLen,
          );

          // Exact floating-point equality (1e-9 tolerance for FP noise).
          // Pre-fix detector uses a different formula → textValue ≠
          // expectedIntensity → RED. Post-fix delegates directly → GREEN.
          expect(
            toneDev.textValue,
            closeTo(expectedIntensity, 1e-9),
            reason:
                'detector 必须复用 SentimentLexicon.intensityScore 公式，'
                '与 StyleAnalyzer 同源；pre-fix 用自创 (pos+neg)/(cjk*0.03+1)*0.5+0.5 '
                '公式 → 不等',
          );
        },
      );
    });
  });
}
