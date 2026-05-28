# AI辅助写作增强功能

## 概述

本文档介绍新增的AI辅助写作增强功能，这些功能在保持现有API兼容性的基础上，为用户提供更智能、更个性化的写作体验。

## 新增服务

### 1. ContextualAIService（上下文AI服务）

**文件位置**: `lib/services/ai/contextual_ai_service.dart`

**主要功能**:
- 文档风格分析
- 个性化提示词生成
- 多轮对话支持
- 上下文感知建议

**核心方法**:
```dart
// 分析文档风格
Future<DocumentStyleAnalysis> analyzeDocumentStyle(
  String documentContent, {
  String? documentId,
  String? context,
})

// 生成个性化提示词
Future<String> generatePersonalizedPrompt({
  required String userIntent,
  String? documentId,
  String? conversationId,
  Map<String, dynamic>? customContext,
})

// 开始多轮对话
String startConversation({
  String? documentId,
  String? initialContext,
  Map<String, dynamic>? metadata,
})

// 继续对话
Future<AIResponse> continueConversation(
  String conversationId,
  String userMessage, {
  AIConfig? config,
})
```

### 2. RealTimeWritingAssistant（实时写作助手）

**文件位置**: `lib/services/ai/realtime_writing_assistant.dart`

**主要功能**:
- 实时写作预测
- 用户意图预测
- 情境化提示生成
- 格式建议

**核心方法**:
```dart
// 开始写作会话
String startWritingSession({
  required String documentId,
  String? conversationId,
  String? initialContent,
  Map<String, dynamic>? metadata,
})

// 处理文本输入并生成预测
Future<List<WritingPrediction>> processTextInput(
  String sessionId,
  String currentText, {
  int? cursorPosition,
})

// 预测用户需求
Future<UserIntentPrediction> predictUserNeeds(
  String sessionId,
  String currentText,
)

// 生成情境化提示
Future<ContextualPrompt> generateContextualPrompt(
  String sessionId,
  String currentText, {
  String? specificContext,
  List<String>? focusAreas,
})

// 提供格式建议
Future<FormatSuggestion> provideFormatSuggestion(
  String sessionId,
  String currentText,
)
```

### 3. AIServiceIntegration（AI服务集成器）

**文件位置**: `lib/services/ai/ai_service_integration.dart`

**主要功能**:
- 统一管理所有AI服务
- 提供向后兼容的API
- 服务健康检查
- 配置管理

**核心方法**:
```dart
// 初始化所有服务
static Future<AIServiceIntegration> initialize({
  AIService? baseService,
  PersonalizedAIService? personalizedService,
  ContextualAIService? contextualService,
  RealTimeWritingAssistant? writingAssistant,
  AIServiceIntegrationConfig? config,
})

// 向后兼容的发送消息方法
Future<AIResponse> sendMessage(
  List<AIMessage> messages, {
  AIConfig? config,
  int? retryCount,
  bool useCache = true,
  bool applyPersonalization = true,
})

// 上下文感知消息
Future<AIResponse> sendContextualMessage(
  String userMessage, {
  String? documentId,
  String? conversationId,
  AIConfig? config,
  Map<String, dynamic>? customContext,
})
```

## 配置选项

### AIServiceIntegrationConfig

```dart
class AIServiceIntegrationConfig {
  final bool enablePersonalizedService;      // 启用个性化服务
  final bool enableContextualService;         // 启用上下文服务
  final bool enableWritingAssistant;          // 启用写作助手
  final bool enableCaching;                   // 启用缓存
  final int maxContextHistory;                // 最大上下文历史
  final double styleAnalysisThreshold;        // 风格分析阈值
  final int maxConversationTurns;             // 最大对话轮数
}
```

### 预设配置

