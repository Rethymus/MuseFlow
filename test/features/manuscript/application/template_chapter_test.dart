import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/templates/application/template_draft.dart';
import 'package:museflow/features/templates/application/template_instantiation_service.dart';
import 'package:hive_ce/hive.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('TemplateInstantiationService chapter skeletons', () {
    late TemplateInstantiationService service;

    setUp(() async {
      await setUpHiveTest();

      final chaptersBox = await Hive.openBox<dynamic>('test_chapters_template');
      final chapterRepo = ChapterRepository(chaptersBox);

      final worldBox = await Hive.openBox<dynamic>('test_world_template');
      final worldRepo = WorldSettingRepository(worldBox);

      final charBox = await Hive.openBox<dynamic>('test_chars_template');
      final charRepo = CharacterCardRepository(charBox);

      service = TemplateInstantiationService(
        worldSettingRepository: worldRepo,
        characterCardRepository: charRepo,
        chapterRepository: chapterRepo,
      );
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test('should create chapter skeletons when manuscriptId provided', () async {
      final draft = TemplateDraft(
        templateId: 't1',
        storyConcept: 'test concept',
        world: WorldSettingDraft(
          selected: false,
          name: DraftTextField(value: 'World', source: TemplateFieldSource.templateDefault),
          description: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          rules: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          factions: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          geography: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          techLevel: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          aliases: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
        ),
        characters: const [],
        manuscriptId: 'manuscript-123',
        chapterTitles: ['世界观铺垫', '角色登场', '主线开启'],
      );

      final result = await service.saveDraft(draft);

      expect(result.chapters, isNotEmpty);
      expect(result.chapters.length, 3);
      expect(result.chapters[0].title, '世界观铺垫');
      expect(result.chapters[0].manuscriptId, 'manuscript-123');
      expect(result.chapters[0].sortOrder, 0);
      expect(result.chapters[0].status, '草稿');
      expect(result.chapters[1].title, '角色登场');
      expect(result.chapters[1].sortOrder, 1);
      expect(result.chapters[2].title, '主线开启');
      expect(result.chapters[2].sortOrder, 2);
    });

    test('should not create chapters when manuscriptId is null', () async {
      final draft = TemplateDraft(
        templateId: 't1',
        storyConcept: 'test',
        world: WorldSettingDraft(
          selected: false,
          name: DraftTextField(value: 'World', source: TemplateFieldSource.templateDefault),
          description: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          rules: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          factions: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          geography: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          techLevel: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          aliases: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
        ),
        characters: const [],
      );

      final result = await service.saveDraft(draft);

      expect(result.chapters, isEmpty);
    });

    test('should use default chapter titles when none provided', () async {
      final draft = TemplateDraft(
        templateId: 't1',
        storyConcept: 'test',
        world: WorldSettingDraft(
          selected: false,
          name: DraftTextField(value: 'World', source: TemplateFieldSource.templateDefault),
          description: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          rules: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          factions: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          geography: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          techLevel: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
          aliases: DraftTextField(value: '', source: TemplateFieldSource.templateDefault),
        ),
        characters: const [],
        manuscriptId: 'ms-456',
        // No chapterTitles provided -- should use defaults
      );

      final result = await service.saveDraft(draft);

      expect(result.chapters, isNotEmpty);
      expect(result.chapters.length, 3);
      expect(result.chapters[0].title, '世界观铺垫');
      expect(result.chapters[1].title, '角色登场');
      expect(result.chapters[2].title, '主线开启');
    });
  });
}
