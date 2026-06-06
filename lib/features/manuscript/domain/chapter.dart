/// A chapter within a [Manuscript], owning its own editor document content.
///
/// Immutable entity -- use [copyWith] to create modified copies.
/// The [documentContent] field stores serialized Markdown (NOT JSON).
/// [wordCount] is a computed getter from [documentContent].
class Chapter {
  final String id;
  final String manuscriptId;
  final String title;
  final int sortOrder;
  final String status; // 草稿/初稿/精修/定稿
  final String documentContent; // Serialized Markdown
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chapter({
    required this.id,
    required this.manuscriptId,
    required this.title,
    required this.sortOrder,
    this.status = '草稿',
    this.documentContent = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Word count computed from [documentContent].
  ///
  /// Counts characters excluding whitespace, which is the standard
  /// metric for Chinese text.
  int get wordCount {
    if (documentContent.isEmpty) return 0;
    return documentContent.replaceAll(RegExp(r'\s'), '').length;
  }

  /// Creates a copy of this chapter with the given fields replaced.
  Chapter copyWith({
    String? id,
    String? manuscriptId,
    String? title,
    int? sortOrder,
    String? status,
    String? documentContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      manuscriptId: manuscriptId ?? this.manuscriptId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      documentContent: documentContent ?? this.documentContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a Chapter from a JSON map.
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: _requiredString(json, 'id'),
      manuscriptId: _requiredString(json, 'manuscriptId'),
      title: _requiredString(json, 'title'),
      sortOrder: _requiredInt(json, 'sortOrder'),
      status: _optionalString(json, 'status') ?? '草稿',
      documentContent: _optionalString(json, 'documentContent') ?? '',
      createdAt: _requiredDateTime(json, 'createdAt'),
      updatedAt: _requiredDateTime(json, 'updatedAt'),
    );
  }

  /// Serializes this chapter to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manuscriptId': manuscriptId,
      'title': title,
      'sortOrder': sortOrder,
      'status': status,
      'documentContent': documentContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter &&
        other.id == id &&
        other.manuscriptId == manuscriptId &&
        other.title == title &&
        other.sortOrder == sortOrder &&
        other.status == status &&
        other.documentContent == documentContent &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    manuscriptId,
    title,
    sortOrder,
    status,
    documentContent,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'Chapter(id: $id, manuscriptId: $manuscriptId, title: $title, sortOrder: $sortOrder, status: $status)';
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Invalid Chapter JSON: "$field" must be a string');
}

String? _optionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Invalid Chapter JSON: "$field" must be a string');
}

int _requiredInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw FormatException('Invalid Chapter JSON: "$field" must be an int');
}

DateTime _requiredDateTime(Map<String, dynamic> json, String field) {
  final value = _requiredString(json, field);
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;
  throw FormatException(
    'Invalid Chapter JSON: "$field" must be an ISO-8601 date',
  );
}
