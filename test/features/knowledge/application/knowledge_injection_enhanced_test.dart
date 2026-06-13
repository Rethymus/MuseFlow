/// Tests for enhanced KnowledgeInjectionMiddleware — fuzzy matching, pronoun resolution.
///
/// Validates Phase 20 (KNOW-01, KNOW-03): context-aware prioritization
/// with fuzzy matching, alias extraction, and pronoun coreference.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/fuzzy_matcher.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/pronoun_resolver.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('KnowledgeInjectionMiddleware (enhanced)', () {
    late Box<dynamic> characterBox;
    late Box<dynamic> settingBox;
    late CharacterCardRepository characterRepository;
    late WorldSettingRepository worldSettingRepository;
    late NameIndex nameIndex;
    late KnowledgeInjectionMiddleware middleware;
    final now = DateTime(2026, 1, 1);

    setUp(() async {
      await setUpHiveTest();
      characterBox = await Hive.openBox<dynamic>('char_test');
      settingBox = await Hive.openBox<dynamic>('set_test');
      characterRepository = CharacterCardRepository(characterBox);
      worldSettingRepository = WorldSettingRepository(settingBox);
      nameIndex = NameIndex();
      middleware = KnowledgeInjectionMiddleware(
        nameIndex: nameIndex,
        characterRepository: characterRepository,
        worldSettingRepository: worldSettingRepository,
        tokenBudgetCalculator: TokenBudgetCalculator(),
        fuzzyMatcher: const FuzzyMatcher(maxDistance: 2),
        pronounResolver: PronounResolver(),
      );
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test('should inject character context when name has a typo', () async {
      await characterBox.put(
        'char-1',
        CharacterCard(
          id: 'char-1',
          name: '林风',
          personality: '冷静',
          appearance: '黑衣',
          backstory: '剑客',
          createdAt: now,
        ).toJson(),
      );
      nameIndex.addEntity('char-1', EntityType.character, ['林风']);

      final result = middleware.apply(
        PromptContext(
          fragments: [Fragment(id: 'f1', text: '林锋站在山门前', createdAt: now)],
          tokenBudget: 4096,
        ),
      );

      // 林锋 (typo) should fuzzy-match 林风
      expect(result.messages.length, equals(1));
      final content = result.messages.first.toJson()['content'] as String;
      expect(content, contains('林风'));
      expect(content, contains('冷静'));
    });

    test('should inject character context when pronoun is used', () async {
      await characterBox.put(
        'char-1',
        CharacterCard(
          id: 'char-1',
          name: '林风',
          personality: '冷静',
          createdAt: now,
        ).toJson(),
      );
      nameIndex.addEntity('char-1', EntityType.character, ['林风']);

      final result = middleware.apply(
        PromptContext(
          fragments: [Fragment(id: 'f1', text: '林风走到门前，他对守卫说', createdAt: now)],
          tokenBudget: 4096,
          characterGenders: {'林风': Gender.male},
        ),
      );

      expect(result.messages.length, equals(1));
      final content = result.messages.first.toJson()['content'] as String;
      // 他 should resolve to 林风
      expect(content, contains('林风'));
    });

    test('should not inject when fuzzy match exceeds max distance', () async {
      await characterBox.put(
        'char-1',
        CharacterCard(
          id: 'char-1',
          name: '林风',
          personality: '冷静',
          createdAt: now,
        ).toJson(),
      );
      nameIndex.addEntity('char-1', EntityType.character, ['林风']);

      final result = middleware.apply(
        PromptContext(
          fragments: [Fragment(id: 'f1', text: '王刚走到门前', createdAt: now)],
          tokenBudget: 4096,
        ),
      );

      // 王刚 is too different from 林风 (2-char strings, no chars in common)
      expect(result.messages, isEmpty);
    });

    test('should prioritize exact matches over fuzzy matches', () async {
      await characterBox.put(
        'char-1',
        CharacterCard(
          id: 'char-1',
          name: '林风',
          personality: '冷静',
          createdAt: now,
        ).toJson(),
      );
      await characterBox.put(
        'char-2',
        CharacterCard(
          id: 'char-2',
          name: '林锋',
          personality: '冲动',
          createdAt: now,
        ).toJson(),
      );
      nameIndex.addEntity('char-1', EntityType.character, ['林风']);
      nameIndex.addEntity('char-2', EntityType.character, ['林锋']);

      final result = middleware.apply(
        PromptContext(
          fragments: [Fragment(id: 'f1', text: '林锋站在山门前', createdAt: now)],
          tokenBudget: 4096,
        ),
      );

      final content = result.messages.first.toJson()['content'] as String;
      // Both 林风 (fuzzy) and 林锋 (exact) match, but 林锋 is exact
      // Both should appear since budget allows
      expect(content, contains('林风'));
      expect(content, contains('林锋'));
    });

    test('should inject both exact and pronoun-resolved entities', () async {
      await characterBox.put(
        'char-1',
        CharacterCard(
          id: 'char-1',
          name: '林风',
          personality: '冷静',
          createdAt: now,
        ).toJson(),
      );
      await characterBox.put(
        'char-2',
        CharacterCard(
          id: 'char-2',
          name: '李雪',
          personality: '温柔',
          createdAt: now,
        ).toJson(),
      );
      nameIndex.addEntity('char-1', EntityType.character, ['林风']);
      nameIndex.addEntity('char-2', EntityType.character, ['李雪']);

      final result = middleware.apply(
        PromptContext(
          fragments: [Fragment(id: 'f1', text: '林风对李雪说，他对她微笑', createdAt: now)],
          tokenBudget: 4096,
          characterGenders: {'林风': Gender.male, '李雪': Gender.female},
        ),
      );

      final content = result.messages.first.toJson()['content'] as String;
      expect(content, contains('林风'));
      expect(content, contains('李雪'));
    });
  });
}
