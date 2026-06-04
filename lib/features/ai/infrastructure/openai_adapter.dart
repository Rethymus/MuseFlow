/// OpenAI-compatible API adapter with streaming and error recovery.
///
/// Wraps the `openai_dart` package's [OpenAIClient] to provide:
/// - Streaming text deltas via [createStream]
/// - Error classification into typed [AIException] hierarchy
/// - Client caching to prevent memory leaks
/// - HTTPS enforcement per T-02-08 (with localhost exception for Ollama)
///
/// Per AI-01: Supports any OpenAI-compatible API via configurable baseUrl
/// (OpenAI, DeepSeek, Ollama, etc.).
library;

import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:openai_dart/openai_dart.dart';

/// Adapter for OpenAI-compatible API streaming.
///
/// Creates and caches [OpenAIClient] instances. When the provider config
/// (apiKey + baseUrl) changes, the old client is disposed and a new one
/// is created. This prevents TCP connection leaks per Pitfall 4 in RESEARCH.md.
class OpenAIAdapter {
  OpenAIClient? _client;
  String? _cachedApiKey;
  String? _cachedBaseUrl;
  bool _disposed = false;

  /// Creates a stream of text deltas from an OpenAI-compatible API.
  ///
  /// Parameters:
  /// - [apiKey]: API key for authentication (use 'ollama' for local Ollama)
  /// - [baseUrl]: API base URL (must be HTTPS, except localhost for Ollama)
  /// - [model]: Model identifier (e.g., 'gpt-4o-mini', 'deepseek-chat')
  /// - [messages]: Pre-assembled chat messages from PromptPipeline
  /// - [temperature]: Sampling temperature (0.0-2.0). Null = model default.
  /// - [topP]: Nucleus sampling threshold (0.0-1.0). Null = model default.
  /// - [maxTokens]: Maximum tokens in response (1-128000). Null = model default.
  ///
  /// Returns a [Stream<String>] of text delta tokens.
  /// On error, the stream emits an [AIException] subclass.
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
  }) {
    // Validate baseUrl per T-02-08
    _validateBaseUrl(baseUrl);

    // Get or create cached client
    final client = _getOrCreateClient(apiKey, baseUrl);

    // Per D-04: pass nullable values directly -- openai_dart handles
    // null-by-omission in its request serialization.
    final request = ChatCompletionCreateRequest(
      model: model,
      messages: messages,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
    );

    // Map the raw stream to text deltas with error classification
    return client.chat.completions.createStream(request).map((event) {
      final delta = event.textDelta;
      return delta ?? '';
    }).where((delta) => delta.isNotEmpty).handleError((error) {
      throw classifyException(error);
    });
  }

  /// Classifies an openai_dart exception into the appropriate [AIException].
  ///
  /// This is a static method so it can be used independently for testing.
  static AIException classifyException(Object error) {
    if (error is AIException) return error;

    // openai_dart typed exceptions
    if (error is AuthenticationException) {
      return const AIAuthException();
    }
    if (error is PermissionDeniedException) {
      return const AIAuthException();
    }
    if (error is RateLimitException) {
      return const AIRateLimitException();
    }
    if (error is ConnectionException) {
      return const AINetworkException();
    }
    if (error is RequestTimeoutException) {
      return const AINetworkException();
    }

    // ApiException with specific status codes
    if (error is ApiException) {
      return switch (error.statusCode) {
        401 || 403 => const AIAuthException(),
        429 => const AIRateLimitException(),
        _ => const AIStreamException(),
      };
    }

    // openai_dart StreamException
    if (error is OpenAIException) {
      return const AIStreamException();
    }

    // Unknown errors
    return const AIStreamException();
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

  /// Gets or creates a cached [OpenAIClient].
  ///
  /// Creates a new client if:
  /// - No client exists yet
  /// - The apiKey or baseUrl changed (provider switch)
  ///
  /// Otherwise returns the cached client to reuse the TCP connection.
  OpenAIClient _getOrCreateClient(String apiKey, String baseUrl) {
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

    // Per Pitfall 2: Ollama works because it accepts any API key.
    // The adapter just passes whatever apiKey it receives.
    final client = OpenAIClient.withApiKey(
      apiKey,
      baseUrl: baseUrl,
    );

    _client = client;
    _cachedApiKey = apiKey;
    _cachedBaseUrl = baseUrl;

    return client;
  }

  /// Validates that the baseUrl uses HTTPS, with an exception for localhost.
  ///
  /// Per T-02-08: Enforces HTTPS to prevent API key leakage.
  /// Localhost is allowed for Ollama and local development.
  void _validateBaseUrl(String baseUrl) {
    final isLocalhost = baseUrl.startsWith('http://localhost') ||
        baseUrl.startsWith('http://127.0.0.1') ||
        baseUrl.startsWith('http://0.0.0.0') ||
        baseUrl.startsWith('http://[::1]');

    if (!baseUrl.startsWith('https://') && !isLocalhost) {
      throw const AIStreamException('baseUrl 必须使用 HTTPS 协议');
    }
  }
}
