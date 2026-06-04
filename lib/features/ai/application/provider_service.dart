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
  Future<AIProvider> createProvider({
    required String name,
    required String baseUrl,
    required AiProviderType type,
    required String model,
    required String apiKey,
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
    );
    await _repository.save(provider);
    await _secureStorage.saveApiKey(provider.id, apiKey);
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
    await _secureStorage.saveApiKey(providerId, apiKey);
  }

  /// Tests the connection to an AI provider by sending a minimal request.
  ///
  /// Creates a temporary OpenAI-compatible client and sends a minimal chat
  /// completion request to validate the API key and base URL.
  ///
  /// Throws [AIAuthException] on authentication failure (401/403).
  /// Throws [AIRateLimitException] on rate limiting (429).
  /// Throws [AINetworkException] on network/connectivity errors.
  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    String model = 'gpt-4o-mini',
  }) async {
    try {
      final client = OpenAIClient.withApiKey(
        apiKey,
        baseUrl: baseUrl,
      );

      await client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: model,
          messages: [ChatMessage.user('Hi')],
          maxTokens: 5,
        ),
      );
      client.close();
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
    }
  }
}
