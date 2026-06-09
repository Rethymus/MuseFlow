/// Tests for SentenceSegmenter Chinese sentence segmentation utility.
///
/// Validates splitting on Chinese sentence-ending punctuation (。！？…)
/// with proper handling of double ellipsis and quoted dialogue.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/sentence_segmenter.dart';

void main() {
  group('SentenceSegmenter.segment', () {
    test('should return empty list for empty text', () {
      expect(SentenceSegmenter.segment(''), isEmpty);
    });

    test('should return single sentence when no punctuation', () {
      expect(SentenceSegmenter.segment('没有标点'), ['没有标点']);
    });

    test('should split on Chinese period (。)', () {
      final result = SentenceSegmenter.segment('第一句。第二句。');
      expect(result, hasLength(2));
      expect(result[0], '第一句。');
      expect(result[1], '第二句。');
    });

    test('should split on exclamation mark (！)', () {
      final result = SentenceSegmenter.segment('太好了！真的吗？');
      expect(result, hasLength(2));
      expect(result[0], '太好了！');
      expect(result[1], '真的吗？');
    });

    test('should split on question mark (？)', () {
      final result = SentenceSegmenter.segment('你是谁？我是张三。');
      expect(result, hasLength(2));
      expect(result[0], '你是谁？');
      expect(result[1], '我是张三。');
    });

    test('should split on ellipsis (…)', () {
      final result = SentenceSegmenter.segment('然后呢…我不知道。');
      expect(result, hasLength(2));
      expect(result[0], '然后呢…');
      expect(result[1], '我不知道。');
    });

    test('should treat double ellipsis (……) as single boundary', () {
      final result = SentenceSegmenter.segment('然后呢……我不知道。');
      // …… is grouped as one punctuation unit and acts as a sentence boundary
      expect(result, hasLength(2));
      expect(result[0], '然后呢……');
      expect(result[1], '我不知道。');
    });

    test('should handle multiple sentence types together', () {
      final result = SentenceSegmenter.segment('你好。世界！真的吗？嗯……好吧。');
      // …… is grouped as one unit and acts as a sentence boundary
      expect(result, hasLength(5));
      expect(result[0], '你好。');
      expect(result[1], '世界！');
      expect(result[2], '真的吗？');
      expect(result[3], '嗯……');
      expect(result[4], '好吧。');
    });

    test('should preserve punctuation at end of each segment', () {
      final result = SentenceSegmenter.segment('一段话。');
      expect(result, ['一段话。']);
    });

    test('should handle text ending without punctuation', () {
      final result = SentenceSegmenter.segment('第一句。没有结尾');
      expect(result, hasLength(2));
      expect(result[0], '第一句。');
      expect(result[1], '没有结尾');
    });

    test('should handle single character sentences', () {
      final result = SentenceSegmenter.segment('好。');
      expect(result, ['好。']);
    });

    test('should handle text with only punctuation', () {
      final result = SentenceSegmenter.segment('。！');
      expect(result, hasLength(2));
      expect(result[0], '。');
      expect(result[1], '！');
    });

    test('should handle quoted dialogue correctly', () {
      final result = SentenceSegmenter.segment('"你好。"他说。');
      // The period inside quotes should still split -- the segmenter
      // splits on all sentence-ending punctuation regardless of quotes
      expect(result, hasLength(2));
    });

    test('should handle consecutive punctuation marks', () {
      final result = SentenceSegmenter.segment('哇！！！');
      expect(result, hasLength(1));
      expect(result[0], '哇！！！');
    });
  });
}
