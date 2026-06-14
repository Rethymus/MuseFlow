/// Contrastive subtraction middleware (AA-02).
///
/// Per CoPA (Fang et al., EMNLP 2025): beyond *forbidding specific words*
/// (handled by [BannedListMiddleware]), the model must actively *subtract
/// machine-scent patterns* at the sentence-organization level. Human writing
/// has natural "burstiness" — irregular sentence lengths, jump-cuts, emotion-
/// driven rhythm — whereas AI writing tends toward mechanical uniformity.
///
/// This middleware injects a decomposed "对比减法 — 主动减去机器味" instruction
/// block naming four concrete patterns to subtract:
///   1. Uniform sentence length → alternate long/short sentences (burstiness).
///   2. Over-perfect logic chains → allow jumps, ellipsis, non-linear motion.
///   3. Mechanical transition words (然而/此外/综上所述/不仅...而且) → connect
///      via scene and action instead.
///   4. Metronomic pacing → allow emotion-driven rhythm shifts.
///
/// Orthogonality: this is injected **regardless** of whether banned phrases are
/// configured. The keyword blacklist ("don't say these words") and contrastive
/// subtraction ("don't organize sentences like a machine") are two distinct
/// anti-AI-scent dimensions; users with no banned phrases still get the
/// sentence-organization layer.
///
/// The existing dynamic-persona anti-AI-scent anchor ("核心要求...避免任何AI
/// 生成的痕迹") is preserved untouched — this block is additive and runs after
/// the banned list in both prompt pipelines.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:openai_dart/openai_dart.dart';

/// Appends the CoPA contrastive-subtraction instruction block to the system
/// message, forming a second anti-AI-scent layer (orthogonal to the keyword
/// blacklist) per AA-02.
class ContrastiveSubtractionMiddleware extends PromptMiddleware {
  const ContrastiveSubtractionMiddleware();

  /// Title used to guard against duplicate injection (idempotency sentinel).
  static const String blockTitle = '对比减法';

  /// The decomposed contrastive-subtraction instruction block.
  ///
  /// Kept as a static const so the exact wording is testable and the
  /// idempotency guard can match it.
  static const String blockContent = '''

**$blockTitle — 主动减去机器味**：
人类写作有自然的「不规则突发性」（burstiness），AI 写作倾向机械均衡。请在以下四点主动减去机器味：
1. 句长：避免均匀的句式长度，主动交替使用长短句（短句制造冲击，长句铺陈氛围），保持不均匀的节奏感。
2. 逻辑链：避免过度完美的因果闭环，允许跳跃、留白、非线性推进——真实叙述有缝隙，不必每个转折都严丝合缝。
3. 过渡词：避免「然而」「此外」「综上所述」「不仅……而且」「值得一提的是」等机械化连接，改用情境、动作、对话自然衔接。
4. 节奏：允许情绪驱动的节奏突变，不要每个段落都匀速推进；该快则快，该慢则慢。''';

  @override
  PromptContext apply(PromptContext context) {
    if (context.messages.isEmpty) {
      return context.addMessage(ChatMessage.system(blockContent));
    }

    final systemContent = _extractContent(context.messages[0]);
    // Idempotency guard: never inject the block twice if the same context
    // flows through the middleware more than once.
    if (systemContent.contains(blockTitle)) {
      return context;
    }

    return context.replaceSystemMessage(
      0,
      systemContent + blockContent,
    );
  }

  /// Extracts the text content from a [ChatMessage].
  String _extractContent(dynamic message) {
    final json = message.toJson();
    final content = json['content'];
    if (content is String) return content;
    return '';
  }
}
