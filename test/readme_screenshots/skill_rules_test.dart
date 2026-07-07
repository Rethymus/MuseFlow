/// Real widget screenshot generator for the README skill-rules image (#09).
///
/// Renders the **actual** [SkillListPage] — the "Skill 规则" view: AppBar
/// 「世界观模板」+ list of skill-document cards (each with icon, name, description
/// or sections, an active Switch, and a delete button) + FAB — at 1440x1000 with
/// seeded skill documents.
///
/// `SkillListPage` is a ConsumerWidget with its own Scaffold. It watches
/// `skillListNotifierProvider`; overridden with seeded data, bypassing the
/// repository/Hive chain. `_SkillTile` has no other provider dependency.
///
/// Shares the bundled universal GB2312 subset `test_assets/noto_sans_sc_subset.ttf`.
///
/// Regenerate after changing the page or seed data:
///   flutter test test/readme_screenshots/skill_rules_test.dart --update-goldens
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/skill_notifier.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/presentation/skill_list_page.dart';

void main() {
  setUpAll(() async {
    final bytes = await File(
      'test_assets/noto_sans_sc_subset.ttf',
    ).readAsBytes();
    final loader = FontLoader('Noto Sans CJK SC');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });

  testWidgets('SkillListPage renders a real 1440x1000 screenshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skillListNotifierProvider.overrideWith(
            () => _SeededSkillListNotifier(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(),
          home: const SkillListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prove the seeded data rendered: AppBar title and seeded skill names.
    expect(find.text('世界观模板'), findsOneWidget);
    expect(find.text('修仙境界体系'), findsOneWidget);
    expect(find.text('门派势力图谱'), findsOneWidget);

    await expectLater(
      find.byType(SkillListPage),
      matchesGoldenFile('../../docs/readme/screenshots/09-skill-rules.png'),
    );
  });
}

/// Seeded SkillListNotifier returning 4 xianxia skill documents, bypassing the
/// repository/Hive chain. The first is active (Switch on) to show the active
/// state truthfully. createdAt uses a FIXED DateTime.
class _SeededSkillListNotifier extends SkillListNotifier {
  @override
  Future<List<SkillDocument>> build() async {
    final created = _created;
    return <SkillDocument>[
      SkillDocument(
        id: 's1',
        name: '修仙境界体系',
        description: '修炼九重境界的划分、突破条件与灵气运转规则',
        content: '# 修仙境界体系\n',
        sections: SkillSections(powerHierarchy: '炼气、筑基、金丹、元婴、化神、合体、大乘、渡劫'),
        isActive: true,
        createdAt: created,
      ),
      SkillDocument(
        id: 's2',
        name: '门派势力图谱',
        description: '青云宗、药王谷、戒律堂等势力的关系与地盘划分',
        content: '# 门派势力图谱\n',
        sections: SkillSections(factionRelations: '青云宗与药王谷结盟，戒律堂暗中掌控旧案'),
        createdAt: created,
      ),
      SkillDocument(
        id: 's3',
        name: '力量规则与禁制',
        description: '战力等级、斗法规则、阵法禁制的设定约束',
        content: '# 力量规则\n',
        sections: SkillSections(rules: '同境界斗法，法宝与功法决定胜负'),
        createdAt: created,
      ),
      SkillDocument(
        id: 's4',
        name: '禁忌与术语表',
        description: '修炼禁忌、专有名词、世界观核心术语释义',
        content: '# 禁忌与术语\n',
        sections: SkillSections(
          taboos: '渡劫前不可动用全力，违者引来天劫加倍',
          terminology: '灵根、道基、剑印、问心石',
        ),
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
