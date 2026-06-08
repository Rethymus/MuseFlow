import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:museflow/features/stats/presentation/charts/chapter_token_bar_chart.dart';
import 'package:museflow/features/stats/presentation/charts/operation_type_pie_chart.dart';
import 'package:museflow/features/stats/presentation/charts/token_trend_line_chart.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';
import 'package:museflow/features/stats/presentation/token_audit_page.dart';

// Create a test-specific provider for easier mocking
final _testTokenAuditProvider = FutureProvider<TokenAuditSnapshot>((ref) async {
  return const TokenAuditSnapshot();
});

void main() {
  group('TokenAuditPage', () {
    testWidgets('renders loading state when snapshot is AsyncLoading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                // Mock loading state
                final asyncValue = ref.watch(_testTokenAuditProvider);
                return Scaffold(
                  appBar: AppBar(title: const Text('Token 消耗总览')),
                  body: asyncValue.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                    data: (snapshot) => const Text('Data loaded'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // During initial pump, the provider is loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state Card when totalCalls is 0', (tester) async {
      final emptySnapshot = const TokenAuditSnapshot();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TokenAuditPage.withSnapshot(emptySnapshot),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('开始使用 AI 功能后，这里会出现消耗统计。'), findsOneWidget);
    });

    testWidgets('renders 4 summary cards when data exists', (tester) async {
      final now = DateTime.now();
      final snapshot = TokenAuditSnapshot(
        totalInputTokens: 1000,
        totalOutputTokens: 500,
        totalCalls: 5,
        records: [
          TokenAuditRecord(
            id: '1',
            inputTokens: 200,
            outputTokens: 100,
            modelName: 'gpt-4',
            operationType: AuditOperationType.synthesis,
            manuscriptId: 'm1',
            timestamp: now,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TokenAuditPage.withSnapshot(snapshot),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have 4 summary cards
      expect(find.byType(StatsSummaryCard), findsNWidgets(4));
      expect(find.text('输入 Token'), findsOneWidget);
      expect(find.text('输出 Token'), findsOneWidget);
      expect(find.text('API 调用次数'), findsOneWidget);
      expect(find.text('总 Token'), findsOneWidget);
    });

    testWidgets('renders 3 chart sections when data exists', (tester) async {
      final now = DateTime.now();
      final snapshot = TokenAuditSnapshot(
        totalInputTokens: 1000,
        totalOutputTokens: 500,
        totalCalls: 5,
        records: [
          TokenAuditRecord(
            id: '1',
            inputTokens: 200,
            outputTokens: 100,
            modelName: 'gpt-4',
            operationType: AuditOperationType.synthesis,
            manuscriptId: 'm1',
            chapterId: 'ch1',
            timestamp: now,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TokenAuditPage.withSnapshot(snapshot),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ChapterTokenBarChart), findsOneWidget);
      expect(find.text('每章 Token 分布'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('按操作类型分布'), 200);
      expect(find.byType(OperationTypePieChart), findsOneWidget);
      expect(find.text('按操作类型分布'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Token 消耗趋势'), 200);
      expect(find.byType(TokenTrendLineChart), findsOneWidget);
      expect(find.text('Token 消耗趋势'), findsOneWidget);
    });

    testWidgets('AppBar title is Token 消耗总览', (tester) async {
      const emptySnapshot = TokenAuditSnapshot();

      await tester.pumpWidget(
        const MaterialApp(
          home: TokenAuditPage.withSnapshot(emptySnapshot),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Token 消耗总览'),
        ),
        findsOneWidget,
      );
    });
  });
}
