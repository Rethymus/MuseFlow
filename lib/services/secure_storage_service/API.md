# MuseFlow 安全存储服务 API 文档

## 概述

SecureStorageService 是一个提供加密数据持久化的安全存储服务，为用户敏感数据（如笔记标题和内容）提供透明的加密/解密功能。所有数据在存储前自动加密，检索时自动解密，确保数据安全的同时提供无缝的用户体验。

### 安全特性

- **透明加密**: 所有笔记数据自动加密存储，检索时自动解密
- **批量操作**: 支持批量加密和解密，提高性能
- **数据迁移**: 自动将旧版本明文数据迁移到加密存储
- **版本管理**: 支持加密版本追踪和升级
- **安全异常处理**: 专门的安全异常处理机制

### 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    SecureStorageService                      │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │  Notes Box    │  │ Settings Box  │  │ Migration Box │    │
│  │  (加密存储)    │  │  (配置存储)    │  │  (迁移追踪)    │    │
│  └───────────────┘  └───────────────┘  └───────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    SecureDataService                         │
│                    (加密/解密服务)                             │
└─────────────────────────────────────────────────────────────┘
```

## 核心 API

### 获取实例

```dart
// 获取单例实例
SecureStorageService storage = SecureStorageService.instance;

// 或使用工厂构造函数
SecureStorageService storage = SecureStorageService();
```

### 初始化服务

```dart
// 必须在使用前调用初始化
await storage.initialize();

// 初始化过程包括:
// 1. 初始化底层加密服务
// 2. 打开Hive存储box
// 3. 检查并执行数据迁移
```

## 加密存储方法

### 保存单个笔记

```dart
// 保存笔记（自动加密）
await storage.saveNote(
  Note(
    id: 'note-id',
    title: '笔记标题',
    content: '笔记内容',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    tags: ['工作', '重要'],
  ),
);

// 内部处理流程:
// 1. 使用SecureDataService加密标题和内容
// 2. 将加密数据与元数据一起存储
// 3. 标记为已加密并记录算法
```

### 批量保存笔记

```dart
// 批量保存（性能优化）
List<Note> notes = [note1, note2, note3];
await storage.bulkSaveNotes(notes);

// 批量操作优势:
// - 一次性加密所有笔记
// - 减少加密操作次数
// - 提高大量数据导入性能
```

## 数据操作 API

### 获取所有笔记

```dart
// 获取所有笔记（自动解密）
List<Note> allNotes = await storage.getAllNotes();

// 返回的笔记内容已自动解密
for (var note in allNotes) {
  print('标题: ${note.title}');  // 明文标题
  print('内容: ${note.content}'); // 明文内容
}
```

### 搜索笔记

```dart
// 搜索笔记（基于解密后的内容）
List<Note> results = await storage.searchNotes('关键词');

// 搜索范围包括标题和内容
// 搜索不区分大小写
```

### 按标签过滤

```dart
// 按标签获取笔记
List<Note> taggedNotes = await storage.getNotesByTag('工作');

// 返回包含指定标签的所有笔记
```

### 删除笔记

```dart
// 删除单个笔记
await storage.deleteNote('note-id');

// 删除操作会移除加密数据和元数据
```

## 批量操作支持

### 导出笔记

```dart
// 导出笔记（解密格式）
List<Map<String, dynamic>> exportedNotes = await storage.exportNotes();

// 返回格式:
// [
//   {
//     'id': 'note-id',
//     'title': '明文标题',
//     'content': '明文内容',
//     'created_at': '2024-01-01T00:00:00.000Z',
//     'updated_at': '2024-01-01T00:00:00.000Z',
//     'tags': ['tag1', 'tag2']
//   }
// ]
```

### 导入笔记

```dart
// 导入笔记（自动加密）
List<Map<String, dynamic>> importData = [
  {
    'id': 'note-id',
    'title': '笔记标题',
    'content': '笔记内容',
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-01T00:00:00.000Z',
    'tags': ['tag1', 'tag2'],
  },
];

