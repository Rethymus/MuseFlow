import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/templates/application/template_instantiation_service.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';
import 'package:museflow/features/templates/presentation/template_draft_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TemplateDraftPage', () {
    late Directory tempDir;
    late Box<dynamic> worldBox;
    late Box<dynamic> characterBox;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'museflow_draft_page_test_',
      );
      Hive.init(tempDir.path);
      worldBox = await Hive.openBox<dynamic>('world_settings_test');
      characterBox = await Hive.openBox<dynamic>('character_cards_test');
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    testWidgets('loads draft with selected collapsed entities', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            worldTemplateRepositoryProvider.overrideWithValue(
              _templateRepository(),
            ),
            templateInstantiationServiceProvider.overrideWith((ref) async {
              return TemplateInstantiationService(
                worldSettingRepository: WorldSettingRepository(worldBox),
                characterCardRepository: CharacterCardRepository(characterBox),
              );
            }),
          ],
          child: const MaterialApp(
            home: TemplateDraftPage(
              templateId: 'male-xuanhuan-bloodline',
              initialConcept: '少年不想修仙',
            ),
          ),
        ),
      );

      await _pumpUntilFound(tester, find.text('世界观：断岳九州'));

      expect(find.text('故事概念'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(4));
      expect(find.text('角色：边地少年'), findsOneWidget);
      expect(find.text('保存到知识库'), findsOneWidget);

      await tester.tap(find.text('世界观：断岳九州'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('模板默认'), findsWidgets);
    });
  });
}

WorldTemplateRepository _templateRepository() {
  return WorldTemplateRepository(
    assetPath: 'test.json',
    assetLoader: (_) async => _templatesJson,
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 10,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected finder to appear: $finder');
}

const _templatesJson = '''
{
  "templateSchemaVersion": 1,
  "language": "zh-CN",
  "templates": [
    {
      "id": "male-xuanhuan-bloodline",
      "channel": "male",
      "sortOrder": 1,
      "genreName": "玄幻",
      "subtitle": "血脉觉醒",
      "description": "边地少年与宗族秘史。",
      "iconName": "auto_awesome",
      "tags": ["血脉", "宗族", "逆袭", "秘境", "天命"],
      "review": {"sourceNote": "reviewed", "reviewedAt": "2026-06-04T00:00:00.000Z", "qualityChecks": ["a", "b", "c", "d"]},
      "world": {"name": "断岳九州", "description": "九州被山脉分隔。", "rules": "血脉可共鸣。", "factions": "镇岳宗。", "geography": "北境雪岭。", "techLevel": "灵器。", "aliases": []},
      "characters": [
        {"name": "边地少年", "personality": "倔强", "appearance": "旧皮甲", "backstory": "矿难中觉醒。", "aliases": []},
        {"name": "冷面师姐", "personality": "克制", "appearance": "白衣", "backstory": "调查异动。", "aliases": []},
        {"name": "流亡族老", "personality": "谨慎", "appearance": "独眼", "backstory": "知道真相。", "aliases": []}
      ],
      "foreshadowingArcs": [
        {"setup": "起点", "development": "发展", "payoff": "回收"},
        {"setup": "族谱缺页", "development": "敌族祭文", "payoff": "共同守封印"},
        {"setup": "玉符裂纹", "development": "压制矿脉", "payoff": "来自母族"}
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
