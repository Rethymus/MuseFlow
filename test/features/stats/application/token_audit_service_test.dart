
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  late Box<dynamic> box;
  late TokenAuditRepository repository;
  late TokenBudgetCalculator calculator;
  late TokenAuditService service;

  setUp(() async {
    Hive.init('./test/.hive');
    box = await Hive.openBox<dynamic>('test_token_audit_service');
    repository = TokenAuditRepository(box);
    calculator = TokenBudgetCalculator();
    service = TokenAuditService(
      repository,
      calculator,
      debounceDuration: const Duration(milliseconds: 100),
      maxRecords: 10,
    );
  });

  tearDown(() async {
    service.dispose();
    await box.clear();
    await box.close();
    await Hive.deleteBoxFromDisk('test_token_audit_service');
  });

  group('TokenAuditService', () {
    test('should buffer record and schedule flush', () async {
      service.recordAudit(
        usage: const Usage(promptTokens: 100, completionTokens: 200, totalTokens: 100 + 200),
        modelName: 'gpt-4o-mini',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript-1',
        inputText: 'input',
        outputText: 'output',
      );

      // Record is buffered, not written yet
      expect(repository.count, 0);

      // Wait for debounce timer to flush
      await Future.delayed(const Duration(milliseconds: 150));

      // Now it should be written
      expect(repository.count, 1);

      final records = await repository.loadAll();
      expect(records.first.inputTokens, 100);
      expect(records.first.outputTokens, 200);
      expect(records.first.modelName, 'gpt-4o-mini');
      expect(records.first.operationType, AuditOperationType.synthesis);
      expect(records.first.manuscriptId, 'manuscript-1');
    });

    test('should flush all buffered records to repository', () async {
      service.recordAudit(
        usage: const Usage(promptTokens: 100, completionTokens: 200, totalTokens: 100 + 200),
        modelName: 'model-1',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript-1',
        inputText: 'input1',
        outputText: 'output1',
      );

      service.recordAudit(
        usage: const Usage(promptTokens: 150, completionTokens: 250, totalTokens: 150 + 250),
        modelName: 'model-2',
        operationType: AuditOperationType.polish,
        manuscriptId: 'manuscript-1',
        chapterId: 'chapter-1',
        inputText: 'input2',
        outputText: 'output2',
      );

      expect(repository.count, 0);

      await service.flush();

      expect(repository.count, 2);
    });

    test('should call enforceLimit after flush', () async {
      // Add 12 records (exceeds maxRecords of 10)
      for (var i = 0; i < 12; i++) {
        service.recordAudit(
          usage: Usage(promptTokens: 100, completionTokens: 200, totalTokens: 100 + 200),
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          inputText: 'input',
          outputText: 'output',
        );
      }

      await service.flush();

      // Should only have 10 records (maxRecords limit enforced)
      expect(repository.count, 10);
    });

    test('should use Usage promptTokens and completionTokens when provided', () async {
      service.recordAudit(
        usage: const Usage(promptTokens: 123, completionTokens: 456, totalTokens: 123 + 456),
        modelName: 'model',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript',
        inputText: 'This would estimate differently',
        outputText: 'But we use the API usage',
      );

      await service.flush();

      final records = await repository.loadAll();
      expect(records.first.inputTokens, 123);
      expect(records.first.outputTokens, 456);
    });

    test('should fallback to TokenBudgetCalculator when usage is null', () async {
      service.recordAudit(
        usage: null,
        modelName: 'model',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript',
        inputText: '你好世界',
        outputText: '再见世界',
      );

      await service.flush();

      final records = await repository.loadAll();
      // TokenBudgetCalculator estimates Chinese at 1.8 tokens per char + 10% margin
      // "你好世界" = 4 chars * 1.8 * 1.1 = 7.92 -> 8 tokens
      // "再见世界" = 4 chars * 1.8 * 1.1 = 7.92 -> 8 tokens
      expect(records.first.inputTokens, greaterThan(0));
      expect(records.first.outputTokens, greaterThan(0));
    });

    test('should cancel timer and flush on dispose', () async {
      service.recordAudit(
        usage: const Usage(promptTokens: 100, completionTokens: 200, totalTokens: 100 + 200),
        modelName: 'model',
        operationType: AuditOperationType.synthesis,
        manuscriptId: 'manuscript',
        inputText: 'input',
        outputText: 'output',
      );

      expect(repository.count, 0);

      service.dispose();

      // Dispose should flush immediately
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repository.count, 1);
    });

    test('should handle chapterId when provided', () async {
      service.recordAudit(
        usage: const Usage(promptTokens: 100, completionTokens: 200, totalTokens: 100 + 200),
        modelName: 'model',
        operationType: AuditOperationType.polish,
        manuscriptId: 'manuscript-1',
        chapterId: 'chapter-1',
        inputText: 'input',
        outputText: 'output',
      );

      await service.flush();

      final records = await repository.loadAll();
      expect(records.first.chapterId, 'chapter-1');
    });

    test('should handle null chapterId', () async {
      service.recordAudit(
        usage: const Usage(promptTokens: 100, completionTokens: 200, totalTokens: 100 + 200),
        modelName: 'model',
        operationType: AuditOperationType.opening,
        manuscriptId: 'manuscript-1',
        chapterId: null,
        inputText: 'input',
        outputText: 'output',
      );

      await service.flush();

      final records = await repository.loadAll();
      expect(records.first.chapterId, isNull);
    });

    test('should debounce multiple rapid records into single flush', () async {
      for (var i = 0; i < 5; i++) {
        service.recordAudit(
          usage: Usage(promptTokens: 100, completionTokens: 200, totalTokens: 100 + 200),
          modelName: 'model',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'manuscript',
          inputText: 'input',
          outputText: 'output',
        );
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Should still be buffered
      expect(repository.count, 0);

      // Wait for debounce timer (100ms from last record)
      await Future.delayed(const Duration(milliseconds: 150));

      // All 5 records flushed in one batch
      expect(repository.count, 5);
    });
  });
}
