import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

void main() {
  group('ExportBundle', () {
    late ExportBundle bundle;

    setUp(() {
      bundle = ExportBundle(
        schemaVersion: '1.0',
        exportedAt: DateTime(2026, 6, 4),
        manuscriptText: '这是稿件的文本内容。',
        foreshadowingEntries: [
          ForeshadowingEntry(
            id: 'f1',
            title: '伏笔一',
            mode: ForeshadowingMode.detailed,
            status: ForeshadowingStatus.planted,
            plantedChapter: 1,
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
        plotNodes: [
          PlotNode(
            id: 'p1',
            title: '开端',
            chapter: 1,
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
        guardianAnnotations: [
          GuardianAnnotation(
            id: 'g1',
            kind: GuardianFindingKind.characterConsistency,
            severity: GuardianSeverity.medium,
            message: '角色行为不一致',
            reason: '与设定冲突',
            createdAt: DateTime(2026, 6, 2),
          ),
        ],
        characterCards: [
          {'id': 'c1', 'name': '角色一'},
        ],
        worldSettings: [
          {'id': 'w1', 'name': '世界一'},
        ],
        skillDocuments: [
          {'id': 's1', 'name': '技能一'},
        ],
        activeSkillIds: ['s1'],
        metadata: {'appVersion': '1.0.0'},
      );
    });

    test('should have schema version', () {
      expect(bundle.schemaVersion, '1.0');
    });

    test('should serialize to JSON with all fields', () {
      final json = bundle.toJson();

      expect(json['schemaVersion'], '1.0');
      expect(json['exportedAt'], isNotNull);
      expect(json['manuscriptText'], '这是稿件的文本内容。');

      // Foreshadowing entries
      final fEntries = json['foreshadowingEntries'] as List;
      expect(fEntries.length, 1);
      expect(fEntries[0]['id'], 'f1');
      expect(fEntries[0]['title'], '伏笔一');

      // Plot nodes
      final pNodes = json['plotNodes'] as List;
      expect(pNodes.length, 1);
      expect(pNodes[0]['id'], 'p1');

      // Guardian annotations
      final gAnns = json['guardianAnnotations'] as List;
      expect(gAnns.length, 1);
      expect(gAnns[0]['id'], 'g1');

      // Character cards
      final chars = json['characterCards'] as List;
      expect(chars.length, 1);
      expect(chars[0]['name'], '角色一');

      // World settings
      final worlds = json['worldSettings'] as List;
      expect(worlds.length, 1);
      expect(worlds[0]['name'], '世界一');

      // Skill documents
      final skills = json['skillDocuments'] as List;
      expect(skills.length, 1);
      expect(skills[0]['name'], '技能一');

      // Active skill IDs
      final activeSkills = json['activeSkillIds'] as List;
      expect(activeSkills, ['s1']);

      // Metadata
      final meta = json['metadata'] as Map;
      expect(meta['appVersion'], '1.0.0');
    });

    test('should deserialize from JSON', () {
      final json = bundle.toJson();
      final restored = ExportBundle.fromJson(json);

      expect(restored.schemaVersion, bundle.schemaVersion);
      expect(restored.manuscriptText, bundle.manuscriptText);
      expect(restored.foreshadowingEntries.length, 1);
      expect(restored.foreshadowingEntries[0].id, 'f1');
      expect(restored.plotNodes.length, 1);
      expect(restored.plotNodes[0].id, 'p1');
      expect(restored.guardianAnnotations.length, 1);
      expect(restored.guardianAnnotations[0].id, 'g1');
      expect(restored.characterCards.length, 1);
      expect(restored.worldSettings.length, 1);
      expect(restored.skillDocuments.length, 1);
      expect(restored.activeSkillIds, ['s1']);
      expect(restored.metadata['appVersion'], '1.0.0');
    });

    test('should create with empty collections', () {
      const empty = ExportBundle(
        schemaVersion: '1.0',
        exportedAt: null,
        manuscriptText: '',
        foreshadowingEntries: [],
        plotNodes: [],
        guardianAnnotations: [],
        characterCards: [],
        worldSettings: [],
        skillDocuments: [],
        activeSkillIds: [],
        metadata: {},
      );

      expect(empty.foreshadowingEntries, isEmpty);
      expect(empty.plotNodes, isEmpty);
      expect(empty.guardianAnnotations, isEmpty);
      expect(empty.characterCards, isEmpty);
      expect(empty.worldSettings, isEmpty);
      expect(empty.skillDocuments, isEmpty);
      expect(empty.activeSkillIds, isEmpty);
    });
  });
}
