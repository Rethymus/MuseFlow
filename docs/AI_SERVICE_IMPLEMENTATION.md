# AI服务接口实现文档

## 概述

本文档说明了MuseFlow项目中AI服务接口的完整实现，包括OpenAI和Claude服务的集成。

## 实现状态

✅ **已完成** - AI服务接口已完整实现并集成到AIActionHandler中

## 核心组件

### 1. AI服务架构

```
AIService (单例管理器)
    ├── OpenAIAdapter (OpenAI API适配器)
    ├── ClaudeAdapter (Claude API适配器)
    ├── DeepSeekAdapter (DeepSeek API适配器)
    └── OllamaAdapter (本地Ollama适配器)
```

### 2. AIActionHandler集成

`AIActionHandler`现在完全集成了真实的AI服务：

```dart
final handler = AIActionHandler(
  onResult: (action, result) {
    // 处理AI响应
  },
  onError: (error) {
    // 处理错误
  },
  aiService: AIService.instance, // 注入AI服务
);
```

## 实现的功能

### ✅ 已实现功能

1. **OpenAI服务调用**
   - 完整的OpenAI API集成
   - 支持流式响应
   - 支持多种GPT模型

2. **Claude服务调用**
   - 完整的Anthropic Claude API集成
   - 支持流式响应
   - 支持Claude 3系列模型

3. **错误处理**
   - API密钥验证
   - 网络错误处理
   - 超时处理
   - 配额限制处理
   - 内容过滤处理

4. **流式响应**
   - 实时文本流式输出
   - 取消操作支持
   - 进度反馈

5. **配置管理**
   - 多AI提供商支持
   - 安全的API密钥存储
   - 动态配置切换

## 使用示例

### 基础使用

```dart
// 1. 初始化AI服务
final aiService = await AIService.initialize();

// 2. 创建配置
final config = AIConfig(
  id: 'openai-config',
  provider: AIProvider.openai,
  apiKey: 'your-api-key',
  model: 'gpt-4o-mini',
);

// 3. 添加配置
await aiService.addConfig(config);

// 4. 设置活跃配置
await aiService.setActiveConfig(config.id);

// 5. 创建AI处理器
final handler = AIActionHandler(
  onResult: (action, result) {
    print('结果: $result');
  },
  onError: (error) {
    print('错误: $error');
  },
  aiService: aiService,
);

// 6. 使用AI功能
await handler.polish(text: '需要润色的文本');
```

### 流式响应处理

```dart
// 监听流式响应
handler.responseStream.listen((chunk) {
  print('收到数据块: $chunk');
});

// 执行操作
await handler.expand(text: '需要扩写的文本');
```

### 错误处理

```dart
try {
  await handler.summarize(text: '长文本...');
} catch (e) {
  if (e is ApiKeyException) {
    // 处理API密钥错误
  } else if (e is RateLimitException) {
    // 处理频率限制
  } else if (e is QuotaException) {
    // 处理配额限制
  }
}
```

## 配置不同的AI提供商

### OpenAI配置

```dart
final openaiConfig = AIConfig(
  id: 'openai-1',
  provider: AIProvider.openai,
  apiKey: 'sk-...',
  model: 'gpt-4o-mini',
  temperature: 0.7,
  maxTokens: 2048,
);
```

### Claude配置

```dart
final claudeConfig = AIConfig(
  id: 'claude-1',
  provider: AIProvider.anthropic,
  apiKey: 'sk-ant-...',
  model: 'claude-3-5-sonnet-20241022',
  temperature: 0.7,
  maxTokens: 4096,
);
```

### 本地Ollama配置

```dart
final ollamaConfig = AIConfig(
  id: 'ollama-1',
  provider: AIProvider.ollama,
  apiKey: '', // 本地模型不需要API密钥
  model: 'llama3',
  baseUrl: 'http://localhost:11434/v1',
);
```

## 技术细节

### AI服务实现

