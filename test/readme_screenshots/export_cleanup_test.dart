/// Real widget screenshot generator for the README export-cleanup image (#14).
///
/// Renders the **actual** [StoryStructurePage] on the 整理与导出 (finish & export)
/// tab: tab 4 of the 5-tab structure page. `_FinishExportSection` is a purely
/// static section (icon + headline + description + '预览清理' FilledButton +
/// '导出稿件' OutlinedButton) with NO provider dependency on its render path —
/// the dialogs it launches read providers only on tap.
///
/// Default tab is 0 (伏笔); the test switches to tab 4 by tapping the
/// '整理与导出' tab label then `pumpAndSettle`. `foreshadowingNotifierProvider`
/// is also overridden so the initial frame (tab 0) renders cleanly before the
/// switch (the foreshadowing section is briefly visible during the slide).
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/export_cleanup_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_notifier.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/presentation/story_structure_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('StoryStructurePage (整理与导出) renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Tab 0 (伏笔) is briefly visible before the switch; seed it so the
          // initial frame is clean. The captured tab 4 is static (no provider).
          foreshadowingNotifierProvider.overrideWith(
            () => _SeededForeshadowingNotifier(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const StoryStructurePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to tab 4 (整理与导出). Tapping the tab label drives the
    // TabBarView slide; pumpAndSettle completes it.
    await tester.tap(find.text('整理与导出'));
    await tester.pumpAndSettle();

    // Prove the static export section rendered.
    expect(find.text('整理成可交付的稿件'), findsOneWidget);
    expect(find.text('预览清理'), findsOneWidget);
    expect(find.text('导出稿件'), findsOneWidget);

    await expectLater(
      find.byType(StoryStructurePage),
      matchesGoldenFile('../../docs/readme/screenshots/14-export-cleanup.png'),
    );
  });
}

/// Seeded ForeshadowingNotifier (mirrors #10) so the initial tab-0 frame is
/// clean before switching to tab 4.
class _SeededForeshadowingNotifier extends ForeshadowingNotifier {
  @override
  Future<List<ForeshadowingEntry>> build() async {
    final created = _created;
    return <ForeshadowingEntry>[
      ForeshadowingEntry(
        id: 'f1',
        title: '古剑低鸣之谜',
        mode: ForeshadowingMode.detailed,
        status: ForeshadowingStatus.planted,
        plantedChapter: 1,
        sourceExcerpt: '林风在山门前听见古剑低鸣',
        createdAt: created,
      ),
      ForeshadowingEntry(
        id: 'f2',
        title: '弃剑峰旧约',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.developing,
        plantedChapter: 20,
        sourceExcerpt: '第八十章前揭开弃剑峰旧约',
        createdAt: created,
      ),
    ];
  }
}

final DateTime _created = DateTime(2026, 6, 1, 9, 30);

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
