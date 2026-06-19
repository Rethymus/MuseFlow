/// Real widget screenshot generator for the README report-details image (#18).
///
/// Renders the **actual** [TokenCostReportPage] (Token 消耗分析 — the report
/// detail reachable from the Analysis & Reports hub: actual token cost,
/// per-operation distribution, 50万字 long-form projection, optimization
/// suggestions) at 1440x1000 with a seeded [TokenCostReport], producing a
/// truthful screenshot of the real UI.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`
/// (covers every Chinese UI string without re-subsetting — rs3 "never drift"
/// design) registered under the family name the theme expects, so the render is
/// deterministic across platforms without google_fonts / system CJK deps.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/token_cost_report_test.dart --update-goldens
/// then deploy: cp docs/readme/screenshots/18-report-details.png \
///              (already written in place by matchesGoldenFile)
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/domain/token_cost_report.dart';
import 'package:museflow/features/reports/presentation/token_cost_report_page.dart';
import 'package:museflow/features/reports/providers.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';

void main() {
  /// Register the bundled Noto Sans CJK SC universal subset under the family
  /// name the theme resolves, so CJK glyphs render (flutter_test does not use
  /// system fonts). Loaded from a File path (no pubspec asset declaration
  /// needed).
  setUpAll(() async {
    final bytes = await File('test_assets/noto_sans_sc_subset.ttf').readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('TokenCostReportPage renders a real 1440x1000 screenshot',
      (tester) async {
    // Seed reflects the *shipped* TokenCostReport shape: a ~1万字 sample whose
    // 50× projection to 50万字 yields ~4.68M estimated tokens — the same order
    // the README mockup advertised, now rendered by the real report service's
    // domain model rather than an SVG sketch. Per-operation distribution mirrors
    // a realistic manuscript (synthesis / polish / logic-guard heavy).
    final seed = TokenCostReport(
      totalInputTokens: 62400,
      totalOutputTokens: 31200,
      totalCalls: 128,
      actualWordCount: 10000.0,
      costByType: const {
        AuditOperationType.synthesis: 42000,
        AuditOperationType.polish: 31600,
        AuditOperationType.deviationDetect: 20000,
      },
      costByChapter: const {},
      projection: const TokenCostProjection(
        targetWordCount: 500000.0,
        multiplier: 50.0,
        estimatedInputTokens: 3120000,
        estimatedOutputTokens: 1560000,
        estimatedCalls: 6400,
        lowEstimateMultiplier: 40.0,
        highEstimateMultiplier: 60.0,
      ),
      optimizationSuggestions: const [
        '批量合并 AI 操作以减少调用次数。',
        '精简知识库注入上下文，降低输入 token 消耗。',
      ],
    );

    // Surface sized to match the README mockup dimensions (1440x1000 @ 1x).
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenCostReportProvider.overrideWith(
            () => _SeededTokenCostReportNotifier(seed),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const TokenCostReportPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert the seeded report rendered into the tree (proves real content, not
    // the loading/error state). Only above-the-fold, uniquely-counted strings:
    // TokenCostReportPage is a ListView, and at 1440x1000 the '优化建议' section
    // sits below the fold (~1048px of content) and is lazily not built — exactly
    // what a real user sees before scrolling. Note '输入 Token' deliberately NOT
    // asserted: it legitimately appears twice (StatsSummaryCard title 14pt +
    // CostProjectionChart legend 12pt), which is correct, not a bug. CJK glyph
    // rasterization correctness follows from the registered universal subset.
    expect(find.text('Token 消耗分析'), findsNWidgets(2)); // AppBar title + body headline
    expect(find.text('50万字长篇推算'), findsOneWidget); // projection section title

    await expectLater(
      find.byType(TokenCostReportPage),
      matchesGoldenFile('../../docs/readme/screenshots/18-report-details.png'),
    );
  });
}

/// Mirrors `appTheme()`'s `MUSEFLOW_DISABLE_GOOGLE_FONTS=true` branch: indigo
/// dark Material 3 scheme with the CJK text theme bound to 'Noto Sans CJK SC'
/// (the registered subset). Kept inline + self-contained so the screenshot is
/// deterministic without google_fonts network access or a dart-define flag.
ThemeData _screenshotTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  );
  final base = Typography.material2021().white.apply(fontFamily: 'Noto Sans CJK SC');
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    textTheme: base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}

/// TokenCostReportNotifier override that returns a fixed seed report, bypassing
/// the token-audit repository / chapter repository chain entirely (no
/// setUpHiveTest, no HttpOverrides trap) — the report page only `watch`es this
/// provider in its render path.
class _SeededTokenCostReportNotifier extends TokenCostReportNotifier {
  _SeededTokenCostReportNotifier(this._seed);

  final TokenCostReport _seed;

  @override
  Future<TokenCostReport> build() async => _seed;
}
