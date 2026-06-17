import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';
import 'package:openai_dart/openai_dart.dart';

/// Generates a compact AI summary of a chapter's plot for long-form context
/// injection (MC-02 slice 1: pure summarization capability).
///
/// Reliability posture (lessons from quick-260617-wma + quick-260618-0ae):
/// - [AIAdapter.createStream] already retries early transient failures via
///   `OpenAIAdapter.retryStream`, so this service delegates streaming directly
///   without duplicating retry logic (single throat, wma principle).
/// - Strict output contract: system message forbids pleasantries/explanation;
///   summary is bounded so context injection stays cheap. Real LLMs pad output
///   unless constrained (0ae lesson).
/// - Errors are NOT silently swallowed: an [AIException] propagates to the
///   caller so a missing summary surfaces instead of being masked (0ae lesson —
///   deviation_detection's `catch (_)` blackout is the anti-pattern).
class ChapterSummarizationService {
  final AIAdapter openAIAdapter;
  final String apiKey;
  final String baseUrl;
  final String model;

  const ChapterSummarizationService({
    required this.openAIAdapter,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  /// Soft char ceiling for the generated summary, mirrored into the prompt so
  /// the model self-limits (hard cap is the maxTokens budget).
  static const int maxSummaryChars = 120;

  /// Summarizes [chapter]'s [Chapter.documentContent] into a [ChapterSummary].
  ///
  /// [summaryId] defaults to `summary-{chapterId}`; pass an explicit id when
  /// persisting (slice 2). [now] is injectable for deterministic tests.
  ///
  /// Throws [AIException] on stream failure (surfaced, not swallowed).
  Future<ChapterSummary> summarize(
    Chapter chapter, {
    String? summaryId,
    DateTime? now,
  }) async {
    final content = chapter.documentContent;
    final buffer = StringBuffer();
    final stream = openAIAdapter.createStream(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      messages: [
        ChatMessage.system('你是小说情节概括助手。只输出概括本身，不要解释、不要寒暄、不要分点标题。'),
        ChatMessage.user(_buildPrompt(content)),
      ],
      maxTokens: 200,
    );
    await for (final token in stream) {
      buffer.write(token);
    }
    final timestamp = now ?? DateTime.now();
    return ChapterSummary(
      id: summaryId ?? 'summary-${chapter.id}',
      chapterId: chapter.id,
      manuscriptId: chapter.manuscriptId,
      summary: buffer.toString().trim(),
      sourceWordCount: content.replaceAll(RegExp(r'\s'), '').length,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  String _buildPrompt(String content) {
    return '用一到两句话概括下面这一章的情节要点：主要人物做了什么、推进了什么事件、'
        '留下什么伏笔。不超过$maxSummaryChars字，只输出概括本身。\n\n'
        '【本章内容】\n$content';
  }
}
