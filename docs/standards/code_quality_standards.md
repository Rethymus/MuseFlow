---
name: code-quality-standards
description: 代码质量和编写规范要求
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 722bc612-8d9f-4032-b1be-353134450a76
---

# 代码质量标准

## 为什么重要

代码质量直接影响项目的可维护性、可扩展性和团队协作效率。MuseFlow作为行业顶尖产品，必须保持高标准的代码质量。

## 编码规范

### Dart语言规范

遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 指南：

1. **命名规范**
   - 类名: UpperCamelCase (例: `UserService`)
   - 变量/方法: lowerCamelCase (例: `userName`, `getUserData()`)
   - 常量: lowerCamelCase (例: `maxFileSize`)
   - 私有成员: 前缀下划线 (例: `_internalMethod`)

2. **文件组织**
   ```dart
   // 1. 导入语句（分组并排序）
   import 'dart:io';
   import 'package:flutter/material.dart';
   import 'package:museflow/models/user.dart';
   
   // 2. 类文档注释
   /// 用户服务类
   ///
   /// 提供用户相关的业务逻辑处理
   class UserService {
     // 3. 静态常量
     static const int maxCacheSize = 100;
     
     // 4. 私有变量
     final _cache = <String, User>{};
     
     // 5. 构造函数
     UserService();
     
     // 6. 公共方法
     Future<User> getUser(String id) async {
       // 实现
     }
     
     // 7. 私有方法
     void _updateCache(User user) {
       // 实现
     }
   }
   ```

3. **注释规范**
   - 公共API必须有文档注释
   - 复杂逻辑必须添加解释注释
   - 不要注释显而易见的代码

### 代码组织原则

1. **文件大小**: 单文件不超过500行（特殊情况除外）
2. **方法长度**: 单方法不超过50行
3. **参数数量**: 不超过5个参数（使用对象封装）
4. **嵌套层级**: 不超过3层

## 错误处理标准

### 完整的异常处理

```dart
// ✅ 正确：完整的错误处理
Future<void> saveUserData(User user) async {
  try {
    await _storageService.save(user);
    Logger.info('User data saved successfully');
  } on StorageException catch (e) {
    Logger.error('Storage error: ${e.message}');
    rethrow;
  } catch (e) {
    Logger.error('Unexpected error: $e');
    throw UserException('Failed to save user data');
  }
}

// ❌ 错误：缺少错误处理
Future<void> saveUserData(User user) async {
  await _storageService.save(user); // 可能抛出未捕获的异常
}
```

## 性能标准

### 关键性能指标

| 操作 | 目标 | 当前 |
|------|------|------|
| 应用启动 | <1.5s | ~1.2s |
| AI响应 | <3s | ~2s |
| 搜索查询 | <150ms | ~100ms |
| 页面切换 | <100ms | ~50ms |

### 性能优化原则

1. **使用const构造函数**
   ```dart
   // ✅ 正确
   const Text('Hello');
   const SizedBox(height: 16);
   
   // ❌ 错误
   Text('Hello'); // 每次都创建新实例
   ```

2. **避免不必要的rebuild**
   ```dart
   // ✅ 正确：使用Builder分离
   Widget build(BuildContext context) {
     return ListView.builder(
       itemBuilder: (context, index) {
         return Builder(
           builder: (context) => _buildItem(index),
         );
       },
     );
   }
   ```

3. **合理使用缓存**
   ```dart
   // ✅ 正确：缓存计算结果
   String _cachedResult;
   
   String getExpensiveResult() {
     return _cachedResult ??= _computeResult();
   }
   ```

## 测试要求

### 测试覆盖

- 公共API必须有单元测试
- 关键业务逻辑必须有集成测试
- UI组件必须有widget测试

### 测试命名

```dart
// 格式: test('描述_条件_预期', () {});
test('getUserData_WhenUserExists_ReturnsUser', () {
  // Arrange
  final service = UserService();
  
  // Act
  final result = service.getUser('123');
  
  // Assert
  expect(result, isNotNull);
});
```

## 依赖管理

### 添加依赖的原则

1. **评估必要性**: 是否真的需要这个依赖
2. **检查维护状态**: 最后更新时间、issue数量
3. **考虑替代方案**: 是否可以用现有代码实现
4. **版本管理**: 使用稳定的版本号

### 依赖审查

定期运行：
```bash
flutter pub upgrade
flutter pub deps
```

## 安全规范

### 敏感信息处理

```dart
// ❌ 错误：硬编码敏感信息
const apiKey = 'sk-1234567890abcdef';

// ✅ 正确：使用环境变量或安全存储
final apiKey = await _secureConfig.getApiKey();
```

### 输入验证

```dart
// ✅ 正确：验证用户输入
void processInput(String input) {
  if (input.isEmpty || input.length > maxLength) {
    throw ValidationException('Invalid input');
  }
  // 处理逻辑...
}
```

## 代码审查检查清单

提交代码前确认：
- [ ] 代码符合命名规范
- [ ] 公共API有文档注释
- [ ] 有完整的错误处理
- [ ] 没有硬编码的敏感信息
- [ ] 性能影响已评估
- [ ] 有相应的测试
- [ ] Commit消息符合规范
