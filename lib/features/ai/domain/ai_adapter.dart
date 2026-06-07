/// Abstract interface for AI streaming adapters.
///
/// Defines the contract for AI adapters that provide streaming text generation.
/// Extracted from [OpenAIAdapter] per D-01 to enable dependency substitution
/// in tests (FakeAdapter) and future adapter implementations (Claude, Ollama).
///
/// The interface includes only the core `createStream` method. Provider-specific
/// methods like `fetchModelList`, `dispose`, `isActive`, and `classifyException`
/// remain on concrete adapter classes.
library;

import 'dart:async';

import 'package:openai_dart/openai_dart.dart';

abstract class AIAdapter {
  /// Creates a stream of text deltas from an AI model.
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
