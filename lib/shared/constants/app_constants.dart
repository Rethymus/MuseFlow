/// Application-wide constants for layout, routing, and window management.
abstract class AppConstants {
  AppConstants._();

  // --- Layout breakpoints ---
  /// Window width at which sidebar switches to extended mode (icon + label).
  static const double sidebarExtendedBreakpoint = 1000.0;

  /// Window width below which sidebar switches to bottom NavigationBar.
  static const double sidebarCollapsedBreakpoint = 600.0;

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
  static const String storyStructure = '/story-structure';
}
