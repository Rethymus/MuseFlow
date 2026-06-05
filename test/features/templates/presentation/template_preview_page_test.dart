import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';
import 'package:museflow/features/templates/presentation/template_preview_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TemplatePreviewPage', () {
    testWidgets('shows collapsed sections and concept input', (tester) async {
      await _pumpPreview(tester);
      await _pumpUntilFound(tester, find.text('世界设定骨架'));

      expect(find.text('玄幻｜血脉觉醒'), findsOneWidget);
      expect(find.text('你的故事概念（可选）'), findsOneWidget);
      expect(find.text('世界设定骨架'), findsOneWidget);
      expect(find.text('角色原型'), findsOneWidget);
      expect(find.text('伏笔模式'), findsOneWidget);
      expect(find.text('开篇示例'), findsOneWidget);

      expect(find.textContaining('断岳九州'), findsNothing);
    });

    testWidgets('expands preview content', (tester) async {
      await _pumpPreview(tester);
      await _pumpUntilFound(tester, find.text('世界设定骨架'));

      await tester.tap(find.text('世界设定骨架'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('断岳九州'), findsOneWidget);

      await tester.tap(find.text('伏笔模式'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining(' -> '), findsWidgets);
    });

    testWidgets('navigates to draft route with concept', (tester) async {
      final router = GoRouter(
        initialLocation: '/preview',
        routes: [
          GoRoute(
            path: '/preview',
            builder: (context, state) => const TemplatePreviewPage(
              templateId: 'male-xuanhuan-bloodline',
            ),
          ),
          GoRoute(
            path: '/knowledge/templates/:id/draft',
            builder: (context, state) => Text(
              'draft:${state.pathParameters['id']}:${state.uri.queryParameters['concept']}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            worldTemplateRepositoryProvider.overrideWithValue(_repository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await _pumpUntilFound(tester, find.byType(TextField));

      await tester.enterText(find.byType(TextField), '少年不想修仙');
      await tester.tap(find.text('使用模板'));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpUntilFound(tester, find.textContaining('draft:'));

      expect(find.text('draft:male-xuanhuan-bloodline:少年不想修仙'), findsOneWidget);
    });
  });
}

Future<void> _pumpPreview(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        worldTemplateRepositoryProvider.overrideWithValue(_repository()),
      ],
      child: MaterialApp(
        home: TemplatePreviewPage(templateId: 'male-xuanhuan-bloodline'),
      ),
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
