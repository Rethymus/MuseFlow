import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';

void main() {
  group('AiProviderType', () {
    test('should create from string value', () {
      expect(AiProviderType.fromString('openai'), AiProviderType.openai);
      expect(AiProviderType.fromString('deepseek'), AiProviderType.deepseek);
      expect(AiProviderType.fromString('ollama'), AiProviderType.ollama);
      expect(AiProviderType.fromString('custom'), AiProviderType.custom);
    });

    test('should create claude from string value', () {
      expect(AiProviderType.fromString('claude'), AiProviderType.claude);
    });

    test('should fall back to custom for unknown string', () {
      expect(AiProviderType.fromString('unknown'), AiProviderType.custom);
    });

    test('should have correct string values', () {
      expect(AiProviderType.openai.value, 'openai');
      expect(AiProviderType.deepseek.value, 'deepseek');
      expect(AiProviderType.ollama.value, 'ollama');
      expect(AiProviderType.claude.value, 'claude');
      expect(AiProviderType.custom.value, 'custom');
    });
  });

  group('AIProvider', () {
    final now = DateTime(2026, 6, 2, 12, 0, 0);
    final provider = AIProvider(
      id: 'test-id',
      name: 'Test Provider',
      baseUrl: 'https://api.test.com/v1',
      type: AiProviderType.openai,
      model: 'gpt-4o-mini',
      isActive: false,
      createdAt: now,
    );

    test('should have all fields set correctly', () {
      expect(provider.id, 'test-id');
      expect(provider.name, 'Test Provider');
      expect(provider.baseUrl, 'https://api.test.com/v1');
      expect(provider.type, AiProviderType.openai);
      expect(provider.model, 'gpt-4o-mini');
      expect(provider.isActive, false);
      expect(provider.createdAt, now);
    });

    test('should default isActive to false', () {
      final p = AIProvider(
        id: 'x',
        name: 'x',
        baseUrl: 'x',
        type: AiProviderType.custom,
        model: 'x',
        createdAt: now,
      );
      expect(p.isActive, false);
    });

    test('copyWith should replace only specified fields', () {
      final copied = provider.copyWith(
        name: 'Updated',
        isActive: true,
      );
      expect(copied.id, provider.id);
      expect(copied.name, 'Updated');
      expect(copied.baseUrl, provider.baseUrl);
      expect(copied.type, provider.type);
      expect(copied.model, provider.model);
      expect(copied.isActive, true);
      expect(copied.createdAt, provider.createdAt);
    });

    test('copyWith with no args returns equal provider', () {
      final copied = provider.copyWith();
      expect(copied, provider);
    });

    test('fromJson/toJson roundtrip preserves all fields', () {
      final json = provider.toJson();
      final restored = AIProvider.fromJson(json);

      expect(restored.id, provider.id);
      expect(restored.name, provider.name);
      expect(restored.baseUrl, provider.baseUrl);
      expect(restored.type, provider.type);
      expect(restored.model, provider.model);
      expect(restored.isActive, provider.isActive);
      expect(restored.createdAt, provider.createdAt);
    });

    test('fromJson handles missing isActive gracefully', () {
      final json = provider.toJson();
      json.remove('isActive');
      final restored = AIProvider.fromJson(json);
      expect(restored.isActive, false);
    });

    test('equality compares all fields', () {
      final same = AIProvider(
        id: 'test-id',
        name: 'Test Provider',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        isActive: false,
        createdAt: now,
      );
      expect(same, provider);
      expect(same.hashCode, provider.hashCode);
    });

    test('inequality when any field differs', () {
      final different = provider.copyWith(name: 'Other');
      expect(different == provider, false);
    });

    test('toString includes key fields', () {
      final str = provider.toString();
      expect(str, contains('test-id'));
      expect(str, contains('Test Provider'));
    });
  });
}
