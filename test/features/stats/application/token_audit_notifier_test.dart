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
    box = await Hive.openBox<dynamic>('test_token_audit_notifier');
    repository = TokenAuditRepository(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await Hive.deleteBoxFromDisk('test_token_audit_notifier');
  });

  group('TokenAuditNotifier', () {
    test('should return aggregated totals from repository', () async {
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
        TokenAuditRecord(
          id: 'record-3',
          inputTokens: 50,
          outputTokens: 100,
          modelName: 'gpt-4o-mini',
          operationType: AuditOperationType.rewrite,
          manuscriptId: 'manuscript-2',
          timestamp: DateTime(2026, 6, 3),
        ),
      ];

      await repository.saveAll(records);

      final snapshot = await repository.buildSnapshot();

      expect(snapshot.totalInputTokens, 300);
      expect(snapshot.totalOutputTokens, 550);
      expect(snapshot.totalCalls, 3);
      expect(snapshot.records.length, 3);
    });

    test('should return empty snapshot when no records exist', () async {
      final snapshot = await repository.buildSnapshot();

      expect(snapshot.totalInputTokens, 0);
      expect(snapshot.totalOutputTokens, 0);
      expect(snapshot.totalCalls, 0);
      expect(snapshot.records, isEmpty);
    });

    test('should include all records in snapshot', () async {
      final records = [
        TokenAuditRecord(
          id: 'record-1',
          inputTokens: 100,
          outputTokens: 200,
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          timestamp: DateTime(2026, 6, 1),
        ),
      ];

      await repository.saveAll(records);

      final snapshot = await repository.buildSnapshot();

      expect(snapshot.records.length, 1);
      expect(snapshot.records.first.id, 'record-1');
    });
  });

  group('TokenAuditSnapshot', () {
    test('should create with default values', () {
      const snapshot = TokenAuditSnapshot();

      expect(snapshot.totalInputTokens, 0);
      expect(snapshot.totalOutputTokens, 0);
      expect(snapshot.totalCalls, 0);
      expect(snapshot.records, isEmpty);
    });

    test('should create with custom values', () {
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

      final snapshot = TokenAuditSnapshot(
        totalInputTokens: 100,
        totalOutputTokens: 200,
        totalCalls: 1,
        records: records,
      );

      expect(snapshot.totalInputTokens, 100);
      expect(snapshot.totalOutputTokens, 200);
      expect(snapshot.totalCalls, 1);
      expect(snapshot.records.length, 1);
    });

    test('should support copyWith', () {
      const snapshot = TokenAuditSnapshot(
        totalInputTokens: 100,
        totalOutputTokens: 200,
        totalCalls: 1,
      );

      final updated = snapshot.copyWith(totalInputTokens: 150, totalCalls: 2);

      expect(updated.totalInputTokens, 150);
      expect(updated.totalOutputTokens, 200); // unchanged
      expect(updated.totalCalls, 2);
    });
  });
}
