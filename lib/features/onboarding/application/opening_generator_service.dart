/// AI service for generating story opening paragraphs.
///
/// Produces 3 distinct opening variants (scene-led, character-led,
/// suspense-led) via a single streaming API call. Follows the same
/// pattern as [TemplateCompletionService] from the templates feature.
library;

import 'dart:convert';

import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';

/// Typedef for test-only stream override.
///
/// In production, this is null and [OpeningGeneratorService] uses
/// [OpenAIAdapter.createStream]. In tests, provide a mock stream.
typedef OpeningStream = Stream<String> Function(List<ChatMessage> messages);

/// Maximum character length for [storyConcept] input (T-08-07).
const int _maxStoryConceptLength = 500;

/// Maximum character length per opening variant text (T-08-09).
const int _maxOpeningTextLength = 1000;

/// Service that generates 3 story opening variants via AI streaming.
///
/// Usage:
/// ```dart
/// final service = OpeningGeneratorService(
///   openAIAdapter: adapter,
///   apiKey: 'sk-...',
///   baseUrl: 'https://api.openai.com/v1',
///   model: 'gpt-4o-mini',
/// );
/// final variants = await service.generateOpenings(
///   genreName: '玄幻',
///   worldDescription: '修仙世界...',
///   characterDescription: '少年主角...',
/// );
/// ```
class OpeningGeneratorService {
  OpeningGeneratorService({
    this.openAIAdapter,
    this.apiKey,
    this.baseUrl,
    this.model,
    this.openingStream,
    this.auditService,
  });

  final OpenAIAdapter? openAIAdapter;
  final String? apiKey;
  final String? baseUrl;
  final String? model;

  /// Test-only override for the streaming function.
  final OpeningStream? openingStream;

  /// Optional audit service for token usage tracking.
  final TokenAuditService? auditService;

  /// Generates 3 opening variants via a single AI streaming call.
  ///
  /// Parameters:
  /// - [genreName]: Genre label (e.g., '玄幻', '都市')
  /// - [worldDescription]: World-building description
  /// - [characterDescription]: Character description
  /// - [storyConcept]: Optional story concept (truncated to 500 chars)
  ///
  /// Returns a list of [OpeningVariant] objects (typically 3).
  /// Returns an empty list on JSON parse errors or stream errors (T-08-08).
  Future<List<OpeningVariant>> generateOpenings({
    required String genreName,
    required String worldDescription,
    required String characterDescription,
    String? storyConcept,
    String? manuscriptId,
  }) async {
    try {
      final messages = _buildMessages(
        genreName: genreName,
        worldDescription: worldDescription,
        characterDescription: characterDescription,
        storyConcept: storyConcept,
      );

      // Capture input for audit (use descriptions)
      final inputText = 'Genre: $genreName\nWorld: $worldDescription\nCharacter: $characterDescription';

      final buffer = StringBuffer();

      if (openingStream != null) {
        // Test path
        final stream = openingStream!.call(messages);
        await for (final chunk in stream) {
          buffer.write(chunk);
        }
      } else {
        // Production path with audit
        final stream = openAIAdapter!.createStream(
          apiKey: apiKey!,
          baseUrl: baseUrl!,
          model: model!,
          messages: messages,
          onUsage: (usage) {
            // Only record if audit service is provided
            auditService?.recordAudit(
              usage: usage,
              modelName: model!,
              operationType: AuditOperationType.opening,
              manuscriptId: manuscriptId ?? '',
              chapterId: null,
              inputText: inputText,
              outputText: buffer.toString(),
            );
          },
        );
        await for (final chunk in stream) {
          buffer.write(chunk);
        }
      }

      final raw = buffer.toString().trim();
      final jsonStr = _stripMarkdownFences(raw);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      final openingsList = decoded['openings'] as List<dynamic>? ?? [];

      return openingsList
          .whereType<Map<String, dynamic>>()
          .map((item) => OpeningVariant.fromJson(item).copyWith(
                text: _truncateText(
                  item['text'] as String? ?? '',
                  _maxOpeningTextLength,
                ),
              ))
          .toList();
    } catch (error) {
      // T-08-08: Graceful fallback to empty list on any error.
      return [];
    }
  }

  /// Builds the system and user chat messages for the AI request.
  List<ChatMessage> _buildMessages({
    required String genreName,
    required String worldDescription,
    required String characterDescription,
    String? storyConcept,
  }) {
    // T-08-07: Truncate story concept to max length.
    final safeConcept = storyConcept != null && storyConcept.length > _maxStoryConceptLength
        ? storyConcept.substring(0, _maxStoryConceptLength)
        : storyConcept;

    return [
      ChatMessage.system(
        '你是 MuseFlow 开篇生成助手。根据给定的世界观、角色和故事概念，'
        '生成3种不同风格的开篇段落。只返回严格 JSON，不要返回 Markdown。'
        '返回格式: {"openings": [{"style": "scene", "text": "..."}, '
        '{"style": "character", "text": "..."}, {"style": "suspense", "text": "..."}]}。'
        '每种开篇200-400字，风格鲜明：scene=场景切入以环境描写开场，'
        'character=人物切入以角色动作/心理开场，suspense=悬念切入以疑问或紧张感开场。',
      ),
      ChatMessage.user(
        jsonEncode({
          'genre': genreName,
          'world': worldDescription,
          'character': characterDescription,
          if (safeConcept != null && safeConcept.isNotEmpty) 'concept': safeConcept,
        }),
      ),
    ];
  }

  /// Strips markdown code fences (```json ... ```) from AI response.
  ///
  /// Some AI models wrap JSON output in markdown fences despite instructions.
  String _stripMarkdownFences(String raw) {
    if (!raw.startsWith('```')) return raw;

    // Remove opening fence (```json or ```)
    var content = raw.replaceFirst(RegExp(r'^```(?:json)?\s*\n?'), '');

    // Remove closing fence (```)
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }

    return content.trim();
  }

  /// Truncates text to [maxLength] characters.
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength);
  }
}
