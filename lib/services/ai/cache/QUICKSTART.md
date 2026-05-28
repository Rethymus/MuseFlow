# AI缓存系统快速开始指南

## 🚀 5分钟快速上手

### 1. 初始化系统
```dart
// 初始化AI服务（自动初始化缓存系统）
final aiService = await AIService.initialize();
```

### 2. 正常使用（自动启用缓存）
```dart
// 创建消息
final messages = [
  AIMessage.user(
    id: 'msg_1',
    content: '什么是Flutter？',
  ),
];

// 创建配置
final config = AIConfig(
  id: 'config_1',
  provider: AIProvider.anthropic,
  apiKey: 'your-api-key',
  model: 'claude-3-5-sonnet-20241022',
);

// 发送消息 - 缓存自动工作
final response = await aiService.sendMessage(messages, config: config);
print('响应: ${response.content}');
print('是否缓存: ${response.metadata?['cached'] ?? false}');
```

### 3. 查看缓存效果
```dart
// 发送相同请求 - 这次会从缓存返回
final cachedResponse = await aiService.sendMessage(messages, config: config);
print('缓存命中: ${cachedResponse.metadata?['cached'] ?? false}');

// 查看统计信息
final stats = await aiService.getCacheStats();
print('缓存命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
print('节省的请求数: ${stats.requestsSaved}');
```

## 📊 监控缓存性能

### 实时统计
```dart
// 获取缓存统计
final stats = await aiService.getCacheStats();
print('总请求数: ${stats.totalRequests}');
print('缓存命中: ${stats.cacheHits}');
print('缓存未命中: ${stats.cacheMisses}');
print('命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
```

### 健康检查
```dart
// 检查缓存健康状态
final health = await aiService.getCacheHealthStatus();
print('健康状态: ${health['is_healthy'] ? "良好" : "需要关注"}');
print('命中率: ${(health['hit_rate'] * 100).toStringAsFixed(1)}%');
print('请求节省率: ${(health['requests_saved_rate'] * 100).toStringAsFixed(1)}%');
```

### 生成报告
```dart
// 生成完整性能报告
final report = await aiService.getCachePerformanceReport();
print(report);
```

## 🔧 缓存管理

### 清理缓存
```dart
// 清理过期缓存
await aiService.clearCache(clearExpiredOnly: true);

// 清空所有缓存
await aiService.clearCache(clearExpiredOnly: false);
```

### 控制缓存
```dart
// 禁用缓存（用于特定请求）
aiService.setCachingEnabled(false);

// 重新启用缓存
aiService.setCachingEnabled(true);

// 单次请求禁用缓存
final response = await aiService.sendMessage(
  messages,
  config: config,
  useCache: false,
);
```

## 🎯 高级功能

### 监听缓存事件
```dart
// 监听所有缓存事件
aiService.cacheEvents.listen((event) {
  switch (event.type) {
    case CacheManagerEventType.hit:
      print('✓ 缓存命中: ${event.key}');
      break;
    case CacheManagerEventType.miss:
      print('✗ 缓存未命中: ${event.key}');
      break;
    case CacheManagerEventType.evicted:
      print('⚠ 缓存驱逐: ${event.key}');
      break;
    case CacheManagerEventType.expired:
      print('⏰ 缓存过期: ${event.key}');
      break;
  }
});
```

### 缓存预热
```dart
// 预热常见查询
final commonQueries = [
  AIMessage.user(id: 'q1', content: '什么是Flutter？'),
  AIMessage.user(id: 'q2', content: '如何开始学习Flutter？'),
  AIMessage.user(id: 'q3', content: 'Flutter的优势是什么？'),
];

await aiService.warmupCache(commonQueries, config);
```

### 性能优化
```dart
// 获取优化建议
final suggestions = await aiService.getCacheSuggestions();
for (final suggestion in suggestions) {
  print('建议: $suggestion');
}

// 优化缓存策略
await aiService.optimizeCacheStrategy();
```

## 📈 性能目标

### 预期效果
- **缓存命中率**: 45%+
- **API调用减少**: 30%+
- **响应时间减少**: 50%+
- **Token节省**: 根据命中率自动计算

### 监控指标
```dart
// 获取详细性能指标
final metrics = await aiService.getCachePerformanceMetrics();
print('命中率: ${(metrics.hitRate * 100).toStringAsFixed(1)}%');
print('请求节省率: ${(metrics.requestsSavedRate * 100).toStringAsFixed(1)}%');
print('Token节省率: ${(metrics.tokensSavedRate * 100).toStringAsFixed(1)}%');
print('平均响应时间: ${metrics.avgResponseTime.toStringAsFixed(0)}ms');
print('效率状态: ${metrics.isEfficient ? "良好" : "需要改进"}');
```

## 🛠️ 故障排除

