/// Editor-specific prompt pipeline for AI operations on selected text.
///
/// Extends [PromptPipeline] with editor-specific middleware:
/// - [EditorOperationMiddleware]: appends operation-specific system prompt
/// - [EditorUserContentMiddleware]: builds user message from selected text
///
/// Per D-16: Each AI operation has a distinct system prompt instruction.
/// Per D-17: Pipeline order = system prompt + anti-AI persona + banned list
///           + context anchors + operation instruction + selected text content.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/banned_list_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/dynamic_persona_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/few_shot_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/persona_injection_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/system_prompt_middleware.dart';
import 'package:museflow/features/editor/application/chapter_context_middleware.dart';
import 'package:museflow/features/editor/application/context_anchor_middleware.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/knowledge/application/skill_enforcement_middleware.dart';
import 'package:openai_dart/openai_dart.dart';

/// Prompt pipeline specialized for editor AI operations.
///
/// Assembles prompts for tone rewrite, paragraph polish, and free-input
/// operations. Uses the same base middlewares as [PromptPipeline] but
/// replaces [UserContentMiddleware] with editor-specific middlewares.
class EditorPromptPipeline extends PromptPipeline {
  /// Creates an editor prompt pipeline with the correct middleware ordering.
  EditorPromptPipeline({
    KnowledgeInjectionMiddleware? knowledgeInjectionMiddleware,
    SkillEnforcementMiddleware? skillEnforcementMiddleware,
  }) : super(
         middlewares: [
           SystemPromptMiddleware(),
           PersonaInjectionMiddleware(),
           const DynamicPersonaMiddleware(),
           const FewShotMiddleware(),
           BannedListMiddleware(),
           ?knowledgeInjectionMiddleware,
           ?skillEnforcementMiddleware,
           const ContextAnchorMiddleware(),
           const ChapterContextMiddleware(),
           EditorOperationMiddleware(),
           EditorUserContentMiddleware(),
         ],
       );
}

/// Middleware that appends operation-specific system prompt instructions.
///
/// Per D-16:
/// - toneRewrite: "请调整以下文字的叙事语气和风格，保持原文意思不变"
/// - paragraphPolish: "请润色以下文段，提升文字质量和文学性"
/// - freeInput: "请根据以下指令修改选中的文字：{userInstruction}"
class EditorOperationMiddleware extends PromptMiddleware {
  const EditorOperationMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final operation = context.selectedOperation;
    if (operation == null) return context;

    final instruction = switch (operation) {
      EditorAIOperation.toneRewrite => '请调整以下文字的叙事语气和风格，保持原文意思不变。',
      EditorAIOperation.paragraphPolish => '请润色以下文段，提升文字质量和文学性。',
      EditorAIOperation.freeInput =>
        '请根据以下指令修改选中的文字：${context.userInstruction ?? ""}',
      EditorAIOperation.expand =>
        '请扩写以下文字，丰富细节、感官描写和情感层次，保持原有风格不变。不要简单地堆砌形容词，而是通过具体的动作、对话和环境来拓展画面。',
      EditorAIOperation.compress =>
        '请精简缩写以下文字，保留核心情节和关键信息，删减冗余描写和重复表达，保持行文流畅。',
      EditorAIOperation.dialogue =>
        '请将以下叙述转换为角色之间的对话形式，保持人物性格和语气特点，对话要自然、有个性、符合角色关系。',
      EditorAIOperation.scene =>
        '请将以下简短描述扩展为有画面感的场景描写，运用视觉、听觉、触觉、嗅觉等多感官细节，营造氛围感，避免空洞的形容词堆砌。',
    };

    if (context.messages.isEmpty) {
      return context.addMessage(ChatMessage.system(instruction));
    }

    // Append to existing system message
    final systemContent = _extractContent(context.messages[0]);
    return context.replaceSystemMessage(0, '$systemContent\n\n$instruction');
  }

  /// Extracts the text content from a ChatMessage.
  String _extractContent(dynamic message) {
    final json = message.toJson();
    final content = json['content'];
    if (content is String) return content;
    return '';
  }
}

/// Middleware that builds the user message from selected text instead of fragments.
///
/// Per D-17: The user message contains the selected text for the AI to process.
/// Format: "请处理以下选中的文字：\n\n{selectedText}"
class EditorUserContentMiddleware extends PromptMiddleware {
  const EditorUserContentMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    final selectedText = context.selectedText;
    if (selectedText == null || selectedText.isEmpty) {
      // No selected text -- fall back to fragment-based content
      // This shouldn't happen in editor mode, but handle gracefully
      return context.addMessage(ChatMessage.user('没有选中任何文字。'));
    }

    final buffer = StringBuffer();
    buffer.write('请处理以下选中的文字：\n\n');
    buffer.write(selectedText);

    return context.addMessage(ChatMessage.user(buffer.toString()));
  }
}
