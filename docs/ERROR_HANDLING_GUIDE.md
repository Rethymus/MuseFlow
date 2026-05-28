# MuseFlow 错误处理系统使用指南

## 概述

MuseFlow错误处理系统提供了一个用户友好的错误处理框架，将技术错误转换为用户可以理解的信息，并提供具体的解决方案。

## 核心组件

### 1. UserFriendlyErrorHandler

核心错误处理器，负责将异常转换为用户友好的错误信息。

```dart
import 'package:museflow/utils/user_friendly_error_handler.dart';

// 获取处理器实例
final handler = UserFriendlyErrorHandler.instance;

// 处理错误
try {
  // 你的代码
} catch (error, stackTrace) {
  final userError = handler.handleError(error, stackTrace);
  // userError 包含用户友好的错误信息
}
```

### 2. ErrorHandlingService

全局错误处理服务，提供错误记录、统计和报告功能。

```dart
import 'package:museflow/services/error_handling_service.dart';

// 显示错误对话框
await errorHandlingService.showError(context, error, stackTrace);

// 显示错误横幅
errorHandlingService.showErrorBanner(context, error, stackTrace);

// 获取错误统计
final stats = errorHandlingService.getErrorStatistics();
```

### 3. ErrorDisplayWidgets

提供多种错误显示方式的UI组件。

```dart
import 'package:museflow/widgets/error_display_widgets.dart';

// 显示错误对话框
await ErrorDisplayWidgets.showErrorDialog(context, userError);

// 显示错误横幅
ErrorDisplayWidgets.showErrorBanner(context, userError);

// 创建错误卡片
Widget errorCard = ErrorDisplayWidgets.createErrorCard(userError);
```

## 错误分类体系

### 错误严重程度

- **Info** (ℹ️): 信息性错误，不影响功能
- **Warning** (⚠️): 警告，可能影响某些功能
- **Error** (❌): 错误，功能无法使用
- **Critical** (🚨): 严重错误，应用核心功能受损

### 错误类别

- **FileSystem**: 文件系统相关错误
- **Network**: 网络相关错误
- **Permission**: 权限相关错误
- **AIService**: AI服务相关错误
- **Data**: 数据相关错误
- **UI**: UI相关错误
- **System**: 系统相关错误
- **Unknown**: 未知错误

## 集成指南

### 1. 全局错误处理

在 `main.dart` 中设置全局错误处理：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置全局错误处理
  FlutterError.onError = (details) {
    errorHandlingService.handleError(details.exception, details.stack);
  };

  runApp(const MuseFlowApp());
}
```

### 2. 应用级错误边界

```dart
class MuseFlowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        errorHandlingService.handleError(error, stackTrace);
      },
      child: MaterialApp(
        // 你的应用配置
      ),
    );
  }
}
```

### 3. 特定错误处理

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<void> _performOperation() async {
    try {
      // 可能失败的异步操作
      await someAsyncOperation();
    } catch (error, stackTrace) {
      // 显示用户友好的错误
      await errorHandlingService.showError(context, error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _performOperation,
      child: Text('执行操作'),
    );
  }
}
```

## 错误处理最佳实践

### 1. 异步操作错误处理

```dart
Future<void> loadData() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final data = await fetchData();
    setState(() {
      _data = data;
    });
  } catch (error, stackTrace) {
    // 使用用户友好的错误处理
    await errorHandlingService.showError(context, error, stackTrace);

    // 可选：记录到日志
    debugPrint('数据加载失败: $error');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

### 2. 文件操作错误处理

```dart
Future<void> saveFile(String content, String path) async {
  try {
    // 验证文件路径
    final validation = await fileSecurityValidator.validateFile(path);
    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    // 执行文件操作
    await File(path).writeAsString(content);

  } catch (error, stackTrace) {
    // 显示用户友好的错误信息
    await errorHandlingService.showError(context, error, stackTrace);
  }
}
```

### 3. 网络请求错误处理

```dart
Future<void> makeApiCall() async {
  try {
    final response = await http.get(Uri.parse('https://api.example.com/data'));

    if (response.statusCode != 200) {
      throw HttpException('请求失败: ${response.statusCode}');
    }

    // 处理响应
    final data = json.decode(response.body);
    _updateUI(data);

  } catch (error, stackTrace) {
    // 网络错误自动转换为用户友好的信息
    await errorHandlingService.showError(context, error, stackTrace);
  }
}
```

### 4. 状态错误处理

```dart
void _performCriticalOperation() {
  if (!_isInCorrectState) {
    final error = StateError('当前状态下无法执行此操作');
    errorHandlingService.showError(context, error);
    return;
  }

  // 执行操作
  _executeOperation();
}
```

## 自定义错误处理

### 1. 自定义错误类型

```dart
class CustomBusinessException implements Exception {
  final String message;
  final String code;

  CustomBusinessException(this.message, {this.code = 'CUSTOM_ERROR'});

