import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/reports/domain/consistency_report.dart';
import 'package:museflow/features/reports/presentation/charts/consistency_drift_chart.dart';
import 'package:museflow/features/reports/presentation/consistency_flag_tile.dart';
import 'package:museflow/features/reports/presentation/consistency_report_page.dart';
import 'package:museflow/features/reports/providers.dart';
import 'package:museflow/features/stats/presentation/stats_summary_card.dart';

void main() {
  group('ConsistencyReportPage', () {
    testWidgets('should render four summary cards', (tester) async {
      await tester.pumpWidget(
        _wrap(const ConsistencyReportPage(), report: _report()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatsSummaryCard), findsAtLeastNWidgets(4));
      expect(find.text('整体一致性'), findsOneWidget);
      expect(find.text('角色检查'), findsOneWidget);
      expect(find.text('设定检查'), findsOneWidget);
      expect(find.text('一致性警报'), findsOneWidget);
    });

    testWidgets('should render consistency trend line chart section', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ConsistencyReportPage(), report: _report()),
      );
      await tester.pumpAndSettle();

      expect(find.text('一致性趋势（每10章）'), findsOneWidget);
      expect(find.byType(ConsistencyDriftChart), findsOneWidget);
    });

    testWidgets('should render narrative quality review section and signals', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ConsistencyReportPage(), report: _report()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('叙事质量复查'), 200);

      expect(find.text('叙事质量复查'), findsOneWidget);
      expect(find.text('场景沉浸'), findsOneWidget);
      expect(find.text('人设锚点'), findsOneWidget);
      expect(find.text('反AI味'), findsOneWidget);
      expect(find.textContaining('第3章 · 疑似模板化 AI 表达'), findsOneWidget);
      expect(find.textContaining('证据：总而言之'), findsOneWidget);
    });

    testWidgets('should render chapter memory freshness section and signals', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ConsistencyReportPage(), report: _report()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('章节记忆新鲜度'), 200);

      expect(find.text('章节记忆新鲜度'), findsOneWidget);
      expect(find.text('记忆重合'), findsOneWidget);
      expect(find.text('需复查'), findsOneWidget);
      expect(find.textContaining('第5章 · 上一章记忆承接偏弱'), findsOneWidget);
      expect(find.textContaining('缺失：禁地、玉简'), findsOneWidget);
    });

    testWidgets(
      'should render character and setting sections with entity cards',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const ConsistencyReportPage(), report: _report()),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('角色一致性'), 200);

        expect(find.text('角色一致性'), findsOneWidget);
        expect(find.text('林青玄'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('设定一致性'), 200);
        expect(find.text('设定一致性'), findsOneWidget);
        expect(find.text('灵溪宗'), findsOneWidget);
      },
    );

    testWidgets('should show export button in app bar', (tester) async {
      await tester.pumpWidget(
        _wrap(const ConsistencyReportPage(), report: _report()),
      );

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });
  });

  group('ConsistencyFlagTile', () {
    testWidgets('should render entity field expected observed and severity', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ConsistencyFlagTile(flag: _flag())),
        ),
      );

      expect(find.text('presence'), findsOneWidget);
      expect(find.text('mentioned -> not found'), findsOneWidget);
      expect(find.text('Ch2'), findsOneWidget);
      expect(find.text('中'), findsOneWidget);
    });
  });

  group('ConsistencyDriftChart', () {
    testWidgets('should render ten data points with x-axis labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConsistencyDriftChart(
              driftScores: List.generate(10, (index) => index / 10),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1-10'), findsWidgets);
      expect(find.text('91-100'), findsWidgets);
      expect(find.byType(ConsistencyDriftChart), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child, {required ConsistencyReport report}) {
  return ProviderScope(
    overrides: [
      consistencyReportProvider.overrideWith(
        () => _FakeConsistencyReportNotifier(report),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

ConsistencyReport _report() {
  return ConsistencyReport(
    characterResults: [
      EntityConsistencyResult(
        entityName: '林青玄',
        entityType: 'character',
        chaptersWhereMentioned: 8,
        consistencyScore: 0.8,
        flags: [_flag()],
      ),
    ],
    settingResults: const [
      EntityConsistencyResult(
        entityName: '灵溪宗',
        entityType: 'setting',
        chaptersWhereMentioned: 7,
        consistencyScore: 0.7,
        flags: [],
      ),
    ],
    overallConsistencyScore: 0.75,
    driftPerSegment: List.generate(10, (index) => 1 - index / 10),
    narrativeQuality: const NarrativeQualitySnapshot(
      immersionScore: 0.6,
      characterAnchoringScore: 0.7,
      antiAiScentScore: 0.8,
      signals: [
        NarrativeQualitySignal(
          chapterIndex: 2,
          category: 'style',
          title: '疑似模板化 AI 表达',
          evidence: '总而言之',
          suggestion: '改成角色动作或场景推进。',
          severity: DeviationSeverity.medium,
        ),
      ],
    ),
    memoryFreshness: const ChapterMemoryFreshnessSnapshot(
      averageOverlapScore: 0.42,
      staleSummaryCount: 1,
      signals: [
        ChapterMemoryFreshnessSignal(
          chapterIndex: 4,
          direction: 'previous',
          summary: '林青玄在禁地发现玉简。',
          overlapScore: 0.25,
          missingTerms: ['禁地', '玉简'],
          evidence: '上一章 记忆词 4 个，当前章承接 1 个',
          suggestion: '复查上一章上下文。',
          severity: DeviationSeverity.clear,
        ),
      ],
    ),
  );
}

ConsistencyFlag _flag() {
  return const ConsistencyFlag(
    chapterIndex: 1,
    field: 'presence',
    expectedValue: 'mentioned',
    observedText: 'not found',
    severity: DeviationSeverity.medium,
  );
}

class _FakeConsistencyReportNotifier extends ConsistencyReportNotifier {
  _FakeConsistencyReportNotifier(this.report);

  final ConsistencyReport report;

  @override
  Future<ConsistencyReport> build() async => report;
}
