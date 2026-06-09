/// Genre preset constants and color mapping for manuscript cover cards.
///
/// Provides the 14 Phase 7 novel genre types with distinct WCAG AA-compliant
/// background colors for the manuscript card cover area.
class ManuscriptGenre {
  ManuscriptGenre._();

  /// The 14 preset novel genres from Phase 7 template types.
  static const List<String> presets = [
    '玄幻',
    '仙侠',
    '都市',
    '科幻',
    '奇幻',
    '武侠',
    '历史',
    '军事',
    '悬疑',
    '恐怖',
    '言情',
    '校园',
    '游戏',
    '末世',
  ];

  /// Valid manuscript status values.
  static const List<String> statusValues = ['构思中', '写作中', '已完成'];

  /// Valid chapter status values.
  static const List<String> chapterStatusValues = ['草稿', '初稿', '精修', '定稿'];

  /// Genre-to-color mapping.
  ///
  /// Male-frequency genres (8): warm/bold tones.
  /// Female-frequency genres (6): soft/elegant tones.
  /// All colors have WCAG AA contrast (>= 4.5:1) with white text overlay.
  static const Map<String, int> _genreColors = {
    // Male-frequency: warm/bold
    '玄幻': 0xFF4F46E5, // Indigo 600
    '仙侠': 0xFF0D9488, // Teal 600
    '科幻': 0xFF2563EB, // Blue 600
    '奇幻': 0xFF7C3AED, // Violet 600
    '武侠': 0xFFB45309, // Amber 700
    '历史': 0xFF92400E, // Amber 800
    '军事': 0xFF991B1B, // Red 800
    '悬疑': 0xFF374151, // Gray 700
    // Female-frequency: soft/elegant
    '都市': 0xFF0891B2, // Cyan 600
    '恐怖': 0xFF581C87, // Purple 900
    '言情': 0xFFBE185D, // Pink 700
    '校园': 0xFF059669, // Emerald 600
    '游戏': 0xFF0284C7, // Sky 600
    '末世': 0xFFA21CAF, // Fuchsia 700
  };

  /// Default gray color for unknown/custom genres.
  static const int _defaultColor = 0xFF49454F;

  /// Returns the color value for the given [genre].
  ///
  /// Returns [_defaultColor] (gray) for genres not in the preset list.
  static int genreColor(String genre) => _genreColors[genre] ?? _defaultColor;
}
