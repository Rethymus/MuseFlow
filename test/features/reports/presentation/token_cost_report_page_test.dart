import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';
import 'package:museflow/features/reports/presentation/charts/cost_projection_chart.dart';
import 'package:museflow/features/reports/presentation/token_cost_report_page.dart';
import 'package:museflow/features/reports/providers.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';

void main() {
  group('TokenCostReportPage', () {
    testWidgets(
      'should render summary cards, chart, projection, suggestions, and export action',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const TokenCostReportPage(), _sampleReport()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StatsSummaryCard), findsNWidgets(4));
        expect(find.text('输入 Token'), findsOneWidget);
        expect(find.text('输出 Token'), findsOneWidget);
        expect(find.text('API 调用次数'), findsOneWidget);
        expect(find.text('实际字数'), findsOneWidget);
        expect(find.text('按操作类型分布'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(find.text('50万字长篇推算'), findsOneWidget);
        expect(find.text('预估总 Token'), findsOneWidget);
        expect(find.text('预估 API 调用'), findsOneWidget);
        expect(find.text('估算范围'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(find.text('优化建议'), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb_outline), findsNWidgets(2));
        expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      },
    );
  });

  group('CostProjectionChart', () {
    testWidgets(
      'should render grouped actual and projected bars for 3 categories',
      (tester) async {
        final report = _sampleReport();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CostProjectionChart(
                report: report,
                projection: report.projection,
              ),
            ),
          ),
        );

        expect(find.byType(CostProjectionChart), findsOneWidget);
        expect(find.text('输入 Token'), findsOneWidget);
        expect(find.text('输出 Token'), findsOneWidget);
        expect(find.text('API 调用'), findsOneWidget);
      },
    );
  });
}

Widget _wrap(Widget child, TokenCostReport report) {
  return ProviderScope(
    overrides: [
      tokenCostReportProvider.overrideWith(() => _TokenReportNotifier(report)),
    ],
    child: MaterialApp(home: child),
  );
}

class _TokenReportNotifier extends TokenCostReportNotifier {
  _TokenReportNotifier(this.report);

  final TokenCostReport report;

  @override
  Future<TokenCostReport> build() async => report;
}

TokenCostReport _sampleReport() {
  return const TokenCostReport(
    totalInputTokens: 1200,
    totalOutputTokens: 600,
    totalCalls: 9,
    actualWordCount: 10000,
    costByType: {
      AuditOperationType.synthesis: 1000,
      AuditOperationType.polish: 800,
    },
    costByChapter: {'c1': 1800},
    projection: TokenCostProjection(
      targetWordCount: 500000,
      multiplier: 50,
      estimatedInputTokens: 60000,
      estimatedOutputTokens: 30000,
      estimatedCalls: 450,
      lowEstimateMultiplier: 40,
      highEstimateMultiplier: 60,
    ),
    optimizationSuggestions: ['批量操作减少 API 调用开销', '减少知识库注入上下文长度'],
  );
}
