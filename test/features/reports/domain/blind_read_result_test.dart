import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/domain/blind_read_result.dart';

void main() {
  group('BlindReadExcerpt', () {
    test('should hold all fields with humanVerdict null by default', () {
      const excerpt = BlindReadExcerpt(
        text: 'Sample paragraph text for testing.',
        chapterId: 'chapter-1',
        chapterIndex: 1,
      );

      expect(excerpt.text, 'Sample paragraph text for testing.');
      expect(excerpt.chapterId, 'chapter-1');
      expect(excerpt.chapterIndex, 1);
      expect(excerpt.humanVerdict, isNull);
    });

    test('should support copyWith to set verdict', () {
      const excerpt = BlindReadExcerpt(
        text: 'text',
        chapterId: 'ch-1',
        chapterIndex: 1,
      );

      final judged = excerpt.copyWith(humanVerdict: true);
      expect(judged.humanVerdict, true);
      expect(judged.text, 'text'); // unchanged
    });

    test('should support equality', () {
      const excerpt1 = BlindReadExcerpt(
        text: 'text',
        chapterId: 'ch-1',
        chapterIndex: 1,
      );
      const excerpt2 = BlindReadExcerpt(
        text: 'text',
        chapterId: 'ch-1',
        chapterIndex: 1,
      );

      expect(excerpt1, equals(excerpt2));
    });
  });

  group('BlindReadResult', () {
    test('should compute score from totalJudged and correctCount', () {
      final result = BlindReadResult(
        excerpts: [
          const BlindReadExcerpt(
            text: 't1',
            chapterId: 'ch-1',
            chapterIndex: 1,
            humanVerdict: true,
          ),
          const BlindReadExcerpt(
            text: 't2',
            chapterId: 'ch-2',
            chapterIndex: 2,
            humanVerdict: false,
          ),
          const BlindReadExcerpt(
            text: 't3',
            chapterId: 'ch-3',
            chapterIndex: 3,
            humanVerdict: true,
          ),
          const BlindReadExcerpt(
            text: 't4',
            chapterId: 'ch-4',
            chapterIndex: 4,
          ), // not judged
        ],
        correctCount: 2,
      );

      expect(result.excerpts.length, 4);
      expect(result.totalJudged, 3);
      expect(result.correctCount, 2);
      expect(result.score, closeTo(0.6667, 0.01));
    });

    test('should return 0 score when no excerpts judged', () {
      final result = BlindReadResult(
        excerpts: const [
          BlindReadExcerpt(
            text: 't1',
            chapterId: 'ch-1',
            chapterIndex: 1,
          ),
        ],
        correctCount: 0,
      );

      expect(result.totalJudged, 0);
      expect(result.score, 0.0);
    });

    test('should support copyWith', () {
      final result = BlindReadResult(
        excerpts: const [],
        correctCount: 0,
      );

      final updated = result.copyWith(correctCount: 5);
      expect(updated.correctCount, 5);
    });
  });
}
