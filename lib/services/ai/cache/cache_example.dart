import '../../config/app_constants.dart';
import '../../utils/logger.dart';
import 'package:museflow/services/ai/ai_service.dart';
import 'package:museflow/models/ai_message.dart';
import 'package:museflow/models/ai_config.dart';

/// AI缓存系统使用示例
/// 演示如何使用AI请求缓存功能
class AICacheExample {
  /// 基础使用示例
  static Future<void> basicExample() async {
    // 1. 初始化AI服务（自动初始化缓存）
    final aiService = await AIService.initialize();

    // 2. 创建消息和配置
    final messages = [
      AIMessage.user(
        id: 'msg_1',
        content: '什么是Flutter？',
      ),
    ];

    final config = AIConfig(
      id: 'config_1',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-5-sonnet-20241022',
    );

    // 3. 发送消息（自动使用缓存）
    final response1 = await aiService.sendMessage(messages, config: config);
    Logger.debug('第一次请求: ${response1.content}');

    // 4. 再次发送相同消息（从缓存返回）
    final response2 = await aiService.sendMessage(messages, config: config);
    Logger.debug('第二次请求（缓存命中）: ${response2.content}');

    // 5. 查看缓存统计
    final stats = await aiService.getCacheStats();
    Logger.debug('缓存命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
    Logger.debug('节省的请求数: ${stats.requestsSaved}');
  }

  /// 高级使用示例
  static Future<void> advancedExample() async {
    final aiService = await AIService.initialize();

    // 创建复杂的消息历史
    final messages = [
      AIMessage.system(
        id: 'sys_1',
        content: '你是一个专业的Flutter开发助手',
      ),
      AIMessage.user(
        id: 'user_1',
        content: '如何优化Flutter应用性能？',
      ),
      AIMessage.assistant(
        id: 'asst_1',
        content: '可以从以下几个方面优化...',
      ),
      AIMessage.user(
        id: 'user_2',
        content: '请详细说明第一点',
      ),
    ];

    final config = AIConfig(
      id: 'config_1',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-5-sonnet-20241022',
      temperature: 0.7,
    );

    // 发送消息并自动缓存
    final response = await aiService.sendMessage(
      messages,
      config: config,
      useCache: true, // 明确启用缓存
    );

    Logger.debug('AI响应: ${response.content}');
    Logger.debug('是否来自缓存: ${response.metadata?['cached'] ?? false}');
  }

  /// 缓存统计监控示例
  static Future<void> monitoringExample() async {
    final aiService = await AIService.initialize();

    // 发送一些请求
    await _sendSampleRequests(aiService);

    // 获取缓存性能报告
    final report = await aiService.getCachePerformanceReport();
    Logger.debug('=== 缓存性能报告 ===');
    Logger.debug(report);

    // 获取缓存健康状态
    final health = await aiService.getCacheHealthStatus();
    Logger.debug('\n=== 缓存健康状态 ===');
    Logger.debug('健康状态: ${health['is_healthy'] ? "良好" : "需要关注"}');
    Logger.debug('命中率: ${(health['hit_rate'] * 100).toStringAsFixed(1)}%');
    Logger.debug('请求节省率: ${(health['requests_saved_rate'] * 100).toStringAsFixed(1)}%');

    // 获取性能指标
    final metrics = await aiService.getCachePerformanceMetrics();
    Logger.debug('\n=== 详细性能指标 ===');
    Logger.debug(metrics.toReport());

    // 获取优化建议
    final suggestions = await aiService.getCacheSuggestions();
    Logger.debug('\n=== 优化建议 ===');
    for (final suggestion in suggestions) {
      Logger.debug('- $suggestion');
    }
  }

  /// 缓存管理示例
  static Future<void> managementExample() async {
    final aiService = await AIService.initialize();

    // 监听缓存事件
    aiService.cacheEvents.listen((event) {
      Logger.debug('缓存事件: $event');
    });

    // 发送一些请求
    await _sendSampleRequests(aiService);

    // 清理过期缓存
    await aiService.clearCache(clearExpiredOnly: true);
    Logger.debug('已清理过期缓存');

    // 清空所有缓存
    await aiService.clearCache(clearExpiredOnly: false);
    Logger.debug('已清空所有缓存');

    // 重置统计信息
    aiService.resetCacheStats();
    Logger.debug('已重置缓存统计');
  }

  /// 缓存优化示例
  static Future<void> optimizationExample() async {
    final aiService = await AIService.initialize();

    // 发送一些请求
    await _sendSampleRequests(aiService);

    // 获取当前性能指标
    final metricsBefore = await aiService.getCachePerformanceMetrics();
    Logger.debug('优化前命中率: ${(metricsBefore.hitRate * 100).toStringAsFixed(1)}%');

    // 优化缓存策略
    await aiService.optimizeCacheStrategy();

    // 发送更多请求
    await _sendSampleRequests(aiService);

    // 查看优化后的效果
    final metricsAfter = await aiService.getCachePerformanceMetrics();
    Logger.debug('优化后命中率: ${(metricsAfter.hitRate * 100).toStringAsFixed(1)}%');
  }

  /// 缓存预热示例
  static Future<void> warmupExample() async {
    final aiService = await AIService.initialize();

    final config = AIConfig(
      id: 'config_1',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-5-sonnet-20241022',
    );

    // 预热常见查询
    final commonQueries = [
      AIMessage.user(id: 'q1', content: '什么是Flutter？'),
      AIMessage.user(id: 'q2', content: '如何开始学习Flutter？'),
      AIMessage.user(id: 'q3', content: 'Flutter的优势是什么？'),
    ];

    for (final query in commonQueries) {
      await aiService.warmupCache(
        [AIMessage.system(
          id: 'sys',
          content: '你是一个Flutter专家',
        ), query],
        config,
      );
    }

    Logger.debug('缓存预热完成');

    // 现在这些请求将直接从缓存返回
    for (final query in commonQueries) {
      final response = await aiService.sendMessage(
        [AIMessage.system(
          id: 'sys',
          content: '你是一个Flutter专家',
        ), query],
        config: config,
      );
      Logger.debug('查询: ${query.content}');
      Logger.debug('响应: ${response.metadata?['cached'] ?? false ? "来自缓存" : "新请求"}');
    }
  }

  /// 禁用缓存示例
  static Future<void> disableCacheExample() async {
    final aiService = await AIService.initialize();

    // 禁用缓存
    aiService.setCachingEnabled(false);

    final messages = [
      AIMessage.user(id: 'msg_1', content: '这个问题不会被缓存'),
    ];

    final config = AIConfig(
      id: 'config_1',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-5-sonnet-20241022',
    );

    // 这次请求不会被缓存
    final response1 = await aiService.sendMessage(messages, config: config);
    Logger.debug('第一次请求: ${response1.content}');

    // 第二次请求仍然会发送到API
    final response2 = await aiService.sendMessage(messages, config: config);
    Logger.debug('第二次请求（未缓存）: ${response2.content}');

    // 重新启用缓存
    aiService.setCachingEnabled(true);
  }

  /// 流式响应缓存示例
  static Future<void> streamingCacheExample() async {
    final aiService = await AIService.initialize();

    final messages = [
      AIMessage.user(id: 'msg_1', content: '请详细介绍Flutter的历史'),
    ];

    final config = AIConfig(
      id: 'config_1',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-5-sonnet-20241022',
    );

    // 流式请求（完成后会缓存完整响应）
    Logger.debug('流式响应:');
    await for (final chunk in aiService.sendMessageStream(
      messages,
      config: config,
      useCache: true,
    )) {
      Logger.debug(chunk.content, end: '');
    }
    Logger.debug('\n');

    // 下次请求会使用缓存
    Logger.debug('第二次请求（缓存命中）:');
    final response = await aiService.sendMessage(messages, config: config);
    Logger.debug(response.content);
  }

  /// 辅助方法：发送示例请求
  static Future<void> _sendSampleRequests(AIService aiService) async {
    final config = AIConfig(
      id: 'config_1',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-5-sonnet-20241022',
    );

    final messages = [
      AIMessage.user(id: 'msg_1', content: '什么是Dart编程语言？'),
    ];

    // 发送几次相同的请求
    for (int i = 0; i < 5; i++) {
      await aiService.sendMessage(messages, config: config);
    }

    // 发送一些不同的请求
    final differentMessages = [
      AIMessage.user(id: 'msg_2', content: '什么是Widget树？'),
      AIMessage.user(id: 'msg_3', content: '如何处理状态管理？'),
    ];

    for (final messages in differentMessages) {
      await aiService.sendMessage(messages, config: config);
    }
  }

  /// 完整的工作流程示例
  static Future<void> completeWorkflowExample() async {
    Logger.debug('=== AI缓存系统完整工作流程 ===\n');

    // 1. 初始化
    Logger.debug('1. 初始化AI服务...');
    final aiService = await AIService.initialize();
    Logger.debug('✓ 初始化完成\n');

    // 2. 配置
    Logger.debug('2. 配置AI服务...');
    final config = AIConfig(
      id: 'config_1',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-5-sonnet-20241022',
    );
    Logger.debug('✓ 配置完成\n');

    // 3. 监听缓存事件
    Logger.debug('3. 监听缓存事件...');
    aiService.cacheEvents.listen((event) {
      Logger.debug('  事件: $event');
    });
    Logger.debug('✓ 监听器已设置\n');

    // 4. 预热缓存
    Logger.debug('4. 预热常见查询...');
    await aiService.warmupCache(
      [
        AIMessage.user(id: 'q1', content: '什么是Flutter？'),
      ],
      config,
    );
    Logger.debug('✓ 预热完成\n');

    // 5. 发送请求
    Logger.debug('5. 发送请求...');
    final messages = [
      AIMessage.user(id: 'msg_1', content: '什么是Flutter？'),
    ];

    final response1 = await aiService.sendMessage(messages, config: config);
    Logger.debug('  第一次请求: ${response1.metadata?['cached'] ?? false ? "缓存命中 ✓" : "新请求"}');

    final response2 = await aiService.sendMessage(messages, config: config);
    Logger.debug('  第二次请求: ${response2.metadata?['cached'] ?? false ? "缓存命中 ✓" : "新请求"}');
    Logger.debug();

    // 6. 查看统计
    Logger.debug('6. 查看缓存统计...');
    final stats = await aiService.getCacheStats();
    Logger.debug('  总请求: ${stats.totalRequests}');
    Logger.debug('  缓存命中: ${stats.cacheHits}');
    Logger.debug('  命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
    Logger.debug('  节省请求: ${stats.requestsSaved}');
    Logger.debug();

    // 7. 获取建议
    Logger.debug('7. 获取优化建议...');
    final suggestions = await aiService.getCacheSuggestions();
    for (final suggestion in suggestions) {
      Logger.debug('  - $suggestion');
    }
    Logger.debug();

    // 8. 生成报告
    Logger.debug('8. 生成性能报告...');
    final report = await aiService.getCachePerformanceReport();
    Logger.debug(report);
    Logger.debug();

    Logger.debug('=== 工作流程完成 ===');
  }
}
