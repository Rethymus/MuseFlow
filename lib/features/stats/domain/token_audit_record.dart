import 'package:museflow/features/stats/domain/audit_operation_type.dart';

/// Immutable audit record for AI API token usage.
///
/// Records token consumption for each AI call with operation type,
/// associated manuscript/chapter IDs, and timestamp for tracking.
///
/// Per AUDIT-01: Captures input tokens, output tokens, model name,
/// operation type, manuscriptId, optional chapterId, and timestamp.
class TokenAuditRecord {
  const TokenAuditRecord({
    required this.id,
    required this.inputTokens,
    required this.outputTokens,
    required this.modelName,
    required this.operationType,
    required this.manuscriptId,
    this.chapterId,
    required this.timestamp,
  })  : assert(inputTokens >= 0, 'inputTokens must be non-negative'),
        assert(outputTokens >= 0, 'outputTokens must be non-negative');

  final String id;
  final int inputTokens;
  final int outputTokens;
  final String modelName;
  final AuditOperationType operationType;
  final String manuscriptId;
  final String? chapterId;
  final DateTime timestamp;

  /// Total tokens consumed (input + output)
  int get totalTokens => inputTokens + outputTokens;

  /// Creates a record from JSON.
  ///
  /// Parses operationType from index stored as 'operationTypeIndex'.
  factory TokenAuditRecord.fromJson(Map<String, dynamic> json) {
    return TokenAuditRecord(
      id: json['id'] as String,
      inputTokens: json['inputTokens'] as int,
      outputTokens: json['outputTokens'] as int,
      modelName: json['modelName'] as String,
      operationType: AuditOperationType.values[json['operationTypeIndex'] as int],
      manuscriptId: json['manuscriptId'] as String,
      chapterId: json['chapterId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts record to JSON.
  ///
  /// Stores operationType as index in 'operationTypeIndex' field.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'modelName': modelName,
      'operationTypeIndex': operationType.index,
      'manuscriptId': manuscriptId,
      'chapterId': chapterId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  TokenAuditRecord copyWith({
    String? id,
    int? inputTokens,
    int? outputTokens,
    String? modelName,
    AuditOperationType? operationType,
    String? manuscriptId,
    String? chapterId,
    DateTime? timestamp,
  }) {
    return TokenAuditRecord(
      id: id ?? this.id,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      modelName: modelName ?? this.modelName,
      operationType: operationType ?? this.operationType,
      manuscriptId: manuscriptId ?? this.manuscriptId,
      chapterId: chapterId ?? this.chapterId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenAuditRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          modelName == other.modelName &&
          operationType == other.operationType &&
          manuscriptId == other.manuscriptId &&
          chapterId == other.chapterId &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      inputTokens.hashCode ^
      outputTokens.hashCode ^
      modelName.hashCode ^
      operationType.hashCode ^
      manuscriptId.hashCode ^
      chapterId.hashCode ^
      timestamp.hashCode;
}
