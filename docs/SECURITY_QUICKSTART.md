# 文件访问控制快速入门指南

## 1. 基本使用

### 验证单个文件操作

```dart
import 'package:museflow/utils/file_security_validator.dart';

// 验证文件路径
final result = await fileSecurityValidator.validatePath(filePath);
if (!result.isValid) {
  print('验证失败: ${result.errorMessage}');
  return;
}

// 使用验证后的路径
final safePath = result.sanitizedPath ?? filePath;
final file = File(safePath);
```

### 完整的文件导入示例

```dart
import 'package:file_picker/file_picker.dart';
import 'package:museflow/utils/file_security_validator.dart';
import 'package:museflow/services/security_audit_service.dart';

Future<List<MyData>> importMyData() async {
  try {
    // 1. 选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final filePath = result.files.single.path!;
    if (filePath == null) {
      return [];
    }

    // 2. 综合安全验证
    final validationResult = await fileSecurityValidator.validateFile(
      filePath,
      requireExistence: true,
      checkType: true,
      checkSize: true,
    );

    if (!validationResult.isValid) {
      print('安全验证失败: ${validationResult.errorMessage}');
      return [];
    }

    // 3. 读取文件内容
    final safePath = validationResult.sanitizedPath!;
    final file = File(safePath);
    final jsonString = await file.readAsString();
    final jsonData = json.decode(jsonString);

    // 4. 记录审计日志
    securityAuditService.logFileOperation(
      operation: 'my_data_import',
      filePath: safePath,
      allowed: true,
      fileSize: await file.length(),
    );

    // 5. 处理数据
    return parseMyData(jsonData);

  } catch (e) {
    // 记录错误
    securityAuditService.logSecurityEvent(
      eventType: SecurityEventType.invalidOperation,
      message: '导入失败: $e',
    );
    return [];
  }
}
```

## 2. 文件导出示例

```dart
Future<bool> exportMyData(List<MyData> data) async {
  try {
    // 1. 准备内容
    final jsonString = json.encode(data.map((e) => e.toJson()).toList());

    // 2. 检查内容大小
    if (jsonString.length > FileSecurityValidator.maxSingleFileSize) {
      print('内容过大，无法导出');
      return false;
    }

    // 3. 创建安全输出路径
    final safePath = await fileSecurityValidator.createSafeOutputPath(
      'my_data_${DateTime.now().millisecondsSinceEpoch}.json',
      'exports',
    );

    // 4. 验证路径
    final validation = await fileSecurityValidator.validateFile(
      safePath,
      checkWritePermission: true,
      checkType: true,
    );

    if (!validation.isValid) {
      print('路径验证失败: ${validation.errorMessage}');
      return false;
    }

    // 5. 写入文件
    final finalPath = validation.sanitizedPath ?? safePath;
    await File(finalPath).writeAsString(jsonString);

    // 6. 记录审计日志
    securityAuditService.logFileOperation(
      operation: 'my_data_export',
      filePath: finalPath,
      allowed: true,
      fileSize: jsonString.length,
    );

    print('导出成功: $finalPath');
    return true;

  } catch (e) {
    print('导出失败: $e');
    return false;
  }
}
```

## 3. 使用现有的安全服务

MuseFlow已经集成了文件访问控制的服务可以直接使用：

### FileExporter（笔记导入导出）

```dart
import 'package:museflow/utils/file_exporter.dart';

// 导出笔记（自动包含安全验证）
await FileExporter.exportToFileWithPicker(notes);

// 导入笔记（自动包含安全验证）
final notes = await FileExporter.importFromFile();
```

### WorldService（世界观数据）

```dart
import 'package:museflow/features/knowledge/world_service.dart';

// 导出世界观（自动包含安全验证）
await worldService.exportToFile();

// 导入世界观（自动包含安全验证）
await worldService.importFromFile();
```

## 4. 查看安全状态

```dart
import 'package:museflow/utils/security_reporter.dart';

// 生成完整安全报告
final report = SecurityReporter.generateFullReport();
print(report);

// 生成安全摘要
final summary = SecurityReporter.generateSummary();
print(summary);

// 生成安全检查清单
final checklist = SecurityReporter.generateSecurityChecklist();
print(checklist);

// 导出安全报告到文件
final reportFile = await SecurityReporter.exportReportToFile();
print('报告已保存到: ${reportFile.path}');
```

## 5. 查看审计日志

