import '../../config/app_constants.dart';
import '../../utils/logger.dart';

/// MuseFlow上下文管理系统使用示例
///
/// 演示如何使用上下文管理器的各种功能

import 'context_services.dart';
import '../../config/app_constants.dart';
import '../../utils/logger.dart';

/// 基础使用示例
void basicUsageExample() {
  // 获取上下文管理器实例
  final manager = ContextManager.getInstance();

  // 添加用户消息
  manager.addSegment(
    type: SegmentType.userMessage,
    content: '你好，我想写一篇关于AI的文章',
    importanceScore: 0.8, // 设置较高重要性
  );

  // 添加系统响应
  manager.addSegment(
    type: SegmentType.systemResponse,
    content: '好的，我可以帮你构思文章大纲',
  );

  // 获取所有片段
  final allSegments = manager.getAllSegments();
  Logger.debug('当前共有 ${allSegments.length} 个片段');

  // 获取格式化的上下文
  final context = manager.getFormattedContext();
  Logger.debug('格式化上下文：\n$context');
}

/// 对话管理示例
void conversationManagementExample() {
  final manager = ContextManager.getInstance(
    const ContextManagerConfig(
      maxTokens: 8000,
      enableSlidingWindow: true,
      enableImportanceScoring: true,
      enableSummarization: true,
    ),
  );

  // 添加系统提示（锁定，不会被裁剪）
  manager.addSegment(
    type: SegmentType.systemPrompt,
    content: '你是一个专业的写作助手',
    isLocked: true,
  );

  // 模拟对话
  final conversation = [
    ('user', '我需要写一篇文章'),
    ('assistant', '好的，请告诉我主题'),
    ('user', '主题是人工智能的未来'),
    ('assistant', '这是个很有趣的主题'),
  ];

  for (final (role, content) in conversation) {
    final type =
        role == 'user' ? SegmentType.userMessage : SegmentType.systemResponse;

    manager.addSegment(
      type: type,
      content: content,
    );
  }

  // 获取最近对话
  final recentMessages = manager.getRecentSegments(3);
  Logger.debug('最近3条消息：');
  for (final message in recentMessages) {
    Logger.debug('  ${message.type}: ${message.content}');
  }

  // 查看统计信息
  final stats = manager.getStats();
  Logger.debug('统计信息：$stats');
}

/// 搜索和查询示例
void searchExample() {
  final manager = ContextManager.getInstance();

  // 添加多个片段
  manager.addSegment(
    type: SegmentType.userMessage,
    content: '我喜欢写小说，特别是科幻类型',
    metadata: {'category': 'writing'},
  );

  manager.addSegment(
    type: SegmentType.userMessage,
    content: '我也喜欢写散文和诗歌',
    metadata: {'category': 'writing'},
  );

  manager.addSegment(
    type: SegmentType.systemResponse,
    content: '我也喜欢编程和数学',
    metadata: {'category': 'tech'},
  );

  // 搜索包含"写"的内容
  final writingResults = manager.search('写');
  Logger.debug('包含"写"的片段：${writingResults.length}个');
  for (final result in writingResults) {
    Logger.debug('  ${result.content}');
  }

  // 按类型查询
  final userMessages = manager.getSegmentsByType(SegmentType.userMessage);
  Logger.debug('用户消息：${userMessages.length}条');
}

/// 监听变化示例
void changeListenerExample() {
  final manager = ContextManager.getInstance();

  // 监听上下文变化
  final subscription = manager.onChange.listen((change) {
    Logger.debug('上下文变化：${change.type} - ${change.segmentId}');
  });

  // 添加片段
  manager.addSegment(
    type: SegmentType.userMessage,
    content: '测试消息',
  );

  // 更新片段
  final segments = manager.getAllSegments();
  if (segments.isNotEmpty) {
    manager.updateSegment(
      segments.first.id,
      content: '更新后的消息',
    );
  }

  // 清理
  subscription.cancel();
}

/// 滑动窗口示例
void slidingWindowExample() {
  final manager = ContextManager.getInstance(
    const ContextManagerConfig(
      maxTokens: 1000, // 设置较小的限制以便演示
      enableSlidingWindow: true,
      enableSummarization: true,
    ),
  );

  Logger.debug('初始状态：');
  Logger.debug(manager.getStats());

  // 添加大量内容
  for (var i = 0; i < 20; i++) {
    manager.addSegment(
      type: SegmentType.userMessage,
      content: '这是第${i + 1}条消息。' * 10, // 让每条消息有一定长度
    );

    if (i % 5 == 4) {
      Logger.debug('添加${i + 1}条后：${manager.getStats()}');
    }
  }

  Logger.debug('最终状态：');
  Logger.debug(manager.getStats());

  // 查看摘要
  final summaries = manager.getAllSegments().where((s) => s.isSummary).toList();
  Logger.debug('创建了${summaries.length}个摘要');
}

