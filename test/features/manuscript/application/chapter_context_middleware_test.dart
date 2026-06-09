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
      );

      expect(context.previousChapterSummary, '前情');
      expect(context.nextChapterSummary, '后续');
    });

    test('should default chapter summaries to null', () {
      const context = PromptContext(fragments: []);

      expect(context.previousChapterSummary, isNull);
      expect(context.nextChapterSummary, isNull);
    });
  });
}
