import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/editor/application/chapter_context_middleware.dart';

void main() {
  group('ChapterContextMiddleware', () {
    const middleware = ChapterContextMiddleware();

    test('should inject previous chapter summary into system message', () {
      final context = PromptContext(
        fragments: const [],
        previousChapterSummary: '上一章讲述主角离开了村庄。',
      );

      final result = middleware.apply(context);

      // Middleware should add a system message with the summary
      expect(result.messages, isNotEmpty);
      final systemMsg = result.messages.first;
      final json = systemMsg.toJson();
      expect(json['role'], 'system');
      expect(json['content'], contains('上一章节摘要'));
      expect(json['content'], contains('上一章讲述主角离开了村庄。'));
    });

    test('should inject next chapter summary into system message', () {
      final context = PromptContext(
        fragments: const [],
        nextChapterSummary: '下一章将揭示真相。',
      );

      final result = middleware.apply(context);

      expect(result.messages, isNotEmpty);
      final systemMsg = result.messages.first;
      final json = systemMsg.toJson();
      expect(json['content'], contains('下一章节摘要'));
      expect(json['content'], contains('下一章将揭示真相。'));
    });

    test('should inject both summaries when both provided', () {
      final context = PromptContext(
        fragments: const [],
        previousChapterSummary: '前情回顾。',
        nextChapterSummary: '后续预告。',
      );

      final result = middleware.apply(context);

      expect(result.messages, isNotEmpty);
      final systemMsg = result.messages.first;
      final json = systemMsg.toJson();
      expect(json['content'], contains('上一章节摘要'));
      expect(json['content'], contains('前情回顾。'));
      expect(json['content'], contains('下一章节摘要'));
      expect(json['content'], contains('后续预告。'));
    });

    test('should mark stale previous summary as advisory context', () {
      final context = PromptContext(
        fragments: const [],
        previousChapterSummary: '林风已经突破金丹。',
        previousChapterMemoryWarning: '摘要与第3章正文重合度偏低，可能仍停留在旧版本。',
      );

      final result = middleware.apply(context);

      final json = result.messages.first.toJson();
      final content = json['content'] as String;
      expect(content, contains('记忆复查提示'));
      expect(content, contains('重合度偏低'));
      expect(content, contains('仅作为参考'));
      expect(content, contains('作者当前正文'));
      expect(content, contains('不要为了迎合过期摘要'));
    });

    test('should mark stale next summary as advisory context', () {
      final context = PromptContext(
        fragments: const [],
        nextChapterSummary: '下一章苏雪晴离开宗门。',
        nextChapterMemoryWarning: '下一章摘要缺少最新新增的宗门试炼线索。',
      );

      final result = middleware.apply(context);

      final content = result.messages.first.toJson()['content'] as String;
      expect(content, contains('下一章节摘要'));
      expect(content, contains('宗门试炼线索'));
      expect(content, contains('知识库冲突'));
    });

    test('should ignore blank memory warning', () {
      final context = PromptContext(
        fragments: const [],
        previousChapterSummary: '前情回顾。',
        previousChapterMemoryWarning: '   ',
      );

      final result = middleware.apply(context);

      final content = result.messages.first.toJson()['content'] as String;
      expect(content, isNot(contains('记忆复查提示')));
    });

    test('should return unchanged context when no summaries provided', () {
      final context = PromptContext(fragments: const []);

      final result = middleware.apply(context);

      // No summaries means no messages added
      expect(result.messages, isEmpty);
    });
  });

  group('PromptContext chapter summary fields', () {
    test('should accept previousChapterSummary and nextChapterSummary', () {
      const context = PromptContext(
        fragments: [],
        previousChapterSummary: '前情',
        nextChapterSummary: '后续',
        previousChapterMemoryWarning: '前情可能过期',
        nextChapterMemoryWarning: '后续可能过期',
      );

      expect(context.previousChapterSummary, '前情');
      expect(context.nextChapterSummary, '后续');
      expect(context.previousChapterMemoryWarning, '前情可能过期');
      expect(context.nextChapterMemoryWarning, '后续可能过期');
    });

    test('should default chapter summaries to null', () {
      const context = PromptContext(fragments: []);

      expect(context.previousChapterSummary, isNull);
      expect(context.nextChapterSummary, isNull);
      expect(context.previousChapterMemoryWarning, isNull);
      expect(context.nextChapterMemoryWarning, isNull);
    });
  });
}
