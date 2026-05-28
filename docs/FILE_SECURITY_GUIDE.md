# MuseFlow 文件访问控制系统

## 概述

MuseFlow项目现在配备了完整的文件访问控制系统，旨在防止安全漏洞并保护用户数据。该系统提供多层防护，包括路径验证、文件类型检查、大小限制和审计日志记录。

## 核心组件

### 1. FileSecurityValidator (lib/utils/file_security_validator.dart)

核心安全验证器，提供全面的文件操作安全检查。

#### 主要功能：
- **路径验证**：防止路径遍历攻击（../..）
- **文件类型检查**：只允许安全的文件类型
- **大小限制**：单个文件<10MB，总大小<100MB
- **权限检查**：验证文件读写权限
- **沙箱隔离**：使用安全的工作目录

#### 使用示例：

```dart
// 验证文件路径
final result = await fileSecurityValidator.validatePath(filePath);
if (!result.isValid) {
  print('验证失败: ${result.errorMessage}');
  return;
}

// 验证文件类型
final typeResult = fileSecurityValidator.validateFileType(filePath);

// 验证文件大小
final sizeResult = await fileSecurityValidator.validateFileSize(filePath);

// 综合验证
final validationResult = await fileSecurityValidator.validateFile(
  filePath,
  checkWritePermission: true,
  checkType: true,
  checkSize: true,
);
```

### 2. SecurityAuditService (lib/services/security_audit_service.dart)

安全审计服务，记录所有文件操作和安全事件。

#### 主要功能：
- **操作记录**：记录所有文件操作
- **安全警报**：自动生成安全事件警报
- **统计分析**：提供详细的安全统计信息
- **报告导出**：生成审计报告

#### 使用示例：

```dart
// 记录文件操作
securityAuditService.logFileOperation(
  operation: 'file_import',
  filePath: filePath,
  allowed: true,
  fileSize: 1024,
);

// 记录安全事件
securityAuditService.logSecurityEvent(
  eventType: SecurityEventType.pathTraversal,
  message: '检测到路径遍历攻击',
  filePath: suspiciousPath,
);

// 获取统计信息
final stats = securityAuditService.getAuditStatistics();

// 导出审计报告
final reportPath = await securityAuditService.exportAuditReport();
```

### 3. SecurityConfig (lib/config/security_config.dart)

集中管理所有安全配置参数。

#### 主要配置：
- 文件大小限制
- 文件类型白名单/黑名单
- 路径安全参数
- 审计配置

## 集成说明

### 已集成的文件操作

1. **FileExporter** (lib/utils/file_exporter.dart)
   - 文件导入导出
   - 自动路径验证
   - 内容大小检查

2. **DiskCache** (lib/services/ai/cache/disk_cache.dart)
   - AI缓存文件操作
   - 安全目录创建
   - 缓存大小管理

3. **WorldService** (lib/features/knowledge/world_service.dart)
   - 世界观数据导入导出
   - 文件类型验证
   - 安全路径生成

4. **CharacterService** (lib/features/knowledge/character_service.dart)
   - 角色卡数据导入导出
   - 完整的安全验证流程

## 安全特性

### 1. 路径遍历防护
系统检测并阻止各种路径遍历攻击模式：
- `../../../etc/passwd`
- `..\\..\\..\\windows\\system32`
- `/etc/passwd`
- `./../../../sensitive_file.txt`

### 2. 文件类型控制
**允许的文件类型**（白名单）：
- 文本文件：.txt, .md, .json, .csv, .xml, .yaml, .yml
- 代码文件：.html, .css, .js, .ts, .dart, .py, .java
- 图片文件：.png, .jpg, .jpeg, .gif, .svg, .webp
- 音频文件：.mp3, .wav, .m4a, .aac, .ogg, .flac
- 视频文件：.mp4, .mov, .avi, .mkv, .webm
- 文档文件：.pdf, .doc, .docx, .xls, .xlsx, .ppt, .pptx
- 压缩文件：.zip, .tar, .gz, .7z, .rar

**禁止的文件类型**（黑名单）：
- 可执行文件：.exe, .bat, .cmd, .sh, .ps1, .vbs
- 系统文件：.scr, .pif, .vb, .jse, .wsf, .lnk
- 软件包：.jar, .app, .deb, .rpm, .dmg, .pkg, .msi

### 3. 大小限制
- 单个文件最大：10MB
- 会话总大小：100MB
- 文件名最大长度：255字符

### 4. 沙箱隔离
系统自动创建并使用安全的目录结构：
```
~/Documents/museflow/
├── notes/           # 笔记文件
├── cache/           # 缓存文件
├── exports/         # 导出文件
├── imports/         # 导入文件
└── audit/           # 审计日志
```

