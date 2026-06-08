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

      expect(result.sentences, hasLength(2));
      expect(result.sentences[0].isModification, isTrue);
      expect(result.sentences[0].originalText, '你好。');
      expect(result.sentences[0].newText, '你好。');
      expect(result.sentences[1].isInsertion, isTrue);
      expect(result.sentences[1].originalText, isNull);
      expect(result.sentences[1].newText, '世界。');
    });

    test('should produce deletion diffs when AI has fewer sentences', () {
      const original = '你好。世界。';
      const aiText = '你好。';

      final result = DiffCalculator.calculate(original, aiText, 'node1', 0);

      expect(result.sentences, hasLength(2));
      expect(result.sentences[0].isModification, isTrue);
      expect(result.sentences[1].isDeletion, isTrue);
      expect(result.sentences[1].originalText, '世界。');
      expect(result.sentences[1].newText, isNull);
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
