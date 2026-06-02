/// User content middleware.
///
/// Creates the user message with formatted fragment content.
/// Per D-06: supports additionalInstruction for fine-grained control.
/// This is the fourth (last) middleware in the pipeline per AI-04.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:openai_dart/openai_dart.dart';

/// Creates the user message with numbered fragment texts.
///
/// Format:
/// "请将以下灵感碎片整理成一个连贯的故事段落：
///
/// 1. fragment1 text
/// 2. fragment2 text
/// ...
///
/// 追加指令：{additionalInstruction}" (if present)
class UserContentMiddleware extends PromptMiddleware {
  const UserContentMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final buffer = StringBuffer();
    buffer.write('请将以下灵感碎片整理成一个连贯的故事段落：\n\n');

    for (var i = 0; i < context.fragments.length; i++) {
      buffer.write('${i + 1}. ${context.fragments[i].text}');
      if (i < context.fragments.length - 1) {
        buffer.write('\n');
      }
    }

    if (context.additionalInstruction != null &&
        context.additionalInstruction!.isNotEmpty) {
      buffer.write('\n\n追加指令：${context.additionalInstruction}');
    }

    return context.addMessage(ChatMessage.user(buffer.toString()));
  }
}
