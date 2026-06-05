import 'package:museflow/features/stats/domain/daily_writing_stats.dart';

class StatsSnapshot {
  const StatsSnapshot({
    this.totalUnits = 0,
    this.humanUnits = 0,
    this.aiUnits = 0,
    this.writingDays = 0,
    this.sessionCount = 0,
    this.editSeconds = 0,
    this.daily = const [],
    this.projectStats = const {},
    this.currentProject,
  });

  final int totalUnits;
  final int humanUnits;
  final int aiUnits;
  final int writingDays;
  final int sessionCount;
  final int editSeconds;
  final List<DailyWritingStats> daily;
  final Map<String, StatsSnapshot> projectStats;
  final StatsSnapshot? currentProject;

  double get aiAssistRatio => totalUnits == 0 ? 0 : aiUnits / totalUnits;

  StatsSnapshot copyWith({
    int? totalUnits,
    int? humanUnits,
    int? aiUnits,
    int? writingDays,
    int? sessionCount,
    int? editSeconds,
    List<DailyWritingStats>? daily,
    Map<String, StatsSnapshot>? projectStats,
    StatsSnapshot? currentProject,
  }) {
    return StatsSnapshot(
      totalUnits: totalUnits ?? this.totalUnits,
      humanUnits: humanUnits ?? this.humanUnits,
      aiUnits: aiUnits ?? this.aiUnits,
      writingDays: writingDays ?? this.writingDays,
      sessionCount: sessionCount ?? this.sessionCount,
      editSeconds: editSeconds ?? this.editSeconds,
      daily: daily ?? this.daily,
      projectStats: projectStats ?? this.projectStats,
      currentProject: currentProject ?? this.currentProject,
    );
  }

  factory StatsSnapshot.fromJson(Map<String, dynamic> json) {
    final humanUnits = json['humanUnits'] as int? ?? 0;
    final aiUnits = json['aiUnits'] as int? ?? 0;
    return StatsSnapshot(
      totalUnits: json['totalUnits'] as int? ?? humanUnits + aiUnits,
      humanUnits: humanUnits,
      aiUnits: aiUnits,
      writingDays: json['writingDays'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
      editSeconds: json['editSeconds'] as int? ?? 0,
      daily: (json['daily'] as List<dynamic>? ?? const [])
          .map(
            (item) => DailyWritingStats.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUnits': totalUnits,
      'humanUnits': humanUnits,
      'aiUnits': aiUnits,
      'writingDays': writingDays,
      'sessionCount': sessionCount,
      'editSeconds': editSeconds,
      'daily': daily.map((item) => item.toJson()).toList(),
    };
  }
}