await storage.importNotes(importData);

// 导入时自动:
// 1. 生成UUID（如果缺少ID）
// 2. 加密标题和内容
// 3. 保存到加密存储
```

## 设置管理

### 获取设置

```dart
// 获取设置值
String theme = await storage.getSetting('theme', defaultValue: 'system');

// 支持的设置类型:
// - 用户偏好
// - 应用配置
// - 界面设置
```

### 保存设置

```dart
// 保存设置值
await storage.setSetting('theme', 'dark');

// 设置直接存储，不加密
```

## 数据管理

### 获取存储统计

```dart
// 获取存储统计信息
Map<String, dynamic> stats = await storage.getStorageStats();

// 返回数据:
// {
//   'total_notes': 100,           // 总笔记数
//   'settings_count': 5,          // 设置数量
//   'encryption_enabled': true,   // 加密已启用
//   'migration_completed': 'true', // 迁移完成状态
//   'encryption_version': '1'    // 加密版本
// }
```

### 清空所有数据

```dart
// 清空所有数据（谨慎使用）
await storage.clearAllData();

// 会清空:
// - 所有加密笔记
// - 所有设置
// - 迁移状态
```

## 资源管理

### 关闭服务

```dart
// 关闭服务并释放资源
await storage.close();

// 执行操作:
// 1. 关闭所有Hive boxes
// 2. 释放加密服务资源
// 3. 清理内存
```

## 数据类型

### Note

```dart
class Note {
  final String id;                    // 唯一标识符
  final String title;                 // 笔记标题（会被加密）
  final String content;               // 笔记内容（会被加密）
  final DateTime createdAt;          // 创建时间
  final DateTime updatedAt;          // 更新时间
  final List<String> tags;           // 标签列表（不加密）

  // 序列化支持
  Map<String, dynamic> toJson();
  factory Note.fromJson(Map<String, dynamic> json);
}
```

### StorageException

```dart
class StorageException implements Exception {
  final String message;              // 用户友好的错误消息
  final Object? originalError;       // 原始错误对象
  final StackTrace? stackTrace;      // 堆栈跟踪

  // 使用示例
  try {
    await storage.saveNote(note);
  } on StorageException catch (e) {
    print('存储错误: ${e.message}');
    print('原始错误: ${e.originalError}');
  }
}
```

### SecurityException

```dart
// 由SecureDataService抛出的安全异常
// 会被SecureStorageService捕获并转换为StorageException
```

## 使用场景

### 场景1: 基本笔记管理

```dart
// 1. 初始化服务
final storage = SecureStorageService.instance;
await storage.initialize();

// 2. 创建并保存笔记
final note = Note(
  id: const Uuid().v4(),
  title: '我的第一篇笔记',
  content: '这是一篇加密存储的笔记内容',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  tags: ['个人', '日记'],
);
await storage.saveNote(note);

// 3. 读取笔记（自动解密）
final allNotes = await storage.getAllNotes();
print('标题: ${allNotes.first.title}'); // 明文显示

// 4. 完成后关闭
await storage.close();
```

### 场景2: 搜索和过滤

```dart
// 1. 添加多个笔记
await storage.saveNote(note1);  // 标题: "项目计划"
await storage.saveNote(note2);  // 标题: "会议记录"
await storage.saveNote(note3);  // 标题: "项目总结"

// 2. 搜索笔记（基于解密内容）
final results = await storage.searchNotes('项目');
// 返回 note1 和 note3

// 3. 按标签过滤
final tagged = await storage.getNotesByTag('工作');
// 返回所有包含"工作"标签的笔记
```

### 场景3: 批量导入导出

```dart
// 1. 导出笔记（用于备份）
final exportedNotes = await storage.exportNotes();

// 2. 保存到文件
final json = jsonEncode(exportedNotes);
File('backup.json').writeAsStringSync(json);

