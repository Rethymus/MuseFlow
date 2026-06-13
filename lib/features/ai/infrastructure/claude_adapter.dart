/// Claude/Anthropic API adapter with streaming and error recovery.
///
/// Wraps the `anthropic_sdk_dart` package's [AnthropicClient] to provide:
/// - Streaming text deltas via [createStream]
/// - Error classification into typed [AIException] hierarchy
/// - Client caching to prevent memory leaks
/// - Message conversion from OpenAI [ChatMessage] format to Anthropic format
///
/// The adapter implements the same [AIAdapter] interface as [OpenAIAdapter]
/// so callers can use either interchangeably. Internally converts:
/// - OpenAI system messages → Anthropic `system` parameter
/// - OpenAI user messages → Anthropic `InputMessage.user()`
/// - OpenAI assistant messages → Anthropic `InputMessage.assistant()`
/// - Anthropic usage → OpenAI [Usage] for compatibility
library;

import 'dart:async';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:flutter/foundation.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:openai_dart/openai_dart.dart';

/// Adapter for Anthropic Claude API streaming.
///
/// Converts OpenAI-format messages to Anthropic format and streams
/// responses back as text deltas. Client is cached per apiKey+baseUrl
/// combination, matching the [OpenAIAdapter] lifecycle pattern.
class ClaudeAdapter implements AIAdapter {
  anthropic.AnthropicClient? _client;
  String? _cachedApiKey;
  String? _cachedBaseUrl;
  bool _disposed = false;

