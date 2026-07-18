import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:flutter/foundation.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:uuid/uuid.dart';

/// Application-layer service for AI provider management.
///
/// Orchestrates CRUD operations, active provider selection,
/// and connection validation between the presentation layer
/// and the ProviderRepository + SecureStorage.
class ProviderService {
  final ProviderRepository _repository;
  final SecureStorageService _secureStorage;
  final _uuid = const Uuid();

  ProviderService(this._repository, this._secureStorage);

  /// Creates a new provider and saves its API key to secure storage.
  ///
  /// Returns the created provider with auto-generated ID and timestamp.
  /// Per D-03: [temperature], [topP], [maxTokens] are nullable model parameters.
  Future<AIProvider> createProvider({
    required String name,
    required String baseUrl,
    required AiProviderType type,
    required String model,
    required String apiKey,
    double? temperature,
    double? topP,
    int? maxTokens,
  }) async {
    final now = DateTime.now();
    final provider = AIProvider(
      id: _uuid.v4(),
      name: name,
      baseUrl: baseUrl,
      type: type,
      model: model,
      isActive: false,
      createdAt: now,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
    );
    await _secureStorage.saveApiKey(provider.id, apiKey);
    try {
      await _repository.save(provider);
    } catch (error, stackTrace) {
      try {
        await _secureStorage.deleteApiKey(provider.id);
      } catch (_) {
        // Preserve the repository failure; cleanup is best-effort here.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    return provider;
  }

  /// Updates an existing provider's configuration.
  Future<AIProvider> updateProvider(AIProvider provider) async {
    await _repository.save(provider);
    return provider;
  }

  /// Deletes a provider and its associated API key.
  Future<void> deleteProvider(String id) async {
    await _repository.delete(id);
  }

  /// Sets the given provider as active and deactivates all others.
  ///
  /// Only one provider can be active at a time.
  Future<void> setActiveProvider(String id) async {
    final providers = _repository.getAll();
    for (final provider in providers) {
      if (provider.id == id) {
        await _repository.save(provider.copyWith(isActive: true));
      } else if (provider.isActive) {
        await _repository.save(provider.copyWith(isActive: false));
      }
    }
  }

  /// Returns all saved providers.
  List<AIProvider> getAllProviders() {
    return _repository.getAll();
  }

  /// Returns the currently active provider, or null if none is active.
  AIProvider? getActiveProvider() {
    final providers = _repository.getAll();
    for (final provider in providers) {
      if (provider.isActive) return provider;
    }
    return null;
  }

  /// Returns the API key for the given provider from secure storage.
  Future<String?> getApiKey(String providerId) async {
    return _secureStorage.getApiKey(providerId);
  }

  /// Updates the API key for an existing provider in secure storage.
  Future<void> updateApiKey(String providerId, String apiKey) async {
    if (_repository.getById(providerId) == null) {
      throw StateError('provider not found: $providerId');
    }
    await _secureStorage.saveApiKey(providerId, apiKey);
  }

  /// Tests the connection to an AI provider by sending a minimal request.
  ///
  /// Routes to [ClaudeAdapter]-style test for Claude providers, or
  /// [OpenAI]-style test for all other OpenAI-compatible providers.
  ///
  /// [timeout] bounds the probe (default 30s) so a dead/unresponsive baseUrl
  /// fails fast instead of hanging on the client's default request timeout.
  /// Exposed as a parameter so tests can inject a short timeout deterministically.
  ///
  /// Throws [AIAuthException] on authentication failure (401/403).
  /// Throws [AIRateLimitException] on rate limiting (429).
  /// Throws [AINetworkException] on network/connectivity errors.
  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    required AiProviderType type,
    String model = 'gpt-4o-mini',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _validateWebBaseUrl(baseUrl);
    if (type == AiProviderType.claude) {
      await _testClaudeConnection(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        timeout: timeout,
      );
    } else {
      await _testOpenAIConnection(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        timeout: timeout,
      );
    }
  }

  void _validateWebBaseUrl(String baseUrl) {
    if (!kIsWeb) return;
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const AINetworkException('Web 版仅支持 HTTPS AI 服务地址');
    }
  }

  /// Tests connection using the Anthropic Messages API.
  Future<void> _testClaudeConnection({
    required String apiKey,
    required String baseUrl,
    required String model,
    required Duration timeout,
  }) async {
    anthropic.AnthropicClient? client;
    try {
      String normalizedUrl = baseUrl;
      if (normalizedUrl.endsWith('/')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
      }
      if (normalizedUrl.endsWith('/v1')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 3);
      }

      client = anthropic.AnthropicClient(
        config: anthropic.AnthropicConfig(
          authProvider: anthropic.ApiKeyProvider(apiKey),
          baseUrl: normalizedUrl,
          timeout: timeout,
        ),
      );

      await client.messages.create(
        anthropic.MessageCreateRequest(
          model: model,
          maxTokens: 5,
          messages: [anthropic.InputMessage.user('Hi')],
        ),
      );
    } on anthropic.AuthenticationException {
      throw const AIAuthException();
    } on anthropic.RateLimitException {
      throw const AIRateLimitException();
    } on anthropic.TimeoutException {
      throw const AINetworkException();
    } on anthropic.ApiException catch (e) {
      final statusCode = e.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw const AIAuthException();
      }
      if (statusCode == 429) {
        throw const AIRateLimitException();
      }
      throw const AINetworkException();
    } catch (_) {
      throw const AINetworkException();
    } finally {
      client?.close();
    }
  }

  /// Tests connection using an OpenAI-compatible API client.
  Future<void> _testOpenAIConnection({
    required String apiKey,
    required String baseUrl,
    required String model,
    required Duration timeout,
  }) async {
    OpenAIClient? client;
    try {
      // Build the client via OpenAIConfig (not the withApiKey factory) so the
      // probe is bounded by [timeout] instead of OpenAIConfig's default
      // Duration(minutes: 10). maxRetries: 0 because a connection test is a
      // single quick probe — it should not back off and retry 4 times.
      client = OpenAIClient(
        config: OpenAIConfig(
          authProvider: ApiKeyProvider(apiKey),
          baseUrl: baseUrl,
          timeout: timeout,
          retryPolicy: const RetryPolicy(maxRetries: 0),
        ),
      );

      await client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: model,
          messages: [ChatMessage.user('Hi')],
          maxTokens: 5,
        ),
      );
    } on AuthenticationException {
      throw const AIAuthException();
    } on RateLimitException {
      throw const AIRateLimitException();
    } on PermissionDeniedException {
      throw const AIAuthException();
    } on ConnectionException {
      throw const AINetworkException();
    } on RequestTimeoutException {
      throw const AINetworkException();
    } on ApiException catch (e) {
      // Classify by status code for more precise error mapping
      final statusCode = e.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw const AIAuthException();
      }
      if (statusCode == 429) {
        throw const AIRateLimitException();
      }
      throw const AINetworkException();
    } on OpenAIException {
      throw const AINetworkException();
    } catch (_) {
      throw const AINetworkException();
    } finally {
      client?.close();
    }
  }
}
