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
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      description: _optionalString(json, 'description'),
      genre: _requiredString(json, 'genre'),
      targetWordCount: _optionalInt(json, 'targetWordCount', 0),
      status: _optionalString(json, 'status') ?? '构思中',
      worldSettingId: _optionalString(json, 'worldSettingId'),
      characterCardIds: _optionalStringList(json, 'characterCardIds'),
      createdAt: _requiredDateTime(json, 'createdAt'),
      updatedAt: _requiredDateTime(json, 'updatedAt'),
      deletedAt: _optionalDateTime(json, 'deletedAt'),
      coverLetter: _optionalString(json, 'coverLetter') ?? '',
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

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Invalid Manuscript JSON: "$field" must be a string');
}

String? _optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Invalid Manuscript JSON: "$field" must be a string');
}

int _optionalInt(Map<String, dynamic> json, String field, int defaultValue) {
  final value = json[field];
  if (value == null) return defaultValue;
  if (value is int) return value;
  throw FormatException('Invalid Manuscript JSON: "$field" must be an int');
}

List<String> _optionalStringList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return const [];
  if (value is! List) {
    throw FormatException('Invalid Manuscript JSON: "$field" must be a list');
  }
  final result = <String>[];
  for (final item in value) {
    if (item is! String) {
      throw FormatException(
        'Invalid Manuscript JSON: "$field" must contain only strings',
      );
    }
    result.add(item);
  }
  return List.unmodifiable(result);
}

DateTime _requiredDateTime(Map<String, dynamic> json, String field) {
  final value = _requiredString(json, field);
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;
  throw FormatException(
    'Invalid Manuscript JSON: "$field" must be an ISO-8601 date',
  );
}

DateTime? _optionalDateTime(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException(
      'Invalid Manuscript JSON: "$field" must be an ISO-8601 date string',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;
  throw FormatException(
    'Invalid Manuscript JSON: "$field" must be an ISO-8601 date',
  );
}
