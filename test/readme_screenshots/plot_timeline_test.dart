/// Real widget screenshot generator for the README plot-timeline image (#11).
///
/// Renders the **actual** [StoryStructurePage] on the 剧情线 (plot timeline) tab:
/// tab 1 of the 5-tab structure page. `PlotTimeline` is a ConsumerWidget that
/// watches `plotNodeNotifierProvider` and groups plot nodes by chapter into a
/// ListView (no custom painting / no animation — deterministic). Seeded with 5
/// plot nodes across chapters, each showing title + role chip + status chip +
/// summary + involved characters.
///
/// `foreshadowingNotifierProvider` is overridden so the initial tab-0 frame is
/// clean before switching to tab 1.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/plot_timeline_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_notifier.dart';
import 'package:museflow/features/story_structure/application/plot_node_notifier.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_structure_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('test_assets/noto_sans_sc_subset.ttf').readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('StoryStructurePage (剧情线) renders a real 1440x1000 screenshot',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          plotNodeNotifierProvider.overrideWith(() => _SeededPlotNodeNotifier()),
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

    // Switch to tab 1 (剧情线).
    await tester.tap(find.text('剧情线'));
    await tester.pumpAndSettle();

    // Prove the seeded plot nodes rendered: the 剧情线 tab + node titles.
    expect(find.text('剧情线'), findsOneWidget);
    expect(find.text('古剑觉醒'), findsOneWidget);
    expect(find.text('雾海探秘'), findsOneWidget);

    await expectLater(
      find.byType(StoryStructurePage),
      matchesGoldenFile('../../docs/readme/screenshots/11-plot-timeline.png'),
    );
  });
}

/// Seeded PlotNodeNotifier returning 5 xianxia plot nodes spanning chapters,
/// with a mix of structural roles and writing statuses (to render the role +
/// status chips truthfully). Bypasses the repository chain.
class _SeededPlotNodeNotifier extends PlotNodeNotifier {
  @override
  Future<List<PlotNode>> build() async {
    final created = _created;
    return <PlotNode>[
      PlotNode(
        id: 'p1',
        title: '古剑觉醒',
        chapter: 1,
        summary: '林风在山门前听见古剑低鸣，觉醒断裂剑印之力。',
        involvedCharacterNames: const ['林风'],
        writingStatus: PlotNodeWritingStatus.complete,
        structuralRole: PlotNodeStructuralRole.setup,
        createdAt: created,
      ),
      PlotNode(
        id: 'p2',
        title: '入门考验',
        chapter: 12,
        summary: '林风拜入青云宗，与苏雪晴初遇，通过问心石阶试炼。',
        involvedCharacterNames: const ['林风', '苏雪晴'],
        writingStatus: PlotNodeWritingStatus.drafting,
        structuralRole: PlotNodeStructuralRole.development,
        createdAt: created,
      ),
      PlotNode(
        id: 'p3',
        title: '弃剑峰之行',
        chapter: 35,
        summary: '林风重返弃剑峰，发现旧宗主令的线索。',
        involvedCharacterNames: const ['林风'],
        writingStatus: PlotNodeWritingStatus.drafting,
        structuralRole: PlotNodeStructuralRole.turn,
        createdAt: created,
      ),
      PlotNode(
        id: 'p4',
        title: '雾海探秘',
        chapter: 50,
        summary: '林风与慕容夜深入雾海禁地，险象环生。',
        involvedCharacterNames: const ['林风', '慕容夜'],
        writingStatus: PlotNodeWritingStatus.notStarted,
        structuralRole: PlotNodeStructuralRole.climax,
        createdAt: created,
      ),
      PlotNode(
        id: 'p5',
        title: '旧约揭晓',
        chapter: 68,
        summary: '弃剑峰旧约真相大白，林风直面戒律堂清虚真人。',
        involvedCharacterNames: const ['林风', '清虚真人'],
        writingStatus: PlotNodeWritingStatus.needsRevision,
        structuralRole: PlotNodeStructuralRole.resolution,
        createdAt: created,
      ),
    ];
  }
}

/// Seeded ForeshadowingNotifier so the initial tab-0 frame is clean before
/// switching to tab 1.
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
