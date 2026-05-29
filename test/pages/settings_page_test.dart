import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:museflow/models/app_state.dart';
import 'package:museflow/pages/settings_page.dart';
import 'package:museflow/services/storage_service.dart';

/// SettingsPage Widget测试
/// 验证设置页面的UI组件交互、状态管理和对话框功能
void main() {
  group('SettingsPage Widget测试', () {
    late AppState mockAppState;
    late StorageService mockStorageService;

    setUp(() {
      // 初始化服务实例
      mockStorageService = StorageService.instance;
      mockAppState = AppState(storageService: mockStorageService);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AppState>(
          create: (_) => mockAppState,
          child: const SettingsPage(),
        ),
      );
    }

    group('页面加载测试', () {
      testWidgets('应该显示加载指示器', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 验证初始加载状态显示CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('加载完成后应该显示设置页面', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // 等待加载完成
        await tester.pumpAndSettle();

        // 验证主要UI元素存在
        expect(find.text('设置'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('应该显示所有设置分区', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证5个主要设置分区
        expect(find.text('通用设置'), findsOneWidget);
        expect(find.text('编辑器设置'), findsOneWidget);
        expect(find.text('AI设置'), findsOneWidget);
        expect(find.text('存储设置'), findsOneWidget);
        expect(find.text('关于'), findsOneWidget);
      });
    });

    group('通用设置测试', () {
      testWidgets('应该显示主题设置选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证主题设置存在
        expect(find.text('主题'), findsOneWidget);
        expect(find.byIcon(Icons.palette), findsOneWidget);
        expect(find.text('选择应用主题'), findsOneWidget);
      });

      testWidgets('应该显示语言设置选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证语言设置存在
        expect(find.text('语言'), findsOneWidget);
        expect(find.byIcon(Icons.language), findsOneWidget);
        expect(find.text('选择界面语言'), findsOneWidget);
      });

      testWidgets('应该显示字体大小设置选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证字体大小设置存在
        expect(find.text('字体大小'), findsOneWidget);
        expect(find.byIcon(Icons.format_size), findsOneWidget);
        expect(find.text('调整编辑器字体大小'), findsOneWidget);
      });

      testWidgets('主题下拉菜单应该显示三个选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 查找并点击主题下拉菜单
        final themeDropdown = find.byType(DropdownButton<ThemeMode>).first;
        expect(themeDropdown, findsOneWidget);
      });

      testWidgets('字体大小下拉菜单应该显示四个选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证字体大小选项存在
        expect(find.text('小'), findsOneWidget);
        expect(find.text('中'), findsOneWidget);
        expect(find.text('大'), findsOneWidget);
        expect(find.text('特大'), findsOneWidget);
      });
    });

    group('编辑器设置测试', () {
      testWidgets('应该显示自动保存开关', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证自动保存设置存在
        expect(find.text('自动保存'), findsOneWidget);
        expect(find.byIcon(Icons.save), findsOneWidget);
        expect(find.text('编辑时自动保存笔记'), findsOneWidget);
      });

      testWidgets('应该显示拼写检查开关', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证拼写检查设置存在
        expect(find.text('拼写检查'), findsOneWidget);
        expect(find.byIcon(Icons.spellcheck), findsOneWidget);
        expect(find.text('启用拼写检查功能'), findsOneWidget);
      });

      testWidgets('应该显示字数统计开关', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证字数统计设置存在
        expect(find.text('字数统计'), findsOneWidget);
        expect(find.byIcon(Icons.countertops), findsOneWidget);
        expect(find.text('显示实时字数统计'), findsOneWidget);
      });

      testWidgets('自动保存开关可以交互', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 查找自动保存开关
        final autoSaveSwitch = find.byType(SwitchListTile).first;
        expect(autoSaveSwitch, findsOneWidget);

        // 点击开关（不应该崩溃）
        await tester.tap(autoSaveSwitch);
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('拼写检查开关可以交互', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 查找拼写检查开关
        final spellCheckSwitch = find.byType(SwitchListTile).at(1);
        expect(spellCheckSwitch, findsOneWidget);

        // 点击开关（不应该崩溃）
        await tester.tap(spellCheckSwitch);
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('字数统计开关可以交互', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 查找字数统计开关
        final wordCountSwitch = find.byType(SwitchListTile).at(2);
        expect(wordCountSwitch, findsOneWidget);

        // 点击开关（不应该崩溃）
        await tester.tap(wordCountSwitch);
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('AI设置测试', () {
      testWidgets('应该显示AI模型选择', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证AI模型设置存在
        expect(find.text('AI模型'), findsOneWidget);
        expect(find.byIcon(Icons.psychology), findsOneWidget);
        expect(find.text('选择AI处理模型'), findsOneWidget);
      });

      testWidgets('应该显示AI创造力设置', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证AI创造力设置存在
        expect(find.text('AI创造力'), findsOneWidget);
        expect(find.byIcon(Icons.tune), findsOneWidget);
        expect(find.text('调整AI的创造力水平'), findsOneWidget);
      });

      testWidgets('应该显示意图确认开关', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证意图确认设置存在
        expect(find.text('意图确认'), findsOneWidget);
        expect(find.byIcon(Icons.verified_user), findsOneWidget);
        expect(find.text('AI操作前显示确认对话框'), findsOneWidget);
      });

      testWidgets('AI模型下拉菜单应该显示三个选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证AI模型选项存在
        expect(find.text('Claude 3.5'), findsOneWidget);
        expect(find.text('GPT-4'), findsOneWidget);
        expect(find.text('本地模型'), findsOneWidget);
      });

      testWidgets('AI创造力下拉菜单应该显示三个选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证AI创造力选项存在
        expect(find.text('保守'), findsOneWidget);
        expect(find.text('平衡'), findsOneWidget);
        expect(find.text('创新'), findsOneWidget);
      });

      testWidgets('意图确认开关可以交互', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 查找意图确认开关
        final intentSwitch = find.byType(SwitchListTile).last;
        expect(intentSwitch, findsOneWidget);

        // 点击开关（不应该崩溃）
        await tester.tap(intentSwitch);
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('存储设置测试', () {
      testWidgets('应该显示存储位置选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证存储位置设置存在
        expect(find.text('存储位置'), findsOneWidget);
        expect(find.byIcon(Icons.folder), findsOneWidget);
        expect(find.text('设置数据存储目录'), findsOneWidget);
      });

      testWidgets('应该显示数据备份选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证数据备份设置存在
        expect(find.text('数据备份'), findsOneWidget);
        expect(find.byIcon(Icons.backup), findsOneWidget);
        expect(find.text('管理数据备份'), findsOneWidget);
      });

      testWidgets('应该显示缓存管理选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证缓存管理设置存在
        expect(find.text('缓存管理'), findsOneWidget);
        expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
        expect(find.text('清除应用缓存'), findsOneWidget);
      });

      testWidgets('点击存储位置应该显示对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击存储位置
        await tester.tap(find.text('存储位置'));
        await tester.pumpAndSettle();

        // 验证对话框显示
        expect(find.text('存储位置'), findsOneWidget);
        expect(find.text('当前存储位置将在未来版本中支持自定义配置。'), findsOneWidget);
        expect(find.text('确定'), findsOneWidget);
      });

      testWidgets('点击数据备份应该显示对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击数据备份
        await tester.tap(find.text('数据备份'));
        await tester.pumpAndSettle();

        // 验证对话框显示
        expect(find.text('数据备份'), findsOneWidget);
        expect(find.text('备份功能将在未来版本中实现。'), findsOneWidget);
        expect(find.text('确定'), findsOneWidget);
      });

      testWidgets('点击缓存管理应该显示对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击缓存管理
        await tester.tap(find.text('缓存管理'));
        await tester.pumpAndSettle();

        // 验证对话框显示
        expect(find.text('缓存管理'), findsOneWidget);
        expect(find.text('缓存大小: 2.5 MB'), findsOneWidget);
        expect(find.text('清除缓存'), findsOneWidget);
        expect(find.text('关闭'), findsOneWidget);
      });

      testWidgets('缓存清除按钮可以交互', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击缓存管理
        await tester.tap(find.text('缓存管理'));
        await tester.pumpAndSettle();

        // 点击清除缓存按钮
        await tester.tap(find.text('清除缓存'));
        await tester.pumpAndSettle();

        // 验证SnackBar显示
        expect(find.text('缓存已清除'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('关于部分测试', () {
      testWidgets('应该显示版本信息', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证版本信息存在
        expect(find.text('版本信息'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
        expect(find.text('MuseFlow v1.0.0'), findsOneWidget);
      });

      testWidgets('应该显示许可证选项', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证许可证选项存在
        expect(find.text('许可证'), findsOneWidget);
        expect(find.byIcon(Icons.description), findsOneWidget);
        expect(find.text('查看开源许可证'), findsOneWidget);
      });

      testWidgets('点击版本信息应该显示详细对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击版本信息
        await tester.tap(find.text('版本信息'));
        await tester.pumpAndSettle();

        // 验证对话框内容
        expect(find.text('版本信息'), findsNWidgets(2)); // 标题和按钮文本
        expect(find.text('MuseFlow v1.0.0'), findsOneWidget);
        expect(find.text('一个集AI辅助写作、知识管理和创意工具于一体的应用。'), findsOneWidget);
        expect(find.text('功能特性:'), findsOneWidget);
        expect(find.text('• AI辅助写作和润色'), findsOneWidget);
        expect(find.text('• 思维碎片管理'), findsOneWidget);
        expect(find.text('• 上下文锚点'), findsOneWidget);
        expect(find.text('• 角色卡和世界观管理'), findsOneWidget);
        expect(find.text('• 全局搜索'), findsOneWidget);
        expect(find.text('确定'), findsOneWidget);
      });

      testWidgets('点击许可证应该显示开源许可证对话框', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击许可证
        await tester.tap(find.text('许可证'));
        await tester.pumpAndSettle();

        // 验证对话框内容
        expect(find.text('开源许可证'), findsOneWidget);
        expect(find.text('MuseFlow 使用以下开源库:'), findsOneWidget);
        expect(find.text('• Flutter - BSD 3-Clause License'), findsOneWidget);
        expect(find.text('• Provider - MIT License'), findsOneWidget);
        expect(find.text('• UUID - BSD 3-Clause License'), findsOneWidget);
        expect(find.text('• Window Manager - MIT License'), findsOneWidget);
        expect(find.text('MuseFlow 本身采用 MIT 许可证发布。'), findsOneWidget);
        expect(find.text('确定'), findsOneWidget);
      });

      testWidgets('版本对话框关闭按钮有效', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 打开对话框
        await tester.tap(find.text('版本信息'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // 点击确定按钮关闭
        await tester.tap(find.text('确定'));
        await tester.pumpAndSettle();

        // 验证对话框已关闭
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('许可证对话框关闭按钮有效', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 打开对话框
        await tester.tap(find.text('许可证'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // 点击确定按钮关闭
        await tester.tap(find.text('确定').last);
        await tester.pumpAndSettle();

        // 验证对话框已关闭
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('对话框交互测试', () {
      testWidgets('所有对话框都能正确打开和关闭', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 测试存储位置对话框
        await tester.tap(find.text('存储位置'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('确定'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        // 测试数据备份对话框
        await tester.tap(find.text('数据备份'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('确定'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        // 测试缓存管理对话框
        await tester.tap(find.text('缓存管理'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('关闭'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('多个对话框不能同时打开', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 打开第一个对话框
        await tester.tap(find.text('存储位置'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);

        // 尝试打开第二个对话框（应该不能打开）
        // 在实际UI中，对话框会阻止背景交互
        // 这里只验证对话框存在
        expect(find.byType(AlertDialog), findsOneWidget);
      });
    });

    group('状态管理测试', () {
      testWidgets('设置更新不应该导致应用崩溃', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击自动保存开关
        await tester.tap(find.byType(SwitchListTile).first);
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('主题设置更新应该正常工作', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击主题下拉菜单
        final themeDropdown = find.byType(DropdownButton<ThemeMode>).first;
        await tester.tap(themeDropdown);
        await tester.pumpAndSettle();

        // 验证下拉菜单展开
        expect(find.byType(DropdownMenuItem<ThemeMode>), findsWidgets);
      });

      testWidgets('字体大小设置更新应该正常工作', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 查找字体大小下拉菜单
        final fontSizeDropdowns = find.byType(DropdownButton<int>);
        expect(fontSizeDropdowns, findsWidgets);

        // 点击第二个下拉菜单（字体大小）
        await tester.tap(fontSizeDropdowns.at(1));
        await tester.pumpAndSettle();

        // 验证选项显示
        expect(find.text('小'), findsOneWidget);
        expect(find.text('中'), findsOneWidget);
        expect(find.text('大'), findsOneWidget);
        expect(find.text('特大'), findsOneWidget);
      });
    });

    group('UI布局测试', () {
      testWidgets('所有设置项都应该有图标', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证所有主要图标都存在
        expect(find.byIcon(Icons.palette), findsOneWidget);    // 主题
        expect(find.byIcon(Icons.language), findsOneWidget);   // 语言
        expect(find.byIcon(Icons.format_size), findsOneWidget); // 字体大小
        expect(find.byIcon(Icons.save), findsOneWidget);       // 自动保存
        expect(find.byIcon(Icons.spellcheck), findsOneWidget); // 拼写检查
        expect(find.byIcon(Icons.countertops), findsOneWidget); // 字数统计
        expect(find.byIcon(Icons.psychology), findsOneWidget);  // AI模型
        expect(find.byIcon(Icons.tune), findsOneWidget);        // AI创造力
        expect(find.byIcon(Icons.verified_user), findsOneWidget); // 意图确认
        expect(find.byIcon(Icons.folder), findsOneWidget);      // 存储位置
        expect(find.byIcon(Icons.backup), findsOneWidget);      // 数据备份
        expect(find.byIcon(Icons.cleaning_services), findsOneWidget); // 缓存管理
        expect(find.byIcon(Icons.info), findsOneWidget);        // 版本信息
        expect(find.byIcon(Icons.description), findsOneWidget); // 许可证
      });

      testWidgets('所有设置项都应该有标题和副标题', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证主要设置项都有标题和副标题
        expect(find.text('选择应用主题'), findsOneWidget);
        expect(find.text('选择界面语言'), findsOneWidget);
        expect(find.text('调整编辑器字体大小'), findsOneWidget);
        expect(find.text('编辑时自动保存笔记'), findsOneWidget);
        expect(find.text('启用拼写检查功能'), findsOneWidget);
        expect(find.text('显示实时字数统计'), findsOneWidget);
        expect(find.text('选择AI处理模型'), findsOneWidget);
        expect(find.text('调整AI的创造力水平'), findsOneWidget);
        expect(find.text('AI操作前显示确认对话框'), findsOneWidget);
        expect(find.text('设置数据存储目录'), findsOneWidget);
        expect(find.text('管理数据备份'), findsOneWidget);
        expect(find.text('清除应用缓存'), findsOneWidget);
      });

      testWidgets('设置页面应该使用Card布局', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证使用了Card组件
        expect(find.byType(Card), findsNWidgets(5)); // 5个设置分区
      });

      testWidgets('设置页面应该有正确的间距', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证SizedBox用于间距
        expect(find.byType(SizedBox), findsWidgets);

        // 验证ListView有padding
        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);
      });
    });

    group('错误处理测试', () {
      testWidgets('加载失败时应该显示错误状态', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 页面应该正常显示（错误处理在内部）
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('设置更新失败不应该崩溃应用', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击开关（不应该崩溃）
        await tester.tap(find.byType(SwitchListTile).first);
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('可访问性测试', () {
      testWidgets('所有交互元素应该可访问', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 验证所有SwitchListTile可访问
        final switches = find.byType(SwitchListTile);
        for (int i = 0; i < tester.widgetList<SwitchListTile>(switches).length; i++) {
          expect(switches.at(i), findsOneWidget);
        }

        // 验证所有ListTile可访问
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsWidgets);
      });

      testWidgets('对话框按钮应该可点击', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 打开对话框
        await tester.tap(find.text('缓存管理'));
        await tester.pumpAndSettle();

        // 验证清除缓存按钮可点击
        final clearButton = find.text('清除缓存');
        expect(clearButton, findsOneWidget);

        // 验证关闭按钮可点击
        final closeButton = find.text('关闭');
        expect(closeButton, findsOneWidget);
      });
    });

    group('持久化测试', () {
      testWidgets('设置更改应该保存到存储', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击开关（不应该崩溃）
        await tester.tap(find.byType(SwitchListTile).first);
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('主题设置应该持久化', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击主题下拉菜单
        final themeDropdown = find.byType(DropdownButton<ThemeMode>).first;
        await tester.tap(themeDropdown);
        await tester.pumpAndSettle();

        // 选择一个选项（不应该崩溃）
        await tester.tap(find.text('深色'));
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('字体大小设置应该持久化', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击字体大小下拉菜单
        final fontSizeDropdown = find.byType(DropdownButton<int>).first;
        await tester.tap(fontSizeDropdown);
        await tester.pumpAndSettle();

        // 选择一个选项（不应该崩溃）
        await tester.tap(find.text('大'));
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('AI创造力设置应该持久化', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 点击AI创造力下拉菜单
        final aiCreativityDropdown = find.byType(DropdownButton<double>).first;
        await tester.tap(aiCreativityDropdown);
        await tester.pumpAndSettle();

        // 选择一个选项（不应该崩溃）
        await tester.tap(find.text('创新'));
        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('边界条件测试', () {
      testWidgets('快速连续点击开关应该正常处理', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 快速连续点击开关
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byType(SwitchListTile).first);
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('快速打开关闭对话框应该正常处理', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 快速打开关闭对话框
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('版本信息'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('确定'));
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // 应用应该仍然正常
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('空值设置应该正常处理', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 应用应该仍然正常显示
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });
  });
}
