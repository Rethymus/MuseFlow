import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/domain/pain_point_report.dart';
import 'package:museflow/features/reports/presentation/pain_point_report_page.dart';
import 'package:museflow/features/reports/presentation/severity_indicator.dart';
import 'package:museflow/features/reports/providers.dart';

void main() {
  group('PainPointReportPage', () {
    testWidgets('should render categorized issue sections and export action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const PainPointReportPage(), _sampleReport()),
      );
      await tester.pumpAndSettle();

      expect(find.text('功能缺陷'), findsOneWidget);
      expect(find.text('体验摩擦'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('缺失需求'), findsOneWidget);
      expect(find.text('GLM 生成越界'), findsOneWidget);
      expect(find.text('暗色对比度不足'), findsOneWidget);
      expect(find.text('中文 IME 待验证'), findsOneWidget);
      expect(find.byType(SeverityIndicator), findsNWidgets(3));
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });
  });

  group('SeverityIndicator', () {
    testWidgets('should render colored dot and text label for high severity', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SeverityIndicator(severity: '高')),
        ),
      );

      expect(find.text('高'), findsOneWidget);
      final dot = tester.widget<Container>(find.byType(Container));
      final decoration = dot.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(
        decoration.color,
        Theme.of(tester.element(find.text('高'))).colorScheme.error,
      );
    });
  });
}

Widget _wrap(Widget child, PainPointReport report) {
  return ProviderScope(
    overrides: [
      painPointReportProvider.overrideWith(() => _PainPointNotifier(report)),
    ],
    child: MaterialApp(home: child),
  );
}

class _PainPointNotifier extends PainPointReportNotifier {
  _PainPointNotifier(this.report);

  final PainPointReport report;

  @override
  Future<PainPointReport> build() async => report;
}

PainPointReport _sampleReport() {
  return PainPointReport(
    issues: const [
      PainPointIssue(
        id: 'P1',
        category: '功能缺陷',
        severity: '高',
        requirement: 'REPORT-02',
        title: 'GLM 生成越界',
        description: '描述',
        status: 'closed',
      ),
      PainPointIssue(
        id: 'P2',
        category: '体验摩擦',
        severity: '低',
        requirement: 'REPORT-02',
        title: '暗色对比度不足',
        description: '描述',
        status: 'closed',
      ),
      PainPointIssue(
        id: 'P3',
        category: '缺失需求',
        severity: '中',
        requirement: 'REPORT-02',
        title: '中文 IME 待验证',
        description: '描述',
        status: 'deferred',
      ),
    ],
  );
}
