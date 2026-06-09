import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/provider_service.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/infrastructure/preset_providers.dart';

/// State for the provider management page.
class ProviderManagementState {
  final List<AIProvider> providers;
  final AIProvider? selectedProvider;
  final AIProvider? activeProvider;
  final bool isLoading;
  final String? error;
  final String? connectionTestResult;
  final bool isTestingConnection;

  /// Per D-07: Available models fetched from the provider's /v1/models endpoint.
  final List<String> availableModels;

  /// Whether model list is currently being fetched.
  final bool isFetchingModels;

  const ProviderManagementState({
    this.providers = const [],
    this.selectedProvider,
    this.activeProvider,
    this.isLoading = true,
    this.error,
    this.connectionTestResult,
    this.isTestingConnection = false,
    this.availableModels = const [],
    this.isFetchingModels = false,
  });

  ProviderManagementState copyWith({
    List<AIProvider>? providers,
    AIProvider? selectedProvider,
    bool clearSelected = false,
    AIProvider? activeProvider,
    bool isLoading = false,
    String? error,
    String? connectionTestResult,
    bool clearConnectionResult = false,
    bool isTestingConnection = false,
    List<String>? availableModels,
    bool clearAvailableModels = false,
    bool isFetchingModels = false,
  }) {
    return ProviderManagementState(
      providers: providers ?? this.providers,
      selectedProvider: clearSelected
          ? null
          : (selectedProvider ?? this.selectedProvider),
      activeProvider: activeProvider ?? this.activeProvider,
      isLoading: isLoading,
      error: error,
      connectionTestResult: clearConnectionResult
          ? null
          : (connectionTestResult ?? this.connectionTestResult),
      isTestingConnection: isTestingConnection,
      availableModels: clearAvailableModels
          ? const []
          : (availableModels ?? this.availableModels),
      isFetchingModels: isFetchingModels,
    );
  }
}

/// Notifier managing provider management page state.
class ProviderManagementNotifier extends Notifier<ProviderManagementState> {
  @override
  ProviderManagementState build() {
    final serviceAsync = ref.watch(providerServiceProvider);
    return serviceAsync.when(
      loading: () => const ProviderManagementState(),
      error: (err, _) =>
          ProviderManagementState(error: '加载失败: $err', isLoading: false),
      data: (_) {
        Future.microtask(() => _loadProviders());
        return const ProviderManagementState();
      },
    );
  }

  ProviderService? _getService() {
    final serviceAsync = ref.read(providerServiceProvider);
    return serviceAsync.asData?.value;
  }

  void _loadProviders() {
    final service = _getService();
    if (service == null) return;
    final providers = service.getAllProviders();
    final active = service.getActiveProvider();
    state = state.copyWith(
      providers: providers,
      activeProvider: active,
      isLoading: false,
      error: null,
    );
  }

  void _reload() {
    final service = _getService();
    if (service == null) return;
    final providers = service.getAllProviders();
    final active = service.getActiveProvider();
    state = state.copyWith(
      providers: providers,
      activeProvider: active,
      isLoading: false,
      error: null,
    );
  }

  /// Selects a provider for editing in the right panel.
  void selectProvider(AIProvider provider) {
    state = state.copyWith(
      selectedProvider: provider,
      clearConnectionResult: true,
    );
  }

  /// Clears the selection (deselects).
  void clearSelection() {
    state = state.copyWith(clearSelected: true, clearConnectionResult: true);
  }

  /// Creates a new provider from form fields.
  Future<void> createProvider({
    required String name,
    required String baseUrl,
    required AiProviderType type,
    required String model,
    required String apiKey,
    double? temperature,
    double? topP,
    int? maxTokens,
  }) async {
    final service = _getService();
    if (service == null) {
      state = state.copyWith(error: '服务未就绪');
      return;
    }
    try {
      final provider = await service.createProvider(
        name: name,
        baseUrl: baseUrl,
        type: type,
        model: model,
        apiKey: apiKey,
        temperature: temperature,
        topP: topP,
        maxTokens: maxTokens,
      );
      _reload();
      state = state.copyWith(selectedProvider: provider);
    } catch (e) {
      state = state.copyWith(error: '创建失败: $e');
    }
  }

