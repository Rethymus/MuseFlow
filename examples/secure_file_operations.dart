/// 安全文件操作示例
///
/// 演示如何在MuseFlow中使用文件访问控制系统
library;

import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../lib/utils/file_security_validator.dart';
import '../lib/services/security_audit_service.dart';
import '../lib/utils/security_reporter.dart';
import '../lib/config/security_config.dart';

/// 示例1: 基本的文件导入
Future<void> example1_BasicFileImport() async {
  print('🔍 示例1: 基本的文件导入');
  print('-' * 50);

  try {
    // 1. 使用文件选择器选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'txt'],
    );

    if (result == null || result.files.isEmpty) {
      print('用户取消了文件选择');
      return;
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      print('文件路径无效');
      return;
    }

    print('选择的文件: $filePath');

    // 2. 验证文件路径
    final pathValidation = await fileSecurityValidator.validatePath(
      filePath,
      requireExistence: true,
    );

    if (!pathValidation.isValid) {
      print('❌ 路径验证失败: ${pathValidation.errorMessage}');
      return;
    }

    print('✅ 路径验证通过');

    // 3. 验证文件类型
    final typeValidation = fileSecurityValidator.validateFileType(filePath);
    if (!typeValidation.isValid) {
      print('❌ 类型验证失败: ${typeValidation.errorMessage}');
      return;
    }

    print('✅ 类型验证通过');

    // 4. 验证文件大小
    final file = File(filePath);
    final fileSize = await file.length();

    final sizeValidation = await fileSecurityValidator.validateFileSize(filePath);
    if (!sizeValidation.isValid) {
      print('❌ 大小验证失败: ${sizeValidation.errorMessage}');
      return;
    }

    print('✅ 大小验证通过 (${fileSize} bytes)');

    // 5. 读取文件内容
    final content = await file.readAsString();
    print('📄 文件内容长度: ${content.length} 字符');

    // 6. 记录审计日志
    securityAuditService.logFileOperation(
      operation: 'example_file_import',
      filePath: filePath,
      allowed: true,
      fileSize: fileSize,
    );

    print('✅ 文件导入成功');

  } catch (e) {
    print('❌ 导入失败: $e');
    securityAuditService.logSecurityEvent(
      eventType: SecurityEventType.invalidOperation,
      message: '导入失败: $e',
    );
  }

  print('');
}

/// 示例2: 安全的文件导出
Future<void> example2_SecureFileExport() async {
  print('💾 示例2: 安全的文件导出');
  print('-' * 50);

  try {
    // 1. 准备要导出的数据
    final data = {
      'example': 'data',
      'timestamp': DateTime.now().toIso8601String(),
      'items': ['item1', 'item2', 'item3'],
    };

    final jsonString = json.encode(data);
    print('准备导出数据: ${jsonString.length} 字符');

    // 2. 检查内容大小
    if (jsonString.length > FileSecurityValidator.maxSingleFileSize) {
      print('❌ 内容过大，无法导出');
      return;
    }

    print('✅ 内容大小检查通过');

    // 3. 创建安全的输出路径
    final safePath = await fileSecurityValidator.createSafeOutputPath(
      'example_data_${DateTime.now().millisecondsSinceEpoch}.json',
      'exports',
    );

    print('安全输出路径: $safePath');

    // 4. 验证输出路径
    final validation = await fileSecurityValidator.validateFile(
      safePath,
      checkWritePermission: true,
      checkType: true,
    );

    if (!validation.isValid) {
      print('❌ 路径验证失败: ${validation.errorMessage}');
      return;
    }

    print('✅ 输出路径验证通过');

    // 5. 写入文件
    final finalPath = validation.sanitizedPath ?? safePath;
    await File(finalPath).writeAsString(jsonString);

    // 6. 记录审计日志
    securityAuditService.logFileOperation(
      operation: 'example_data_export',
      filePath: finalPath,
      allowed: true,
      fileSize: jsonString.length,
    );

    print('✅ 数据导出成功: $finalPath');

  } catch (e) {
    print('❌ 导出失败: $e');
    securityAuditService.logSecurityEvent(
      eventType: SecurityEventType.invalidOperation,
      message: '导出失败: $e',
    );
  }

  print('');
}

/// 示例3: 安全检查
Future<void> example3_SecurityChecks() async {
  print('🛡️ 示例3: 安全检查');
  print('-' * 50);

  // 测试各种安全威胁
  final testCases = [
    {
      'name': '路径遍历攻击测试',
      'paths': ['../../../etc/passwd', '..\\..\\system32\\config'],
    },
    {
      'name': '危险文件类型测试',
      'files': ['virus.exe', 'malware.bat', 'trojan.sh'],
    },
    {
      'name': '安全文件类型测试',
      'files': ['document.txt', 'data.json', 'image.png'],
    },
  ];

  for (final testCase in testCases) {
    print('\n📋 ${testCase['name']}');

    if (testCase.containsKey('paths')) {
      final paths = testCase['paths'] as List<String>;
      for (final path in paths) {
        final result = await fileSecurityValidator.validatePath(path);
        final status = result.isValid ? '❌ 未阻止' : '✅ 已阻止';
        print('$status: $path');
      }
    }

    if (testCase.containsKey('files')) {
      final files = testCase['files'] as List<String>;
      for (final file in files) {
        final result = fileSecurityValidator.validateFileType(file);
        final status = result.isValid ? '✅ 允许' : '❌ 阻止';
        print('$status: $file');
      }
    }
  }

  print('\n');
}

