# Flutter/Dart 编码标准

## 不可变性（强制）

```dart
// ✅ 正确
User updateUser(User user, String name) => user.copyWith(name: name);

// ❌ 错误
void updateUser(User user, String name) { user.name = name; }
```

## Widget 规范

- 使用 `const` 构造函数
- 单个 Widget < 300 行，最大 500 行
- 使用 `ConsumerWidget` / `ConsumerStatefulWidget`
- 状态读取用 `ref.watch`，操作用 `ref.read`

## Riverpod 状态管理

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => MyState.initial();

  void updateData(Data data) => state = state.copyWith(data: data);
}
```

## 错误处理

- 使用 `Result<T>` 类型包裹异步操作
- 所有用户输入必须验证
- 禁止空 catch 块
- 使用 `debugPrint` 而非 `print`

## 性能

- 使用 `ListView.builder` 而非 `ListView`
- 使用 `RepaintBoundary` 隔离重绘
- 避免不必要的 `setState`
- 图片使用缓存

## 测试

- TDD: Red → Green → Refactor
- 覆盖率 ≥ 90%
- 测试命名: `should [行为] when [条件]`
- Mock 外部依赖，不 mock 内部逻辑

## 文件大小

- 推荐: 200-400 行
- 最大: 800 行
- 超过则拆分
