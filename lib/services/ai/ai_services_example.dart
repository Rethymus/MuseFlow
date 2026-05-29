import 'ai_service_integration.dart';
import '../../models/ai_message.dart';
import '../../models/ai_config.dart';

/// AI服务使用示例
/// 演示如何使用增强的AI服务功能
class AIServicesExample {
  /// 基础使用示例
  static Future<void> basicExample() async {
    // 1. 初始化服务（使用默认配置）
    final integration = await AIServiceIntegration.initialize();

    // 2. 配置AI服务
    final config = AIConfig(
      id: 'my-config',
      provider: AIProvider.anthropic,
      apiKey: 'your-api-key',
      model: 'claude-3-sonnet',
    );

    await integration.addConfig(config);
    await integration.setActiveConfig(config.id);

    // 3. 发送简单消息（向后兼容）
    final messages = [
      AIMessage.system(
        id: 'sys-1',
        content: '你是一个专业的写作助手',
      ),
      AIMessage.user(
        id: 'user-1',
        content: '帮我写一段关于AI技术的介绍',
      ),
    ];

    final response = await integration.sendMessage(messages);
    print('AI响应: ${response.content}');
  }

  /// 个性化服务示例
  static Future<void> personalizedExample() async {
    // 1. 初始化完整服务
    final integration = await AIServiceIntegration.initialize(
      config: AIServiceIntegrationConfig.fullFeatured(),
    );

    // 2. 记录用户反馈以学习偏好
    await integration.recordFeedback(
      originalText: '这个很好',
      suggestedText: '这个非常优秀',
      finalText: '这个非常优秀',
      context: '写作风格调整',
    );

    // 3. 发送个性化消息
    final messages = [
      AIMessage.user(
        id: 'user-1',
        content: '帮我修改这段文字的风格',
      ),
    ];

    final response = await integration.sendMessage(
      messages,
      applyPersonalization: true, // 应用个性化设置
    );

    print('个性化响应: ${response.content}');

    // 4. 查看学习统计
    final stats = integration.getLearningStats();
    print('学习统计: $stats');
  }

  /// 上下文感知写作示例
  static Future<void> contextualExample() async {
    final integration = await AIServiceIntegration.initialize();

    // 1. 分析文档风格
    final documentContent = '''
人工智能技术正在快速发展，深度学习、自然语言处理等领域的突破
为各行各业带来了革命性变化。在写作领域，AI助手能够帮助作者
提高创作效率，提供智能建议，优化文本结构。
''';

    final styleAnalysis = await integration.analyzeDocumentStyle(
      documentContent,
      documentId: 'doc-001',
    );

    print('文档风格分析:');
    print('- 主要风格: ${styleAnalysis.styleProfile.primaryStyle}');
    print('- 置信度: ${styleAnalysis.confidence}');
    print('- 建议: ${styleAnalysis.recommendations}');

    // 2. 开始上下文对话
    final conversationId = integration.startConversation(
      documentId: 'doc-001',
      initialContext: '技术文档写作',
    );

    // 3. 发送上下文感知消息
    final response = await integration.sendContextualMessage(
      '帮我扩展关于深度学习的内容',
      documentId: 'doc-001',
      conversationId: conversationId,
    );

    print('上下文感知响应: ${response.content}');

    // 4. 继续对话
    await integration.continueConversation(
      conversationId,
      '再添加一些应用案例',
    );

    // 5. 结束对话获取摘要
    final summary = await integration.endConversation(conversationId);
    print('对话摘要: ${summary.totalTurns}轮对话');
  }

  /// 实时写作助手示例
  static Future<void> writingAssistantExample() async {
    final integration = await AIServiceIntegration.initialize();

    // 1. 开始写作会话
    final sessionId = integration.startWritingSession(
      documentId: 'doc-002',
      initialContent: '',
    );

    // 2. 模拟用户输入
    final userInput1 = '人工智能';
    final predictions1 = await integration.processWritingInput(
      sessionId,
      userInput1,
    );

    print('输入: "$userInput1"');
    print('预测: ${predictions1.map((p) => p.content).join(', ')}');

    // 3. 预测用户意图
    final userInput2 = '人工智能技术在现代社会中';
    final intent = await integration.predictUserNeeds(sessionId, userInput2);

    print('\n当前输入: "$userInput2"');
    print('预测意图: ${intent.primaryIntent}');
    print(
        '建议动作: ${intent.suggestedActions.map((a) => a.description).join(', ')}');

    // 4. 获取格式建议
    final userInput3 = '''
人工智能技术在现代社会中发挥重要作用。
它改变了我们的工作方式、学习方式以及生活方式。
''';

    final formatSuggestion = await integration.provideFormatSuggestion(
      sessionId,
      userInput3,
    );

    print('\n格式建议:');
    print('- 当前格式: ${formatSuggestion.currentFormat}');
    print('- 建议格式: ${formatSuggestion.suggestedFormat}');

    // 5. 获取情境化提示
    final contextualPrompt = await integration.generateContextualPrompt(
      sessionId,
      userInput3,
      focusAreas: ['风格优化', '结构改进'],
    );

    print('\n情境化提示:');
    print(contextualPrompt.content);

    // 6. 结束写作会话
    final sessionSummary = await integration.endWritingSession(sessionId);
    print('\n会话结束: ${sessionSummary.finalContent.length} 字符');
  }

