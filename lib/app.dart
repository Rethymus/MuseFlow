import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/app_shell.dart';
import 'package:museflow/features/ai/presentation/provider_management_page.dart';
import 'package:museflow/features/capture/presentation/capture_page.dart';
import 'package:museflow/features/editor/presentation/editor_page.dart';
import 'package:museflow/features/settings/presentation/settings_page.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/theme/app_theme.dart';

/// Root application widget for MuseFlow.
///
/// Uses go_router with StatefulShellRoute.indexedStack to preserve
/// branch state when switching between navigation destinations.
class MuseFlowApp extends ConsumerWidget {
  const MuseFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter();

    return MaterialApp.router(
      title: 'MuseFlow 灵韵',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      routerConfig: router,
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppConstants.editor,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShellScaffold(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Capture
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.capture,
                  builder: (context, state) => const CapturePage(),
                ),
              ],
            ),
            // Branch 1: Editor (home screen, per D-03)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.editor,
                  builder: (context, state) => const EditorPage(),
                ),
              ],
            ),
            // Branch 2: Settings (with AI providers sub-route)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.settings,
                  builder: (context, state) => const SettingsPage(),
                  routes: [
                    GoRoute(
                      path: 'ai-providers',
                      builder: (context, state) =>
                          const ProviderManagementPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
