import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/features/reports/presentation/report_card.dart';
import 'package:museflow/features/reports/presentation/reports_hub_page.dart';
import 'package:museflow/shared/constants/app_constants.dart';

void main() {
  group('ReportsHubPage', () {
    late GoRouter goRouter;

    setUp(() {
      goRouter = GoRouter(
        initialLocation: AppConstants.statsReports,
        routes: [
          GoRoute(
            path: AppConstants.stats,
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              GoRoute(
                path: 'reports',
                builder: (context, state) => const ReportsHubPage(),
                routes: [
                  GoRoute(
                    path: 'token-cost',
                    builder: (context, state) =>
                        const SizedBox(child: Text('token-cost')),
                  ),
                  GoRoute(
                    path: 'pain-points',
                    builder: (context, state) =>
                        const SizedBox(child: Text('pain-points')),
                  ),
                  GoRoute(
                    path: 'anti-ai-scent',
                    builder: (context, state) =>
                        const SizedBox(child: Text('anti-ai-scent')),
                  ),
                  GoRoute(
                    path: 'consistency',
                    builder: (context, state) =>
                        const SizedBox(child: Text('consistency')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });

    Future<void> pumpHubPage(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));
      await tester.pumpAndSettle();
    }

    testWidgets('should render page title in headlineMedium style', (
      WidgetTester tester,
    ) async {
      await pumpHubPage(tester);

      final titleFinder = find.text('分析报告');
      // There are two "分析报告" texts: one in AppBar, one in body.
      // Find the one in the body that has headlineMedium style.
      expect(titleFinder, findsNWidgets(2));

      // Verify the body title has headlineMedium style
      final bodyTitleWidget = tester
          .widgetList<Text>(titleFinder)
          .firstWhere(
            (text) =>
                text.style?.fontSize ==
                Theme.of(
                  tester.element(titleFinder.first),
                ).textTheme.headlineMedium?.fontSize,
          );
      expect(bodyTitleWidget.style?.fontSize, isNotNull);
    });

    testWidgets('should render subtitle in bodyMedium style', (
      WidgetTester tester,
    ) async {
      await pumpHubPage(tester);

      final subtitleFinder = find.text('百章创作验证的四维分析。');
      expect(subtitleFinder, findsOneWidget);

      final subtitleWidget = tester.widget<Text>(subtitleFinder);
      final context = tester.element(subtitleFinder);
      expect(
        subtitleWidget.style,
        equals(Theme.of(context).textTheme.bodyMedium),
      );
    });

    testWidgets('should render 4 ReportCard widgets with correct titles', (
      WidgetTester tester,
    ) async {
      await pumpHubPage(tester);

      expect(find.text('Token 成本分析'), findsOneWidget);
      expect(find.text('用户痛点报告'), findsOneWidget);
      expect(find.text('反AI味效果评估'), findsOneWidget);
      expect(find.text('知识库一致性分析'), findsOneWidget);
    });

    testWidgets(
      'should render 4 ReportCard widgets with correct descriptions',
      (WidgetTester tester) async {
        await pumpHubPage(tester);

        expect(find.text('万字短篇实际成本与50万字长篇消耗推算'), findsOneWidget);
        expect(find.text('功能缺陷 + 体验摩擦 + 缺失需求，按严重程度分类'), findsOneWidget);
        expect(find.text('盲读测试评估 AI 生成内容的自然度'), findsOneWidget);
        expect(find.text('角色卡和设定集与实际内容的一致性对比'), findsOneWidget);
      },
    );

    testWidgets('should render 4 report cards with correct icons', (
      WidgetTester tester,
    ) async {
      await pumpHubPage(tester);

      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
    });

    testWidgets('should render chevron trailing icons on cards', (
      WidgetTester tester,
    ) async {
      await pumpHubPage(tester);

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    });

    testWidgets('should navigate to token-cost route on tap', (
      WidgetTester tester,
    ) async {
      await pumpHubPage(tester);

      await tester.tap(find.text('Token 成本分析'));
      await tester.pumpAndSettle();

      expect(find.text('token-cost'), findsOneWidget);
    });

    testWidgets('should navigate to pain-points route on tap', (
      WidgetTester tester,
    ) async {
      await pumpHubPage(tester);

      await tester.tap(find.text('用户痛点报告'));
      await tester.pumpAndSettle();

      expect(find.text('pain-points'), findsOneWidget);
    });
  });

  group('ReportCard', () {
    testWidgets('should render icon, title, description, and chevron', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              icon: Icons.analytics_outlined,
              title: 'Test Title',
              description: 'Test Description',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              icon: Icons.analytics_outlined,
              title: 'Test',
              description: 'Desc',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      expect(tapped, isTrue);
    });
  });

  group('AppConstants reports routes', () {
    test('should have all 5 report route constants', () {
      expect(AppConstants.statsReports, '/stats/reports');
      expect(AppConstants.statsReportsTokenCost, '/stats/reports/token-cost');
      expect(AppConstants.statsReportsPainPoints, '/stats/reports/pain-points');
      expect(
        AppConstants.statsReportsAntiAiScent,
        '/stats/reports/anti-ai-scent',
      );
      expect(
        AppConstants.statsReportsConsistency,
        '/stats/reports/consistency',
      );
    });
  });
}
