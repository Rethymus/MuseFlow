/// Real widget screenshot generator for the README settings image (#19).
///
/// Renders the **actual** [SettingsPage] — 设置: AI section (model / phrase
/// filter / auto-consistency switch / creativity segmented button), storage
/// section, and about section — at 1440x1000, producing a truthful screenshot.
///
/// SettingsPage's build path watches only two persisted providers
/// (autoDeviationCheckProvider bool, creativityLevelProvider enum); both are
/// overridden with seeded values. The clear-stats repository ref lives only
/// in the tap action, never hit during a static screenshot. No appBar on this
/// page, so '设置' appears once (the body headline).
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/settings_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';
import 'package:museflow/features/settings/presentation/settings_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('SettingsPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // D-CP-01: auto consistency check is OFF by default (it costs an
          // extra LLM call). The screenshot reflects the shipped default.
          autoDeviationCheckProvider.overrideWith(
            () => _SeededAutoDeviationNotifier(false),
          ),
          // AA-03: creativity defaults to 'balanced' (灵动 lowers machine
          // scent). Screenshot shows the balanced segment selected.
          creativityLevelProvider.overrideWith(
            () => _SeededCreativityNotifier(CreativityLevel.balanced),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the page rendered its sections. No appBar here, so '设置' appears
    // once (body headline); 'AI' / '存储' are unique section titles. All
    // above the fold at 1440x1000. CJK rasterization follows the registered
    // universal subset.
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('存储'), findsOneWidget);

    await expectLater(
      find.byType(SettingsPage),
      matchesGoldenFile('../../docs/readme/screenshots/19-settings.png'),
    );
  });
}

/// Seeded override — returns a fixed bool, bypassing the persisted settings
/// repository. auto-deviation OFF = shipped default (D-CP-01).
class _SeededAutoDeviationNotifier extends AutoDeviationCheckNotifier {
  _SeededAutoDeviationNotifier(this._value);

  final bool _value;

  @override
  bool build() => _value;
}

/// Seeded override — returns a fixed CreativityLevel. balanced = shipped
/// default (AA-03).
class _SeededCreativityNotifier extends CreativityLevelNotifier {
  _SeededCreativityNotifier(this._value);

  final CreativityLevel _value;

  @override
  CreativityLevel build() => _value;
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
