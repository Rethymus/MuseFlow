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

class _TestEditorPage extends StatefulWidget {
  const _TestEditorPage();

  @override
  State<_TestEditorPage> createState() => _TestEditorPageState();
}

class _TestEditorPageState extends State<_TestEditorPage> {
  String _editorText = 'Initial editor text';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_editorText),
            TextButton(
              onPressed: () => setState(() => _editorText = 'Modified editor text'),
              child: const Text('MODIFY_TEXT'),
            ),
          ],
        ),
      ),
    );
  }
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

class _TestStatsPage extends StatelessWidget {
  const _TestStatsPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('TEST_STATS')));
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
                path: AppConstants.stats,
                builder: (context, state) => const _TestStatsPage(),
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
  group('Navigation Destinations', () {
    testWidgets('should render destinations with correct Chinese labels',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('捕捉器'), findsOneWidget);
      expect(find.text('编辑器'), findsOneWidget);
      expect(find.text('知识库'), findsOneWidget);
      expect(find.text('故事结构'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should have editor as initial branch (index 1)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // NavigationRail should show editor (index 1) selected
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.selectedIndex, equals(1));

      // Editor content should be visible
      expect(find.text('Initial editor text'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should switch branch when tapping capture destination',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Tap capture destination
      await tester.tap(find.text('捕捉器'));
      await tester.pumpAndSettle();

      // Should show capture content
      expect(find.text('TEST_CAPTURE'), findsOneWidget);

      // NavigationRail should show index 0 selected
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.selectedIndex, equals(0));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should switch branch when tapping settings destination',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Tap settings destination
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // Should show settings content
      expect(find.text('TEST_SETTINGS'), findsOneWidget);

      // NavigationRail should show settings branch selected.
      final navRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navRail.selectedIndex, equals(5));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('should preserve editor state when switching branches',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Modify editor state
      await tester.tap(find.text('MODIFY_TEXT'));
      await tester.pumpAndSettle();

      // Verify text changed
      expect(find.text('Modified editor text'), findsOneWidget);

      // Switch to capture
      await tester.tap(find.text('捕捉器'));
      await tester.pumpAndSettle();
      expect(find.text('TEST_CAPTURE'), findsOneWidget);

      // Switch back to editor -- state should be preserved
      await tester.tap(find.text('编辑器'));
      await tester.pumpAndSettle();

      expect(find.text('Modified editor text'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
