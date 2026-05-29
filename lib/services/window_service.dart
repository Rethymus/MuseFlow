import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../config/app_constants.dart';

/// 窗口管理服务单例
/// 负责应用程序窗口的初始化和配置
class WindowService {
  // 私有构造函数
  WindowService._();

  // 单例实例
  static final WindowService instance = WindowService._();

  /// 初始化应用程序窗口
  ///
  /// 在支持的桌面平台上（Windows、Linux、macOS）配置和显示窗口
  /// 包括设置窗口尺寸、最小尺寸、居中显示等属性
  Future<void> initializeWindow() async {
    // 检查当前平台是否支持窗口管理
    if (!_isDesktopPlatform()) {
      return;
    }

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(
          AppConstants.defaultWindowWidth, AppConstants.defaultWindowHeight),
      minimumSize:
          Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }

  /// 检查当前平台是否为桌面平台
  bool _isDesktopPlatform() {
    final platform = Theme.of().platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  /// 自定义窗口配置初始化
  ///
  /// 允许使用自定义窗口选项进行初始化
  /// [customOptions] 自定义的窗口配置选项
  Future<void> initializeWindowWithCustomOptions(
      WindowOptions customOptions) async {
    if (!_isDesktopPlatform()) {
      return;
    }

    await windowManager.ensureInitialized();

    await windowManager.waitUntilReadyToShow(customOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }

  /// 获取当前窗口尺寸
  Future<Size> getWindowSize() async {
    return await windowManager.getSize();
  }

  /// 设置窗口尺寸
  ///
  /// [width] 窗口宽度
  /// [height] 窗口高度
  Future<void> setWindowSize(double width, double height) async {
    await windowManager.setSize(Size(width, height));
  }

  /// 最小化窗口
  Future<void> minimizeWindow() async {
    await windowManager.minimize();
  }

  /// 最大化窗口
  Future<void> maximizeWindow() async {
    await windowManager.maximize();
  }

  /// 关闭窗口
  Future<void> closeWindow() async {
    await windowManager.close();
  }
}
