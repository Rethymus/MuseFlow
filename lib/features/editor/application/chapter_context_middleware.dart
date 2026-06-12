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
/// 记忆复查提示：{previousWarning}
///
/// 下一章节摘要：
/// {nextSummary}
/// 记忆复查提示：{nextWarning}
/// ```
class ChapterContextMiddleware extends PromptMiddleware {
  const ChapterContextMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final buffer = StringBuffer();

    // Inject multi-chapter context chain if available (LFIN-01)
    if (context.chapterContextChain != null &&
        context.chapterContextChain!.isNotEmpty) {
      buffer.writeln('前序章节脉络：');
      buffer.writeln(context.chapterContextChain);
      buffer.writeln();
    }

    if (context.previousChapterSummary != null &&
        context.previousChapterSummary!.isNotEmpty) {
      buffer.writeln('上一章节摘要：');
      buffer.writeln(context.previousChapterSummary);
      _writeMemoryWarning(buffer, context.previousChapterMemoryWarning);
      buffer.writeln();
    }

    if (context.nextChapterSummary != null &&
        context.nextChapterSummary!.isNotEmpty) {
      buffer.writeln('下一章节摘要：');
      buffer.writeln(context.nextChapterSummary);
      _writeMemoryWarning(buffer, context.nextChapterMemoryWarning);
      buffer.writeln();
    }

    if (buffer.isEmpty) return context;

    return context.addMessage(
      ChatMessage.system(buffer.toString().trimRight()),
    );
  }

  void _writeMemoryWarning(StringBuffer buffer, String? warning) {
    if (warning == null || warning.trim().isEmpty) return;

    buffer.writeln();
    buffer.writeln('记忆复查提示：${warning.trim()}');
    buffer.writeln('请把该摘要仅作为参考，若它与作者当前正文、选中文本或知识库冲突，必须以后者为准。');
    buffer.writeln('不要为了迎合过期摘要而改写作者已经确定的事实、人物关系或伏笔。');
  }
}