```dart
// 基础配置（仅核心功能）
AIServiceIntegrationConfig.basicOnly()

// 默认配置（推荐）
AIServiceIntegrationConfig.defaultConfig()

// 完整功能配置
AIServiceIntegrationConfig.fullFeatured()

// 创意写作配置
AIServiceIntegrationConfig.creativeWriting()

// 技术写作配置
AIServiceIntegrationConfig.technicalWriting()
```

## 使用示例

### 1. 基础使用

```dart
// 初始化服务
final integration = await AIServiceIntegration.initialize();

// 配置AI服务
final config = AIConfig(
  id: 'my-config',
  provider: AIProvider.anthropic,
  apiKey: 'your-api-key',
  model: 'claude-3-sonnet',
);

await integration.addConfig(config);
await integration.setActiveConfig(config.id);

// 发送消息（向后兼容）
final messages = [
  AIMessage.user(id: 'user-1', content: '帮我写一篇文章'),
];

final response = await integration.sendMessage(messages);
```

### 2. 上下文感知写作

```dart
// 分析文档风格
final styleAnalysis = await integration.analyzeDocumentStyle(
  documentContent,
  documentId: 'doc-001',
);

// 开始上下文对话
final conversationId = integration.startConversation(
  documentId: 'doc-001',
);

// 发送上下文感知消息
final response = await integration.sendContextualMessage(
  '帮我扩展内容',
  documentId: 'doc-001',
  conversationId: conversationId,
);

// 继续对话
await integration.continueConversation(conversationId, '再详细一些');

// 结束对话
final summary = await integration.endConversation(conversationId);
```

### 3. 实时写作助手

```dart
// 开始写作会话
final sessionId = integration.startWritingSession(
  documentId: 'doc-002',
);

// 处理用户输入
final predictions = await integration.processWritingInput(
  sessionId,
  '人工智能技术',
);

// 预测用户意图
final intent = await integration.predictUserNeeds(
  sessionId,
  '人工智能技术在现代社会中的重要作用',
);

// 获取格式建议
final formatSuggestion = await integration.provideFormatSuggestion(
  sessionId,
  currentText,
);

// 结束写作会话
final summary = await integration.endWritingSession(sessionId);
```

## API兼容性

### 保持兼容的方法

所有现有的AIService方法都被保留，可以通过集成器访问：

```dart
// 配置管理
integration.addConfig(config)
integration.getConfigs()
integration.getConfig(id)
integration.deleteConfig(id)
integration.setActiveConfig(id)
integration.getActiveConfig()

// 消息发送
integration.sendMessage(messages)
integration.sendMessageStream(messages)

// 缓存管理
integration.cacheManager
integration.getCacheStats()
integration.clearCache()
```

### 新增功能

新功能通过专用方法提供，不影响现有功能：

```dart
// 上下文服务
integration.sendContextualMessage()
integration.startConversation()
integration.continueConversation()
integration.endConversation()

// 写作助手
integration.startWritingSession()
integration.processWritingInput()
integration.predictUserNeeds()
integration.generateContextualPrompt()
integration.provideFormatSuggestion()
```

## 配置管理

### 使用配置管理器

```dart
// 初始化配置管理器
final configManager = await AIServicesConfigManager.initialize();

// 启用/禁用服务
await configManager.enablePersonalizedService();
await configManager.disableContextualService();

// 应用预设配置
await configManager.applyPresetConfig('creative_writing');

// 自定义配置
await configManager.setMaxContextHistory(100);
await configManager.setStyleAnalysisThreshold(0.7);

// 验证配置
final issues = configManager.validateConfig(configManager.currentConfig);

// 获取优化建议
final suggestions = configManager.getOptimizationSuggestions();
```

## 错误处理

### 服务未启用错误

```dart
try {
  await integration.sendContextualMessage('测试消息');
} catch (e) {
  if (e.toString().contains('not enabled')) {
    // 启用所需服务
    final config = AIServiceIntegrationConfig.fullFeatured();
    await integration.updateServiceConfig(config);
  }
}
```

### 初始化错误

