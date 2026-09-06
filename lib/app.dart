library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/app_shell.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/presentation/banned_phrase_settings.dart';
import 'package:museflow/features/ai/presentation/provider_management_page.dart';
import 'package:museflow/features/capture/presentation/capture_page.dart';
import 'package:museflow/features/manuscript/presentation/editor_with_sidebar.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_library_page.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_settings_page.dart';
import 'package:museflow/features/editor/presentation/author_style_profile_page.dart';
import 'package:museflow/features/knowledge/presentation/character_card_form.dart';
import 'package:museflow/features/knowledge/presentation/knowledge_base_page.dart';
import 'package:museflow/features/knowledge/presentation/skill_generation_wizard.dart';
import 'package:museflow/features/knowledge/presentation/skill_list_page.dart';
import 'package:museflow/features/knowledge/presentation/world_setting_form.dart';
import 'package:museflow/features/onboarding/presentation/onboarding_wizard_page.dart';
import 'package:museflow/features/settings/presentation/settings_page.dart';
import 'package:museflow/features/settings/presentation/web_workspace_gate.dart';
import 'package:museflow/features/stats/presentation/project_stats_page.dart';
import 'package:museflow/features/stats/presentation/token_audit_page.dart';
import 'package:museflow/features/stats/presentation/writing_stats_page.dart';
import 'package:museflow/features/stats/presentation/progress_dashboard_page.dart';
import 'package:museflow/features/reports/presentation/blind_read_page.dart';
import 'package:museflow/features/reports/presentation/consistency_report_page.dart';
import 'package:museflow/features/reports/presentation/editorial_review_page.dart';
import 'package:museflow/features/reports/presentation/pain_point_report_page.dart';
import 'package:museflow/features/reports/presentation/reports_hub_page.dart';
import 'package:museflow/features/reports/presentation/token_cost_report_page.dart';
import 'package:museflow/features/story_structure/presentation/story_structure_page.dart';
import 'package:museflow/features/templates/presentation/template_draft_page.dart';
import 'package:museflow/features/templates/presentation/template_gallery_page.dart';
import 'package:museflow/features/templates/presentation/template_preview_page.dart';
import 'package:museflow/shared/constants/app_constants.dart';
import 'package:museflow/shared/theme/apple_scroll_behavior.dart';
import 'package:museflow/shared/theme/app_materials.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_ambient.dart';

part 'app_routes.dart';

/// Root application widget for MuseFlow.
///
/// Uses go_router with StatefulShellRoute.indexedStack to preserve
/// branch state when switching between navigation destinations.
class MuseFlowApp extends ConsumerWidget {
  const MuseFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter();

    return MaterialApp.router(
      title: 'MuseFlow 灵韵',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppleScrollBehavior(),
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      // Chinese-first localization: the app's own copy is Chinese, so every
      // framework-provided string (tooltips, counters like "characters
      // remaining", date pickers) must follow instead of mixing English
      // defaults into a Chinese interface (HF-8).
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => _AppBackdrop(
        child: WebWorkspaceGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  /// Redirect guard for first-run detection.
  ///
  /// Reads the `onboarding_completed` flag from the Hive settings box.
  /// - Fresh install (flag not set): redirects to /onboarding
  /// - Completed onboarding while on /onboarding: redirects to editor
  /// - Completed onboarding on any other route: no redirect
  /// - Prevents infinite loops by checking current location before redirecting.
  Future<String?> _handleRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final isOnboarding = state.matchedLocation == AppConstants.onboarding;

    try {
      final box = Hive.box('settings');
      final completed =
          box.get('onboarding_completed', defaultValue: false) as bool;

      // Fresh install: redirect to onboarding wizard
      if (!completed && !isOnboarding) {
        return AppConstants.onboarding;
      }

      // Completed user landed on /onboarding (e.g. deep link): redirect to editor
      if (completed && isOnboarding) {
        return AppConstants.editor;
      }

      // No redirect needed
      return null;
    } catch (_) {
      // If settings box is not yet open, allow normal routing.
      // The onboarding check will run again once the box is available.
      return null;
    }
  }
}

/// The root [Stack]: the ambient canvas underneath, app chrome above.
///
/// The shell scaffold is transparent, so wherever a page does not paint
/// (behind the glass sidebar, under the floating toolbar) the canvas shows
/// through and the [BackdropFilter]s in [AppMaterial] finally sample real
/// luminance variation instead of a flat void — the depth layer the design
/// roadmap calls "毛玻璃随背后的界面内容产生层次".
class _AppBackdrop extends ConsumerWidget {
  const _AppBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceTransparency = ref.watch(reduceTransparencyProvider);
    return AppVisualSettings(
      reduceTransparency: reduceTransparency,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          AppAmbientCanvas(enabled: !reduceTransparency),
          child,
        ],
      ),
    );
  }
}
