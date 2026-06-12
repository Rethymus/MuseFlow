/// Tests for PronounResolver — coreference resolution for Chinese pronouns.
///
/// Validates Phase 20 (KNOW-01): map 他/她/它 to recently mentioned
/// characters in context.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/infrastructure/pronoun_resolver.dart';

void main() {
  group('PronounResolver', () {
    final resolver = PronounResolver();

    // --- Gender resolution ---

    group('gender resolution', () {
      test('should resolve 他 to most recent male character', () {
        final result = resolver.resolvePronoun(
          pronoun: '他',
          text: '林风走到张三面前，他对张三说',
          characters: {'林风': Gender.male, '张三': Gender.male},
        );
        expect(result, isNotNull);
        expect(result!.entityId, '张三');
      });

      test('should resolve 她 to most recent female character', () {
        final result = resolver.resolvePronoun(
          pronoun: '她',
          text: '林风和李雪走在路上，她对林风微笑',
          characters: {'林风': Gender.male, '李雪': Gender.female},
        );
        expect(result, isNotNull);
        expect(result!.entityId, '李雪');
      });

      test('should return null when gender does not match any character', () {
        final result = resolver.resolvePronoun(
          pronoun: '她',
          text: '林风和张三走在路上，他对张三说',
          characters: {'林风': Gender.male, '张三': Gender.male},
        );
        expect(result, isNull);
      });
    });

    // --- Recency ---

    group('recency', () {
      test('should prefer more recently mentioned character', () {
        final result = resolver.resolvePronoun(
          pronoun: '他',
          text: '张三走在路上，林风追了上来，他对张三说',
          characters: {'林风': Gender.male, '张三': Gender.male},
        );
        // 林风 mentioned more recently before 他
        expect(result, isNotNull);
        expect(result!.entityId, '林风');
      });

      test('should resolve based on closest preceding mention', () {
        final result = resolver.resolvePronoun(
          pronoun: '他',
          text: '林风走在路上。忽然张三出现了。他大声喊道',
          characters: {'林风': Gender.male, '张三': Gender.male},
        );
        // 张三 is mentioned immediately before 他
        expect(result, isNotNull);
        expect(result!.entityId, '张三');
      });
    });

    // --- Unknown gender ---

    group('unknown gender', () {
      test('should resolve 他/她 to unknown-gender characters when no match', () {
        final result = resolver.resolvePronoun(
          pronoun: '他',
          text: '小明走过来，他向大家打招呼',
          characters: {'小明': Gender.unknown},
        );
        expect(result, isNotNull);
        expect(result!.entityId, '小明');
      });

      test('should prefer gender match over unknown gender', () {
        final result = resolver.resolvePronoun(
          pronoun: '她',
          text: '李雪和小明走在一起，她微笑着说',
          characters: {'李雪': Gender.female, '小明': Gender.unknown},
        );
        expect(result, isNotNull);
        expect(result!.entityId, '李雪');
      });
    });

    // --- Pronouns ---

    group('pronoun types', () {
      test('should resolve multiple 他 in same text', () {
        final result1 = resolver.resolvePronoun(
          pronoun: '他',
          pronounIndex: 10,
          text: '林风走到张三面前，他对张三说，张三也对他点头',
          characters: {'林风': Gender.male, '张三': Gender.male},
        );
        expect(result1, isNotNull);

        final result2 = resolver.resolvePronoun(
          pronoun: '他',
          pronounIndex: 18,
          text: '林风走到张三面前，他对张三说，张三也对他点头',
          characters: {'林风': Gender.male, '张三': Gender.male},
        );
        expect(result2, isNotNull);
      });
    });

    // --- Edge cases ---

    group('edge cases', () {
      test('should return null for empty text', () {
        final result = resolver.resolvePronoun(
          pronoun: '他',
          text: '',
          characters: {'林风': Gender.male},
        );
        expect(result, isNull);
      });

      test('should return null for empty characters', () {
        final result = resolver.resolvePronoun(
          pronoun: '他',
          text: '他走到门前',
          characters: {},
        );
        expect(result, isNull);
      });

      test('should return null for unrecognized pronoun', () {
        final result = resolver.resolvePronoun(
          pronoun: '这',
          text: '这是谁',
          characters: {'林风': Gender.male},
        );
        expect(result, isNull);
      });

      test('should return null when no character names appear in text', () {
        final result = resolver.resolvePronoun(
          pronoun: '他',
          text: '那个人走了过来',
          characters: {'林风': Gender.male},
        );
        expect(result, isNull);
      });
    });

    // --- resolveAll ---

    group('resolveAll', () {
      test('should resolve all pronouns in text', () {
        final results = resolver.resolveAll(
          text: '林风对李雪说，他看着她微笑',
          characters: {'林风': Gender.male, '李雪': Gender.female},
        );
        expect(results, isNotEmpty);
        expect(results.any((r) => r.entityId == '林风'), true);
        expect(results.any((r) => r.entityId == '李雪'), true);
      });
    });
  });
}
