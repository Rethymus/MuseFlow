import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import '../lib/utils/file_security_validator.dart';
import '../lib/services/security_audit_service.dart';

void main() {
  group('FileSecurityValidator Tests', () {
    late FileSecurityValidator validator;

    setUp(() async {
      validator = FileSecurityValidator.instance;
      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('应该检测路径遍历攻击', () async {
      // 测试各种路径遍历模式
      final pathTraversalCases = [
        '../../../etc/passwd',
        '..\\..\\..\\windows\\system32',
        '/etc/passwd',
        './../../../sensitive_file.txt',
        '../../config/database.yml',
        '..\\..\\config\\app.json',
      ];

      for (final testCase in pathTraversalCases) {
        final result = await validator.validatePath(testCase);
        expect(result.isValid, false, reason: '应该拒绝路径: $testCase');
        expect(result.errorMessage, isNotNull, reason: '应该有错误信息');
        print('✓ 正确检测到路径遍历攻击: $testCase');
      }
    });

    test('应该检测危险文件扩展名', () async {
      final dangerousFiles = [
        'virus.exe',
        'script.bat',
        'malware.cmd',
        'hack.sh',
        'trojan.ps1',
        'payload.vbs',
        'malicious.jar',
      ];

      for (final fileName in dangerousFiles) {
        final result = validator.validateFileType(fileName);
        expect(result.isValid, false, reason: '应该拒绝文件: $fileName');
        print('✓ 正确检测到危险文件: $fileName');
      }
    });

    test('应该允许安全的文件扩展名', () async {
      final safeFiles = [
        'document.txt',
        'notes.md',
        'data.json',
        'image.png',
        'photo.jpg',
        'audio.mp3',
        'video.mp4',
        'archive.zip',
      ];

      for (final fileName in safeFiles) {
        final result = validator.validateFileType(fileName);
        expect(result.isValid, true, reason: '应该允许文件: $fileName');
        print('✓ 正确允许安全文件: $fileName');
      }
    });

    test('应该检测过长文件名', () async {
      final longFileName = 'a' * 300 + '.txt';
      final result = await validator.validatePath(longFileName);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('文件名过长'));
      print('✓ 正确检测到过长文件名');
    });

    test('应该检测禁止的文件名模式', () async {
      final forbiddenPatterns = [
        'thumbs.db',
        '.DS_Store',
        '._file',
        '.spotlight-v100',
        '.Trash',
        '~$temporary.doc',
      ];

      for (final pattern in forbiddenPatterns) {
        final result = await validator.validatePath(pattern);
        expect(result.isValid, false, reason: '应该拒绝文件名: $pattern');
        print('✓ 正确检测到禁止的文件名模式: $pattern');
      }
    });

    test('应该正确验证文件大小', () async {
      // 创建一个测试文件
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test_large_file.txt');

      try {
        // 创建超过大小限制的文件
        final largeContent = 'x' * (11 * 1024 * 1024); // 11MB
        await testFile.writeAsString(largeContent);

        final result = await validator.validateFileSize(testFile.path);
        expect(result.isValid, false);
        expect(result.errorMessage, contains('文件过大'));
        print('✓ 正确检测到文件大小超限');
      } finally {
        // 清理测试文件
        if (await testFile.exists()) {
          await testFile.delete();
        }
      }
    });

    test('应该创建安全的输出路径', () async {
      final safePath = await validator.createSafeOutputPath(
        'test_file.txt',
        'test_exports',
      );

      expect(safePath, isNotNull);
      expect(safePath, contains('museflow'));
      expect(safePath, contains('test_exports'));
      expect(safePath, endsWith('.txt'));

      print('✓ 正确创建安全的输出路径: $safePath');
    });

    test('应该清理文件名中的危险字符', () async {
      // 注意：_sanitizeFileName是私有方法，我们通过createSafeOutputPath间接测试
      final safePath = await validator.createSafeOutputPath(
        'test<>:"|?*file.txt',
        'test_sanitized',
      );

      expect(safePath, isNotNull);
      expect(safePath, contains('test'));
      expect(safePath, isNot(contains(RegExp(r'[<>:"|?*\\]'))));

      print('✓ 正确清理危险字符: $safePath');
    });

    test('应该维护会话大小限制', () async {
      final initialSize = validator.getCurrentSessionSize();
      validator.updateSessionSize(1024 * 1024); // 1MB
      expect(validator.getCurrentSessionSize(), initialSize + 1024 * 1024);
      print('✓ 正确维护会话大小');

      validator.resetSessionSize();
      expect(validator.getCurrentSessionSize(), 0);
      print('✓ 正确重置会话大小');
    });

    test('应该生成安全状态报告', () async {
      final status = validator.getSecurityStatus();

      expect(status, isNotNull);
      expect(status, containsPair('current_session_size', isA<int>()));
      expect(status, containsPair('max_single_file_size', isA<int>()));
      expect(status, containsPair('max_total_size', isA<int>()));
      expect(status, containsPair('safe_directories', isA<List>()));
      expect(status, containsPair('allowed_extensions', isA<List>()));

      print('✓ 生成安全状态报告');
      print('  安全目录数量: ${status['safe_directories'].length}');
      print('  允许的扩展名数量: ${status['allowed_extensions'].length}');
    });

    test('应该记录审计日志', () async {
      final initialLogCount = validator.getAuditLogs().length;

      // 执行一些操作来生成审计日志
      await validator.validatePath('test.txt');
      validator.validateFileType('document.json');
      validator.updateSessionSize(1024);

      final finalLogCount = validator.getAuditLogs().length;
      expect(finalLogCount, greaterThan(initialLogCount));

      print('✓ 正确记录审计日志');
      print('  记录的日志数量: ${finalLogCount - initialLogCount}');
    });
  });

  group('SecurityAuditService Tests', () {
    late SecurityAuditService auditService;

    setUp(() async {
      auditService = SecurityAuditService.instance;
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('应该记录文件操作', () {
      final initialCount = auditService.getRecentLogs().length;

      auditService.logFileOperation(
        operation: 'test_operation',
        filePath: '/test/path/file.txt',
        allowed: true,
        fileSize: 1024,
      );

      final finalCount = auditService.getRecentLogs().length;
      expect(finalCount, greaterThan(initialCount));

      print('✓ 正确记录文件操作');
    });

    test('应该记录被拒绝的操作为安全事件', () {
      final initialAlerts = auditService.getActiveAlerts().length;

      auditService.logFileOperation(
        operation: 'suspicious_operation',
        filePath: '/etc/passwd',
        allowed: false,
        reason: '路径遍历攻击检测',
      );

      final finalAlerts = auditService.getActiveAlerts().length;
      expect(finalAlerts, greaterThan(initialAlerts));

      print('✓ 正确记录被拒绝的操作为安全事件');
    });

    test('应该生成审计统计信息', () {
      final stats = auditService.getAuditStatistics();

      expect(stats, isNotNull);
      expect(stats, containsPair('total_logs', isA<int>()));
      expect(stats, containsPair('total_alerts', isA<int>()));
      expect(stats, containsPair('active_alerts', isA<int>()));

      print('✓ 正确生成审计统计信息');
      print('  总日志数: ${stats['total_logs']}');
      print('  总警报数: ${stats['total_alerts']}');
      print('  活跃警报数: ${stats['active_alerts']}');
    });

    test('应该能够导出审计报告', () async {
      try {
        final reportPath = await auditService.exportAuditReport();
        expect(reportPath, isNotNull);
        expect(await File(reportPath).exists(), true);

        print('✓ 成功导出审计报告: $reportPath');

        // 清理测试文件
        await File(reportPath).delete();
      } catch (e) {
        print('导出审计报告时出错: $e');
        rethrow;
      }
    });

    test('应该能够清理旧日志', () async {
      // 添加一些测试日志
      for (int i = 0; i < 10; i++) {
        auditService.logFileOperation(
          operation: 'test_operation_$i',
          filePath: '/test/path/file_$i.txt',
          allowed: true,
        );
      }

      final beforeCleanup = auditService.getRecentLogs().length;
      await auditService.cleanupOldLogs(maxAge: const Duration(days: 1));
      final afterCleanup = auditService.getRecentLogs().length;

      print('✓ 清理旧日志: 从 $beforeCleanup 到 $afterCleanup');
    });
  });

  group('Integration Tests', () {
    test('应该完整的安全验证流程', () async {
      final validator = FileSecurityValidator.instance;
      final auditService = SecurityAuditService.instance;

      // 模拟完整的文件操作安全检查
      final filePath = '/test/path/document.txt';

      // 1. 路径验证
      final pathResult = await validator.validatePath(filePath);
      expect(pathResult.isValid, true);

      // 2. 类型验证
      final typeResult = validator.validateFileType(filePath);
      expect(typeResult.isValid, true);

      // 3. 记录审计日志
      auditService.logFileOperation(
        operation: 'file_import',
        filePath: filePath,
        allowed: true,
        fileSize: 1024,
      );

      // 4. 检查统计信息
      final securityStatus = validator.getSecurityStatus();
      final auditStats = auditService.getAuditStatistics();

      expect(securityStatus['allowed_operations'], greaterThan(0));
      expect(auditStats['total_logs'], greaterThan(0));

      print('✓ 完整的安全验证流程测试通过');
    });
  });
}
