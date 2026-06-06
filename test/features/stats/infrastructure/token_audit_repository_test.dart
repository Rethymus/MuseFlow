import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';

void main() {
  late Box<dynamic> box;
  late TokenAuditRepository repository;

  setUp(() async {
    Hive.init('./test/.hive');
    box = await Hive.openBox<dynamic>('test_token_audit');
    repository = TokenAuditRepository(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await Hive.deleteBoxFromDisk('test_token_audit');
  });

  group('TokenAuditRepository', () {
    test('should save and load multiple records', () async {
      final records = [
        TokenAuditRecord(
          id: 'record-1',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'gpt-4o-mini',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript-1',
          timestamp: DateTime(2026, 6, 1),
        ),
        TokenAuditRecord(
          id: 'record-2',
          inputTokens: 150,
          outputTokens: 250,
          modelName: 'deepseek-chat',
          operationType: AuditOperationType.polish,
          manuscriptId: 'manuscript-1',
          chapterId: 'chapter-1',
          timestamp: DateTime(2026, 6, 2),
        ),
      ];

      await repository.saveAll(records);

      final loaded = await repository.loadAll();
      expect(loaded.length, 2);
      // Should be sorted by timestamp descending (newest first)
      expect(loaded[0].id, 'record-2');
      expect(loaded[1].id, 'record-1');
    });

    test('should return empty list when box is empty', () async {
      final loaded = await repository.loadAll();
      expect(loaded, isEmpty);
    });

    test('should enforce limit when count exceeds maxRecords', () async {
      final records = List.generate(
        15,
        (i) => TokenAuditRecord(
          id: 'record-$i',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime(2026, 6, 1).add(Duration(hours: i)),
        ),
      );

      await repository.saveAll(records);
      expect(box.length, 15);

      await repository.enforceLimit(10);
      expect(box.length, 10);

      final remaining = await repository.loadAll();
      // Should keep newest 10 records (record-5 through record-14)
      expect(remaining.first.id, 'record-14');
      expect(remaining.last.id, 'record-5');
    });

    test('should not delete anything when count is at limit', () async {
      final records = List.generate(
        10,
        (i) => TokenAuditRecord(
          id: 'record-$i',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime(2026, 6, 1).add(Duration(hours: i)),
        ),
      );

      await repository.saveAll(records);
      expect(box.length, 10);

      await repository.enforceLimit(10);
      expect(box.length, 10);
    });

    test('should not delete anything when count is below limit', () async {
      final records = List.generate(
        5,
        (i) => TokenAuditRecord(
          id: 'record-$i',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime(2026, 6, 1).add(Duration(hours: i)),
        ),
      );

      await repository.saveAll(records);
      expect(box.length, 5);

      await repository.enforceLimit(10);
      expect(box.length, 5);
    });

    test('should clear all records', () async {
      final records = [
        TokenAuditRecord(
          id: 'record-1',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime.now(),
        ),
      ];

      await repository.saveAll(records);
      expect(box.length, 1);

      await repository.clearAll();
      expect(box.length, 0);
    });

    test('should return correct count', () async {
      expect(repository.count, 0);

      final records = List.generate(
        3,
        (i) => TokenAuditRecord(
          id: 'record-$i',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime.now(),
        ),
      );

      await repository.saveAll(records);
      expect(repository.count, 3);
    });
  });
}