  @override
  String toString() => 'CustomBusinessException: $message (Code: $code)';
}
```

### 2. 扩展错误处理器

```dart
extension CustomErrorHandler on UserFriendlyErrorHandler {
  UserFriendlyError handleCustomError(CustomBusinessException error) {
    return UserFriendlyError(
      title: '业务逻辑错误',
      description: error.message,
      solutions: [
        '检查操作步骤是否正确',
        '确认账户状态',
        '联系客服获取帮助',
      ],
      severity: ErrorSeverity.warning,
      category: ErrorCategory.unknown,
      technicalDetails: error.toString(),
    );
  }
}
```

## 错误监控和分析

### 1. 错误统计

```dart
final stats = errorHandlingService.getErrorStatistics();
print('总错误数: ${stats['total_errors']}');
print('严重错误数: ${stats['critical_errors']}');
```

### 2. 错误趋势分析

```dart
final patterns = errorHandlingService.analyzeErrorPatterns();
print('最常见错误: ${patterns['most_common_category']}');
print('错误趋势: ${patterns['trend']}');
```

### 3. 生成错误报告

```dart
final reportPath = await errorHandlingService.createErrorReport();
print('错误报告已生成: $reportPath');
```

## 错误流监听

```dart
// 监听全局错误流
errorHandlingService.errorStream.listen((error) {
  // 处理错误流
  print('新错误: ${error.title}');

  // 可以发送到分析服务
  // analyticsService.logError(error);
});
```

## 测试错误处理

### 1. 单元测试

```dart
test('文件系统错误处理', () {
  final handler = UserFriendlyErrorHandler.instance;
  final error = FileSystemException('文件不存在', '/path/to/file.txt');

  final userError = handler.handleError(error);

  expect(userError.title, '文件找不到');
  expect(userError.category, ErrorCategory.fileSystem);
  expect(userError.severity, ErrorSeverity.error);
});
```

### 2. 集成测试

```dart
testWidgets('错误对话框显示', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());

  // 触发错误
  await tester.tap(find.text('触发错误'));
  await tester.pumpAndSettle();

  // 验证错误对话框显示
  expect(find.text('文件找不到'), findsOneWidget);
  expect(find.text('解决方案：'), findsOneWidget);
});
```

## 常见错误处理场景

### 1. 文件不存在

```dart
try {
  final file = File('/path/to/file.txt');
  if (!await file.exists()) {
    throw FileSystemException('文件不存在', '/path/to/file.txt');
  }
} catch (error, stackTrace) {
  await errorHandlingService.showError(context, error, stackTrace);
}
```

### 2. 权限拒绝

```dart
try {
  await File('/protected/file.txt').readAsString();
} catch (error, stackTrace) {
  if (error.toString().contains('permission')) {
    await errorHandlingService.showError(context, error, stackTrace);
  }
}
```

### 3. 网络超时

```dart
try {
  final response = await http.get(Uri.parse('https://api.example.com'))
      .timeout(const Duration(seconds: 10));
} on TimeoutException catch (error, stackTrace) {
  await errorHandlingService.showError(context, error, stackTrace);
}
```

### 4. 数据解析错误

```dart
try {
  final data = json.decode(responseBody);
  final model = DataModel.fromJson(data);
} on FormatException catch (error, stackTrace) {
  await errorHandlingService.showError(context, error, stackTrace);
}
```

## 性能考虑

### 1. 避免重复处理

```dart
// 不要这样做
try {
  await operation1();
} catch (e) {
  errorHandlingService.showError(context, e);
}

try {
  await operation2();
} catch (e) {
  errorHandlingService.showError(context, e);
}

// 应该这样做
try {
  await operation1();
  await operation2();
} catch (e) {
  await errorHandlingService.showError(context, e);
}
```

### 2. 异步错误处理

```dart
// 不要阻塞UI
void _handleOperation() async {
  try {
    await longRunningOperation();
  } catch (e) {
    // 异步处理错误，不阻塞UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      errorHandlingService.showError(context, e);
    });
  }
}
```

## 维护和监控

### 1. 定期检查错误报告

```dart
// 每周生成错误报告
Timer.periodic(const Duration(days: 7), (_) async {
  final reportPath = await errorHandlingService.createErrorReport();
  // 发送报告到管理后台
  await sendReportToBackend(reportPath);
});
```

### 2. 设置错误告警

```dart
errorHandlingService.errorStream.listen((error) {
  if (error.severity == ErrorSeverity.critical) {
    // 发送紧急告警
    sendCriticalAlert(error);
  }
});
```

## 总结

MuseFlow错误处理系统提供了完整的错误处理解决方案：

1. **用户友好**: 将技术错误转换为用户可理解的信息
2. **具体指导**: 为每种错误提供具体的解决步骤
3. **分级管理**: 根据严重程度和类别分类管理错误
4. **全局监控**: 提供错误统计、趋势分析和报告功能
5. **易于集成**: 简单的API和完整的组件支持

通过正确使用这个系统，可以显著提升用户体验和应用稳定性。