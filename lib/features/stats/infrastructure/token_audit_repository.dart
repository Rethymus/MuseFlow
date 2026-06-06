import 'package:hive_ce/hive.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';

/// Repository for token audit records persistence.
///
/// Stores audit records in an independent Hive box with auto-cleanup
/// to prevent unbounded growth. Follows the same CRUD pattern as
/// WritingStatsRepository.
class TokenAuditRepository {
  TokenAuditRepository(this._box);

  final Box<dynamic> _box;

  /// Saves multiple audit records to the box.
  Future<void> saveAll(List<TokenAuditRecord> records) async {
    for (final record in records) {
      await _box.put(record.id, record.toJson());
    }
  }

  /// Loads all audit records, sorted by timestamp descending (newest first).
  Future<List<TokenAuditRecord>> loadAll() async {
    final records = <TokenAuditRecord>[];
    for (final value in _box.values) {
      records.add(
        TokenAuditRecord.fromJson(Map<String, dynamic>.from(value as Map)),
      );
    }
    // Sort by timestamp descending (newest first)
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  /// Enforces record limit by deleting oldest records when count exceeds maxRecords.
  ///
  /// Per D-06: Auto-cleanup with upper limit. When exceeded, oldest records
  /// deleted chronologically, keeping newest records.
  Future<void> enforceLimit(int maxRecords) async {
    final count = _box.length;
    if (count <= maxRecords) return;

    // Load all records and sort by timestamp ascending (oldest first)
    final records = <TokenAuditRecord>[];
    for (final value in _box.values) {
      records.add(
        TokenAuditRecord.fromJson(Map<String, dynamic>.from(value as Map)),
      );
    }
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Delete oldest records to get down to maxRecords
    final deleteCount = count - maxRecords;
    final keysToDelete = records.take(deleteCount).map((r) => r.id).toList();
    await _box.deleteAll(keysToDelete);
  }

  /// Removes all audit records from the box.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Returns the current count of audit records in the box.
  int get count => _box.length;

  /// Builds an aggregated snapshot from all records.
  ///
  /// This is used by TokenAuditNotifier to build the initial state.
  Future<TokenAuditSnapshot> buildSnapshot() async {
    final records = await loadAll();
    if (records.isEmpty) {
      return const TokenAuditSnapshot();
    }

    var totalInput = 0;
    var totalOutput = 0;
    for (final record in records) {
      totalInput += record.inputTokens;
      totalOutput += record.outputTokens;
    }

    return TokenAuditSnapshot(
      totalInputTokens: totalInput,
      totalOutputTokens: totalOutput,
      totalCalls: records.length,
      records: records,
    );
  }
}

/// Aggregated snapshot of token audit data.
///
/// Holds totals and the full list of records for UI display.
class TokenAuditSnapshot {
  const TokenAuditSnapshot({
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.totalCalls = 0,
    this.records = const [],
  });

  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCalls;
  final List<TokenAuditRecord> records;

  TokenAuditSnapshot copyWith({
    int? totalInputTokens,
    int? totalOutputTokens,
    int? totalCalls,
    List<TokenAuditRecord>? records,
  }) {
    return TokenAuditSnapshot(
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      totalCalls: totalCalls ?? this.totalCalls,
      records: records ?? this.records,
    );
  }
}