/// 完整工作流示例
void completeWorkflowExample() async {
  // 1. 初始化配置
  final config = const ContextManagerConfig(
    maxTokens: 8000,
    enableSlidingWindow: true,
    enableImportanceScoring: true,
    enableSummarization: true,
    keepSummaryAtStart: true,
  );

  final manager = ContextManager.getInstance(config);

  // 2. 设置系统提示
  manager.addSegment(
    type: SegmentType.systemPrompt,
    content: '''
你是一个专业的写作助手，擅长帮助用户构思、修改和完善文章。
你的回答应该：
1. 清晰明了
2. 具有建设性
3. 考虑用户的写作风格
''',
    isLocked: true, // 锁定重要内容
  );

  // 3. 开始对话
  Logger.debug('开始对话...\n');

  // 用户第一句话
  manager.addSegment(
    type: SegmentType.userMessage,
    content: '我想写一篇关于人工智能的未来发展趋势的文章',
    importanceScore: 0.9, // 高重要性
  );

  // 系统回应
  manager.addSegment(
    type: SegmentType.systemResponse,
    content: '''很好的主题！我们可以从以下几个角度来构思：

1. 技术发展趋势
2. 社会影响
3. 伦理考量
4. 未来展望

你希望从哪个角度开始？''',
  );

  // 用户追问
  manager.addSegment(
    type: SegmentType.userMessage,
    content: '我想重点讨论技术发展趋势和社会影响',
  );

  // 4. 查看当前上下文
  Logger.debug('当前对话状态：');
  final stats = manager.getStats();
  Logger.debug(stats);
  Logger.debug('');

  // 5. 获取格式化的上下文
  Logger.debug('当前对话内容：');
  Logger.debug(manager.getFormattedContext());
  Logger.debug('');

  // 6. 搜索相关内容
  Logger.debug('搜索"技术"相关内容：');
  final techResults = manager.search('技术');
  for (final result in techResults) {
    Logger.debug('  ${result.type}: ${result.content.substring(0, 50)}...');
  }
  Logger.debug('');

  // 7. 获取最近的对话
  Logger.debug('最近的2条消息：');
  final recent = manager.getRecentSegments(2);
  for (final message in recent) {
    Logger.debug('  ${message.type}: ${message.content}');
  }
  Logger.debug('');

  // 8. 演示长对话的自动管理
  Logger.debug('模拟长对话...');
  for (var i = 0; i < 30; i++) {
    manager.addSegment(
      type: i % 2 == 0 ? SegmentType.userMessage : SegmentType.systemResponse,
      content: '这是第${i + 1}轮对话的内容。' * 15,
    );
  }

  Logger.debug('长对话后的状态：');
  Logger.debug(manager.getStats());
  Logger.debug('');

  // 9. 查看是否有摘要被创建
  final summaries = manager.getAllSegments().where((s) => s.isSummary).toList();
  if (summaries.isNotEmpty) {
    Logger.debug('已创建${summaries.length}个摘要来压缩对话历史');
    for (final summary in summaries.take(2)) {
      Logger.debug('  摘要: ${summary.content}');
    }
  }

  // 10. 清理
  manager.dispose();
  Logger.debug('对话结束');
}

void main() {
  Logger.debug('=== MuseFlow 上下文管理系统示例 ===\n');

  Logger.debug('1. 基础使用：');
  basicUsageExample();
  Logger.debug('\n' + '=' * 50 + '\n');

  Logger.debug('2. 对话管理：');
  conversationManagementExample();
  Logger.debug('\n' + '=' * 50 + '\n');

  Logger.debug('3. 搜索和查询：');
  searchExample();
  Logger.debug('\n' + '=' * 50 + '\n');

  Logger.debug('4. 监听变化：');
  changeListenerExample();
  Logger.debug('\n' + '=' * 50 + '\n');

  Logger.debug('5. 滑动窗口：');
  slidingWindowExample();
  Logger.debug('\n' + '=' * 50 + '\n');

  Logger.debug('6. 完整工作流：');
  completeWorkflowExample();

  // 重置管理器
  ContextManager.reset();
}
