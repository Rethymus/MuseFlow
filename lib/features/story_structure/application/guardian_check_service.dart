import 'dart:convert';

import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:uuid/uuid.dart';

/// Interface for providing character card data to the guardian check service.
///
/// Abstracts the data source so the service can be tested without Hive.
abstract class CharacterSource {
  /// Returns all character cards.
  List<CharacterCard> getAll();

  /// Searches character cards by name substring (case-insensitive).
  List<CharacterCard> searchByName(String query);
}

/// Adapter that wraps [CharacterCardRepository] as a [CharacterSource].
class RepositoryCharacterSource implements CharacterSource {
  final CharacterCardRepository _repository;

  RepositoryCharacterSource(this._repository);

  @override
  List<CharacterCard> getAll() => _repository.getAll();

  @override
  List<CharacterCard> searchByName(String query) =>
      _repository.searchByName(query);
}

/// Service for performing manual character consistency guardian checks.
///
/// Sends selected text along with relevant character context to an AI provider
/// and parses the response into advisory [GuardianAnnotation] objects.
///
/// Key design constraints:
/// - Manual trigger only; never runs automatically.
/// - Suggestions are advisory only; never auto-apply to manuscript text.
/// - Malformed AI responses return empty results, never throw through UI.
///
/// Per T-05-02: Sends only selected text and top relevant character context,
/// not the entire knowledge base.
class GuardianCheckService {
  final CharacterSource _characterSource;
  final String _apiKey;
  final String _baseUrl;
  final String _model;
  final _uuid = const Uuid();

  GuardianCheckService({
    required this._characterSource,
    required this._apiKey,
    required this._baseUrl,
    required this._model,
  });

  /// Convenience constructor that wraps a [CharacterCardRepository].
  GuardianCheckService.fromRepository({
    required CharacterCardRepository characterRepository,
    required String apiKey,
    required String baseUrl,
    required String model,
  }) : this(
          characterSource: RepositoryCharacterSource(characterRepository),
          apiKey: apiKey,
          baseUrl: baseUrl,
          model: model,
        );

  /// Builds the guardian check prompt with relevant character context.
  ///
  /// Selects characters whose names or aliases appear in the text,
  /// then assembles a prompt asking for JSON-formatted findings.
  String buildPrompt({required String text}) {
    final relevantCards = _findRelevantCharacters(text);

    final buffer = StringBuffer();

    buffer.writeln('你是一个小说角色一致性检查助手。');
    buffer.writeln('请检查以下文本是否存在角色行为与角色设定不一致的情况。');
    buffer.writeln();
    buffer.writeln('## 待检查文本');
    buffer.writeln(text);
    buffer.writeln();

    if (relevantCards.isNotEmpty) {
      buffer.writeln('## 相关角色设定');
      for (final card in relevantCards) {
        buffer.writeln(card.toContextString);
        buffer.writeln();
      }
    } else {
      buffer.writeln('## 所有角色设定');
      for (final card in _characterSource.getAll()) {
        buffer.writeln(card.toContextString);
        buffer.writeln();
      }
    }

    buffer.writeln('## 输出要求');
    buffer.writeln('请以 JSON 数组格式输出检查结果。每个元素包含：');
    buffer.writeln('- severity: "low" | "medium" | "high"（严重程度）');
    buffer.writeln('- kind: "characterConsistency" | "timelineContradiction" | "worldRuleConflict" | "skillRuleConflict" | "unresolvedForeshadowing"（问题类型）');
    buffer.writeln('- message: 简短的问题描述');
    buffer.writeln('- reason: 详细的原因说明');
    buffer.writeln('- suggestedFix: 建议的修改（可选，无则为 null）');
    buffer.writeln('- sourceText: 涉及问题的原文片段');
    buffer.writeln();
    buffer.writeln('如果没有发现一致性问题，返回空数组 []。');
    buffer.writeln('只输出 JSON 数组，不要添加任何其他文字。');

    return buffer.toString();
  }

