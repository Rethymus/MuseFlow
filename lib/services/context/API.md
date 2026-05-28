# MuseFlow 上下文管理系统 API 文档

## 核心 API

### ContextManager

#### 获取实例

```dart
// 获取单例实例
ContextManager manager = ContextManager.getInstance();

// 使用自定义配置
ContextManager manager = ContextManager.getInstance(
  const ContextManagerConfig(
    maxTokens: 16000,
    enableSlidingWindow: true,
  ),
);

// 重置单例（主要用于测试）
ContextManager.reset();
```

#### 添加上下文片段

```dart
// 添加基本片段
String id = manager.addSegment(
  type: SegmentType.userMessage,
  content: '用户消息内容',
);

// 添加带重要性的片段
String id = manager.addSegment(
  type: SegmentType.systemPrompt,
  content: '系统提示内容',
  importanceScore: 0.9,
);

// 添加锁定的片段（不会被裁剪）
String id = manager.addSegment(
  type: SegmentType.systemPrompt,
  content: '重要的系统提示',
  isLocked: true,
);

// 添加带元数据的片段
String id = manager.addSegment(
  type: SegmentType.userMessage,
  content: '用户消息',
  metadata: {
    'userId': 'user123',
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// 添加预构建的片段
manager.addSegmentDirectly(segment);
```

#### 查询片段

```dart
// 获取单个片段
ContextSegment? segment = manager.getSegment('segment-id');

// 获取所有片段
List<ContextSegment> all = manager.getAllSegments();

// 按类型获取片段
List<ContextSegment> userMessages = manager.getSegmentsByType(SegmentType.userMessage);

// 搜索片段
List<ContextSegment> results = manager.search('关键词');

// 获取最近N个片段
List<ContextSegment> recent = manager.getRecentSegments(10);
```

#### 更新片段

```dart
// 更新片段内容
bool updated = manager.updateSegment('segment-id',
  content: '新的内容',
);

// 更新多个属性
bool updated = manager.updateSegment('segment-id',
  content: '新内容',
  importanceScore: 0.8,
  isLocked: true,
  metadata: {'key': 'value'},
);
```

#### 删除片段

```dart
// 删除单个片段
bool removed = manager.removeSegment('segment-id');

// 清空所有上下文
manager.clear();
```

#### 获取格式化上下文

```dart
// 获取基本格式化上下文
String context = manager.getFormattedContext();

// 包含元数据的格式化
String context = manager.getFormattedContext(
  includeMetadata: true,
);

// 自定义分隔符
String context = manager.getFormattedContext(
  separator: '\n---\n',
);

// 不包含摘要
String context = manager.getFormattedContext(
  includeSummaries: false,
);
```

#### 统计信息

```dart
// 获取统计信息
ContextStats stats = manager.getStats();

// 访问统计数据
print('总片段数: ${stats.totalSegments}');
print('总token数: ${stats.totalTokens}');
print('用户消息数: ${stats.userMessages}');
print('系统响应数: ${stats.systemResponses}');
print('工具调用数: ${stats.toolCalls}');
print('缓存片段数: ${stats.cachedSegments}');
print('摘要片段数: ${stats.summarySegments}');
print('平均重要性: ${stats.averageImportance}');
print('缓存使用率: ${stats.cacheUsageRate}');
print('摘要比例: ${stats.summaryRatio}');
```

#### 监听变化

```dart
// 监听上下文变化
StreamSubscription subscription = manager.onChange.listen((change) {
  switch (change.type) {
    case ChangeType.added:
      print('片段已添加: ${change.segmentId}');
      break;
    case ChangeType.removed:
      print('片段已移除: ${change.segmentId}');
      break;
    case ChangeType.updated:
      print('片段已更新: ${change.segmentId}');
      break;
    case ChangeType.cleared:
      print('上下文已清空');
      break;
  }
});

// 取消订阅
await subscription.cancel();
```

#### 资源释放

```dart
// 释放资源
manager.dispose();

// 重置管理器
ContextManager.reset();
```

## 数据类型

### SegmentType

```dart
enum SegmentType {
  userMessage,      // 用户消息
  systemResponse,   // 系统响应
  systemPrompt,     // 系统提示
  toolCall,         // 工具调用
  toolResult,       // 工具结果
  metadata,         // 元数据
}
```

