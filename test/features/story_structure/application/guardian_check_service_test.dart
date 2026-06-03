import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/story_structure/application/guardian_check_service.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

/// Simple character data holder for tests without Hive dependency.
class TestCharacterSource implements CharacterSource {
  final List<CharacterCard> _cards;

  TestCharacterSource(this._cards);

  @override
  List<CharacterCard> getAll() => _cards;

  @override
  List<CharacterCard> searchByName(String query) {
    final lowerQuery = query.toLowerCase();
    return _cards.where((card) {
      if (card.name.toLowerCase().contains(lowerQuery)) return true;
      return card.aliases
          .any((alias) => alias.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}

void main() {
  group('GuardianCheckService', () {
    late GuardianCheckService service;
    late TestCharacterSource characterSource;

    final aliceCard = CharacterCard(
      id: 'char-1',
      name: 'Alice',
      personality: 'Shy and introverted, rarely speaks unless spoken to',
      appearance: 'Small with brown hair',
      backstory: 'Grew up in a quiet village',
      aliases: const ['Ali'],
      createdAt: DateTime(2026, 1, 1),
    );

    final bobCard = CharacterCard(
      id: 'char-2',
      name: 'Bob',
      personality: 'Bold and outgoing, natural leader',
      appearance: 'Tall with red hair',
      backstory: 'Former soldier',
      aliases: const ['Bobby'],
      createdAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      characterSource = TestCharacterSource([aliceCard, bobCard]);
    });

    group('prompt building', () {
      test('should include character personality when name appears in text', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        final text = 'Alice walked into the room and boldly declared her intentions to everyone.';

        final prompt = service.buildPrompt(text: text);

        // Should include Alice's personality context
        expect(prompt, contains('Alice'));
        expect(prompt, contains('Shy'));
        expect(prompt, contains('introverted'));
      });

      test('should include character matched by alias', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        final text = 'Ali said something uncharacteristically brave.';

        final prompt = service.buildPrompt(text: text);

        expect(prompt, contains('Alice'));
      });

      test('should not include unrelated characters', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        // Only mentions Alice, should not include Bob's details
        final text = 'Alice sat quietly in the corner reading a book.';

        final prompt = service.buildPrompt(text: text);

        expect(prompt, contains('Alice'));
        // Bob should not be in the prompt since he's not mentioned
        expect(prompt, isNot(contains('Bold and outgoing')));
      });

      test('should handle text with no matching characters', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        final text = 'The wind howled through the empty streets.';

        final prompt = service.buildPrompt(text: text);

        // Should still build a valid prompt, just without character context
        expect(prompt, contains(text));
      });
    });

    group('JSON parsing', () {
      test('should parse valid JSON array into annotations', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        const jsonResponse = '''
[
  {
    "severity": "medium",
    "kind": "characterConsistency",
    "message": "Alice speaks too boldly",
    "reason": "Alice is described as shy and introverted but speaks confidently here",
    "suggestedFix": "Consider rewriting as a hesitant whisper",
    "sourceText": "Alice declared confidently"
  },
  {
    "severity": "low",
    "kind": "characterConsistency",
    "message": "Minor tone inconsistency",
    "reason": "Slightly out of character",
    "sourceText": "Alice said"
  }
]''';

        final annotations = service.parseResponse(jsonResponse);

        expect(annotations, hasLength(2));

        expect(annotations[0].severity, GuardianSeverity.medium);
        expect(annotations[0].kind, GuardianFindingKind.characterConsistency);
        expect(annotations[0].message, 'Alice speaks too boldly');
        expect(
          annotations[0].reason,
          'Alice is described as shy and introverted but speaks confidently here',
        );
        expect(
          annotations[0].suggestedFix,
          'Consider rewriting as a hesitant whisper',
        );
        expect(annotations[0].sourceText, 'Alice declared confidently');

        expect(annotations[1].severity, GuardianSeverity.low);
        expect(annotations[1].suggestedFix, isNull);
      });

      test('should handle malformed JSON gracefully returning empty list', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        const malformedJson = 'This is not JSON at all';

        final annotations = service.parseResponse(malformedJson);

        expect(annotations, isEmpty);
      });

      test('should handle JSON with missing fields gracefully', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        const partialJson = '''
[
  {
    "severity": "high",
    "message": "Missing fields test"
  }
]''';

        final annotations = service.parseResponse(partialJson);

        expect(annotations, hasLength(1));
        expect(annotations[0].severity, GuardianSeverity.high);
        expect(annotations[0].message, 'Missing fields test');
        // Missing fields should use defaults
        expect(annotations[0].kind, GuardianFindingKind.characterConsistency);
        expect(annotations[0].reason, isEmpty);
      });

      test('should handle empty JSON array', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        const emptyJson = '[]';

        final annotations = service.parseResponse(emptyJson);

        expect(annotations, isEmpty);
      });

      test('should handle JSON with nested code blocks', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        const wrappedJson = '```json\n[]\n```';

        final annotations = service.parseResponse(wrappedJson);

        expect(annotations, isEmpty);
      });
    });

    group('annotations should never auto-apply', () {
      test('parsed annotations should have no document mutation API', () {
        service = GuardianCheckService(
          characterSource: characterSource,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com',
          model: 'test-model',
        );

        const jsonResponse = '''
[
  {
    "severity": "high",
    "kind": "characterConsistency",
    "message": "Test",
    "reason": "Test reason",
    "suggestedFix": "A suggested rewrite"
  }
]''';

        final annotations = service.parseResponse(jsonResponse);

        // Verify suggestions are stored in suggestedFix
        expect(annotations[0].suggestedFix, 'A suggested rewrite');
        // No mutation API exists on GuardianAnnotation
        // (it's immutable with no apply/replace methods)
        expect(annotations[0].id, isNotEmpty);
        expect(annotations[0].createdAt, isNotNull);
      });
    });
  });
}
