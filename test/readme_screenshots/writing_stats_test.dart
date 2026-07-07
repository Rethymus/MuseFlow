/// Real widget screenshot generator for the README writing-stats image (#15).
///
/// Renders the **actual** [WritingStatsPage] — 写作统计: daily word counts, speed
/// trend, AI-usage ratio, achievement badges, and a token-usage summary — at
/// 1440x1000 with seeded demo data, producing a truthful screenshot of the UI.
///
/// Uses [WritingStatsPage]'s `debugSnapshot` constructor param, which bypasses
/// the writingStats provider chain and renders directly from a seeded
/// [StatsSnapshot]. The nested token-summary section still watches
/// `tokenAuditNotifierProvider`, so that provider is overridden with a seeded
/// snapshot too (so the section renders real cards instead of an empty state).
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/writing_stats_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/application/token_audit_notifier.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:museflow/features/stats/presentation/writing_stats_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('WritingStatsPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenAuditNotifierProvider.overrideWith(
            () => _SeededTokenAuditNotifier(_buildTokenAuditSeed()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: WritingStatsPage(debugSnapshot: _buildWritingStatsSeed()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the seeded data rendered (not empty / loading / error). '写作统计'
    // is the AppBar title + body headline (=2); '每日字数' is the first chart
    // section title (unique, above fold). Only above-the-fold content is
    // asserted (the page is a tall ListView). CJK rasterization correctness
    // follows from the registered universal subset.
    expect(find.text('写作统计'), findsNWidgets(2));
    expect(find.text('每日字数'), findsOneWidget);

    await expectLater(
      find.byType(WritingStatsPage),
      matchesGoldenFile('../../docs/readme/screenshots/15-writing-stats.png'),
    );
  });
}

/// Writing-stats seed: totals + AI ratio internally consistent (aiUnits /
/// totalUnits ≈ 22.5%), 14 days of daily breakdown for the bar + trend charts.
/// Totals are honest order-of-magnitude for a mid-draft manuscript (not copied
/// from the mockup verbatim, but consistent with the same ~12.6万字 scale).
StatsSnapshot _buildWritingStatsSeed() {
  // (humanUnits, aiUnits, editSeconds) per day over 14 days — varied so the
  // bar + trend charts look natural rather than uniform.
  const daily = <(int, int, int)>[
    (6100, 1500, 3200),
    (7400, 2100, 4100),
    (5200, 1200, 2800),
    (8300, 2400, 5200),
    (6900, 1800, 3600),
    (4500, 900, 2400),
    (7800, 2300, 4300),
    (8600, 2600, 5500),
    (6000, 1400, 3100),
    (7200, 2000, 3900),
    (5500, 1100, 2700),
    (8100, 2500, 5000),
    (6700, 1700, 3500),
    (7300, 2100, 4000),
  ];
  final now = DateTime.now();
  final dailyStats = <DailyWritingStats>[
    for (var i = 0; i < daily.length; i++)
      DailyWritingStats(
        dateKey: _dateKey(now.subtract(Duration(days: daily.length - 1 - i))),
        humanUnits: daily[i].$1,
        aiUnits: daily[i].$2,
        sessionCount: 1,
        editSeconds: daily[i].$3,
      ),
  ];
  final humanUnits = daily.fold(0, (s, d) => s + d.$1);
  final aiUnits = daily.fold(0, (s, d) => s + d.$2);
  return StatsSnapshot(
    totalUnits: humanUnits + aiUnits,
    humanUnits: humanUnits,
    aiUnits: aiUnits,
    writingDays: 18,
    sessionCount: daily.length,
    editSeconds: daily.fold(0, (s, d) => s + d.$3),
    daily: dailyStats,
  );
}

/// Token-audit seed for the nested token-summary section: 6 records, totals
/// computed from them (consistent). Reuses the vr3 honesty approach.
TokenAuditSnapshot _buildTokenAuditSeed() {
  final now = DateTime.now();
  const spec = <(AuditOperationType, int, int, int)>[
    (AuditOperationType.synthesis, 6, 6200, 2800),
    (AuditOperationType.polish, 5, 4100, 1900),
    (AuditOperationType.deviationDetect, 4, 5300, 600),
    (AuditOperationType.rewrite, 3, 4500, 2200),
    (AuditOperationType.polish, 2, 3900, 1700),
    (AuditOperationType.synthesis, 1, 6800, 3100),
  ];
  final records = <TokenAuditRecord>[
    for (var i = 0; i < spec.length; i++)
      TokenAuditRecord(
        id: 'ws-rec-$i',
        inputTokens: spec[i].$3,
        outputTokens: spec[i].$4,
        modelName: 'glm-4-flash',
        operationType: spec[i].$1,
        manuscriptId: 'm1',
        chapterId: '第${i + 1}章',
        timestamp: now.subtract(Duration(days: spec[i].$2, hours: i)),
      ),
  ];
  return TokenAuditSnapshot(
    totalInputTokens: records.fold(0, (s, r) => s + r.inputTokens),
    totalOutputTokens: records.fold(0, (s, r) => s + r.outputTokens),
    totalCalls: records.length,
    records: records,
  );
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Override for tokenAuditNotifierProvider returning a fixed seed snapshot.
class _SeededTokenAuditNotifier extends TokenAuditNotifier {
  _SeededTokenAuditNotifier(this._seed);

  final TokenAuditSnapshot _seed;

  @override
  Future<TokenAuditSnapshot> build() async => _seed;
}

ThemeData _screenshotTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );
  final base = Typography.material2021().white.apply(
    fontFamily: 'Noto Sans CJK SC',
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    textTheme: base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}