  /// Updates an existing provider.
  Future<void> updateProvider(AIProvider provider) async {
    final service = _getService();
    if (service == null) {
      state = state.copyWith(error: '服务未就绪');
      return;
    }
    try {
      await service.updateProvider(provider);
      _reload();
      state = state.copyWith(selectedProvider: provider);
    } catch (e) {
      state = state.copyWith(error: '更新失败: $e');
    }
  }

  /// Deletes a provider by ID.
  Future<void> deleteProvider(String id) async {
    final service = _getService();
    if (service == null) {
      state = state.copyWith(error: '服务未就绪');
      return;
    }
    try {
      await service.deleteProvider(id);
      state = state.copyWith(clearSelected: true, clearConnectionResult: true);
      _reload();
    } catch (e) {
      state = state.copyWith(error: '删除失败: $e');
    }
  }

  /// Sets the active provider.
  Future<void> setActiveProvider(String id) async {
    final service = _getService();
    if (service == null) {
      state = state.copyWith(error: '服务未就绪');
      return;
    }
    try {
      await service.setActiveProvider(id);
      _reload();
    } catch (e) {
      state = state.copyWith(error: '设置活跃模型失败: $e');
    }
  }

  /// Tests the connection with the given API key, base URL, and model.
  Future<void> testConnection({
    required String apiKey,
    required String baseUrl,
    String model = 'gpt-4o-mini',
  }) async {
    final service = _getService();
    if (service == null) {
      state = state.copyWith(connectionTestResult: '服务未就绪');
      return;
    }
    state = state.copyWith(
      isTestingConnection: true,
      clearConnectionResult: true,
    );
    try {
      await service.testConnection(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
      );
      state = state.copyWith(
        connectionTestResult: 'success',
        isTestingConnection: false,
      );
    } on AIAuthException {
      state = state.copyWith(
        connectionTestResult: 'API Key 无效',
        isTestingConnection: false,
      );
    } on AIRateLimitException {
      state = state.copyWith(
        connectionTestResult: '请求频率超限，但连接正常',
        isTestingConnection: false,
      );
    } on AINetworkException {
      state = state.copyWith(
        connectionTestResult: '网络连接失败',
        isTestingConnection: false,
      );
    } catch (e) {
      state = state.copyWith(
        connectionTestResult: '测试失败: $e',
        isTestingConnection: false,
      );
    }
  }

  /// Starts creating from a preset template.
  void startFromPreset(AIProvider preset) {
    state = state.copyWith(
      selectedProvider: preset,
      clearConnectionResult: true,
    );
  }

  /// Fetches available models from the provider's /v1/models endpoint.
  ///
  /// Per D-08: On any error, silently clears the available models list.
  /// The user can always type a model ID manually.
  Future<void> fetchModels({
    required String apiKey,
    required String baseUrl,
  }) async {
    state = state.copyWith(isFetchingModels: true, clearAvailableModels: true);
    try {
      final adapter = OpenAIAdapter();
      final models = await adapter.fetchModelList(
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
      adapter.dispose();
      state = state.copyWith(availableModels: models, isFetchingModels: false);
    } catch (_) {
      // Per D-08: silent fallback
      state = state.copyWith(
        clearAvailableModels: true,
        isFetchingModels: false,
      );
    }
  }

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for the provider management page state.
final providerManagementProvider =
    NotifierProvider<ProviderManagementNotifier, ProviderManagementState>(
      ProviderManagementNotifier.new,
    );

/// Computed provider returning preset provider templates.
final presetProvidersProvider = Provider<List<AIProvider>>((ref) {
  return PresetProviders.all;
});
