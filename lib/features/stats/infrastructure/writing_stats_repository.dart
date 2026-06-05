import 'package:hive_ce/hive.dart';
import 'package:museflow/features/stats/domain/achievement_badge.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';

class WritingStatsRepository {
  WritingStatsRepository(this._aggregateBox, this._dailyBox, [this._badgeBox]);

  static const globalKey = 'global';
  static const defaultProjectId = 'default';

  final Box<dynamic> _aggregateBox;
  final Box<dynamic> _dailyBox;
  final Box<dynamic>? _badgeBox;

  Future<StatsSnapshot> loadSnapshot({String? projectId}) async {
    final global = _readSnapshot(globalKey);
    final daily = await loadDailyStats();
    final projectKey = _projectKey(projectId ?? defaultProjectId);
    final currentProject = _readSnapshot(projectKey);

    return global.copyWith(
      writingDays: daily.where((day) => day.totalUnits > 0).length,
      daily: daily,
      currentProject: currentProject,
    );
  }

  Future<void> recordSessionDelta({
    String? projectId,
    String? documentId,
    required int humanUnits,
    required int aiUnits,
    required Duration editDuration,
    required DateTime occurredAt,
  }) async {
    final safeHumanUnits = humanUnits < 0 ? 0 : humanUnits;
    final safeAiUnits = aiUnits < 0 ? 0 : aiUnits;
    if (safeHumanUnits == 0 &&
        safeAiUnits == 0 &&
        editDuration.inSeconds <= 0) {
      return;
    }

    await _mergeAggregate(
      globalKey,
      humanUnits: safeHumanUnits,
      aiUnits: safeAiUnits,
      editSeconds: editDuration.inSeconds,
      occurredAt: occurredAt,
    );
    await _mergeAggregate(
      _projectKey(projectId ?? defaultProjectId),
      humanUnits: safeHumanUnits,
      aiUnits: safeAiUnits,
      editSeconds: editDuration.inSeconds,
      occurredAt: occurredAt,
    );
    await _mergeDaily(
      _dateKey(occurredAt),
      humanUnits: safeHumanUnits,
      aiUnits: safeAiUnits,
      editSeconds: editDuration.inSeconds,
    );
  }

  Future<List<DailyWritingStats>> loadDailyStats({int days = 30}) async {
    final stats = <DailyWritingStats>[];
    for (final value in _dailyBox.values) {
      stats.add(
        DailyWritingStats.fromJson(Map<String, dynamic>.from(value as Map)),
      );
    }
    stats.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    if (stats.length <= days) return stats;
    return stats.sublist(stats.length - days);
  }

  Future<void> clearAll() async {
    await _aggregateBox.clear();
    await _dailyBox.clear();
    await _badgeBox?.clear();
  }

  Future<List<AchievementBadge>> loadBadges() async {
    final box = _badgeBox;
    if (box == null) return const [];
    return box.values
        .map(
          (value) => AchievementBadge.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
  }

  Future<void> saveBadges(List<AchievementBadge> badges) async {
    final box = _badgeBox;
    if (box == null) return;
    for (final badge in badges) {
      await box.put(badge.id, badge.toJson());
    }
  }

  StatsSnapshot _readSnapshot(String key) {
    final value = _aggregateBox.get(key);
    if (value == null) return const StatsSnapshot();
    return StatsSnapshot.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> _mergeAggregate(
    String key, {
    required int humanUnits,
    required int aiUnits,
    required int editSeconds,
    required DateTime occurredAt,
  }) async {
    final current = _readSnapshot(key);
    final totalHuman = current.humanUnits + humanUnits;
    final totalAi = current.aiUnits + aiUnits;
    await _aggregateBox.put(
      key,
      current
          .copyWith(
            humanUnits: totalHuman,
            aiUnits: totalAi,
            totalUnits: totalHuman + totalAi,
            sessionCount: current.sessionCount + 1,
            editSeconds:
                current.editSeconds + (editSeconds < 0 ? 0 : editSeconds),
          )
          .toJson()
        ..addAll({'lastWrittenAt': occurredAt.toIso8601String()}),
    );
  }

  Future<void> _mergeDaily(
    String key, {
    required int humanUnits,
    required int aiUnits,
    required int editSeconds,
  }) async {
    final raw = _dailyBox.get(key);
    final current = raw == null
        ? DailyWritingStats(dateKey: key)
        : DailyWritingStats.fromJson(Map<String, dynamic>.from(raw as Map));
    await _dailyBox.put(
      key,
      current
          .copyWith(
            humanUnits: current.humanUnits + humanUnits,
            aiUnits: current.aiUnits + aiUnits,
            sessionCount: current.sessionCount + 1,
            editSeconds:
                current.editSeconds + (editSeconds < 0 ? 0 : editSeconds),
          )
          .toJson(),
    );
  }

  String _projectKey(String projectId) => 'project:$projectId';

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
