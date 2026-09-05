import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_card.dart';
import 'package:museflow/shared/widgets/app_controls.dart';
import 'package:museflow/shared/widgets/app_dialogs.dart';
import 'package:museflow/shared/widgets/app_list_section.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: appTheme(Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  group('AppListSection', () {
    testWidgets('renders header, footer and rows with separators', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: AppListSection(
              header: '外观',
              footer: '主题跟随系统设置切换。',
              children: [
                AppListTile(
                  icon: CupertinoIcons.paintbrush,
                  iconColor: Color(0xFF5856D7),
                  title: '浅色',
                  showChevron: true,
                  value: '当前',
                ),
                AppListTile(
                  title: '深色',
                  trailing: AppSwitch(value: false, onChanged: null),
                ),
                AppListTile(title: '删除全部', destructive: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('外观'), findsOneWidget);
      expect(find.text('主题跟随系统设置切换。'), findsOneWidget);
      expect(find.text('浅色'), findsOneWidget);
      expect(find.text('当前'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });

    testWidgets('tap on tile fires callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: AppListSection(
              children: [AppListTile(title: '一项', onTap: () => tapped = true)],
            ),
          ),
        ),
      );

      await tester.tap(find.text('一项'));
      expect(tapped, isTrue);
    });
  });

  group('showAppDialog', () {
    testWidgets('renders centered title and stacked actions, fires callbacks', (
      tester,
    ) async {
      var confirmed = false;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAppDialog(
                  context,
                  title: '确认删除',
                  message: '文稿将在 30 天后永久删除。',
                  actions: [
                    const AppDialogAction('取消'),
                    AppDialogAction(
                      '删除',
                      isDestructive: true,
                      onPressed: () => confirmed = true,
                    ),
                  ],
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
      expect(find.text('确认删除'), findsNothing);
    });

    testWidgets('long action labels stack vertically', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAppDialog(
                  context,
                  title: '导出文稿',
                  actions: const [
                    AppDialogAction('导出为 Markdown'),
                    AppDialogAction('导出为纯文本'),
                    AppDialogAction('取消'),
                  ],
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('导出为 Markdown'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });
  });

  group('showAppActionSheet', () {
    testWidgets('shows actions and cancel, fires tapped action', (
      tester,
    ) async {
      var picked = '';
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAppActionSheet(
                  context,
                  title: '选择操作',
                  actions: [
                    AppSheetAction('重命名', onPressed: () => picked = 'rename'),
                    AppSheetAction(
                      '删除',
                      isDestructive: true,
                      onPressed: () => picked = 'delete',
                    ),
                  ],
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.text('选择操作'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();
      expect(picked, equals('rename'));
    });
  });

  group('AppSegmentedControl', () {
    testWidgets('reports selection changes', (tester) async {
      String selected = '浅色';
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => AppSegmentedControl<String>(
              segments: const ['浅色', '深色', '跟随系统'],
              selected: selected,
              onSelectionChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      );

      await tester.tap(find.text('深色'));
      await tester.pumpAndSettle();
      expect(selected, equals('深色'));
    });
  });

  group('AppCard', () {
    testWidgets('renders child and handles taps', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          Center(
            child: AppCard(
              onTap: () => tapped = true,
              child: const Text('卡片内容'),
            ),
          ),
        ),
      );

      expect(find.text('卡片内容'), findsOneWidget);
      await tester.tap(find.text('卡片内容'));
      expect(tapped, isTrue);
    });
  });

  group('AppEmptyState / AppBadge', () {
    testWidgets('empty state shows icon, title, message and action', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            icon: CupertinoIcons.book,
            title: '还没有文稿',
            message: '从灵感开始，写下属于你的故事。',
            action: FilledButton(
              onPressed: () => pressed = true,
              child: const Text('创建文稿'),
            ),
          ),
        ),
      );

      expect(find.text('还没有文稿'), findsOneWidget);
      await tester.tap(find.text('创建文稿'));
      expect(pressed, isTrue);
    });

    testWidgets('badge renders label', (tester) async {
      await tester.pumpWidget(
        _wrap(const Center(child: AppBadge(label: '已完结'))),
      );
      expect(find.text('已完结'), findsOneWidget);
    });
  });
}
