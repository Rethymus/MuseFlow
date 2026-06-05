class DailyWritingStats {
  const DailyWritingStats({
    required this.dateKey,
    this.humanUnits = 0,
    this.aiUnits = 0,
    this.sessionCount = 0,
    this.editSeconds = 0,
  });

  final String dateKey;
  final int humanUnits;
  final int aiUnits;
  final int sessionCount;
  final int editSeconds;

  int get totalUnits => humanUnits + aiUnits;

  DailyWritingStats copyWith({
    String? dateKey,
    int? humanUnits,
    int? aiUnits,
    int? sessionCount,
    int? editSeconds,
  }) {
    return DailyWritingStats(
      dateKey: dateKey ?? this.dateKey,
      humanUnits: humanUnits ?? this.humanUnits,
      aiUnits: aiUnits ?? this.aiUnits,
      sessionCount: sessionCount ?? this.sessionCount,
      editSeconds: editSeconds ?? this.editSeconds,
    );
  }

  factory DailyWritingStats.fromJson(Map<String, dynamic> json) {
    return DailyWritingStats(
      dateKey: json['dateKey'] as String,
      humanUnits: json['humanUnits'] as int? ?? 0,
      aiUnits: json['aiUnits'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
      editSeconds: json['editSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'humanUnits': humanUnits,
      'aiUnits': aiUnits,
      'sessionCount': sessionCount,
      'editSeconds': editSeconds,
    };
  }
}
