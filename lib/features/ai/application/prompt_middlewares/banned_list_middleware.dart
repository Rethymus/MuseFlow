/// Banned list middleware.
///
/// Appends a negative checklist of banned phrases to the system message.
/// Per D-11: formatted as "避免以下词汇和句式：\n- phrase1\n- phrase2\n..."
/// This is the third middleware in the pipeline per AI-04.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:openai_dart/openai_dart.dart';

/// Appends banned phrases checklist to the existing system message.
///
/// The banned list tells the AI model which words and patterns to avoid,
/// forming the prompt-layer of the anti-AI-scent system per AI-05.
class BannedListMiddleware extends PromptMiddleware {
  const BannedListMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    if (context.bannedPhrases.isEmpty) {
      // No banned phrases -- skip
      return context;
    }

    final buffer = StringBuffer();
    buffer.write('\n\n避免以下词汇和句式：');
    for (final phrase in context.bannedPhrases) {
      buffer.write('\n- ');
      buffer.write(phrase);
    }

    if (context.messages.isEmpty) {
      return context.addMessage(ChatMessage.system(buffer.toString()));
    }

    final systemContent = _extractContent(context.messages[0]);
    return context.replaceSystemMessage(0, systemContent + buffer.toString());
  }

  /// Extracts the text content from a ChatMessage.
  String _extractContent(dynamic message) {
    final json = message.toJson();
    final content = json['content'];
    if (content is String) return content;
    return '';
  }
}
