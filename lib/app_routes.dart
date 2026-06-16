part of 'app.dart';

/// Routes table for [MuseFlowApp].
///
/// Extracted from app.dart to satisfy the 03-flutter-standards.md file-size
/// cap. Dart does not allow splitting a single class body across files, so
/// the GoRouter construction and the routes table live in this private
/// extension. [MuseFlowApp.build] invokes [createRouter] via a bare name —
/// Dart resolves same-library extension-on-this members transparently, so the
/// call site is unchanged. [_handleRedirect] stays in app.dart as a private
/// method of [MuseFlowApp]; the `redirect: _handleRedirect` reference below
/// resolves through same-library part visibility (the part file shares the
/// main library's scope).
extension _MuseFlowAppRoutes on MuseFlowApp {
  GoRouter createRouter() {
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
        GoRoute(
          path: AppConstants.manuscriptStyleProfile,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return AuthorStyleProfilePage(manuscriptId: id);
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
                      path: 'progress',
                      builder: (context, state) =>
                          const ProgressDashboardPage(),
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
                          builder: (context, state) => const BlindReadPage(),
                        ),
                        GoRoute(
                          path: 'consistency',
                          builder: (context, state) =>
                              const ConsistencyReportPage(),
                        ),
                        GoRoute(
                          path: 'editorial-review',
                          builder: (context, state) =>
                              const EditorialReviewPage(),
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
}
