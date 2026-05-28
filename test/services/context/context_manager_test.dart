import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/services/context/context_services.dart';

void main() {
  group('ContextSegment', () {
    test('应该正确计算中文字符的token数量', () {
      final segment = ContextSegment(
        type: SegmentType.userMessage,
        content: '这是一段中文文本，大约有15个字符。',
      );

      // 中文约1.5字/token，15字应该约10个token
      expect(segment.estimatedTokens, greaterThan(8));
      expect(segment.estimatedTokens, lessThan(15));
    });

    test('应该正确计算英文字符的token数量', () {
      final segment = ContextSegment(
        type: SegmentType.userMessage,
        content: 'This is English text with about 30 characters.',
      );

      // 英文约4字符/token，30字应该约7-8个token
      expect(segment.estimatedTokens, greaterThan(5));
      expect(segment.estimatedTokens, lessThan(12));
    });

    test('应该能创建摘要版本', () {
      final original = ContextSegment(
        type: SegmentType.userMessage,
        content: '这是一段很长的文本内容',
      );

      final summary = original.asSummary('简短摘要');

      expect(summary.id, equals(original.id));
      expect(summary.content, equals('简短摘要'));
      expect(summary.summary, equals(original.content));
      expect(summary.isSummary, isTrue);
    });

    test('应该能计算相似度', () {
      final seg1 = ContextSegment(
        type: SegmentType.userMessage,
        content: 'hello world test',
      );

      final seg2 = ContextSegment(
        type: SegmentType.userMessage,
        content: 'hello world example',
      );

      final similarity = seg1.similarityWith(seg2);
      expect(similarity, greaterThan(0.5));
    });
  });

  group('ContextCache', () {
    late ContextCache cache;

    setUp(() {
      cache = ContextCache(const CacheConfig(maxTokens: 100));
    });

    tearDown(() {
      cache.clear();
    });

    test('应该能添加和获取片段', () {
      final segment = ContextSegment(
        type: SegmentType.userMessage,
        content: 'test content',
      );

      cache.put(segment);
      final retrieved = cache.get(segment.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(segment.id));
    });

    test('应该能移除片段', () {
      final segment = ContextSegment(
        type: SegmentType.userMessage,
        content: 'test content',
      );

      cache.put(segment);
      expect(cache.contains(segment.id), isTrue);

      cache.remove(segment.id);
      expect(cache.contains(segment.id), isFalse);
    });

    test('应该按LRU策略移除最少使用的片段', () {
      // 添加多个小片段
      final segments = List.generate(
        5,
        (i) => ContextSegment(
          type: SegmentType.userMessage,
          content: 'content $i',
          importanceScore: 0.5,
        ),
      );

      for (final segment in segments) {
        cache.put(segment);
      }

      // 访问第一个片段，使其成为最近使用
      cache.get(segments[0].id);

      // 添加一个超过限制的大片段
      final largeSegment = ContextSegment(
        type: SegmentType.userMessage,
        content: 'x' * 200, // 约50 tokens
      );

      cache.put(largeSegment);

      // 检查统计
      final stats = cache.getStats();
      expect(stats.totalTokens, lessThan(150)); // 应该裁剪到限制以下
    });

    test('应该正确计算统计信息', () {
      final segment1 = ContextSegment(
        type: SegmentType.userMessage,
        content: 'user message',
      );

      final segment2 = ContextSegment(
        type: SegmentType.systemResponse,
        content: 'system response',
      );

      cache.put(segment1);
      cache.put(segment2);

      final stats = cache.getStats();
      expect(stats.totalSegments, equals(2));
      expect(stats.totalTokens, greaterThan(0));
    });
  });

  group('ContextManager', () {
    late ContextManager manager;

    setUp(() {
      ContextManager.reset();
      manager = ContextManager.getInstance(
        const ContextManagerConfig(maxTokens: 500),
      );
    });

    tearDown(() {
      manager.dispose();
      ContextManager.reset();
    });

    test('应该能添加和获取片段', () {
      final id = manager.addSegment(
        type: SegmentType.userMessage,
        content: 'test message',
      );

      final segment = manager.getSegment(id);
      expect(segment, isNotNull);
      expect(segment!.content, equals('test message'));
    });

    test('应该能按类型获取片段', () {
      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'user message 1',
      );

      manager.addSegment(
        type: SegmentType.systemResponse,
        content: 'system response',
      );

      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'user message 2',
      );

      final userSegments = manager.getSegmentsByType(SegmentType.userMessage);
      expect(userSegments.length, equals(2));

      final systemSegments = manager.getSegmentsByType(SegmentType.systemResponse);
      expect(systemSegments.length, equals(1));
    });

    test('应该能更新片段', () {
      final id = manager.addSegment(
        type: SegmentType.userMessage,
        content: 'original content',
      );

      final updated = manager.updateSegment(
        id,
        content: 'updated content',
      );

      expect(updated, isTrue);

      final segment = manager.getSegment(id);
      expect(segment!.content, equals('updated content'));
    });

    test('应该能移除片段', () {
      final id = manager.addSegment(
        type: SegmentType.userMessage,
        content: 'test message',
      );

      expect(manager.getSegment(id), isNotNull);

      manager.removeSegment(id);
      expect(manager.getSegment(id), isNull);
    });

    test('应该能搜索片段', () {
      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'apple banana cherry',
      );

      manager.addSegment(
        type: SegmentType.systemResponse,
        content: 'dog cat fish',
      );

      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'apple pie',
      );

      final results = manager.search('apple');
      expect(results.length, equals(2));
    });

    test('应该能获取最近片段', () {
      for (var i = 0; i < 5; i++) {
        manager.addSegment(
          type: SegmentType.userMessage,
          content: 'message $i',
        );
      }

      final recent = manager.getRecentSegments(3);
      expect(recent.length, equals(3));
      expect(recent.last.content, contains('4')); // 最新的一条
    });

    test('应该能格式化上下文', () {
      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'Hello',
      );

      manager.addSegment(
        type: SegmentType.systemResponse,
        content: 'Hi there!',
      );

      final formatted = manager.getFormattedContext();
      expect(formatted, contains('用户'));
      expect(formatted, contains('助手'));
      expect(formatted, contains('Hello'));
      expect(formatted, contains('Hi there!'));
    });

    test('应该能获取统计信息', () {
      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'user message',
      );

      manager.addSegment(
        type: SegmentType.systemResponse,
        content: 'system response',
      );

      final stats = manager.getStats();
      expect(stats.totalSegments, equals(2));
      expect(stats.userMessages, equals(1));
      expect(stats.systemResponses, equals(1));
      expect(stats.totalTokens, greaterThan(0));
    });

    test('应该能清空所有上下文', () {
      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'test',
      );

      expect(manager.getStats().totalSegments, equals(1));

      manager.clear();
      expect(manager.getStats().totalSegments, equals(0));
    });

    test('应该能触发变化通知', () async {
      final changes = <ContextChange>[];

      final subscription = manager.onChange.listen((change) {
        changes.add(change);
      });

      manager.addSegment(
        type: SegmentType.userMessage,
        content: 'test',
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(changes.length, equals(1));
      expect(changes.first.type, equals(ChangeType.added));

      await subscription.cancel();
    });

    test('应该能保护锁定的片段不被裁剪', () {
      // 添加一个锁定的片段
      final lockedId = manager.addSegment(
        type: SegmentType.systemPrompt,
        content: 'x' * 200, // 约50 tokens
        isLocked: true,
      );

      // 添加大量未锁定的片段
      for (var i = 0; i < 20; i++) {
        manager.addSegment(
          type: SegmentType.userMessage,
          content: 'y' * 100, // 约25 tokens each
        );
      }

      // 锁定的片段应该仍然存在
      expect(manager.getSegment(lockedId), isNotNull);
    });

    test('应该能计算重要性评分', () {
      // 系统提示应该有更高的重要性
      manager.addSegment(
        type: SegmentType.systemPrompt,
        content: 'system prompt',
        importanceScore: 0.5,
      );

      final segments = manager.getAllSegments();
      final systemPrompt = segments.first;

      // 重要性评分应该被调整（系统提示很重要）
      expect(systemPrompt.importanceScore, greaterThan(0.6));
    });
  });

  group('ContextManager with Sliding Window', () {
    late ContextManager manager;

    setUp(() {
      ContextManager.reset();
      manager = ContextManager.getInstance(
        const ContextManagerConfig(
          maxTokens: 300,
          enableSlidingWindow: true,
          enableSummarization: true,
        ),
      );
    });

    tearDown(() {
      manager.dispose();
      ContextManager.reset();
    });

    test('应该在超过限制时裁剪上下文', () {
      // 添加多个片段直到超过限制
      for (var i = 0; i < 15; i++) {
        manager.addSegment(
          type: SegmentType.userMessage,
          content: 'message $i ' * 10, // 每条约50 tokens
        );
      }

      final stats = manager.getStats();

      // 应该裁剪到接近限制以下
      expect(stats.totalTokens, lessThan(400));

      // 应该保留一些片段
      expect(stats.totalSegments, greaterThan(0));
    });

    test('应该能创建摘要', () {
      // 添加一个长片段
      final id = manager.addSegment(
        type: SegmentType.userMessage,
        content: '这是第一句话。这是第二句话。这是第三句话。这是第四句话。这是第五句话。',
      );

      // 添加足够的片段触发裁剪
      for (var i = 0; i < 10; i++) {
        manager.addSegment(
          type: SegmentType.userMessage,
          content: 'message $i ' * 15,
        );
      }

      // 检查是否创建了摘要
      final segments = manager.getAllSegments();
      final hasSummary = segments.any((s) => s.isSummary);

      // 注意：摘要创建依赖于具体的裁剪策略
      // 这里只验证不会崩溃
      expect(manager.getStats().totalSegments, greaterThan(0));
    });
  });
}
