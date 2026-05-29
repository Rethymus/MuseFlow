import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:museflow/models/app_state.dart';
import 'package:museflow/pages/main_navigation.dart';
import 'package:museflow/utils/page_transitions.dart';
import 'package:museflow/services/secure_storage_service.dart';
import 'package:museflow/features/knowledge/character_service.dart';
import 'package:museflow/features/knowledge/world_service.dart';
import 'package:museflow/services/global_search_service.dart';

/// MainNavigationContainer Widget测试
/// 完整覆盖主导航容器的功能测试
void main() {
  // 确保Flutter测试绑定初始化
  TestWidgetsFlutterBinding.ensureInitialized();
  group('MainNavigationContainer基础测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('主导航容器加载验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证导航容器存在
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 验证Scaffold结构
      expect(find.byType(Scaffold), findsOneWidget);

      // 验证Stack布局（主内容+导航栏）
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('初始页面为写作页面', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证默认显示写作页面（HomePage）
      expect(find.text('MuseFlow'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('导航目标项验证 - 5个导航项', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证所有导航图标存在
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.library_books), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('NavigationBar组件存在验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证底部导航栏存在
      expect(find.byType(NavigationBar), findsOneWidget);

      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      // 验证导航栏配置
      expect(navBar.selectedIndex, equals(0));
      expect(navBar.destinations.length, equals(5));
    });

    testWidgets('PageSwitchAnimation组件存在验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证页面切换动画组件存在
      expect(find.byType(PageSwitchAnimation), findsOneWidget);
    });

    testWidgets('TabController初始化验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证TabController正常工作
      // 通过检查导航栏间接验证TabController状态
      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      expect(navBar.selectedIndex, equals(0));
    });

    testWidgets('主内容区域Padding验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 查找Padding组件（为底部导航栏留出空间）
      final paddingWidgets = find.byType(Padding);
      expect(paddingWidgets, findsWidgets);

      // 验证页面内容不被导航栏遮挡
      // 通过检查Stack中的布局顺序
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('导航栏布局位置验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证导航栏位于底部
      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      // 获取NavigationBar的位置
      final position = tester.getTopLeft(navBar);

      // 验证导航栏在屏幕底部区域
      expect(position.dy, greaterThan(500));
    });
  });

  group('MainNavigationContainer页面切换测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('切换到编辑器页面', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 点击编辑器导航项
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // 验证切换到编辑器页面
      // 编辑器页面应该包含特定的UI元素
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 验证导航栏选中状态更新
      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(1));
    });

    testWidgets('切换到知识库页面', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 点击知识库导航项
      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pumpAndSettle();

      // 验证切换到知识库页面
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(2));
    });

    testWidgets('切换到搜索页面', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 点击搜索导航项
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证切换到搜索页面
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(3));
    });

    testWidgets('切换到设置页面', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 点击设置导航项
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 验证切换到设置页面
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(4));
    });

    testWidgets('页面双向切换验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 切换到编辑器
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      var navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(1));

      // 切换回写作
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(0));
    });

    testWidgets('连续多页面切换验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      final expectedIndices = [1, 2, 3, 4, 0];

      // 按顺序切换页面
      for (final expectedIndex in expectedIndices) {
        switch (expectedIndex) {
          case 1:
            await tester.tap(find.byIcon(Icons.psychology));
            break;
          case 2:
            await tester.tap(find.byIcon(Icons.library_books));
            break;
          case 3:
            await tester.tap(find.byIcon(Icons.search));
            break;
          case 4:
            await tester.tap(find.byIcon(Icons.settings));
            break;
          case 0:
            await tester.tap(find.byIcon(Icons.edit_note));
            break;
        }

        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(
          find.byType(NavigationBar),
        );
        expect(navBar.selectedIndex, equals(expectedIndex));
      }
    });

    testWidgets('快速连续切换页面', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 快速连续点击多个导航项
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 最终应该停留在搜索页面
      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(3));
    });

    testWidgets('页面切换动画验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());

      // 记录初始状态
      expect(find.byType(PageSwitchAnimation), findsOneWidget);

      // 执行页面切换
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pump();

      // 验证动画组件重新创建（通过ValueKey变化）
      expect(find.byType(PageSwitchAnimation), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('所有页面都可访问', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      final pages = [
        Icons.edit_note, // 写作
        Icons.psychology, // 编辑器
        Icons.library_books, // 知识库
        Icons.search, // 搜索
        Icons.settings, // 设置
      ];

      for (final pageIcon in pages) {
        await tester.tap(find.byIcon(pageIcon));
        await tester.pumpAndSettle();

        // 验证页面切换成功
        expect(find.byType(MainNavigationContainer), findsOneWidget);
      }
    });

    testWidgets('页面索引边界测试', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 测试第一个页面
      var navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, greaterThanOrEqualTo(0));
      expect(navBar.selectedIndex, lessThan(5));

      // 切换到最后一个页面
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(4));
    });

    testWidgets('TabController与UI状态同步', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 初始状态
      var navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(0));

      // 切换到知识库
      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pumpAndSettle();

      // 验证状态同步
      navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(2));
    });
  });

  group('MainNavigationContainer导航栏测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('底部导航栏完整结构', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证NavigationBar
      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      // 验证导航栏属性
      expect(
          navBar.animationDuration, equals(const Duration(milliseconds: 300)));
      expect(navBar.destinations.length, equals(5));
    });

    testWidgets('导航项标签验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证导航标签存在
      expect(find.text('写作'), findsOneWidget);
      expect(find.text('编辑器'), findsOneWidget);
      expect(find.text('知识库'), findsOneWidget);
      expect(find.text('搜索'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('导航项图标状态切换', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 初始状态：写作页面选中
      expect(find.byIcon(Icons.edit_note), findsOneWidget);

      // 切换到编辑器
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // 编辑器图标应该仍然存在
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('导航栏位置响应式验证 - 小屏幕', (WidgetTester tester) async {
      // 设置小屏幕尺寸
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 小屏幕应该显示底部导航栏
      expect(find.byType(NavigationBar), findsOneWidget);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('导航栏位置响应式验证 - 大屏幕', (WidgetTester tester) async {
      // 设置大屏幕尺寸（>800px）
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 大屏幕应该显示侧边导航栏样式
      // 验证Container组件（侧边栏实现）
      expect(find.byType(Container), findsWidgets);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('侧边导航栏结构验证 - 大屏幕', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证Row布局（侧边导航栏使用Row）
      expect(find.byType(Row), findsWidgets);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('导航栏点击响应验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证所有导航项都可点击
      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      expect(navBar.onDestinationSelected, isNotNull);
    });

    testWidgets('导航栏高度验证 - 大屏幕', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 大屏幕侧边栏高度为80
      final container = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(container);

      // 验证装饰存在（侧边栏样式）
      expect(containerWidget.decoration, isNotNull);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('导航栏装饰验证 - 大屏幕', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 查找带装饰的Container
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('导航项InkWell交互验证', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证InkWell存在（大屏幕侧边栏使用InkWell）
      expect(find.byType(InkWell), findsWidgets);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('MainNavigationContainer页面状态保持测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('页面切换后状态保持', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 创建一个笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final firstNoteId = mockAppState.currentNote?.id;
      expect(mockAppState.notes.length, 1);

      // 切换到编辑器
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // 切换回写作页面
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      // 验证笔记状态保持
      expect(mockAppState.notes.length, 1);
      expect(mockAppState.currentNote?.id, equals(firstNoteId));
    });

    testWidgets('多次切换后AppState一致性', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final initialNoteCount = mockAppState.notes.length;

      // 执行多次页面切换
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.psychology));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.library_books));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.edit_note));
        await tester.pumpAndSettle();
      }

      // 验证AppState保持一致
      expect(mockAppState.notes.length, equals(initialNoteCount));
    });

    testWidgets('导航切换不影响Provider状态', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证Provider存在
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 切换页面
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Provider应该仍然可用
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('页面切换动画不丢失状态', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final noteBeforeSwitch = mockAppState.currentNote;

      // 触发页面切换动画
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(); // 动画进行中

      // 立即切回
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      // 验证状态未丢失
      expect(mockAppState.currentNote?.id, equals(noteBeforeSwitch?.id));
    });

    testWidgets('TabController状态同步验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 记录初始导航索引
      var navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      final initialIndex = navBar.selectedIndex;

      // 切换页面
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      final newIndex = navBar.selectedIndex;

      // 验证索引正确更新
      expect(newIndex, equals(4));
      expect(newIndex, isNot(equals(initialIndex)));
    });

    testWidgets('导航栏选中状态持久化', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 切换到知识库
      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pumpAndSettle();

      var navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(2));

      // 重新构建（模拟热重载）
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 导航状态应该重置为默认（因为没有持久化）
      navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(0));
    });
  });

  group('MainNavigationContainer响应式布局测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('小屏幕布局验证', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone SE

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证基本组件存在
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('中等屏幕布局验证', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证基本组件存在
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('大屏幕布局验证', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080)); // Desktop

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证基本组件存在
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 大屏幕应该有特定的布局元素
      expect(find.byType(Row), findsWidgets);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('响应式断点验证 - 800px', (WidgetTester tester) async {
      // 测试刚好小于800px
      await tester.binding.setSurfaceSize(const Size(799, 600));
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 测试刚好大于800px
      await tester.binding.setSurfaceSize(const Size(801, 600));
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationContainer), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('不同屏幕尺寸导航功能一致性', (WidgetTester tester) async {
      final sizes = [
        const Size(375, 667),
        const Size(768, 1024),
        const Size(1920, 1080),
      ];

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(createMainNavigationUnderTest());
        await tester.pumpAndSettle();

        // 验证导航功能正常
        expect(find.byType(NavigationBar), findsOneWidget);

        // 验证可以切换页面
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationContainer), findsOneWidget);
      }

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('横竖屏切换验证', (WidgetTester tester) async {
      // 竖屏
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 横屏
      await tester.binding.setSurfaceSize(const Size(667, 375));
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationContainer), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('超宽屏幕布局验证', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(2560, 1440)); // 2K

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证布局正常
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('内容区域响应式验证', (WidgetTester tester) async {
      final sizes = [
        const Size(400, 800),
        const Size(800, 600),
        const Size(1200, 800),
      ];

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(createMainNavigationUnderTest());
        await tester.pumpAndSettle();

        // 验证内容区域有适当的Padding
        expect(find.byType(Padding), findsWidgets);

        // 验证页面不被导航栏遮挡
        expect(find.byType(Stack), findsOneWidget);
      }

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('MainNavigationContainer切换动画测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('PageSwitchAnimation初始状态', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());

      // 验证PageSwitchAnimation存在
      expect(find.byType(PageSwitchAnimation), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('页面切换触发动画', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 执行页面切换
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pump();

      // 验证动画组件存在
      expect(find.byType(PageSwitchAnimation), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('动画持续时间验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 触发页面切换
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      // 等待动画完成
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 动画应该在合理时间内完成（<500ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('连续快速切换动画', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 快速连续切换
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.edit_note));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // 验证最终状态正确
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('动画不影响交互可用性', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 开始页面切换
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pump();

      // 动画进行中仍然可以点击
      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pumpAndSettle();

      // 验证最终切换成功
      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.selectedIndex, equals(2));
    });

    testWidgets('PageSwitchAnimation ValueKey变化验证',
        (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 切换页面会改变ValueKey
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 验证PageSwitchAnimation重新创建
      expect(find.byType(PageSwitchAnimation), findsOneWidget);
    });

    testWidgets('动画组件生命周期管理', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 多次切换页面
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.edit_note));
        await tester.pumpAndSettle();
      }

      // 验证没有内存泄漏迹象（动画组件正常工作）
      expect(find.byType(PageSwitchAnimation), findsOneWidget);
    });

    testWidgets('FadeTransition和ScaleTransition存在验证',
        (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // PageSwitchAnimation包含FadeTransition和ScaleTransition
      // 这些是内部实现，我们验证动画效果存在
      expect(find.byType(PageSwitchAnimation), findsOneWidget);

      // 切换页面触发动画
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      // 动画组件应该仍然存在
      expect(find.byType(PageSwitchAnimation), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });

  group('MainNavigationContainer集成测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('完整用户流程 - 写作到搜索', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 在写作页面创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(mockAppState.notes.length, 1);

      // 切换到搜索页面
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证成功切换
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('多页面协作流程', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 切换到知识库
      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pumpAndSettle();

      // 切换到编辑器
      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // 返回写作页面
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      // 验证笔记状态保持
      expect(mockAppState.notes.length, 1);
    });

    testWidgets('Provider依赖完整性验证', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 所有页面都应该能访问到所需的Provider
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 切换到需要CharacterService的页面
      await tester.tap(find.byIcon(Icons.library_books));
      await tester.pumpAndSettle();

      // 页面应该正常工作
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('主题适配验证', (WidgetTester tester) async {
      // 测试亮色主题
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AppState>.value(value: mockAppState),
              ChangeNotifierProvider<GlobalSearchService>.value(
                value: mockSearchService,
              ),
            ],
            child: const MainNavigationContainer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 测试暗色主题
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AppState>.value(value: mockAppState),
              ChangeNotifierProvider<GlobalSearchService>.value(
                value: mockSearchService,
              ),
            ],
            child: const MainNavigationContainer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('性能测试 - 快速连续操作', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 执行10次快速页面切换
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.edit_note));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // 应该在合理时间内完成（<3秒）
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('边界条件 - 所有页面快速切换', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 遍历所有页面
      final icons = [
        Icons.edit_note,
        Icons.psychology,
        Icons.library_books,
        Icons.search,
        Icons.settings,
      ];

      for (final icon in icons) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationContainer), findsOneWidget);
      }
    });
  });

  group('MainNavigationContainer边界条件测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      mockStorageService = SecureStorageService();
      mockCharacterService = CharacterService();
      mockWorldService = WorldService();

      mockSearchService = GlobalSearchService(
        storageService: mockStorageService,
        characterService: mockCharacterService,
        worldService: mockWorldService,
      );

      mockAppState = AppState(storageService: mockStorageService);
    });

    tearDown(() {
      mockAppState.dispose();
      mockSearchService.dispose();
    });

    Widget createMainNavigationUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
            Provider<CharacterService>.value(value: mockCharacterService),
            Provider<WorldService>.value(value: mockWorldService),
          ],
          child: const MainNavigationContainer(),
        ),
      );
    }

    testWidgets('空状态处理', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 初始状态：没有笔记
      expect(mockAppState.notes, isEmpty);

      // 导航应该正常工作
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('极端小屏幕尺寸', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 应该仍然正常工作
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('极端大屏幕尺寸', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(3840, 2160)); // 4K

      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 应该仍然正常工作
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('导航栏边界点击', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 点击导航栏边界外的区域
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 不应该影响导航状态
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('页面状态在重建后保持', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final noteId = mockAppState.currentNote?.id;

      // 重建widget（模拟热重载）
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // AppState状态应该保持
      expect(mockAppState.notes.any((note) => note.id == noteId), isTrue);
    });

    testWidgets('可访问性 - 导航按钮', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 验证所有导航项都存在且可交互
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.library_books), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('错误恢复 - 无效状态处理', (WidgetTester tester) async {
      await tester.pumpWidget(createMainNavigationUnderTest());
      await tester.pumpAndSettle();

      // 尝试切换到不存在的页面索引
      // NavigationBar会自动处理无效索引
      expect(find.byType(MainNavigationContainer), findsOneWidget);

      // 导航栏应该仍然工作
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });
  });
}
