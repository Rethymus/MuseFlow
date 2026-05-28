import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/services/ai/ai.dart';

void main() {
  group('AI Service Tests', () {
    late AIService aiService;

    setUp(() async {
      aiService = await AIService.initialize();
    });

    tearDown(() {
      aiService.dispose();
    });

    test('创建OpenAI配置', () {
      final config = AIConfigManager.createOpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
      );

      expect(config.provider, AIProvider.openai);
      expect(config.model, 'gpt-4o');
      expect(config.apiKey, 'test-key');
    });

    test('创建Anthropic配置', () {
      final config = AIConfigManager.createAnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-5-sonnet-20241022',
      );

      expect(config.provider, AIProvider.anthropic);
      expect(config.model, 'claude-3-5-sonnet-20241022');
    });

    test('创建DeepSeek配置', () {
      final config = AIConfigManager.createDeepSeekConfig(
        apiKey: 'test-key',
        model: 'deepseek-chat',
      );

      expect(config.provider, AIProvider.deepseek);
      expect(config.model, 'deepseek-chat');
    });

    test('创建Ollama配置', () {
      final config = AIConfigManager.createOllamaConfig(
        baseUrl: 'http://localhost:11434',
        model: 'llama3',
      );

      expect(config.provider, AIProvider.ollama);
      expect(config.model, 'llama3');
      expect(config.apiKey, ''); // Ollama不需要API Key
    });

    test('配置验证', () {
      // 有效配置
      final validConfig = AIConfigManager.createOpenAIConfig(
        apiKey: 'valid-key',
      );
      expect(AIConfigManager.validate(validConfig), isNull);

      // 无效配置（空API Key）
      final invalidConfig = AIConfigManager.createOpenAIConfig(
        apiKey: '',
      );
      expect(AIConfigManager.validate(invalidConfig), isNotNull);
    });

    test('消息创建', () {
      final userMessage = AIMessage.user(
        id: '1',
        content: 'Hello',
      );
      expect(userMessage.role, MessageRole.user);
      expect(userMessage.content, 'Hello');

      final assistantMessage = AIMessage.assistant(
        id: '2',
        content: 'Hi there!',
      );
      expect(assistantMessage.role, MessageRole.assistant);

      final systemMessage = AIMessage.system(
        id: '3',
        content: 'You are helpful.',
      );
      expect(systemMessage.role, MessageRole.system);
    });

    test('消息序列化', () {
      final message = AIMessage.user(
        id: '1',
        content: 'Test',
      );

      final json = message.toJson();
      final restored = AIMessage.fromJson(json);

      expect(restored.id, message.id);
      expect(restored.content, message.content);
      expect(restored.role, message.role);
    });

    test('AI响应创建', () {
      final response = AIResponse(
        id: '1',
        content: 'Response content',
        model: 'gpt-4o',
        inputTokens: 10,
        outputTokens: 20,
      );

      expect(response.content, 'Response content');
      expect(response.totalTokens, 30);
      expect(response.calculatedTotalTokens, 30);
    });

    test('Token估算', () {
      final config = AIConfigManager.createOpenAIConfig(
        apiKey: 'test-key',
      );

      final messages = [
        AIMessage.user(id: '1', content: 'Hello' * 100),
      ];

      final tokens = aiService.estimateTokens(messages, config);
      expect(tokens, greaterThan(0));
    });

    test('配置预设', () {
      final fastConfig = AIConfigPresets.getFastResponse(
        AIProvider.openai,
      );
      expect(fastConfig.temperature, lessThan(0.5));

      final creativeConfig = AIConfigPresets.getCreativeWriting(
        AIProvider.anthropic,
      );
      expect(creativeConfig.temperature, greaterThan(0.8));
    });

    test('供应商默认参数', () {
      final openai = AIProvider.openai;
      expect(openai.defaultBaseUrl, 'https://api.openai.com/v1');
      expect(openai.defaultTimeout, 30);

      final anthropic = AIProvider.anthropic;
      expect(anthropic.defaultBaseUrl, 'https://api.anthropic.com/v1');
      expect(anthropic.defaultTimeout, 60);

      final deepseek = AIProvider.deepseek;
      expect(deepseek.defaultBaseUrl, 'https://api.deepseek.com/v1');

      final ollama = AIProvider.ollama;
      expect(ollama.defaultBaseUrl, 'http://localhost:11434/v1');
    });

    test('配置导入导出', () {
      final configs = [
        AIConfigManager.createOpenAIConfig(apiKey: 'key1'),
        AIConfigManager.createAnthropicConfig(apiKey: 'key2'),
      ];

      final jsonString = AIConfigManager.exportToJsonList(configs);
      expect(jsonString, isNotEmpty);

      final imported = AIConfigManager.importFromJsonList(jsonString);
      expect(imported.length, 2);
    });

    test('配置描述生成', () {
      final config = AIConfigManager.createOpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://custom.api.com',
      );

      final description = AIConfigManager.getDescription(config);
      expect(description, contains('OpenAI'));
      expect(description, contains('custom.api.com'));
    });

    test('流式响应块', () {
      final incompleteChunk = AIStreamChunk.incomplete('partial');
      expect(incompleteChunk.isComplete, isFalse);
      expect(incompleteChunk.content, 'partial');

      final completeChunk = AIStreamChunk.complete(
        content: 'complete',
        finishReason: 'stop',
      );
      expect(completeChunk.isComplete, isTrue);
      expect(completeChunk.finishReason, 'stop');
    });

    test('配置克隆', () {
      final config = AIConfigManager.createOpenAIConfig(
        apiKey: 'test-key',
      );

      final cloned = AIConfigManager.clone(config);
      expect(cloned.provider, config.provider);
      expect(cloned.model, config.model);
      expect(cloned.id, isNot(config.id)); // ID应该不同
    });
  });

  group('AI Adapter Tests', () {
    test('OpenAI适配器创建', () {
      final config = AIConfigManager.createOpenAIConfig(
        apiKey: 'test-key',
      );

      final adapter = OpenAIAdapter(config: config);
      expect(adapter.adapterName, 'OpenAIAdapter');
      expect(adapter.config.id, config.id);
    });

    test('Claude适配器创建', () {
      final config = AIConfigManager.createAnthropicConfig(
        apiKey: 'test-key',
      );

      final adapter = ClaudeAdapter(config: config);
      expect(adapter.adapterName, 'ClaudeAdapter');
    });

    test('DeepSeek适配器创建', () {
      final config = AIConfigManager.createDeepSeekConfig(
        apiKey: 'test-key',
      );

      final adapter = DeepSeekAdapter(config: config);
      expect(adapter.adapterName, 'DeepSeekAdapter');
    });

    test('Ollama适配器创建', () {
      final config = AIConfigManager.createOllamaConfig();

      final adapter = OllamaAdapter(config: config);
      expect(adapter.adapterName, 'OllamaAdapter');
    });
  });
}
