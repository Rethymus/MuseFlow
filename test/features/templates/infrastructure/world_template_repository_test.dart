import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/templates/domain/world_template.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorldTemplateRepository', () {
    test('loads bundled template library with expected counts', () async {
      final repository = WorldTemplateRepository();

      final templates = await repository.getAll();

      expect(templates, hasLength(14));
      expect(
        templates.where((template) => template.channel == TemplateChannel.male),
        hasLength(8),
      );
      expect(
        templates.where(
          (template) => template.channel == TemplateChannel.female,
        ),
        hasLength(6),
      );
      expect(templates.first.sortOrder, 1);
      expect(templates.last.sortOrder, 14);
    });

    test(
      'validates bundled template structure and entity instantiation',
      () async {
        final repository = WorldTemplateRepository();
        final templates = await repository.getAll();

        for (final template in templates) {
          expect(template.tags.length, inInclusiveRange(5, 8));
          expect(template.characters, hasLength(3));
          expect(template.foreshadowingArcs.length, inInclusiveRange(3, 5));
          expect(template.openingSamples, hasLength(3));
          expect(
            template.openingSamples.map((sample) => sample.style).toSet(),
            {
              OpeningSampleStyle.scene,
              OpeningSampleStyle.character,
              OpeningSampleStyle.suspense,
            },
          );
          expect(template.review.qualityChecks, hasLength(4));

          expect(() => template.world.toWorldSetting(), returnsNormally);
          for (final character in template.characters) {
            expect(() => character.toCharacterCard(), returnsNormally);
          }
        }
      },
    );

    test('supports id lookup, channel filter, and metadata search', () async {
      final repository = WorldTemplateRepository();

      final template = await repository.getById('male-xuanhuan-bloodline');
      expect(template, isNotNull);
      expect(template!.genreName, '玄幻');

      final femaleTemplates = await repository.filterByChannel(
        TemplateChannel.female,
      );
      expect(femaleTemplates, hasLength(6));

      final tagMatches = await repository.search('职场');
      expect(
        tagMatches.any((template) => template.id == 'female-modern-career'),
        isTrue,
      );

      final all = await repository.search('');
      expect(all, hasLength(14));
    });

    test('can load from injected asset loader', () async {
      final repository = WorldTemplateRepository(
        assetPath: 'fake.json',
        assetLoader: (_) async => _oneTemplateJson,
      );

      final templates = await repository.getAll();

      expect(templates, hasLength(1));
      expect(templates.single.id, 'test-template');
    });
  });
}

const _oneTemplateJson = '''
{
  "templateSchemaVersion": 1,
  "language": "zh-CN",
  "templates": [
    {
      "id": "test-template",
      "channel": "male",
      "sortOrder": 1,
      "genreName": "测试",
      "subtitle": "模板",
      "description": "测试描述",
      "iconName": "test",
      "tags": ["一", "二", "三", "四", "五"],
      "review": {"sourceNote": "reviewed", "reviewedAt": "2026-06-04T00:00:00.000Z", "qualityChecks": ["a", "b", "c", "d"]},
      "world": {"name": "世界", "description": "描述", "rules": "规则", "factions": "势力", "geography": "地理", "techLevel": "技术", "aliases": []},
      "characters": [
        {"name": "角色一", "personality": "性格", "appearance": "外貌", "backstory": "背景", "aliases": []},
        {"name": "角色二", "personality": "性格", "appearance": "外貌", "backstory": "背景", "aliases": []},
        {"name": "角色三", "personality": "性格", "appearance": "外貌", "backstory": "背景", "aliases": []}
      ],
      "foreshadowingArcs": [
        {"setup": "起点", "development": "发展", "payoff": "回收"},
        {"setup": "起点", "development": "发展", "payoff": "回收"},
        {"setup": "起点", "development": "发展", "payoff": "回收"}
      ],
      "openingSamples": [
        {"style": "scene", "text": "场景"},
        {"style": "character", "text": "人物"},
        {"style": "suspense", "text": "悬念"}
      ]
    }
  ]
}
''';
