import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/infrastructure/foreshadowing_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/guardian_annotation_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/plot_node_repository.dart';

import '../helpers/hive_test_helper.dart';

/// Reload-roundtrip coverage for Hive-backed repositories.
///
/// Hive's non-lazy `Box` returns the exact object a same-session `put()`
/// stored, so decode bugs are invisible until the box is closed and reopened
/// (what a web page refresh or app restart does). These tests force the
/// close→reopen cycle that previously let `Map<dynamic, dynamic>` fail a
/// `as Map<String, dynamic>` cast in production.
void main() {
  setUp(() async {
    await setUpHiveTest();
    // Only the fragments box is typed; the repository boxes below read raw
    // maps from Box<dynamic>, so FragmentAdapter is the only one exercised.
    if (!Hive.isAdapterRegistered(HiveTypeIds.fragment)) {
      Hive.registerAdapter(FragmentAdapter());
    }
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  group('Fragment typed box survives close→reopen', () {
    test(
      'reads back a Fragment after the box is closed and reopened',
      () async {
        final box = await Hive.openBox<Fragment>('fragments');
        await box.put(
          'f1',
          Fragment(
            id: 'f1',
            text: '雨夜旧巷里的半目棋社',
            tags: [FragmentTags.story, FragmentTags.scene],
            createdAt: DateTime(2026, 8, 16),
          ),
        );
        await box.close();

        final reopened = await Hive.openBox<Fragment>('fragments');
        final fragment = reopened.get('f1');

        expect(fragment, isNotNull);
        expect(fragment!.text, '雨夜旧巷里的半目棋社');
        expect(fragment.tags, [FragmentTags.story, FragmentTags.scene]);
      },
    );
  });

  group('CharacterCardRepository survives close→reopen', () {
    test('getAll reads cards written in a previous box session', () async {
      final box = await Hive.openBox<dynamic>('character_cards');
      final repository = CharacterCardRepository(box);
      await repository.add(
        CharacterCard(
          id: 'c1',
          name: '林风',
          personality: '坚韧重情义',
          aliases: const ['小风', '风哥'],
          createdAt: DateTime(2026, 8, 16),
        ),
      );
      await box.close();

      final reopened = await Hive.openBox<dynamic>('character_cards');
      final reloadedRepository = CharacterCardRepository(reopened);

      final cards = reloadedRepository.getAll();
      expect(cards, hasLength(1));
      expect(cards.first.name, '林风');
      expect(cards.first.aliases, ['小风', '风哥']);
      expect(reloadedRepository.getById('c1')!.personality, '坚韧重情义');
    });
  });

  group('WorldSettingRepository survives close→reopen', () {
    test('getAll reads settings written in a previous box session', () async {
      final box = await Hive.openBox<dynamic>('world_settings');
      final repository = WorldSettingRepository(box);
      await repository.add(
        WorldSetting(
          id: 'w1',
          name: '九州灵墟',
          description: '灵气复苏的九州大陆',
          aliases: const ['灵墟'],
          createdAt: DateTime(2026, 8, 16),
        ),
      );
      await box.close();

      final reopened = await Hive.openBox<dynamic>('world_settings');
      final settings = WorldSettingRepository(reopened).getAll();

      expect(settings, hasLength(1));
      expect(settings.first.name, '九州灵墟');
      expect(settings.first.aliases, ['灵墟']);
    });
  });

  group('PlotNodeRepository survives close→reopen', () {
    test('reads nodes written in a previous box session', () async {
      final box = await Hive.openBox<dynamic>('plot_nodes');
      final repository = PlotNodeRepository(box);
      await repository.add(
        PlotNode(
          id: 'p1',
          title: '断崖得剑',
          chapter: 3,
          summary: '林风在断崖下拾得古剑',
          involvedCharacterIds: const ['c1'],
          involvedCharacterNames: const ['林风'],
          createdAt: DateTime(2026, 8, 18),
        ),
      );
      await box.close();

      final reopened = await Hive.openBox<dynamic>('plot_nodes');
      final nodes = PlotNodeRepository(reopened).getAll();

      expect(nodes, hasLength(1));
      expect(nodes.first.title, '断崖得剑');
      expect(nodes.first.involvedCharacterNames, ['林风']);
    });
  });

  group('GuardianAnnotationRepository survives close→reopen', () {
    test('reads annotations written in a previous box session', () async {
      final box = await Hive.openBox<dynamic>('guardian_annotations');
      final repository = GuardianAnnotationRepository(box);
      await repository.add(
        GuardianAnnotation(
          id: 'g1',
          kind: GuardianFindingKind.characterConsistency,
          severity: GuardianSeverity.high,
          message: '林风不应知晓此事',
          reason: '与第 2 章设定冲突',
          createdAt: DateTime(2026, 8, 18),
        ),
      );
      await box.close();

      final reopened = await Hive.openBox<dynamic>('guardian_annotations');
      final annotations = GuardianAnnotationRepository(reopened).getAll();

      expect(annotations, hasLength(1));
      expect(annotations.first.message, '林风不应知晓此事');
      expect(annotations.first.severity, GuardianSeverity.high);
    });
  });

  group('ForeshadowingRepository survives close→reopen', () {
    test('nested sourceLocation map decodes after reload', () async {
      final box = await Hive.openBox<dynamic>('foreshadowing_entries');
      final repository = ForeshadowingRepository(box);
      await repository.add(
        ForeshadowingEntry(
          id: 'fo1',
          title: '断崖古剑的星图',
          mode: ForeshadowingMode.simple,
          status: ForeshadowingStatus.planted,
          plantedChapter: 3,
          targetResolutionChapter: 40,
          sourceLocation: const SourceLocation(
            nodeId: 'node-3',
            startOffset: 12,
            endOffset: 30,
            chapter: 3,
          ),
          createdAt: DateTime(2026, 8, 16),
        ),
      );
      await box.close();

      final reopened = await Hive.openBox<dynamic>('foreshadowing_entries');
      final entries = ForeshadowingRepository(reopened).getAll();

      expect(entries, hasLength(1));
      expect(entries.first.sourceLocation?.nodeId, 'node-3');
      expect(entries.first.sourceLocation?.startOffset, 12);
    });
  });
}