```dart
try {
  final integration = await AIServiceIntegration.initialize();
} catch (e) {
  // 处理初始化错误
  print('初始化失败: $e');
}
```

## 性能优化

### 缓存策略

```dart
// 启用缓存
final config = AIServiceIntegrationConfig(
  enableCaching: true,
);

// 预热缓存
await integration.warmupCache(commonMessages, config);

// 查看缓存统计
final stats = await integration.getCacheStats();
print('缓存命中率: ${stats.hitRate}');
```

### 资源管理

```dart
// 定期清理不活跃的上下文
integration.clearContextHistory(documentId: 'old-doc');

// 设置合理的历史大小限制
configManager.setMaxContextHistory(50);

// 监听服务事件
integration.writingAssistantEvents.listen((event) {
  // 处理事件
});
```

## 监控和调试

### 健康检查

```dart
// 获取服务健康状态
final healthStatus = await integration.getHealthStatus();
print('服务状态: ${healthStatus['services']}');
print('缓存状态: ${healthStatus['cache']}');
```

### 学习统计

```dart
// 查看个性化学习统计
final stats = integration.getLearningStats();
print('反馈数量: ${stats['feedbackCount']}');
print('偏好置信度: ${stats['preferenceConfidence']}');
```

### 隐私报告

```dart
// 获取隐私报告
final privacyReport = await integration.getPrivacyReport();
print('数据收集: ${privacyReport['dataCollection']}');
print('存储位置: ${privacyReport['storageLocation']}');
```

## 最佳实践

### 1. 渐进式启用

```dart
// 从基础配置开始
final integration = await AIServiceIntegration.initialize(
  config: AIServiceIntegrationConfig.basicOnly(),
);

// 逐步启用功能
await integration.updateServiceConfig(
  AIServiceIntegrationConfig.defaultConfig(),
);
```

### 2. 错误恢复

```dart
try {
  final response = await integration.sendMessage(messages);
} catch (e) {
  // 记录错误
  Logger.error('AI请求失败: $e');

  // 尝试降级到基础服务
  await integration.updateServiceConfig(
    AIServiceIntegrationConfig.basicOnly(),
  );

  // 重试请求
  final response = await integration.sendMessage(messages);
}
```

### 3. 资源清理

```dart
// 使用完毕后清理资源
try {
  // 使用服务
} finally {
  integration.dispose();
}
```

## 迁移指南

### 从现有AIService迁移

```dart
// 旧代码
final aiService = await AIService.initialize();
final response = await aiService.sendMessage(messages);

// 新代码（保持兼容）
final integration = await AIServiceIntegration.initialize();
final response = await integration.sendMessage(messages);

// 或者使用新功能
final response = await integration.sendContextualMessage(
  userMessage,
  documentId: 'doc-001',
);
```

## 故障排除

### 常见问题

1. **服务初始化失败**
   - 检查依赖服务是否已正确初始化
   - 验证API密钥配置
   - 查看日志输出

2. **上下文服务不工作**
   - 确认已启用上下文服务
   - 检查文档ID是否正确
   - 验证上下文历史大小设置

3. **性能问题**
   - 减少上下文历史大小
   - 启用缓存功能
   - 调整分析阈值

4. **内存使用过高**
   - 定期清理上下文历史
   - 限制最大对话轮数
   - 禁用不需要的服务

## 更新日志

### v1.0.0 (当前版本)

- ✅ 新增ContextualAIService
- ✅ 新增RealTimeWritingAssistant
- ✅ 新增AIServiceIntegration
- ✅ 保持向后兼容性
- ✅ 添加配置管理器
- ✅ 完善错误处理
- ✅ 添加使用示例

## 支持

如有问题或建议，请查看以下资源：

- 示例代码: `lib/services/ai/ai_services_example.dart`
- 配置管理: `lib/services/ai/ai_services_config.dart`
- 集成文档: `lib/services/ai/ai_service_integration.dart`