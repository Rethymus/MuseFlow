import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';

import 'helpers/journey_container.dart';
import 'helpers/xianxia_fixtures.dart';

void main() {
  final apiKey = Platform.environment['GLM_API_KEY'];
  final baseUrl = Platform.environment['GLM_BASE_URL'] ??
      'https://open.bigmodel.cn/api/paas/v4';
  final model = Platform.environment['GLM_MODEL'] ?? 'glm-4-flash';

  late ProviderContainer container;

  setUp(() async {
    container = await createJourneyContainer(
      apiKey: apiKey!,
      baseUrl: baseUrl,
      model: model,
    );
  });

  tearDown(() async {
    await cleanupJourneyContainer(container);
  });

  group('Character Card Creation', () {
    test('should create and verify 4 character cards', skip: apiKey == null
        ? 'GLM_API_KEY not set'
        : null, () async {
      final repo = await container.read(characterCardRepositoryProvider.future);

      final cards = [
        XianxiaFixtures.protagonist(),
        XianxiaFixtures.master(),
        XianxiaFixtures.senior(),
        XianxiaFixtures.rival(),
      ];

      for (final card in cards) {
        await repo.add(card);
      }

      final allCards = repo.getAll();
      expect(allCards, hasLength(4));

      final names = allCards.map((c) => c.name).toList();
      expect(names, containsAll(['林风', '清虚真人', '苏雪晴', '赵天磊']));
    });
  });

  group('World Setting Creation', () {
    test('should create and retrieve world setting', skip: apiKey == null
        ? 'GLM_API_KEY not set'
        : null, () async {
      final repo =
          await container.read(worldSettingRepositoryProvider.future);

      final setting = XianxiaFixtures.sectWorld();
      await repo.add(setting);

      final retrieved = repo.getById(setting.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, contains('青云'));
    });
  });

  group('Skill Document Creation', () {
    test('should create and verify 4 skill documents with isActive:true',
        skip: apiKey == null ? 'GLM_API_KEY not set' : null, () async {
      final repo = await container.read(skillRepositoryProvider.future);

      final skills = XianxiaFixtures.skillRules();
      expect(skills, hasLength(4));

      for (final skill in skills) {
        await repo.add(skill);
      }

      final allDocs = repo.getAll();
      expect(allDocs, hasLength(4));

      // Verify all have isActive: true
      for (final doc in allDocs) {
        expect(doc.isActive, isTrue,
            reason: 'Skill document "${doc.name}" should be active');
      }

      // Verify expected rule names
      final names = allDocs.map((d) => d.name).toList();
      expect(names, containsAll(['境界体系约束', '门派等级森严', '世界观禁忌', '能力限制']));
    });
  });

  group('NameIndex Refresh', () {
    test('should find character names in index after entity creation',
        skip: apiKey == null ? 'GLM_API_KEY not set' : null, () async {
      // Create all entities first (prerequisite for NameIndex to have data)
      final characterRepo =
          await container.read(characterCardRepositoryProvider.future);
      for (final card in [
        XianxiaFixtures.protagonist(),
        XianxiaFixtures.master(),
        XianxiaFixtures.senior(),
        XianxiaFixtures.rival(),
      ]) {
        await characterRepo.add(card);
      }

      final worldRepo =
          await container.read(worldSettingRepositoryProvider.future);
      await worldRepo.add(XianxiaFixtures.sectWorld());

      final skillRepo =
          await container.read(skillRepositoryProvider.future);
      for (final skill in XianxiaFixtures.skillRules()) {
        await skillRepo.add(skill);
      }

      // Refresh the NameIndex after all entities are created
      container.read(nameIndexServiceProvider.notifier).refresh();

      // Read the rebuilt index and verify matches
      final nameIndex = container.read(nameIndexServiceProvider);

      final linFengMatches = nameIndex.findMatches('林风踏入青云峰');
      expect(linFengMatches, isNotEmpty,
          reason: 'NameIndex should find matches for 林风');

      final elderMatches = nameIndex.findMatches('清虚真人在殿中讲道');
      expect(elderMatches, isNotEmpty,
          reason: 'NameIndex should find matches for 清虚真人');
    });
  });
}
