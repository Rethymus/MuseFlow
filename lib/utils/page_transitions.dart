import 'package:flutter/material.dart';

/// 页面过渡动画工具类
/// 提供各种页面切换动画效果
class PageTransitions {
  /// 淡入淡出过渡
  static Widget fadeTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// 缩放淡入过渡
  static Widget scaleFadeTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// 滑动淡入过渡
  static Widget slideFadeTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    const begin = Offset(0.0, 0.05); // 从下方轻微滑入
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end);
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    return SlideTransition(
      position: tween.animate(curvedAnimation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

/// 自定义页面过渡路由
class CustomPageTransition extends PageRouteBuilder {
  final Widget child;
  final String transitionType;

  CustomPageTransition({
    required this.child,
    this.transitionType = 'fade',
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    switch (transitionType) {
      case 'scale':
        return PageTransitions.scaleFadeTransition(
            context, animation, secondaryAnimation, child);
      case 'slide':
        return PageTransitions.slideFadeTransition(
            context, animation, secondaryAnimation, child);
      case 'fade':
      default:
        return PageTransitions.fadeTransition(
            context, animation, secondaryAnimation, child);
    }
  }
}

/// 页面切换动画包装器
/// 用于主导航容器中的页面切换
class PageSwitchAnimation extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final int previousIndex;

  const PageSwitchAnimation({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.previousIndex,
  });

  @override
  State<PageSwitchAnimation> createState() => _PageSwitchAnimationState();
}

class _PageSwitchAnimationState extends State<PageSwitchAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // 启动动画
    _animationController.forward();
  }

  @override
  void didUpdateWidget(PageSwitchAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != widget.previousIndex) {
      // 页面切换时重新启动动画
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}
