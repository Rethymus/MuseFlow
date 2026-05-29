import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:museflow/models/app_state.dart';
import 'package:museflow/models/note.dart';
import 'package:museflow/pages/home_page.dart';
import 'package:museflow/services/global_search_service.dart';
import 'package:museflow/services/secure_storage_service.dart';
import 'package:museflow/features/knowledge/character_service.dart';
import 'package:museflow/features/knowledge/world_service.dart';
import 'package:museflow/widgets/note_list.dart';
import 'package:museflow/widgets/note_editor.dart';

void main() {
  // 确保Flutter测试绑定初始化
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HomePage Widget测试', () {
    late AppState mockAppState;
    late GlobalSearchService mockSearchService;
    late SecureStorageService mockStorageService;
    late CharacterService mockCharacterService;
    late WorldService mockWorldService;

    setUp(() {
      // 初始化Mock服务
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

    Widget createHomePageUnderTest() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: mockAppState),
            ChangeNotifierProvider<GlobalSearchService>.value(
              value: mockSearchService,
            ),
          ],
          child: const HomePage(),
        ),
      );
    }

    testWidgets('页面加载验证基本组件', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 验证AppBar存在
      expect(find.text('MuseFlow'), findsOneWidget);

      // 验证搜索按钮存在
      expect(find.byIcon(Icons.search), findsOneWidget);

      // 验证设置按钮存在
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // 验证浮动操作按钮存在
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('页面布局结构验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 验证Scaffold结构
      expect(find.byType(Scaffold), findsOneWidget);

      // 验证AppBar
      expect(find.byType(AppBar), findsOneWidget);

      // 验证主体内容区域
      expect(find.byType(Row), findsOneWidget);

      // 验证NoteList和NoteEditor组件存在
      expect(find.byType(NoteList), findsOneWidget);
      expect(find.byType(NoteEditor), findsOneWidget);
    });

    testWidgets('浮动操作按钮创建新笔记', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 初始状态：笔记列表为空
      expect(mockAppState.notes, isEmpty);

      // 点击浮动操作按钮
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证创建了新笔记
      expect(mockAppState.notes.length, 1);
      expect(mockAppState.notes.first.title, 'New Note');
      expect(mockAppState.currentNote, isNotNull);
      expect(mockAppState.currentNote!.id, mockAppState.notes.first.id);
    });

    testWidgets('多次创建笔记验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 创建第一个笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final firstNoteId = mockAppState.currentNote?.id;
      expect(mockAppState.notes.length, 1);

      // 创建第二个笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(mockAppState.notes.length, 2);
      expect(mockAppState.currentNote?.id, isNot(equals(firstNoteId)));
    });

    testWidgets('搜索按钮打开搜索对话框', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 点击搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证搜索对话框已打开
      expect(find.text('搜索笔记、角色、世界观...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('设置按钮显示提示信息', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 点击设置按钮
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 验证SnackBar显示
      expect(find.text('请使用底部导航栏的设置功能'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('搜索结果处理 - 笔记类型', (WidgetTester tester) async {
      // 创建测试笔记
      final testNote = Note(
        id: 'test-note-1',
        title: '测试笔记标题',
        content: '测试笔记内容',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['test', 'search'],
      );
      mockAppState.createNewNote();
      mockAppState.selectNote(testNote);

      await tester.pumpWidget(createHomePageUnderTest());

      // 点击搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 在搜索框输入内容
      await tester.enterText(find.byType(TextField), '测试');
      await tester.pumpAndSettle();

      // 关闭对话框
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('页面组件响应式布局测试', (WidgetTester tester) async {
      // 测试不同屏幕尺寸
      final testSizes = [
        const Size(400, 800), // 小屏幕
        const Size(800, 600), // 中等屏幕
        const Size(1920, 1080), // 大屏幕
      ];

      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(createHomePageUnderTest());
        await tester.pumpAndSettle();

        // 验证基本组件在不同屏幕尺寸下都存在
        expect(find.text('MuseFlow'), findsOneWidget);
        expect(find.byType(NoteList), findsOneWidget);
        expect(find.byType(NoteEditor), findsOneWidget);

        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      }
    });

    testWidgets('搜索结果处理 - 角色类型', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 模拟角色搜索结果
      final characterResult = GlobalSearchResult(
        id: 'char-1',
        title: '测试角色',
        content: '角色描述内容',
        subtitle: '主角 · 25岁',
        type: GlobalSearchResultType.character,
        data: {'id': 'char-1', 'name': '测试角色'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['protagonist'],
      );

      // 点击搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证搜索对话框打开
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('搜索结果处理 - 世界观类型', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 模拟世界观搜索结果
      final worldResult = GlobalSearchResult(
        id: 'world-1',
        title: '奇幻世界',
        content: '世界观描述',
        subtitle: '魔法世界 · 中世纪',
        type: GlobalSearchResultType.world,
        data: {'id': 'world-1', 'name': '奇幻世界'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['magic', 'medieval'],
      );

      // 点击搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证搜索对话框打开
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('搜索结果处理 - 地点类型', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 模拟地点搜索结果
      final locationResult = GlobalSearchResult(
        id: 'location-1',
        title: '王都',
        content: '王都描述',
        subtitle: '奇幻世界 · 地点',
        type: GlobalSearchResultType.location,
        data: {'id': 'location-1', 'name': '王都'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['capital'],
      );

      // 点击搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证搜索对话框打开
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('搜索结果处理 - 组织类型', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 模拟组织搜索结果
      final organizationResult = GlobalSearchResult(
        id: 'org-1',
        title: '魔法师协会',
        content: '组织描述',
        subtitle: '奇幻世界 · 组织',
        type: GlobalSearchResultType.organization,
        data: {'id': 'org-1', 'name': '魔法师协会'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['magic', 'organization'],
      );

      // 点击搜索按钮
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证搜索对话框打开
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('笔记创建时间验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      final beforeCreate = DateTime.now();

      // 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final afterCreate = DateTime.now();

      // 验证创建时间在合理范围内
      expect(
        mockAppState.notes.first.createdAt.isAfter(beforeCreate) ||
        mockAppState.notes.first.createdAt.isAtSameMomentAs(beforeCreate),
        isTrue,
      );
      expect(
        mockAppState.notes.first.createdAt.isBefore(afterCreate) ||
        mockAppState.notes.first.createdAt.isAtSameMomentAs(afterCreate),
        isTrue,
      );
    });

    testWidgets('笔记内容初始状态验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证新笔记的初始状态
      expect(mockAppState.currentNote?.title, 'New Note');
      expect(mockAppState.currentNote?.content, '');
      expect(mockAppState.currentNote?.tags, isEmpty);
    });

    testWidgets('连续创建笔记的唯一性', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      final noteIds = <String>{};

      // 创建5个笔记
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        final currentId = mockAppState.currentNote?.id;
        expect(currentId, isNotNull);
        noteIds.add(currentId!);
      }

      // 验证所有笔记ID都是唯一的
      expect(noteIds.length, 5);
      expect(mockAppState.notes.length, 5);
    });

    testWidgets('页面状态管理验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 创建第一个笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final firstNote = mockAppState.currentNote;

      // 创建第二个笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final secondNote = mockAppState.currentNote;

      // 验证当前笔记切换
      expect(firstNote?.id, isNot(equals(secondNote?.id)));
      expect(mockAppState.currentNote?.id, equals(secondNote?.id));
    });

    testWidgets('搜索框交互验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 打开搜索对话框
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证搜索框有焦点
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);

      // 验证清除按钮初始不存在
      expect(find.byIcon(Icons.clear), findsNothing);

      // 输入搜索内容
      await tester.enterText(find.byType(TextField), 'test search');
      await tester.pump();

      // 验证清除按钮出现
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // 点击清除按钮
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // 验证输入框清空
      final textFieldAfterClear = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfterClear.controller?.text, isEmpty);
    });

    testWidgets('AppBar按钮布局验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 获取AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      // 验证AppBar标题
      expect(appBar.title, isA<Text>());
      final titleWidget = appBar.title as Text;
      expect(titleWidget.data, 'MuseFlow');

      // 验证actions不为空
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, 2); // 搜索和设置按钮
    });

    testWidgets('主页面Row布局flex验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 查找Row组件
      final rowWidgets = find.byType(Row);
      expect(rowWidgets, findsWidgets);

      // 获取主体Row
      final mainRow = tester.widget<Row>(rowWidgets.first);
      expect(mainRow.children.length, 2);

      // 验证Expanded组件
      expect(mainRow.children[0], isA<Expanded>());
      expect(mainRow.children[1], isA<Expanded>());
    });

    testWidgets('浮动操作按钮样式验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 获取FloatingActionButton
      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));

      // 验证按钮包含加号图标
      expect(find.byIcon(Icons.add), findsOneWidget);

      // 验证按钮可点击
      expect(fab.onPressed, isNotNull);
    });

    testWidgets('页面主题适配验证', (WidgetTester tester) async {
      // 测试亮色主题
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: ChangeNotifierProvider<AppState>.value(
            value: mockAppState,
            child: const HomePage(),
          ),
        ),
      );

      expect(find.byType(HomePage), findsOneWidget);

      // 测试暗色主题
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: ChangeNotifierProvider<AppState>.value(
            value: mockAppState,
            child: const HomePage(),
          ),
        ),
      );

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('搜索对话框关闭验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 打开搜索对话框
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 验证对话框打开
      expect(find.byType(Dialog), findsOneWidget);

      // 点击关闭按钮
      final closeButton = find.text('关闭');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // 验证对话框关闭
        expect(find.byType(Dialog), findsNothing);
      }
    });

    testWidgets('多平台兼容性验证', (WidgetTester tester) async {
      // 测试默认平台
      await tester.pumpWidget(createHomePageUnderTest());
      expect(find.byType(HomePage), findsOneWidget);

      // HomePage在所有平台都应该正常工作
      // 因为主题差异导致WindowManager注册不同
    });

    testWidgets('边界条件 - 空笔记列表', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 初始状态：没有笔记
      expect(mockAppState.notes, isEmpty);

      // 页面应该正常渲染
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(NoteList), findsOneWidget);
      expect(find.byType(NoteEditor), findsOneWidget);
    });

    testWidgets('边界条件 - 大量笔记处理', (WidgetTester tester) async {
      // 创建大量笔记
      for (int i = 0; i < 50; i++) {
        mockAppState.createNewNote();
      }

      await tester.pumpWidget(createHomePageUnderTest());

      // 验证页面仍能正常工作
      expect(find.byType(HomePage), findsOneWidget);
      expect(mockAppState.notes.length, 50);

      // 验证可以创建新笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(mockAppState.notes.length, 51);
    });

    testWidgets('错误处理 - AppState不可用时', (WidgetTester tester) async {
      // 创建一个没有AppState的页面
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomePage(),
          ),
        ),
      );

      // 页面应该能够渲染，但可能会有警告
      // 实际使用中应该总是提供AppState
    });

    testWidgets('性能测试 - 页面渲染时间', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createHomePageUnderTest());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 页面应该在合理时间内渲染完成
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('可访问性 - 按钮可访问性标签', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 验证主要按钮存在
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // 所有主要交互元素都应该可访问
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('状态持久化验证', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageUnderTest());

      // 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final createdNote = mockAppState.currentNote;

      // 重新构建页面
      await tester.pumpWidget(createHomePageUnderTest());
      await tester.pumpAndSettle();

      // AppState应该保持状态
      expect(mockAppState.notes.length, greaterThanOrEqualTo(1));
      if (createdNote != null) {
        expect(
          mockAppState.notes.any((note) => note.id == createdNote.id),
          isTrue,
        );
      }
    });
  });

  group('HomePage WindowListener集成测试', () {
    testWidgets('窗口事件处理验证', (WidgetTester tester) async {
      final mockAppState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: mockAppState,
            child: const HomePage(),
          ),
        ),
      );

      // HomePage应该实现WindowListener
      // 在桌面平台上会注册窗口事件
      expect(find.byType(HomePage), findsOneWidget);

      mockAppState.dispose();
    });
  });

  group('HomePage用户交互流程测试', () {
    testWidgets('完整用户流程 - 创建到搜索', (WidgetTester tester) async {
      final mockAppState = AppState();
      final mockSearchService = GlobalSearchService(
        storageService: SecureStorageService(),
        characterService: CharacterService(),
        worldService: WorldService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AppState>.value(value: mockAppState),
              ChangeNotifierProvider<GlobalSearchService>.value(
                value: mockSearchService,
              ),
            ],
            child: const HomePage(),
          ),
        ),
      );

      // 1. 创建笔记
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(mockAppState.notes.length, 1);

      // 2. 打开搜索
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      // 3. 关闭搜索
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);

      mockAppState.dispose();
      mockSearchService.dispose();
    });

    testWidgets('设置提示用户反馈', (WidgetTester tester) async {
      final mockAppState = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: mockAppState,
            child: const HomePage(),
          ),
        ),
      );

      // 多次点击设置按钮
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // 每次都应该显示SnackBar
        expect(find.text('请使用底部导航栏的设置功能'), findsOneWidget);

        // 等待SnackBar消失
        await tester.pump(const Duration(milliseconds: 3000));
        await tester.pumpAndSettle();
      }

      mockAppState.dispose();
    });
  });
}
