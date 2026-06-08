import 'dart:async';

import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:uuid/uuid.dart';

/// Service for debatched token audit record writes.
///
/// Follows the same pattern as WritingStatsCollector with 30s debounce timer.
/// Buffers audit records in memory and flushes to Hive on timer, preventing
/// excessive I/O during rapid AI operations.
class TokenAuditService {
  TokenAuditService(
    this._repository,
    this._tokenBudgetCalculator, {
    this.debounceDuration = const Duration(seconds: 30),
    this._maxRecords = 10000,
  });

  final TokenAuditRepository _repository;
  final TokenBudgetCalculator _tokenBudgetCalculator;
  final Duration debounceDuration;
  final int _maxRecords;

  Timer? _flushTimer;
  final List<TokenAuditRecord> _pendingRecords = <TokenAuditRecord>[];

  /// Records an audit record with usage data and context.
  ///
  /// Uses API usage when provided, falls back to TokenBudgetCalculator
  /// estimation when usage is null.
  void recordAudit({
    required Usage? usage,
    required String modelName,
    required AuditOperationType operationType,
    required String manuscriptId,
    String? chapterId,
    required String inputText,
    required String outputText,
  }) {
    final inputTokens = usage?.promptTokens ??
        _tokenBudgetCalculator.estimateTokens(inputText);
    final outputTokens = usage?.completionTokens ??
        _tokenBudgetCalculator.estimateTokens(outputText);

    final record = TokenAuditRecord(
      id: const Uuid().v4(),
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      modelName: modelName,
      operationType: operationType,
      manuscriptId: manuscriptId,
      chapterId: chapterId,
      timestamp: DateTime.now(),
    );

    record_(record);
  }

  /// Buffers a record and schedules flush.
  void record_(TokenAuditRecord record) {
    _pendingRecords.add(record);
    _scheduleFlush();
  }

  /// Flushes all pending records to repository and enforces limit.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_pendingRecords.isEmpty) return;

    final records = List<TokenAuditRecord>.from(_pendingRecords);
    _pendingRecords.clear();

    await _repository.saveAll(records);
    await _repository.enforceLimit(_maxRecords);
  }

  /// Cancels timer and flushes remaining records.
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    unawaited(flush());
  }

  /// Schedules flush on debounce timer.
  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(debounceDuration, () {
      unawaited(flush());
    });
  }
}
