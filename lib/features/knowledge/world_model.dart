import 'package:hive/hive.dart';

part 'world_model.g.dart';

/// 地点信息
@HiveType(typeId: 11)
class Location extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<String> relatedCharacters;

  Location({
    required this.id,
    required this.name,
    required this.description,
    List<String>? relatedCharacters,
  }) : relatedCharacters = relatedCharacters ?? [];

  Location copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? relatedCharacters,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      relatedCharacters: relatedCharacters ?? List.from(this.relatedCharacters),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'relatedCharacters': relatedCharacters,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      relatedCharacters:
          (json['relatedCharacters'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// 势力组织
@HiveType(typeId: 12)
class Organization extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String? leader;

  @HiveField(4)
  List<String> members;

  @HiveField(5)
  String? philosophy;

  Organization({
    required this.id,
    required this.name,
    required this.description,
    this.leader,
    List<String>? members,
    this.philosophy,
  }) : members = members ?? [];

  Organization copyWith({
    String? id,
    String? name,
    String? description,
    String? leader,
    List<String>? members,
    String? philosophy,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      leader: leader ?? this.leader,
      members: members ?? List.from(this.members),
      philosophy: philosophy ?? this.philosophy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'leader': leader,
      'members': members,
      'philosophy': philosophy,
    };
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      leader: json['leader'] as String?,
      members: (json['members'] as List<dynamic>?)?.cast<String>() ?? [],
      philosophy: json['philosophy'] as String?,
    );
  }
}

/// 世界观设定数据模型
@HiveType(typeId: 13)
class WorldModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String worldType;

  @HiveField(3)
  String? era;

  @HiveField(4)
  String? magicSystem;

  @HiveField(5)
  String? technology;

  @HiveField(6)
  List<String> rules;

  @HiveField(7)
  List<Location> locations;

  @HiveField(8)
  List<Organization> organizations;

  @HiveField(9)
  String? geography;

  @HiveField(10)
  String? history;

  @HiveField(11)
  List<String> tags;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  @HiveField(14)
  String? notes;

  @HiveField(15)
  bool isActive;

  WorldModel({
    required this.id,
    required this.name,
    required this.worldType,
    this.era,
    this.magicSystem,
    this.technology,
    List<String>? rules,
    List<Location>? locations,
    List<Organization>? organizations,
    this.geography,
    this.history,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notes,
    this.isActive = true,
  })  : rules = rules ?? [],
        locations = locations ?? [],
        organizations = organizations ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 创建副本
  WorldModel copyWith({
    String? id,
    String? name,
    String? worldType,
    String? era,
    String? magicSystem,
    String? technology,
    List<String>? rules,
    List<Location>? locations,
    List<Organization>? organizations,
    String? geography,
    String? history,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isActive,
  }) {
    return WorldModel(
      id: id ?? this.id,
      name: name ?? this.name,
      worldType: worldType ?? this.worldType,
      era: era ?? this.era,
      magicSystem: magicSystem ?? this.magicSystem,
      technology: technology ?? this.technology,
      rules: rules ?? List.from(this.rules),
      locations: locations ?? this.locations.map((l) => l.copyWith()).toList(),
      organizations:
          organizations ?? this.organizations.map((o) => o.copyWith()).toList(),
      geography: geography ?? this.geography,
      history: history ?? this.history,
      tags: tags ?? List.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'worldType': worldType,
      'era': era,
      'magicSystem': magicSystem,
      'technology': technology,
      'rules': rules,
      'locations': locations.map((l) => l.toJson()).toList(),
      'organizations': organizations.map((o) => o.toJson()).toList(),
      'geography': geography,
      'history': history,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
    };
  }

  /// 从JSON创建
  factory WorldModel.fromJson(Map<String, dynamic> json) {
    return WorldModel(
      id: json['id'] as String,
      name: json['name'] as String,
      worldType: json['worldType'] as String,
      era: json['era'] as String?,
      magicSystem: json['magicSystem'] as String?,
      technology: json['technology'] as String?,
      rules: (json['rules'] as List<dynamic>?)?.cast<String>() ?? [],
      locations: (json['locations'] as List<dynamic>?)
              ?.map((l) => Location.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      organizations: (json['organizations'] as List<dynamic>?)
              ?.map((o) => Organization.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      geography: json['geography'] as String?,
      history: json['history'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// 生成AI提示词模板
  String generateAIPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('世界名称：$name');
    buffer.writeln('世界类型：$worldType');

    if (era?.isNotEmpty == true) buffer.writeln('时代：$era');
    if (magicSystem?.isNotEmpty == true) buffer.writeln('魔法体系：$magicSystem');
    if (technology?.isNotEmpty == true) buffer.writeln('科技水平：$technology');

    if (rules.isNotEmpty) {
      buffer.writeln('世界规则：');
      for (final rule in rules) {
        buffer.writeln('  - $rule');
      }
    }

    if (geography?.isNotEmpty == true) buffer.writeln('地理环境：$geography');
    if (history?.isNotEmpty == true) buffer.writeln('历史背景：$history');

    if (locations.isNotEmpty) {
      buffer.writeln('主要地点：');
      for (final location in locations) {
        buffer.writeln('  - ${location.name}：${location.description}');
      }
    }

    if (organizations.isNotEmpty) {
      buffer.writeln('主要势力：');
      for (final org in organizations) {
        buffer.writeln('  - ${org.name}：${org.description}');
        if (org.leader?.isNotEmpty == true)
          buffer.writeln('    领袖：${org.leader}');
      }
    }

    if (tags.isNotEmpty) {
      buffer.writeln('关键词：${tags.join('、')}');
    }

    if (notes?.isNotEmpty == true) buffer.writeln('备注：$notes');

    return buffer.toString().trim();
  }

  /// 搜索匹配检查
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        worldType.toLowerCase().contains(lowerQuery) ||
        (era?.toLowerCase().contains(lowerQuery) ?? false) ||
        (magicSystem?.toLowerCase().contains(lowerQuery) ?? false) ||
        (technology?.toLowerCase().contains(lowerQuery) ?? false) ||
        (geography?.toLowerCase().contains(lowerQuery) ?? false) ||
        (history?.toLowerCase().contains(lowerQuery) ?? false) ||
        rules.any((rule) => rule.toLowerCase().contains(lowerQuery)) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
        locations.any((loc) =>
            loc.name.toLowerCase().contains(lowerQuery) ||
            loc.description.toLowerCase().contains(lowerQuery)) ||
        organizations.any((org) =>
            org.name.toLowerCase().contains(lowerQuery) ||
            org.description.toLowerCase().contains(lowerQuery));
  }

  @override
  String toString() {
    return 'WorldModel(id: $id, name: $name, worldType: $worldType, tags: $tags)';
  }
}
