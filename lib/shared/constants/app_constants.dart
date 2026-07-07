/// Application-wide constants for layout, routing, and window management.
abstract class AppConstants {
  AppConstants._();

  // --- Release metadata ---
  static const String appVersion = '0.1.5';

  // --- Layout breakpoints ---
  /// Window width at which sidebar switches to extended mode (icon + label).
  static const double sidebarExtendedBreakpoint = 1000.0;

  /// Window width below which sidebar switches to bottom NavigationBar.
  static const double sidebarCollapsedBreakpoint = 600.0;

  /// Width below which stats cards switch to single-column layout.
  static const double cardGridBreakpoint = 720.0;

  /// Width below which the editor chapter sidebar collapses to a drawer.
  static const double editorSidebarBreakpoint = 700.0;

  // --- Editor layout ---
  /// Maximum width for centered editor content area.
  static const double editorMaxWidth = 800.0;

  // --- Window defaults ---
  static const double defaultWindowWidth = 1200.0;
  static const double defaultWindowHeight = 800.0;
  static const double minimumWindowWidth = 800.0;
  static const double minimumWindowHeight = 600.0;

  // --- Route paths ---
  static const String capture = '/capture';
  static const String editor = '/editor';
  static const String settings = '/settings';
  static const String aiProviders = '/settings/ai-providers';
  static const String bannedPhrases = '/settings/banned-phrases';
  static const String knowledge = '/knowledge';
  static const String knowledgeCharacterNew = '/knowledge/character/new';
  static const String knowledgeSettingNew = '/knowledge/setting/new';
  static const String knowledgeTemplates = '/knowledge/templates';
  static const String knowledgeTemplateDraft = '/knowledge/templates/draft';
  static const String storyStructure = '/story-structure';
  static const String stats = '/stats';
  static const String statsProject = '/stats/project';
  static const String statsTokens = '/stats/tokens';
  static const String statsReports = '/stats/reports';
  static const String statsReportsTokenCost = '/stats/reports/token-cost';
  static const String statsReportsPainPoints = '/stats/reports/pain-points';
  static const String statsReportsAntiAiScent = '/stats/reports/anti-ai-scent';
  static const String statsReportsConsistency = '/stats/reports/consistency';
  static const String statsReportsEditorialReview =
      '/stats/reports/editorial-review';
  static const String statsProgress = '/stats/progress';
  static const String onboarding = '/onboarding';

  // --- Manuscript routes ---
  static const String manuscriptEditor = '/manuscript/:id/editor';
  static const String manuscriptSettings = '/manuscript/:id/settings';
  static const String manuscriptStyleProfile = '/manuscript/:id/style-profile';
}
