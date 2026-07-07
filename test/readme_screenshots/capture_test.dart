/// Real widget screenshot generator for the README capture-inbox image (#02).
///
/// Renders the **actual** [CapturePage] — 灵感捕捉: the zero-click fragment
/// bullet-note workspace (input field, 故事/章节/场景 filter chips, fragment list,
/// AI-整理 button when ≥1 fragment selected) — at 1440x1000 with a seeded
/// [CaptureState], producing a truthful screenshot.
///
/// CapturePage's build watches captureProvider (state) + synthesisProvider
/// (idle by default → panel stays hidden) + captureInputProvider (empty default).
/// Only captureProvider is overridden with a seeded state carrying 6 realistic
/// fragments (4 selected) — bypassing the fragmentRepository/Hive chain. The
/// xianxia seed content mirrors the README's running 修仙 sample.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/capture_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/capture/presentation/capture_page.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('CapturePage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          captureProvider.overrideWith(() => _SeededCaptureNotifier()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          // CapturePage is a body-only widget (no Scaffold of its own); the real
          // app hosts it inside AppShellScaffold's Scaffold. Mirror that host
          // here: a bare Scaffold provides the Material ancestor the TextField
          // (capture_page.dart:113) and FilterChips (:204) require, with no
          // AppBar — the real desktop capture screen has no AppBar either.
          home: const Scaffold(body: CapturePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the seeded state rendered: the '全部' filter chip is present, and
    // 'AI 整理' button shows (which only renders when ≥1 fragment is selected
    // and the synthesis panel is hidden) — proving the 4-selection seed took.
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('AI 整理'), findsOneWidget);
    expect(find.text('林风在山门前听见古剑低鸣'), findsOneWidget);

    await expectLater(
      find.byType(CapturePage),
      matchesGoldenFile('../../docs/readme/screenshots/02-capture-inbox.png'),
    );
  });
}

/// Seeded CaptureNotifier returning a fixed state with 6 fragments (4 selected),
/// isLoading=false. Bypasses fragmentRepositoryProvider/Hive entirely. The seed
/// mirrors the README's 修仙 sample (林风/苏雪晴/弃剑峰/问心石/雾海).
class _SeededCaptureNotifier extends CaptureNotifier {
  @override
  CaptureState build() {
    // FIXED base (not DateTime.now()): FragmentCard renders the absolute
    // 'yyyy-MM-dd HH:mm' timestamp via _formatTimestamp, so a wall-clock seed
    // would make the right-edge timestamp column drift run-to-run (different
    // minute each run → flaky golden). A pinned base makes every createdAt
    // deterministic. (Unlike ManuscriptLibraryPage, which renders *relative*
    // '2小时前' text where now cancels out — capture shows absolute time.)
    final now = DateTime(2026, 6, 22, 22, 40);
    final fragments = <Fragment>[
      Fragment(
        id: 'f1',
        text: '林风在山门前听见古剑低鸣',
        tags: const ['故事'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 8)),
      ),
      Fragment(
        id: 'f2',
        text: '苏雪晴用药香留下禁地线索',
        tags: const ['故事'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 14)),
      ),
      Fragment(
        id: 'f3',
        text: '第八十章前揭开弃剑峰旧约',
        tags: const ['章节'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 20)),
      ),
      Fragment(
        id: 'f4',
        text: '问心石阶只回应断裂剑印',
        tags: const ['场景'],
        createdAt: now.subtract(const Duration(hours: 2, minutes: 28)),
      ),
      Fragment(
        id: 'f5',
        text: '雾海裂隙深处藏着旧宗主令',
        tags: const ['场景'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      ),
      Fragment(
        id: 'f6',
        text: '戒律堂的旧案卷指向清虚真人',
        tags: const ['章节'],
        createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
    ];
    return CaptureState(
      fragments: fragments,
      selectedIds: const {'f1', 'f2', 'f3', 'f4'},
      activeFilter: '全部',
      isLoading: false,
    );
  }
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
