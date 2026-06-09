import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';

void main() {
  group('TokenAuditRecord', () {
    TokenAuditRecord createRecord({
      String id = 'test-id',
      int inputTokens = 100,
      int outputTokens = 50,
      String modelName = 'gpt-4o-mini',
      AuditOperationType operationType = AuditOperationType.synthesis,
      String manuscriptId = 'manuscript-1',
      String? chapterId,
      DateTime? timestamp,
    }) {
      return TokenAuditRecord(
        id: id,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        modelName: modelName,
        operationType: operationType,
        manuscriptId: manuscriptId,
        chapterId: chapterId,
        timestamp: timestamp ?? DateTime(2026, 1, 15, 10, 30),
      );
    }

    group('construction', () {
      test('should create record with all fields', () {
        final record = createRecord(chapterId: 'chapter-1');

        expect(record.id, 'test-id');
        expect(record.inputTokens, 100);
        expect(record.outputTokens, 50);
        expect(record.modelName, 'gpt-4o-mini');
        expect(record.operationType, AuditOperationType.synthesis);
        expect(record.manuscriptId, 'manuscript-1');
        expect(record.chapterId, 'chapter-1');
        expect(record.timestamp, DateTime(2026, 1, 15, 10, 30));
      });

      test('should create record with nullable chapterId', () {
        final record = createRecord(chapterId: null);
        expect(record.chapterId, isNull);
      });

      test('should throw AssertionError when inputTokens is negative', () {
        expect(
          () => createRecord(inputTokens: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw AssertionError when outputTokens is negative', () {
        expect(
          () => createRecord(outputTokens: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should allow zero tokens', () {
        final record = createRecord(inputTokens: 0, outputTokens: 0);

        expect(record.inputTokens, 0);
        expect(record.outputTokens, 0);
        expect(record.totalTokens, 0);
      });
    });

    group('totalTokens', () {
      test('should return inputTokens + outputTokens', () {
        final record = createRecord(inputTokens: 100, outputTokens: 50);
        expect(record.totalTokens, 150);
      });

      test('should return 0 when both are zero', () {
        final record = createRecord(inputTokens: 0, outputTokens: 0);
        expect(record.totalTokens, 0);
      });
    });

    group('serialization', () {
      test('should round-trip through JSON with all 8 fields', () {
        final timestamp = DateTime(2026, 6, 6, 12, 30, 0);
        final original = createRecord(
          id: 'test-id-123',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'gpt-4o-mini',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript-1',
          chapterId: 'chapter-1',
          timestamp: timestamp,
        );

        final json = original.toJson();
        final decoded = TokenAuditRecord.fromJson(json);

        expect(decoded.id, original.id);
        expect(decoded.inputTokens, original.inputTokens);
        expect(decoded.outputTokens, original.outputTokens);
        expect(decoded.modelName, original.modelName);
        expect(decoded.operationType, original.operationType);
        expect(decoded.manuscriptId, original.manuscriptId);
        expect(decoded.chapterId, original.chapterId);
        expect(decoded.timestamp, original.timestamp);
      });

      test('should round-trip through JSON with nullable chapterId', () {
        final original = createRecord(chapterId: null);

        final json = original.toJson();
        final decoded = TokenAuditRecord.fromJson(json);

        expect(decoded.id, original.id);
        expect(decoded.chapterId, isNull);
      });

      test('should store operationType as index in JSON', () {
        final record = createRecord(operationType: AuditOperationType.polish);

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
          'operationTypeIndex': 2,
          'manuscriptId': 'manuscript',
          'chapterId': null,
          'timestamp': DateTime.now().toIso8601String(),
        };

        final record = TokenAuditRecord.fromJson(json);
        expect(record.operationType, AuditOperationType.polish);
      });

      test('should handle all 8 operation types in round-trip', () {
        for (final type in AuditOperationType.values) {
          final record = createRecord(operationType: type);
          final json = record.toJson();
          final restored = TokenAuditRecord.fromJson(json);

          expect(
            restored.operationType,
            type,
            reason: 'Failed for ${type.name}',
          );
        }
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

        expect(
          () => TokenAuditRecord.fromJson(json),
          throwsA(isA<TypeError>()),
        );
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

        expect(
          () => TokenAuditRecord.fromJson(json),
          throwsA(isA<TypeError>()),
        );
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

        expect(
          () => TokenAuditRecord.fromJson(json),
          throwsA(isA<TypeError>()),
        );
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

        expect(
          () => TokenAuditRecord.fromJson(json),
          throwsA(isA<TypeError>()),
        );
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

        expect(
          () => TokenAuditRecord.fromJson(json),
          throwsA(isA<TypeError>()),
        );
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

        expect(
          () => TokenAuditRecord.fromJson(json),
          throwsA(isA<TypeError>()),
        );
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

        expect(
          () => TokenAuditRecord.fromJson(json),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = createRecord();
        final copied = original.copyWith(inputTokens: 200, outputTokens: 100);

        expect(copied.inputTokens, 200);
        expect(copied.outputTokens, 100);
        expect(copied.id, original.id);
        expect(copied.modelName, original.modelName);
      });

      test('should keep original values when not specified', () {
        final original = createRecord();
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.inputTokens, original.inputTokens);
        expect(copied.outputTokens, original.outputTokens);
      });
    });
  });
}