// 3. 从备份恢复
final backupData = jsonDecode(File('backup.json').readAsStringSync());
await storage.importNotes(List<Map<String, dynamic>>.from(
  backupData.map((item) => item as Map<String, dynamic>)
));
```

### 场景4: 设置管理

```dart
// 1. 保存用户偏好
await storage.setSetting('theme', 'dark');
await storage.setSetting('language', 'zh-CN');
await storage.setSetting('auto_save', 'true');

// 2. 读取设置
final theme = await storage.getSetting('theme', defaultValue: 'light');
final language = await storage.getSetting('language', defaultValue: 'en');

// 3. 应用设置
applyTheme(theme);
applyLanguage(language);
```

### 场景5: 错误处理

```dart
try {
  // 尝试保存笔记
  await storage.saveNote(note);
} on StorageException catch (e) {
  // 处理存储异常
  print('存储失败: ${e.message}');

  if (e.originalError != null) {
    print('技术详情: ${e.originalError}');
  }

  // 显示用户友好的错误提示
  showErrorDialog(e.message);
} catch (e) {
  // 处理其他异常
  print('未知错误: $e');
}
```

## 性能考虑

### 时间复杂度

| 操作 | 复杂度 | 说明 |
|------|--------|------|
| saveNote | O(1) | 加密并保存单个笔记 |
| bulkSaveNotes | O(n) | 批量加密并保存n个笔记 |
| getAllNotes | O(n) | 解密并返回所有笔记 |
| searchNotes | O(n) | 解密并搜索所有笔记 |
| getNotesByTag | O(n) | 过滤并返回匹配笔记 |
| deleteNote | O(1) | 删除单个笔记 |
| exportNotes | O(n) | 解密并导出所有笔记 |
| importNotes | O(n) | 加密并导入所有笔记 |

### 空间复杂度

| 组件 | 空间复杂度 | 说明 |
|------|-----------|------|
| Notes Box | O(n) | n为笔记数量，每个笔记包含加密数据 |
| Settings Box | O(1) | 固定数量的设置项 |
| Migration Box | O(1) | 只存储迁移状态 |

### 优化建议

1. **批量操作**: 使用`bulkSaveNotes`代替多次调用`saveNote`
2. **限制结果**: 搜索前可以先按标签过滤减少数据量
3. **定期清理**: 定期清理不需要的笔记减少存储空间
4. **异步处理**: 所有操作都是异步的，可以在后台执行
5. **内存管理**: 使用完毕后及时调用`close()`释放资源

## 错误处理

### 错误类型

```dart
// 1. SecurityException - 加密/解密失败
try {
  await storage.saveNote(note);
} on SecurityException catch (e) {
  // 由SecureDataService抛出
  print('加密失败: ${e.message}');
}

// 2. StorageException - 存储操作失败
try {
  await storage.getAllNotes();
} on StorageException catch (e) {
  // 用户友好的错误消息
  print('存储错误: ${e.message}');
  print('原始错误: ${e.originalError}');
}

// 3. 通用异常
try {
  await storage.initialize();
} catch (e) {
  // 其他未预期的错误
  print('初始化失败: $e');
}
```

### 常见错误场景

```dart
// 1. 数据迁移失败
// - 自动记录日志
// - 不中断应用启动
// - 用户可重试

// 2. 加密密钥不匹配
// - 抛出SecurityException
// - 转换为StorageException
// - 提示用户重启应用

