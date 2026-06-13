/// Tests for AliasExtractor — automatic alias extraction from character descriptions.
///
/// Validates Phase 20 (KNOW-01): auto-extract nicknames/aliases from
/// character personality, appearance, and backstory text.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/infrastructure/alias_extractor.dart';

void main() {
  group('AliasExtractor', () {
    final extractor = AliasExtractor();

    // --- Common patterns ---

    group('common patterns', () {
      test('should extract 小+surname pattern', () {
        final aliases = extractor.extract(
          name: '林风',
          description: '大家都叫他小林，他是村里最年轻的人。',
        );
        expect(aliases, contains('小林'));
      });

      test('should extract 小+given_name pattern', () {
        final aliases = extractor.extract(
          name: '林风',
          description: '风儿从小就喜欢练剑，村里人都叫他小风。',
        );
        expect(aliases, contains('小风'));
      });

      test('should extract 儿 suffix pattern', () {
        final aliases = extractor.extract(name: '林风', description: '风儿站在山门前。');
        expect(aliases, contains('风儿'));
      });

      test('should extract 阿+given_name pattern', () {
        final aliases = extractor.extract(name: '陈云', description: '阿云是村长的女儿。');
        expect(aliases, contains('阿云'));
      });

      test('should extract 老+surname pattern', () {
        final aliases = extractor.extract(
          name: '王师傅',
          description: '老王是镇上有名的铁匠。',
        );
        expect(aliases, contains('老王'));
      });
    });

    // --- Title-based aliases ---

    group('title-based aliases', () {
      test('should extract common title + surname pattern', () {
        final aliases = extractor.extract(
          name: '李明',
          description: '李掌柜在镇上开了三十年的店铺。',
        );
        expect(aliases, contains('李掌柜'));
      });

      test('should extract title patterns from description', () {
        final aliases = extractor.extract(
          name: '张三',
          description: '张师兄武功高强，大家都敬佩他。',
        );
        expect(aliases, contains('张师兄'));
      });
    });

    // --- Deduplication ---

    group('deduplication', () {
      test('should not include the original name', () {
        final aliases = extractor.extract(name: '林风', description: '林风站在山门前。');
        expect(aliases, isNot(contains('林风')));
      });

      test('should not duplicate aliases found in multiple fields', () {
        final aliases = extractor.extract(
          name: '林风',
          description: '大家都叫他小风。',
          extraText: '小风从小就很聪明。',
        );
        expect(aliases.where((a) => a == '小风').length, 1);
      });

      test('should not include existing aliases', () {
        final aliases = extractor.extract(
          name: '林风',
          description: '大家叫他小风。',
          existingAliases: ['小风'],
        );
        expect(aliases, isNot(contains('小风')));
      });
    });

    // --- Filtering ---

    group('filtering', () {
      test('should exclude aliases shorter than 2 characters', () {
        final aliases = extractor.extract(name: '林风', description: '他叫做风。');
        // '风' is only 1 char, should be excluded
        expect(aliases, isNot(contains('风')));
      });

      test('should exclude aliases longer than 6 characters', () {
        final aliases = extractor.extract(
          name: '林风',
          description: '他被称为一个非常非常厉害的人。',
        );
        // No valid alias pattern here
        expect(aliases, isEmpty);
      });

      test('should return empty for text without patterns', () {
        final aliases = extractor.extract(
          name: '林风',
          description: '他是一个普通的年轻人。',
        );
        expect(aliases, isEmpty);
      });

      test('should handle empty description', () {
        final aliases = extractor.extract(name: '林风', description: '');
        expect(aliases, isEmpty);
      });
    });

    // --- Multi-source extraction ---

    group('multi-source', () {
      test('should extract from personality, appearance, and backstory', () {
        final aliases = extractor.extract(
          name: '陈云',
          personality: '阿云性格温和',
          appearance: '大家都叫她云儿',
          backstory: '小陈从小就住在山上',
        );
        expect(aliases, contains('阿云'));
        expect(aliases, contains('云儿'));
        expect(aliases, contains('小陈'));
      });
    });
  });
}
