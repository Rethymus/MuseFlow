/// Tests for [KbStalenessChecker] — MC-01 dynamic knowledge-base staleness.
///
/// Validates staleness detection for knowledge-base entries: an entry verified
/// N chapters ago is fresh (< 10), stale (>= 10), or very stale (>= 20), per
/// MC-01 (NAACL 2025 DOME temporal conflict analysis; research roadmap). Legacy
/// entries with no tracked verification chapter are treated as fresh (unknown,
/// not nagged) to avoid false positives on migration.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/application/kb_staleness_checker.dart';

void main() {
  const checker = KbStalenessChecker();

  group('KbStalenessChecker MC-01 staleness levels', () {
    test('legacy entry (null lastVerifiedChapter) is fresh, not nagged', () {
      final result = checker.check(null, 50);
      expect(result.level, KbStalenessLevel.fresh);
      expect(result.chaptersSinceVerified, isNull);
    });

    test('just verified (since 0) is fresh', () {
      final result = checker.check(30, 30);
      expect(result.level, KbStalenessLevel.fresh);
      expect(result.chaptersSinceVerified, 0);
    });

    test('9 chapters since verified is still fresh (below threshold)', () {
      final result = checker.check(21, 30);
      expect(result.level, KbStalenessLevel.fresh);
      expect(result.chaptersSinceVerified, 9);
    });

    test('exactly 10 chapters since verified is stale (boundary)', () {
      final result = checker.check(20, 30);
      expect(result.level, KbStalenessLevel.stale);
      expect(result.chaptersSinceVerified, 10);
    });

    test('15 chapters since verified is stale', () {
      final result = checker.check(15, 30);
      expect(result.level, KbStalenessLevel.stale);
      expect(result.chaptersSinceVerified, 15);
    });

    test('exactly 20 chapters since verified is veryStale (boundary)', () {
      final result = checker.check(10, 30);
      expect(result.level, KbStalenessLevel.veryStale);
      expect(result.chaptersSinceVerified, 20);
    });

    test('50 chapters since verified is veryStale', () {
      final result = checker.check(5, 55);
      expect(result.level, KbStalenessLevel.veryStale);
      expect(result.chaptersSinceVerified, 50);
    });

    test('currentChapterCount below lastVerifiedChapter clamps to fresh', () {
      // Defensive: if the stored verified-chapter is somehow ahead of the
      // current count (data corruption / rollback), treat as fresh (since 0),
      // never negative.
      final result = checker.check(40, 30);
      expect(result.level, KbStalenessLevel.fresh);
      expect(result.chaptersSinceVerified, 0);
    });
  });

  group('KbStalenessResult message', () {
    test('fresh result has a non-empty message', () {
      expect(checker.check(30, 30).message, isNotEmpty);
    });

    test('stale result message mentions staleness', () {
      final msg = checker.check(20, 30).message;
      expect(
        msg,
        anyOf(contains('过期'), contains('陈旧'), contains('更新'), contains('提醒')),
      );
    });

    test('veryStale result message is more urgent than stale', () {
      final staleMsg = checker.check(20, 30).message;
      final veryStaleMsg = checker.check(5, 30).message;
      expect(veryStaleMsg.length, greaterThanOrEqualTo(staleMsg.length));
      expect(veryStaleMsg, isNot(equals(staleMsg)));
    });
  });

  group('KbStalenessChecker thresholds are documented constants', () {
    test('staleThreshold is 10 per MC-01 spec', () {
      expect(KbStalenessChecker.staleThreshold, 10);
    });

    test('veryStaleThreshold is 20', () {
      expect(KbStalenessChecker.veryStaleThreshold, 20);
    });
  });
}
