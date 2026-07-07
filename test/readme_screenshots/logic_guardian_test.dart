/// Real widget screenshot generator for the README logic-guardian image (#13).
///
/// Renders the **actual** [StoryStructurePage] on the 守护 (guardian) tab: tab 3
/// of the 5-tab structure page. `GuardianPanel` watches `guardianNotifierProvider`
/// and `activeApiKeyProvider`. Seeded into the `results` state with a non-empty
/// annotations list, it renders the findings list (`_FindingCard` with severity +
/// kind chips) — the truthful "guardian found these issues" view.
///
/// `activeApiKeyProvider` is overridden to a non-null value so the panel does
/// not show the "configure API key" prompt. `foreshadowingNotifierProvider` is
/// overridden so the initial tab-0 frame is clean before switching to tab 3.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/logic_guardian_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_notifier.dart';
import 'package:museflow/features/story_structure/application/guardian_notifier.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
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

  testWidgets('StoryStructurePage (守护) renders a real 1440x1000 screenshot', (
    tester,
  ) async {
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
          guardianNotifierProvider.overrideWith(
            () => _SeededGuardianNotifier(),
          ),
          // Non-null key so GuardianPanel renders the findings list, not the
          // "configure API key" prompt.
          activeApiKeyProvider.overrideWith((ref) => 'demo-key'),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const StoryStructurePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to tab 3 (守护). Tapping the tab drives the TabBarView slide.
    await tester.tap(find.text('守护'));
    await tester.pumpAndSettle();

    // Prove the seeded findings rendered: the 守护 tab + a couple finding
    // messages are present in the tree.
    expect(find.text('守护'), findsOneWidget);
    expect(find.text('林风性格前后矛盾'), findsOneWidget);
    expect(find.text('第八章时间线冲突'), findsOneWidget);

    await expectLater(
      find.byType(StoryStructurePage),
      matchesGoldenFile('../../docs/readme/screenshots/13-logic-guardian.png'),
    );
  });
}

/// Seeded GuardianNotifier returning a `results` state with 4 findings (mix of
/// kind + severity to render the chips truthfully), bypassing the repository /
/// LLM check chain. Bypasses `build()`'s repository read entirely.
class _SeededGuardianNotifier extends GuardianNotifier {
  @override
  Future<GuardianCheckResult> build() async {
    final created = _created;
    return GuardianCheckResult(
      state: GuardianCheckState.results,
      annotations: [
        GuardianAnnotation(
          id: 'g1',
          kind: GuardianFindingKind.characterConsistency,
          severity: GuardianSeverity.high,
          message: '林风性格前后矛盾',
          reason: '第十二章描写林风沉稳冷静，第三十五章却冲动行事，缺乏铺垫。',
          suggestedFix: '在第三十章前加入情绪积累的过渡段落。',
          sourceText: '林风怒不可遏，拔剑便刺',
          createdAt: created,
        ),
        GuardianAnnotation(
          id: 'g2',
          kind: GuardianFindingKind.timelineContradiction,
          severity: GuardianSeverity.medium,
          message: '第八章时间线冲突',
          reason: '苏雪晴第八章说"三日前离开药王谷"，但第五章已写她抵达宗门。',
          createdAt: created,
        ),
        GuardianAnnotation(
          id: 'g3',
          kind: GuardianFindingKind.worldRuleConflict,
          severity: GuardianSeverity.low,
          message: '灵气规则细节不一致',
          reason: '设定筑基期不能御剑，第二十章筑基主角却御剑飞行。',
          createdAt: created,
        ),
        GuardianAnnotation(
          id: 'g4',
          kind: GuardianFindingKind.unresolvedForeshadowing,
          severity: GuardianSeverity.medium,
          message: '古剑低鸣之谜未回收',
          reason: '第一章埋下的古剑低鸣伏笔，至第六十八章仍未揭示。',
          createdAt: created,
        ),
      ],
    );
  }
}

/// Seeded ForeshadowingNotifier (mirrors #10) so the initial tab-0 frame is
/// clean before switching to tab 3.
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
