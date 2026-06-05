import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/knowledge_entity.dart';

/// A character card in the knowledge base.
///
/// Immutable entity representing a story character with personality,
/// appearance, backstory, and optional aliases. Used for AI context
/// injection during writing to maintain character consistency.
///
/// Use [copyWith] to create modified copies.
class CharacterCard implements KnowledgeEntity {
  final String id;
  final String name;
  final String personality;
  final String appearance;
  final String backstory;
  final List<String> aliases;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Creates a [CharacterCard] with field validation.
  ///
  /// Throws [ArgumentError] if:
  /// - [name] exceeds 100 characters
  /// - [personality], [appearance], or [backstory] exceed 5000 characters
  /// - [aliases] has more than 20 items or any item exceeds 50 characters
  CharacterCard({
    required this.id,
    required this.name,
    this.personality = '',
    this.appearance = '',
    this.backstory = '',
    this.aliases = const [],
    required this.createdAt,
    this.updatedAt,
  }) {
    // T-04-01: Validate field lengths at domain layer
    _validateNameText(name, 'name');
    if (name.length > 100) {
      throw ArgumentError.value(
        name,
        'name',
        'CharacterCard name must not exceed 100 characters (got ${name.length})',
      );
    }
    if (personality.length > 5000) {
      throw ArgumentError.value(
        personality,
        'personality',
        'CharacterCard personality must not exceed 5000 characters (got ${personality.length})',
      );
    }
    if (appearance.length > 5000) {
      throw ArgumentError.value(
        appearance,
        'appearance',
        'CharacterCard appearance must not exceed 5000 characters (got ${appearance.length})',
      );
    }
    if (backstory.length > 5000) {
      throw ArgumentError.value(
        backstory,
        'backstory',
        'CharacterCard backstory must not exceed 5000 characters (got ${backstory.length})',
      );
    }
    // T-04-02: Limit alias count and length
    if (aliases.length > 20) {
      throw ArgumentError.value(
        aliases,
        'aliases',
        'CharacterCard must not have more than 20 aliases (got ${aliases.length})',
      );
    }
    for (var i = 0; i < aliases.length; i++) {
      _validateNameText(aliases[i], 'aliases[$i]');
      if (aliases[i].length > 50) {
        throw ArgumentError.value(
          aliases[i],
          'aliases[$i]',
          'Each alias must not exceed 50 characters (got ${aliases[i].length})',
        );
      }
    }
  }

  /// Creates a copy with the given fields replaced.
  CharacterCard copyWith({
    String? id,
    String? name,
    String? personality,
    String? appearance,
    String? backstory,
    List<String>? aliases,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterCard(
      id: id ?? this.id,
      name: name ?? this.name,
      personality: personality ?? this.personality,
      appearance: appearance ?? this.appearance,
      backstory: backstory ?? this.backstory,
      aliases: aliases ?? this.aliases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a [CharacterCard] from a JSON map.
  factory CharacterCard.fromJson(Map<String, dynamic> json) {
    return CharacterCard(
      id: json['id'] as String,
      name: json['name'] as String,
      personality: json['personality'] as String? ?? '',
      appearance: json['appearance'] as String? ?? '',
      backstory: json['backstory'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Serializes this card to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'personality': personality,
      'appearance': appearance,
      'backstory': backstory,
      'aliases': aliases,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterCard &&
        other.id == id &&
        other.name == name &&
        other.personality == personality &&
        other.appearance == appearance &&
        other.backstory == backstory &&
        _listEquals(other.aliases, aliases) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        personality,
        appearance,
        backstory,
        Object.hashAll(aliases),
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'CharacterCard(id: $id, name: $name, personality: $personality, '
      'appearance: $appearance, backstory: $backstory, aliases: $aliases, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  // --- KnowledgeEntity interface ---

  @override
  String get displayName => name;

  @override
  EntityType get entityType => EntityType.character;

  @override
  List<String> get allNames => [name, ...aliases];

  @override
  String get toContextString {
    final buffer = StringBuffer()
      ..writeln('【角色】$name')
      ..writeln('性格：$personality')
      ..writeln('外貌：$appearance')
      ..writeln('背景：$backstory');
    return buffer.toString().trimRight();
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static void _validateNameText(String value, String fieldName) {
    if (_containsControlCharacter(value)) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Must not contain control characters',
      );
    }
  }

  static bool _containsControlCharacter(String value) {
    return value.runes.any((rune) => rune < 0x20 || rune == 0x7f);
  }
}
