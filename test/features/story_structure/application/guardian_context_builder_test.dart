import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

void main() {
  group('GuardianContextBundle', () {
    test('should expose omitted counts for each section', () {
      final bundle = GuardianContextBundle(
        manuscriptExcerpt: 'text',
        relevantCharacters: [],
        relevantWorldSettings: [],
        skillConstraints: [],
        plotSummaries: [],
        unresolvedForeshadowing: [],
        omittedCharacterCount: 5,
        omittedWorldSettingCount: 3,
        omittedSkillCount: 1,
        omittedPlotNodeCount: 0,
        omittedForeshadowingCount: 2,
        totalTokensUsed: 100,
        tokenBudget: 1000,
      );

      expect(bundle.omittedCharacterCount, 5);
      expect(bundle.omittedWorldSettingCount, 3);
      expect(bundle.omittedSkillCount, 1);
      expect(bundle.omittedPlotNodeCount, 0);
      expect(bundle.omittedForeshadowingCount, 2);
    });

    test('should report budget usage percentage', () {
      final bundle = GuardianContextBundle(
        manuscriptExcerpt: 'text',
        relevantCharacters: [],
        relevantWorldSettings: [],
        skillConstraints: [],
        plotSummaries: [],
        unresolvedForeshadowing: [],
        omittedCharacterCount: 0,
        omittedWorldSettingCount: 0,
        omittedSkillCount: 0,
        omittedPlotNodeCount: 0,
        omittedForeshadowingCount: 0,
        totalTokensUsed: 250,
        tokenBudget: 1000,
      );

      expect(bundle.budgetUsagePercent, closeTo(25.0, 0.1));
    });
  });

  group('GuardianContextBuilder', () {
    late TokenBudgetCalculator tokenBudget;

    setUp(() {
      tokenBudget = TokenBudgetCalculator();
    });

    GuardianContextBuilder builder({int budget = 4000}) {
      return GuardianContextBuilder(
        tokenBudgetCalculator: tokenBudget,
        tokenBudget: budget,
      );
    }

    // Helper: create a character card
    CharacterCard makeCharacter({
      required String id,
      required String name,
      List<String> aliases = const [],
      String personality = 'Friendly and brave.',
    }) {
      return CharacterCard(
        id: id,
        name: name,
        aliases: aliases,
        personality: personality,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    // Helper: create a world setting
    WorldSetting makeWorldSetting({
      required String id,
      required String name,
      List<String> aliases = const [],
      String rules = 'Magic follows conservation of energy.',
    }) {
      return WorldSetting(
        id: id,
        name: name,
        aliases: aliases,
        rules: rules,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    // Helper: create a plot node
    PlotNode makePlotNode({
      required String id,
      required String title,
      required int chapter,
      String summary = 'Something happens.',
    }) {
      return PlotNode(
        id: id,
        title: title,
        chapter: chapter,
        summary: summary,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    // Helper: create a foreshadowing entry
    ForeshadowingEntry makeForeshadowing({
      required String id,
      required String title,
      required int plantedChapter,
      ForeshadowingStatus status = ForeshadowingStatus.planted,
      ForeshadowingMode mode = ForeshadowingMode.simple,
    }) {
      return ForeshadowingEntry(
        id: id,
        title: title,
        plantedChapter: plantedChapter,
        status: status,
        mode: mode,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    group('character relevance', () {
      test('should include characters whose name appears in checked text', () {
        final alice = makeCharacter(id: 'c1', name: 'Alice');
        final bob = makeCharacter(id: 'c2', name: 'Bob');
        final charlie = makeCharacter(id: 'c3', name: 'Charlie');

        final result = builder().build(
          checkedText: 'Alice walked into the room.',
          currentChapter: 1,
          characters: [alice, bob, charlie],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.relevantCharacters, contains(alice));
        expect(result.relevantCharacters, isNot(contains(bob)));
        expect(result.relevantCharacters, isNot(contains(charlie)));
      });

      test('should include characters whose alias appears in checked text', () {
        final alice = makeCharacter(
          id: 'c1',
          name: 'Alice',
          aliases: ['The White Rabbit'],
        );

        final result = builder().build(
          checkedText: 'The White Rabbit appeared.',
          currentChapter: 1,
          characters: [alice],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.relevantCharacters, contains(alice));
      });

      test('should report omitted characters when budget is too small', () {
        final chars = List.generate(
          20,
          (i) => makeCharacter(
            id: 'c$i',
            name:
                'Character$i with a long personality description that uses tokens',
            personality: 'A' * 200,
          ),
        );

        // All names appear in the text
        final text = chars.map((c) => c.name).join(' ');

        final result = builder(budget: 300).build(
          checkedText: text,
          currentChapter: 1,
          characters: chars,
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.omittedCharacterCount, greaterThan(0));
      });
    });

    group('world setting relevance', () {
      test(
        'should include world settings whose name appears in checked text',
        () {
          final magic = makeWorldSetting(id: 'w1', name: 'Magic System');
          final tech = makeWorldSetting(id: 'w2', name: 'Technology');

          final result = builder().build(
            checkedText: 'The Magic System governs all spells.',
            currentChapter: 1,
            characters: [],
            worldSettings: [magic, tech],
            skillConstraints: const [],
            plotNodes: [],
            foreshadowingEntries: [],
          );

          expect(result.relevantWorldSettings, contains(magic));
          expect(result.relevantWorldSettings, isNot(contains(tech)));
        },
      );

      test(
        'should include world settings whose alias appears in checked text',
        () {
          final magic = makeWorldSetting(
            id: 'w1',
            name: 'Magic System',
            aliases: ['The Weave'],
          );

          final result = builder().build(
            checkedText: 'She tapped into The Weave.',
            currentChapter: 1,
            characters: [],
            worldSettings: [magic],
            skillConstraints: const [],
            plotNodes: [],
            foreshadowingEntries: [],
          );

          expect(result.relevantWorldSettings, contains(magic));
        },
      );

      test('should omit unrelated world settings when budget is small', () {
        final settings = List.generate(
          10,
          (i) =>
              makeWorldSetting(id: 'w$i', name: 'World$i', rules: 'Rule ' * 50),
        );

        final text = settings.map((s) => s.name).join(' and ');

        final result = builder(budget: 200).build(
          checkedText: text,
          currentChapter: 1,
          characters: [],
          worldSettings: settings,
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.omittedWorldSettingCount, greaterThan(0));
      });
    });

    group('skill constraints', () {
      test('should include skill constraints in constraints-only form', () {
        const constraints = [
          'No character can use fire magic without a catalyst.',
          'Healing magic requires life force exchange.',
        ];

        final result = builder().build(
          checkedText: 'She tried to heal him.',
          currentChapter: 1,
          characters: [],
          worldSettings: [],
          skillConstraints: constraints,
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.skillConstraints, containsAll(constraints));
      });

      test('should omit skill constraints when budget is exceeded', () {
        final constraints = List.generate(
          20,
          (i) => 'Constraint $i: ${'X' * 100}',
        );

        final result = builder(budget: 200).build(
          checkedText: 'Some text',
          currentChapter: 1,
          characters: [],
          worldSettings: [],
          skillConstraints: constraints,
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.omittedSkillCount, greaterThan(0));
      });
    });

    group('plot node relevance', () {
      test('should prioritize plot nodes matching current chapter', () {
        final ch3Node = makePlotNode(
          id: 'p1',
          title: 'Chapter 3 Event',
          chapter: 3,
        );
        final ch5Node = makePlotNode(
          id: 'p2',
          title: 'Chapter 5 Event',
          chapter: 5,
        );
        final ch1Node = makePlotNode(
          id: 'p3',
          title: 'Chapter 1 Event',
          chapter: 1,
        );

        final result = builder().build(
          checkedText: 'The protagonist arrives.',
          currentChapter: 3,
          characters: [],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [ch3Node, ch5Node, ch1Node],
          foreshadowingEntries: [],
        );

        // Current chapter node should be first
        expect(result.plotSummaries.first.id, 'p1');
      });

      test('should include all plot nodes when budget allows', () {
        final nodes = List.generate(
          5,
          (i) => makePlotNode(id: 'p$i', title: 'Node $i', chapter: i + 1),
        );

        final result = builder(budget: 10000).build(
          checkedText: 'Story text',
          currentChapter: 3,
          characters: [],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: nodes,
          foreshadowingEntries: [],
        );

        expect(result.plotSummaries.length, 5);
        expect(result.omittedPlotNodeCount, 0);
      });
    });

    group('foreshadowing relevance', () {
      test('should include unresolved foreshadowing near current chapter', () {
        final near = makeForeshadowing(
          id: 'f1',
          title: 'Mysterious Stranger',
          plantedChapter: 1,
        );
        final far = makeForeshadowing(
          id: 'f2',
          title: 'Distant Prophecy',
          plantedChapter: 50,
        );

        final result = builder().build(
          checkedText: 'The stranger appeared again.',
          currentChapter: 3,
          characters: [],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [near, far],
        );

        expect(result.unresolvedForeshadowing, contains(near));
        // Far foreshadowing may or may not be included depending on budget,
        // but near one should always be prioritized
      });

      test('should exclude resolved foreshadowing', () {
        final resolved = makeForeshadowing(
          id: 'f1',
          title: 'Mystery Solved',
          plantedChapter: 1,
          status: ForeshadowingStatus.resolved,
        );
        final open = makeForeshadowing(
          id: 'f2',
          title: 'Mystery Open',
          plantedChapter: 1,
          status: ForeshadowingStatus.planted,
        );

        final result = builder().build(
          checkedText: 'The mystery deepened.',
          currentChapter: 3,
          characters: [],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [resolved, open],
        );

        expect(result.unresolvedForeshadowing, isNot(contains(resolved)));
        expect(result.unresolvedForeshadowing, contains(open));
      });
    });

    group('token budget', () {
      test('should never exceed the token budget', () {
        final chars = List.generate(
          50,
          (i) => makeCharacter(
            id: 'c$i',
            name: 'Char$i',
            personality: 'Personality ${'A' * 300}',
          ),
        );
        final text = chars.map((c) => c.name).join(' ');

        final result = builder(budget: 500).build(
          checkedText: text,
          currentChapter: 1,
          characters: chars,
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.totalTokensUsed, lessThanOrEqualTo(500));
      });

      test('should track total tokens used', () {
        final result = builder(budget: 4000).build(
          checkedText: 'Alice went to the market.',
          currentChapter: 1,
          characters: [makeCharacter(id: 'c1', name: 'Alice')],
          worldSettings: [],
          skillConstraints: const ['No magic in markets.'],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.totalTokensUsed, greaterThan(0));
      });
    });

    group('manuscript excerpt', () {
      test('should always include the manuscript excerpt', () {
        final result = builder().build(
          checkedText: 'The hero crossed the bridge.',
          currentChapter: 1,
          characters: [],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        expect(result.manuscriptExcerpt, 'The hero crossed the bridge.');
      });
    });

    group('formatAsPrompt', () {
      test('should produce a formatted prompt string with sections', () {
        final result = builder().build(
          checkedText: 'Alice entered the Magic System.',
          currentChapter: 1,
          characters: [makeCharacter(id: 'c1', name: 'Alice')],
          worldSettings: [makeWorldSetting(id: 'w1', name: 'Magic System')],
          skillConstraints: const ['No teleportation.'],
          plotNodes: [makePlotNode(id: 'p1', title: 'Arrival', chapter: 1)],
          foreshadowingEntries: [
            makeForeshadowing(
              id: 'f1',
              title: 'Hidden Power',
              plantedChapter: 1,
            ),
          ],
        );

        final prompt = result.formatAsPrompt();

        expect(prompt, contains('待检查文本'));
        expect(prompt, contains('Alice'));
        expect(prompt, contains('Magic System'));
        expect(prompt, contains('No teleportation.'));
        expect(prompt, contains('Arrival'));
        expect(prompt, contains('Hidden Power'));
      });

      test('should omit empty sections from prompt', () {
        final result = builder().build(
          checkedText: 'Some text.',
          currentChapter: 1,
          characters: [],
          worldSettings: [],
          skillConstraints: const [],
          plotNodes: [],
          foreshadowingEntries: [],
        );

        final prompt = result.formatAsPrompt();

        expect(prompt, contains('待检查文本'));
        // Empty sections should not appear as headers
        expect(prompt, isNot(contains('相关角色设定')));
      });
    });
  });
}
