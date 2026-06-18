import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/application/chapter_summary_staleness_checker.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';

void main() {
  const checker = ChapterSummaryStalenessChecker();

  ChapterSummary summary({required int sourceWordCount}) => ChapterSummary(
        id: 's1',
        chapterId: 'c1',
        manuscriptId: 'm1',
        summary: '概括',
        sourceWordCount: sourceWordCount,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

  group('ChapterSummaryStalenessChecker', () {
    test('fresh when chapter has not grown (current <= source)', () {
      expect(checker.isStale(summary(sourceWordCount: 100), 100), isFalse);
      expect(checker.isStale(summary(sourceWordCount: 100), 90), isFalse);
    });

    test('fresh when growth is below the absolute threshold', () {
      // source=1000, +30 chars: 30 < 50 absolute → fresh
      expect(checker.isStale(summary(sourceWordCount: 1000), 1030), isFalse);
    });

    test('fresh when growth meets absolute but not relative threshold', () {
      // source=2000, +300 chars: 300>=50 but 300 < 400 (20%) → fresh
      expect(checker.isStale(summary(sourceWordCount: 2000), 2300), isFalse);
    });

    test('stale when short chapter grew substantially', () {
      // source=100, +60 chars: 60>=50 && 60>=20 → stale
      expect(checker.isStale(summary(sourceWordCount: 100), 160), isTrue);
    });

    test('stale when long chapter grew past both thresholds', () {
      // source=2000, +500 chars: 500>=50 && 500>=400 → stale
      expect(checker.isStale(summary(sourceWordCount: 2000), 2500), isTrue);
    });

    test('boundary: growth just below absolute threshold stays fresh', () {
      // source=200, +49: 49 < 50 → fresh
      expect(checker.isStale(summary(sourceWordCount: 200), 249), isFalse);
    });
  });
}
