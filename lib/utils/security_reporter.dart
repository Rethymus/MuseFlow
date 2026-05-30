import 'dart:io';
import 'file_security_validator.dart';
import '../services/security_audit_service.dart';

/// 安全状态报告器
///
/// 提供安全状态可视化和报告功能
class SecurityReporter {
  static final String separator = '\n${'=' * 60}';

  /// 生成完整的安全状态报告
  static String generateFullReport() {
    final buffer = StringBuffer();

    buffer.writeln('🔒 MuseFlow 安全状态报告');
    buffer.writeln(separator);
    buffer.writeln('生成时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln(separator);

    // 1. 文件安全验证器状态
    buffer.writeln('\n📊 文件安全验证器状态:');
    buffer.writeln(_formatSecurityStatus());

    // 2. 审计服务状态
    buffer.writeln('\n📋 安全审计服务状态:');
    buffer.writeln(_formatAuditStatus());

    // 3. 安全配置
    buffer.writeln('\n⚙️ 安全配置:');
    buffer.writeln(_formatSecurityConfig());

    // 4. 最近的审计日志
    buffer.writeln('\n📝 最近的审计日志:');
    buffer.writeln(_formatRecentLogs());

    // 5. 活跃的安全警报
    buffer.writeln('\n⚠️ 活跃的安全警报:');
    buffer.writeln(_formatActiveAlerts());

    buffer.writeln(separator);
    buffer.writeln('报告结束');

    return buffer.toString();
  }

  /// 生成简化的安全摘要
  static String generateSummary() {
    final securityStatus = fileSecurityValidator.getSecurityStatus();
    final auditStats = securityAuditService.getAuditStatistics();

    final buffer = StringBuffer();
    buffer.writeln('🔒 MuseFlow 安全摘要');
    buffer.writeln(separator);
    buffer
        .writeln('当前会话大小: ${securityStatus['current_session_size_formatted']}');
    buffer.writeln(
        '最大单文件大小: ${_formatBytes(securityStatus['max_single_file_size'])}');
    buffer.writeln('最大总大小: ${_formatBytes(securityStatus['max_total_size'])}');
    buffer.writeln(separator);
    buffer.writeln('最近24小时操作: ${auditStats['last_24_hours']}');
    buffer.writeln('最近7天操作: ${auditStats['last_7_days']}');
    buffer.writeln('被拒绝的操作(24小时): ${auditStats['rejected_last_24_hours']}');
    buffer.writeln('被拒绝的操作(7天): ${auditStats['rejected_last_7_days']}');
    buffer.writeln('活跃警报: ${auditStats['active_alerts']}');
    buffer.writeln('高严重性警报: ${auditStats['high_severity_alerts']}');
    buffer.writeln(separator);

    return buffer.toString();
  }

  /// 生成安全检查清单
  static Future<String> generateSecurityChecklist() async {
    final buffer = StringBuffer();

    buffer.writeln('✅ MuseFlow 安全检查清单');
    buffer.writeln(separator);

    final checks = await Future.wait([
      _checkPathTraversalProtection(),
      Future.value(_checkFileTypeValidation()),
      Future.value(_checkFileSizeLimits()),
      Future.value(_checkSafeDirectories()),
      Future.value(_checkAuditLogging()),
      Future.value(_checkAlertSystem()),
    ]);

    int passed = 0;
    int failed = 0;

    for (final check in checks) {
      buffer.writeln(check['status'] == 'PASS' ? '✅' : '❌');
      buffer.writeln('检查项目: ${check['name']}');
      buffer.writeln('状态: ${check['status']}');
      buffer.writeln('详情: ${check['details']}');
      buffer.writeln('-' * 40);

      if (check['status'] == 'PASS') {
        passed++;
      } else {
        failed++;
      }
    }

    buffer.writeln(separator);
    buffer.writeln('检查结果: $passed 通过, $failed 失败');
    buffer.writeln(separator);

    return buffer.toString();
  }

  /// 导出安全报告到文件
  static Future<File> exportReportToFile() async {
    final reportContent = generateFullReport();
    final fileName = 'security_report_${DateTime.now().toIso8601String()}.txt';

    final safePath = await fileSecurityValidator.createSafeOutputPath(
      fileName,
      'reports',
    );

    final file = File(safePath);
    await file.writeAsString(reportContent);

    return file;
  }

  // 私有辅助方法

  static String _formatSecurityStatus() {
    final status = fileSecurityValidator.getSecurityStatus();
    final buffer = StringBuffer();

    buffer.writeln('当前会话大小: ${status['current_session_size_formatted']}');
    buffer.writeln('单文件大小限制: ${_formatBytes(status['max_single_file_size'])}');
    buffer.writeln('总大小限制: ${_formatBytes(status['max_total_size'])}');
    buffer.writeln('安全目录数量: ${status['safe_directories'].length}');
    buffer.writeln('允许的文件类型: ${status['allowed_extensions'].length}种');

    return buffer.toString();
  }

  static String _formatAuditStatus() {
    final stats = securityAuditService.getAuditStatistics();
    final buffer = StringBuffer();

    buffer.writeln('总审计日志: ${stats['total_logs']}');
    buffer.writeln('最近24小时操作: ${stats['last_24_hours']}');
    buffer.writeln('最近7天操作: ${stats['last_7_days']}');
    buffer.writeln('被拒绝操作(24小时): ${stats['rejected_last_24_hours']}');
    buffer.writeln('被拒绝操作(7天): ${stats['rejected_last_7_days']}');
    buffer.writeln('总警报数: ${stats['total_alerts']}');
    buffer.writeln('活跃警报: ${stats['active_alerts']}');
    buffer.writeln('高严重性警报: ${stats['high_severity_alerts']}');

    return buffer.toString();
  }

  static String _formatSecurityConfig() {
    final buffer = StringBuffer();

    buffer.writeln(
        '最大单文件大小: ${_formatBytes(FileSecurityValidator.maxSingleFileSize)}');
    buffer
        .writeln('最大总大小: ${_formatBytes(FileSecurityValidator.maxTotalSize)}');
    buffer.writeln('最大文件名长度: ${FileSecurityValidator.maxFileNameLength}字符');
    buffer.writeln(
        '允许的文件扩展名: ${FileSecurityValidator.allowedExtensions.length}种');
    buffer.writeln(
        '禁止的文件扩展名: ${FileSecurityValidator.dangerousExtensions.length}种');

    return buffer.toString();
  }

  static String _formatRecentLogs() {
    final logs = securityAuditService.getRecentLogs(limit: 10);
    final buffer = StringBuffer();

    if (logs.isEmpty) {
      buffer.writeln('暂无最近的审计日志');
      return buffer.toString();
    }

    for (final log in logs) {
      final status = log.allowed ? '✅' : '❌';
      buffer.writeln('$status ${log.timestamp.toIso8601String()}');
      buffer.writeln('   操作: ${log.operation}');
      if (log.filePath != null) {
        buffer.writeln('   文件: ${log.filePath}');
      }
      if (!log.allowed && log.reason != null) {
        buffer.writeln('   原因: ${log.reason}');
      }
      if (log.fileSize != null) {
        buffer.writeln('   大小: ${_formatBytes(log.fileSize!)}');
      }
      buffer.writeln('   -' * 20);
    }

    return buffer.toString();
  }

  static String _formatActiveAlerts() {
    final alerts = securityAuditService.getActiveAlerts();
    final buffer = StringBuffer();

    if (alerts.isEmpty) {
      buffer.writeln('✅ 无活跃的安全警报');
      return buffer.toString();
    }

    for (final alert in alerts) {
      final severityIcon = _getSeverityIcon(alert.severity);
      buffer.writeln('$severityIcon ${alert.timestamp.toIso8601String()}');
      buffer.writeln('   严重性: ${alert.severity.name.toUpperCase()}');
      buffer.writeln('   消息: ${alert.message}');
      if (alert.filePath != null) {
        buffer.writeln('   文件: ${alert.filePath}');
      }
      buffer.writeln('   详情: ${alert.details}');
      buffer.writeln('   ID: ${alert.id}');
      buffer.writeln('   -' * 20);
    }

    return buffer.toString();
  }

  static Future<Map<String, dynamic>> _checkPathTraversalProtection() async {
    try {
      // 测试路径遍历检测
      final testPaths = ['../../../etc/passwd', '..\\..\\system32'];
      int detected = 0;

      for (final path in testPaths) {
        final result = await fileSecurityValidator.validatePath(path);
        if (!result.isValid) detected++;
      }

      if (detected == testPaths.length) {
        return {
          'name': '路径遍历保护',
          'status': 'PASS',
          'details': '成功检测所有测试的路径遍历攻击模式',
        };
      } else {
        return {
          'name': '路径遍历保护',
          'status': 'FAIL',
          'details': '仅检测到 $detected/${testPaths.length} 个攻击模式',
        };
      }
    } catch (e) {
      return {
        'name': '路径遍历保护',
        'status': 'ERROR',
        'details': '检查过程中出错: $e',
      };
    }
  }

  static Map<String, dynamic> _checkFileTypeValidation() {
    try {
      final safeFiles = ['test.txt', 'data.json', 'image.png'];
      final dangerousFiles = ['virus.exe', 'malware.bat', 'hack.sh'];

      int safeAllowed = 0;
      int dangerousBlocked = 0;

      for (final file in safeFiles) {
        final result = fileSecurityValidator.validateFileType(file);
        if (result.isValid) safeAllowed++;
      }

      for (final file in dangerousFiles) {
        final result = fileSecurityValidator.validateFileType(file);
        if (!result.isValid) dangerousBlocked++;
      }

      if (safeAllowed == safeFiles.length &&
          dangerousBlocked == dangerousFiles.length) {
        return {
          'name': '文件类型验证',
          'status': 'PASS',
          'details': '正确允许所有安全文件，阻止所有危险文件',
        };
      } else {
        return {
          'name': '文件类型验证',
          'status': 'FAIL',
          'details': '文件类型验证不准确',
        };
      }
    } catch (e) {
      return {
        'name': '文件类型验证',
        'status': 'ERROR',
        'details': '检查过程中出错: $e',
      };
    }
  }

  static Map<String, dynamic> _checkFileSizeLimits() {
    try {
      final status = fileSecurityValidator.getSecurityStatus();
      final maxSize = status['max_single_file_size'] as int;
      final totalSize = status['max_total_size'] as int;

      if (maxSize > 0 && totalSize > 0 && maxSize < totalSize) {
        return {
          'name': '文件大小限制',
          'status': 'PASS',
          'details':
              '单文件限制: ${_formatBytes(maxSize)}, 总大小限制: ${_formatBytes(totalSize)}',
        };
      } else {
        return {
          'name': '文件大小限制',
          'status': 'FAIL',
          'details': '文件大小限制配置无效',
        };
      }
    } catch (e) {
      return {
        'name': '文件大小限制',
        'status': 'ERROR',
        'details': '检查过程中出错: $e',
      };
    }
  }

  static Map<String, dynamic> _checkSafeDirectories() {
    try {
      final status = fileSecurityValidator.getSecurityStatus();
      final safeDirs = status['safe_directories'] as List;

      if (safeDirs.isNotEmpty) {
        return {
          'name': '安全目录配置',
          'status': 'PASS',
          'details': '配置了 ${safeDirs.length} 个安全目录',
        };
      } else {
        return {
          'name': '安全目录配置',
          'status': 'FAIL',
          'details': '未配置安全目录',
        };
      }
    } catch (e) {
      return {
        'name': '安全目录配置',
        'status': 'ERROR',
        'details': '检查过程中出错: $e',
      };
    }
  }

  static Map<String, dynamic> _checkAuditLogging() {
    try {
      final stats = securityAuditService.getAuditStatistics();
      final totalLogs = stats['total_logs'] as int;

      if (totalLogs >= 0) {
        return {
          'name': '审计日志记录',
          'status': 'PASS',
          'details': '已记录 $totalLogs 条审计日志',
        };
      } else {
        return {
          'name': '审计日志记录',
          'status': 'FAIL',
          'details': '审计日志计数无效',
        };
      }
    } catch (e) {
      return {
        'name': '审计日志记录',
        'status': 'ERROR',
        'details': '检查过程中出错: $e',
      };
    }
  }

  static Map<String, dynamic> _checkAlertSystem() {
    try {
      final stats = securityAuditService.getAuditStatistics();
      final totalAlerts = stats['total_alerts'] as int;

      if (totalAlerts >= 0) {
        return {
          'name': '安全警报系统',
          'status': 'PASS',
          'details': '已生成 $totalAlerts 个安全警报',
        };
      } else {
        return {
          'name': '安全警报系统',
          'status': 'FAIL',
          'details': '安全警报计数无效',
        };
      }
    } catch (e) {
      return {
        'name': '安全警报系统',
        'status': 'ERROR',
        'details': '检查过程中出错: $e',
      };
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return '🟢';
      case AlertSeverity.medium:
        return '🟡';
      case AlertSeverity.high:
        return '🟠';
      case AlertSeverity.critical:
        return '🔴';
    }
  }
}
