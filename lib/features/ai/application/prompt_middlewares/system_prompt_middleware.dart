/// System prompt middleware.
///
/// Adds the base system message with role description.
/// This is the first middleware in the pipeline per AI-04.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:openai_dart/openai_dart.dart';

/// Adds the base system instruction message to the context.
///
/// The system message defines the AI's role:
/// "你是一位经验丰富的中文小说作者。你的任务是将碎片化的灵感整理成流畅的故事段落。"
class SystemPromptMiddleware extends PromptMiddleware {
  /// Base system instruction for the AI model.
  static const String baseInstruction =
      '你是一位经验丰富的中文小说作者。你的任务是将碎片化的灵感整理成流畅的故事段落。';

  const SystemPromptMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    return context.addMessage(
      ChatMessage.system(baseInstruction),
    );
  }
}
