import '../../config/app_constants.dart';
import '../../utils/logger.dart';
/// AI服务集成示例
/// 展示如何在应用中使用AI服务

import 'package:flutter/material.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/adapters/openai_adapter.dart';
import '../services/ai/adapters/claude_adapter.dart';
import '../models/ai_config.dart';
import '../models/ai_message.dart';
import 'ai_action_handler.dart';

/// AI服务集成示例
class AIServiceIntegrationExample {
  static const String example = '''
  // 1. 初始化AI服务
  final aiService = await AIService.initialize();

  // 2. 创建OpenAI配置
  final openaiConfig = AIConfig(
    id: 'openai-config-1',
    provider: AIProvider.openai,
    apiKey: 'your-api-key-here',
    model: 'gpt-4o',
  );

  // 3. 添加配置到服务
  await aiService.addConfig(openaiConfig);

  // 4. 设置为活跃配置
  await aiService.setActiveConfig(openaiConfig.id);

  // 5. 创建AI操作处理器
  final handler = AIActionHandler(
    onResult: (action, result) {
      Logger.debug('操作 $action 完成: $result');
    },
    onError: (error) {
      Logger.debug('发生错误: $error');
    },
    aiService: aiService,
  );

  // 6. 使用AI功能
  await handler.polish(text: '这是一段需要润色的文本');

  // 7. 或者直接使用AI服务
  final messages = [
    AIMessage.user(
      id: 'user-1',
      content: '请帮我润色这段文本',
    ),
  ];

  final response = await aiService.sendMessage(messages);
  Logger.debug('AI回复: ${response.content}');
  ''';
}

/// 实际使用示例
class AIServiceUsageExample extends StatefulWidget {
  @override
  _AIServiceUsageExampleState createState() => _AIServiceUsageExampleState();
}

class _AIServiceUsageExampleState extends State<AIServiceUsageExample> {
  late final AIActionHandler _handler;
  late final AIService _aiService;
  String _result = '';
  String _error = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeAIService();
  }

  Future<void> _initializeAIService() async {
    try {
      // 初始化AI服务
      _aiService = await AIService.initialize();

      // 创建示例配置（在实际使用中，应该从安全存储或用户设置中获取）
      final config = AIConfig(
        id: 'demo-config',
        provider: AIProvider.openai,
        apiKey: 'your-api-key-here', // 替换为实际的API密钥
        model: 'gpt-4o-mini',
      );

      // 添加配置并设置为活跃
      await _aiService.addConfig(config);
      await _aiService.setActiveConfig(config.id);

      // 创建AI操作处理器
      _handler = AIActionHandler(
        onResult: (action, result) {
          setState(() {
            _result = result;
            _isProcessing = false;
          });
        },
        onError: (error) {
          setState(() {
            _error = error;
            _isProcessing = false;
          });
        },
        aiService: _aiService,
      );
    } catch (e) {
      setState(() {
        _error = '初始化失败: $e';
      });
    }
  }

  Future<void> _performPolish() async {
    setState(() {
      _isProcessing = true;
      _result = '';
      _error = '';
    });

    await _handler.polish(
      text: '这是一个需要润色的示例文本，它可能需要更好的表达方式。',
      context: '这是一篇技术文档的一部分。',
    );
  }

  Future<void> _PerformExpand() async {
    setState(() {
      _isProcessing = true;
      _result = '';
      _error = '';
    });

    await _handler.expand(
      text: '人工智能技术正在快速发展。',
      context: '技术趋势分析',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI服务集成示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    '错误: $_error',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            if (_result.isNotEmpty)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    '结果: $_result',
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _performPolish,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('AI润色'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isProcessing ? null : _PerformExpand,
              child: const Text('AI扩写'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _handler.dispose();
    _aiService.dispose();
    super.dispose();
  }
}

/// 配置不同的AI提供商
class AIProviderConfiguration {
  /// 创建OpenAI配置
  static AIConfig createOpenAIConfig({
    required String apiKey,
    String model = 'gpt-4o-mini',
    String? baseUrl,
  }) {
    return AIConfig(
      id: 'openai-${DateTime.now().millisecondsSinceEpoch}',
      provider: AIProvider.openai,
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
      maxTokens: 2048,
      temperature: 0.7,
    );
  }

  /// 创建Claude配置
  static AIConfig createClaudeConfig({
    required String apiKey,
    String model = 'claude-3-5-sonnet-20241022',
    String? baseUrl,
  }) {
    return AIConfig(
      id: 'claude-${DateTime.now().millisecondsSinceEpoch}',
      provider: AIProvider.anthropic,
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
      maxTokens: 4096,
      temperature: 0.7,
    );
  }

  /// 创建DeepSeek配置
  static AIConfig createDeepSeekConfig({
    required String apiKey,
    String model = 'deepseek-chat',
    String? baseUrl,
  }) {
    return AIConfig(
      id: 'deepseek-${DateTime.now().millisecondsSinceEpoch}',
      provider: AIProvider.deepseek,
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
      maxTokens: 2048,
      temperature: 0.7,
    );
  }

  /// 创建本地Ollama配置
  static AIConfig createOllamaConfig({
    String model = 'llama3',
    String? baseUrl,
  }) {
    return AIConfig(
      id: 'ollama-${DateTime.now().millisecondsSinceEpoch}',
      provider: AIProvider.ollama,
      apiKey: '', // Ollama不需要API密钥
      model: model,
      baseUrl: baseUrl ?? 'http://localhost:11434/v1',
      maxTokens: 2048,
      temperature: 0.7,
    );
  }
}

/// 流式响应处理示例
class StreamingExample {
  static Future<void> streamResponses(AIService aiService) async {
    final messages = [
      AIMessage.user(
        id: 'user-1',
        content: '请详细解释什么是机器学习',
      ),
    ];

    Logger.debug('开始接收流式响应...');

    await for (final chunk in aiService.sendMessageStream(messages)) {
      Logger.debug(chunk.content);
      if (chunk.isComplete) {
        Logger.debug('\n流式响应完成');
        Logger.debug('使用Token: ${chunk.inputTokens} + ${chunk.outputTokens}');
      }
    }
  }
}

/// 错误处理示例
class ErrorHandlingExample {
  static Future<void> handleAIErrors(AIService aiService) async {
    try {
      final config = AIConfig(
        id: 'test-config',
        provider: AIProvider.openai,
        apiKey: 'invalid-key',
        model: 'gpt-4o-mini',
      );

      await aiService.addConfig(config);
      await aiService.setActiveConfig(config.id);

      final messages = [
        AIMessage.user(id: 'test', content: '测试消息'),
      ];

      await aiService.sendMessage(messages);
    } catch (e) {
      // 处理不同类型的错误
      if (e is ApiKeyException) {
        Logger.debug('API密钥错误: ${e.message}');
      } else if (e is RateLimitException) {
        Logger.debug('请求频率限制: ${e.message}');
      } else if (e is QuotaException) {
        Logger.debug('配额用完: ${e.message}');
      } else if (e is TimeoutException) {
        Logger.debug('请求超时: ${e.message}');
      } else if (e is NetworkException) {
        Logger.debug('网络错误: ${e.message}');
      } else {
        Logger.debug('未知错误: $e');
      }
    }
  }
}
