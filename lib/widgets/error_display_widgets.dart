import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/user_friendly_error_handler.dart';

/// 错误显示组件
///
/// 提供各种错误显示方式，包括横幅、对话框、卡片等
class ErrorDisplayWidgets {
  /// 显示错误横幅
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorBanner(
    BuildContext context,
    UserFriendlyError error, {
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onAction,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Text(error.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  error.description,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: _getSeverityColor(error.severity),
      duration: duration,
      action: onAction != null
          ? SnackBarAction(
              label: '查看详情',
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
      behavior: SnackBarBehavior.floating,
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 显示错误对话框
  static Future<void> showErrorDialog(
    BuildContext context,
    UserFriendlyError error, {
    bool showTechnicalDetails = kDebugMode,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ErrorDialog(
          error: error,
          showTechnicalDetails: showTechnicalDetails,
        );
      },
    );
  }

  /// 创建错误卡片
  static Widget createErrorCard(
    UserFriendlyError error, {
    VoidCallback? onDismiss,
    VoidCallback? onContactSupport,
  }) {
    return Card(
      color: _getSeverityColor(error.severity).withOpacity(0.1),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(error.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              error.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '解决方案：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...error.solutions.asMap().entries.map((entry) {
              final index = entry.key;
              final solution = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getSeverityColor(error.severity),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(solution)),
                  ],
                ),
              );
            }).toList(),
            if (error.helpLink != null) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  // 打开帮助链接
                },
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '查看帮助文档',
                      style: TextStyle(
                        color: _getSeverityColor(error.severity),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (error.contactSupport != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.support_agent, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text('技术支持：${error.contactSupport}')),
                ],
              ),
            ],
            if (showTechnicalDetails && error.technicalDetails != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  '🔧 技术详情',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        error.technicalDetails!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 创建错误通知（用于状态栏或通知中心）
  static Widget createErrorNotification(
    UserFriendlyError error, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getSeverityColor(error.severity),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(error.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    error.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  /// 获取错误严重程度对应的颜色
  static Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.purple;
    }
  }

  static bool get showTechnicalDetails => kDebugMode;
}

/// 错误对话框组件
class _ErrorDialog extends StatelessWidget {
  final UserFriendlyError error;
  final bool showTechnicalDetails;

  const _ErrorDialog({
    required this.error,
    required this.showTechnicalDetails,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(error.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.title,
              style: TextStyle(
                color: ErrorDisplayWidgets._getSeverityColor(error.severity),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.description),
            const SizedBox(height: 16),
            const Text(
              '解决方案：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...error.solutions.asMap().entries.map((entry) {
              final index = entry.key;
              final solution = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ErrorDisplayWidgets._getSeverityColor(error.severity),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(width: 8),
                Expanded(child: Text(solution)),
              ],
                ),
              );
            }).toList(),
            if (error.helpLink != null) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  // 打开帮助链接的实现
                },
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '📚 查看帮助文档',
                      style: TextStyle(
                        color: ErrorDisplayWidgets._getSeverityColor(error.severity),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (error.contactSupport != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.support_agent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('📞 技术支持：${error.contactSupport}'),
                  ),
                ],
              ),
            ],
            if (showTechnicalDetails && error.technicalDetails != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  '🔧 技术详情',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        error.technicalDetails!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
        if (error.severity == ErrorSeverity.critical) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 重启应用的实现
            },
            child: const Text('重启应用'),
          ),
        ],
        if (error.contactSupport != null) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 联系支持的实现
            },
            child: const Text('联系支持'),
          ),
        ],
      ],
    );
  }
}

/// 错误边界组件
///
/// 用于捕获子组件树中的错误并友好显示
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(dynamic error, StackTrace? stackTrace)? errorBuilder;
  final void Function(dynamic error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  dynamic _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _error = null;
    _stackTrace = null;
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    widget.onError?.call(error, stackTrace);

    // 记录错误
    final userFriendlyError = userFriendlyErrorHandler.handleError(error, stackTrace);
    userFriendlyErrorHandler.logError(userFriendlyError);
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error, _stackTrace);
      }

      // 默认错误显示
      final userFriendlyError = userFriendlyErrorHandler.handleError(_error, _stackTrace);
      return Scaffold(
        appBar: AppBar(
          title: const Text('发生错误'),
          backgroundColor: ErrorDisplayWidgets._getSeverityColor(userFriendlyError.severity),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ErrorDisplayWidgets.createErrorCard(
              userFriendlyError,
              onDismiss: _resetError,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _resetError,
          child: const Icon(Icons.refresh),
        ),
      );
    }

    return ErrorHandlingWidget(
      onError: _handleError,
      child: widget.child,
    );
  }
}

/// 错误处理Widget
///
/// 用于包装可能抛出错误的组件
class ErrorHandlingWidget extends SingleChildRenderObjectWidget {
  final void Function(dynamic error, StackTrace stackTrace) onError;

  const ErrorHandlingWidget({
    super.key,
    required this.onError,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ErrorHandlingRenderObject(onError);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _ErrorHandlingRenderObject).onError = onError;
  }
}

class _ErrorHandlingRenderObject extends RenderProxyBox {
  void Function(dynamic error, StackTrace stackTrace) onError;

  _ErrorHandlingRenderObject(this.onError);

  @override
  void performLayout() {
    try {
      super.performLayout();
    } catch (e, stackTrace) {
      onError(e, stackTrace);
      rethrow;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    try {
      super.paint(context, offset);
    } catch (e, stackTrace) {
      onError(e, stackTrace);
      rethrow;
    }
  }
}