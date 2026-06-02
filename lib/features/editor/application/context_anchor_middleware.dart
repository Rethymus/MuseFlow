/// Context anchor middleware for the prompt pipeline.
///
/// Injects anchor context into the AI prompt system message so the AI
/// can reference user-designated paragraphs during operations.
///
/// Per D-15: Anchor content is automatically injected into the
/// PromptPipeline system message.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/context_anchor.dart';
import 'package:openai_dart/openai_dart.dart';

/// Middleware that injects context anchor text into the prompt.
///
/// Reads [PromptContext.anchors] (typed as `List<AnchorReference>?`),
/// casts each to [ContextAnchor], and appends a system message containing
/// the anchor text for the AI to reference.
///
/// Pipeline position: after BannedListMiddleware, before EditorOperationMiddleware.
class ContextAnchorMiddleware extends PromptMiddleware {
  const ContextAnchorMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final anchorRefs = context.anchors;
    if (anchorRefs == null || anchorRefs.isEmpty) {
      return context;
    }

    // Cast to ContextAnchor (the concrete type implementing AnchorReference)
    final anchors = anchorRefs.cast<ContextAnchor>();

    final buffer = StringBuffer();
    buffer.write('以下是作者指定的参考上下文，请在改写时参考：');

    for (final anchor in anchors) {
      buffer.write('\n\n【${anchor.label}】\n${anchor.text}');
    }

    return context.addMessage(ChatMessage.system(buffer.toString()));
  }
}
