import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';
import 'package:museflow/features/templates/presentation/template_gallery_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TemplateGalleryPage', () {
    testWidgets('shows channel filter and template cards', (tester) async {
      await _pumpGallery(tester);
      await _pumpUntilFound(tester, find.text('全部'));

      expect(find.text('全部'), findsOneWidget);
      expect(find.text('男频'), findsWidgets);
      expect(find.text('女频'), findsWidgets);
      expect(find.text('玄幻｜血脉觉醒'), findsOneWidget);
      expect(find.text('内置已审核'), findsWidgets);
    });

    testWidgets('filters female templates by segmented control', (
      tester,
    ) async {
      await _pumpGallery(tester);
      await _pumpUntilFound(tester, find.text('女频'));

      await tester.tap(find.text('女频').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('现言｜职场成长'), findsOneWidget);
      expect(find.text('玄幻｜血脉觉醒'), findsNothing);
    });

    testWidgets('searches by tag metadata', (tester) async {
      await _pumpGallery(tester);
      await _pumpUntilFound(tester, find.byType(TextField));

      await tester.enterText(find.byType(TextField), '职场');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('现言｜职场成长'), findsOneWidget);
      expect(find.text('玄幻｜血脉觉醒'), findsNothing);
    });
  });
}

Future<void> _pumpGallery(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        worldTemplateRepositoryProvider.overrideWithValue(_repository()),
      ],
      child: const MaterialApp(home: TemplateGalleryPage()),
    ),
  );
}

WorldTemplateRepository _repository() {
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
      "world": {"name": "断岳九州", "description": "描述", "rules": "规则", "factions": "势力", "geography": "地理", "techLevel": "技术", "aliases": []},
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
    },
    {
      "id": "female-modern-career",
      "channel": "female",
      "sortOrder": 2,
      "genreName": "现言",
      "subtitle": "职场成长",
      "description": "现代职场成长。",
      "iconName": "work_outline",
      "tags": ["现言", "职场", "成长", "都市情感", "创业"],
      "review": {"sourceNote": "reviewed", "reviewedAt": "2026-06-04T00:00:00.000Z", "qualityChecks": ["a", "b", "c", "d"]},
      "world": {"name": "海城", "description": "描述", "rules": "规则", "factions": "势力", "geography": "地理", "techLevel": "技术", "aliases": []},
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
