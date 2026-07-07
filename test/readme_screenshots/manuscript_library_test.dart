/// Real widget screenshot generator for the README manuscript-library image.
///
/// Unlike the SVG mockups produced by `scripts/generate_readme_screenshots.mjs`,
/// this renders the **actual** [ManuscriptLibraryPage] widget with seeded demo
/// data at 1440x1000, producing a truthful screenshot of the real UI.
///
/// CJK text renders via a bundled `pyftsubset`-cut Noto Sans CJK SC subset
/// (`test_assets/noto_sans_sc_subset.ttf`, ~33KB — only the glyphs the page
/// shows), registered under the family name the theme expects. This makes the
/// render **deterministic across platforms** without depending on google_fonts
/// network access or system-installed CJK fonts (the subset travels with the
/// repo), so the golden is a valid regression assertion in CI.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/manuscript_library_test.dart --update-goldens
/// then deploy: cp test/readme_screenshots/manuscript-library.png \
///              docs/readme/screenshots/01-manuscript-library.png
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/presentation/manuscript_library_page.dart';

void main() {
  /// Register the bundled Noto Sans CJK SC subset under the family name the
  /// theme resolves, so CJK glyphs render (flutter_test does not use system
  /// fonts). Loaded from a File path (no pubspec asset declaration needed).
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('ManuscriptLibraryPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    // Offsets are relative to the REAL wall clock so ManuscriptCard's
    // _relativeTime (which calls DateTime.now() internally) renders a stable
    // "2小时前 / 1天前 / 5天前" no matter when the test runs — the wall clock
    // cancels out. A fixed `now` here would let the relative text drift with the
    // run time and break the golden in CI.
    final now = DateTime.now();
    final seed = <Manuscript>[
      Manuscript(
        id: 'm1',
        title: '剑道苍穹',
        genre: '仙侠',
        targetWordCount: 500000,
        status: '写作中',
        coverLetter: '剑',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Manuscript(
        id: 'm2',
        title: '雾海灯塔',
        genre: '奇幻',
        targetWordCount: 300000,
        status: '构思中',
        coverLetter: '雾',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Manuscript(
        id: 'm3',
        title: '雪线旧约',
        genre: '悬疑',
        targetWordCount: 200000,
        status: '已完成',
        coverLetter: '雪',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    // Surface sized to match the README mockup dimensions (1440x1000 @ 1x).
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manuscriptNotifierProvider.overrideWith(
            () => _SeededManuscriptNotifier(seed),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const ManuscriptLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert the seeded data rendered into the tree (proves real content, not
    // empty/error state). CJK glyph rasterization correctness follows from the
    // registered subset font (cmap verified to contain every glyph) + Flutter's
    // deterministic use of a registered font whose family name matches.
    expect(find.text('文稿库'), findsOneWidget);
    expect(find.text('剑道苍穹'), findsOneWidget);
    expect(find.text('雾海灯塔'), findsOneWidget);
    expect(find.text('雪线旧约'), findsOneWidget);

    await expectLater(
      find.byType(ManuscriptLibraryPage),
      matchesGoldenFile(
        '../../docs/readme/screenshots/01-manuscript-library.png',
      ),
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

/// ManuscriptNotifier override that returns a fixed seed list, bypassing the
/// Hive/repository chain entirely (no setUpHiveTest, no HttpOverrides trap) —
/// the library page only `watch`es this provider in its render path.
class _SeededManuscriptNotifier extends ManuscriptNotifier {
  _SeededManuscriptNotifier(this._seed);

  final List<Manuscript> _seed;

  @override
  Future<List<Manuscript>> build() async => _seed;
}
