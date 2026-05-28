# AI适配器接口层 - 快速开始指南

## 安装依赖

```bash
flutter pub get
```

## 基础使用（3步开始）

### 1. 导入模块

```dart
import 'package:museflow/services/ai/ai.dart';
```

### 2. 创建并发送消息

```dart
// 初始化服务
final aiService = await AIService.initialize();

// 创建配置（只需一次）
final config = AIConfigManager.createOpenAIConfig(
  apiKey: 'your-api-key-here',
);

await aiService.addConfig(config);
await aiService.setActiveConfig(config.id);

// 发送消息
final messages = [
  AIMessage.user(id: '1', content: 'Hello, AI!'),
];

final response = await aiService.sendMessage(messages);
print(response.content);
```

## 快速示例

### 使用不同的AI供应商

```dart
// OpenAI
final openai = AIConfigManager.createOpenAIConfig(
  apiKey: 'sk-...',
  model: 'gpt-4o',
);

// Claude
final claude = AIConfigManager.createAnthropicConfig(
  apiKey: 'sk-ant-...',
  model: 'claude-3-5-sonnet-20241022',
);

// DeepSeek
final deepseek = AIConfigManager.createDeepSeekConfig(
  apiKey: 'sk-...',
  model: 'deepseek-chat',
);

// Ollama (本地，免费)
final ollama = AIConfigManager.createOllamaConfig(
  model: 'llama3',
);
```

### 流式响应（实时显示）

```dart
await for (final chunk in aiService.sendMessageStream(messages)) {
  if (!chunk.isComplete) {
    print(chunk.content, end: ''); // 逐字显示
  }
}
```

### 对话历史（上下文记忆）

```dart
final conversation = <AIMessage>[
  AIMessage.system(id: '0', content: '你是友好的助手'),
];

conversation.add(AIMessage.user(id: '1', content: '你好'));
final response = await aiService.sendMessage(conversation);

conversation.add(AIMessage.assistant(
  id: response.id,
  content: response.content,
));

conversation.add(AIMessage.user(id: '2', content: '我叫什么？'));
// AI会记得之前的对话
```

## 配置预设（快速优化）

```dart
// 快速回复（温度低，简洁）
final fast = AIConfigPresets.getFastResponse(AIProvider.openai);

// 创意写作（温度高，有创意）
final creative = AIConfigPresets.getCreativeWriting(AIProvider.anthropic);

// 代码生成（专为编程优化）
final coding = AIConfigPresets.getCodeGeneration(AIProvider.deepseek);
```

## 错误处理

```dart
try {
  await aiService.sendMessage(messages);
} on ApiKeyException {
  print('请检查API密钥');
} on RateLimitException {
  print('请求过快，请稍后再试');
} on NetworkException {
  print('网络连接失败');
}
```

## 常见问题

**Q: 如何获取API密钥？**
- OpenAI: platform.openai.com
- Anthropic: console.anthropic.com
- DeepSeek: platform.deepseek.com
- Ollama: ollama.com (本地免费)

**Q: Token是什么？**
- Token是AI处理文本的单位
- 大约1个Token = 4个字符（英文）
- 估算token数：`aiService.estimateTokens(messages, config)`

**Q: 如何优化成本？**
- 使用更小的模型（如gpt-4o-mini）
- 降低maxTokens限制
- 使用流式响应（避免重复请求）

**Q: 支持哪些模型？**
- OpenAI: gpt-4o, gpt-4-turbo, gpt-3.5-turbo
- Anthropic: claude-3-5-sonnet, claude-3-opus
- DeepSeek: deepseek-chat, deepseek-coder
- Ollama: llama3, mistral, codellama等

## 下一步

查看完整文档：
- 详细文档：`README.md`
- 使用示例：`ai_usage_example.dart`
- 测试代码：`test/services/ai/ai_service_test.dart`
