/// Real widget screenshot generator for the README knowledge-characters image (#06).
///
/// Renders the **actual** [KnowledgeBasePage] — 知识库: the character-card tab
/// (AppBar "知识库" + TabBar 角色卡/世界观 + 模板库 button + search field +
/// FAB + character list) — at 1440x1000 with seeded character cards, producing
/// a truthful screenshot of the real knowledge-base UI.
///
/// KnowledgeBasePage has its own Scaffold (unlike CapturePage), so it is hosted
/// directly. Its `_CharacterCardList` watches `characterCardNotifierProvider`
/// (`AsyncNotifierProvider<CharacterCardNotifier, List<CharacterCard>>`) and each
/// `_CharacterCardTile` watches `chapterNotifierProvider` (for staleness). Both
/// are overridden with seeded data, bypassing the Hive/repository chain.
///
/// Default tab is index 0 (角色卡), so the character list renders without
/// tab interaction — exactly the #06 shot.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/knowledge_characters_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/character_card_notifier.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/presentation/knowledge_base_page.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('KnowledgeBasePage (角色卡) renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterCardNotifierProvider.overrideWith(
            () => _SeededCharacterCardNotifier(),
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

    // Prove the seeded data rendered: AppBar title, the 角色卡 tab, and the
    // seeded character names are present in the tree.
    expect(find.text('知识库'), findsOneWidget);
    expect(find.text('角色卡'), findsOneWidget);
    expect(find.text('林风'), findsOneWidget);
    expect(find.text('苏雪晴'), findsOneWidget);

    await expectLater(
      find.byType(KnowledgeBasePage),
      matchesGoldenFile(
        '../../docs/readme/screenshots/06-knowledge-characters.png',
      ),
    );
  });
}

/// Seeded CharacterCardNotifier returning 4 xianxia characters, bypassing the
/// repository/Hive chain. Names mirror the README's running 修仙 sample
/// (林风/苏雪晴/清虚真人/慕容夜). createdAt uses a FIXED DateTime (lesson from
/// #02: any time-derived render must be deterministic across runs).
class _SeededCharacterCardNotifier extends CharacterCardNotifier {
  @override
  Future<List<CharacterCard>> build() async {
    final created = _created;
    return <CharacterCard>[
      CharacterCard(
        id: 'c1',
        name: '林风',
        personality: '坚毅冷静，剑道天才',
        appearance: '青衫负剑，眉目清朗',
        backstory: '弃剑峰走出的少年，身负断裂剑印',
        aliases: const ['剑子'],
        createdAt: created,
      ),
      CharacterCard(
        id: 'c2',
        name: '苏雪晴',
        personality: '外柔内刚，医术精湛',
        appearance: '白衣如雪，常携药篓',
        backstory: '药王谷传人，暗中留下禁地线索',
        aliases: const ['药女'],
        createdAt: created,
      ),
      CharacterCard(
        id: 'c3',
        name: '清虚真人',
        personality: '深沉阴鸷，城府极深',
        appearance: '灰袍鹤发，目含寒星',
        backstory: '戒律堂长老，旧案卷指向之人',
        aliases: const <String>[],
        createdAt: created,
      ),
      CharacterCard(
        id: 'c4',
        name: '慕容夜',
        personality: '豪迈不羁，重情重义',
        appearance: '玄衣大氅，背负双刀',
        backstory: '北境剑修，与林风结伴闯雾海',
        aliases: const ['夜刀'],
        createdAt: created,
      ),
    ];
  }
}

/// Seeded ChapterNotifier returning an empty list — chapterCount stays 0, so
/// every character card's staleness is fresh (no stale badges), keeping the
/// screenshot focused on the character rows. Bypasses the chapter repository.
class _SeededChapterNotifier extends ChapterNotifier {
  @override
  Future<List<Chapter>> build() async => const <Chapter>[];
}

/// Fixed creation timestamp — the character card does not render createdAt in
/// the list tile, but a pinned value keeps the seed fully deterministic anyway
/// (habit enforced after the #02 wall-clock flake).
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
