import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/app_shell.dart';
import 'package:museflow/shared/constants/app_constants.dart';

/// Simple placeholder pages for testing navigation without SuperEditor.
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

/// Creates a test router with the same shell structure as the real app,
/// but with simple placeholder pages instead of SuperEditor.
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
    child: MaterialApp.router(routerConfig: _createTestRouter()),
  );
}

void main() {
  group('App Shell Navigation', () {
    testWidgets('should render NavigationRail with 6 destinations', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Should find NavigationRail
      expect(find.byType(NavigationRail), findsOneWidget);

      // Should have 6 navigation destinations with Chinese labels

      // Use find.byType to locate NavigationRailDestination labels
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.destinations.length, equals(6));

      // Verify labels exist in the widget tree
      expect(find.text('捕捉器'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should have editor as initial route', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Initial route should show the editor page (branch index 1)
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.selectedIndex, equals(1));

      // Editor page content should be visible
      expect(find.text('TEST_EDITOR'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should switch branch when tapping navigation item', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Tap the capture destination (index 0)
      await tester.tap(find.text('捕捉器'));
      await tester.pumpAndSettle();

      // NavigationRail should now show index 0 selected
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.selectedIndex, equals(0));

      // Capture page content should be visible
      expect(find.text('TEST_CAPTURE'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should show NavigationBar on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Should find NavigationBar (bottom) instead of NavigationRail
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Should have 6 destinations

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, equals(6));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