### ContextSegment

```dart
class ContextSegment {
  final String id;                          // 唯一标识符
  final SegmentType type;                   // 片段类型
  final String content;                      // 内容文本
  final DateTime createdAt;                  // 创建时间
  final double importanceScore;              // 重要性评分 (0.0-1.0)
  final int estimatedTokens;                 // 估算的token数量
  final bool isLocked;                       // 是否被锁定
  final Map<String, dynamic> metadata;       // 元数据
  final String? summary;                     // 摘要
  final bool isSummary;                      // 是否为摘要

  // 创建摘要版本
  ContextSegment asSummary(String summary);

  // 计算相似度
  double similarityWith(ContextSegment other);

  // 创建副本
  ContextSegment copyWith({...});

  // 序列化
  Map<String, dynamic> toJson();
  factory ContextSegment.fromJson(Map<String, dynamic> json);
}
```

### ContextManagerConfig

```dart
class ContextManagerConfig {
  final int maxTokens;                      // 最大token数
  final bool enableSlidingWindow;           // 启用滑动窗口
  final bool enableImportanceScoring;       // 启用重要性评分
  final bool enableSummarization;           // 启用智能摘要
  final bool keepSummaryAtStart;           // 摘要保持在开头
  final int windowSize;                     // 上下文窗口大小
}
```

### CacheConfig

```dart
class CacheConfig {
  final int maxTokens;                      // 缓存最大token数
  final double trimThreshold;               // 裁剪阈值
  final double retainRatio;                 // 保留比例
  final int minTokens;                      // 最小保留token数
  final bool enableSummarization;           // 启用摘要
  final int summaryTargetLength;            // 摘要目标长度

  // 预设配置
  static const defaultConfig = CacheConfig();
  static const compactConfig = CacheConfig(...);  // 紧凑配置
  static const spaciousConfig = CacheConfig(...); // 宽松配置
}
```

### ContextStats

```dart
class ContextStats {
  final int totalSegments;                  // 总片段数
  final int totalTokens;                    // 总token数
  final int userMessages;                   // 用户消息数
  final int systemResponses;                // 系统响应数
  final int toolCalls;                      // 工具调用数
  final int cachedSegments;                // 缓存片段数
  final int summarySegments;                // 摘要片段数
  final double averageImportance;           // 平均重要性

  // 计算属性
  double get cacheUsageRate;                // 缓存使用率
  double get summaryRatio;                  // 摘要比例

  // 序列化
  Map<String, dynamic> toJson();
}
```

### ContextChange

```dart
class ContextChange {
  final ChangeType type;                    // 变化类型
  final String segmentId;                   // 片段ID
  final DateTime timestamp;                 // 时间戳
}
```

### ChangeType

```dart
enum ChangeType {
  added,                                    // 已添加
  removed,                                  // 已移除
  updated,                                  // 已更新
  cleared,                                  // 已清空
}
```

## 使用场景

### 场景1: 简单对话管理

```dart
// 1. 初始化管理器
final manager = ContextManager.getInstance();

// 2. 添加对话
manager.addSegment(
  type: SegmentType.userMessage,
  content: '你好',
);

manager.addSegment(
  type: SegmentType.systemResponse,
  content: '你好！有什么可以帮助你的吗？',
);

// 3. 获取格式化上下文
final context = manager.getFormattedContext();
```

### 场景2: 长对话管理

```dart
// 1. 配置滑动窗口
final manager = ContextManager.getInstance(
  const ContextManagerConfig(
    maxTokens: 16000,
    enableSlidingWindow: true,
    enableSummarization: true,
  ),
);

// 2. 添加系统提示（锁定）
manager.addSegment(
  type: SegmentType.systemPrompt,
  content: '你是一个专业的写作助手',
  isLocked: true,
);

// 3. 处理长对话
for (var message in longConversation) {
  manager.addSegment(
    type: message.isUser ? SegmentType.userMessage : SegmentType.systemResponse,
    content: message.content,
  );

  // 自动管理上下文大小
  if (manager.getStats().totalTokens > 15000) {
    print('上下文已自动裁剪');
  }
}
```

### 场景3: 上下文搜索

