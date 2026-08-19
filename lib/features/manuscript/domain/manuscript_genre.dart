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

  /// Genre-to-color mapping, on Apple system hues.
  ///
  /// Male-frequency genres (8): bold tones. Female-frequency genres (6):
  /// soft/elegant tones. Covers pair these with white display text plus a
  /// subtle dark scrim rendered by the card, keeping the hues legible.
  static const Map<String, int> _genreColors = {
    // Male-frequency: bold
    '玄幻': 0xFF5856D7, // systemIndigo
    '仙侠': 0xFF30B0C7, // systemTeal
    '科幻': 0xFF007AFF, // systemBlue
    '奇幻': 0xFFAF52DE, // systemPurple
    '武侠': 0xFFE07600, // systemOrange (slightly deepened for white text)
    '历史': 0xFFA2845E, // systemBrown
    '军事': 0xFFD70015, // systemRed (slightly deepened)
    '悬疑': 0xFF3A3A3C, // dark gray
    // Female-frequency: soft/elegant
    '都市': 0xFF32ADE6, // systemCyan
    '恐怖': 0xFF5E3D99, // deep violet
    '言情': 0xFFE0407B, // systemPink (slightly deepened)
    '校园': 0xFF28A745, // systemGreen (slightly deepened)
    '游戏': 0xFF00A9B8, // systemMint (slightly deepened)
    '末世': 0xFF8E44AD, // deep fuchsia
  };

  /// Default gray color for unknown/custom genres (systemGray, deepened).
  static const int _defaultColor = 0xFF636366;

  /// Returns the color value for the given [genre].
  ///
  /// Returns [_defaultColor] (gray) for genres not in the preset list.
  static int genreColor(String genre) => _genreColors[genre] ?? _defaultColor;
}
