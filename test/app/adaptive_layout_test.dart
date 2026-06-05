import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/app_shell.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Simple placeholder pages for testing layout without SuperEditor.
class _TestCapturePage extends StatelessWidget {
  const _TestCapturePage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TEST_CAPTURE')));
}

class _TestEditorPage extends StatelessWidget {
  const _TestEditorPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TEST_EDITOR')));
}

class _TestSettingsPage extends StatelessWidget {
  const _TestSettingsPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TEST_SETTINGS')));
}

class _TestKnowledgePage extends StatelessWidget {
  const _TestKnowledgePage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TEST_KNOWLEDGE')));
}

class _TestStoryStructurePage extends StatelessWidget {
  const _TestStoryStructurePage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TEST_STORY_STRUCTURE')));
}

/// Creates a test router with the same shell structure as the real app.
GoRouter _createTestRouter() {
  return GoRouter(
    initialLocation: AppConstants.editor,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.capture,
                builder: (context, state) => const _TestCapturePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.editor,
                builder: (context, state) => const _TestEditorPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.knowledge,
                builder: (context, state) => const _TestKnowledgePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.storyStructure,
                builder: (context, state) => const _TestStoryStructurePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppConstants.settings,
                builder: (context, state) => const _TestSettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _createTestApp() {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: _createTestRouter(),
    ),
  );
}

void main() {
  group('Adaptive Layout Breakpoints', () {
    testWidgets(
        'should show extended NavigationRail at width >= 1000px',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // NavigationRail should be present
      expect(find.byType(NavigationRail), findsOneWidget);

      // Should be extended (showing labels)
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.extended, isTrue);

      // Labels should be visible for all destinations
      expect(find.text('捕捉器'), findsOneWidget);
      expect(find.text('编辑器'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('知识库'), findsOneWidget);
      expect(find.text('故事结构'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
        'should show collapsed NavigationRail at width 600-999px',
        (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // NavigationRail should be present
      expect(find.byType(NavigationRail), findsOneWidget);

      // Should NOT be extended (icons only)
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.extended, isFalse);

      // NavigationBar should NOT be present
      expect(find.byType(NavigationBar), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
        'should show NavigationBar at bottom and hide NavigationRail below 600px',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // NavigationBar should be present at bottom
      expect(find.byType(NavigationBar), findsOneWidget);

      // NavigationRail should NOT be present
      expect(find.byType(NavigationRail), findsNothing);

      // NavigationBar should have 5 destinations with Chinese labels
      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.destinations.length, equals(5));

      // Labels should be visible in NavigationBar
      expect(find.text('捕捉器'), findsOneWidget);
      expect(find.text('编辑器'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
        'should have exactly 5 destinations with matching icons in both modes',
        (tester) async {
      // Test desktop mode
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.destinations.length, equals(5));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();

      // Test mobile mode
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navBar.destinations.length, equals(5));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
