# MuseFlow 上下文管理系统

## 概述

MuseFlow的上下文管理系统是一个高性能、线程安全的对话历史管理解决方案，专为AI写作助手设计。系统采用滑动窗口策略、重要性评分和智能摘要技术，有效管理长对话历史。

## 核心特性

### 1. 滑动窗口管理
- **动态裁剪**: 当上下文超过设定限制时，自动裁剪最不重要的内容
- **智能保留**: 优先保留高重要性内容和锁定片段
- **平滑过渡**: 裁剪过程透明，不影响用户体验

### 2. 重要性评分
- **自动评分**: 根据片段类型、长度、内容自动计算重要性(0.0-1.0)
- **类型权重**: 系统提示 > 用户消息 > 工具调用 > 系统响应 > 元数据
- **长度调整**: 避免过长内容占用过多资源

### 3. Token估算
- **中文优化**: 约1.5字/token
- **英文支持**: 约4字符/token
- **混合文本**: 智能识别中英文混合内容

### 4. 智能摘要
- **自动摘要**: 对裁剪的长内容创建简短摘要
- **关键句提取**: 保留开头、结尾的关键句
- **可配置**: 可开关摘要功能或调整摘要长度

### 5. 分段存储
- **类型分类**: 支持多种片段类型(消息、响应、工具等)
- **元数据支持**: 每个片段可携带自定义元数据
- **快速查询**: 按类型、时间、重要性快速检索

## 架构设计

### 三层架构

```
┌─────────────────────────────────────┐
│     ContextManager (管理层)         │
│  - 单例模式                         │
│  - 配置管理                         │
│  - 业务逻辑                         │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│     ContextCache (缓存层)            │
│  - LRU策略                          │
│  - 快速查找                         │
│  - 统计信息                         │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│   ContextSegment (数据层)            │
│  - 数据模型                         │
│  - Token估算                        │
│  - 序列化支持                       │
└─────────────────────────────────────┘
```

### 核心组件

#### 1. ContextManager
**职责**: 核心管理器，协调各组件工作
- 实现单例模式，确保全局唯一实例
- 提供统一的API接口
- 管理上下文变化通知
- 实现业务逻辑(裁剪、评分、摘要)

#### 2. ContextCache
**职责**: 缓存管理，优化访问性能
- 实现LRU缓存策略
- 提供O(1)查找复杂度
- 维护访问统计信息
- 自动执行缓存裁剪

#### 3. ContextSegment
**职责**: 数据模型，封装上下文片段
- 表示对话中的单个片段
- 提供Token估算功能
- 支持相似度计算
- 可序列化为JSON

## 使用指南

### 基础使用

```dart
import 'package:museflow/services/context/context_services.dart';

// 获取管理器实例
final manager = ContextManager.getInstance();

// 添加片段
final id = manager.addSegment(
  type: SegmentType.userMessage,
  content: '你好，我想写一篇文章',
);

// 获取片段
final segment = manager.getSegment(id);

// 获取格式化上下文
final context = manager.getFormattedContext();
```

### 高级配置

```dart
// 自定义配置
final manager = ContextManager.getInstance(
  const ContextManagerConfig(
    maxTokens: 16000,                    // 最大token数
    enableSlidingWindow: true,          // 启用滑动窗口
    enableImportanceScoring: true,      // 启用重要性评分
    enableSummarization: true,          // 启用智能摘要
    keepSummaryAtStart: true,          // 摘要保持在开头
    windowSize: 20,                    // 窗口大小
  ),
);
```

### 监听变化

```dart
// 监听上下文变化
final subscription = manager.onChange.listen((change) {
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

// 使用完毕后取消订阅
await subscription.cancel();
```

### 搜索和查询

```dart
// 搜索内容
final results = manager.search('人工智能');

// 按类型查询
final userMessages = manager.getSegmentsByType(SegmentType.userMessage);

// 获取最近消息
final recent = manager.getRecentSegments(5);

// 获取统计信息
final stats = manager.getStats();
print('总片段数: ${stats.totalSegments}');
print('总token数: ${stats.totalTokens}');
print('平均重要性: ${stats.averageImportance}');
```

### 锁定重要内容

```dart
// 锁定系统提示，防止被裁剪
manager.addSegment(
  type: SegmentType.systemPrompt,
  content: '你是一个专业的写作助手',
  isLocked: true,  // 锁定
);
```

## 性能优化

### 内存优化
- **智能裁剪**: 自动移除低重要性内容
- **摘要压缩**: 长内容压缩为简短摘要
- **LRU缓存**: 只保留最近使用的内容

### 查询优化
- **哈希查找**: O(1)片段查找
- **双向链表**: 高效的LRU操作
- **类型索引**: 快速按类型查询

### 线程安全
- **单例模式**: 确保全局唯一实例
- **状态同步**: 内置同步机制
- **原子操作**: 关键操作保证原子性

## 配置参数说明

### ContextManagerConfig

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| maxTokens | int | 8000 | 最大token数量限制 |
| enableSlidingWindow | bool | true | 是否启用滑动窗口 |
| enableImportanceScoring | bool | true | 是否启用重要性评分 |
| enableSummarization | bool | true | 是否启用智能摘要 |
| keepSummaryAtStart | bool | true | 摘要是否保持在开头 |
| windowSize | int | 20 | 上下文窗口大小 |

### CacheConfig

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| maxTokens | int | 8000 | 缓存最大token数 |
| trimThreshold | double | 0.9 | 裁剪阈值(比例) |
| retainRatio | double | 0.7 | 保留比例 |
| minTokens | int | 1000 | 最小保留token数 |
| enableSummarization | bool | true | 是否启用摘要 |
| summaryTargetLength | int | 200 | 摘要目标长度 |

## 测试

系统包含完整的单元测试，覆盖所有核心功能：

```bash
# 运行测试
flutter test test/services/context/
```

测试覆盖：
- ContextSegment测试
- ContextCache测试
- ContextManager测试
- 滑动窗口测试
- 重要性评分测试
- 线程安全测试

## 最佳实践

1. **合理设置限制**: 根据应用场景设置合适的maxTokens
2. **锁定重要内容**: 系统提示等关键内容应锁定
3. **利用元数据**: 使用元数据存储额外信息，便于检索
4. **监听变化**: 订阅onChange事件以响应上下文变化
5. **定期检查统计**: 使用getStats()监控系统状态
6. **适当使用摘要**: 对长对话启用摘要功能
7. **及时释放资源**: 使用完毕后调用dispose()

## 扩展性

系统设计支持以下扩展：

### 自定义评分策略
```dart
// 可以扩展_calculateImportance方法
// 实现更复杂的评分算法
```

### 自定义摘要算法
```dart
// 可以扩展_createSummary方法
// 实现AI驱动的智能摘要
```

### 持久化存储
```dart
// 利用ContextSegment的序列化功能
// 实现上下文的持久化存储
```

### 分布式支持
```dart
// 可以扩展为支持分布式缓存
// 实现多实例间上下文共享
```

## 注意事项

1. **单例模式**: ContextManager是单例，重置需调用reset()
2. **资源释放**: 使用完毕后应调用dispose()释放资源
3. **线程安全**: 虽然Dart是单线程，但API设计考虑了多线程场景
4. **Token估算**: Token估算是近似的，实际使用时需考虑模型差异
5. **摘要质量**: 当前摘要算法较简单，可根据需要升级为AI摘要

## 版本历史

- **1.0.0** (2026-05-28)
  - 初始版本发布
  - 实现核心上下文管理功能
  - 支持滑动窗口、重要性评分、智能摘要
