/// A structured export model for a single chapter.
///
/// Used when building chapter-aware export bundles. Contains the chapter's
/// title, its position in the manuscript, and its content as Markdown.
class ChapterExport {
  final String title;
  final int sortOrder;
  final String content;

  const ChapterExport({
    required this.title,
    required this.sortOrder,
    required this.content,
  });

  /// Creates a ChapterExport from a JSON map.
  factory ChapterExport.fromJson(Map<String, dynamic> json) {
    return ChapterExport(
      title: json['title'] as String,
      sortOrder: json['sortOrder'] as int,
      content: json['content'] as String,
    );
  }

  /// Serializes this chapter export to a JSON map.
  Map<String, dynamic> toJson() {
    return {'title': title, 'sortOrder': sortOrder, 'content': content};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterExport &&
        other.title == title &&
        other.sortOrder == sortOrder &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(title, sortOrder, content);

  @override
  String toString() =>
      'ChapterExport(title: $title, sortOrder: $sortOrder, content: ${content.length} chars)';
}
