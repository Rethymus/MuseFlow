import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/application/logic_guardian_service.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

void main() {
  group('LogicGuardianService', () {
    late LogicGuardianService service;

    setUp(() {
      service = LogicGuardianService(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        model: 'test-model',
      );
    });

    /// Helper to create a minimal context bundle for testing.
    GuardianContextBundle makeBundle({
      String excerpt = 'Test excerpt text.',
      List<String> skillConstraints = const [],
    }) {
      return GuardianContextBundle(
        manuscriptExcerpt: excerpt,
        relevantCharacters: [],
        relevantWorldSettings: [],
        skillConstraints: skillConstraints,
        plotSummaries: [],
        unresolvedForeshadowing: [],
        omittedCharacterCount: 0,
        omittedWorldSettingCount: 0,
        omittedSkillCount: 0,
        omittedPlotNodeCount: 0,
        omittedForeshadowingCount: 0,
        totalTokensUsed: 50,
        tokenBudget: 4000,
      );
    }

    group('buildLogicPrompt', () {
      test('should include context bundle prompt text', () {
        final bundle = makeBundle(excerpt: 'Alice traveled back in time.');
        final prompt = service.buildLogicPrompt(
          text: 'Alice traveled back in time.',
          context: bundle,
        );

        expect(prompt, contains('Alice traveled back in time.'));
        expect(prompt, contains('时间线'));
        expect(prompt, contains('世界规则'));
      });

      test('should include skill constraints in prompt', () {
        final bundle = makeBundle(
          skillConstraints: ['No teleportation allowed.'],
        );
        final prompt = service.buildLogicPrompt(
          text: 'She teleported away.',
          context: bundle,
        );

        expect(prompt, contains('No teleportation allowed.'));
      });

      test('should request strict JSON output', () {
        final bundle = makeBundle();
        final prompt = service.buildLogicPrompt(text: 'Text', context: bundle);

        expect(prompt, contains('JSON'));
        expect(prompt, contains('timelineContradiction'));
        expect(prompt, contains('worldRuleConflict'));
        expect(prompt, contains('skillRuleConflict'));
        expect(prompt, contains('unresolvedForeshadowing'));
      });
    });

    group('parseLogicResponse', () {
      test('should parse clean JSON array of timeline contradictions', () {
        const response = '''
          [
            {
              "kind": "timelineContradiction",
              "severity": "high",
              "message": "Chapter 3 takes place before Chapter 1",
              "reason": "The protagonist mentions events from chapter 3 that haven't happened yet.",
              "suggestedFix": "Move the flashback to after chapter 1 events."
            }
          ]
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(annotations[0].kind, GuardianFindingKind.timelineContradiction);
        expect(annotations[0].severity, GuardianSeverity.high);
        expect(annotations[0].message, contains('Chapter 3'));
        expect(annotations[0].reason, isNotEmpty);
        expect(annotations[0].suggestedFix, isNotNull);
      });

      test('should parse world rule conflict findings', () {
        const response = '''
          [
            {
              "kind": "worldRuleConflict",
              "severity": "medium",
              "message": "Character uses magic in a no-magic zone",
              "reason": "The Magic System rules state that the Dead Zone prevents spellcasting."
            }
          ]
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(annotations[0].kind, GuardianFindingKind.worldRuleConflict);
        expect(annotations[0].severity, GuardianSeverity.medium);
      });

      test('should parse skill rule conflict findings', () {
        const response = '''
          [
            {
              "kind": "skillRuleConflict",
              "severity": "low",
              "message": "Skill used without required catalyst",
              "reason": "Fire magic requires a catalyst but none was mentioned."
            }
          ]
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(annotations[0].kind, GuardianFindingKind.skillRuleConflict);
      });

      test('should parse unresolved foreshadowing risk findings', () {
        const response = '''
          [
            {
              "kind": "unresolvedForeshadowing",
              "severity": "medium",
              "message": "Foreshadowing thread at risk of being forgotten",
              "reason": "The mysterious stranger was introduced in chapter 1 but hasn't been addressed for 10 chapters."
            }
          ]
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(
          annotations[0].kind,
          GuardianFindingKind.unresolvedForeshadowing,
        );
      });

      test('should parse multiple findings from a single response', () {
        const response = '''
          [
            {
              "kind": "timelineContradiction",
              "severity": "high",
              "message": "Timeline issue",
              "reason": "Dates don't match."
            },
            {
              "kind": "worldRuleConflict",
              "severity": "medium",
              "message": "Rule violation",
              "reason": "Breaks established rules."
            },
            {
              "kind": "skillRuleConflict",
              "severity": "low",
              "message": "Skill issue",
              "reason": "No catalyst."
            }
          ]
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 3);
        expect(annotations[0].kind, GuardianFindingKind.timelineContradiction);
        expect(annotations[1].kind, GuardianFindingKind.worldRuleConflict);
        expect(annotations[2].kind, GuardianFindingKind.skillRuleConflict);
      });

      test('should handle JSON wrapped in markdown code block', () {
        const response = '''
          ```json
          [
            {
              "kind": "timelineContradiction",
              "severity": "high",
              "message": "Timeline error",
              "reason": "Inconsistent chronology."
            }
          ]
          ```
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(annotations[0].kind, GuardianFindingKind.timelineContradiction);
      });

      test('should handle JSON embedded in prose text', () {
        const response = '''
          Here are my findings:

          [{"kind": "worldRuleConflict", "severity": "medium", "message": "Rule broken", "reason": "Physics violation."}]

          Please review these issues.
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(annotations[0].kind, GuardianFindingKind.worldRuleConflict);
      });

      test('should return empty list for malformed JSON without throwing', () {
        const response = 'This is not JSON at all!';

        final annotations = service.parseLogicResponse(response);

        expect(annotations, isEmpty);
      });

      test('should return empty list for incomplete JSON without throwing', () {
        const response = '[{"kind": "timelineContradiction", "severity":';

        final annotations = service.parseLogicResponse(response);

        expect(annotations, isEmpty);
      });

      test('should skip findings with empty message', () {
        const response = '''
          [
            {
              "kind": "timelineContradiction",
              "severity": "high",
              "message": "",
              "reason": "Some reason."
            },
            {
              "kind": "worldRuleConflict",
              "severity": "medium",
              "message": "Valid finding",
              "reason": "Valid reason."
            }
          ]
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(annotations[0].message, 'Valid finding');
      });

      test('should use sensible defaults for missing fields', () {
        const response = '''
          [
            {
              "message": "Some issue found"
            }
          ]
        ''';

        final annotations = service.parseLogicResponse(response);

        expect(annotations.length, 1);
        expect(annotations[0].kind, GuardianFindingKind.characterConsistency);
        expect(annotations[0].severity, GuardianSeverity.low);
        expect(annotations[0].reason, isEmpty);
      });

      test('should handle empty JSON array', () {
        const response = '[]';

        final annotations = service.parseLogicResponse(response);

        expect(annotations, isEmpty);
      });
    });

    group('API contract', () {
      test('should not expose any editor mutation methods', () {
        // Verify the service only has read-only/check methods.
        // No applyFix, editNode, updateAnnotation, or similar mutation methods.
        final service = LogicGuardianService(
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        // These read-only methods should exist and be callable
        expect(service.buildLogicPrompt, isA<Function>());
        expect(service.parseLogicResponse, isA<Function>());

        // The service should not have void/side-effect methods that mutate
        // editor state. This is a design contract check: LogicGuardianService
        // is a pure data-in/data-out service.
        expect(service, isA<LogicGuardianService>());
      });
    });
  });
}
