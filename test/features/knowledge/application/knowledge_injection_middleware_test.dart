import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:openai_dart/openai_dart.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('KnowledgeInjectionMiddleware', () {
    late Box<dynamic> characterBox;
    late Box<dynamic> settingBox;
    late CharacterCardRepository characterRepository;
    late WorldSettingRepository worldSettingRepository;
    late NameIndex nameIndex;
    late KnowledgeInjectionMiddleware middleware;

    final now = DateTime(2026, 1, 1);

    setUp(() async {
      await setUpHiveTest();
      characterBox = await Hive.openBox<dynamic>('character_cards_test');
      settingBox = await Hive.openBox<dynamic>('world_settings_test');
      characterRepository = CharacterCardRepository(characterBox);
      worldSettingRepository = WorldSettingRepository(settingBox);
      nameIndex = NameIndex();
      middleware = KnowledgeInjectionMiddleware(
        nameIndex: nameIndex,
        characterRepository: characterRepository,
        worldSettingRepository: worldSettingRepository,
        tokenBudgetCalculator: TokenBudgetCalculator(),
      );
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test('should leave context unchanged when no matches exist', () {
      final context = PromptContext(
        fragments: [Fragment(id: 'f1', text: '无人出现', createdAt: now)],
      );

      final result = middleware.apply(context);

      expect(result.messages, isEmpty);
    });

    test('should inject matched character context into system message', () async {
      await characterBox.put(
        'char-1',
        CharacterCard(
          id: 'char-1',
          name: '李白',
          personality: '洒脱',
          appearance: '白衣',
          backstory: '诗仙',
          createdAt: now,
        ).toJson(),
      );
      nameIndex.addEntity('char-1', EntityType.character, ['李白']);

      final result = middleware.apply(
        PromptContext(
          fragments: [Fragment(id: 'f1', text: '李白举杯邀月', createdAt: now)],
          tokenBudget: 4096,
        ),
      );

      expect(result.messages.length, equals(1));
      final content = result.messages.first.toJson()['content'] as String;
      expect(content, contains('以下是与当前内容相关的角色和设定信息'));
      expect(content, contains('李白'));
      expect(content, contains('洒脱'));
    });

    test('should append injection to existing system message', () async {
      await settingBox.put(
        'setting-1',
        WorldSetting(
          id: 'setting-1',
          name: '长安',
          rules: '宵禁',
          factions: '禁军',
          geography: '都城',
          techLevel: '唐风',
          createdAt: now,
        ).toJson(),
      );
      nameIndex.addEntity('setting-1', EntityType.setting, ['长安']);

      final result = middleware.apply(
        PromptContext(
          fragments: [Fragment(id: 'f1', text: '长安夜雨', createdAt: now)],
          messages: [ChatMessage.system('原系统提示')],
        ),
      );

      final content = result.messages.first.toJson()['content'] as String;
      expect(content, startsWith('原系统提示'));
      expect(content, contains('长安'));
      expect(content, contains('宵禁'));
    });
  });
}
