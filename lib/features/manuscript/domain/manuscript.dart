const _copyWithSentinel = Object();

/// A manuscript container that owns multiple [Chapter] entities.
///
/// Immutable entity -- use [copyWith] to create modified copies.
/// Follows the same pattern as [Fragment] in lib/core/domain/fragment.dart.
class Manuscript {
  final String id;
  final String title;
  final String? description;
  final String genre;
  final int targetWordCount;
  final String status; // 构思中/写作中/已完成
  final String? worldSettingId;
  final List<String> characterCardIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String coverLetter; // max 2 chars for card display

  const Manuscript({
    required this.id,
    required this.title,
    this.description,
    required this.genre,
    this.targetWordCount = 0,
    this.status = '构思中',
    this.worldSettingId,
    this.characterCardIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.coverLetter = '',
  });

  /// Creates a copy of this manuscript with the given fields replaced.
  Manuscript copyWith({
    String? id,
    String? title,
    Object? description = _copyWithSentinel,
    String? genre,
    int? targetWordCount,
    String? status,
    Object? worldSettingId = _copyWithSentinel,
    List<String>? characterCardIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _copyWithSentinel,
    String? coverLetter,
  }) {
    return Manuscript(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description == _copyWithSentinel
          ? this.description
          : description as String?,
      genre: genre ?? this.genre,
      targetWordCount: targetWordCount ?? this.targetWordCount,
      status: status ?? this.status,
      worldSettingId: worldSettingId == _copyWithSentinel
          ? this.worldSettingId
          : worldSettingId as String?,
      characterCardIds: characterCardIds ?? this.characterCardIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt == _copyWithSentinel
          ? this.deletedAt
          : deletedAt as DateTime?,
      coverLetter: coverLetter ?? this.coverLetter,
    );
  }

  /// Creates a Manuscript from a JSON map.
  factory Manuscript.fromJson(Map<String, dynamic> json) {
    return Manuscript(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      genre: json['genre'] as String,
      targetWordCount: json['targetWordCount'] as int? ?? 0,
      status: json['status'] as String? ?? '构思中',
      worldSettingId: json['worldSettingId'] as String?,
      characterCardIds:
          (json['characterCardIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      coverLetter: json['coverLetter'] as String? ?? '',
    );
  }

  /// Serializes this manuscript to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'targetWordCount': targetWordCount,
      'status': status,
      'worldSettingId': worldSettingId,
      'characterCardIds': characterCardIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'coverLetter': coverLetter,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manuscript &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.genre == genre &&
        other.targetWordCount == targetWordCount &&
        other.status == status &&
        other.worldSettingId == worldSettingId &&
        _listEquals(other.characterCardIds, characterCardIds) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt &&
        other.coverLetter == coverLetter;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    genre,
    targetWordCount,
    status,
    worldSettingId,
    Object.hashAll(characterCardIds),
    createdAt,
    updatedAt,
    deletedAt,
    coverLetter,
  );

  @override
  String toString() =>
      'Manuscript(id: $id, title: $title, genre: $genre, status: $status)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