// 3. 数据损坏
// - 记录详细错误日志
// - 返回友好错误消息
// - 建议联系支持
```

## 安全最佳实践

### 数据安全

1. **自动加密**: 所有笔记数据自动加密，无需手动操作
2. **透明解密**: 读取时自动解密，对应用透明
3. **密钥管理**: 加密密钥由SecureDataService统一管理
4. **算法追踪**: 记录使用的加密算法便于升级

### 异常处理

1. **详细日志**: 所有安全错误都记录详细日志
2. **友好消息**: 向用户显示友好的错误消息
3. **原始错误**: 保留原始错误便于调试
4. **优雅降级**: 非关键错误不影响应用运行

### 数据迁移

1. **自动检测**: 启动时自动检测是否需要迁移
2. **批量处理**: 一次性迁移所有历史数据
3. **状态追踪**: 记录迁移状态避免重复
4. **版本管理**: 支持加密版本升级

### 开发建议

1. **异常处理**: 始终使用try-catch包裹存储操作
2. **资源管理**: 使用完毕后调用close()释放资源
3. **错误日志**: 记录StorageException的originalError
4. **用户反馈**: 向用户显示友好的错误消息
5. **性能监控**: 使用getStorageStats()监控存储状态

## 迁移指南

### 从明文存储迁移

```dart
// SecureStorageService会自动检测并迁移旧数据
// 迁移过程:
// 1. 检测legacy notes box
// 2. 读取所有明文笔记
// 3. 加密并保存到新box
// 4. 清空旧box
// 5. 标记迁移完成

// 迁移状态查询
final stats = await storage.getStorageStats();
if (stats['migration_completed'] == 'true') {
  print('数据已迁移到加密存储');
}
```

### 加密版本升级

```dart
// 当加密算法升级时:
// 1. 增加_currentEncryptionVersion
// 2. 实现新的迁移逻辑
// 3. 重新加密所有数据
// 4. 更新版本号

// 检查加密版本
final stats = await storage.getStorageStats();
final version = stats['encryption_version'];
print('当前加密版本: $version');
```

## 测试建议

### 单元测试

```dart
// 测试加密存储
test('save and retrieve encrypted note', () async {
  final storage = SecureStorageService.instance;
  await storage.initialize();

  final note = Note(
    id: 'test-id',
    title: 'Test Title',
    content: 'Test Content',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    tags: [],
  );

  await storage.saveNote(note);
  final retrieved = await storage.getAllNotes();

  expect(retrieved.first.title, equals(note.title));
  expect(retrieved.first.content, equals(note.content));
});

// 测试错误处理
test('handle storage exception', () async {
  try {
    await storage.saveNote(invalidNote);
    fail('Should throw StorageException');
  } on StorageException catch (e) {
    expect(e.message, isNotEmpty);
  }
});
```

### 集成测试

```dart
// 测试批量操作
test('bulk save and export notes', () async {
  final notes = List.generate(100, (i) => Note(
    id: 'note-$i',
    title: 'Title $i',
    content: 'Content $i',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    tags: [],
  ));

  await storage.bulkSaveNotes(notes);
  final exported = await storage.exportNotes();

  expect(exported.length, equals(100));
});

// 测试搜索功能
test('search encrypted notes', () async {
  await storage.saveNote(note1); // 标题: "Hello World"
  await storage.saveNote(note2); // 标题: "Goodbye"

  final results = await storage.searchNotes('hello');
  expect(results.length, equals(1));
  expect(results.first.title, contains('Hello'));
});
```

## 注意事项

1. **初始化要求**: 必须调用`initialize()`后才能使用其他方法
2. **单例模式**: 使用`instance`获取单例，不要创建多个实例
3. **资源释放**: 使用完毕后调用`close()`释放资源
4. **异常处理**: 所有方法都可能抛出`StorageException`
5. **数据迁移**: 首次启动会自动迁移旧数据，可能需要额外时间
6. **加密透明**: 加密/解密对应用透明，但数据在存储时是加密的
7. **设置不加密**: 设置值不加密，不要存储敏感信息
8. **批量性能**: 大量数据使用批量操作提高性能

## 相关服务

- **SecureDataService**: 底层加密/解密服务
- **ContextManager**: 上下文管理服务
- **Logger**: 日志记录服务
- **AppState**: 应用状态管理
