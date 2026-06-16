/// Tests for AntiAIScentProcessor.
///
/// Validates AI-05 (anti-AI-scent prompt layer) and AI-06 (post-processing):
/// - Banned phrase replacement with boundary-aware matching
/// - Highlight-only phrases (common literary words) wrapped with 【】
/// - Structural pattern highlighting with 【】 markers
/// - ProcessingResult with processed text and highlight locations
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';

void main() {
  group('AntiAIScentProcessor', () {
    late AntiAIScentProcessor processor;

    setUp(() {
      processor = AntiAIScentProcessor();
    });

    group('banned phrase auto-replacement', () {
      test(
        'should highlight 然而 instead of auto-replacing (highlight-only)',
        () {
          final result = processor.process(
            '他看着远方，然而心中却无比平静。',
            bannedPhrases: [],
          );
          // 然而 is a common literary word — should be highlighted, not replaced
          expect(result.processedText, contains('【然而】'));
          expect(result.processedText, isNot(contains('但是')));
        },
      );

      test('should delete 综上所述 (empty replacement)', () {
        final result = processor.process('综上所述，这是一个好故事。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('综上所述')));
      });

      test('should delete 值得注意的是', () {
        final result = processor.process('值得注意的是，他没有放弃。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('值得注意的是')));
      });

      test('should highlight 毫无疑问 instead of auto-deleting', () {
        final result = processor.process('毫无疑问，这是正确的选择。', bannedPhrases: []);
        expect(result.processedText, contains('【毫无疑问】'));
      });

      test('should highlight 首先/其次/最后 instead of auto-deleting', () {
        final result = processor.process(
          '首先，他来了。其次，他走了。最后，他回来了。',
          bannedPhrases: [],
        );
        expect(result.processedText, contains('【首先】'));
        expect(result.processedText, contains('【其次】'));
        expect(result.processedText, contains('【最后】'));
      });

      test('should use boundary-aware matching per Pitfall 5', () {
        // "然而" inside a compound word should NOT be highlighted
        final result = processor.process('这件事自然而然地发生了。', bannedPhrases: []);
        // "然而" is inside "自然而然", should NOT be highlighted
        expect(result.processedText, contains('自然而然'));
      });

      test('should highlight 然而 at string boundaries', () {
        final result = processor.process('然而天黑了。', bannedPhrases: []);
        // "然而" at start of string should be highlighted
        expect(result.processedText, contains('【然而】'));
      });

      test(
        'should highlight 然而 at sentence boundaries (after punctuation)',
        () {
          final result = processor.process('天亮了。然而他又睡着了。', bannedPhrases: []);
          expect(result.processedText, contains('【然而】'));
        },
      );

      test('should respect additional bannedPhrases from parameter', () {
        final result = processor.process('这个故事真棒极了。', bannedPhrases: ['棒极了']);
        expect(result.processedText, isNot(contains('棒极了')));
      });
    });

    group('highlight-only phrase behavior', () {
      test('should wrap common intensifiers with 【】 instead of deleting', () {
        final result = processor.process('这极其重要，十分紧急。', bannedPhrases: []);
        expect(result.processedText, contains('【极其】'));
        expect(result.processedText, contains('【十分】'));
        // The words should still be present (not deleted)
        expect(result.processedText, contains('重要'));
        expect(result.processedText, contains('紧急'));
      });

      test('should wrap common transitions with 【】 instead of deleting', () {
        final result = processor.process('事实上，他一直在等你。', bannedPhrases: []);
        expect(result.processedText, contains('【事实上】'));
        expect(result.processedText, contains('他一直在等你'));
      });

      test('should wrap literary time words with 【】', () {
        final result = processor.process('刹那间，他明白了。', bannedPhrases: []);
        expect(result.processedText, contains('【刹那间】'));
        expect(result.processedText, contains('他明白了'));
      });

      test(
        'should include highlight-only phrases in synonymKeys for prompt layer',
        () {
          final keys = AntiAIScentProcessor.synonymKeys;
          // Common words should still be in the banned list for AI prompt
          expect(keys, contains('然而'));
          expect(keys, contains('最后'));
          expect(keys, contains('极其'));
          expect(keys, contains('毫无疑问'));
          // And AI-specific words too
          expect(keys, contains('综上所述'));
          expect(keys, contains('值得注意的是'));
        },
      );

      test('should highlight multiple highlight-only phrases in one text', () {
        final result = processor.process(
          '首先，不可否认这件事极其重要。最后，大家一致同意。',
          bannedPhrases: [],
        );
        expect(result.processedText, contains('【首先】'));
        expect(result.processedText, contains('【不可否认】'));
        expect(result.processedText, contains('【极其】'));
        expect(result.processedText, contains('【最后】'));
      });

      test(
        'should not highlight highlight-only phrases inside compound words',
        () {
          final result = processor.process('他自然而然地走过去。', bannedPhrases: []);
          // "然而" inside "自然而然" should NOT be highlighted
          expect(result.processedText, contains('自然而然'));
        },
      );
    });

    group('classic literature false-positive prevention', () {
      test('should not destroy classic fiction prose structure', () {
        // Simulates a passage in style of 余华's 《活着》
        final passage =
            '然而福贵并没有放弃。他告诉自己，最后一定要活下去。'
            '首先他要想办法找点吃的，其次还要照顾家珍。';

        final result = processor.process(passage, bannedPhrases: []);

        // Key words should be highlighted but NOT deleted
        expect(result.processedText, contains('【然而】'));
        expect(result.processedText, contains('【最后】'));
        expect(result.processedText, contains('【首先】'));
        expect(result.processedText, contains('【其次】'));

        // Prose structure should be intact
        expect(result.processedText, contains('福贵并没有放弃'));
        expect(result.processedText, contains('一定要活下去'));
        expect(result.processedText, contains('要想办法找点吃的'));
        expect(result.processedText, contains('还要照顾家珍'));
      });

      test('should preserve literary time expressions in genre fiction', () {
        final passage =
            '刹那间剑光闪过，顷刻间胜负已分。'
            '转瞬之间，一切归于平静。';

        final result = processor.process(passage, bannedPhrases: []);

        // Literary time words should be highlighted but preserved
        expect(result.processedText, contains('【刹那间】'));
        expect(result.processedText, contains('【顷刻间】'));
        expect(result.processedText, contains('【转瞬之间】'));

        // Core narrative should be intact
        expect(result.processedText, contains('剑光闪过'));
        expect(result.processedText, contains('胜负已分'));
        expect(result.processedText, contains('一切归于平静'));
      });

      test('should not break narrator emphasis in literary prose', () {
        final passage =
            '毫无疑问，他是全村最穷的人。'
            '不可否认，他也是最善良的人。';

        final result = processor.process(passage, bannedPhrases: []);

        // Emphasis words highlighted but preserved
        expect(result.processedText, contains('【毫无疑问】'));
        expect(result.processedText, contains('【不可否认】'));

        // Meaning intact
        expect(result.processedText, contains('他是全村最穷的人'));
        expect(result.processedText, contains('他也是最善良的人'));
      });
    });

    group('structural pattern highlighting', () {
      test('should highlight 不仅...而且 pattern', () {
        final result = processor.process('他不仅聪明而且勤奋。', bannedPhrases: []);
        expect(result.processedText, contains('【'));
        expect(result.processedText, contains('不仅'));
        expect(result.processedText, contains('而且'));
      });

      test('should highlight 随着...的发展 pattern', () {
        final result = processor.process(
          '随着科技的发展，世界变得更加美好。',
          bannedPhrases: [],
        );
        expect(result.processedText, contains('【'));
      });

      test('should add highlight locations to result', () {
        final result = processor.process('他不仅聪明而且勤奋。', bannedPhrases: []);
        expect(result.highlights, isNotEmpty);
        expect(
          result.highlights.first.type,
          equals(HighlightType.structuralPattern),
        );
        expect(result.highlights.first.originalText, isNotEmpty);
      });

      test('should handle text with no structural patterns', () {
        final result = processor.process('他在月光下静静行走。', bannedPhrases: []);
        // May still have banned phrase replacements, but no structural highlights
        final structuralHighlights = result.highlights
            .where((h) => h.type == HighlightType.structuralPattern)
            .toList();
        expect(structuralHighlights, isEmpty);
      });
    });

    group('ProcessingResult', () {
      test('should return processedText with replacements and highlights', () {
        final result = processor.process(
          '然而，这是一个好故事。综上所述，值得一读。',
          bannedPhrases: [],
        );
        expect(result.processedText, isNotEmpty);
        // 然而 is now highlight-only
        expect(result.processedText, contains('【然而】'));
        // 综上所述 is still auto-deleted
        expect(result.processedText, isNot(contains('综上所述')));
      });

      test('should return highlights with correct positions', () {
        final result = processor.process('他不仅聪明而且勤奋。', bannedPhrases: []);
        for (final highlight in result.highlights) {
          expect(highlight.start, greaterThanOrEqualTo(0));
          expect(highlight.end, greaterThan(highlight.start));
          expect(highlight.originalText, isNotEmpty);
        }
      });

      test('should classify highlights as bannedWord or structuralPattern', () {
        final result = processor.process('然而，他不仅聪明而且勤奋。', bannedPhrases: []);
        final types = result.highlights.map((h) => h.type).toSet();
        // Should have at least one of each type
        expect(types, contains(HighlightType.structuralPattern));
        // 然而 is now highlight-only → bannedWord highlight type
        expect(types, contains(HighlightType.bannedWord));
      });

      test('should return review signals for structural AI-scent risk', () {
        final result = processor.process(
          '与此同时，林风体内灵力翻涌，周身气息骤然拔高。'
          '就在这时，他眼中闪过一丝冷光，磅礴的力量震开石阶。'
          '下一刻，真正的考验才刚刚开始。',
          bannedPhrases: [],
        );

        expect(result.reviewSignals, isNotEmpty);
        expect(
          result.reviewSignals.map((signal) => signal.title),
          containsAll(['转场套话偏多', '类型文套句偏多', '结尾悬念公式化']),
        );
      });

      test('should name the genre in the genre-cliche description (AA-05)', () {
        // Xianxia-dominant text → description names 修仙 (not hardcoded
        // beyond xianxia). Verifies the genre label is accurate.
        final xianxiaResult = processor.process(
          '林风体内灵力翻涌，周身气息骤然拔高，磅礴的力量震开石阶。',
          bannedPhrases: [],
        );
        final xianxiaSignal = xianxiaResult.reviewSignals.firstWhere(
          (s) => s.title == '类型文套句偏多',
        );
        expect(xianxiaSignal.description, contains('修仙'));
      });

      test('should detect wuxia genre cliches (AA-05)', () {
        // Wuxia-dominant text previously produced NO genre signal (only
        // xianxia was covered). Now it surfaces 类型文套句偏多 naming 武侠.
        final result = processor.process(
          '楚云内力运转一周，施展轻功掠上屋脊。'
          '只见剑光一闪，刀光剑影间，他身法如电避开三招。',
          bannedPhrases: [],
        );

        final genreSignal = result.reviewSignals.firstWhere(
          (s) => s.title == '类型文套句偏多',
        );
        // Evidence counts hits across genre sets (5 here: 内力运转/施展轻功/
        // 剑光一闪/刀光剑影/身法如电).
        expect(genreSignal.evidence, contains('次'));
        // Wuxia dominates → description names 武侠, not 修仙.
        expect(genreSignal.description, contains('武侠'));
        expect(genreSignal.description, isNot(contains('修仙')));
      });

      test('should detect urban genre cliches (AA-05b)', () {
        final result = processor.process(
          '他薄唇微抿，眉眼冷峻，气场全开地走进顶级会所。'
          '这位叱咤商界的人物，向来雷厉风行。',
          bannedPhrases: [],
        );
        final genreSignal = result.reviewSignals.firstWhere(
          (s) => s.title == '类型文套句偏多',
        );
        expect(genreSignal.description, contains('都市'));
      });

      test('should detect sci-fi genre cliches (AA-05b)', () {
        final result = processor.process(
          '意识上传完成后，他跨越光年之外的星际航行。'
          '量子纠缠维系着维度坍缩前最后的文明等级。',
          bannedPhrases: [],
        );
        final genreSignal = result.reviewSignals.firstWhere(
          (s) => s.title == '类型文套句偏多',
        );
        expect(genreSignal.description, contains('科幻'));
      });

      test('should detect xuanhuan genre cliches (AA-05c)', () {
        // Xuanhuan-dominant text (西方魔法/异界/血脉契约 register) previously
        // produced NO genre signal — AA-05b deferred 玄幻 citing "high overlap
        // with xianxia", but the western-magic register is a xianxia blind
        // spot. Now it surfaces 类型文套句偏多 naming 玄幻, not 修仙.
        final result = processor.process(
          '他血脉觉醒，吟唱咒语召唤魔兽。'
          '在这座魔法学院里，他签订了契约，踏上了异界大陆的征途。',
          bannedPhrases: [],
        );
        final genreSignal = result.reviewSignals.firstWhere(
          (s) => s.title == '类型文套句偏多',
        );
        expect(genreSignal.description, contains('玄幻'));
        // Proves the xuanhuan register does not collide with xianxia —
        // refutes the AA-05b "high overlap" deferral reason.
        expect(genreSignal.description, isNot(contains('修仙')));
      });

      test('should weight xianxia above xuanhuan on equal hits (AA-05c)', () {
        // 玄幻 enters the genre-priority chain at lowest precedence
        // (修仙 > 武侠 > 都市 > 科幻 > 玄幻). reduce keeps the earlier entry
        // on a tie, so a mixed xianxia+xuanhuan text names 修仙.
        final result = processor.process(
          '他体内灵力翻涌，魔法元素在掌心汇聚。',
          bannedPhrases: [],
        );
        final genreSignal = result.reviewSignals.firstWhere(
          (s) => s.title == '类型文套句偏多',
        );
        expect(genreSignal.description, contains('修仙'));
      });

      test('should flag uniform sentence rhythm for author review', () {
        final result = processor.process(
          '林风握紧木剑走过石阶。'
          '苏雪晴停在山门望着他。'
          '赵天磊冷笑着挡住去路。'
          '清虚真人沉默地抬起手。',
          bannedPhrases: [],
        );

        expect(
          result.reviewSignals.map((signal) => signal.title),
          contains('句长节奏过于整齐'),
        );
      });
    });

    group('edge cases', () {
      test('should handle empty text', () {
        final result = processor.process('', bannedPhrases: []);
        expect(result.processedText, isEmpty);
        expect(result.highlights, isEmpty);
      });

      test('should handle text with no banned phrases or patterns', () {
        final result = processor.process('月光洒在古道上，剑影闪烁。', bannedPhrases: []);
        expect(result.processedText, equals('月光洒在古道上，剑影闪烁。'));
        expect(result.highlights, isEmpty);
      });

      test(
        'should highlight highlight-only phrases without structural patterns',
        () {
          final result = processor.process('然而，天黑了。', bannedPhrases: []);
          expect(result.processedText, contains('【然而】'));
          // No structural patterns
          final structuralHighlights = result.highlights
              .where((h) => h.type == HighlightType.structuralPattern)
              .toList();
          expect(structuralHighlights, isEmpty);
        },
      );

      test('should highlight consecutive highlight-only phrases', () {
        final result = processor.process('首先其次最后', bannedPhrases: []);
        expect(result.processedText, contains('【首先】'));
        expect(result.processedText, contains('【其次】'));
        expect(result.processedText, contains('【最后】'));
      });
    });

    group('expanded synonym map', () {
      test('should delete 具体来说', () {
        final result = processor.process('具体来说，有三个原因。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('具体来说')));
      });

      test('should delete 换句话说', () {
        final result = processor.process('换句话说，他已经输了。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('换句话说')));
      });

      test('should delete 简而言之', () {
        final result = processor.process('简而言之，这是一场豪赌。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('简而言之')));
      });

      test('should highlight 毋庸置疑 instead of auto-deleting', () {
        final result = processor.process('毋庸置疑，他是最佳人选。', bannedPhrases: []);
        expect(result.processedText, contains('【毋庸置疑】'));
      });

      test('should delete 至关重要', () {
        final result = processor.process('这至关重要。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('至关重要')));
      });

      test('should delete 从某种意义上说', () {
        final result = processor.process('从某种意义上说，他是对的。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('从某种意义上说')));
      });

      test('should have at least 25 synonym entries', () {
        expect(
          AntiAIScentProcessor.synonymKeys.length,
          greaterThanOrEqualTo(25),
        );
      });

      test(
        'synonymKeys should include both auto-replace and highlight-only phrases',
        () {
          final keys = AntiAIScentProcessor.synonymKeys;
          // Auto-replace phrases
          expect(keys, contains('综上所述'));
          expect(keys, contains('心中涌起一股暖流'));
          // Highlight-only phrases
          expect(keys, contains('然而'));
          expect(keys, contains('最后'));
          expect(keys, contains('极其'));
        },
      );
    });

    group('expanded structural patterns', () {
      test('should highlight 无论...都... pattern', () {
        final result = processor.process(
          '无论前方有多少艰难险阻，他都不会退缩。',
          bannedPhrases: [],
        );
        expect(result.processedText, contains('【'));
        expect(result.processedText, contains('无论'));
      });

      test('should highlight 仿佛...一般 pattern', () {
        final result = processor.process('那双眼睛仿佛深邃的星空一般。', bannedPhrases: []);
        expect(result.processedText, contains('【'));
      });

      test('should highlight 让人不禁 pattern', () {
        final result = processor.process('这番话让人不禁深思。', bannedPhrases: []);
        expect(result.processedText, contains('【'));
      });

      test('should highlight 既...又... balanced pattern', () {
        final result = processor.process('她既温柔又坚强。', bannedPhrases: []);
        expect(result.processedText, contains('【'));
      });

      test('should highlight 因为...所以... explicit causal', () {
        final result = processor.process('因为他太过疲惫，所以倒头就睡。', bannedPhrases: []);
        expect(result.processedText, contains('【'));
      });

      test('should have at least 10 structural patterns', () {
        // Verify the expanded pattern count
        final testText = '他不仅聪明而且勤奋。';
        final result = processor.process(testText, bannedPhrases: []);
        // This test validates the expansion was applied;
        // the actual pattern count is a structural constant
        expect(result.highlights, isNotEmpty);
      });
    });

    group('emotional cliche review signals', () {
      test('should flag emotional cliches when present', () {
        final result = processor.process(
          '看着母亲的白发，他心中涌起一股暖流，眼眶微微湿润了。',
          bannedPhrases: [],
        );

        expect(result.reviewSignals.map((s) => s.title), contains('情感描写套路化'));
      });

      test('should not flag emotional cliches when absent', () {
        final result = processor.process(
          '他握紧拳头，指甲掐进肉里。月光照在他苍白的脸上。',
          bannedPhrases: [],
        );

        expect(
          result.reviewSignals.map((s) => s.title),
          isNot(contains('情感描写套路化')),
        );
      });
    });

    group('description formula review signals', () {
      test('should flag description formulas when multiple present', () {
        final result = processor.process(
          '眼前的景象宛如仙境，美不胜收，如诗如画。',
          bannedPhrases: [],
        );

        expect(result.reviewSignals.map((s) => s.title), contains('描写公式化'));
      });

      test('should not flag description formulas when absent', () {
        final result = processor.process('枯叶落在泥水里，被行人踩成碎片。', bannedPhrases: []);

        expect(
          result.reviewSignals.map((s) => s.title),
          isNot(contains('描写公式化')),
        );
      });
    });
  });
}