  /// 高级功能示例
  static Future<void> advancedExample() async {
    final integration = await AIServiceIntegration.initialize(
      config: AIServiceIntegrationConfig.fullFeatured(),
    );

    // 1. 监听写作助手事件
    integration.writingAssistantEvents.listen((event) {
      print('写作助手事件: ${event.type}');
      print('数据: ${event.data}');
    });

    // 2. 监听上下文建议
    integration.contextualSuggestions.listen((suggestion) {
      print('收到建议: ${suggestion.title}');
      print('描述: ${suggestion.description}');
    });

    // 3. 检查服务状态
    final healthStatus = await integration.getHealthStatus();
    print('服务健康状态: ${healthStatus}');

    // 4. 分析用户写作
    final userText = '这是一个很棒的想法，我非常赞同。';
    final writingAnalysis = await integration.analyzeUserWriting(userText);

    print('写作分析:');
    print('- 语言风格: ${writingAnalysis.languageStyle}');
    print('- 详细程度: ${writingAnalysis.detailLevel}');
    print('- 置信度: ${writingAnalysis.confidence}');
  }

  /// 自定义配置示例
  static Future<void> customConfigExample() async {
    // 1. 创建自定义配置
    final customConfig = AIServiceIntegrationConfig(
      enablePersonalizedService: true,
      enableContextualService: true,
      enableWritingAssistant: false, // 禁用写作助手
      enableCaching: true,
      maxContextHistory: 100,
      styleAnalysisThreshold: 0.7,
    );

    // 2. 使用自定义配置初始化
    final integration = await AIServiceIntegration.initialize(
      config: customConfig,
    );

    // 3. 检查服务状态
    print('服务状态: ${integration.serviceStatus}');
    print('个性化服务: ${integration.isServiceEnabled('personalized')}');
    print('上下文服务: ${integration.isServiceEnabled('contextual')}');
    print('写作助手: ${integration.isServiceEnabled('writingAssistant')}');

    // 4. 动态更新配置
    await integration.updateServiceConfig(
      customConfig.copyWith(
        enableWritingAssistant: true, // 启用写作助手
      ),
    );

    print('更新后服务状态: ${integration.serviceStatus}');
  }

  /// 错误处理示例
  static Future<void> errorHandlingExample() async {
    try {
      final integration = await AIServiceIntegration.initialize();

      // 1. 尝试使用未启用的服务
      try {
        await integration.sendContextualMessage('测试消息');
      } catch (e) {
        print('捕获预期错误: $e');
      }

      // 2. 使用正确的配置
      final config = AIServiceIntegrationConfig.fullFeatured();
      await integration.updateServiceConfig(config);

      // 3. 现在应该可以正常工作
      final response = await integration.sendContextualMessage('测试消息');
      print('成功发送上下文消息: ${response.content}');
    } catch (e) {
      print('发生错误: $e');
      // 错误处理逻辑
    } finally {
      // 清理资源
      final instance = AIServiceIntegration.instance;
      if (instance != null) {
        // 使用反射访问私有字段不是好的做法
        // 这里只是示例，实际应用中应该使用公共API
      }
    }
  }

  /// 性能优化示例
  static Future<void> performanceExample() async {
    final integration = await AIServiceIntegration.initialize();

    // 1. 使用缓存功能
    final messages = [
      AIMessage.user(id: 'user-1', content: '常见问题'),
    ];

    // 第一次请求（无缓存）
    final response1 = await integration.sendMessage(
      messages,
      useCache: true,
    );

    // 第二次请求（从缓存获取）
    final response2 = await integration.sendMessage(
      messages,
      useCache: true,
    );

    print('缓存性能: ${response1.metadata}');
    print('缓存命中: ${response2.metadata}');

    // 2. 预热缓存
    await integration.warmupCache(
      messages,
      await integration.getActiveConfig(),
    );

    // 3. 获取缓存统计
    final stats = await integration.getCacheStats();
    print('缓存统计: 命中率 ${stats.hitRate}');
  }

  /// 运行所有示例
  static Future<void> runAllExamples() async {
    print('=== 基础使用示例 ===');
    await basicExample();

    print('\n=== 个性化服务示例 ===');
    await personalizedExample();

    print('\n=== 上下文感知写作示例 ===');
    await contextualExample();

    print('\n=== 实时写作助手示例 ===');
    await writingAssistantExample();

    print('\n=== 高级功能示例 ===');
    await advancedExample();

    print('\n=== 自定义配置示例 ===');
    await customConfigExample();

    print('\n=== 错误处理示例 ===');
    await errorHandlingExample();

    print('\n=== 性能优化示例 ===');
    await performanceExample();
  }
}
