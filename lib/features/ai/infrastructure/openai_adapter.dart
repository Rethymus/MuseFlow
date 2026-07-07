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

import 'dart:async';

import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:openai_dart/openai_dart.dart';

/// Adapter for OpenAI-compatible API streaming.
///
/// Creates and caches [OpenAIClient] instances. When the provider config
/// (apiKey + baseUrl) changes, the old client is disposed and a new one
/// is created. This prevents TCP connection leaks per Pitfall 4 in RESEARCH.md.
class OpenAIAdapter implements AIAdapter {
  OpenAIClient? _client;
  String? _cachedApiKey;
  String? _cachedBaseUrl;
  bool _disposed = false;

  /// Optional offline pre-flight. When injected, [createStream] fast-fails with
  /// [AIOfflineException] BEFORE any network call if the probe reports the
  /// device offline — saving the user the bounded-timeout wait and avoiding
  /// futile quota burn on a known-bad state. Null (default) preserves legacy
  /// no-gate behavior (e.g. the connection-test probe, which IS the probe).
  /// Production adapters are wired by their provider via [ConnectivityService].
  final Future<bool> Function()? onlineCheck;

  /// Creates an adapter. Pass [onlineCheck] to enable offline fast-fail.
  OpenAIAdapter({this.onlineCheck});

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
  /// - [onUsage]: Optional callback invoked with usage data after stream completes.
  ///
  /// Returns a [Stream<String>] of text delta tokens.
  /// On error, the stream emits an [AIException] subclass.
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
    // Validate baseUrl per T-02-08
    _validateBaseUrl(baseUrl);

    // Eagerly create+cache the client so the lifecycle invariant (isActive
    // reflects a live client immediately after createStream) holds. The
    // retryStream factory below reuses this cached client on each (re)attempt
    // via _attemptStream's _getOrCreateClient (idempotent for same params).
    // Restored after quick-260617-wma deferred creation into the factory
    // closure, which accidentally made client creation lazy-on-subscription
    // and broke the caching tests' isActive invariant.
    _getOrCreateClient(apiKey, baseUrl);

