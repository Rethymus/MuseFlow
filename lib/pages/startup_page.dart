import 'package:flutter/material.dart';
import '../services/progressive_initializer.dart';
import '../config/app_constants.dart';

/// 启动页面
///
/// 显示初始化进度，提供视觉反馈
class StartupPage extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const StartupPage({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage>
    with SingleTickerProviderStateMixin {
  late ProgressiveInitializer _initializer;
  late InitializationListener _listener;
  double _progress = 0.0;
  String _message = '正在启动...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializer = ProgressiveInitializer.instance;
    _listener = InitializationListener(_initializer);

    _startInitialization();
  }

  Future<void> _startInitialization() async {
    // 监听初始化状态
    _listener.listen((state) {
      if (mounted) {
        setState(() {
          _progress = state.progress;
          _message = state.message ?? '正在启动...';
          _hasError = !state.isLoading &&
              state.currentPhase != StartupPhase.completed &&
              _progress < 1.0;

          // 如果初始化完成
          if (state.currentPhase == StartupPhase.completed && !_hasError) {
            // 延迟一小段时间让用户看到完成状态
            Future.delayed(AppConstants.mediumDelay, () {
              if (mounted) {
                widget.onInitializationComplete();
              }
            });
          }
        });
      }
    });

    // 开始初始化
    await _initializer.initialize();
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo或应用图标
                _buildLogo(),
                const SizedBox(height: 48),

                // 应用名称
                Text(
                  'MuseFlow',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 64),

                // 进度指示器
                _buildProgressIndicator(),
                const SizedBox(height: 24),

                // 状态消息
                _buildStatusMessage(),

                // 错误提示
                if (_hasError) _buildErrorWarning(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        // 线性进度条
        Container(
          width: 300,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _progress),
              duration: AppConstants.mediumDelay,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  minHeight: 4,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 百分比显示
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: _progress),
          duration: AppConstants.mediumDelay,
          builder: (context, value, child) {
            return Text(
              '${(value * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    return Text(
      _message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '部分功能可能受影响',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
          ),
        ],
      ),
    );
  }
}

/// 启动屏幕包装器
///
/// 用于在app启动时显示启动屏幕
class StartupScreenWrapper extends StatefulWidget {
  final Widget child;

  const StartupScreenWrapper({
    super.key,
    required this.child,
  });

  @override
  State<StartupScreenWrapper> createState() => _StartupScreenWrapperState();
}

class _StartupScreenWrapperState extends State<StartupScreenWrapper> {
  bool _showStartupScreen = true;

  @override
  void initState() {
    super.initState();

    // 如果已经初始化完成，直接显示主界面
    if (ProgressiveInitializer.instance.isInitialized) {
      _showStartupScreen = false;
    }
  }

  void _onInitializationComplete() {
    if (mounted) {
      setState(() {
        _showStartupScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showStartupScreen) {
      return StartupPage(
        onInitializationComplete: _onInitializationComplete,
      );
    }

    return widget.child;
  }
}
