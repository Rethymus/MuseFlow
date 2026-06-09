import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/application/diff_calculator.dart';

void main() {
  group('DiffCalculator', () {
    test('should produce modification diffs for equal sentence counts', () {
      const original = '你好。世界。';
      const aiText = '您好。地球。';

      final result = DiffCalculator.calculate(original, aiText, 'node1', 0);

      expect(result.sentences, hasLength(2));
      expect(result.sentences[0].isModification, isTrue);
      expect(result.sentences[0].originalText, '你好。');
      expect(result.sentences[0].newText, '您好。');
      expect(result.sentences[1].isModification, isTrue);
      expect(result.sentences[1].originalText, '世界。');
      expect(result.sentences[1].newText, '地球。');
      // All should be pending
      expect(result.pendingCount, 2);
    });

    test('should produce insertion diffs when AI has more sentences', () {
      const original = '你好。';
      const aiText = '你好。世界。';

      final result = DiffCalculator.calculate(original, aiText, 'node1', 0);

      expect(result.sentences, hasLength(1));
      expect(result.sentences[0].isInsertion, isTrue);
      expect(result.sentences[0].originalText, isNull);
      expect(result.sentences[0].newText, '世界。');
      expect(result.sentences[0].startOffset, 3);
      expect(result.sentences[0].endOffset, 3);
    });

    test('should produce deletion diffs when AI has fewer sentences', () {
      const original = '你好。世界。';
      const aiText = '你好。';

      final result = DiffCalculator.calculate(original, aiText, 'node1', 0);

      expect(result.sentences, hasLength(1));
      expect(result.sentences[0].isDeletion, isTrue);
      expect(result.sentences[0].originalText, '世界。');
      expect(result.sentences[0].newText, isNull);
      expect(result.sentences[0].startOffset, 3);
      expect(result.sentences[0].endOffset, 6);
    });

    test('should align inserted sentence without cascading modifications', () {
      const original = '林风推开门。苏雪晴站在院中。赵天磊没有说话。';
      const aiText = '林风推开门。雨声从檐角落下。苏雪晴站在院中。赵天磊没有说话。';

      final result = DiffCalculator.calculate(original, aiText, 'node1', 0);

      expect(result.sentences, hasLength(1));
      expect(result.sentences.single.isInsertion, isTrue);
      expect(result.sentences.single.newText, '雨声从檐角落下。');
      expect(result.sentences.single.startOffset, '林风推开门。'.length);
      expect(result.sentences.single.endOffset, '林风推开门。'.length);
    });

    test('should align deleted sentence without cascading modifications', () {
      const original = '林风推开门。雨声从檐角落下。苏雪晴站在院中。';
      const aiText = '林风推开门。苏雪晴站在院中。';

      final result = DiffCalculator.calculate(original, aiText, 'node1', 0);

      expect(result.sentences, hasLength(1));
      expect(result.sentences.single.isDeletion, isTrue);
      expect(result.sentences.single.originalText, '雨声从檐角落下。');
    });

    test('should produce no diffs when AI keeps all sentences unchanged', () {
      const text = '林风推开门。苏雪晴站在院中。';

      final result = DiffCalculator.calculate(text, text, 'node1', 0);

      expect(result.sentences, isEmpty);
    });

    test('should keep unrelated replacement as a single modification', () {
      const original = '林风推开门。';
      const aiText = '夜色压在屋檐上。';

      final result = DiffCalculator.calculate(original, aiText, 'node1', 0);

      expect(result.sentences, hasLength(1));
      expect(result.sentences.single.isModification, isTrue);
      expect(result.sentences.single.originalText, original);
      expect(result.sentences.single.newText, aiText);
    });

    test('should set nodeId on all sentences', () {
      final result = DiffCalculator.calculate('A。', 'B。', 'myNode', 0);
      expect(result.sentences[0].nodeId, 'myNode');
      expect(result.nodeId, 'myNode');
    });

    test('should calculate offsets from startOffset', () {
      final result = DiffCalculator.calculate('你好。世界。', '您好。地球。', 'n1', 10);
      expect(result.sentences[0].startOffset, 10);
      expect(result.sentences[0].endOffset, 13); // 10 + len('你好。')
      expect(result.sentences[1].startOffset, 13);
      expect(result.sentences[1].endOffset, 16); // 13 + len('世界。')
    });

    test('should handle empty original text', () {
      final result = DiffCalculator.calculate('', '新文。', 'n1', 0);
      expect(result.sentences, hasLength(1));
      expect(result.sentences[0].isInsertion, isTrue);
    });

    test('should handle empty AI text', () {
      final result = DiffCalculator.calculate('原文。', '', 'n1', 0);
      expect(result.sentences, hasLength(1));
      expect(result.sentences[0].isDeletion, isTrue);
    });
  });
}