### 缓存命中率低
**问题**: 命中率低于45%
**解决方案**:
```dart
// 1. 检查配置
final suggestions = await aiService.getCacheSuggestions();
print(suggestions);

// 2. 优化策略
await aiService.optimizeCacheStrategy();

// 3. 考虑预热
await aiService.warmupCache(commonQueries, config);
```

### 内存使用过高
**问题**: 内存缓存占用过大
**解决方案**:
```dart
// 1. 清理过期缓存
await aiService.clearCache(clearExpiredOnly: true);

// 2. 清空所有缓存
await aiService.clearCache(clearExpiredOnly: false);
```

### 缓存未生效
**问题**: 请求没有被缓存
**解决方案**:
```dart
// 1. 确认缓存已启用
aiService.setCachingEnabled(true);

// 2. 检查是否明确禁用
final response = await aiService.sendMessage(
  messages,
  config: config,
  useCache: true, // 确保启用
);
```

## 📱 实际应用示例

### 聊天应用
```dart
class ChatService {
  final AIService _aiService = AIService.instance;

  Future<String> sendMessage(String message) async {
    final messages = [
      AIMessage.system(id: 'sys', content: '你是一个友好的助手'),
      AIMessage.user(id: 'user', content: message),
    ];

    final response = await _aiService.sendMessage(messages, config: config);

    // 检查是否来自缓存
    if (response.metadata?['cached'] == true) {
      print('⚡ 响应来自缓存');
    }

    return response.content;
  }
}
```

### 文档问答
```dart
class DocQAService {
  final AIService _aiService = AIService.instance;

  Future<String> answerQuestion(String question, String document) async {
    final messages = [
      AIMessage.system(id: 'sys', content: '根据以下文档回答问题：\n$document'),
      AIMessage.user(id: 'user', content: question),
    ];

    final response = await _aiService.sendMessage(messages, config: config);
    return response.content;
  }

  // 预热常见问题
  Future<void> warmupCommonQuestions(String document) async {
    final commonQuestions = [
      '这个文档的主要内容是什么？',
      '如何使用这个功能？',
      '有什么注意事项？',
    ];

    for (final question in commonQuestions) {
      await answerQuestion(question, document);
    }
  }
}
```

### 代码助手
```dart
class CodeAssistantService {
  final AIService _aiService = AIService.instance;

  Future<String> generateCode(String description) async {
    final messages = [
      AIMessage.system(id: 'sys', content: '你是一个编程助手，用Flutter/Dart编写代码'),
      AIMessage.user(id: 'user', content: description),
    ];

    final response = await _aiService.sendMessage(messages, config: config);
    return response.content;
  }

  // 监听缓存事件来优化
  void setupCacheMonitoring() {
    _aiService.cacheEvents.listen((event) {
      if (event.type == CacheManagerEventType.miss) {
        print('缓存未命中，考虑预热: ${event.key}');
      }
    });
  }
}
```

## 🎓 最佳实践

### 1. 合理使用缓存
```dart
// ✅ 适合缓存的场景
final systemPrompt = '你是一个Flutter专家';
final commonQuestions = ['什么是Flutter？', '如何开始学习？'];

// ❌ 不适合缓存的场景
final realtimeData = '当前时间是：${DateTime.now()}';
final userSpecific = '用户${userId}的私人数据';
```

### 2. 定期监控
```dart
// 定期检查缓存性能
Timer.periodic(Duration(hours: 1), (timer) async {
  final health = await aiService.getCacheHealthStatus();
  if (!(health['is_healthy'] as bool)) {
    print('⚠ 缓存性能需要关注');
    final suggestions = await aiService.getCacheSuggestions();
    print(suggestions);
  }
});
```

### 3. 错误处理
```dart
try {
  final response = await aiService.sendMessage(messages, config: config);
  print('响应: ${response.content}');
} catch (e) {
  print('请求失败: $e');

  // 可以禁用缓存重试
  final retry = await aiService.sendMessage(
    messages,
    config: config,
    useCache: false,
  );
}
```

## 🔗 相关资源

- **详细文档**: [README.md](README.md)
- **实现总结**: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- **使用示例**: [cache_example.dart](cache_example.dart)
- **单元测试**: [cache_test.dart](cache_test.dart)

## 💡 小贴士

1. **缓存会自动工作** - 无需特殊处理，正常调用AI服务即可
2. **监控很重要** - 定期检查缓存统计，优化性能
3. **预热很有用** - 对常见查询进行预热可以显著提高命中率
4. **事件监听很强大** - 通过监听缓存事件可以深入了解系统运行状态
5. **配置很灵活** - 根据应用特点调整缓存配置

---

现在你已经准备好使用AI缓存系统了！记住，缓存会自动工作，但通过监控和优化可以获得更好的效果。