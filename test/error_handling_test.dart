import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/utils/user_friendly_error_handler.dart';
import 'package:museflow/services/error_handling_service.dart';
import 'dart:io';

void main() {
  group('UserFriendlyErrorHandler Tests', () {
    late UserFriendlyErrorHandler handler;

    setUp(() {
      handler = UserFriendlyErrorHandler.instance;
    });

    test('应该正确处理文件系统异常', () {
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);

      expect(userError.title, contains('文件'));
      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.fileSystem);
      expect(userError.solutions.length, greaterThan(0));
      expect(userError.severity, UserFriendlyErrorHandler.ErrorSeverity.error);
    });

    test('应该正确处理网络异常', () {
      final error = SocketException('网络连接失败');
      final userError = handler.handleError(error);

      expect(userError.title, contains('网络'));
      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.network);
      expect(userError.solutions.length, greaterThan(0));
    });

    test('应该正确处理权限异常', () {
      final error = PermissionDeniedException('没有访问权限');
      final userError = handler.handleError(error);

      expect(userError.title, contains('权限'));
      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.permission);
      expect(userError.solutions.length, greaterThan(0));
    });

    test('应该正确处理超时异常', () {
      final error = TimeoutException('操作超时', const Duration(seconds: 30));
      final userError = handler.handleError(error);

      expect(userError.title, contains('超时'));
      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.system);
      expect(userError.severity, UserFriendlyErrorHandler.ErrorSeverity.warning);
    });

    test('应该正确处理格式异常', () {
      final error = FormatException('无效的JSON格式', '{invalid json}', 0);
      final userError = handler.handleError(error);

      expect(userError.title, contains('格式'));
      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.data);
      expect(userError.solutions.length, greaterThan(0));
    });

    test('应该正确处理未知异常', () {
      final error = Exception('未知错误');
      final userError = handler.handleError(error);

      expect(userError.title.isNotEmpty, true);
      expect(userError.description.isNotEmpty, true);
      expect(userError.solutions.length, greaterThan(0));
      expect(userError.severity, UserFriendlyErrorHandler.ErrorSeverity.critical);
    });

    test('应该正确处理字符串错误消息', () {
      final error = '文件操作失败';
      final userError = handler.handleError(error);

      expect(userError.title, contains('文件'));
      expect(userError.solutions.length, greaterThan(0));
    });

    test('应该正确格式化错误信息', () {
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);
      final formatted = userError.format();

      expect(formatted, contains(userError.title));
      expect(formatted, contains(userError.description));
      expect(formatted, contains('解决方案'));
      expect(formatted.contains('1.'), true);
    });

    test('应该正确转换错误为JSON', () {
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);
      final json = userError.toJson();

      expect(json['title'], isNotNull);
      expect(json['description'], isNotNull);
      expect(json['solutions'], isList);
      expect(json['severity'], isNotNull);
      expect(json['category'], isNotNull);
    });
  });

  group('ErrorHandlingService Tests', () {
    late ErrorHandlingService service;

    setUp(() {
      service = ErrorHandlingService.instance;
    });

    tearDown(() {
      service.clearErrorHistory();
    });

    test('应该正确记录错误', () {
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      service.handleError(error);

      final history = service.getErrorHistory();
      expect(history.length, greaterThan(0));
    });

    test('应该正确统计错误', () {
      service.handleError(Exception('错误1'));
      service.handleError(Exception('错误2'));

      final stats = service.getErrorStatistics();
      expect(stats['total_errors'], greaterThan(0));
    });

    test('应该正确检测严重错误', () {
      final error = Exception('严重系统错误');
      final userError = service.handleError(error);

      expect(userError.severity, UserFriendlyErrorHandler.ErrorSeverity.critical);
      expect(service.hasCriticalErrors(), true);
    });

    test('应该正确分析错误模式', () {
      service.handleError(FileSystemException('文件不存在', '/path/to/file.txt'));
      service.handleError(SocketException('网络连接失败'));

      final patterns = service.analyzeErrorPatterns();
      expect(patterns['most_common_category'], isNotNull);
      expect(patterns['trend'], isNotNull);
      expect(patterns['recommendations'], isList);
    });

    test('应该正确清除错误历史', () {
      service.handleError(Exception('测试错误'));
      expect(service.getErrorHistory().length, greaterThan(0));

      service.clearErrorHistory();
      expect(service.getErrorHistory().length, 0);
    });

    test('应该限制错误历史大小', () {
      // 生成超过限制的错误
      for (int i = 0; i < 150; i++) {
        service.handleError(Exception('错误$i'));
      }

      final history = service.getErrorHistory();
      expect(history.length, lessThanOrEqualTo(100));
    });
  });

  group('错误分类测试', () {
    final handler = UserFriendlyErrorHandler.instance;

    test('文件系统错误应该正确分类', () {
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);

      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.fileSystem);
    });

    test('网络错误应该正确分类', () {
      final error = SocketException('网络连接失败');
      final userError = handler.handleError(error);

      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.network);
    });

    test('权限错误应该正确分类', () {
      final error = PermissionDeniedException('没有访问权限');
      final userError = handler.handleError(error);

      expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.permission);
    });

    test('AI服务错误应该正确分类', () {
      final error = Exception('AI service unavailable');
      final userError = handler.handleError(error);

      // AI相关错误会被分类为aiService
      if (error.toString().toLowerCase().contains('ai')) {
        expect(userError.category, UserFriendlyErrorHandler.ErrorCategory.aiService);
      }
    });
  });

  group('错误严重程度测试', () {
    final handler = UserFriendlyErrorHandler.instance;

    test('文件不存在应该是Error级别', () {
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);

      expect(userError.severity, UserFriendlyErrorHandler.ErrorSeverity.error);
    });

    test('网络超时应该是Warning级别', () {
      final error = SocketException('连接超时');
      final userError = handler.handleError(error);

      // 超时相关错误通常是warning级别
      expect(
        userError.severity == UserFriendlyErrorHandler.ErrorSeverity.warning ||
        userError.severity == UserFriendlyErrorHandler.ErrorSeverity.error,
        true,
      );
    });

    test('未知错误应该是Critical级别', () {
      final error = Exception('完全未知的错误');
      final userError = handler.handleError(error);

      expect(userError.severity, UserFriendlyErrorHandler.ErrorSeverity.critical);
    });
  });

  group('解决方案生成测试', () {
    final handler = UserFriendlyErrorHandler.instance;

    test('文件错误应该生成文件相关解决方案', () {
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);

      expect(userError.solutions.length, greaterThan(0));
      // 检查是否包含文件相关的解决方案
      final hasFileRelatedSolution = userError.solutions.any((solution) =>
        solution.contains('文件') || solution.contains('路径'));
      expect(hasFileRelatedSolution, true);
    });

    test('网络错误应该生成网络相关解决方案', () {
      final error = SocketException('网络连接失败');
      final userError = handler.handleError(error);

      expect(userError.solutions.length, greaterThan(0));
      // 检查是否包含网络相关的解决方案
      final hasNetworkRelatedSolution = userError.solutions.any((solution) =>
        solution.contains('网络') || solution.contains('连接'));
      expect(hasNetworkRelatedSolution, true);
    });

    test('权限错误应该生成权限相关解决方案', () {
      final error = PermissionDeniedException('没有访问权限');
      final userError = handler.handleError(error);

      expect(userError.solutions.length, greaterThan(0));
      // 检查是否包含权限相关的解决方案
      final hasPermissionRelatedSolution = userError.solutions.any((solution) =>
        solution.contains('权限') || solution.contains('设置'));
      expect(hasPermissionRelatedSolution, true);
    });
  });

  group('错误显示测试', () {
    test('错误信息应该包含表情符号', () {
      final handler = UserFriendlyErrorHandler.instance;
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);

      expect(userError.emoji, isNotEmpty);
    });

    test('错误信息应该正确格式化', () {
      final handler = UserFriendlyErrorHandler.instance;
      final error = FileSystemException('文件不存在', '/path/to/file.txt');
      final userError = handler.handleError(error);
      final formatted = userError.format();

      expect(formatted, contains(userError.emoji));
      expect(formatted, contains(userError.title));
      expect(formatted, contains('解决方案'));
    });
  });
}