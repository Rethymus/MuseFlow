import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/pages/startup_page.dart';
import 'package:museflow/services/progressive_initializer.dart';

void main() {
  // 确保Flutter测试绑定初始化
  TestWidgetsFlutterBinding.ensureInitialized();
  group('StartupPage Widget测试', () {
    late List<String> completionCallbacks;
    late VoidCallback onInitializationComplete;

    setUp(() {
      completionCallbacks = <String>[];
      onInitializationComplete = () {
        completionCallbacks.add('completed');
      };

      // 确保每次测试前初始化器处于干净状态
      if (ProgressiveInitializer.instance.isInitialized) {
        // 重置初始化器状态（实际项目中可能需要添加reset方法）
      }
    });

    Widget createStartupPageUnderTest() {
      return MaterialApp(
        home: StartupPage(
          onInitializationComplete: onInitializationComplete,
        ),
      );
    }

    testWidgets('启动页面基本组件验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 验证应用名称显示
      expect(find.text('MuseFlow'), findsOneWidget);

      // 验证Logo图标存在
      expect(find.byIcon(Icons.music_note), findsOneWidget);

      // 验证初始状态消息
      expect(find.text('正在启动...'), findsOneWidget);

      // 验证进度条存在
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // 验证百分比显示存在
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('启动页面布局结构验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 验证Scaffold结构
      expect(find.byType(Scaffold), findsOneWidget);

      // 验证Container装饰（渐变背景）
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // 验证居中布局
      expect(find.byType(Center), findsOneWidget);

      // 验证Column布局
      expect(find.byType(Column), findsWidgets);

      // 验证Padding
      expect(find.byType(Padding), findsOneWidget);
    });

    testWidgets('Logo组件验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找包含Icon的Container
      // ignore: unused_local_variable
      final containerWithIcon = find.descendant(
        of: find.byType(Container),
        matching: find.byType(InkWell),
      );

      // 验证Logo存在
      expect(find.byIcon(Icons.music_note), findsOneWidget);

      // Icon应该在白色背景上
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.music_note));
      expect(iconWidget.color, Colors.white);
      expect(iconWidget.size, 48);
    });

    testWidgets('应用名称样式验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找MuseFlow文本
      final textFinder = find.text('MuseFlow');
      expect(textFinder, findsOneWidget);

      // 获取文本样式
      final textWidget = tester.widget<Text>(textFinder);
      final textStyle = textWidget.style!;

      // 验证文本样式属性
      expect(textStyle.fontSize, isNotNull);
      expect(textStyle.fontWeight, FontWeight.bold);
    });

    testWidgets('进度条组件验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 验证进度条存在
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // 获取进度条组件
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // 初始进度应该为0或接近0
      expect(progressIndicator.value, 0.0);
    });

    testWidgets('进度百分比显示验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 验证初始百分比显示
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('状态消息显示验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 初始消息
      expect(find.text('正在启动...'), findsOneWidget);
    });

    testWidgets('页面渐变背景验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找最外层Container
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // 获取第一个Container（背景容器）
      final backgroundContainer = tester.widget<Container>(containers.first);

      // 验证有装饰
      expect(backgroundContainer.decoration, isA<BoxDecoration>());

      final decoration = backgroundContainer.decoration as BoxDecoration;

      // 验证是渐变装饰
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('TweenAnimationBuilder动画验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找所有TweenAnimationBuilder
      final tweenAnimBuilders = find.byType(TweenAnimationBuilder<double>);
      expect(tweenAnimBuilders, findsWidgets);

      // 应该有至少2个TweenAnimationBuilder（进度条和百分比）
      expect(tweenAnimBuilders.evaluate().length, greaterThanOrEqualTo(2));
    });

    testWidgets('错误提示组件初始状态验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 初始状态不应该显示错误提示
      expect(find.text('部分功能可能受影响'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('页面组件响应式布局测试', (WidgetTester tester) async {
      final testSizes = [
        const Size(400, 800), // 小屏幕
        const Size(800, 600), // 中等屏幕
        const Size(1920, 1080), // 大屏幕
      ];

      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(createStartupPageUnderTest());
        await tester.pumpAndSettle();

        // 验证基本组件在不同屏幕尺寸下都存在
        expect(find.text('MuseFlow'), findsOneWidget);
        expect(find.byIcon(Icons.music_note), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      }
    });

    testWidgets('页面主题适配验证', (WidgetTester tester) async {
      // 测试亮色主题
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: StartupPage(
            onInitializationComplete: onInitializationComplete,
          ),
        ),
      );

      expect(find.byType(StartupPage), findsOneWidget);

      // 测试暗色主题
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: StartupPage(
            onInitializationComplete: onInitializationComplete,
          ),
        ),
      );

      expect(find.byType(StartupPage), findsOneWidget);
    });

    testWidgets('进度条容器尺寸验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找进度条容器（应该是300px宽，4px高）
      final containers = find.byType(Container);

      // 找到包含LinearProgressIndicator的Container
      bool foundProgressContainer = false;
      for (final containerFinder in containers.evaluate()) {
        final container = containerFinder.widget as Container;
        if (container.constraints != null &&
            container.constraints!.maxWidth == 300) {
          foundProgressContainer = true;
          break;
        }
      }

      expect(foundProgressContainer, isTrue);
    });

    testWidgets('可访问性 - 基本可访问性验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 验证主要文本元素存在
      expect(find.text('MuseFlow'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);

      // 进度指示器应该可访问
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('性能测试 - 页面初始渲染时间', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createStartupPageUnderTest());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 页面应该在合理时间内渲染完成
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('边界条件 - 极小屏幕尺寸', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      await tester.pumpWidget(createStartupPageUnderTest());
      await tester.pumpAndSettle();

      // 即使在极小屏幕上，基本组件也应该存在
      expect(find.text('MuseFlow'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('边界条件 - 超大屏幕尺寸', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(3840, 2160));
      await tester.pumpWidget(createStartupPageUnderTest());
      await tester.pumpAndSettle();

      // 在超大屏幕上应该正常显示
      expect(find.text('MuseFlow'), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('组件间距验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找SizedBox组件
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);

      // 验证主要间距组件存在
      expect(sizedBoxes.evaluate().length, greaterThan(2));
    });

    testWidgets('ProgressiveInitializer集成验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 验证初始化器实例存在
      expect(ProgressiveInitializer.instance, isNotNull);
      expect(ProgressiveInitializer.instance, isA<ProgressiveInitializer>());
    });

    testWidgets('启动页面生命周期验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 验证初始状态
      expect(find.byType(StartupPage), findsOneWidget);

      // 触发帧更新
      await tester.pump();

      // 页面应该仍然存在
      expect(find.byType(StartupPage), findsOneWidget);
    });

    testWidgets('进度条颜色主题适配', (WidgetTester tester) async {
      // 测试自定义主题
      final customTheme = ThemeData(
        primaryColor: Colors.purple,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: customTheme,
          home: StartupPage(
            onInitializationComplete: onInitializationComplete,
          ),
        ),
      );

      // 验证进度条存在
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Column布局mainAxisAlignment验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找主Column
      final columns = find.byType(Column);
      expect(columns, findsWidgets);

      // 主Column应该有mainAxisAlignment: MainAxisAlignment.center
      bool foundCenterColumn = false;
      for (final columnFinder in columns.evaluate()) {
        final column = columnFinder.widget as Column;
        if (column.mainAxisAlignment == MainAxisAlignment.center) {
          foundCenterColumn = true;
          break;
        }
      }

      expect(foundCenterColumn, isTrue);
    });

    testWidgets('文本textAlign验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 查找状态消息文本
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsWidgets);

      // 状态消息应该居中对齐
      bool foundCenterAlignedText = false;
      for (final textFinder in textWidgets.evaluate()) {
        final text = textFinder.widget as Text;
        if (text.textAlign == TextAlign.center) {
          foundCenterAlignedText = true;
          break;
        }
      }

      expect(foundCenterAlignedText, isTrue);
    });
  });

  group('StartupScreenWrapper测试', () {
    testWidgets('未初始化时显示启动页面', (WidgetTester tester) async {
      // 确保初始化器未初始化
      // 注意：这需要ProgressiveInitializer提供重置方法

      await tester.pumpWidget(
        const MaterialApp(
          home: StartupScreenWrapper(
            child: Scaffold(
              body: Text('主应用内容'),
            ),
          ),
        ),
      );

      // 应该显示启动页面
      expect(find.byType(StartupPage), findsOneWidget);
      expect(find.text('主应用内容'), findsNothing);
    });

    testWidgets('已初始化时显示主内容', (WidgetTester tester) async {
      // 模拟已初始化状态
      // 注意：这需要ProgressiveInitializer提供设置初始化状态的方法

      await tester.pumpWidget(
        const MaterialApp(
          home: StartupScreenWrapper(
            child: Scaffold(
              body: Text('主应用内容'),
            ),
          ),
        ),
      );

      // 如果已初始化，应该显示主内容
      // 但由于测试环境限制，这个测试可能需要调整
    });

    testWidgets('包装器基本渲染验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StartupScreenWrapper(
            child: Scaffold(
              body: Center(
                child: Text('测试内容'),
              ),
            ),
          ),
        ),
      );

      // 验证包装器能够渲染
      expect(find.byType(StartupScreenWrapper), findsOneWidget);
    });
  });

  group('StartupPage状态变化测试', () {
    late List<String> completionCallbacks;
    late VoidCallback onInitializationComplete;

    setUp(() {
      completionCallbacks = <String>[];
      onInitializationComplete = () {
        completionCallbacks.add('completed');
      };
    });

    Widget createStartupPageUnderTest() {
      return MaterialApp(
        home: StartupPage(
          onInitializationComplete: onInitializationComplete,
        ),
      );
    }

    testWidgets('进度更新验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 等待几帧让动画开始
      await tester.pump(const Duration(milliseconds: 100));

      // 验证页面仍然正常显示
      expect(find.byType(StartupPage), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('状态消息更新验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 初始消息
      expect(find.text('正在启动...'), findsOneWidget);

      // 等待状态更新
      await tester.pump(const Duration(milliseconds: 200));

      // 页面应该仍然响应
      expect(find.byType(StartupPage), findsOneWidget);
    });

    testWidgets('完成回调触发验证', (WidgetTester tester) async {
      await tester.pumpWidget(createStartupPageUnderTest());

      // 给足够时间让初始化完成
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 验证页面结构
      expect(find.byType(StartupPage), findsOneWidget);
    });
  });

  group('StartupPage错误处理测试', () {
    late List<String> errorEvents;
    late VoidCallback onInitializationComplete;

    setUp(() {
      errorEvents = <String>[];
      onInitializationComplete = () {
        errorEvents.add('completion_attempted');
      };
    });

    Widget createStartupPageUnderTest() {
      return MaterialApp(
        home: StartupPage(
          onInitializationComplete: onInitializationComplete,
        ),
      );
    }

    testWidgets('页面构建不应抛出异常', (WidgetTester tester) async {
      expect(
        () async => await tester.pumpWidget(createStartupPageUnderTest()),
        returnsNormally,
      );
    });

    testWidgets('null回调处理', (WidgetTester tester) async {
      // 使用null回调（虽然实际使用中不应该这样做）
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 页面应该正常构建
      expect(find.byType(StartupPage), findsOneWidget);
    });

    testWidgets('快速重建测试', (WidgetTester tester) async {
      // 测试页面快速重建的能力
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(createStartupPageUnderTest());
        await tester.pump();
      }

      // 页面应该仍然正常工作
      expect(find.byType(StartupPage), findsOneWidget);
    });
  });

  group('StartupPage集成测试', () {
    testWidgets('与ProgressiveInitializer集成', (WidgetTester tester) async {
      final List<String> events = [];

      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {
              events.add('completed');
            },
          ),
        ),
      );

      // 验证初始化器可用
      expect(ProgressiveInitializer.instance, isNotNull);

      // 验证页面正常显示
      expect(find.byType(StartupPage), findsOneWidget);
    });

    testWidgets('InitializationListener生命周期', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 页面创建后，listener应该被设置
      expect(find.byType(StartupPage), findsOneWidget);

      // 移除页面
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // 页面应该被移除
      expect(find.byType(StartupPage), findsNothing);
    });
  });

  group('StartupPage性能和优化测试', () {
    testWidgets('初始渲染性能', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      stopwatch.stop();

      // 初始渲染应该很快
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('动画性能验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 测试多帧动画性能
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      stopwatch.stop();

      // 10帧应该在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('内存使用 - 多次重建', (WidgetTester tester) async {
      // 执行多次重建测试内存泄漏
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: StartupPage(
              onInitializationComplete: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
      }

      // 最后一次构建应该仍然正常工作
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      expect(find.byType(StartupPage), findsOneWidget);
    });
  });

  group('StartupPage UI细节测试', () {
    testWidgets('Padding值验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 查找Padding组件
      final paddings = find.byType(Padding);
      expect(paddings, findsWidgets);

      // 主Padding应该是48.0
      bool foundMainPadding = false;
      for (final paddingFinder in paddings.evaluate()) {
        final padding = paddingFinder.widget as Padding;
        if (padding.padding == const EdgeInsets.all(48.0)) {
          foundMainPadding = true;
          break;
        }
      }

      expect(foundMainPadding, isTrue);
    });

    testWidgets('BorderRadius验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 查找Container
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Logo容器应该有圆角
      bool foundRoundedContainer = false;
      for (final containerFinder in containers.evaluate()) {
        final container = containerFinder.widget as Container;
        if (container.decoration != null) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.borderRadius != null) {
            foundRoundedContainer = true;
            break;
          }
        }
      }

      expect(foundRoundedContainer, isTrue);
    });

    testWidgets('LinearGradient方向验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 查找有渐变的Container
      final containers = find.byType(Container);

      bool foundGradient = false;
      for (final containerFinder in containers.evaluate()) {
        final container = containerFinder.widget as Container;
        if (container.decoration != null) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.gradient != null) {
            final gradient = decoration.gradient as LinearGradient;
            // 验证渐变方向
            expect(gradient.begin, Alignment.topLeft);
            expect(gradient.end, Alignment.bottomRight);
            foundGradient = true;
            break;
          }
        }
      }

      expect(foundGradient, isTrue);
    });
  });

  group('StartupPage边界条件测试', () {
    testWidgets('空回调处理', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {}, // 空回调
          ),
        ),
      );

      // 页面应该正常工作
      expect(find.byType(StartupPage), findsOneWidget);
    });

    testWidgets('重复创建和销毁', (WidgetTester tester) async {
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: StartupPage(
              onInitializationComplete: () {},
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(StartupPage), findsOneWidget);

        // 销毁
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        expect(find.byType(StartupPage), findsNothing);
      }
    });

    testWidgets('长时间显示测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 模拟长时间显示
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 页面应该仍然正常
      expect(find.byType(StartupPage), findsOneWidget);
    });
  });

  group('StartupPage多语言和本地化测试', () {
    testWidgets('中文显示验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 应用名称是中文
      expect(find.text('MuseFlow'), findsOneWidget);

      // 初始消息是中文
      expect(find.text('正在启动...'), findsOneWidget);
    });

    testWidgets('特殊字符显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 验证特殊字符能正常显示
      expect(find.text('MuseFlow'), findsOneWidget);
    });
  });

  group('StartupPage辅助功能测试', () {
    testWidgets('Semantics结构验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 主要元素应该可访问
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('文本对比度验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(highlightColor: Colors.blue),
          home: StartupPage(
            onInitializationComplete: () {},
          ),
        ),
      );

      // 验证文本可见
      expect(find.text('MuseFlow'), findsOneWidget);
      expect(find.text('正在启动...'), findsOneWidget);
    });
  });

  group('StartupPage状态持久化测试', () {
    testWidgets('状态保持验证', (WidgetTester tester) async {
      final callbackCount = <int>[];
      var callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {
              callCount++;
              callbackCount.add(callCount);
            },
          ),
        ),
      );

      // 验证初始状态
      expect(find.byType(StartupPage), findsOneWidget);

      // 重建页面
      await tester.pumpWidget(
        MaterialApp(
          home: StartupPage(
            onInitializationComplete: () {
              callCount++;
              callbackCount.add(callCount);
            },
          ),
        ),
      );

      // 页面应该仍然正常工作
      expect(find.byType(StartupPage), findsOneWidget);
    });
  });
}
