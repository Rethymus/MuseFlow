import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/preset_providers.dart';

void main() {
  group('PresetProviders', () {
    test('should return exactly 4 preset providers', () {
      expect(PresetProviders.all.length, 4);
    });

    test('OpenAI preset should have correct configuration', () {
      final openai = PresetProviders.all.firstWhere(
        (p) => p.type == AiProviderType.openai,
      );
      expect(openai.id, 'preset-openai');
      expect(openai.name, 'OpenAI');
      expect(openai.baseUrl, 'https://api.openai.com/v1');
      expect(openai.model, 'gpt-4o-mini');
      expect(openai.type, AiProviderType.openai);
    });

    test('DeepSeek preset should have correct configuration', () {
      final deepseek = PresetProviders.all.firstWhere(
        (p) => p.type == AiProviderType.deepseek,
      );
      expect(deepseek.id, 'preset-deepseek');
      expect(deepseek.name, 'DeepSeek');
      expect(deepseek.baseUrl, 'https://api.deepseek.com/v1');
      expect(deepseek.model, 'deepseek-chat');
      expect(deepseek.type, AiProviderType.deepseek);
    });

    test('Ollama preset should have correct configuration', () {
      final ollama = PresetProviders.all.firstWhere(
        (p) => p.type == AiProviderType.ollama,
      );
      expect(ollama.id, 'preset-ollama');
      expect(ollama.name, 'Ollama');
      expect(ollama.baseUrl, 'http://localhost:11434/v1');
      expect(ollama.model, 'llama3');
      expect(ollama.type, AiProviderType.ollama);
    });

    test('getById returns correct preset', () {
      final openai = PresetProviders.getById('preset-openai');
      expect(openai, isNotNull);
      expect(openai!.name, 'OpenAI');
    });

    test('getById returns null for unknown ID', () {
      final result = PresetProviders.getById('nonexistent');
      expect(result, isNull);
    });

    test('requiresApiKey should be true for OpenAI', () {
      expect(PresetProviders.requiresApiKey(AiProviderType.openai), true);
    });

    test('requiresApiKey should be true for DeepSeek', () {
      expect(PresetProviders.requiresApiKey(AiProviderType.deepseek), true);
    });

    test('requiresApiKey should be true for custom', () {
      expect(PresetProviders.requiresApiKey(AiProviderType.custom), true);
    });

    test('requiresApiKey should be false for Ollama', () {
      expect(PresetProviders.requiresApiKey(AiProviderType.ollama), false);
    });

    test('Claude preset should have correct configuration', () {
      final claude = PresetProviders.all.firstWhere(
        (p) => p.type == AiProviderType.claude,
      );
      expect(claude.id, 'preset-claude');
      expect(claude.name, 'Claude');
      expect(claude.baseUrl, 'https://api.anthropic.com/v1/');
      expect(claude.model, 'claude-sonnet-4-20250514');
      expect(claude.type, AiProviderType.claude);
    });

    test('getById returns Claude preset by ID', () {
      final claude = PresetProviders.getById('preset-claude');
      expect(claude, isNotNull);
      expect(claude!.name, 'Claude');
      expect(claude.baseUrl, 'https://api.anthropic.com/v1/');
      expect(claude.model, 'claude-sonnet-4-20250514');
    });

    test('requiresApiKey should be true for Claude', () {
      expect(PresetProviders.requiresApiKey(AiProviderType.claude), true);
    });
  });
}
