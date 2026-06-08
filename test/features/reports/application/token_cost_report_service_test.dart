import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/reports/application/token_cost_report_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';

void main() {
  group('TokenCostReportService', () {
    test(
      'should return zero-value report when audit records are empty',
      () async {
        final service = TokenCostReportService(
          auditRepository: _FakeTokenAuditRepository(
            const TokenAuditSnapshot(),
          ),
          chapterRepository: _FakeChapterRepository(const []),
        );

        final report = await service.generate();

        expect(report.totalInputTokens, 0);
        expect(report.totalOutputTokens, 0);
        expect(report.totalCalls, 0);
        expect(report.actualWordCount, 0);
        expect(report.costByType, isEmpty);
        expect(report.costByChapter, isEmpty);
        expect(report.projection.multiplier, 500000.0);
      },
    );

    test(
      'should aggregate totals, type groups, chapter groups, projection, and suggestions',
      () async {
        final now = DateTime(2026, 6, 8);
        final records = [
          TokenAuditRecord(
            id: 'r1',
            inputTokens: 100,
            outputTokens: 40,
            modelName: 'gpt-test',
            operationType: AuditOperationType.synthesis,
            manuscriptId: 'm1',
            chapterId: 'c1',
            timestamp: now,
          ),
          TokenAuditRecord(
            id: 'r2',
            inputTokens: 300,
            outputTokens: 60,
            modelName: 'gpt-test',
            operationType: AuditOperationType.polish,
            manuscriptId: 'm1',
            chapterId: 'c1',
            timestamp: now,
          ),
          TokenAuditRecord(
            id: 'r3',
            inputTokens: 500,
            outputTokens: 100,
            modelName: 'gpt-test',
            operationType: AuditOperationType.synthesis,
            manuscriptId: 'm1',
            chapterId: 'c2',
            timestamp: now,
          ),
        ];
        final service = TokenCostReportService(
          auditRepository: _FakeTokenAuditRepository(
            TokenAuditSnapshot(
              totalInputTokens: 900,
              totalOutputTokens: 200,
              totalCalls: 3,
              records: records,
            ),
          ),
          chapterRepository: _FakeChapterRepository([
            _chapter('c1', 'm1', '天地玄黄'),
            _chapter('c2', 'm1', ' 宇宙 洪荒 '),
          ]),
        );

        final report = await service.generate();

        expect(report.totalInputTokens, 900);
        expect(report.totalOutputTokens, 200);
        expect(report.totalCalls, 3);
        expect(report.costByType[AuditOperationType.synthesis], 740);
        expect(report.costByType[AuditOperationType.polish], 360);
        expect(report.costByChapter, {'c1': 500, 'c2': 600});
        expect(report.actualWordCount, 8);
        expect(report.projection.multiplier, 62500.0);
        expect(report.projection.estimatedInputTokens, 56250000);
        expect(report.projection.estimatedOutputTokens, 12500000);
        expect(report.projection.estimatedCalls, 187500);
        expect(report.projection.lowEstimateMultiplier, 50000.0);
        expect(report.projection.highEstimateMultiplier, 75000.0);
        expect(report.optimizationSuggestions.length, greaterThanOrEqualTo(2));
      },
    );
  });
}

Chapter _chapter(String id, String manuscriptId, String content) {
  return Chapter(
    id: id,
    manuscriptId: manuscriptId,
    title: id,
    sortOrder: 1,
    documentContent: content,
    createdAt: DateTime(2026, 6, 8),
    updatedAt: DateTime(2026, 6, 8),
  );
}

class _FakeTokenAuditRepository implements TokenAuditRepository {
  _FakeTokenAuditRepository(this.snapshot);

  final TokenAuditSnapshot snapshot;

  @override
  Future<TokenAuditSnapshot> buildSnapshot() async => snapshot;

  @override
  Future<List<TokenAuditRecord>> loadAll() async => snapshot.records;

  @override
  Future<void> saveAll(List<TokenAuditRecord> records) async {}

  @override
  Future<void> enforceLimit(int maxRecords) async {}

  @override
  Future<void> clearAll() async {}

  @override
  int get count => snapshot.records.length;
}

class _FakeChapterRepository implements ChapterRepository {
  _FakeChapterRepository(this.chapters);

  final List<Chapter> chapters;

  @override
  List<Chapter> getAll() => chapters;

  @override
  Future<Chapter> add(Chapter chapter) async => chapter;

  @override
  Chapter? getById(String id) => chapters.where((c) => c.id == id).firstOrNull;

  @override
  List<Chapter> getByManuscriptId(String manuscriptId) =>
      chapters.where((c) => c.manuscriptId == manuscriptId).toList();

  @override
  Future<void> update(Chapter chapter) async {}

  @override
  Future<void> updateDocumentContent(String chapterId, String markdown) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteByManuscriptId(String manuscriptId) async {}
}
