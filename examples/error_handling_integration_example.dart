import 'package:flutter/material.dart';
import 'package:museflow/services/error_handling_service.dart';
import 'package:museflow/utils/user_friendly_error_handler.dart';
import 'dart:io';
import 'dart:async';

/// BuildContext扩展方法，用于显示错误
extension BuildContextErrorExtension on BuildContext {
  Future<void> showError(Object error, StackTrace? stackTrace) async {
    final message = error.toString();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text('发生错误: $message'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '确定',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void showErrorBanner(Object error, StackTrace? stackTrace) {
    final message = error.toString();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text('错误: $message'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 安全执行异步操作，自动处理错误
  Future<T> safeAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await showError(error, stackTrace);
      rethrow;
    }
  }
}

/// 权限拒绝异常
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

/// 实际项目中的错误处理集成示例
///
/// 这个文件展示了如何在MuseFlow项目的实际场景中
/// 集成和使用用户友好的错误处理系统
class ErrorHandlingIntegrationExample {

  /// 示例1: 文件导出功能的错误处理
  static Future<void> fileExportWithErrorHandling(BuildContext context) async {
    try {
      // 1. 获取要导出的数据
      final data = await _fetchExportData();

      // 2. 验证文件路径
      final path = await _getExportPath();
      if (path == null) {
        throw Exception('无法获取导出路径');
      }

      // 3. 执行文件导出
      await _writeFile(path, data);

      // 4. 显示成功消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件导出成功')),
        );
      }
    } catch (error, stackTrace) {
      // 错误会被自动转换为用户友好的格式
      if (context.mounted) {
        // 使用扩展方法显示错误
        await context.showError(error, stackTrace);
      }
    }
  }

  /// 示例2: AI服务调用的错误处理
  static Future<String> aiServiceCallWithErrorHandling(
    BuildContext context,
    String prompt,
  ) async {
    try {
      // 模拟AI服务调用
      final response = await _callAIService(prompt);
      return response;
    } on SocketException catch (e, stackTrace) {
      // 网络错误会被识别并提供网络相关的解决方案
      if (context.mounted) {
        await context.showError(e, stackTrace);
      }
      throw e;
    } on TimeoutException catch (e, stackTrace) {
      // 超时错误会被识别并提供超时相关的解决方案
      if (context.mounted) {
        await context.showError(e, stackTrace);
      }
      throw e;
    } catch (error, stackTrace) {
      // 其他错误也会被适当处理
      if (context.mounted) {
        await context.showError(error, stackTrace);
      }
      throw error;
    }
  }

  /// 示例3: 用户偏好设置的错误处理
  static Future<void> savePreferencesWithErrorHandling(
    BuildContext context,
    Map<String, dynamic> preferences,
  ) async {
    try {
      // 验证偏好设置数据
      _validatePreferences(preferences);

      // 保存到存储
      await _savePreferences(preferences);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('偏好设置已保存')),
        );
      }
    } on FormatException catch (e, stackTrace) {
      // 格式错误会被识别为数据格式问题
      if (context.mounted) {
        await context.showError(e, stackTrace);
      }
    } on FileSystemException catch (e, stackTrace) {
      // 文件系统错误会被识别为存储问题
      if (context.mounted) {
        await context.showError(e, stackTrace);
      }
    } catch (error, stackTrace) {
      // 其他错误
      if (context.mounted) {
        await context.showError(error, stackTrace);
      }
    }
  }

  /// 示例4: 数据导入功能的错误处理
  static Future<void> dataImportWithErrorHandling(
    BuildContext context,
    String filePath,
  ) async {
    try {
      // 1. 验证文件
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('文件不存在', filePath);
      }

      // 2. 读取文件内容
      final content = await file.readAsString();

      // 3. 验证数据格式
      final data = _parseImportData(content);

      // 4. 导入数据
      await _importData(data);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导入成功')),
        );
      }
    } catch (error, stackTrace) {
      if (context.mounted) {
        // 显示用户友好的错误信息
        await context.showError(error, stackTrace);
      }
    }
  }

  /// 示例5: 批量操作的错误处理
  static Future<void> batchOperationWithErrorHandling(
    BuildContext context,
    List<String> items,
  ) async {
    final errors = <String>[];
    var successCount = 0;

    for (final item in items) {
      try {
        await _processItem(item);
        successCount++;
      } catch (error, stackTrace) {
        // 记录错误但继续处理其他项目
        errors.add('$item: ${error.toString()}');

        // 可选：显示单个错误的横幅
        if (context.mounted) {
          context.showErrorBanner(error, stackTrace);
        }
      }
    }

    // 显示批量操作结果
    if (context.mounted) {
      final message = '处理完成: 成功 $successCount 个，失败 ${errors.length} 个';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      // 如果有错误，可以选择显示详细报告
      if (errors.isNotEmpty) {
        await _showBatchOperationErrors(context, errors);
      }
    }
  }

  /// 示例6: 长时间运行任务的错误处理
  static Future<void> longRunningTaskWithErrorHandling(
    BuildContext context,
  ) async {
    // 显示进度对话框
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('处理中...'),
            ],
          ),
        ),
      );
    }

    try {
      // 执行长时间运行的任务
      await _executeLongRunningTask();

      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务完成')),
        );
      }
    } catch (error, stackTrace) {
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        // 显示错误
        await context.showError(error, stackTrace);
      }
    }
  }

  /// 示例7: 权限请求的错误处理
  static Future<bool> requestPermissionWithErrorHandling(
    BuildContext context,
    String permission,
  ) async {
    try {
      // 请求权限
      final granted = await _requestPermission(permission);

      if (!granted) {
        throw PermissionDeniedException('权限被拒绝: $permission');
      }

      return true;
    } on PermissionDeniedException catch (e, stackTrace) {
      // 权限错误会被识别并提供具体的解决方案
      if (context.mounted) {
        await context.showError(e, stackTrace);
      }
      return false;
    } catch (error, stackTrace) {
      if (context.mounted) {
        await context.showError(error, stackTrace);
      }
      return false;
    }
  }

  /// 示例8: 网络请求的重试机制
  static Future<T> networkRequestWithRetry<T>(
    BuildContext context,
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    var lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await request();
      } catch (error, stackTrace) {
        lastError = error;

        // 如果是最后一次尝试，显示错误
        if (attempt == maxRetries) {
          if (context.mounted) {
            await context.showError(error, stackTrace);
          }
          throw error;
        }

        // 显示重试提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('请求失败，第 $attempt 次重试中...'),
              duration: retryDelay,
            ),
          );
        }

        // 等待后重试
        await Future.delayed(retryDelay);
      }
    }

    throw lastError;
  }

  // 辅助方法

  static Future<String> _fetchExportData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 'export data';
  }

  static Future<String?> _getExportPath() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return '/path/to/export.txt';
  }

  static Future<void> _writeFile(String path, String data) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // 模拟可能的文件错误
    if (DateTime.now().second % 10 == 0) {
      throw FileSystemException('磁盘空间不足', path);
    }
  }

  static Future<String> _callAIService(String prompt) async {
    await Future.delayed(const Duration(seconds: 2));
    // 模拟可能的AI服务错误
    if (DateTime.now().second % 8 == 0) {
      throw SocketException('AI服务连接失败');
    }
    return 'AI response';
  }

  static void _validatePreferences(Map<String, dynamic> preferences) {
    // 模拟验证逻辑
    if (preferences.containsKey('invalid')) {
      throw FormatException('无效的偏好设置');
    }
  }

  static Future<void> _savePreferences(Map<String, dynamic> preferences) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // 模拟可能的存储错误
    if (DateTime.now().second % 15 == 0) {
      throw FileSystemException('存储失败', '/preferences.json');
    }
  }

  static dynamic _parseImportData(String content) {
    // 模拟解析逻辑
    if (content.contains('invalid')) {
      throw FormatException('数据格式错误');
    }
    return {'data': content};
  }

  static Future<void> _importData(dynamic data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static Future<void> _processItem(String item) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // 模拟处理错误
    if (item.contains('error')) {
      throw Exception('处理失败: $item');
    }
  }

  static Future<void> _showBatchOperationErrors(
    BuildContext context,
    List<String> errors,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量操作错误'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: errors.map((error) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(error, style: const TextStyle(fontSize: 12)),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  static Future<void> _executeLongRunningTask() async {
    await Future.delayed(const Duration(seconds: 3));
    // 模拟可能的错误
    if (DateTime.now().second % 20 == 0) {
      throw Exception('长时间运行任务失败');
    }
  }

  static Future<bool> _requestPermission(String permission) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // 模拟权限请求
    return DateTime.now().second % 3 != 0;
  }
}

