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

  group('AIProvider nullable parameters', () {
    final now = DateTime(2026, 6, 2, 12, 0, 0);

    test('should accept nullable temperature, topP, maxTokens with default null', () {
      final p = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        createdAt: now,
      );
      expect(p.temperature, isNull);
      expect(p.topP, isNull);
      expect(p.maxTokens, isNull);
    });

    test('should accept non-null temperature, topP, maxTokens values', () {
      final p = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        temperature: 1.5,
        topP: 0.9,
        maxTokens: 4096,
        createdAt: now,
      );
      expect(p.temperature, 1.5);
      expect(p.topP, 0.9);
      expect(p.maxTokens, 4096);
    });

    test('copyWith preserves existing nullable values when no override given', () {
      final p = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        temperature: 1.2,
        topP: 0.8,
        maxTokens: 2048,
        createdAt: now,
      );
      final copied = p.copyWith(name: 'Updated');
      expect(copied.temperature, 1.2);
      expect(copied.topP, 0.8);
      expect(copied.maxTokens, 2048);
    });

    test('copyWith can set temperature/topP/maxTokens to specific non-null values', () {
      final p = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        createdAt: now,
      );
      final copied = p.copyWith(
        temperature: 0.7,
        topP: 0.5,
        maxTokens: 1024,
      );
      expect(copied.temperature, 0.7);
      expect(copied.topP, 0.5);
      expect(copied.maxTokens, 1024);
    });

    test('copyWith can set temperature/topP/maxTokens back to null', () {
      final p = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        temperature: 1.2,
        topP: 0.8,
        maxTokens: 2048,
        createdAt: now,
      );
      final copied = p.copyWith(
        temperature: null,
        topP: null,
        maxTokens: null,
      );
      expect(copied.temperature, isNull);
      expect(copied.topP, isNull);
      expect(copied.maxTokens, isNull);
    });

    test('fromJson/toJson roundtrip includes temperature, topP, maxTokens', () {
      final p = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        temperature: 1.0,
        topP: 0.7,
        maxTokens: 8192,
        createdAt: now,
      );
      final json = p.toJson();
      final restored = AIProvider.fromJson(json);
      expect(restored.temperature, 1.0);
      expect(restored.topP, 0.7);
      expect(restored.maxTokens, 8192);
    });

    test('fromJson handles missing temperature/topP/maxTokens gracefully', () {
      final json = <String, dynamic>{
        'id': 'test-id',
        'name': 'Test',
        'baseUrl': 'https://api.test.com/v1',
        'type': 'openai',
        'model': 'gpt-4o-mini',
        'isActive': false,
        'createdAt': now.toIso8601String(),
      };
      final restored = AIProvider.fromJson(json);
      expect(restored.temperature, isNull);
      expect(restored.topP, isNull);
      expect(restored.maxTokens, isNull);
    });

    test('operator == and hashCode include temperature, topP, maxTokens', () {
      final a = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        temperature: 1.0,
        topP: 0.5,
        maxTokens: 4096,
        createdAt: now,
      );
      final b = AIProvider(
        id: 'test-id',
        name: 'Test',
        baseUrl: 'https://api.test.com/v1',
        type: AiProviderType.openai,
        model: 'gpt-4o-mini',
        temperature: 1.0,
        topP: 0.5,
        maxTokens: 4096,
        createdAt: now,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      // Different temperature should not be equal
      final c = b.copyWith(temperature: 0.5);
      expect(a == c, false);
    });
  });
}
