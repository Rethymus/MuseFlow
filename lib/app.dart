import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/app_shell.dart';
import 'package:museflow/features/ai/presentation/banned_phrase_settings.dart';
import 'package:museflow/features/ai/presentation/provider_management_page.dart';
import 'package:museflow/features/capture/presentation/capture_page.dart';
import 'package:museflow/features/manuscript/presentation/editor_with_sidebar.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_library_page.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_settings_page.dart';
import 'package:museflow/features/knowledge/presentation/character_card_form.dart';
import 'package:museflow/features/knowledge/presentation/knowledge_base_page.dart';
import 'package:museflow/features/knowledge/presentation/skill_generation_wizard.dart';
import 'package:museflow/features/knowledge/presentation/skill_list_page.dart';
import 'package:museflow/features/knowledge/presentation/world_setting_form.dart';
import 'package:museflow/features/onboarding/presentation/onboarding_wizard_page.dart';
import 'package:museflow/features/settings/presentation/settings_page.dart';
import 'package:museflow/features/stats/presentation/project_stats_page.dart';
import 'package:museflow/features/stats/presentation/token_audit_page.dart';
import 'package:museflow/features/stats/presentation/writing_stats_page.dart';
import 'package:museflow/features/reports/presentation/pain_point_report_page.dart';
import 'package:museflow/features/reports/presentation/reports_hub_page.dart';
import 'package:museflow/features/reports/presentation/token_cost_report_page.dart';
import 'package:museflow/features/story_structure/presentation/story_structure_page.dart';
import 'package:museflow/features/templates/presentation/template_draft_page.dart';
import 'package:museflow/features/templates/presentation/template_gallery_page.dart';
import 'package:museflow/features/templates/presentation/template_preview_page.dart';
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
      darkTheme: appTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppConstants.editor,
      redirect: _handleRedirect,
      routes: [
        // Top-level onboarding route — outside StatefulShellRoute for full-screen display.
        // The OnboardingWizardPage will be implemented in Plan 02.
        GoRoute(
          path: AppConstants.onboarding,
          builder: (context, state) => const OnboardingWizardPage(),
        ),
        // Top-level manuscript routes -- outside StatefulShellRoute per
        // RESEARCH Pitfall 4 so bottom nav is hidden inside editor.
        GoRoute(
          path: AppConstants.manuscriptEditor,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return EditorWithSidebar(manuscriptId: id);
          },
        ),
        GoRoute(
          path: AppConstants.manuscriptSettings,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ManuscriptSettingsPage(manuscriptId: id);
          },
        ),
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
            // Branch 1: Manuscript Library (home screen, per D-06)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.editor,
                  builder: (context, state) => const ManuscriptLibraryPage(),
                ),
              ],
            ),
            // Branch 2: Knowledge base
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.knowledge,
                  builder: (context, state) => const KnowledgeBasePage(),
                  routes: [
                    GoRoute(
                      path: 'character/new',
                      builder: (context, state) => const CharacterCardForm(),
                    ),
                    GoRoute(
                      path: 'character/:id',
                      builder: (context, state) {
                        final id = state.pathParameters['id'];
                        return CharacterCardForm(cardId: id);
                      },
                    ),
                    GoRoute(
                      path: 'setting/new',
                      builder: (context, state) => const WorldSettingForm(),
                    ),
                    GoRoute(
                      path: 'setting/:id',
                      builder: (context, state) {
                        final id = state.pathParameters['id'];
                        return WorldSettingForm(settingId: id);
                      },
                    ),
                    GoRoute(
                      path: 'skills',
                      builder: (context, state) => const SkillListPage(),
                    ),
                    GoRoute(
                      path: 'skills/new',
                      builder: (context, state) =>
                          const SkillGenerationWizard(),
                    ),
                    GoRoute(
                      path: 'templates',
                      builder: (context, state) => const TemplateGalleryPage(),
                    ),
                    GoRoute(
                      path: 'templates/:id/draft',
                      builder: (context, state) {
                        final id = state.pathParameters['id'];
                        final concept =
                            state.uri.queryParameters['concept'] ?? '';
                        return TemplateDraftPage(
                          templateId: id,
                          initialConcept: concept,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'templates/:id',
                      builder: (context, state) {
                        final id = state.pathParameters['id'];
                        return TemplatePreviewPage(templateId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Branch 3: Story Structure
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.storyStructure,
                  builder: (context, state) => const StoryStructurePage(),
                ),
              ],
            ),
            // Branch 4: Settings (with AI providers sub-route)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppConstants.stats,
                  builder: (context, state) => const WritingStatsPage(),
                  routes: [
                    GoRoute(
                      path: 'project',
                      builder: (context, state) => const ProjectStatsPage(),
                    ),
                    GoRoute(
                      path: 'tokens',
                      builder: (context, state) => const TokenAuditPage(),
                    ),
                    GoRoute(
                      path: 'reports',
                      builder: (context, state) => const ReportsHubPage(),
                      routes: [
                        GoRoute(
                          path: 'token-cost',
                          builder: (context, state) =>
                              const TokenCostReportPage(),
                        ),
                        GoRoute(
                          path: 'pain-points',
                          builder: (context, state) =>
                              const PainPointReportPage(),
                        ),
                        GoRoute(
                          path: 'anti-ai-scent',
                          builder: (context, state) => const SizedBox.shrink(),
                        ),
                        GoRoute(
                          path: 'consistency',
                          builder: (context, state) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Branch 5: Settings (with AI providers sub-route)
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
                    GoRoute(
                      path: 'banned-phrases',
                      builder: (context, state) =>
                          const BannedPhraseSettingsPage(),
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
      // If settings box is not yet open, allow normal navigation.
      // The onboarding check will run again once the box is available.
      return null;
    }
  }
}