/// 实际Widget使用示例
class ExampleWidgetWithErrorHandling extends StatefulWidget {
  const ExampleWidgetWithErrorHandling({super.key});

  @override
  State<ExampleWidgetWithErrorHandling> createState() => _ExampleWidgetWithErrorHandlingState();
}

class _ExampleWidgetWithErrorHandlingState extends State<ExampleWidgetWithErrorHandling> {
  bool _isLoading = false;
  String? _result;

  Future<void> _handleButtonClick() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      // 使用安全的异步操作
      final result = await context.safeAsync(() async {
        await Future.delayed(const Duration(seconds: 2));

        // 模拟可能的错误
        if (DateTime.now().second % 4 == 0) {
          throw Exception('随机错误发生');
        }

        return '操作成功完成';
      });

      setState(() {
        _result = result;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('错误处理示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_result != null)
              Text(_result!)
            else
              ElevatedButton(
                onPressed: _isLoading ? null : _handleButtonClick,
                child: const Text('执行操作'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 使用错误流监控的全局状态管理示例
class GlobalErrorMonitoring extends StatefulWidget {
  const GlobalErrorMonitoring({super.key});

  @override
  State<GlobalErrorMonitoring> createState() => _GlobalErrorMonitoringState();
}

class _GlobalErrorMonitoringState extends State<GlobalErrorMonitoring> {
  final List<String> _recentErrors = [];
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();

    // 监听全局错误流
    _errorSubscription = ErrorHandlingService.instance.errorStream.listen((error) {
      setState(() {
        _recentErrors.add(error.title);
      });

      // 可以根据错误严重程度采取不同行动
      if (error.severity == UserFriendlyErrorHandler.UserFriendlyErrorHandler.ErrorSeverity.critical) {
        _handleCriticalError(error);
      }
    });
  }

  void _handleCriticalError(UserFriendlyErrorHandler.UserFriendlyError error) {
    // 处理严重错误
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('严重错误'),
        content: Text('检测到严重错误: ${error.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () {
              // 重启应用
            },
            child: const Text('重启'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全局错误监控'),
        actions: [
          IconButton(
            icon: const Icon(Icons.error_outline),
            onPressed: () => _showErrorStatistics(),
          ),
        ],
      ),
      body: _recentErrors.isEmpty
          ? const Center(child: Text('暂无错误'))
          : ListView.builder(
              itemCount: _recentErrors.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_recentErrors[index]),
                leading: const Icon(Icons.warning, color: Colors.orange),
              ),
            ),
    );
  }

  void _showErrorStatistics() async {
    final stats = ErrorHandlingService.instance.getErrorStatistics();
    final patterns = ErrorHandlingService.instance.analyzeErrorPatterns();

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
            Text('错误趋势: ${patterns['trend']}'),
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
        ],
      ),
    );
  }
}