import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/reports/application/report_export_service.dart';
import 'package:museflow/features/reports/domain/blind_read_result.dart';
import 'package:museflow/features/reports/domain/consistency_report.dart';
import 'package:museflow/features/reports/domain/pain_point_report.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';

void main() {
  late ReportExportService service;

  setUp(() {
    service = const ReportExportService();
  });

  group('buildTokenCostMarkdown', () {
    test('should produce Token cost report header with sections', () {
      const report = TokenCostReport(
        totalInputTokens: 10000,
        totalOutputTokens: 5000,
        totalCalls: 50,
        actualWordCount: 12000.0,
        costByType: {AuditOperationType.synthesis: 3000},
        costByChapter: {'chapter-1': 2000},
        projection: TokenCostProjection(
          targetWordCount: 500000.0,
          multiplier: 41.67,
          estimatedInputTokens: 416700,
          estimatedOutputTokens: 208350,
          estimatedCalls: 2083,
          lowEstimateMultiplier: 35.0,
          highEstimateMultiplier: 48.0,
        ),
        optimizationSuggestions: ['Batch operations to reduce overhead'],
      );

      final md = service.buildTokenCostMarkdown(report);

      expect(md, contains('# Token 消耗分析报告'));
      expect(md, contains('## 实际消耗'));
      expect(md, contains('## 按操作类型分布'));
      expect(md, contains('## 50万字长篇推算'));
      expect(md, contains('## 优化建议'));
      expect(md, contains('Batch operations to reduce overhead'));
    });
  });

  group('buildPainPointMarkdown', () {
    test('should produce Pain point report header with category sections', () {
      final report = PainPointReport(
        issues: [
          const PainPointIssue(
            id: 'I-01',
            category: '功能缺陷',
            severity: '高',
            requirement: 'TEST',
            title: 'Crash on save',
            description: 'desc',
            status: 'open',
          ),
          const PainPointIssue(
            id: 'I-02',
            category: '体验摩擦',
            severity: '中',
            requirement: 'TEST',
            title: 'Slow load',
            description: 'desc',
            status: 'open',
          ),
          const PainPointIssue(
            id: 'I-03',
            category: '缺失需求',
            severity: '低',
            requirement: 'TEST',
            title: 'No shortcut',
            description: 'desc',
            status: 'open',
          ),
        ],
      );

      final md = service.buildPainPointMarkdown(report);

      expect(md, contains('# 痛点报告'));
      expect(md, contains('## 功能缺陷'));
      expect(md, contains('## 体验摩擦'));
      expect(md, contains('## 缺失需求'));
      expect(md, contains('Crash on save'));
      expect(md, contains('Slow load'));
      expect(md, contains('No shortcut'));
    });
  });

  group('buildBlindReadMarkdown', () {
    test('should produce Anti-AI-scent report with verdict tally and score', () {
      final result = BlindReadResult(
        excerpts: [
          const BlindReadExcerpt(
            text: 'AI text',
            chapterId: 'ch-1',
            chapterIndex: 1,
            humanVerdict: true,
          ),
          const BlindReadExcerpt(
            text: 'Human text',
            chapterId: 'ch-2',
            chapterIndex: 2,
            humanVerdict: false,
          ),
        ],
        correctCount: 1,
      );

      final md = service.buildBlindReadMarkdown(result);

      expect(md, contains('# 反AI味评估报告'));
      expect(md, contains('1')); // correctCount
    });
  });

  group('buildConsistencyMarkdown', () {
    test('should produce Consistency report with entity scores and flags', () {
      final report = ConsistencyReport(
        characterResults: const [
          EntityConsistencyResult(
            entityName: 'Alice',
            entityType: 'character',
            chaptersWhereMentioned: 80,
            consistencyScore: 0.92,
            flags: [
              ConsistencyFlag(
                chapterIndex: 45,
                field: 'personality',
                expectedValue: 'brave',
                observedText: 'timid',
                severity: DeviationSeverity.medium,
              ),
            ],
          ),
        ],
        settingResults: const [],
        overallConsistencyScore: 0.88,
        driftPerSegment: List.filled(10, 0.9),
      );

      final md = service.buildConsistencyMarkdown(report);

      expect(md, contains('# 知识库一致性分析报告'));
      expect(md, contains('Alice'));
      expect(md, contains('0.92'));
      expect(md, contains('personality'));
    });
  });
}