  /// Parses an AI response string into a list of [GuardianAnnotation] objects.
  ///
  /// Handles:
  /// - Valid JSON arrays
  /// - JSON wrapped in code blocks (```json ... ```)
  /// - Malformed/invalid JSON (returns empty list)
  /// - Missing fields (uses sensible defaults)
  List<GuardianAnnotation> parseResponse(String response) {
    try {
      final cleaned = _extractJson(response);
      if (cleaned.isEmpty) return const [];

      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_parseAnnotation)
          .where((a) => a.message.isNotEmpty)
          .toList();
    } catch (_) {
      // Malformed JSON returns non-blocking empty result
      return const [];
    }
  }

  /// Performs a full character consistency check.
  ///
  /// Sends the text to the AI provider with relevant character context
  /// and returns parsed annotations. Never throws; errors are returned
  /// as an empty list.
  Future<List<GuardianAnnotation>> checkCharacterConsistency({
    required String text,
    String? nodeId,
    int? startOffset,
    int? endOffset,
  }) async {
    try {
      final prompt = buildPrompt(text: text);

      final client = OpenAIClient.withApiKey(
        _apiKey,
        baseUrl: _baseUrl,
      );

      final response = await client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: _model,
          messages: [
            ChatMessage.user(prompt),
          ],
          temperature: 0.3,
        ),
      );

      client.close();

      final content = response.choices.firstOrNull?.message.content ?? '';
      if (content.isEmpty) return const [];

      final annotations = parseResponse(content);

      // Enrich annotations with location data if provided
      return annotations
          .map((a) => a.copyWith(
                nodeId: nodeId,
                startOffset: startOffset,
                endOffset: endOffset,
              ))
          .toList();
    } catch (_) {
      // Errors are non-blocking; return empty result
      // The notifier handles showing retry affordances
      return const [];
    }
  }

  /// Finds characters whose names or aliases appear in the given text.
  List<CharacterCard> _findRelevantCharacters(String text) {
    final allCards = _characterSource.getAll();
    final lowerText = text.toLowerCase();

    return allCards.where((card) {
      if (lowerText.contains(card.name.toLowerCase())) return true;
      return card.aliases
          .any((alias) => lowerText.contains(alias.toLowerCase()));
    }).toList();
  }

  /// Extracts JSON from a response that may contain code blocks or extra text.
  String _extractJson(String response) {
    final trimmed = response.trim();

    // Handle code block wrapping
    if (trimmed.startsWith('```')) {
      // Remove opening code fence
      var withoutOpen = trimmed.replaceFirst(RegExp(r'^```(?:json)?\s*\n?'), '');
      // Remove closing code fence
      withoutOpen = withoutOpen.replaceFirst(RegExp(r'\n?```\s*$'), '');
      return withoutOpen.trim();
    }

    // Try to find JSON array in the response
    final startIndex = trimmed.indexOf('[');
    final endIndex = trimmed.lastIndexOf(']');
    if (startIndex != -1 && endIndex > startIndex) {
      return trimmed.substring(startIndex, endIndex + 1);
    }

    return trimmed;
  }

  /// Parses a single JSON object into a [GuardianAnnotation].
  GuardianAnnotation _parseAnnotation(Map<String, dynamic> json) {
    return GuardianAnnotation(
      id: _uuid.v4(),
      kind: _parseKind(json['kind'] as String?),
      severity: _parseSeverity(json['severity'] as String?),
      message: json['message'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      suggestedFix: json['suggestedFix'] as String?,
      sourceText: json['sourceText'] as String?,
      characterIds: const [],
      createdAt: DateTime.now(),
    );
  }

  GuardianFindingKind _parseKind(String? value) {
    if (value == null) return GuardianFindingKind.characterConsistency;
    return GuardianFindingKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GuardianFindingKind.characterConsistency,
    );
  }

  GuardianSeverity _parseSeverity(String? value) {
    if (value == null) return GuardianSeverity.low;
    return GuardianSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GuardianSeverity.low,
    );
  }
}
