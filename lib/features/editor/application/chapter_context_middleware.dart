import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:openai_dart/openai_dart.dart';

/// Middleware that injects adjacent chapter summaries into the AI prompt.
///
/// Per D-24: Adds previous and next chapter summaries to the system message
/// so the AI understands the surrounding narrative context when processing
/// selected text in a chapter-aware manuscript.
///
/// Output format when both summaries are present:
/// ```
/// 上一章节摘要：
/// {previousSummary}
///
/// 下一章节摘要：
/// {nextSummary}
/// ```
class ChapterContextMiddleware extends PromptMiddleware {
  const ChapterContextMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final buffer = StringBuffer();

    if (context.previousChapterSummary != null &&
        context.previousChapterSummary!.isNotEmpty) {
      buffer.writeln('上一章节摘要：');
      buffer.writeln(context.previousChapterSummary);
      buffer.writeln();
    }

    if (context.nextChapterSummary != null &&
        context.nextChapterSummary!.isNotEmpty) {
      buffer.writeln('下一章节摘要：');
      buffer.writeln(context.nextChapterSummary);
      buffer.writeln();
    }

    if (buffer.isEmpty) return context;

    return context.addMessage(
      ChatMessage.system(buffer.toString().trimRight()),
    );
  }
}
