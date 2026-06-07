import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';

import 'helpers/journey_container.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  const baseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  const model = 'glm-4-flash';

  late ProviderContainer container;

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: 'journey-local-test-key',
      baseUrl: baseUrl,
      model: model,
    );
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });

  group('Template World-Building Flow', () {
    test('should instantiate Phase 7 xianxia template with custom supplements',
        () async {
      final templateRepository = container.read(worldTemplateRepositoryProvider);
      final template = await templateRepository.getById('male-xianxia-sect');
      expect(
        template,
        isNotNull,
        reason: 'Phase 7 xianxia template must be available for JOURNEY-01',
      );

      final instantiationService = await container.read(
        templateInstantiationServiceProvider.future,
      );
      final draft = instantiationService.createDraft(
        template!,
        storyConcept: '凡人少年入青冥山海，经历练气、筑基的慢热成长线',
      );
      final creationResult = await instantiationService.saveDraft(draft);

      expect(creationResult.worldSetting, isNotNull);
      expect(creationResult.worldSetting!.name, contains('青冥'));
      expect(creationResult.characterCards, isNotEmpty);

      final characterRepo = await container.read(
        characterCardRepositoryProvider.future,
      );
      for (final card in XianxiaFixtures.characters()) {
        await characterRepo.add(card);
      }

      final skillRepo = await container.read(skillRepositoryProvider.future);
      final skills = XianxiaFixtures.skills();
      expect(skills, hasLength(4));
      for (final skill in skills) {
        await skillRepo.add(skill);
      }

      container.read(nameIndexServiceProvider.notifier).refresh();

      final worldRepo = await container.read(worldSettingRepositoryProvider.future);
      final worldSettings = worldRepo.getAll();
      expect(worldSettings, isNotEmpty);
      expect(
        worldSettings.map((setting) => setting.name),
        contains(creationResult.worldSetting!.name),
      );

      final allCards = characterRepo.getAll();
      expect(allCards.length, greaterThanOrEqualTo(3));
      expect(
        allCards.map((card) => card.name),
        containsAll(['林风', '清虚真人', '苏雪晴']),
      );

      final activeSkills = skillRepo.getActive();
      expect(activeSkills, hasLength(4));
      expect(
        activeSkills.map((skill) => skill.name),
        containsAll(['境界体系约束', '门派等级森严', '世界观禁忌', '能力限制']),
      );

      final nameIndex = container.read(nameIndexServiceProvider);
      expect(
        nameIndex.findMatches('林风踏入青冥剑宗药圃，清虚真人在殿中讲道'),
        isNotEmpty,
        reason: 'NameIndex should find custom character names after refresh',
      );
      expect(
        nameIndex.findMatches('青冥山海云海中藏有失航古舟'),
        isNotEmpty,
        reason: 'NameIndex should find template world setting keywords',
      );
    });
  });
}
