import '../../config/app_constants.dart';
import '../../utils/logger.dart';
import '../../models/ai_config.dart';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';
import 'ai_service.dart';
import 'ai_config_manager.dart';

/// AI服务使用示例
class AIUsageExample {
  /// 示例1: 基础使用
  static Future<void> basicExample() async {
    // 1. 初始化AI服务
    final aiService = await AIService.initialize();

    // 2. 创建配置
    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'your-api-key-here',
      model: 'gpt-4o',
    );

    // 3. 添加配置（会自动加密API Key）
    await aiService.addConfig(config);

    // 4. 设置为活跃配置
    await aiService.setActiveConfig(config.id);

    // 5. 发送消息
    final messages = [
      AIMessage.user(id: '1', content: 'Hello, how are you?'),
    ];

    try {
      final response = await aiService.sendMessage(messages);
      Logger.debug('Response: ${response.content}');
      Logger.debug('Tokens used: ${response.totalTokens}');
    } catch (e) {
      Logger.debug('Error: $e');
    }
  }

  /// 示例2: 多供应商切换
  static Future<void> multiProviderExample() async {
    final aiService = await AIService.initialize();

    // 创建多个供应商的配置
    final openaiConfig = AIConfigManager.createOpenAIConfig(
      apiKey: 'openai-key',
    );

    final claudeConfig = AIConfigManager.createAnthropicConfig(
      apiKey: 'anthropic-key',
    );

    final deepseekConfig = AIConfigManager.createDeepSeekConfig(
      apiKey: 'deepseek-key',
    );

    // 添加所有配置
    await aiService.addConfig(openaiConfig);
    await aiService.addConfig(claudeConfig);
    await aiService.addConfig(deepseekConfig);

    // 使用OpenAI
    await aiService.setActiveConfig(openaiConfig.id);
    final openaiResponse = await aiService.sendMessage([
      AIMessage.user(id: '1', content: 'What is Flutter?'),
    ]);
    Logger.debug('OpenAI: ${openaiResponse.content}');

    // 切换到Claude
    await aiService.setActiveConfig(claudeConfig.id);
    final claudeResponse = await aiService.sendMessage([
      AIMessage.user(id: '1', content: 'What is Flutter?'),
    ]);
    Logger.debug('Claude: ${claudeResponse.content}');
  }

  /// 示例3: 流式响应
  static Future<void> streamingExample() async {
    final aiService = await AIService.initialize();

    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'your-api-key',
    );

    await aiService.addConfig(config);
    await aiService.setActiveConfig(config.id);

    final messages = [
      AIMessage.user(id: '1', content: 'Tell me a story about AI'),
    ];

    Logger.debug('Streaming response:');
    await for (final chunk in aiService.sendMessageStream(messages)) {
      if (chunk.isComplete) {
        Logger.debug('\n[Complete]');
      } else {
        Logger.debug(chunk.content, end: '');
      }
    }
  }

  /// 示例4: 对话历史
  static Future<void> conversationExample() async {
    final aiService = await AIService.initialize();

    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'your-api-key',
    );

    await aiService.addConfig(config);
    await aiService.setActiveConfig(config.id);

    // 构建对话历史
    final conversation = <AIMessage>[
      AIMessage.system(
        id: 'system',
        content: 'You are a helpful assistant.',
      ),
    ];

    // 第一轮对话
    conversation.add(AIMessage.user(id: '1', content: 'What is 2+2?'));
    final response1 = await aiService.sendMessage(conversation);
    conversation.add(AIMessage.assistant(
      id: response1.id,
      content: response1.content,
    ));

    Logger.debug('Q: What is 2+2?');
    Logger.debug('A: ${response1.content}');

    // 第二轮对话（基于上下文）
    conversation.add(AIMessage.user(id: '2', content: 'And what is 3+3?'));
    final response2 = await aiService.sendMessage(conversation);
    conversation.add(AIMessage.assistant(
      id: response2.id,
      content: response2.content,
    ));

    Logger.debug('Q: And what is 3+3?');
    Logger.debug('A: ${response2.content}');
  }

  /// 示例5: 使用Ollama（本地）
  static Future<void> ollamaExample() async {
    final aiService = await AIService.initialize();

    // Ollama配置（不需要API Key）
    final config = AIConfigManager.createOllamaConfig(
      baseUrl: 'http://localhost:11434',
      model: 'llama3',
    );

    await aiService.addConfig(config);
    await aiService.setActiveConfig(config.id);

    final messages = [
      AIMessage.user(id: '1', content: 'What is Flutter?'),
    ];

    try {
      final response = await aiService.sendMessage(messages);
      Logger.debug('Ollama Response: ${response.content}');
    } catch (e) {
      Logger.debug('Error: Make sure Ollama is running locally');
    }
  }

  /// 示例6: 配置管理
  static Future<void> configManagementExample() async {
    final aiService = await AIService.initialize();

    // 创建配置
    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'your-api-key',
    );

    // 验证配置
    final validation = AIConfigManager.validate(config);
    if (validation != null) {
      Logger.debug('Invalid config: $validation');
      return;
    }

    // 添加配置
    await aiService.addConfig(config);

    // 获取所有配置
    final configs = await aiService.getConfigs();
    Logger.debug('Total configs: ${configs.length}');

    // 获取活跃配置
    await aiService.setActiveConfig(config.id);
    final activeConfig = await aiService.getActiveConfig();
    Logger.debug('Active config: ${AIConfigManager.getDescription(activeConfig!)}');

    // 删除配置
    await aiService.deleteConfig(config.id);
  }

  /// 示例7: 错误处理
  static Future<void> errorHandlingExample() async {
    final aiService = await AIService.initialize();

    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'invalid-key',
    );

    await aiService.addConfig(config);
    await aiService.setActiveConfig(config.id);

    final messages = [
      AIMessage.user(id: '1', content: 'Hello'),
    ];

    try {
      await aiService.sendMessage(messages);
    } catch (e) {
      Logger.debug('Error type: ${e.runtimeType}');
      Logger.debug('Error message: $e');

      // 根据错误类型处理
      if (e is ApiKeyException) {
        Logger.debug('Please check your API key');
      } else if (e is RateLimitException) {
        Logger.debug('Rate limit exceeded, please wait');
      } else if (e is NetworkException) {
        Logger.debug('Network connection failed');
      }
    }
  }

  /// 示例8: Token估算
  static Future<void> tokenEstimationExample() async {
    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'your-api-key',
    );

    final messages = [
      AIMessage.system(id: '1', content: 'You are a helpful assistant'),
      AIMessage.user(id: '2', content: 'What is Flutter?' * 10),
    ];

    final estimatedTokens = AIConfigManager.estimateTokens(messages, config);
    Logger.debug('Estimated tokens: $estimatedTokens');

    if (estimatedTokens > config.maxTokens) {
      Logger.debug('Warning: Message may exceed token limit');
    }
  }

  /// 示例9: 使用预设配置
  static Future<void> presetConfigExample() async {
    // 获取创意写作预设
    final creativeConfig = AIConfigPresets.getCreativeWriting(
      AIProvider.openai,
    );

    // 获取代码生成预设
    final codeConfig = AIConfigPresets.getCodeGeneration(
      AIProvider.anthropic,
    );

    Logger.debug('Creative config: ${AIConfigManager.getDescription(creativeConfig)}');
    Logger.debug('Code config: ${AIConfigManager.getDescription(codeConfig)}');
  }

  /// 示例10: 批量处理
  static Future<void> batchProcessingExample() async {
    final aiService = await AIService.initialize();

    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'your-api-key',
    );

    await aiService.addConfig(config);
    await aiService.setActiveConfig(config.id);

    final questions = [
      'What is Flutter?',
      'What is Dart?',
      'What is Widget?',
    ];

    final responses = <String>[];

    for (final question in questions) {
      final messages = [
        AIMessage.user(id: question.hashCode.toString(), content: question),
      ];

      try {
        final response = await aiService.sendMessage(messages);
        responses.add(response.content);
        Logger.debug('Q: $question');
        Logger.debug('A: ${response.content.substring(0, 100)}...\n');
      } catch (e) {
        Logger.debug('Error processing question: $question');
      }
    }

    Logger.debug('Total responses: ${responses.length}');
  }

  /// 示例11: 配置导入导出
  static Future<void> configImportExportExample() async {
    // 创建多个配置
    final configs = [
      AIConfigManager.createOpenAIConfig(apiKey: 'key1'),
      AIConfigManager.createAnthropicConfig(apiKey: 'key2'),
    ];

    // 导出为JSON
    final jsonString = AIConfigManager.exportToJsonList(configs);
    Logger.debug('Exported configs: $jsonString');

    // 导入配置
    final importedConfigs = AIConfigManager.importFromJsonList(jsonString);
    Logger.debug('Imported ${importedConfigs.length} configs');
  }

  /// 示例12: 高级错误处理和重试
  static Future<void> advancedRetryExample() async {
    final aiService = await AIService.initialize();

    // 创建带重试的配置
    final config = AIConfigManager.createOpenAIConfig(
      apiKey: 'your-api-key',
      retryCount: 5, // 增加重试次数
      timeoutSeconds: 60, // 增加超时时间
    );

    await aiService.addConfig(config);
    await aiService.setActiveConfig(config.id);

    final messages = [
      AIMessage.user(id: '1', content: 'Hello'),
    ];

    try {
      // 服务会自动重试
      final response = await aiService.sendMessage(messages);
      Logger.debug('Response: ${response.content}');
    } catch (e) {
      Logger.debug('Failed after retries: $e');
    }
  }
}
