import 'dart:convert';

import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:uuid/uuid.dart';

/// Service for detecting timeline, world-setting, skill-rule contradictions,
/// and unresolved foreshadowing risks in story text.
///
/// Sends bounded context to an AI provider and parses the response into
/// advisory [GuardianAnnotation] objects. Malformed AI output and provider
/// failures are non-blocking (return empty results, never throw through UI).
///
/// Key design constraints:
/// - Manual trigger only; never runs automatically.
/// - Suggestions are advisory only; never auto-apply to manuscript text.
/// - No editor mutation methods in the API (pure data-in/data-out).
class LogicGuardianService {
  final String _apiKey;
  final String _baseUrl;
  final String _model;
  final _uuid = const Uuid();

  LogicGuardianService({
    required this._apiKey,
    required this._baseUrl,
    required this._model,
  });

  /// Builds the logic guardian check prompt with bounded context.
  String buildLogicPrompt({
    required String text,
    required GuardianContextBundle context,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('你是一个小说逻辑一致性检查助手。');
    buffer.writeln('请检查以下文本是否存在时间线矛盾、世界规则冲突、技能规则冲突或未解决伏笔风险。');
    buffer.writeln();

    // Include the formatted context bundle
    buffer.write(context.formatAsPrompt());
    buffer.writeln();

    buffer.writeln('## 输出要求');
    buffer.writeln('请以 JSON 数组格式输出检查结果。每个元素包含：');
    buffer.writeln(
      '- kind: "timelineContradiction" | "worldRuleConflict" | "skillRuleConflict" | "unresolvedForeshadowing"（问题类型）',
    );
    buffer.writeln('- severity: "low" | "medium" | "high"（严重程度）');
    buffer.writeln('- message: 简短的问题描述');
    buffer.writeln('- reason: 详细的原因说明');
    buffer.writeln('- suggestedFix: 建议的修改（可选，无则为 null）');
    buffer.writeln();
    buffer.writeln('如果没有发现问题，返回空数组 []。');
    buffer.writeln('只输出 JSON 数组，不要添加任何其他文字。');

    return buffer.toString();
  }

  /// Parses an AI response string into a list of [GuardianAnnotation] objects.
  ///
  /// Handles:
  /// - Valid JSON arrays
  /// - JSON wrapped in code blocks (```json ... ```)
  /// - JSON embedded in surrounding prose
  /// - Malformed/invalid JSON (returns empty list)
  /// - Missing fields (uses sensible defaults)
  List<GuardianAnnotation> parseLogicResponse(String response) {
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

  /// Performs a full logic consistency check.
  ///
  /// Sends the text with bounded context to the AI provider
  /// and returns parsed annotations. Never throws; errors are
  /// returned as an empty list.
  Future<List<GuardianAnnotation>> checkLogic({
    required String text,
    required GuardianContextBundle context,
    String? nodeId,
    int? startOffset,
    int? endOffset,
  }) async {
    try {
      final prompt = buildLogicPrompt(text: text, context: context);

      final client = OpenAIClient.withApiKey(_apiKey, baseUrl: _baseUrl);

      final response = await client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: _model,
          messages: [ChatMessage.user(prompt)],
          temperature: 0.3,
        ),
      );

      client.close();

      final content = response.choices.firstOrNull?.message.content ?? '';
      if (content.isEmpty) return const [];

      final annotations = parseLogicResponse(content);

      // Enrich annotations with location data if provided
      return annotations
          .map(
            (a) => a.copyWith(
              nodeId: nodeId,
              startOffset: startOffset,
              endOffset: endOffset,
            ),
          )
          .toList();
    } catch (_) {
      // Errors are non-blocking; return empty result
      // The notifier handles showing retry affordances
      return const [];
    }
  }

  /// Extracts JSON from a response that may contain code blocks or prose.
  String _extractJson(String response) {
    final trimmed = response.trim();

    // Handle code block wrapping
    if (trimmed.startsWith('```')) {
      var withoutOpen = trimmed.replaceFirst(
        RegExp(r'^```(?:json)?\s*\n?'),
        '',
      );
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
