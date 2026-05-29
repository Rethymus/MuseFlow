import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/user_friendly_error_handler.dart';
import '../widgets/error_display_widgets.dart';
import '../services/error_handling_service.dart';

// Type aliases for nested types
typedef UserFriendlyError = UserFriendlyErrorHandler.UserFriendlyError;
typedef ErrorSeverity = UserFriendlyErrorHandler.ErrorSeverity;
typedef ErrorCategory = UserFriendlyErrorHandler.ErrorCategory;

/// 错误处理集成示例
///
/// 展示如何在应用中集成和使用用户友好的错误处理系统
class ErrorHandlingExample extends StatelessWidget {
  const ErrorHandlingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '错误处理示例',
      home: const ErrorHandlingDemoScreen(),
      // 全局错误边界
      builder: (context, child) {
        return ErrorBoundary(
          onError: (error, stackTrace) {
            // 全局错误处理
            handleErrorSilently(error, stackTrace);
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// 错误处理演示屏幕
class ErrorHandlingDemoScreen extends StatefulWidget {
  const ErrorHandlingDemoScreen({super.key});

  @override
  State<ErrorHandlingDemoScreen> createState() => _ErrorHandlingDemoScreenState();
}

class _ErrorHandlingDemoScreenState extends State<ErrorHandlingDemoScreen> {
  final List<UserFriendlyError> _errors = [];

  @override
  void initState() {
    super.initState();

    // 监听错误流
    errorHandlingService.errorStream.listen((error) {
      setState(() {
        _errors.add(error);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('错误处理演示'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showErrorStatistics(),
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => _clearErrorHistory(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '点击下面的按钮触发不同类型的错误',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 文件系统错误
          _createErrorButton(
            '文件不存在错误',
            Icons.error_outline,
            Colors.red,
            () => _triggerFileNotFoundError(),
          ),

          // 网络错误
          _createErrorButton(
            '网络连接错误',
            Icons.wifi_off,
            Colors.orange,
            () => _triggerNetworkError(),
          ),

          // 权限错误
          _createErrorButton(
            '权限拒绝错误',
            Icons.lock,
            Colors.purple,
            () => _triggerPermissionError(),
          ),

          // 格式错误
          _createErrorButton(
            '数据格式错误',
            Icons.format_align_left,
            Colors.blue,
            () => _triggerFormatError(),
          ),

          // 超时错误
          _createErrorButton(
            '操作超时错误',
            Icons.access_time,
            Colors.amber,
            () => _triggerTimeoutError(),
          ),

          // 严重错误
          _createErrorButton(
            '严重系统错误',
            Icons.error_outline,
            Colors.deepPurple,
            () => _triggerCriticalError(),
          ),

          const SizedBox(height: 20),
          const Text(
            '最近的错误：',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 错误列表
          if (_errors.isEmpty)
            const Center(
              child: Text('暂无错误记录'),
            )
          else
            ..._errors.reversed.take(5).map((error) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ErrorDisplayWidgets.createErrorNotification(
                  error,
                  onTap: () => _showErrorDetails(error),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _createErrorButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _triggerFileNotFoundError() {
    try {
      // 模拟文件不存在错误
      throw FileSystemException('文件找不到', '/path/to/nonexistent/file.txt');
    } catch (e, stackTrace) {
      errorHandlingService.showError(context, e, stackTrace);
    }
  }

  void _triggerNetworkError() {
    try {
      // 模拟网络错误
      throw SocketException('连接失败');
    } catch (e, stackTrace) {
      errorHandlingService.showError(context, e, stackTrace);
    }
  }

  void _triggerPermissionError() {
    try {
      // 模拟权限错误
      throw PermissionDeniedException('没有访问权限');
    } catch (e, stackTrace) {
      errorHandlingService.showError(context, e, stackTrace);
    }
  }

  void _triggerFormatError() {
    try {
      // 模拟格式错误
      throw FormatException('无效的JSON格式', '{invalid json}', 0);
    } catch (e, stackTrace) {
      errorHandlingService.showError(context, e, stackTrace);
    }
  }

  void _triggerTimeoutError() {
    try {
      // 模拟超时错误
      throw TimeoutException('操作超时', const Duration(seconds: 30));
    } catch (e, stackTrace) {
      errorHandlingService.showError(context, e, stackTrace);
    }
  }

  void _triggerCriticalError() {
    try {
      // 模拟严重错误
      throw Exception('系统核心功能失效');
    } catch (e, stackTrace) {
      errorHandlingService.showError(context, e, stackTrace);
    }
  }

  void _showErrorDetails(UserFriendlyError error) {
    errorHandlingService.showError(context, error);
  }

  void _showErrorStatistics() async {
    final stats = errorHandlingService.getErrorStatistics();
    final patterns = errorHandlingService.analyzeErrorPatterns();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('总错误数: ${stats['total_errors']}'),
            Text('严重错误数: ${stats['critical_errors']}'),
            const SizedBox(height: 16),
            const Text('错误趋势：', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(patterns['trend'] ?? '未知'),
            const SizedBox(height: 16),
            const Text('改进建议：', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(patterns['recommendations'] as List<String>).map((rec) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• $rec'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              final reportPath = await errorHandlingService.createErrorReport();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('错误报告已生成: $reportPath')),
                );
              }
            },
            child: const Text('生成报告'),
          ),
        ],
      ),
    );
  }

  void _clearErrorHistory() {
    errorHandlingService.clearErrorHistory();
    setState(() {
      _errors.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('错误历史已清除')),
    );
  }
}

/// 错误处理最佳实践示例
class ErrorHandlingBestPractices extends StatefulWidget {
  const ErrorHandlingBestPractices({super.key});

  @override
  State<ErrorHandlingBestPractices> createState() => _ErrorHandlingBestPracticesState();
}

class _ErrorHandlingBestPracticesState extends State<ErrorHandlingBestPractices> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('错误处理最佳实践')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 最佳实践1: 使用try-catch包装可能失败的操作
            ElevatedButton(
              onPressed: _isLoading ? null : () => _demonstrateTryCatch(),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('演示 Try-Catch 错误处理'),
            ),

            const SizedBox(height: 16),

            // 最佳实践2: 使用ErrorBoundary包装整个组件树
            ElevatedButton(
              onPressed: () => _demonstrateErrorBoundary(),
              child: const Text('演示 ErrorBoundary'),
            ),

            const SizedBox(height: 16),

            // 最佳实践3: 提供具体的错误信息
            ElevatedButton(
              onPressed: () => _demonstrateSpecificErrors(),
              child: const Text('演示具体错误信息'),
            ),

            const SizedBox(height: 16),

            // 最佳实践4: 使用错误流进行全局错误监听
            ElevatedButton(
              onPressed: () => _demonstrateErrorStream(),
              child: const Text('演示错误流监听'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _demonstrateTryCatch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟异步操作
      await Future.delayed(const Duration(seconds: 1));

      // 模拟可能的错误
      if (DateTime.now().second % 2 == 0) {
        throw Exception('随机错误发生');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作成功完成')),
        );
      }
    } catch (e, stackTrace) {
      // 使用用户友好的错误处理
      await errorHandlingService.showError(context, e, stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _demonstrateErrorBoundary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ErrorBoundary(
          child: _ErrorBoundaryDemo(),
        ),
      ),
    );
  }

  void _demonstrateSpecificErrors() {
    // 展示如何为不同类型的错误提供具体的解决方案
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择错误类型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('文件错误'),
              onTap: () {
                Navigator.of(context).pop();
                _handleFileError();
              },
            ),
            ListTile(
              title: const Text('网络错误'),
              onTap: () {
                Navigator.of(context).pop();
                _handleNetworkError();
              },
            ),
            ListTile(
              title: const Text('权限错误'),
              onTap: () {
                Navigator.of(context).pop();
                _handlePermissionError();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileError() {
    final error = FileSystemException('文件不存在', '/path/to/file.txt');
    errorHandlingService.showError(context, error);
  }

  void _handleNetworkError() {
    final error = SocketException('网络连接失败');
    errorHandlingService.showError(context, error);
  }

  void _handlePermissionError() {
    final error = PermissionDeniedException('没有访问权限');
    errorHandlingService.showError(context, error);
  }

  void _demonstrateErrorStream() {
    // 展示如何监听错误流
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误流监听'),
        content: const Text('触发一些错误以查看流监听效果'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 触发一些错误
              errorHandlingService.handleError(Exception('测试错误1'));
              errorHandlingService.handleError(Exception('测试错误2'));
            },
            child: const Text('触发测试错误'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// ErrorBoundary演示组件
class _ErrorBoundaryDemo extends StatelessWidget {
  const _ErrorBoundaryDemo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ErrorBoundary 演示')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('点击按钮触发错误'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                throw Exception('这是一个测试错误');
              },
              child: const Text('触发错误'),
            ),
          ],
        ),
      ),
    );
  }
}