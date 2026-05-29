import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'config/app_constants.dart';
import 'utils/logger.dart';
import 'dart:io';

// 导入原有的模块
import 'pages/home_page.dart';
import 'pages/startup_page.dart';
import 'services/progressive_initializer.dart';
import 'services/startup_monitor.dart';
import 'services/window_service.dart';
import 'services/error_handling_service.dart';
import 'models/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/error_display_widgets.dart';
import 'utils/user_friendly_error_handler.dart';
import 'config/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 开始启动性能监控
  StartupMonitor.instance.startMonitoring();

  // 初始化错误处理服务
  ErrorHandlingService.instance;

  // 设置全局错误处理
  FlutterError.onError = (details) {
    ErrorHandlingService.instance.handleError(details.exception, details.stack);
  };

  // 初始化渐进式初始化器
  await ProgressiveInitializer.instance.initialize();

  // Initialize Window Manager for Desktop
  await WindowService.instance.initializeWindow();

  // 记录启动完成
  StartupMonitor.instance.recordComplete();

  runApp(const MuseFlowApp());
}

class MuseFlowApp extends StatelessWidget {
  const MuseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        // 全局错误处理
        ErrorHandlingService.instance.handleError(error, stackTrace);
      },
      child: ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          title: 'MuseFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const StartupScreenWrapper(
            child: HomePage(),
          ),
          // 全局错误构建器
          builder: (context, child) {
            return ErrorHandlingWidget(
              onError: (error, stackTrace) {
                ErrorHandlingService.instance.handleError(error, stackTrace);
              },
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

/// 带有错误处理的启动页面包装器
class StartupScreenWrapper extends StatefulWidget {
  final Widget child;

  const StartupScreenWrapper({super.key, required this.child});

  @override
  State<StartupScreenWrapper> createState() => _StartupScreenWrapperState();
}

class _StartupScreenWrapperState extends State<StartupScreenWrapper> {
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeWithErrorHandling();
  }

  Future<void> _initializeWithErrorHandling() async {
    try {
      // 模拟初始化过程
      await Future.delayed(AppConstants.initializationDelay);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error, stackTrace) {
      // 处理初始化错误
      if (mounted) {
        setState(() {
          _initializationError = error.toString();
        });

        // 显示错误对话框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ErrorHandlingService.instance.showError(context, error, stackTrace);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      // 显示错误页面
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: AppConstants.massiveIconSize, color: Colors.red),
              const SizedBox(height: AppConstants.standardSpacing),
              const Text('初始化失败', style: TextStyle(fontSize: AppConstants.hugeFontSize)),
              const SizedBox(height: AppConstants.smallSpacing),
              ElevatedButton(
                onPressed: () {
                  // 重启应用
                  main();
                },
                child: const Text('重新启动'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return StartupPage(onInitializationComplete: () {});
    }

    return widget.child;
  }
}

/// 带有错误处理的文件操作示例
class SafeFileOperations extends StatelessWidget {
  const SafeFileOperations({super.key});

  Future<void> _saveFileWithErrorHandling(String content, String path) async {
    try {
      // 尝试保存文件
      await File(path).writeAsString(content);

      // 显示成功消息
      Logger.debug('文件保存成功', tag: 'FILE');
    } catch (error, stackTrace) {
      // 获取当前上下文
      final context = GlobalKey<ScaffoldState>().currentContext;
      if (context != null) {
        await ErrorHandlingService.instance.showError(context, error, stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// 带有错误处理的网络请求示例
class SafeNetworkRequests extends StatelessWidget {
  const SafeNetworkRequests({super.key});

  Future<void> _makeRequestWithErrorHandling(String url) async {
    try {
      // 模拟网络请求
      await Future.delayed(AppConstants.extraLongDelay);

      // 模拟可能的网络错误
      if (DateTime.now().second % 3 == 0) {
        throw SocketException('网络连接失败');
      }

      Logger.debug('请求成功', tag: 'API');
    } catch (error, stackTrace) {
      // 网络错误会被自动转换为用户友好的格式
      // 并提供具体的解决建议
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// 带有错误处理的AI服务调用示例
class SafeAIServiceCalls extends StatelessWidget {
  const SafeAIServiceCalls({super.key});

  Future<String> _callAIServiceWithErrorHandling(String prompt) async {
    try {
      // 模拟AI服务调用
      await Future.delayed(AppConstants.simulatedDelay);

      // 模拟可能的AI服务错误
      if (DateTime.now().second % 5 == 0) {
        throw Exception('AI服务暂时不可用');
      }

      return 'AI响应内容';
    } catch (error, stackTrace) {
      // AI服务错误会被自动识别并提供相关解决方案
      // 包括：检查API密钥、查看服务状态、联系支持等
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// 错误处理最佳实践示例
class ErrorHandlingBestPractices {
  /// 最佳实践1: 使用try-catch包装所有可能失败的操作
  static Future<T> safeExecute<T>(
    Future<T> Function() operation, {
    void Function(dynamic error, StackTrace? stackTrace)? onError,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }

  /// 最佳实践2: 提供有意义的错误上下文
  static Future<T> contextualExecute<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      // 添加操作上下文信息
      final contextualError = Exception('$operationName 失败: $error');
      throw contextualError;
    }
  }

  /// 最佳实践3: 使用错误流进行全局监控
  static void setupGlobalErrorMonitoring() {
    ErrorHandlingService.instance.errorStream.listen((error) {
      // 记录到分析服务
      Logger.info('全局错误监控: ${error.title}', tag: 'ERROR');

      // 可以发送到崩溃报告服务
      // Crashlytics.instance.recordError(error, null);

      // 可以根据严重程度采取不同行动
      if (error.severity == ErrorSeverity.critical) {
        // 发送紧急通知
        Logger.error('严重错误发生！', tag: 'ERROR');
      }
    });
  }

  /// 最佳实践4: 定期错误报告和分析
  static void setupPeriodicErrorReporting() {
    // 每天生成错误报告
    // Timer.periodic(const Duration(days: 1), (_) async {
    //   final reportPath = await ErrorHandlingService.instance.createErrorReport();
    //   Logger.info('每日错误报告: $reportPath', tag: 'REPORT');
    // });
  }
}

/// 用户友好的错误处理器扩展
extension ErrorHandlingExtensions on BuildContext {
  /// 便捷方法：显示错误
  Future<void> showError(dynamic error, [dynamic stackTrace]) async {
    await ErrorHandlingService.instance.showError(this, error, stackTrace);
  }

  /// 便捷方法：显示错误横幅
  void showErrorBanner(dynamic error, [dynamic stackTrace]) {
    ErrorHandlingService.instance.showErrorBanner(this, error, stackTrace);
  }

  /// 便捷方法：安全执行异步操作
  Future<T?> safeAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await showError(error, stackTrace);
      return null;
    }
  }
}