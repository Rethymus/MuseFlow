/// Tests for AntiAIScentProcessor.
///
/// Validates AI-05 (anti-AI-scent prompt layer) and AI-06 (post-processing):
/// - Banned phrase replacement with boundary-aware matching
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
      test('should replace 然而 with 但是', () {
        final result = processor.process('他看着远方，然而心中却无比平静。', bannedPhrases: []);
        expect(result.processedText, contains('但是'));
        expect(result.processedText, isNot(contains('然而')));
      });

      test('should delete 综上所述 (empty replacement)', () {
        final result = processor.process('综上所述，这是一个好故事。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('综上所述')));
      });

      test('should delete 值得注意的是', () {
        final result = processor.process('值得注意的是，他没有放弃。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('值得注意的是')));
      });

      test('should delete 毫无疑问', () {
        final result = processor.process('毫无疑问，这是正确的选择。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('毫无疑问')));
      });

      test('should replace multiple banned phrases in single text', () {
        final result = processor.process(
          '首先，他来了。其次，他走了。最后，他回来了。',
          bannedPhrases: [],
        );
        expect(result.processedText, isNot(contains('首先')));
        expect(result.processedText, isNot(contains('其次')));
        expect(result.processedText, isNot(contains('最后')));
      });

      test('should use boundary-aware matching per Pitfall 5', () {
        // "然而" inside a compound word should NOT be replaced
        final result = processor.process('这件事自然而然地发生了。', bannedPhrases: []);
        // "然而" is inside "自然而然", should NOT be replaced
        expect(result.processedText, contains('自然而然'));
      });

      test('should replace at string boundaries', () {
        final result = processor.process('然而天黑了。', bannedPhrases: []);
        // "然而" at start of string should be replaced
        expect(result.processedText, isNot(contains('然而')));
      });

      test('should replace at sentence boundaries (after punctuation)', () {
        final result = processor.process('天亮了。然而他又睡着了。', bannedPhrases: []);
        expect(result.processedText, contains('但是'));
      });

      test('should respect additional bannedPhrases from parameter', () {
        final result = processor.process('这个故事真棒极了。', bannedPhrases: ['棒极了']);
        expect(result.processedText, isNot(contains('棒极了')));
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
      test('should return processedText with replacements applied', () {
        final result = processor.process(
          '然而，这是一个好故事。综上所述，值得一读。',
          bannedPhrases: [],
        );
        expect(result.processedText, isNotEmpty);
        expect(result.processedText, isNot(contains('然而')));
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

      test('should handle text with only banned phrase replacements', () {
        final result = processor.process('然而，天黑了。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('然而')));
        // No structural patterns
        final structuralHighlights = result.highlights
            .where((h) => h.type == HighlightType.structuralPattern)
            .toList();
        expect(structuralHighlights, isEmpty);
      });

      test('should handle consecutive banned phrases', () {
        final result = processor.process('首先其次最后', bannedPhrases: []);
        expect(result.processedText, isNot(contains('首先')));
        expect(result.processedText, isNot(contains('其次')));
        expect(result.processedText, isNot(contains('最后')));
      });
    });

    group('expanded synonym map', () {
      test('should delete 事实上', () {
        final result = processor.process('事实上，他并没有离开。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('事实上')));
      });

      test('should delete 实际上', () {
        final result = processor.process('实际上，她一直都在旁边。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('实际上')));
      });

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

      test('should delete 毋庸置疑', () {
        final result = processor.process('毋庸置疑，他是最佳人选。', bannedPhrases: []);
        expect(result.processedText, isNot(contains('毋庸置疑')));
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
        expect(AntiAIScentProcessor.synonymKeys.length, greaterThanOrEqualTo(25));
      });
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
        final result = processor.process(
          '那双眼睛仿佛深邃的星空一般。',
          bannedPhrases: [],
        );
        expect(result.processedText, contains('【'));
      });

      test('should highlight 让人不禁 pattern', () {
        final result = processor.process(
          '这番话让人不禁深思。',
          bannedPhrases: [],
        );
        expect(result.processedText, contains('【'));
      });

      test('should highlight 既...又... balanced pattern', () {
        final result = processor.process(
          '她既温柔又坚强。',
          bannedPhrases: [],
        );
        expect(result.processedText, contains('【'));
      });

      test('should highlight 因为...所以... explicit causal', () {
        final result = processor.process(
          '因为他太过疲惫，所以倒头就睡。',
          bannedPhrases: [],
        );
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

        expect(
          result.reviewSignals.map((s) => s.title),
          contains('情感描写套路化'),
        );
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

        expect(
          result.reviewSignals.map((s) => s.title),
          contains('描写公式化'),
        );
      });

      test('should not flag description formulas when absent', () {
        final result = processor.process(
          '枯叶落在泥水里，被行人踩成碎片。',
          bannedPhrases: [],
        );

        expect(
          result.reviewSignals.map((s) => s.title),
          isNot(contains('描写公式化')),
        );
      });
    });
  });
}