## 最佳实践

### 1. 文件导入
```dart
Future<List<MyData>> importData() async {
  try {
    // 1. 选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return [];

    // 2. 验证路径
    final pathValidation = await fileSecurityValidator.validatePath(
      result.files.single.path!,
      requireExistence: true,
    );

    if (!pathValidation.isValid) {
      throw Exception(pathValidation.errorMessage);
    }

    // 3. 验证类型
    final typeValidation = fileSecurityValidator.validateFileType(
      pathValidation.sanitizedPath!,
    );

    if (!typeValidation.isValid) {
      throw Exception(typeValidation.errorMessage);
    }

    // 4. 验证大小
    final file = File(pathValidation.sanitizedPath!);
    final fileSize = await file.length();

    if (fileSize > FileSecurityValidator.maxSingleFileSize) {
      throw Exception('文件过大');
    }

    // 5. 读取内容
    final jsonString = await file.readAsString();
    final data = json.decode(jsonString);

    // 6. 记录审计
    securityAuditService.logFileOperation(
      operation: 'data_import',
      filePath: file.path,
      allowed: true,
      fileSize: fileSize,
    );

    return parseData(data);
  } catch (e) {
    securityAuditService.logSecurityEvent(
      eventType: SecurityEventType.invalidOperation,
      message: '导入失败: $e',
    );
    return [];
  }
}
```

### 2. 文件导出
```dart
Future<bool> exportData(List<MyData> data) async {
  try {
    // 1. 生成内容
    final jsonString = json.encode(data);

    // 2. 检查大小
    if (jsonString.length > FileSecurityValidator.maxSingleFileSize) {
      throw Exception('内容过大');
    }

    // 3. 创建安全路径
    final safePath = await fileSecurityValidator.createSafeOutputPath(
      'data_${DateTime.now().millisecondsSinceEpoch}.json',
      'exports',
    );

    // 4. 验证路径
    final validation = await fileSecurityValidator.validateFile(
      safePath,
      checkWritePermission: true,
      checkType: true,
    );

    if (!validation.isValid) {
      throw Exception(validation.errorMessage);
    }

    // 5. 写入文件
    await File(safePath).writeAsString(jsonString);

    // 6. 记录审计
    securityAuditService.logFileOperation(
      operation: 'data_export',
      filePath: safePath,
      allowed: true,
      fileSize: jsonString.length,
    );

    return true;
  } catch (e) {
    securityAuditService.logSecurityEvent(
      eventType: SecurityEventType.invalidOperation,
      message: '导出失败: $e',
    );
    return false;
  }
}
```

## 安全审计

### 查看审计日志
```dart
// 获取最近的日志
final recentLogs = securityAuditService.getRecentLogs(limit: 100);

// 获取活跃警报
final activeAlerts = securityAuditService.getActiveAlerts();

// 获取统计信息
final stats = securityAuditService.getAuditStatistics();
print('总操作数: ${stats['total_logs']}');
print('被拒绝的操作: ${stats['rejected_last_24_hours']}');
```

### 导出审计报告
```dart
final reportPath = await securityAuditService.exportAuditReport();
print('审计报告已保存到: $reportPath');
```

## 测试

运行安全测试：
```bash
flutter test test/security_test.dart
```

测试覆盖：
- 路径遍历检测
- 危险文件类型检测
- 文件大小验证
- 文件名模式检查
- 安全路径生成
- 审计日志记录

## 安全最佳实践

1. **永远不要绕过验证**：所有文件操作都必须经过安全验证
2. **使用安全的API**：使用提供的安全API而不是直接操作文件
3. **记录审计日志**：所有文件操作都应该记录审计日志
4. **处理安全事件**：及时处理安全警报和异常情况
5. **定期检查报告**：定期导出和分析审计报告

## 故障排除

### 常见问题

1. **文件路径验证失败**
   - 检查路径是否包含相对路径遍历
   - 确认文件是否在安全目录内
   - 验证文件权限

2. **文件类型被拒绝**
   - 确认文件扩展名在白名单中
   - 检查是否匹配危险文件类型
   - 验证文件扩展名格式

3. **文件大小超限**
   - 检查单个文件大小（<10MB）
   - 检查会话总大小（<100MB）
   - 考虑分批处理大文件

## 维护和更新

定期检查和更新：
- 文件类型白名单和黑名单
- 大小限制配置
- 安全目录结构
- 审计日志保留策略

## 总结

MuseFlow的文件访问控制系统提供了全面的文件操作安全保护，确保应用程序和用户数据的安全性。通过遵循最佳实践和正确使用安全API，可以有效防止安全漏洞和攻击。