```dart
// 1. 添加带元数据的片段
manager.addSegment(
  type: SegmentType.userMessage,
  content: '我喜欢写科幻小说',
  metadata: {'category': 'writing', 'genre': 'scifi'},
);

// 2. 搜索内容
final results = manager.search('科幻');
for (final result in results) {
  print('找到: ${result.content}');
  print('元数据: ${result.metadata}');
}
```

### 场景4: 监听变化

```dart
// 1. 监听上下文变化
manager.onChange.listen((change) {
  if (change.type == ChangeType.added) {
    final segment = manager.getSegment(change.segmentId);
    print('新片段: ${segment?.content}');
  }
});

// 2. 添加片段（会触发事件）
manager.addSegment(
  type: SegmentType.userMessage,
  content: '测试消息',
);
```

### 场景5: 资源管理

```dart
try {
  // 1. 使用管理器
  final manager = ContextManager.getInstance();

  // 2. 执行操作
  manager.addSegment(...);

  // 3. 使用完毕后释放资源
  manager.dispose();
} finally {
  // 4. 确保重置
  ContextManager.reset();
}
```

## 性能考虑

### 时间复杂度

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| addSegment | O(1) | 添加片段 |
| getSegment | O(1) | 获取单个片段 |
| getAllSegments | O(n) | 获取所有片段 |
| search | O(n) | 搜索内容 |
| updateSegment | O(1) | 更新片段 |
| removeSegment | O(1) | 删除片段 |
| getFormattedContext | O(n) | 格式化上下文 |

### 空间复杂度

| 组件 | 空间复杂度 | 说明 |
|------|-----------|------|
| ContextCache | O(n) | n为片段数量 |
| ContextManager | O(n) | 包括缓存和队列 |
| ContextSegment | O(1) | 单个片段 |

### 优化建议

1. **限制片段数量**: 设置合理的maxTokens
2. **启用摘要**: 对长对话启用summary
3. **锁定重要内容**: 防止重要内容被裁剪
4. **定期清理**: 定期调用clear()释放内存
5. **批量操作**: 使用addSegmentDirectly批量添加

## 错误处理

### 常见错误

```dart
// 1. 片段不存在
final segment = manager.getSegment('non-existent');
if (segment == null) {
  print('片段不存在');
}

// 2. 更新失败
final updated = manager.updateSegment('non-existent',
  content: 'new content',
);
if (!updated) {
  print('更新失败');
}

// 3. 资源释放
try {
  manager.dispose();
} catch (e) {
  print('释放资源时出错: $e');
}
```

## 扩展接口

### 自定义评分策略

```dart
// 扩展ContextManager以实现自定义评分
class CustomContextManager extends ContextManager {
  @override
  double _calculateImportance(ContextSegment segment) {
    // 实现自定义评分逻辑
    double score = super._calculateImportance(segment);

    // 添加自定义因素
    if (segment.metadata.containsKey('priority')) {
      score *= segment.metadata['priority'];
    }

    return score.clamp(0.0, 1.0);
  }
}
```

### 自定义摘要算法

```dart
// 扩展ContextManager以实现AI摘要
class AISummaryContextManager extends ContextManager {
  @override
  String _createSummary(ContextSegment segment) {
    // 调用AI服务生成摘要
    return aiService.summarize(segment.content);
  }
}
```

### 持久化存储

```dart
// 扩展ContextManager以支持持久化
class PersistentContextManager extends ContextManager {
  void saveToStorage() {
    final segments = getAllSegments();
    final json = segments.map((s) => s.toJson()).toList();
    storage.save('context.json', json);
  }

  void loadFromStorage() {
    final json = storage.load('context.json');
    for (final item in json) {
      addSegmentDirectly(ContextSegment.fromJson(item));
    }
  }
}
```

## 最佳实践

1. **使用单例**: 通过getInstance()获取实例
2. **合理配置**: 根据应用场景设置合适的配置
3. **利用元数据**: 使用元数据存储额外信息
4. **监听变化**: 订阅onChange事件以响应状态变化
5. **及时释放**: 使用完毕后调用dispose()
6. **错误处理**: 检查返回值，处理错误情况
7. **性能监控**: 使用getStats()监控系统状态
8. **线程安全**: 注意Dart的单线程特性
