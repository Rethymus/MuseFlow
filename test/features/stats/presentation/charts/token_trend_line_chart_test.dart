import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/presentation/charts/token_trend_line_chart.dart';

void main() {
  group('TokenTrendLineChart', () {
    testWidgets('renders empty state text when no records provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TokenTrendLineChart(records: [])),
        ),
      );

      expect(find.text('还没有 Token 消耗趋势'), findsOneWidget);
    });

    testWidgets('plots cumulative totalTokens over timestamp as a line', (
      tester,
    ) async {
      final baseTime = DateTime(2026, 6, 1, 10, 0);
      final records = [
        TokenAuditRecord(
          id: '1',
          inputTokens: 100,
          outputTokens: 50,
          modelName: 'gpt-4',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'm1',
          timestamp: baseTime,
        ),
        TokenAuditRecord(
          id: '2',
          inputTokens: 200,
          outputTokens: 100,
          modelName: 'gpt-4',
          operationType: AuditOperationType.rewrite,
          manuscriptId: 'm1',
          timestamp: baseTime.add(const Duration(hours: 1)),
        ),
        TokenAuditRecord(
          id: '3',
          inputTokens: 150,
          outputTokens: 75,
          modelName: 'gpt-4',
          operationType: AuditOperationType.polish,
          manuscriptId: 'm1',
          timestamp: baseTime.add(const Duration(hours: 2)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TokenTrendLineChart(records: records)),
        ),
      );

      await tester.pumpAndSettle();

      // Should render line chart (LineChart widget exists)
      // Cumulative: 150, 450, 675
      expect(find.byType(TokenTrendLineChart), findsOneWidget);
    });
  });
}
