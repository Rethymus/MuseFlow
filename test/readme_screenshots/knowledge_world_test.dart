/// Real widget screenshot generator for the README knowledge-world image (#07).
///
/// Renders the **actual** [KnowledgeBasePage] on the 世界观 (world-settings) tab:
/// the same page as #06, switched to tab 1 via a tap on the '世界观' tab label.
/// AppBar「知识库」+ TabBar + 模板库 button + search field + FAB + world-setting
/// list.
///
/// `_WorldSettingList` watches `worldSettingNotifierProvider` and each
/// `_WorldSettingTile` watches `chapterNotifierProvider` (for staleness). Both
/// are overridden with seeded data. The tab switch is driven by tapping the
/// '世界观' tab then `pumpAndSettle` so the TabBarView slide animation completes
/// deterministically before the golden capture.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/knowledge_world_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/world_setting_notifier.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/presentation/knowledge_base_page.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('test_assets/noto_sans_sc_subset.ttf').readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('KnowledgeBasePage (世界观) renders a real 1440x1000 screenshot',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldSettingNotifierProvider.overrideWith(
            () => _SeededWorldSettingNotifier(),
          ),
          chapterNotifierProvider.overrideWith(() => _SeededChapterNotifier()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const KnowledgeBasePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to the 世界观 tab (default is 角色卡, index 0). Tapping the tab
    // label drives the TabBarView slide; pumpAndSettle completes it.
    await tester.tap(find.text('世界观'));
    await tester.pumpAndSettle();

    // Prove the tab switched and the seeded world settings rendered.
    expect(find.text('知识库'), findsOneWidget);
    expect(find.text('世界观'), findsOneWidget);
    expect(find.text('青云界'), findsOneWidget);
    expect(find.text('弃剑峰'), findsOneWidget);

    await expectLater(
      find.byType(KnowledgeBasePage),
      matchesGoldenFile('../../docs/readme/screenshots/07-knowledge-world.png'),
    );
  });
}

/// Seeded WorldSettingNotifier returning 4 xianxia world-building entries,
/// bypassing the repository/Hive chain. Names mirror the README's running
/// 修仙 sample (青云界/弃剑峰/雾海禁地/戒律堂). createdAt uses a FIXED DateTime.
class _SeededWorldSettingNotifier extends WorldSettingNotifier {
  @override
  Future<List<WorldSetting>> build() async {
    final created = _created;
    return <WorldSetting>[
      WorldSetting(
        id: 'w1',
        name: '青云界',
        description: '人妖仙三族共存的修仙大世界',
        rules: '修炼需引天地灵气，境分九重',
        geography: '东域凡尘，西域妖土，北境冰原',
        createdAt: created,
      ),
      WorldSetting(
        id: 'w2',
        name: '弃剑峰',
        description: '断剑沉眠的古峰，林风出身之地',
        rules: '唯有断裂剑印可启问心石阶',
        geography: '青云界南陲，云雾终年不散',
        createdAt: created,
      ),
      WorldSetting(
        id: 'w3',
        name: '雾海禁地',
        description: '裂隙深处藏有旧宗主令的禁地',
        rules: '擅入者迷失于幻象，生还者寥寥',
        geography: '青云界东海，雾气凝而不散',
        createdAt: created,
      ),
      WorldSetting(
        id: 'w4',
        name: '戒律堂',
        description: '执掌宗门旧案的权力中枢',
        rules: '旧案卷封存百年，唯长老可阅',
        geography: '青云宗内院，石阶九十九级',
        createdAt: created,
      ),
    ];
  }
}

/// Seeded ChapterNotifier returning an empty list — chapterCount stays 0, so
/// every world setting's staleness is fresh (no stale badges).
class _SeededChapterNotifier extends ChapterNotifier {
  @override
  Future<List<Chapter>> build() async => const <Chapter>[];
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