/// 示例4: 审计日志分析
Future<void> example4_AuditLogAnalysis() async {
  print('📊 示例4: 审计日志分析');
  print('-' * 50);

  try {
    // 获取审计统计信息
    final stats = securityAuditService.getAuditStatistics();

    print('审计统计信息:');
    print('  总日志数: ${stats['total_logs']}');
    print('  最近24小时操作: ${stats['last_24_hours']}');
    print('  最近7天操作: ${stats['last_7_days']}');
    print('  被拒绝的操作(24小时): ${stats['rejected_last_24_hours']}');
    print('  被拒绝的操作(7天): ${stats['rejected_last_7_days']}');
    print('  总警报数: ${stats['total_alerts']}');
    print('  活跃警报: ${stats['active_alerts']}');
    print('  高严重性警报: ${stats['high_severity_alerts']}');

    // 获取最近的审计日志
    print('\n最近的审计日志:');
    final recentLogs = securityAuditService.getRecentLogs(limit: 5);

    for (final log in recentLogs) {
      final status = log.allowed ? '✅' : '❌';
      final time = log.timestamp.toIso8601String().substring(0, 19);
      print('$status $time | ${log.operation} | ${log.filePath ?? "无文件"}');

      if (!log.allowed && log.reason != null) {
        print('   原因: ${log.reason}');
      }
    }

    // 获取活跃的安全警报
    print('\n活跃的安全警报:');
    final activeAlerts = securityAuditService.getActiveAlerts();

    if (activeAlerts.isEmpty) {
      print('✅ 无活跃的安全警报');
    } else {
      for (final alert in activeAlerts) {
        final severity = alert.severity.name.toUpperCase();
        final time = alert.timestamp.toIso8601String().substring(0, 19);
        print('⚠️  $severity | $time | ${alert.message}');

        if (alert.filePath != null) {
          print('   文件: ${alert.filePath}');
        }
      }
    }

  } catch (e) {
    print('❌ 审计分析失败: $e');
  }

  print('');
}

/// 示例5: 安全报告生成
Future<void> example5_SecurityReport() async {
  print('📄 示例5: 安全报告生成');
  print('-' * 50);

  try {
    // 生成完整的安全报告
    print('正在生成完整安全报告...');
    final fullReport = SecurityReporter.generateFullReport();

    print(fullReport);

    // 生成安全摘要
    print('\n正在生成安全摘要...');
    final summary = SecurityReporter.generateSummary();
    print(summary);

    // 生成安全检查清单
    print('\n正在生成安全检查清单...');
    final checklist = SecurityReporter.generateSecurityChecklist();
    print(checklist);

    // 导出报告到文件
    print('\n正在导出报告到文件...');
    final reportFile = await SecurityReporter.exportReportToFile();
    print('✅ 报告已保存到: ${reportFile.path}');

  } catch (e) {
    print('❌ 报告生成失败: $e');
  }

  print('');
}

/// 示例6: 安全配置检查
Future<void> example6_SecurityConfig() async {
  print('⚙️  示例6: 安全配置检查');
  print('-' * 50);

  try {
    // 检查文件扩展名安全性
    print('文件扩展名安全检查:');

    final testExtensions = [
      '.json', '.txt', '.exe', '.bat', '.png', '.sh'
    ];

    for (final ext in testExtensions) {
      final isSafe = SecurityConfig.isSafeExtension(ext);
      final isDangerous = SecurityConfig.isDangerousExtension(ext);
      final category = SecurityConfig.getFileTypeCategory(ext);

      final safety = isSafe ? '✅ 安全' : '❌ 危险';
      final danger = isDangerous ? '⚠️ 危险' : '✅ 无害';
      print('  $ext: $safety, $danger, 分类: $category');
    }

    // 获取文件类型的大小限制
    print('\n文件类型大小限制:');
    final categories = ['text', 'image', 'audio', 'video', 'document'];

    for (final category in categories) {
      final limit = SecurityConfig.getSafeSizeLimit(category);
      print('  $category: ${limit} bytes');
    }

    // 获取所有允许的扩展名
    print('\n所有允许的文件扩展名:');
    final allowedExtensions = SecurityConfig.getAllAllowedExtensions();
    print('  总计: ${allowedExtensions.length} 种扩展名');
    print('  示例: ${allowedExtensions.take(10).join(", ")}');

  } catch (e) {
    print('❌ 配置检查失败: $e');
  }

  print('');
}

/// 主函数 - 运行所有示例
Future<void> main() async {
  print('🚀 MuseFlow 文件访问控制示例');
  print('=' * 50);
  print('');

  // 等待初始化完成
  await Future.delayed(const Duration(milliseconds: 500));

  // 运行所有示例
  await example1_BasicFileImport();
  await example2_SecureFileExport();
  await example3_SecurityChecks();
  await example4_AuditLogAnalysis();
  await example5_SecurityReport();
  await example6_SecurityConfig();

  print('✅ 所有示例运行完成');
  print('');
  print('💡 提示: 在实际应用中，你应该：');
  print('  1. 始终验证用户提供的文件路径');
  print('  2. 检查文件类型和大小限制');
  print('  3. 记录所有文件操作的审计日志');
  print('  4. 定期检查安全状态和警报');
  print('  5. 遵循安全最佳实践');
}

/// 自定义安全异常类
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
