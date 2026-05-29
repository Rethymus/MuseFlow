import 'package:hive/hive.dart';

part 'character_model.g.dart';

/// 角色卡数据模型
@HiveType(typeId: 10)
class CharacterModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int? age;

  @HiveField(3)
  String? appearance;

  @HiveField(4)
  String? personality;

  @HiveField(5)
  String? background;

  @HiveField(6)
  String? speakingStyle;

  @HiveField(7)
  List<String> relationships;

  @HiveField(8)
  List<String> tags;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  String? avatarPath;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  bool isActive;

  CharacterModel({
    required this.id,
    required this.name,
    this.age,
    this.appearance,
    this.personality,
    this.background,
    this.speakingStyle,
    List<String>? relationships,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.avatarPath,
    this.notes,
    this.isActive = true,
  })  : relationships = relationships ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 创建副本
  CharacterModel copyWith({
    String? id,
    String? name,
    int? age,
    String? appearance,
    String? personality,
    String? background,
    String? speakingStyle,
    List<String>? relationships,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarPath,
    String? notes,
    bool? isActive,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      appearance: appearance ?? this.appearance,
      personality: personality ?? this.personality,
      background: background ?? this.background,
      speakingStyle: speakingStyle ?? this.speakingStyle,
      relationships: relationships ?? List.from(this.relationships),
      tags: tags ?? List.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarPath: avatarPath ?? this.avatarPath,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'appearance': appearance,
      'personality': personality,
      'background': background,
      'speakingStyle': speakingStyle,
      'relationships': relationships,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'avatarPath': avatarPath,
      'notes': notes,
      'isActive': isActive,
    };
  }

  /// 从JSON创建
  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      appearance: json['appearance'] as String?,
      personality: json['personality'] as String?,
      background: json['background'] as String?,
      speakingStyle: json['speakingStyle'] as String?,
      relationships:
          (json['relationships'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      avatarPath: json['avatarPath'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// 生成AI提示词模板
  String generateAIPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('角色名称：$name');

    if (age != null) buffer.writeln('年龄：$age');
    if (appearance?.isNotEmpty == true) buffer.writeln('外貌：$appearance');
    if (personality?.isNotEmpty == true) buffer.writeln('性格：$personality');
    if (background?.isNotEmpty == true) buffer.writeln('背景：$background');
    if (speakingStyle?.isNotEmpty == true)
      buffer.writeln('说话风格：$speakingStyle');

    if (relationships.isNotEmpty) {
      buffer.writeln('人际关系：${relationships.join('、')}');
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
        (appearance?.toLowerCase().contains(lowerQuery) ?? false) ||
        (personality?.toLowerCase().contains(lowerQuery) ?? false) ||
        (background?.toLowerCase().contains(lowerQuery) ?? false) ||
        (speakingStyle?.toLowerCase().contains(lowerQuery) ?? false) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
        relationships.any((rel) => rel.toLowerCase().contains(lowerQuery));
  }

  @override
  String toString() {
    return 'CharacterModel(id: $id, name: $name, age: $age, tags: $tags)';
  }
}
