import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/templates/application/template_draft.dart';
import 'package:museflow/features/templates/application/template_instantiation_service.dart';
import 'package:museflow/features/templates/domain/world_template.dart';

void main() {
  group('TemplateInstantiationService', () {
    late Directory tempDir;
    late Box<dynamic> worldBox;
    late Box<dynamic> characterBox;
    late TemplateInstantiationService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'museflow_template_test_',
      );
      Hive.init(tempDir.path);
      worldBox = await Hive.openBox<dynamic>('world_settings_test');
      characterBox = await Hive.openBox<dynamic>('character_cards_test');
      service = TemplateInstantiationService(
        worldSettingRepository: WorldSettingRepository(worldBox),
        characterCardRepository: CharacterCardRepository(characterBox),
      );
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('creates selected world and character drafts from template', () {
      final draft = service.createDraft(_template(), storyConcept: '概念');

      expect(draft.templateId, 'template-1');
      expect(draft.storyConcept, '概念');
      expect(draft.world.selected, isTrue);
      expect(draft.world.name.source, TemplateFieldSource.templateDefault);
      expect(draft.characters, hasLength(3));
      expect(draft.characters.every((character) => character.selected), isTrue);
    });

    test('saves selected entities only', () async {
      final draft = service
          .createDraft(_template())
          .copyWith(
            world: service
                .createDraft(_template())
                .world
                .copyWith(selected: false),
            characters: [
              service.createDraft(_template()).characters[0],
              service
                  .createDraft(_template())
                  .characters[1]
                  .copyWith(selected: false),
              service.createDraft(_template()).characters[2],
            ],
          );

      final result = await service.saveDraft(draft);

      expect(result.worldSetting, isNull);
      expect(result.characterCards, hasLength(2));
      expect(worldBox.values, isEmpty);
      expect(characterBox.values, hasLength(2));
    });
  });
}

WorldTemplate _template() {
  return WorldTemplate(
    id: 'template-1',
    channel: TemplateChannel.male,
    sortOrder: 1,
    genreName: '玄幻',
    subtitle: '血脉觉醒',
    description: '描述',
    iconName: 'auto_awesome',
    tags: const ['血脉', '宗族', '逆袭', '秘境', '天命'],
    review: TemplateReviewMetadata(
      sourceNote: 'reviewed',
      reviewedAt: DateTime(2026, 6, 4),
      qualityChecks: const ['a', 'b', 'c', 'd'],
    ),
    world: const WorldTemplateWorld(
      name: '断岳九州',
      description: '描述',
      rules: '规则',
      factions: '势力',
      geography: '地理',
      techLevel: '技术',
      aliases: [],
    ),
    characters: const [
      WorldTemplateCharacter(
        name: '角色一',
        personality: '性格',
        appearance: '外貌',
        backstory: '背景',
        aliases: [],
      ),
      WorldTemplateCharacter(
        name: '角色二',
        personality: '性格',
        appearance: '外貌',
        backstory: '背景',
        aliases: [],
      ),
      WorldTemplateCharacter(
        name: '角色三',
        personality: '性格',
        appearance: '外貌',
        backstory: '背景',
        aliases: [],
      ),
    ],
    foreshadowingArcs: const [
      ForeshadowingArc(setup: '起点', development: '发展', payoff: '回收'),
      ForeshadowingArc(setup: '起点', development: '发展', payoff: '回收'),
      ForeshadowingArc(setup: '起点', development: '发展', payoff: '回收'),
    ],
    openingSamples: const [
      OpeningSample(style: OpeningSampleStyle.scene, text: '场景'),
      OpeningSample(style: OpeningSampleStyle.character, text: '人物'),
      OpeningSample(style: OpeningSampleStyle.suspense, text: '悬念'),
    ],
  );
}
