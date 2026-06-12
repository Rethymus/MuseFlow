/// Tests for FuzzyMatcher — Damerau-Levenshtein distance based fuzzy matching.
///
/// Validates Phase 20 (KNOW-01): fuzzy matching with edit distance ≤ 2.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/infrastructure/fuzzy_matcher.dart';

void main() {
  group('FuzzyMatcher', () {
    const matcher = FuzzyMatcher(maxDistance: 2);

    // --- distance ---

    group('distance', () {
      test('identical strings should return 0', () {
        expect(matcher.distance('林风', '林风'), 0);
      });

      test('single character substitution should return 1', () {
        expect(matcher.distance('林风', '林锋'), 1);
      });

      test('single character insertion should return 1', () {
        expect(matcher.distance('林风', '林大风'), 1);
      });

      test('single character deletion should return 1', () {
        expect(matcher.distance('林大风', '林风'), 1);
      });

      test('transposition of adjacent characters should return 1', () {
        expect(matcher.distance('风林', '林风'), 1);
      });

      test('single substitution in 3-char string should return 1', () {
        expect(matcher.distance('林风云', '林锋云'), 1);
      });

      test('two substitutions should return 2', () {
        expect(matcher.distance('林风云雷', '王刚云雷'), 2);
      });

      test('three substitutions should return 3', () {
        expect(matcher.distance('林风云雷', '王刚光雷'), 3);
      });

      test('two-char completely different strings should return 2', () {
        expect(matcher.distance('张三', '李四'), 2);
      });

      test('empty strings should return 0', () {
        expect(matcher.distance('', ''), 0);
      });

      test('empty to non-empty should return length', () {
        expect(matcher.distance('', '林风'), 2);
      });

      test('non-empty to empty should return length', () {
        expect(matcher.distance('林风', ''), 2);
      });

      test('should handle multi-byte Unicode correctly', () {
        expect(matcher.distance('小明', '小刚'), 1);
        expect(matcher.distance('欧阳锋', '欧阳峰'), 1);
      });
    });

    // --- isMatch ---

    group('isMatch', () {
      test('should match identical strings', () {
        expect(matcher.isMatch('林风', '林风'), true);
      });

      test('should match with 1 edit', () {
        expect(matcher.isMatch('林风', '林锋'), true);
      });

      test('should match with 2 edits', () {
        expect(matcher.isMatch('林风云雷', '王刚云雷'), true);
      });

      test('should not match with 3 edits', () {
        expect(matcher.isMatch('林风云雷', '王刚光雷'), false);
      });

      test('should not match very different strings', () {
        expect(matcher.isMatch('张三丰', '李四光'), false);
      });
    });

    // --- findFuzzyMatches ---

    group('findFuzzyMatches', () {
      test('should find exact matches', () {
        final results = matcher.findFuzzyMatches(
          text: '林风站在山门前',
          candidates: ['林风', '张三', '李四'],
        );
        expect(results, isNotEmpty);
        expect(results.first.candidate, '林风');
        expect(results.first.distance, 0);
      });

      test('should find fuzzy matches within max distance', () {
        final results = matcher.findFuzzyMatches(
          text: '林锋站在山门前',
          candidates: ['林风', '张三', '李四'],
        );
        expect(results, isNotEmpty);
        expect(results.first.candidate, '林风');
        expect(results.first.distance, 1);
      });

      test('should not find matches exceeding max distance', () {
        final results = matcher.findFuzzyMatches(
          text: '王刚站在山门前',
          candidates: ['林风', '张三', '李四'],
        );
        expect(results, isEmpty);
      });

      test('should return one best result per position+candidate', () {
        final results = matcher.findFuzzyMatches(
          text: '林锋和张峰站在山门前',
          candidates: ['林风', '张峰'],
        );
        // 林锋→林风 at pos 0, 张峰→张峰 at pos 3 — one result each
        expect(results.length, 2);
        expect(results.any((r) => r.candidate == '林风' && r.distance == 1), true);
        expect(results.any((r) => r.candidate == '张峰' && r.distance == 0), true);
      });

      test('should handle empty text', () {
        final results = matcher.findFuzzyMatches(
          text: '',
          candidates: ['林风', '张三'],
        );
        expect(results, isEmpty);
      });

      test('should handle empty candidates', () {
        final results = matcher.findFuzzyMatches(
          text: '林风站在山门前',
          candidates: [],
        );
        expect(results, isEmpty);
      });

      test('should respect custom max distance', () {
        const strictMatcher = FuzzyMatcher(maxDistance: 1);
        final results = strictMatcher.findFuzzyMatches(
          text: '王刚站在山门前',
          candidates: ['林风'],
        );
        // 王刚 vs 林风 = distance 2 > maxDistance 1
        expect(results, isEmpty);
      });
    });

    // --- findBestMatch ---

    group('findBestMatch', () {
      test('should return best match for a name', () {
        final result = matcher.findBestMatch(
          query: '林锋',
          candidates: ['林风', '张三', '李四'],
        );
        expect(result, isNotNull);
        expect(result!.candidate, '林风');
        expect(result.distance, 1);
      });

      test('should return null when no match found', () {
        final result = matcher.findBestMatch(
          query: '王刚',
          candidates: ['林风', '张三', '李四'],
        );
        expect(result, isNull);
      });

      test('should return exact match with distance 0', () {
        final result = matcher.findBestMatch(
          query: '林风',
          candidates: ['林风', '张三'],
        );
        expect(result, isNotNull);
        expect(result!.candidate, '林风');
        expect(result.distance, 0);
      });
    });
  });
}
