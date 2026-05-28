# MuseFlow AI适配器接口层

完整的AI适配器接口层实现，支持多种AI供应商的统一访问。

## 功能特性

- **多供应商支持**: OpenAI、Anthropic、DeepSeek、Ollama
- **统一接口**: 一致的API调用方式
- **安全存储**: API Key加密存储（使用Flutter Secure Storage）
- **流式响应**: 支持实时流式输出
- **错误处理**: 完善的错误分类和重试机制
- **配置管理**: 灵活的配置创建和管理
- **Token估算**: 消息token数量估算

## 目录结构

```
lib/
├── models/
│   ├── ai_config.dart          # AI配置模型
│   ├── ai_message.dart          # 消息模型
│   └── ai_response.dart         # 响应模型
├── services/ai/
│   ├── ai_adapter.dart          # 基础接口定义
│   ├── openai_adapter.dart      # OpenAI适配器
│   ├── claude_adapter.dart      # Anthropic Claude适配器
│   ├── deepseek_adapter.dart    # DeepSeek适配器
│   ├── ollama_adapter.dart      # Ollama适配器
│   ├── ai_service.dart          # 统一服务层
│   ├── ai_config_manager.dart   # 配置管理工具
│   └── ai_usage_example.dart    # 使用示例
```

## 快速开始

### 1. 初始化服务

```dart
import 'package:museflow/services/ai/ai_service.dart';

final aiService = await AIService.initialize();
```

### 2. 创建配置

```dart
import 'package:museflow/services/ai/ai_config_manager.dart';

// OpenAI配置
final openaiConfig = AIConfigManager.createOpenAIConfig(
  apiKey: 'your-api-key',
  model: 'gpt-4o',
);

// Anthropic配置
final claudeConfig = AIConfigManager.createAnthropicConfig(
  apiKey: 'your-api-key',
  model: 'claude-3-5-sonnet-20241022',
);

// DeepSeek配置
final deepseekConfig = AIConfigManager.createDeepSeekConfig(
  apiKey: 'your-api-key',
  model: 'deepseek-chat',
);

// Ollama配置（本地，不需要API Key）
final ollamaConfig = AIConfigManager.createOllamaConfig(
  baseUrl: 'http://localhost:11434',
  model: 'llama3',
);
```

### 3. 发送消息

```dart
// 添加配置
await aiService.addConfig(openaiConfig);
await aiService.setActiveConfig(openaiConfig.id);

// 创建消息
final messages = [
  AIMessage.user(
    id: '1',
    content: 'What is Flutter?',
  ),
];

// 发送消息
final response = await aiService.sendMessage(messages);
print(response.content);
```

### 4. 流式响应

```dart
await for (final chunk in aiService.sendMessageStream(messages)) {
  if (!chunk.isComplete) {
    print(chunk.content, end: ''); // 实时输出
  } else {
    print('\n[Complete]');
  }
}
```

## 高级用法

### 对话历史管理

```dart
final conversation = <AIMessage>[
  AIMessage.system(id: 'system', content: 'You are a helpful assistant.'),
];

// 第一轮
conversation.add(AIMessage.user(id: '1', content: 'Hello'));
final response1 = await aiService.sendMessage(conversation);
conversation.add(AIMessage.assistant(
  id: response1.id,
  content: response1.content,
));

// 第二轮（保留上下文）
conversation.add(AIMessage.user(id: '2', content: 'How are you?'));
final response2 = await aiService.sendMessage(conversation);
```

### 配置预设

```dart
// 快速响应预设
final fastConfig = AIConfigPresets.getFastResponse(AIProvider.openai);

// 创意写作预设
final creativeConfig = AIConfigPresets.getCreativeWriting(AIProvider.anthropic);

// 代码生成预设
final codeConfig = AIConfigPresets.getCodeGeneration(AIProvider.deepseek);
```

### 错误处理

```dart
try {
  final response = await aiService.sendMessage(messages);
} on ApiKeyException {
  print('API密钥无效');
} on RateLimitException {
  print('达到速率限制');
} on NetworkException {
  print('网络连接失败');
} on TimeoutException {
  print('请求超时');
}
```

### Token估算

```dart
final messages = [
  AIMessage.user(id: '1', content: 'Your message here'),
];

final estimatedTokens = aiService.estimateTokens(messages, config);
if (estimatedTokens > config.maxTokens) {
  print('消息过长，可能超出token限制');
}
```

## 供应商特性

### OpenAI
- 支持GPT-4o、GPT-4 Turbo、GPT-3.5等模型
- 完整的流式响应支持
- 精确的token计数

### Anthropic Claude
- 支持Claude 3.5 Sonnet、Claude 3 Opus等模型
- 优秀的长文本处理能力
- 独特的API格式

### DeepSeek
- 兼容OpenAI API格式
- 专业的代码生成能力
- 高性价比

### Ollama
- 本地运行，无需网络
- 支持多种开源模型
- 完全私有化

## 安全特性

- API Key加密存储
- 使用AES-GCM加密算法
- 安全密钥管理
- 配置文件加密

## 性能优化

- 自动重试机制
- 连接池管理
- 流式响应减少延迟
- Token估算防止超限

## 配置参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `apiKey` | String | - | API密钥（Ollama不需要） |
| `baseUrl` | String? | 供应商默认 | 自定义API地址 |
| `model` | String | 供应商默认 | 模型名称 |
| `maxTokens` | int | 2048 | 最大生成token数 |
| `temperature` | double | 0.7 | 温度参数（0-2） |
| `topP` | double | 1.0 | Top-P采样（0-1） |
| `retryCount` | int? | 供应商默认 | 重试次数 |
| `timeoutSeconds` | int? | 供应商默认 | 超时时间（秒） |

## 依赖项

```yaml
dependencies:
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  encrypt: ^5.0.2
  uuid: ^4.5.1
  retry: ^3.1.2
```

## 最佳实践

1. **配置管理**: 使用`AIConfigManager`统一管理配置
2. **错误处理**: 捕获特定异常类型进行针对性处理
3. **Token控制**: 发送前估算token数量
4. **流式响应**: 长文本生成使用流式API
5. **配置预设**: 使用预设配置快速开始

## 故障排除

### API密钥问题
```dart
final isValid = await aiService.validateApiKey(config);
if (!isValid) {
  print('API密钥无效');
}
```

### 连接问题
```dart
try {
  await aiService.sendMessage(messages);
} catch (e) {
  print('连接失败: $e');
}
```

### Token限制
```dart
final tokens = aiService.estimateTokens(messages, config);
print('估算token数: $tokens');
```

## 示例代码

完整的使用示例请参考 `ai_usage_example.dart` 文件，包含：
- 基础使用
- 多供应商切换
- 流式响应
- 对话历史
- 错误处理
- 配置管理
- Token估算
- 批量处理
- 高级重试

## 许可证

MIT License
