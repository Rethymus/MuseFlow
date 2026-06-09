import 'dart:convert';

import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/knowledge_entity.dart';

class SkillSections {
  static const int maxSectionLength = 10000;

  final String? powerHierarchy;
  final String? factionRelations;
  final String? rules;
  final String? taboos;
  final String? terminology;
  final String? rawContent;

  SkillSections({
    this.powerHierarchy,
    this.factionRelations,
    this.rules,
    this.taboos,
    this.terminology,
    this.rawContent,
  }) {
    _validateSection('powerHierarchy', powerHierarchy);
    _validateSection('factionRelations', factionRelations);
    _validateSection('rules', rules);
    _validateSection('taboos', taboos);
    _validateSection('terminology', terminology);
    _validateSection('rawContent', rawContent);
  }

  factory SkillSections.fromJson(Map<String, dynamic> json) {
    return SkillSections(
      powerHierarchy: json['powerHierarchy'] as String?,
      factionRelations: json['factionRelations'] as String?,
      rules: json['rules'] as String?,
      taboos: json['taboos'] as String?,
      terminology: json['terminology'] as String?,
      rawContent: json['rawContent'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'powerHierarchy': powerHierarchy,
    'factionRelations': factionRelations,
    'rules': rules,
    'taboos': taboos,
    'terminology': terminology,
    'rawContent': rawContent,
  };

  SkillSections copyWith({
    String? powerHierarchy,
    String? factionRelations,
    String? rules,
    String? taboos,
    String? terminology,
    String? rawContent,
  }) {
    return SkillSections(
      powerHierarchy: powerHierarchy ?? this.powerHierarchy,
      factionRelations: factionRelations ?? this.factionRelations,
      rules: rules ?? this.rules,
      taboos: taboos ?? this.taboos,
      terminology: terminology ?? this.terminology,
      rawContent: rawContent ?? this.rawContent,
    );
  }

  bool get isEmpty =>
      _isBlank(powerHierarchy) &&
      _isBlank(factionRelations) &&
      _isBlank(rules) &&
      _isBlank(taboos) &&
      _isBlank(terminology) &&
      _isBlank(rawContent);

  List<String> get nonNullSections {
    final names = <String>[];
    if (!_isBlank(powerHierarchy)) names.add('力量等级体系');
    if (!_isBlank(factionRelations)) names.add('门派/势力关系');
    if (!_isBlank(rules)) names.add('世界规则');
    if (!_isBlank(taboos)) names.add('禁忌/限制');
    if (!_isBlank(terminology)) names.add('专用术语');
    if (!_isBlank(rawContent)) names.add('原始内容');
    return names;
  }

  String toFormattedString() {
    final buffer = StringBuffer();
    void section(String title, String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('## $title');
      buffer.writeln(trimmed);
    }

    section('力量等级体系', powerHierarchy);
    section('门派/势力关系', factionRelations);
    section('世界规则', rules);
    section('禁忌/限制', taboos);
    section('专用术语', terminology);
    section('原始内容', rawContent);
    return buffer.toString().trim();
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  static void _validateSection(String fieldName, String? value) {
    if (value != null && value.length > maxSectionLength) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Skill section must not exceed $maxSectionLength characters (got ${value.length})',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillSections &&
          runtimeType == other.runtimeType &&
          powerHierarchy == other.powerHierarchy &&
          factionRelations == other.factionRelations &&
          rules == other.rules &&
          taboos == other.taboos &&
          terminology == other.terminology &&
          rawContent == other.rawContent;

  @override
  int get hashCode => Object.hash(
    powerHierarchy,
    factionRelations,
    rules,
    taboos,
    terminology,
    rawContent,
  );
}

class SkillDocument implements KnowledgeEntity {
  static const int maxContentLength = 50000;

  final String id;
  final String name;
  final String description;
  final String content;
  final SkillSections sections;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SkillDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.sections,
    this.isActive = false,
    required this.createdAt,
    this.updatedAt,
  }) {
    if (content.length > maxContentLength) {
      throw ArgumentError.value(
        content,
        'content',
        'SkillDocument content must not exceed $maxContentLength characters (got ${content.length})',
      );
    }
  }

  factory SkillDocument.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'];
    return SkillDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      sections: sectionsJson is Map
          ? SkillSections.fromJson(Map<String, dynamic>.from(sectionsJson))
          : SkillSections(),
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory SkillDocument.fromJsonString(String jsonString) {
    return SkillDocument.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'content': content,
    'sections': sections.toJson(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  SkillDocument copyWith({
    String? id,
    String? name,
    String? description,
    String? content,
    SkillSections? sections,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SkillDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      sections: sections ?? this.sections,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String get displayName => name;

  @override
  EntityType get entityType => EntityType.skill;

  @override
  List<String> get allNames => [name];

  @override
  String get toContextString {
    final formatted = sections.toFormattedString();
    return formatted.isNotEmpty ? formatted : content;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillDocument &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          content == other.content &&
          sections == other.sections &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    content,
    sections,
    isActive,
    createdAt,
    updatedAt,
  );
}
