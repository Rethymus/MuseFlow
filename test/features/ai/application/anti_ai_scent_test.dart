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
  });
}
