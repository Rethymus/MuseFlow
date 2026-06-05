import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/writing_unit_counter.dart';

void main() {
  group('countWritingUnits', () {
    test('counts Chinese characters and ignores punctuation', () {
      expect(countWritingUnits('月光下，他走了。'), 6);
    });

    test('counts contiguous English words as tokens', () {
      expect(countWritingUnits('The old city sleeps'), 4);
    });

    test('counts mixed Chinese and English text', () {
      expect(countWritingUnits('她打开AI notebook 2026版'), 7);
    });

    test('returns zero for empty whitespace and punctuation', () {
      expect(countWritingUnits(''), 0);
      expect(countWritingUnits('   \n\t'), 0);
      expect(countWritingUnits('，。！？...'), 0);
    });
  });
}
