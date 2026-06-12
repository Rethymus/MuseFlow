/// Character relationship types supported in the knowledge base.
///
/// Per Phase 21 (KNOW-02): Defines the types of relationships between
/// characters that can be tracked and injected into AI prompts.
enum RelationshipType {
  /// 师父-徒弟 / 导师-学生
  mentor('师徒'),

  /// 敌对关系
  enemy('敌对'),

  /// 家族关系（父子、兄弟、姐妹等）
  family('家族'),

  /// 恋人 / 伴侣
  lover('恋人'),

  /// 竞争对手（非敌对）
  rival('对手'),

  /// 盟友 / 合作伙伴
  ally('盟友'),

  /// 上下级关系（门派、组织）
  subordinate('上下级'),

  /// 朋友
  friend('朋友');

  const RelationshipType(this.label);

  /// Chinese display label for UI and AI prompts.
  final String label;

  /// Deserialize from JSON string.
  static RelationshipType fromJsonString(String value) {
    return RelationshipType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RelationshipType.friend,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// An immutable character-to-character relationship.
///
/// Tracks the directional relationship between two characters in the story.
/// Relationships are stored alongside CharacterCard data and injected into
/// AI prompts when either character appears in the current chapter text.
///
/// Use [copyWith] to create modified copies.
class CharacterRelationship {
  final String id;
  final String fromCharacterId;
  final String toCharacterId;
  final RelationshipType type;
  final String description;
  final DateTime createdAt;

  const CharacterRelationship({
    required this.id,
    required this.fromCharacterId,
    required this.toCharacterId,
    required this.type,
    this.description = '',
    required this.createdAt,
  });

  /// Creates a copy with the given fields replaced.
  CharacterRelationship copyWith({
    String? id,
    String? fromCharacterId,
    String? toCharacterId,
    RelationshipType? type,
    String? description,
    DateTime? createdAt,
  }) {
    return CharacterRelationship(
      id: id ?? this.id,
      fromCharacterId: fromCharacterId ?? this.fromCharacterId,
      toCharacterId: toCharacterId ?? this.toCharacterId,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Creates a [CharacterRelationship] from a JSON map.
  factory CharacterRelationship.fromJson(Map<String, dynamic> json) {
    return CharacterRelationship(
      id: json['id'] as String,
      fromCharacterId: json['fromCharacterId'] as String,
      toCharacterId: json['toCharacterId'] as String,
      type: RelationshipType.fromJsonString(json['type'] as String),
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Serializes this relationship to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromCharacterId': fromCharacterId,
      'toCharacterId': toCharacterId,
      'type': type.toJsonString(),
      if (description.isNotEmpty) 'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Generates a context string for AI prompt injection.
  ///
  /// [fromName] and [toName] are the display names of the characters.
  String toContextString(String fromName, String toName) {
    final buffer = StringBuffer()
      ..write(fromName)
      ..write('与')
      ..write(toName)
      ..write('是')
      ..write(type.label);
    if (description.isNotEmpty) {
      buffer.write('关系（');
      buffer.write(description);
      buffer.write('）');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterRelationship &&
        other.id == id &&
        other.fromCharacterId == fromCharacterId &&
        other.toCharacterId == toCharacterId &&
        other.type == type &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    fromCharacterId,
    toCharacterId,
    type,
    description,
    createdAt,
  );

  @override
  String toString() =>
      'CharacterRelationship(id: $id, from: $fromCharacterId, to: $toCharacterId, '
      'type: ${type.name})';
}