```dart
import 'package:museflow/services/security_audit_service.dart';

// 获取最近的审计日志
final recentLogs = securityAuditService.getRecentLogs(limit: 50);
for (final log in recentLogs) {
  print('${log.timestamp}: ${log.operation} - ${log.allowed ? "允许" : "拒绝"}');
}

// 获取活跃的安全警报
final activeAlerts = securityAuditService.getActiveAlerts();
for (final alert in activeAlerts) {
  print('${alert.severity.name}: ${alert.message}');
}

// 获取统计信息
final stats = securityAuditService.getAuditStatistics();
print('总操作数: ${stats['total_logs']}');
print('被拒绝的操作: ${stats['rejected_last_24_hours']}');
print('活跃警报数: ${stats['active_alerts']}');

// 导出审计报告
final auditReport = await securityAuditService.exportAuditReport();
print('审计报告已保存到: $auditReport');
```

## 6. 自定义安全配置

```dart
import 'package:museflow/config/security_config.dart';

// 检查文件扩展名是否安全
if (SecurityConfig.isSafeExtension('.json')) {
  print('JSON文件是安全的');
}

// 检查文件扩展名是否危险
if (SecurityConfig.isDangerousExtension('.exe')) {
  print('EXE文件是危险的');
}

// 获取文件类型分类
final category = SecurityConfig.getFileTypeCategory('.png');
print('PNG文件属于: $category'); // 输出: image

// 获取特定文件类型的大小限制
final sizeLimit = SecurityConfig.getSafeSizeLimit('image');
print('图片文件大小限制: ${sizeLimit} bytes');
```

## 7. 错误处理模式

```dart
// 标准的错误处理模式
try {
  // 执行文件操作
  final result = await fileSecurityValidator.validateFile(filePath);

  if (!result.isValid) {
    // 处理验证失败
    throw SecurityException(result.errorMessage ?? '未知错误');
  }

  // 继续处理文件
  await processFile(result.sanitizedPath!);

} on SecurityException catch (e) {
  // 处理安全相关的错误
  print('安全错误: ${e.message}');
  securityAuditService.logSecurityEvent(
    eventType: SecurityEventType.invalidOperation,
    message: e.message,
  );

} catch (e) {
  // 处理其他错误
  print('操作失败: $e');
  securityAuditService.logSecurityEvent(
    eventType: SecurityEventType.invalidOperation,
    message: '操作失败: $e',
  );
}
```

## 8. 安全最佳实践

### DO（应该做的）

1. ✅ **始终验证文件路径**
```dart
final result = await fileSecurityValidator.validatePath(userInput);
```

2. ✅ **记录所有文件操作**
```dart
securityAuditService.logFileOperation(
  operation: 'file_read',
  filePath: filePath,
  allowed: true,
);
```

3. ✅ **处理验证失败**
```dart
if (!result.isValid) {
  // 通知用户
  showError(result.errorMessage!);
  return;
}
```

4. ✅ **使用安全的API**
```dart
// 使用 FileExporter 而不是直接操作文件
await FileExporter.exportToFile(notes);
```

### DON'T（不应该做的）

1. ❌ **不要绕过验证**
```dart
// 错误：直接使用用户输入
final file = File(userInput); // 危险！
```

2. ❌ **不要忽略错误**
```dart
// 错误：忽略验证结果
await fileSecurityValidator.validateFile(filePath);
// 没有检查结果！
final file = File(filePath); // 危险！
```

3. ❌ **不要硬编码路径**
```dart
// 错误：硬编码路径
final file = File('/etc/passwd'); // 危险！
```

4. ❌ **不要忘记记录审计**
```dart
// 错误：没有记录审计
await file.writeAsString(data);
// 应该记录这个操作！
```

## 9. 常见问题解答

### Q: 如何处理用户选择的文件路径？
A: 使用文件选择器 + 安全验证：
```dart
final result = await FilePicker.platform.pickFiles();
if (result != null) {
  final validation = await fileSecurityValidator.validateFile(
    result.files.single.path!,
    requireExistence: true,
    checkType: true,
  );
  if (validation.isValid) {
    // 安全地使用文件
  }
}
```

### Q: 如何处理大型文件？
A: 检查大小并分批处理：
```dart
final fileSize = await File(filePath).length();
if (fileSize > FileSecurityValidator.maxSingleFileSize) {
  print('文件过大，请选择较小的文件');
  return;
}
```

### Q: 如何生成安全报告？
A: 使用SecurityReporter：
```dart
final report = SecurityReporter.generateFullReport();
print(report);
```

### Q: 如何查看安全警报？
A: 检查活跃警报：
```dart
final alerts = securityAuditService.getActiveAlerts();
for (final alert in alerts) {
  print('${alert.severity}: ${alert.message}');
}
```

## 10. 下一步

1. 📖 阅读 [完整安全指南](FILE_SECURITY_GUIDE.md)
2. 🧪 运行安全测试：`flutter test test/security_test.dart`
3. 🔍 检查现有代码中的文件操作
4. 🛡️ 为新的文件操作添加安全验证
5. 📊 定期检查安全报告

---

有了这个快速入门指南，你可以立即开始使用MuseFlow的文件访问控制系统，确保你的应用文件操作安全可靠！
