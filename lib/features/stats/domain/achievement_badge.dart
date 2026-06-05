enum AchievementBadgeType {
  totalWords,
  streakDays;

  static AchievementBadgeType fromJsonString(String value) {
    return AchievementBadgeType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AchievementBadgeType.totalWords,
    );
  }
}

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.threshold,
    this.unlockedAt,
    this.progress = 0,
  });

  final String id;
  final String title;
  final String description;
  final AchievementBadgeType type;
  final int threshold;
  final DateTime? unlockedAt;
  final int progress;

  bool get isUnlocked => unlockedAt != null;

  AchievementBadge copyWith({
    String? id,
    String? title,
    String? description,
    AchievementBadgeType? type,
    int? threshold,
    DateTime? unlockedAt,
    int? progress,
  }) {
    return AchievementBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }

  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: AchievementBadgeType.fromJsonString(json['type'] as String),
      threshold: json['threshold'] as int,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: json['progress'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'threshold': threshold,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
    };
  }
}