`AIService`提供了统一的接口来管理多个AI适配器：

- **单例模式**: 确保全局只有一个服务实例
- **适配器模式**: 统一不同AI提供商的接口
- **安全存储**: API密钥加密存储
- **缓存管理**: 智能缓存AI响应
- **重试机制**: 自动重试失败的请求

### AIActionHandler实现

`AIActionHandler`负责处理具体的AI操作：

- **操作队列**: 管理多个AI请求
- **意图确认**: 确认用户意图
- **自然语言处理**: 去除AI生成的"味道"
- **流式响应**: 支持实时输出
- **错误处理**: 完善的错误处理机制

### 错误处理层级

```
AIException (基础异常)
    ├── ApiKeyException (API密钥错误)
    ├── RateLimitException (频率限制)
    ├── QuotaException (配额限制)
    ├── TimeoutException (超时)
    ├── NetworkException (网络错误)
    └── ContentFilterException (内容过滤)
```

## 性能优化

### 缓存策略

```dart
// 启用缓存（默认启用）
await aiService.sendMessage(messages, useCache: true);

// 禁用缓存
await aiService.sendMessage(messages, useCache: false);

// 清理缓存
await aiService.clearCache(clearExpiredOnly: true);
```

### 流式响应优势

- 更快的响应时间
- 更好的用户体验
- 实时反馈
- 支持取消操作

## 安全性

### API密钥管理

- **加密存储**: 使用AES加密
- **安全存储**: 使用FlutterSecureStorage
- **自动解密**: 使用时自动解密
- **密钥轮换**: 支持定期更换密钥

### 内容过滤

- 自动检测敏感内容
- 防止不当内容生成
- 符合内容安全政策

## 测试

### 单元测试

```dart
test('AI服务基础测试', () async {
  final service = await AIService.initialize();
  
  // 验证API密钥
  final isValid = await service.validateApiKey(config);
  expect(isValid, true);
  
  // 发送消息
  final response = await service.sendMessage(messages);
  expect(response.content, isNotEmpty);
});
```

### 集成测试

```dart
test('AIActionHandler集成测试', () async {
  final handler = AIActionHandler(
    onResult: (action, result) {
      expect(result, isNotEmpty);
    },
    onError: (error) {
      fail('不应该有错误: $error');
    },
    aiService: aiService,
  );
  
  await handler.polish(text: '测试文本');
});
```

## 故障排除

### 常见问题

1. **API密钥无效**
   - 检查API密钥是否正确
   - 验证密钥是否已激活
   - 确认密钥有足够的权限

2. **请求超时**
   - 检查网络连接
   - 增加超时时间
   - 尝试使用更快的模型

3. **配额限制**
   - 检查API使用情况
   - 考虑升级计划
   - 实施请求限流

4. **内容过滤**
   - 调整输入内容
   - 使用更温和的提示词
   - 考虑使用不同的模型

## 未来改进

### 计划功能

- [ ] 多语言支持
- [ ] 自定义模型训练
- [ ] 批处理请求
- [ ] 更多AI提供商
- [ ] 高级缓存策略
- [ ] 性能监控

### 扩展性

- 插件化AI提供商
- 自定义适配器
- 中间件支持
- 事件系统

## 相关文件

- `lib/services/ai/ai_service.dart` - AI服务主文件
- `lib/services/ai/openai_adapter.dart` - OpenAI适配器
- `lib/services/ai/claude_adapter.dart` - Claude适配器
- `lib/features/editor/ai_action_handler.dart` - AI操作处理器
- `lib/models/ai_config.dart` - AI配置模型
- `lib/models/ai_message.dart` - AI消息模型
- `lib/models/ai_response.dart` - AI响应模型

## 总结

AI服务接口已完整实现，支持OpenAI和Claude等多种AI提供商，提供了完善的错误处理、流式响应、缓存管理和安全存储功能。用户可以通过AIActionHandler方便地使用各种AI功能，如润色、扩写、大纲生成等。
