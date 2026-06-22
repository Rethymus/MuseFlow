/// Real widget screenshot generator for the README template-gallery image (#08).
///
/// Renders the **actual** [TemplateGalleryPage] — 世界观模板库: AppBar +
/// SegmentedButton filter (全部/男频/女频) + search field + template card list
/// (each CircleAvatar icon + displayTitle + description + channel tag + tags).
///
/// Unlike the provider-watch pages, `TemplateGalleryPage` reads the repository
/// directly in initState: `_templatesFuture = ref.read(worldTemplateRepositoryProvider).getAll()`.
/// So `worldTemplateRepositoryProvider` (a `Provider<WorldTemplateRepository>`) is
/// overridden with a fake repository whose `getAll()` returns the seed list.
///
/// `WorldTemplate` has 13 required fields incl. nested `world`/`review` objects;
/// the nested objects are minimally seeded (the card only renders displayTitle,
/// description, channel, tags, icon). Lists are empty const.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/template_gallery_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/templates/domain/world_template.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';
import 'package:museflow/features/templates/presentation/template_gallery_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('test_assets/noto_sans_sc_subset.ttf').readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('TemplateGalleryPage renders a real 1440x1000 screenshot',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldTemplateRepositoryProvider.overrideWith(
            (ref) => _SeededTemplateRepository(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const TemplateGalleryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the seeded templates rendered: AppBar title + a couple display
    // titles (genreName｜subtitle).
    expect(find.text('世界观模板库'), findsOneWidget);
    expect(find.text('仙侠｜剑道苍穹'), findsOneWidget);
    expect(find.text('悬疑｜雪线旧约'), findsOneWidget);

    await expectLater(
      find.byType(TemplateGalleryPage),
      matchesGoldenFile('../../docs/readme/screenshots/08-template-gallery.png'),
    );
  });
}

/// Fake WorldTemplateRepository whose `getAll()` returns a seed list directly,
/// bypassing the asset `loadLibrary()` chain. `WorldTemplateRepository` is a
/// concrete class with a parameterless ctor, so a subclass overrides `getAll()`.
class _SeededTemplateRepository extends WorldTemplateRepository {
  @override
  Future<List<WorldTemplate>> getAll() async => _templates;
}

// `final`, not `const`: TemplateReviewMetadata.reviewedAt is a runtime DateTime
// (DateTime has no const ctor), so the templates cannot be fully const.
final List<WorldTemplate> _templates = <WorldTemplate>[
  WorldTemplate(
    id: 't1',
    channel: TemplateChannel.male,
    sortOrder: 1,
    genreName: '仙侠',
    subtitle: '剑道苍穹',
    description: '少年剑修觉醒断裂剑印，逆天改命的修仙长篇。',
    iconName: 'terrain',
    tags: <String>['热血', '逆命', '剑修'],
    review: TemplateReviewMetadata(
      sourceNote: 'demo seed',
      reviewedAt: _seededReviewedAt,
      qualityChecks: <String>[],
    ),
    world: WorldTemplateWorld(
      name: '青云界',
      description: '',
      rules: '',
      factions: '',
      geography: '',
      techLevel: '',
      aliases: <String>[],
    ),
    characters: <WorldTemplateCharacter>[],
    foreshadowingArcs: <ForeshadowingArc>[],
    openingSamples: <OpeningSample>[],
  ),
  WorldTemplate(
    id: 't2',
    channel: TemplateChannel.male,
    sortOrder: 2,
    genreName: '奇幻',
    subtitle: '雾海灯塔',
    description: '迷雾海域中守护灯塔的孤勇者，与深渊的低语抗争。',
    iconName: 'travel_explore',
    tags: <String>['冒险', '群像', '黑暗'],
    review: TemplateReviewMetadata(
      sourceNote: 'demo seed',
      reviewedAt: _seededReviewedAt,
      qualityChecks: <String>[],
    ),
    world: WorldTemplateWorld(
      name: '雾海域',
      description: '',
      rules: '',
      factions: '',
      geography: '',
      techLevel: '',
      aliases: <String>[],
    ),
    characters: <WorldTemplateCharacter>[],
    foreshadowingArcs: <ForeshadowingArc>[],
    openingSamples: <OpeningSample>[],
  ),
  WorldTemplate(
    id: 't3',
    channel: TemplateChannel.female,
    sortOrder: 3,
    genreName: '悬疑',
    subtitle: '雪线旧约',
    description: '雪山古宅尘封的旧约，牵出三代人的隐秘纠葛。',
    iconName: 'account_balance',
    tags: <String>['推理', '家族', '情感'],
    review: TemplateReviewMetadata(
      sourceNote: 'demo seed',
      reviewedAt: _seededReviewedAt,
      qualityChecks: <String>[],
    ),
    world: WorldTemplateWorld(
      name: '雪线古宅',
      description: '',
      rules: '',
      factions: '',
      geography: '',
      techLevel: '',
      aliases: <String>[],
    ),
    characters: <WorldTemplateCharacter>[],
    foreshadowingArcs: <ForeshadowingArc>[],
    openingSamples: <OpeningSample>[],
  ),
  WorldTemplate(
    id: 't4',
    channel: TemplateChannel.female,
    sortOrder: 4,
    genreName: '都市',
    subtitle: '霓虹旧事',
    description: '霓虹都市里四个陌生人的命运，因一通错拨的电话交汇。',
    iconName: 'location_city',
    tags: <String>['都市', '治愈', '群像'],
    review: TemplateReviewMetadata(
      sourceNote: 'demo seed',
      reviewedAt: _seededReviewedAt,
      qualityChecks: <String>[],
    ),
    world: WorldTemplateWorld(
      name: '霓虹城',
      description: '',
      rules: '',
      factions: '',
      geography: '',
      techLevel: '',
      aliases: <String>[],
    ),
    characters: <WorldTemplateCharacter>[],
    foreshadowingArcs: <ForeshadowingArc>[],
    openingSamples: <OpeningSample>[],
  ),
];

/// Fixed timestamp for the review metadata (TemplateReviewMetadata.reviewedAt
/// is a runtime DateTime, so the template list cannot be fully const — but the
/// value itself is pinned for determinism).
final DateTime _seededReviewedAt = DateTime(2026, 5, 1, 10, 0);

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
