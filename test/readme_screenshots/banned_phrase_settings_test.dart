/// Real widget screenshot generator for the README banned-phrases image.
///
/// Renders the **actual** [BannedPhraseSettingsPage] (the anti-AI-scent filter
/// list — a soul page for MuseFlow, whose core value is "AI helps write the
/// story but the reader can't tell") with seeded real lexicon phrases at
/// 1440x1000, producing a truthful screenshot of the real UI.
///
/// Shares the bundled `test_assets/noto_sans_sc_subset.ttf` (a pyftsubset-cut
/// Noto Sans CJK SC subset covering BOTH the manuscript-library and
/// banned-phrases pages) registered under the family name the theme expects —
/// deterministic across platforms without google_fonts / system CJK deps.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/banned_phrase_settings_test.dart --update-goldens
/// then deploy: cp test/readme_screenshots/banned-phrases.png \
///              docs/readme/screenshots/21-banned-phrases.png
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/presentation/banned_phrase_settings.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('BannedPhraseSettingsPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    // Real phrases drawn from anti_ai_scent_lexicon.dart's default banned map
    // (conclusion / emphasis / logic categories) — an honest reflection of the
    // shipped default filter list, not invented demo text.
    const seed = <String>[
      '综上所述',
      '总而言之',
      '值得注意的是',
      '需要指出的是',
      '毫无疑问',
      '不可否认',
      '众所周知',
      '换言之',
    ];

    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bannedPhrasesProvider.overrideWith(
            () => _SeededBannedPhrasesNotifier(seed),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const BannedPhraseSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert the seeded phrases + chrome rendered into the tree (real content,
    // not empty/error state). CJK glyph rasterization correctness follows from
    // the registered subset font (cmap verified to contain every glyph).
    expect(find.text('AI 用语过滤'), findsOneWidget);
    expect(find.text('综上所述'), findsOneWidget);
    expect(find.text('值得注意的是'), findsOneWidget);
    expect(find.text('众所周知'), findsOneWidget);

    await expectLater(
      find.byType(BannedPhraseSettingsPage),
      matchesGoldenFile('../../docs/readme/screenshots/21-banned-phrases.png'),
    );
  });
}

/// Mirrors `appTheme()`'s `MUSEFLOW_DISABLE_GOOGLE_FONTS=true` branch (same as
/// the manuscript-library screenshot test): indigo dark Material 3 scheme with
/// the CJK text theme bound to 'Noto Sans CJK SC'. Inline + self-contained so
/// the screenshot is deterministic without google_fonts / dart-define.
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

/// BannedPhrasesNotifier override returning a fixed seed list, bypassing the
/// settingsRepository/Hive chain entirely — the page only `watch`es this
/// provider in its render path.
class _SeededBannedPhrasesNotifier extends BannedPhrasesNotifier {
  _SeededBannedPhrasesNotifier(this._seed);

  final List<String> _seed;

  @override
  AsyncValue<List<String>> build() => AsyncValue.data(_seed);
}
