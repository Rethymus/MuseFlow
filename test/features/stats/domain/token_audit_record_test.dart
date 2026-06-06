import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';

void main() {
  group('TokenAuditRecord', () {
    test('should round-trip through JSON with all 8 fields', () {
      final timestamp = DateTime(2026, 6, 6, 12, 30, 0);
      final record = TokenAuditRecord(
        id: 'test-id-123',
        inputTokens: 100,
        outputTokens: 200,
        modelName: 'gpt-4o-mini',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript-1',
        chapterId: 'chapter-1',
        timestamp: timestamp,
      );

      final json = record.toJson();
      final decoded = TokenAuditRecord.fromJson(json);

      expect(decoded.id, 'test-id-123');
      expect(decoded.inputTokens, 100);
      expect(decoded.outputTokens, 200);
      expect(decoded.modelName, 'gpt-4o-mini');
      expect(decoded.operationType, AuditOperationType.synthesis);
      expect(decoded.manuscriptId, 'manuscript-1');
      expect(decoded.chapterId, 'chapter-1');
      expect(decoded.timestamp, timestamp);
    });

    test('should round-trip through JSON with nullable chapterId', () {
      final timestamp = DateTime(2026, 6, 6, 12, 30, 0);
      final record = TokenAuditRecord(
        id: 'test-id-456',
        inputTokens: 150,
        outputTokens: 250,
        modelName: 'deepseek-chat',
        operationType: AuditOperationType.opening,
        manuscriptId: 'manuscript-2',
        chapterId: null,
        timestamp: timestamp,
      );

      final json = record.toJson();
      final decoded = TokenAuditRecord.fromJson(json);

      expect(decoded.id, 'test-id-456');
      expect(decoded.chapterId, isNull);
    });

    test('should store operationType as index in JSON', () {
      final record = TokenAuditRecord(
        id: 'test-id',
        inputTokens: 100,
        outputTokens: 200,
        modelName: 'model',
        operationType: AuditOperationType.polish,
        manuscriptId: 'manuscript',
        timestamp: DateTime.now(),
      );

      final json = record.toJson();
      expect(json['operationTypeIndex'], AuditOperationType.polish.index);
      expect(json.containsKey('operationType'), isFalse);
    });

    test('should parse operationType from index in JSON', () {
      final json = {
        'id': 'test-id',
        'inputTokens': 100,
        'outputTokens': 200,
        'modelName': 'model',
        'operationTypeIndex': 2, // polish is at index 2
        'manuscriptId': 'manuscript',
        'chapterId': null,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final record = TokenAuditRecord.fromJson(json);
      expect(record.operationType, AuditOperationType.polish);
    });

    test('should throw on missing required field: id', () {
      final json = {
        'inputTokens': 100,
        'outputTokens': 200,
        'modelName': 'model',
        'operationTypeIndex': 0,
        'manuscriptId': 'manuscript',
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => TokenAuditRecord.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('should throw on missing required field: inputTokens', () {
      final json = {
        'id': 'test-id',
        'outputTokens': 200,
        'modelName': 'model',
        'operationTypeIndex': 0,
        'manuscriptId': 'manuscript',
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => TokenAuditRecord.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('should throw on missing required field: outputTokens', () {
      final json = {
        'id': 'test-id',
        'inputTokens': 100,
        'modelName': 'model',
        'operationTypeIndex': 0,
        'manuscriptId': 'manuscript',
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => TokenAuditRecord.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('should throw on missing required field: modelName', () {
      final json = {
        'id': 'test-id',
        'inputTokens': 100,
        'outputTokens': 200,
        'operationTypeIndex': 0,
        'manuscriptId': 'manuscript',
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => TokenAuditRecord.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('should throw on missing required field: operationTypeIndex', () {
      final json = {
        'id': 'test-id',
        'inputTokens': 100,
        'outputTokens': 200,
        'modelName': 'model',
        'manuscriptId': 'manuscript',
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => TokenAuditRecord.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('should throw on missing required field: manuscriptId', () {
      final json = {
        'id': 'test-id',
        'inputTokens': 100,
        'outputTokens': 200,
        'modelName': 'model',
        'operationTypeIndex': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(() => TokenAuditRecord.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('should throw on missing required field: timestamp', () {
      final json = {
        'id': 'test-id',
        'inputTokens': 100,
        'outputTokens': 200,
        'modelName': 'model',
        'operationTypeIndex': 0,
        'manuscriptId': 'manuscript',
      };

      expect(() => TokenAuditRecord.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('totalTokens getter should return sum of input and output tokens', () {
      final record = TokenAuditRecord(
        id: 'test-id',
        inputTokens: 100,
        outputTokens: 200,
        modelName: 'model',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript',
        timestamp: DateTime.now(),
      );

      expect(record.totalTokens, 300);
    });

    test('should throw ArgumentError when inputTokens is negative', () {
      expect(
        () => TokenAuditRecord(
          id: 'test-id',
          inputTokens: -100,
          outputTokens: 200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw ArgumentError when outputTokens is negative', () {
      expect(
        () => TokenAuditRecord(
          id: 'test-id',
          inputTokens: 100,
          outputTokens: -200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should allow zero tokens', () {
      final record = TokenAuditRecord(
        id: 'test-id',
        inputTokens: 0,
        outputTokens: 0,
        modelName: 'model',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript',
        timestamp: DateTime.now(),
      );

      expect(record.totalTokens, 0);
    });
  });
}
