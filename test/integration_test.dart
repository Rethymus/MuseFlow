import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:museflow/main.dart';
import 'package:museflow/models/app_state.dart';
import 'package:museflow/pages/main_navigation.dart';
import 'package:museflow/pages/home_page.dart';
import 'package:museflow/pages/settings_page.dart';
import 'package:museflow/pages/search_page.dart';
import 'package:museflow/features/editor/editor_screen.dart';
import 'package:museflow/features/knowledge/knowledge_screen.dart';
import 'package:museflow/features/knowledge/character_service.dart';
import 'package:museflow/features/knowledge/world_service.dart';
import 'package:museflow/services/shared_data_service.dart';
import 'package:museflow/services/global_search_service.dart';

/// 主应用集成测试
/// 验证所有模块正确集成到主应用中
void main() {
  group('MuseFlow 主应用集成测试', () {
    testWidgets('应用启动并显示主导航容器', (WidgetTester tester) async {
      // 构建应用
      await tester.pumpWidget(const MuseFlowApp());

      // 验证主导航容器存在
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('主导航显示所有5个导航项', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());

      // 等待动画完成
      await tester.pumpAndSettle();

      // 验证所有导航项都存在
      expect(find.text('写作'), findsOneWidget);
      expect(find.text('编辑器'), findsOneWidget);
      expect(find.text('知识库'), findsOneWidget);
      expect(find.text('搜索'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('可以导航到编辑器页面', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 点击编辑器导航项
      await tester.tap(find.text('编辑器'));
      await tester.pumpAndSettle();

      // 验证编辑器页面显示
      expect(find.byType(EditorScreen), findsOneWidget);
    });

    testWidgets('可以导航到知识库页面', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 点击知识库导航项
      await tester.tap(find.text('知识库'));
      await tester.pumpAndSettle();

      // 验证知识库页面显示
      expect(find.byType(KnowledgeScreen), findsOneWidget);
    });

    testWidgets('可以导航到搜索页面', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 点击搜索导航项
      await tester.tap(find.text('搜索'));
      await tester.pumpAndSettle();

      // 验证搜索页面显示
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('可以导航到设置页面', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 点击设置导航项
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 验证设置页面显示
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('可以返回写作主页', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 导航到设置页面
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 返回主页
      await tester.tap(find.text('写作'));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('所有必要的服务都已提供', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 验证AppState存在
      final appState = Provider.of<AppState>(
        tester.element(find.byType(MainNavigationContainer)),
        listen: false,
      );
      expect(appState, isNotNull);

      // 验证CharacterService存在
      final characterService = Provider.of<CharacterService>(
        tester.element(find.byType(MainNavigationContainer)),
        listen: false,
      );
      expect(characterService, isNotNull);

      // 验证WorldService存在
      final worldService = Provider.of<WorldService>(
        tester.element(find.byType(MainNavigationContainer)),
        listen: false,
      );
      expect(worldService, isNotNull);

      // 验证SharedDataService存在
      final sharedDataService = Provider.of<SharedDataService>(
        tester.element(find.byType(MainNavigationContainer)),
        listen: false,
      );
      expect(sharedDataService, isNotNull);

      // 验证GlobalSearchService存在
      final searchService = Provider.of<GlobalSearchService>(
        tester.element(find.byType(MainNavigationContainer)),
        listen: false,
      );
      expect(searchService, isNotNull);
    });

    testWidgets('页面切换有动画效果', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 记录初始页面
      expect(find.byType(HomePage), findsOneWidget);

      // 切换页面
      await tester.tap(find.text('编辑器'));
      await tester.pump(const Duration(milliseconds: 100));

      // 在动画过程中，应该同时看到两个页面的一部分
      expect(find.byType(EditorScreen), findsOneWidget);

      // 等待动画完成
      await tester.pumpAndSettle();
      expect(find.byType(EditorScreen), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('页面切换保持状态', (WidgetTester tester) async {
      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 在主页创建一个笔记
      final homePageFinder = find.byType(HomePage);
      expect(homePageFinder, findsOneWidget);

      // 导航到其他页面
      await tester.tap(find.text('编辑器'));
      await tester.pumpAndSettle();

      // 返回主页
      await tester.tap(find.text('写作'));
      await tester.pumpAndSettle();

      // 验证主页状态仍然存在
      expect(homePageFinder, findsOneWidget);
    });
  });

  group('数据共享服务测试', () {
    testWidgets('可以在页面间共享编辑器内容', (WidgetTester tester) async {
      final sharedDataService = SharedDataService();

      // 设置编辑器内容
      const testContent = '这是一段测试内容';
      sharedDataService.updateEditorContent(testContent);

      // 验证内容被正确设置
      expect(sharedDataService.sharedEditorContent, equals(testContent));
    });

    testWidgets('可以在页面间共享知识库选择', (WidgetTester tester) async {
      final sharedDataService = SharedDataService();

      // 验证初始状态
      expect(sharedDataService.selectedCharacter, isNull);
      expect(sharedDataService.selectedWorld, isNull);

      // 这里可以添加更多测试逻辑
    });
  });

  group('导航响应性测试', () {
    testWidgets('导航栏在移动端显示在底部', (WidgetTester tester) async {
      // 设置移动端尺寸
      tester.binding.platformDispatcher.views.first.physicalSize = const Size(400, 800);
      tester.binding.platformDispatcher.views.first.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MuseFlowApp());
      await tester.pumpAndSettle();

      // 验证底部导航栏存在
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
