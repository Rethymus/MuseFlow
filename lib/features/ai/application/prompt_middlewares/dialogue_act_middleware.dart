// PATHs dialogue-act → response-strategy middleware (CI-01 wiring).
//
// Reads [PromptContext.additionalInstruction] (the user's free-text refine
// instruction from synthesis regenerate), classifies it via
// [DialogueActClassifier], and injects an act-specific Chinese system
// instruction that adapts the AI's response strategy — closing the PATHs loop
// (260614-ci1 delivered the pure-logic classifier; this is its first consumer).
//
// No-op cases (respects the classifier's safe-default design and avoids
// injecting noise into every refine turn):
//   - null / empty / whitespace instruction (first synthesis, no refine)
//   - confidence == 0 (purely ambiguous, no matched signal)
//   - [DialogueAct.followUp] (providing depth is the safe default; a strategy
//     for every follow-up would add noise)
library;

import 'package:museflow/features/ai/application/dialogue_act_classifier.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/domain/dialogue_act.dart';
import 'package:openai_dart/openai_dart.dart';

/// Injects a dialogue-act-aware response-strategy system message.
///
/// Sits right after [SystemPromptMiddleware] in the default pipeline: the base
/// instruction defines the role, this middleware adapts how the role should
/// respond to the current turn. The two are orthogonal.
class DialogueActMiddleware extends PromptMiddleware {
  const DialogueActMiddleware();

  /// Chinese response-strategy instruction per actionable act.
  ///
  /// [DialogueAct.followUp] is intentionally absent — depth is the safe
  /// non-destructive default, so a follow-up turn needs no special strategy.
  static const Map<DialogueAct, String> _strategies = {
    DialogueAct.styleAdjustment:
        '用户正在调整文风或语气。本次重写须严格尊重其风格偏好，仅调整语气与措辞，不得改变情节走向与人物行为。',
    DialogueAct.contentExploration:
        '用户正在探索内容可能性。可提供分支方向，但每条须紧扣碎片主题，并标注为可选方向而非定稿。',
    DialogueAct.intentRevision: '用户纠正了你的理解。请重新对齐其真实意图，丢弃上一版方向，按新意图重写。',
    DialogueAct.injection: '用户要求插入或补充指定内容。请忠实融入所求内容，保持上下文连贯，不得删改既有主体。',
  };

  @override
  PromptContext apply(PromptContext context) {
    final instruction = context.additionalInstruction;
    if (instruction == null || instruction.trim().isEmpty) return context;

    final classification = const DialogueActClassifier().classify(instruction);
    // No matched signal → ambiguous turn. Give depth by doing nothing special.
    if (classification.confidence == 0) return context;

    final strategy = _strategies[classification.act];
    // followUp (or any act without an explicit strategy) → no-op.
    if (strategy == null) return context;

    // Merge into the existing system message (messages[0]) the same way
    // PersonaInjectionMiddleware / BannedListMiddleware do, so the pipeline
    // keeps a single coherent system message rather than fragmenting it.
    final block = '\n\n【响应策略·${classification.act.label}】$strategy';
    if (context.messages.isEmpty) {
      return context.addMessage(ChatMessage.system(block));
    }
    final systemContent = _extractContent(context.messages[0]);
    return context.replaceSystemMessage(0, systemContent + block);
  }

  /// Extracts the text content from a ChatMessage (mirrors the helper in
  /// PersonaInjectionMiddleware / BannedListMiddleware).
  String _extractContent(dynamic message) {
    final json = message.toJson();
    final content = json['content'];
    if (content is String) return content;
    return '';
  }
}
