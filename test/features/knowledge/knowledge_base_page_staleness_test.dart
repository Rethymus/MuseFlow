// Widget tests for MC-01 knowledge-base staleness UI wiring.
//
// These tests do NOT import the private _CharacterCardTile / _WorldSettingTile
// widgets directly (private classes can't be referenced across files). Instead
// they pump the public [KnowledgeBasePage] and assert on the rendered staleness
// badges / action menu via find.byIcon / find.textContaining.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/character_card_notifier.dart';
import 'package:museflow/features/knowledge/application/world_setting_notifier.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/presentation/knowledge_base_page.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

void main() {
  group('_CharacterCardTile staleness', () {
    testWidgets(
      'should show no staleness badge when legacy lastVerifiedChapter is null',
      (tester) async {
        await _pumpKnowledgePage(
          tester,
          chapterCount: 5,
          cards: [_makeCharacterCard(lastVerifiedChapter: null)],
        );

        // Tile rendered (PopupMenu visible).
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      },
    );

    testWidgets(
      'should show amber badge with stale message when since is 13 chapters',
      (tester) async {
        await _pumpKnowledgePage(
          tester,
          chapterCount: 15,
          cards: [_makeCharacterCard(lastVerifiedChapter: 2)],
        );

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(find.textContaining('13 章未验证'), findsOneWidget);
      },
    );

    testWidgets(
      'should show red badge with 严重过期 message when since is 23 chapters',
      (tester) async {
        await _pumpKnowledgePage(
          tester,
          chapterCount: 25,
          cards: [_makeCharacterCard(lastVerifiedChapter: 2)],
        );

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
        expect(find.textContaining('严重过期'), findsOneWidget);
      },
    );
  });

  group('_WorldSettingTile staleness', () {
    testWidgets('should show amber badge when world setting is stale', (
      tester,
    ) async {
      await _pumpKnowledgePage(
        tester,
        chapterCount: 18,
        cards: const [],
        settings: [_makeWorldSetting(lastVerifiedChapter: 3)],
        initialTab: 1,
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('15 章未验证'), findsOneWidget);
    });

    testWidgets('should show red badge when world setting is very stale', (
      tester,
    ) async {
      await _pumpKnowledgePage(
        tester,
        chapterCount: 30,
        cards: const [],
        settings: [_makeWorldSetting(lastVerifiedChapter: 5)],
        initialTab: 1,
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('严重过期'), findsOneWidget);
    });
  });

  group('mark-as-verified action', () {
    testWidgets(
      'should call CharacterCardNotifier.save with current chapterCount '
      'when user confirms',
      (tester) async {
        final fakeCard = _FakeCharacterCardNotifier(
          cards: [_makeCharacterCard(lastVerifiedChapter: 2)],
        );

        await _pumpKnowledgePage(
          tester,
          chapterCount: 15,
          cards: null,
          fakeCharacterNotifier: fakeCard,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('标记为已验证'));
        await tester.pumpAndSettle();

        expect(find.text('标记为已验证'), findsWidgets);
        await tester.tap(find.widgetWithText(TextButton, '确认').last);
        await tester.pumpAndSettle();

        expect(fakeCard.savedCard, isNotNull);
        expect(fakeCard.savedCard!.lastVerifiedChapter, 15);
      },
    );

    testWidgets(
      'should call WorldSettingNotifier.save with current chapterCount '
      'when user confirms',
      (tester) async {
        final fakeSetting = _FakeWorldSettingNotifier(
          settings: [_makeWorldSetting(lastVerifiedChapter: 3)],
        );

        await _pumpKnowledgePage(
          tester,
          chapterCount: 18,
          cards: const [],
          settings: null,
          fakeWorldSettingNotifier: fakeSetting,
          initialTab: 1,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('标记为已验证'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, '确认').last);
        await tester.pumpAndSettle();

        expect(fakeSetting.savedSetting, isNotNull);
        expect(fakeSetting.savedSetting!.lastVerifiedChapter, 18);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

CharacterCard _makeCharacterCard({required int? lastVerifiedChapter}) {
  return CharacterCard(
    id: 'char-1',
    name: '林青',
    personality: '冷静、坚韧',
    createdAt: DateTime(2026, 1, 1),
    lastVerifiedChapter: lastVerifiedChapter,
  );
}

WorldSetting _makeWorldSetting({required int? lastVerifiedChapter}) {
  return WorldSetting(
    id: 'set-1',
    name: '北方帝国',
    description: '寒冷之地',
    createdAt: DateTime(2026, 1, 1),
    lastVerifiedChapter: lastVerifiedChapter,
  );
}

/// Pumps [KnowledgeBasePage] with fake providers.
///
/// [cards] / [settings] when non-null create a real fake notifier via the
/// [_FakeCharacterCardNotifier] / [_FakeWorldSettingNotifier] classes; when
/// null the corresponding [fakeXxxNotifier] override is used instead so the
/// action tests can capture `save()` calls.
Future<void> _pumpKnowledgePage(
  WidgetTester tester, {
  required int chapterCount,
  List<CharacterCard>? cards,
  List<WorldSetting>? settings,
  _FakeCharacterCardNotifier? fakeCharacterNotifier,
  _FakeWorldSettingNotifier? fakeWorldSettingNotifier,
  int initialTab = 0,
}) async {
  final characterNotifier =
      fakeCharacterNotifier ??
      _FakeCharacterCardNotifier(cards: cards ?? const []);
  final worldNotifier =
      fakeWorldSettingNotifier ??
      _FakeWorldSettingNotifier(settings: settings ?? const []);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chapterNotifierProvider.overrideWith(
          () => _FixedChapterNotifier(chapterCount),
        ),
        characterCardNotifierProvider.overrideWith(() => characterNotifier),
        worldSettingNotifierProvider.overrideWith(() => worldNotifier),
      ],
      child: MaterialApp(home: KnowledgeBasePage()),
    ),
  );

  // Pump the initial build (loaders resolve synchronously since the fake
  // notifiers' build() returns immediately).
  await tester.pumpAndSettle();

  if (initialTab == 1) {
    // Tap the second tab "世界观".
    final tabBar = find.byType(TabBar);
    await tester.tap(tabBar);
    await tester.pumpAndSettle();
    // Find the second Tab widget specifically.
    final tabs = find.descendant(
      of: find.byType(TabBar),
      matching: find.byType(Tab),
    );
    await tester.tap(tabs.at(1));
    await tester.pumpAndSettle();
  }
}

/// Fake chapter notifier returning a fixed-length chapter list.
class _FixedChapterNotifier extends ChapterNotifier {
  _FixedChapterNotifier(this.count);

  final int count;

  @override
  Future<List<Chapter>> build() async {
    final now = DateTime(2026, 1, 1);
    return [
      for (var i = 0; i < count; i++)
        Chapter(
          id: 'c$i',
          manuscriptId: 'm1',
          title: '第${i + 1}章',
          sortOrder: i,
          createdAt: now,
          updatedAt: now,
        ),
    ];
  }
}

/// Fake character-card notifier that records the last `save()` argument.
class _FakeCharacterCardNotifier extends CharacterCardNotifier {
  _FakeCharacterCardNotifier({required this.cards});

  final List<CharacterCard> cards;

  CharacterCard? savedCard;

  @override
  Future<List<CharacterCard>> build() async => cards;

  @override
  Future<void> save(CharacterCard card) async {
    savedCard = card;
    state = AsyncData([card]);
  }
}

/// Fake world-setting notifier that records the last `save()` argument.
class _FakeWorldSettingNotifier extends WorldSettingNotifier {
  _FakeWorldSettingNotifier({required this.settings});

  final List<WorldSetting> settings;

  WorldSetting? savedSetting;

  @override
  Future<List<WorldSetting>> build() async => settings;

  @override
  Future<void> save(WorldSetting setting) async {
    savedSetting = setting;
    state = AsyncData([setting]);
  }
}
