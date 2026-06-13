/// Tests for EditorialReview domain model + tolerant JSON parser.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/domain/editorial_review.dart';

void main() {
  group('EditorialReview.parseFromLLM', () {
    const cleanJson = '''
{"dimensions":[
  {"dimension":"情节","score":80,"strengths":"伏笔清晰","weaknesses":"转折略快","suggestions":"放缓高潮"},
  {"dimension":"人物","score":75,"strengths":"动机合理","weaknesses":"配角扁平","suggestions":"补背景"},
  {"dimension":"文笔","score":82,"strengths":"描写细腻","weaknesses":"偶有堆砌","suggestions":"删形容词"},
  {"dimension":"节奏","score":70,"strengths":"张弛有度","weaknesses":"中段拖沓","suggestions":"删冗余"}
]}''';

    test('parses clean JSON into 4 dimensions with scores', () {
      final review = EditorialReview.parseFromLLM(cleanJson);
      expect(review.isDegraded, isFalse);
      expect(review.dimensions, hasLength(4));
      expect(review.dimensions[0].dimension, ReviewDimension.plot);
      expect(review.dimensions[0].score, 80);
      expect(review.dimensions[0].strengths, '伏笔清晰');
      expect(review.dimensions[2].dimension, ReviewDimension.prose);
      expect(review.dimensions[2].score, 82);
      expect(review.overallScore, closeTo(76.75, 0.5));
    });

    test('parses JSON wrapped in ```json fences', () {
      final fenced = '```json\n$cleanJson\n```';
      final review = EditorialReview.parseFromLLM(fenced);
      expect(review.isDegraded, isFalse);
      expect(review.dimensions, hasLength(4));
    });

    test('parses JSON with trailing prose after the object', () {
      final trailing = '$cleanJson\n\n以上是本次评审，仅供参考。';
      final review = EditorialReview.parseFromLLM(trailing);
      expect(review.isDegraded, isFalse);
      expect(review.dimensions, hasLength(4));
    });

    test('returns degraded review (non-throwing) for malformed output', () {
      const malformed = '这不是 JSON，模型拒绝了结构化输出。';
      final review = EditorialReview.parseFromLLM(malformed);
      expect(review.isDegraded, isTrue);
      expect(review.dimensions, isEmpty);
      expect(review.degradedReason, isNotNull);
    });

    test('tolerates partial dimension arrays (drops invalid items)', () {
      const partial = '''{"dimensions":[
  {"dimension":"情节","score":80,"strengths":"a","weaknesses":"b","suggestions":"c"},
  {"dimension":"未知维度","score":50,"strengths":"x","weaknesses":"y","suggestions":"z"},
  {"dimension":"文笔","score":70,"strengths":"d","weaknesses":"e","suggestions":"f"}
]}''';
      final review = EditorialReview.parseFromLLM(partial);
      expect(review.isDegraded, isFalse);
      expect(review.dimensions, hasLength(2));
      expect(
        review.dimensions.map((d) => d.dimension).toList(),
        [ReviewDimension.plot, ReviewDimension.prose],
      );
    });

    test('clamps out-of-range scores into 0-100', () {
      const oob = '''{"dimensions":[
  {"dimension":"情节","score":150,"strengths":"a","weaknesses":"b","suggestions":"c"},
  {"dimension":"节奏","score":-20,"strengths":"d","weaknesses":"e","suggestions":"f"}
]}''';
      final review = EditorialReview.parseFromLLM(oob);
      expect(review.dimensions[0].score, 100);
      expect(review.dimensions[1].score, 0);
    });
  });

  group('ReviewDimension', () {
    test('matches by Chinese label and by enum name', () {
      expect(ReviewDimension.fromName('情节'), ReviewDimension.plot);
      expect(ReviewDimension.fromName('plot'), ReviewDimension.plot);
      expect(ReviewDimension.fromName('人物'), ReviewDimension.character);
      expect(ReviewDimension.fromName('文笔'), ReviewDimension.prose);
      expect(ReviewDimension.fromName('节奏'), ReviewDimension.pacing);
      expect(ReviewDimension.fromName('未知'), isNull);
    });
  });

  group('DimensionReview immutability', () {
    test('copyWith produces a new instance with overridden fields', () {
      final original = DimensionReview(
        dimension: ReviewDimension.plot,
        score: 80,
        strengths: 'a',
        weaknesses: 'b',
        suggestions: 'c',
      );
      final copy = original.copyWith(score: 90);
      expect(copy.score, 90);
      expect(copy.dimension, ReviewDimension.plot);
      expect(identical(copy, original), isFalse);
    });
  });
}
