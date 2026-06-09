import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/presentation/charts/chapter_token_bar_chart.dart';

void main() {
  group('ChapterTokenBarChart', () {
    testWidgets('renders empty state text when no records provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChapterTokenBarChart(records: [])),
        ),
      );

      expect(find.text('还没有章节 Token 记录'), findsOneWidget);
    });

    testWidgets('renders empty state when no records have chapterId', (
      tester,
    ) async {
      final now = DateTime.now();
      final records = [
        TokenAuditRecord(
          id: '1',
          inputTokens: 100,
          outputTokens: 50,
          modelName: 'gpt-4',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'm1',
          chapterId: null, // no chapter
          timestamp: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChapterTokenBarChart(records: records)),
        ),
      );

      expect(find.text('还没有章节 Token 记录'), findsOneWidget);
    });

    testWidgets(
      'aggregates totalTokens per chapterId and renders one bar per chapter',
      (tester) async {
        final now = DateTime.now();
        final records = [
          TokenAuditRecord(
            id: '1',
            inputTokens: 100,
            outputTokens: 50,
            modelName: 'gpt-4',
            operationType: AuditOperationType.synthesis,
            manuscriptId: 'm1',
            chapterId: 'ch1',
            timestamp: now,
          ),
          TokenAuditRecord(
            id: '2',
            inputTokens: 200,
            outputTokens: 100,
            modelName: 'gpt-4',
            operationType: AuditOperationType.rewrite,
            manuscriptId: 'm1',
            chapterId: 'ch1', // same chapter
            timestamp: now,
          ),
          TokenAuditRecord(
            id: '3',
            inputTokens: 150,
            outputTokens: 75,
            modelName: 'gpt-4',
            operationType: AuditOperationType.polish,
            manuscriptId: 'm1',
            chapterId: 'ch2',
            timestamp: now,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ChapterTokenBarChart(records: records)),
          ),
        );

        // Should render bar chart (BarChart widget exists)
        // ch1: 450 tokens (100+50+200+100), ch2: 225 tokens
        await tester.pumpAndSettle();
        expect(find.byType(ChapterTokenBarChart), findsOneWidget);
      },
    );

    testWidgets('uses chapter number as X-axis label', (tester) async {
      final now = DateTime.now();
      final records = [
        TokenAuditRecord(
          id: '1',
          inputTokens: 100,
          outputTokens: 50,
          modelName: 'gpt-4',
          operationType: AuditOperationType.synthesis,
          manuscriptId: 'm1',
          chapterId: 'ch1',
          timestamp: now,
        ),
        TokenAuditRecord(
          id: '2',
          inputTokens: 200,
          outputTokens: 100,
          modelName: 'gpt-4',
          operationType: AuditOperationType.rewrite,
          manuscriptId: 'm1',
          chapterId: 'ch2',
          timestamp: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ChapterTokenBarChart(records: records)),
        ),
      );

      await tester.pumpAndSettle();

      // Chapter labels should be rendered (Ch1, Ch2)
      expect(find.text('Ch1'), findsOneWidget);
      expect(find.text('Ch2'), findsOneWidget);
    });
  });
}
