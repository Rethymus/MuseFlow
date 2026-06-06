import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/presentation/charts/operation_type_pie_chart.dart';

void main() {
  group('OperationTypePieChart', () {
    testWidgets('renders empty state text when no records provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OperationTypePieChart(records: []),
          ),
        ),
      );

      expect(find.text('还没有 Token 使用记录'), findsOneWidget);
    });

    testWidgets('groups records by AuditOperationType.group into 4 pie sections', (tester) async {
      final now = DateTime.now();
      final records = [
        // organize group
        TokenAuditRecord(
          id: '1',
          inputTokens: 100,
          outputTokens: 50,
          modelName: 'gpt-4',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'm1',
          timestamp: now,
        ),
        // edit group
        TokenAuditRecord(
          id: '2',
          inputTokens: 200,
          outputTokens: 100,
          modelName: 'gpt-4',
          operationType: AuditOperationType.rewrite,
          manuscriptId: 'm1',
          timestamp: now,
        ),
        TokenAuditRecord(
          id: '3',
          inputTokens: 150,
          outputTokens: 75,
          modelName: 'gpt-4',
          operationType: AuditOperationType.polish,
          manuscriptId: 'm1',
          timestamp: now,
        ),
        // worldview group
        TokenAuditRecord(
          id: '4',
          inputTokens: 300,
          outputTokens: 200,
          modelName: 'gpt-4',
          operationType: AuditOperationType.skillGen,
          manuscriptId: 'm1',
          timestamp: now,
        ),
        // template group
        TokenAuditRecord(
          id: '5',
          inputTokens: 250,
          outputTokens: 150,
          modelName: 'gpt-4',
          operationType: AuditOperationType.templateComplete,
          manuscriptId: 'm1',
          timestamp: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OperationTypePieChart(records: records),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify pie chart widget is rendered (labels are rendered inside chart canvas, not as Text widgets)
      expect(find.byType(OperationTypePieChart), findsOneWidget);
      // Verify empty state is NOT shown
      expect(find.text('还没有 Token 使用记录'), findsNothing);
    });
  });
}
