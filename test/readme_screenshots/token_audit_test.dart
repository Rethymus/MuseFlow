/// Real widget screenshot generator for the README token-audit image (#16).
///
/// Renders the **actual** [TokenAuditPage] — the Token 消耗总览 that tracks
/// per-call token usage and cost distribution (summary cards + per-chapter bar
/// chart + per-operation pie chart + trend line chart) — at 1440x1000 with a
/// seeded [TokenAuditSnapshot], producing a truthful screenshot of the real UI.
///
/// Uses [TokenAuditPage.withSnapshot], the page's own test constructor: it
/// short-circuits the provider/repository chain and renders directly from a
/// snapshot, so no ProviderScope override is needed — the simplest screenshot
/// form (like reports-hub, but with seed data).
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`
/// (covers every Chinese UI string without re-subsetting — rs3 "never drift"
/// design) registered under the family name the theme expects.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/token_audit_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:museflow/features/stats/presentation/token_audit_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('TokenAuditPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    final snapshot = _buildSeedSnapshot();

    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _screenshotTheme(),
        home: TokenAuditPage.withSnapshot(snapshot),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the seeded data rendered (not the empty-state / loading / error
    // branch). 'Token 消耗总览' is the AppBar title + body headline (=2);
    // '每章 Token 分布' is the first chart section title (unique, above fold).
    // Only above-the-fold content is asserted: the page is a ListView and the
    // 2nd/3rd charts sit below the fold at 1440x1000. CJK rasterization
    // correctness follows from the registered universal subset.
    expect(find.text('Token 消耗总览'), findsNWidgets(2));
    expect(find.text('每章 Token 分布'), findsOneWidget);

    await expectLater(
      find.byType(TokenAuditPage),
      matchesGoldenFile('../../docs/readme/screenshots/16-token-audit.png'),
    );
  });
}

/// Builds a realistic TokenAuditSnapshot: 15 records across 3 chapters and 5
/// operation types over the last 7 days, with totals computed FROM the records
/// (not fabricated) so the summary cards and charts are internally consistent —
/// an honest reflection of what the real TokenAuditRepository snapshot would
/// aggregate. Timestamps use fixed offsets from `now` so the trend chart's
/// point spacing is deterministic regardless of wall-clock time.
TokenAuditSnapshot _buildSeedSnapshot() {
  final now = DateTime.now();
  // (chapterId, operationType, daysAgo, inputTokens, outputTokens)
  const spec = <(String, AuditOperationType, int, int, int)>[
    ('第1章', AuditOperationType.synthesis, 6, 6200, 2800),
    ('第1章', AuditOperationType.polish, 6, 4100, 1900),
    ('第1章', AuditOperationType.deviationDetect, 5, 5300, 600),
    ('第2章', AuditOperationType.synthesis, 5, 6800, 3100),
    ('第2章', AuditOperationType.rewrite, 4, 4500, 2200),
    ('第2章', AuditOperationType.polish, 4, 3900, 1700),
    ('第2章', AuditOperationType.deviationDetect, 3, 5100, 550),
    ('第3章', AuditOperationType.synthesis, 3, 7100, 3300),
    ('第3章', AuditOperationType.freeInput, 2, 5200, 2600),
    ('第3章', AuditOperationType.polish, 2, 4300, 2000),
    ('第3章', AuditOperationType.rewrite, 1, 4700, 2300),
    ('第3章', AuditOperationType.deviationDetect, 1, 5400, 580),
    ('第4章', AuditOperationType.synthesis, 1, 6600, 3000),
    ('第4章', AuditOperationType.polish, 0, 4000, 1800),
    ('第4章', AuditOperationType.freeInput, 0, 4900, 2400),
  ];
  final records = <TokenAuditRecord>[
    for (var i = 0; i < spec.length; i++)
      TokenAuditRecord(
        id: 'rec-$i',
        inputTokens: spec[i].$4,
        outputTokens: spec[i].$5,
        modelName: 'glm-4-flash',
        operationType: spec[i].$2,
        manuscriptId: 'm1',
        chapterId: spec[i].$1,
        timestamp: now.subtract(Duration(days: spec[i].$3, hours: i)),
      ),
  ];
  return TokenAuditSnapshot(
    totalInputTokens: records.fold(0, (s, r) => s + r.inputTokens),
    totalOutputTokens: records.fold(0, (s, r) => s + r.outputTokens),
    totalCalls: records.length,
    records: records,
  );
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
