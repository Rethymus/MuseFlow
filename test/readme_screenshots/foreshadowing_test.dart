/// Real widget screenshot generator for the README foreshadowing image (#10).
///
/// Renders the **actual** [StoryStructurePage] on the 伏笔 (foreshadowing) tab:
/// the default tab 0 of the 5-tab structure page (伏笔/剧情线/弧线图/守护/整理与导出).
/// Shows the AppBar + TabBar + foreshadowing entry list + FAB.
///
/// `_ForeshadowingSection` watches `foreshadowingNotifierProvider`; overridden
/// with seeded entries. `_ForeshadowingTile` has no provider dependency on the
/// render path (only ref.read in delete action), so a single override suffices.
/// Default tab 0 = 伏笔, so no tab interaction is needed.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/foreshadowing_test.dart --update-goldens
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
    final bytes = await File('test_assets/noto_sans_sc_subset.ttf').readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('StoryStructurePage (伏笔) renders a real 1440x1000 screenshot',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    // Prove the seeded data rendered: the 伏笔 tab and seeded entry titles.
    expect(find.text('伏笔'), findsOneWidget);
    expect(find.text('古剑低鸣之谜'), findsOneWidget);
    expect(find.text('弃剑峰旧约'), findsOneWidget);

    await expectLater(
      find.byType(StoryStructurePage),
      matchesGoldenFile('../../docs/readme/screenshots/10-foreshadowing.png'),
    );
  });
}

/// Seeded ForeshadowingNotifier returning 5 xianxia foreshadowing entries,
/// bypassing the repository/Hive chain. Mix of statuses (planted/developing/
/// resolved) and modes to render the status icons truthfully. createdAt uses a
/// FIXED DateTime.
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
        targetResolutionChapter: 80,
        sourceExcerpt: '林风在山门前听见古剑低鸣',
        notes: '与断裂剑印呼应，暗示剑灵未灭',
        createdAt: created,
      ),
      ForeshadowingEntry(
        id: 'f2',
        title: '苏雪晴的禁地线索',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.developing,
        plantedChapter: 12,
        sourceExcerpt: '药香留下的禁地线索',
        createdAt: created,
      ),
      ForeshadowingEntry(
        id: 'f3',
        title: '弃剑峰旧约',
        mode: ForeshadowingMode.detailed,
        status: ForeshadowingStatus.planted,
        plantedChapter: 20,
        targetResolutionChapter: 80,
        sourceExcerpt: '第八十章前揭开弃剑峰旧约',
        createdAt: created,
      ),
      ForeshadowingEntry(
        id: 'f4',
        title: '问心石断裂剑印',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.developing,
        plantedChapter: 35,
        sourceExcerpt: '问心石阶只回应断裂剑印',
        createdAt: created,
      ),
      ForeshadowingEntry(
        id: 'f5',
        title: '雾海旧宗主令',
        mode: ForeshadowingMode.simple,
        status: ForeshadowingStatus.resolved,
        plantedChapter: 40,
        resolvedChapter: 68,
        sourceExcerpt: '雾海裂隙深处藏着旧宗主令',
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
