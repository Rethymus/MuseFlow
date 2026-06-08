import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';

void main() {
  group('TokenCostReport', () {
    test('should hold all fields with correct values', () {
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

      expect(report.totalInputTokens, 10000);
      expect(report.totalOutputTokens, 5000);
      expect(report.totalCalls, 50);
      expect(report.actualWordCount, 12000.0);
      expect(report.costByType, {AuditOperationType.synthesis: 3000});
      expect(report.costByChapter, {'chapter-1': 2000});
      expect(report.optimizationSuggestions, [
        'Batch operations to reduce overhead',
      ]);
    });

    test('should support copyWith', () {
      const report = TokenCostReport(
        totalInputTokens: 10000,
        totalOutputTokens: 5000,
        totalCalls: 50,
        actualWordCount: 12000.0,
        costByType: {},
        costByChapter: {},
        projection: TokenCostProjection(
          targetWordCount: 500000.0,
          multiplier: 41.67,
          estimatedInputTokens: 416700,
          estimatedOutputTokens: 208350,
          estimatedCalls: 2083,
          lowEstimateMultiplier: 35.0,
          highEstimateMultiplier: 48.0,
        ),
        optimizationSuggestions: [],
      );

      final updated = report.copyWith(
        totalInputTokens: 20000,
        totalCalls: 100,
      );

      expect(updated.totalInputTokens, 20000);
      expect(updated.totalCalls, 100);
      expect(updated.totalOutputTokens, 5000); // unchanged
    });

    test('should support equality', () {
      const report1 = TokenCostReport(
        totalInputTokens: 100,
        totalOutputTokens: 50,
        totalCalls: 5,
        actualWordCount: 1000.0,
        costByType: {},
        costByChapter: {},
        projection: TokenCostProjection(
          targetWordCount: 500000.0,
          multiplier: 500.0,
          estimatedInputTokens: 50000,
          estimatedOutputTokens: 25000,
          estimatedCalls: 2500,
          lowEstimateMultiplier: 400.0,
          highEstimateMultiplier: 600.0,
        ),
        optimizationSuggestions: [],
      );
      const report2 = TokenCostReport(
        totalInputTokens: 100,
        totalOutputTokens: 50,
        totalCalls: 5,
        actualWordCount: 1000.0,
        costByType: {},
        costByChapter: {},
        projection: TokenCostProjection(
          targetWordCount: 500000.0,
          multiplier: 500.0,
          estimatedInputTokens: 50000,
          estimatedOutputTokens: 25000,
          estimatedCalls: 2500,
          lowEstimateMultiplier: 400.0,
          highEstimateMultiplier: 600.0,
        ),
        optimizationSuggestions: [],
      );

      expect(report1, equals(report2));
      expect(report1.hashCode, equals(report2.hashCode));
    });
  });

  group('TokenCostProjection', () {
    test('should hold projection fields', () {
      const projection = TokenCostProjection(
        targetWordCount: 500000.0,
        multiplier: 41.67,
        estimatedInputTokens: 416700,
        estimatedOutputTokens: 208350,
        estimatedCalls: 2083,
        lowEstimateMultiplier: 35.0,
        highEstimateMultiplier: 48.0,
      );

      expect(projection.targetWordCount, 500000.0);
      expect(projection.multiplier, 41.67);
      expect(projection.estimatedInputTokens, 416700);
      expect(projection.estimatedOutputTokens, 208350);
      expect(projection.estimatedCalls, 2083);
      expect(projection.lowEstimateMultiplier, 35.0);
      expect(projection.highEstimateMultiplier, 48.0);
    });

    test('should support copyWith', () {
      const projection = TokenCostProjection(
        targetWordCount: 500000.0,
        multiplier: 41.67,
        estimatedInputTokens: 416700,
        estimatedOutputTokens: 208350,
        estimatedCalls: 2083,
        lowEstimateMultiplier: 35.0,
        highEstimateMultiplier: 48.0,
      );

      final updated = projection.copyWith(estimatedCalls: 3000);

      expect(updated.estimatedCalls, 3000);
      expect(updated.targetWordCount, 500000.0); // unchanged
    });
  });
}
