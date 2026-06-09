/// Persona injection middleware.
///
/// Appends anti-AI-scent persona to the system message.
/// Per D-11: injects "写作风格：自然、有温度、像人写的。避免使用任何AI生成的痕迹。"
/// This is the second middleware in the pipeline per AI-04.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/system_prompt_middleware.dart';
import 'package:openai_dart/openai_dart.dart';

/// Appends persona injection text to the existing system message.
///
/// This ensures the AI writes in a natural, human-like style
/// without detectable AI patterns.
class PersonaInjectionMiddleware extends PromptMiddleware {
  /// Persona injection text per D-11.
  static const String personaText = '\n\n写作风格：自然、有温度、像人写的。避免使用任何AI生成的痕迹。';

  const PersonaInjectionMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    if (context.messages.isEmpty) {
      // No system message yet -- create one with persona only
      return context.addMessage(
        ChatMessage.system(
          SystemPromptMiddleware.baseInstruction + personaText,
        ),
      );
    }

    // Append to the first (system) message
    final systemContent = _extractContent(context.messages[0]);
    return context.replaceSystemMessage(0, systemContent + personaText);
  }

  /// Extracts the text content from a ChatMessage.
  String _extractContent(dynamic message) {
    final json = message.toJson();
    final content = json['content'];
    if (content is String) return content;
    return '';
  }
}