    // Retry transient EARLY failures (5xx / connection blip / SSE parse /
    // rate-limit) so a single hiccup no longer kills a long serial
    // generation (root-caused via the real BigModel key: one transient
    // AIStreamException aborted a 30-chapter journey at chapter 6).
    // Mid-stream failures (tokens already emitted) are NOT retried —
    // restarting would duplicate the partial output. See quick-260617-wma.
    final inner = retryStream(
      () => _attemptStream(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        messages: messages,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
        onUsage: onUsage,
      ),
    );
    // Offline fast-fail pre-flight runs OUTSIDE retryStream — an offline device
    // must NOT be retried 3× (that just burns time/quota on a known-bad state).
    // Skipped when no probe is injected (legacy path / connection-test probe).
    if (onlineCheck == null) return inner;
    return _guardOnline(inner);
  }

  /// One non-retried attempt: maps the openai_dart stream to text deltas,
  /// classifies errors into the [AIException] hierarchy, and reports usage on
  /// completion. Extracted from [createStream] so [retryStream] can re-invoke
  /// it cleanly on each retry.
  Stream<String> _attemptStream({
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

    // Per D-04: pass nullable values directly -- openai_dart handles
    // null-by-omission in its request serialization.
    final request = ChatCompletionCreateRequest(
      model: model,
      messages: messages,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
    );

    // Create accumulator to capture usage data
    final accumulator = ChatStreamAccumulator();

    // Map the raw stream to text deltas with error classification
    return client.chat.completions
        .createStream(request)
        .map((event) {
          accumulator.add(event);
          final delta = event.textDelta;
          return delta ?? '';
        })
        .where((delta) => delta.isNotEmpty)
        .handleError((error) {
          throw classifyException(error);
        })
        .transform(
          StreamTransformer<String, String>.fromHandlers(
            handleDone: (sink) {
              onUsage?.call(accumulator.usage);
              sink.close();
            },
          ),
        );
  }

  /// Whether [error] is worth retrying. Transient stream/network/rate-limit
  /// errors are retryable; auth errors are not (retrying a bad key wastes
  /// quota and never succeeds). Offline is explicitly excluded — it is a
  /// known-bad state that won't resolve during a backoff window, so retrying
  /// only burns time/quota. The offline gate normally sits OUTSIDE retryStream
  /// (see _guardOnline) so this exclusion is defense-in-depth: it keeps the
  /// no-retry-offline contract correct even if that wiring changes.
  static bool _isRetryable(AIException error) =>
      error is AIRateLimitException ||
      (error is AINetworkException && error is! AIOfflineException) ||
      error is AIStreamException;

  /// Maximum retry attempts after the initial call (so up to 4 total calls).
  static const int defaultMaxRetries = 3;

  /// Retries [factory] on early transient failures with exponential backoff.
  ///
  /// Retry ONLY fires when ALL hold:
  /// - [factory] throws a retryable [AIException] (rate-limit / network /
  ///   stream),
  /// - no tokens were emitted on the current attempt (an EARLY failure such
  ///   as a connection reset before the first byte). Once a single delta has
  ///   been emitted the stream is committed and an error is surfaced to the
  ///   caller — restarting would duplicate the partial output already
  ///   delivered.
  ///
  /// Exposed (static, factory-injected) for deterministic unit testing with a
  /// fake factory — no network, no quota burn. The real OpenAI path is
  /// exercised by the GLM integration smoke test.
  static Stream<String> retryStream(
    Stream<String> Function() factory, {
    int maxRetries = defaultMaxRetries,
    Duration Function(int attempt)? backoff,
  }) async* {
    final delay = backoff ?? _defaultBackoff;
    var attempt = 0;
    while (true) {
      var emitted = false;
      try {
        await for (final delta in factory()) {
          emitted = true;
          yield delta;
        }
        return;
      } on AIException catch (error) {
        if (emitted || !_isRetryable(error) || attempt >= maxRetries) {
          rethrow;
        }
        attempt++;
        await Future<void>.delayed(delay(attempt));
      }
    }
  }

  static Duration _defaultBackoff(int attempt) =>
      Duration(milliseconds: 100 * (1 << attempt));

  /// Wraps [inner] with a one-shot offline pre-flight before the first byte.
  ///
  /// The [AIOfflineException] is thrown BEFORE `yield* inner`, so the caller
  /// receives it directly and never enters [retryStream] — an offline device is
  /// a known-bad state and must not be retried. Called only when [onlineCheck]
  /// is non-null; the eager `_getOrCreateClient` in [createStream] already ran,
  /// so the `isActive` invariant (quick-260618-1g4) is preserved.
  Stream<String> _guardOnline(Stream<String> inner) async* {
    if (await onlineCheck!()) {
      throw const AIOfflineException();
    }
    yield* inner;
  }

  /// Classifies an openai_dart exception into the appropriate [AIException].
  ///
  /// This is a static method so it can be used independently for testing.
  static AIException classifyException(Object error) {
    if (error is AIException) return error;

    final diagnostic = _safeDiagnostic(error);

    // openai_dart typed exceptions
    if (error is AuthenticationException) {
      return AIAuthException(diagnostic);
    }
    if (error is PermissionDeniedException) {
      return AIAuthException(diagnostic);
    }
    if (error is RateLimitException) {
      return AIRateLimitException(diagnostic);
    }
    if (error is ConnectionException) {
      return AINetworkException(diagnostic);
    }
    if (error is RequestTimeoutException) {
      return AINetworkException(diagnostic);
    }

    // ApiException with specific status codes
    if (error is ApiException) {
      return switch (error.statusCode) {
        401 || 403 => AIAuthException(diagnostic),
        429 => AIRateLimitException(diagnostic),
        _ => AIStreamException(diagnostic),
      };
    }

    // openai_dart StreamException
    if (error is OpenAIException) {
      return AIStreamException(diagnostic);
    }

    // Unknown errors
    return AIStreamException(diagnostic);
  }

  static String _safeDiagnostic(Object error) {
    final message = error.toString();
    final sanitized = message
        .replaceAll(
          RegExp(
            r'authorization\s*[:=]\s*bearer\s+[^\s,}]+',
            caseSensitive: false,
          ),
          'Auth header [REDACTED]',
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

  /// Fetches the list of available models from the provider's /v1/models endpoint.
  ///
  /// Per D-08: Returns a list of model ID strings on success. Returns an empty
  /// list on any error (network failure, timeout, invalid response) -- silent
  /// fallback so the user can always type a model ID manually.
  ///
  /// Uses a 5-second timeout per the plan specification.
  Future<List<String>> fetchModelList({
    required String apiKey,
    required String baseUrl,
  }) async {
    if (apiKey.isEmpty) return [];
    OpenAIClient? client;
    try {
      if (onlineCheck != null && await onlineCheck!()) return [];
      _validateBaseUrl(baseUrl);
      client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
      final modelList = await client.models.list().timeout(
        const Duration(seconds: 5),
      );
      return modelList.data.map((m) => m.id).toList();
    } catch (_) {
      // Per D-08: silent fallback on any error
      return [];
    } finally {
      client?.close();
    }
  }

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
    final client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);

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
    final isLocalhost =
        baseUrl.startsWith('http://localhost') ||
        baseUrl.startsWith('http://127.0.0.1') ||
        baseUrl.startsWith('http://0.0.0.0') ||
        baseUrl.startsWith('http://[::1]');

    if (!baseUrl.startsWith('https://') && !isLocalhost) {
      throw const AIStreamException('baseUrl 必须使用 HTTPS 协议');
    }
  }
}
