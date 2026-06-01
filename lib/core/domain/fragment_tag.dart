/// Default fragment tag constants.
/// Tags are free-form string values, not an enum.
/// Users can create custom tags beyond these defaults.
class FragmentTags {
  FragmentTags._();

  /// Default story-level tag.
  static const String story = '故事';

  /// Default chapter-level tag.
  static const String chapter = '章节';

  /// Default scene-level tag.
  static const String scene = '场景';

  /// All default tags in display order.
  static const List<String> defaults = [story, chapter, scene];
}
