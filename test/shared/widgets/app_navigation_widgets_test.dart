import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_sidebar.dart';
import 'package:museflow/shared/widgets/app_tab_bar.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: appTheme(Brightness.light),
  home: Scaffold(body: child),
);

void main() {
  group('AppSidebar', () {
    const destinations = [
      AppSidebarDestination(icon: CupertinoIcons.bookmark, label: '捕捉器'),
      AppSidebarDestination(icon: CupertinoIcons.pen, label: '编辑器'),
      AppSidebarDestination(icon: CupertinoIcons.book, label: '知识库'),
      AppSidebarDestination(icon: CupertinoIcons.graph_circle, label: '故事结构'),
      AppSidebarDestination(icon: CupertinoIcons.chart_bar, label: '统计'),
      AppSidebarDestination(icon: CupertinoIcons.gear, label: '设置'),
    ];

    testWidgets('extended shows app title and all labels', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppSidebar(
            selectedIndex: 1,
            destinations: destinations,
            onDestinationSelected: (_) {},
            extended: true,
          ),
        ),
      );

      expect(find.text('灵韵'), findsOneWidget);
      for (final d in destinations) {
        expect(find.text(d.label), findsOneWidget);
      }
    });

    testWidgets('collapsed hides labels but keeps semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          AppSidebar(
            selectedIndex: 0,
            destinations: destinations,
            onDestinationSelected: (_) {},
            extended: false,
          ),
        ),
      );

      expect(find.text('编辑器'), findsNothing);
      expect(find.bySemanticsLabel('编辑器'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('tap reports the tapped index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        _wrap(
          AppSidebar(
            selectedIndex: 0,
            destinations: destinations,
            onDestinationSelected: (i) => tapped = i,
            extended: true,
          ),
        ),
      );

      await tester.tap(find.text('统计'));
      expect(tapped, equals(4));
    });

    testWidgets('selected destination is exposed for state assertions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppSidebar(
            selectedIndex: 3,
            destinations: destinations,
            onDestinationSelected: (_) {},
            extended: true,
          ),
        ),
      );

      final sidebar = tester.widget<AppSidebar>(find.byType(AppSidebar));
      expect(sidebar.selectedIndex, equals(3));
      expect(sidebar.destinations.length, equals(6));
    });
  });

  group('AppTabBar', () {
    const destinations = [
      AppSidebarDestination(icon: CupertinoIcons.bookmark, label: '捕捉器'),
      AppSidebarDestination(icon: CupertinoIcons.pen, label: '编辑器'),
      AppSidebarDestination(icon: CupertinoIcons.book, label: '知识库'),
      AppSidebarDestination(icon: CupertinoIcons.graph_circle, label: '故事结构'),
      AppSidebarDestination(icon: CupertinoIcons.chart_bar, label: '统计'),
    ];

    testWidgets('renders every tab label and selection state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppTabBar(
            selectedIndex: 2,
            destinations: destinations,
            onDestinationSelected: (_) {},
          ),
        ),
      );

      for (final d in destinations) {
        expect(find.text(d.label), findsOneWidget);
      }
      final bar = tester.widget<AppTabBar>(find.byType(AppTabBar));
      expect(bar.selectedIndex, equals(2));
    });

    testWidgets('tap fires selection callback', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        _wrap(
          AppTabBar(
            selectedIndex: 0,
            destinations: destinations,
            onDestinationSelected: (i) => tapped = i,
          ),
        ),
      );

      await tester.tap(find.text('编辑器'));
      expect(tapped, equals(1));
    });
  });
}