  /// Creates a stream of text deltas from the Claude API.
  ///
  /// Accepts OpenAI-format [ChatMessage] and converts them to Anthropic
  /// format internally. System messages are extracted and passed as the
  /// top-level `system` prompt per Claude API convention.
  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  }) {
    // Get or create cached client
    final client = _getOrCreateClient(apiKey, baseUrl);

    // Convert OpenAI messages to Anthropic format
    final systemPrompt = _extractSystemPrompt(messages);
    final anthropicMessages = _convertMessages(messages);

    // Build request
    final request = anthropic.MessageCreateRequest(
      model: model,
      maxTokens: maxTokens ?? 4096,
      messages: anthropicMessages,
      system: systemPrompt != null
          ? anthropic.SystemPrompt.text(systemPrompt)
          : null,
      temperature: temperature,
      topP: topP,
    );

    // Track usage across BOTH stream events:
    //   MessageStartEvent carries INPUT (prompt) tokens at stream start.
    //   MessageDeltaEvent carries OUTPUT (completion) tokens at stream end.
    // Anthropic splits usage across two events; MessageDeltaUsage.inputTokens
    // is null in real streams, so prompt tokens MUST come from the start event.
    int? startInputTokens;
    anthropic.MessageDeltaUsage? deltaUsage;

    // Map the Claude stream to text deltas
    return client.messages
        .createStream(request)
        .map((event) {
          // Capture INPUT tokens from message_start events (prompt)
          if (event is anthropic.MessageStartEvent) {
            startInputTokens = event.message.usage.inputTokens;
          }
          // Capture OUTPUT tokens from message_delta events (completion)
          if (event is anthropic.MessageDeltaEvent) {
            deltaUsage = event.usage;
          }
          return _extractTextDelta(event);
        })
        .where((delta) => delta.isNotEmpty)
        .handleError((error) {
          throw _classifyException(error);
        })
        .transform(
          StreamTransformer<String, String>.fromHandlers(
            handleDone: (sink) {
              // Convert captured Anthropic usage to OpenAI Usage format,
              // using the same logic as processStreamEvents (DRY).
              onUsage?.call(_buildUsage(startInputTokens, deltaUsage));
              sink.close();
            },
          ),
        );
  }

  /// Extracts system prompt text from OpenAI system messages.
  ///
  /// Anthropic handles system prompts as a separate parameter rather than
  /// a message in the conversation array. Multiple system messages are
  /// concatenated with newlines.
  String? _extractSystemPrompt(List<ChatMessage> messages) {
    final systemTexts = <String>[];
    for (final msg in messages) {
      if (msg.role == 'system') {
        systemTexts.add(_getMessageContent(msg));
      }
    }
    return systemTexts.isEmpty ? null : systemTexts.join('\n\n');
  }

  /// Converts OpenAI ChatMessage list to Anthropic InputMessage list.
  ///
  /// Filters out system messages (handled separately) and maps user/assistant
  /// roles to Anthropic format.
  List<anthropic.InputMessage> _convertMessages(List<ChatMessage> messages) {
    return messages
        .where((msg) =>
            msg.role != 'system' && msg.role != 'developer')
        .map((msg) {
      final text = _getMessageContent(msg);
      if (msg.role == 'user') {
        return anthropic.InputMessage.user(text);
      }
      if (msg.role == 'assistant') {
        return anthropic.InputMessage.assistant(text);
      }
      // Fallback: treat unknown roles as user
      return anthropic.InputMessage.user(text);
    }).toList();
  }

  /// Extracts text content from a ChatMessage regardless of role.
  ///
  /// Uses the concrete type hierarchy because openai_dart v6 has different
  /// content types per role: SystemMessage.content is String, but
  /// UserMessage.content is UserMessageContent (may be UserTextContent or
  /// UserPartsContent), and AssistantMessage.content is String?.
  String _getMessageContent(ChatMessage msg) {
    return switch (msg) {
      final SystemMessage m => m.content,
      final UserMessage m => _extractUserText(m.content),
      final AssistantMessage m => m.content ?? '',
      // Developer messages are not sent to Claude, but handle gracefully
      _ => '',
    };
  }

  /// Extracts plain text from a [UserMessageContent].
  ///
  /// Handles text-only content and falls back to joining all text parts.
  static String _extractUserText(dynamic content) {
    if (content is UserTextContent) return content.text;
    if (content is UserPartsContent) {
      return content.parts
          .whereType<TextContentPart>()
          .map((p) => p.text)
          .join('');
    }
    return content.toString();
  }

  /// Extracts text from a Claude stream event.
  String _extractTextDelta(anthropic.MessageStreamEvent event) {
    if (event is anthropic.ContentBlockDeltaEvent &&
        event.delta is anthropic.TextDelta) {
      return (event.delta as anthropic.TextDelta).text;
    }
    return '';
  }

  /// Processes a list of Claude stream events for unit testing.
  ///
  /// This is a testable seam extracted from [createStream] so usage-capture
  /// logic can be exercised without a live API. It iterates [events],
  /// accumulates text from [anthropic.ContentBlockDeltaEvent] deltas, captures
  /// usage from BOTH [anthropic.MessageStartEvent] (input/prompt tokens) and
  /// [anthropic.MessageDeltaEvent] (output/completion tokens), and invokes
  /// [onUsage] exactly once with the combined usage (or null if neither usage
  /// event was seen). Returns the concatenated text.
  ///
  /// Anthropic splits usage across two stream events: input tokens arrive in
  /// `MessageStartEvent.message.usage.inputTokens` at start, output tokens
  /// arrive in `MessageDeltaEvent.usage.outputTokens` at end. Reading input
  /// tokens from `MessageDeltaUsage` is wrong — that field is null in real
  /// streams, which is the root cause of the promptTokens=0 audit bug.
  @visibleForTesting
  String processStreamEvents(
    List<anthropic.MessageStreamEvent> events, {
    void Function(Usage?)? onUsage,
  }) {
    final buffer = StringBuffer();
    int? startInputTokens;
    anthropic.MessageDeltaUsage? deltaUsage;

    for (final event in events) {
      if (event is anthropic.MessageStartEvent) {
        startInputTokens = event.message.usage.inputTokens;
      } else if (event is anthropic.MessageDeltaEvent) {
        deltaUsage = event.usage;
      } else if (event is anthropic.ContentBlockDeltaEvent &&
          event.delta is anthropic.TextDelta) {
        buffer.write((event.delta as anthropic.TextDelta).text);
      }
    }

    onUsage?.call(_buildUsage(startInputTokens, deltaUsage));

    return buffer.toString();
  }

  /// Builds the OpenAI-compatible [Usage] from the two captured Anthropic
  /// usage events.
  ///
  /// - [startInputTokens]: prompt tokens from `MessageStartEvent` (non-null in
  ///   real streams).
  /// - [deltaUsage]: completion usage from `MessageDeltaEvent` (provides
  ///   `outputTokens`; its `inputTokens` is intentionally ignored — it is null
  ///   in real streams and is the bug source).
  ///
  /// Returns:
  /// - A [Usage] combining prompt + completion when BOTH events were seen.
  /// - null when NEITHER event was seen (preserves the "unknown usage = null"
  ///   contract that downstream token audit relies on).
  /// - A partial-but-nonzero [Usage] when only one event arrived (defensive:
  ///   prefer recording what we know over null — documented per the plan's
  ///   partial-stream edge case T-q8x-03).
  static Usage? _buildUsage(
    int? startInputTokens,
    anthropic.MessageDeltaUsage? deltaUsage,
  ) {
    if (startInputTokens == null && deltaUsage == null) {
      return null;
    }
    final promptTokens = startInputTokens ?? 0;
    final completionTokens = deltaUsage?.outputTokens ?? 0;
    return Usage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: promptTokens + completionTokens,
    );
  }

  /// Classifies an Anthropic SDK exception into the appropriate [AIException].
  AIException _classifyException(Object error) {
    if (error is AIException) return error;

    final diagnostic = _safeDiagnostic(error);

    // Anthropic typed exceptions
    if (error is anthropic.AuthenticationException) {
      return AIAuthException(diagnostic);
    }
    if (error is anthropic.RateLimitException) {
      return AIRateLimitException(diagnostic);
    }
    if (error is anthropic.TimeoutException) {
      return AINetworkException(diagnostic);
    }
    if (error is anthropic.ApiException) {
      return switch (error.statusCode) {
        401 || 403 => AIAuthException(diagnostic),
        429 => AIRateLimitException(diagnostic),
        >= 500 => AINetworkException(diagnostic),
        _ => AIStreamException(diagnostic),
      };
    }

    // Generic errors
    return AIStreamException(diagnostic);
  }

  /// Sanitizes error messages to remove sensitive data.
  static String _safeDiagnostic(Object error) {
    final message = error.toString();
    final sanitized = message
        .replaceAll(
          RegExp(
            r'x-api-key[:\s]*[^\s,}]+',
            caseSensitive: false,
          ),
          'API key [REDACTED]',
        )
        .replaceAll(
          RegExp(r'bearer\s+[^\s,}]+', caseSensitive: false),
          'Auth token [REDACTED]',
        )
        .replaceAll(
          RegExp(r'(api[_-]?key\s*[:=]\s*)[^\s,}]+', caseSensitive: false),
          r'$1[REDACTED]',
        );
    return '${error.runtimeType}: $sanitized';
  }

  /// Whether the adapter has an active client.
  bool get isActive => _client != null && !_disposed;

  /// Disposes the current client and releases resources.
  void dispose() {
    _client?.close();
    _client = null;
    _cachedApiKey = null;
    _cachedBaseUrl = null;
    _disposed = true;
  }

  /// Gets or creates a cached [anthic.AnthropicClient].
  anthropic.AnthropicClient _getOrCreateClient(String apiKey, String baseUrl) {
    if (_disposed) {
      _disposed = false;
    }

    if (_client != null &&
        _cachedApiKey == apiKey &&
        _cachedBaseUrl == baseUrl) {
      return _client!;
    }

    // Provider changed -- dispose old client
    _client?.close();

    // Normalize baseUrl: strip trailing slash and /v1 suffix
    String normalizedUrl = baseUrl;
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }
    // Anthropic client handles /v1 path internally
    if (normalizedUrl.endsWith('/v1')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 3);
    }

    final client = anthropic.AnthropicClient(
      config: anthropic.AnthropicConfig(
        authProvider: anthropic.ApiKeyProvider(apiKey),
        baseUrl: normalizedUrl,
        timeout: const Duration(minutes: 5),
      ),
    );

    _client = client;
    _cachedApiKey = apiKey;
    _cachedBaseUrl = baseUrl;

    return client;
  }
}
