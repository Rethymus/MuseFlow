import 'dart:async';

import 'package:openai_dart/openai_dart.dart';

/// Abstract interface for AI streaming adapters.
///
/// Implementations provide streaming text deltas for AI completions. Extracted
/// from [OpenAIAdapter] so tests can substitute deterministic adapters.
abstract class AIAdapter {
  /// Creates a stream of text deltas from an AI API.
  ///
  /// Parameters match OpenAIAdapter.createStream exactly.
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  });
}
