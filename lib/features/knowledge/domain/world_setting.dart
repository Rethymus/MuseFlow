import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/knowledge_entity.dart';

/// A world setting in the knowledge base.
///
/// Immutable entity representing a fictional world with its rules,
/// factions, geography, and technology level. Used for AI context
/// injection during writing to maintain world consistency.
///
/// Use [copyWith] to create modified copies.
class WorldSetting implements KnowledgeEntity {
  final String id;
  final String name;
  final String description;
  final String rules;
  final String factions;
  final String geography;
  final String techLevel;
  final List<String> aliases;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Creates a [WorldSetting] with field validation.
  ///
  /// Throws [ArgumentError] if:
  /// - [name] exceeds 100 characters
  /// - [description], [rules], [factions], [geography], or [techLevel] exceed 5000 characters
  /// - [aliases] has more than 20 items or any item exceeds 50 characters
  WorldSetting({
    required this.id,
    required this.name,
    this.description = '',
    this.rules = '',
    this.factions = '',
    this.geography = '',
    this.techLevel = '',
    this.aliases = const [],
    required this.createdAt,
    this.updatedAt,
  }) {
    // T-04-01: Validate field lengths at domain layer
    if (name.length > 100) {
      throw ArgumentError.value(
        name,
        'name',
        'WorldSetting name must not exceed 100 characters (got ${name.length})',
      );
    }
    if (description.length > 5000) {
      throw ArgumentError.value(
        description,
        'description',
        'WorldSetting description must not exceed 5000 characters (got ${description.length})',
      );
    }
    if (rules.length > 5000) {
      throw ArgumentError.value(
        rules,
        'rules',
        'WorldSetting rules must not exceed 5000 characters (got ${rules.length})',
      );
    }
    if (factions.length > 5000) {
      throw ArgumentError.value(
        factions,
        'factions',
        'WorldSetting factions must not exceed 5000 characters (got ${factions.length})',
      );
    }
    if (geography.length > 5000) {
      throw ArgumentError.value(
        geography,
        'geography',
        'WorldSetting geography must not exceed 5000 characters (got ${geography.length})',
      );
    }
    if (techLevel.length > 5000) {
      throw ArgumentError.value(
        techLevel,
        'techLevel',
        'WorldSetting techLevel must not exceed 5000 characters (got ${techLevel.length})',
      );
    }
    // T-04-02: Limit alias count and length
    if (aliases.length > 20) {
      throw ArgumentError.value(
        aliases,
        'aliases',
        'WorldSetting must not have more than 20 aliases (got ${aliases.length})',
      );
    }
    for (var i = 0; i < aliases.length; i++) {
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
  WorldSetting copyWith({
    String? id,
    String? name,
    String? description,
    String? rules,
    String? factions,
    String? geography,
    String? techLevel,
    List<String>? aliases,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorldSetting(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      factions: factions ?? this.factions,
      geography: geography ?? this.geography,
      techLevel: techLevel ?? this.techLevel,
      aliases: aliases ?? this.aliases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a [WorldSetting] from a JSON map.
  factory WorldSetting.fromJson(Map<String, dynamic> json) {
    return WorldSetting(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      rules: json['rules'] as String? ?? '',
      factions: json['factions'] as String? ?? '',
      geography: json['geography'] as String? ?? '',
      techLevel: json['techLevel'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Serializes this setting to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rules': rules,
      'factions': factions,
      'geography': geography,
      'techLevel': techLevel,
      'aliases': aliases,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorldSetting &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.rules == rules &&
        other.factions == factions &&
        other.geography == geography &&
        other.techLevel == techLevel &&
        _listEquals(other.aliases, aliases) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        rules,
        factions,
        geography,
        techLevel,
        Object.hashAll(aliases),
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'WorldSetting(id: $id, name: $name, description: $description, '
      'rules: $rules, factions: $factions, geography: $geography, '
      'techLevel: $techLevel, aliases: $aliases, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';

  // --- KnowledgeEntity interface ---

  @override
  String get displayName => name;

  @override
  EntityType get entityType => EntityType.setting;

  @override
  List<String> get allNames => [name, ...aliases];

  @override
  String get toContextString {
    final buffer = StringBuffer()
      ..writeln('【世界观】$name')
      ..writeln('规则：$rules')
      ..writeln('势力：$factions')
      ..writeln('地理：$geography')
      ..writeln('科技等级：$techLevel');
    return buffer.toString().trimRight();
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
