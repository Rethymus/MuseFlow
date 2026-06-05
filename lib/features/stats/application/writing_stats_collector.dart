import 'dart:async';

import 'package:museflow/features/stats/domain/writing_unit_counter.dart';
import 'package:museflow/features/stats/infrastructure/writing_stats_repository.dart';

class WritingStatsCollector {
  WritingStatsCollector(
    this._repository, {
    this.debounceDuration = const Duration(seconds: 30),
  });

  final WritingStatsRepository _repository;
  final Duration debounceDuration;

  Timer? _flushTimer;
  int? _lastTextUnits;
  int _pendingHumanUnits = 0;
  int _pendingAiUnits = 0;
  DateTime? _sessionStartedAt;
  DateTime? _lastActivityAt;
  String? _projectId;
  String? _documentId;

  void recordTextSnapshot(
    String plainText, {
    String? projectId,
    String? documentId,
  }) {
    final units = countWritingUnits(plainText);
    _projectId = projectId ?? _projectId;
    _documentId = documentId ?? _documentId;
    _sessionStartedAt ??= DateTime.now();
    _lastActivityAt = DateTime.now();

    final previous = _lastTextUnits;
    _lastTextUnits = units;
    if (previous == null) return;

    final delta = units - previous;
    if (delta > 0) {
      _pendingHumanUnits += delta;
      _scheduleFlush();
    }
  }

  void recordAiInsertion(String text, {String? projectId, String? documentId}) {
    final units = countWritingUnits(text);
    if (units == 0) return;

    _projectId = projectId ?? _projectId;
    _documentId = documentId ?? _documentId;
    _sessionStartedAt ??= DateTime.now();
    _lastActivityAt = DateTime.now();
    _pendingAiUnits += units;
    _lastTextUnits = (_lastTextUnits ?? 0) + units;
    _scheduleFlush();
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    final humanUnits = _pendingHumanUnits;
    final aiUnits = _pendingAiUnits;
    if (humanUnits == 0 && aiUnits == 0) return;

    final now = DateTime.now();
    final startedAt = _sessionStartedAt ?? now;
    final lastActivityAt = _lastActivityAt ?? now;
    _pendingHumanUnits = 0;
    _pendingAiUnits = 0;
    _sessionStartedAt = now;

    await _repository.recordSessionDelta(
      projectId: _projectId,
      documentId: _documentId,
      humanUnits: humanUnits,
      aiUnits: aiUnits,
      editDuration: lastActivityAt.difference(startedAt),
      occurredAt: now,
    );
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    unawaited(flush());
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(debounceDuration, () {
      unawaited(flush());
    });
  }
}
