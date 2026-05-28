/// MuseFlow上下文管理服务包
///
/// 提供完整的上下文管理功能，包括：
/// - 滑动窗口管理
/// - 重要性评分
/// - Token估算
/// - 智能摘要
/// - 分段存储
library;

export 'context_segment.dart';
export 'context_cache.dart';
export 'context_manager.dart';

/// 上下文管理服务版本
const String contextVersion = '1.0.0';

/// 便捷访问单例
ContextManager get contextManager => ContextManager.getInstance();
