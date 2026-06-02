import 'package:museflow/features/ai/domain/ai_provider.dart';

/// Preset AI provider templates.
///
/// Per D-02: Pre-configured providers for OpenAI, DeepSeek, and Ollama
/// with correct baseUrl and model. Users click a preset card to pre-fill
/// the configuration form.
class PresetProviders {
  PresetProviders._();

  /// Returns the list of preset AI provider templates.
  ///
  /// Each preset has a stable ID (preset-openai, preset-deepseek, preset-ollama)
  /// for reliable reference. Ollama uses http://localhost and does not require
  /// an API key.
  static List<AIProvider> get all {
    final now = DateTime.now();
    return [
      AIProvider(
        id: 'preset-openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        createdAt: now,
      ),
      AIProvider(
        id: 'preset-deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        type: AiProviderType.deepseek,
        model: 'deepseek-chat',
        createdAt: now,
      ),
      AIProvider(
        id: 'preset-ollama',
        name: 'Ollama',
        baseUrl: 'http://localhost:11434/v1',
        type: AiProviderType.ollama,
        model: 'llama3',
        createdAt: now,
      ),
    ];
  }

  /// Returns the preset provider by ID, or null if not found.
  static AIProvider? getById(String id) {
    for (final provider in all) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  /// Whether the given provider type requires an API key.
  /// Ollama runs locally and does not require authentication.
  static bool requiresApiKey(AiProviderType type) {
    return type != AiProviderType.ollama;
  }
}
