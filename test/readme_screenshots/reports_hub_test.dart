/// Real widget screenshot generator for the README reports-hub image.
///
/// Renders the **actual** [ReportsHubPage] (the Analysis & Reports hub — entry
/// point to the hundred-chapter four-dimensional analysis) at 1440x1000.
/// ReportsHubPage is a pure stateless widget with fully hardcoded report cards
/// (no provider/state), so this is the simplest screenshot form: just pump it
/// under the screenshot theme with the bundled CJK subset — no override/seed.
///
/// Shares the bundled `test_assets/noto_sans_sc_subset.ttf` (now covering the
/// manuscript-library, banned-phrases, AND reports-hub pages).
///
/// Regenerate after changing the page:
///   flutter test test/readme_screenshots/reports_hub_test.dart --update-goldens
/// then deploy: cp test/readme_screenshots/reports-hub.png \
///              docs/readme/screenshots/17-reports-hub.png
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/presentation/reports_hub_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('ReportsHubPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _screenshotTheme(),
        home: const ReportsHubPage(),
      ),
    );
    await tester.pumpAndSettle();

    // '分析报告' appears in both the AppBar title and the body headline.
    expect(find.text('分析报告'), findsNWidgets(2));
    expect(find.text('Token 成本分析'), findsOneWidget);
    expect(find.text('用户痛点报告'), findsOneWidget);
    expect(find.text('编辑评审团'), findsOneWidget);

    await expectLater(
      find.byType(ReportsHubPage),
      matchesGoldenFile('../../docs/readme/screenshots/17-reports-hub.png'),
    );
  });
}

/// Mirrors `appTheme()`'s `MUSEFLOW_DISABLE_GOOGLE_FONTS=true` branch (same as
/// the other screenshot tests): indigo dark Material 3 scheme with the CJK
/// text theme bound to 'Noto Sans CJK SC'.
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
