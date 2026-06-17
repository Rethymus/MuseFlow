/// AI-generated summary of a single chapter's plot, used to inject compact
/// long-form context into subsequent-chapter prompts (MC-02). Pure immutable
/// Dart entity — no Flutter dependency (domain layer rule).
///
/// [sourceWordCount] captures the source [Chapter.documentContent] length at
/// summarization time so a stale summary (chapter grew since) can be detected
/// and refreshed — mirrors the KbStalenessChecker lastVerifiedChapter pattern.
class ChapterSummary {
  final String id;
  final String chapterId;
  final String manuscriptId;
  final String summary;
  final int sourceWordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChapterSummary({
    required this.id,
    required this.chapterId,
    required this.manuscriptId,
    required this.summary,
    required this.sourceWordCount,
    required this.createdAt,
    required this.updatedAt,
  });

  ChapterSummary copyWith({
    String? id,
    String? chapterId,
    String? manuscriptId,
    String? summary,
    int? sourceWordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChapterSummary(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      manuscriptId: manuscriptId ?? this.manuscriptId,
      summary: summary ?? this.summary,
      sourceWordCount: sourceWordCount ?? this.sourceWordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'manuscriptId': manuscriptId,
    'summary': summary,
    'sourceWordCount': sourceWordCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    return ChapterSummary(
      id: json['id'] as String,
      chapterId: json['chapterId'] as String,
      manuscriptId: json['manuscriptId'] as String,
      summary: json['summary'] as String,
      sourceWordCount: (json['sourceWordCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ChapterSummary && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
