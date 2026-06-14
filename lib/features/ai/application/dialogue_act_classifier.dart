/// PATHs dialogue-act classifier (CI-01).
///
/// A lightweight, dependency-free keyword-signal classifier that maps a user's
/// free-text message to one of the five [DialogueAct]s (Mysore et al., EMNLP
/// 2025 SAC Highlight). The act can then drive response-strategy adaptation in
/// the multi-turn conversation flow (future wiring; this class is pure logic).
///
/// Scoring: each act owns a set of signal phrases; the act with the most
/// distinct matched signals wins. Ties break by a fixed priority that favors
/// the more actionable act (injection > styleAdjustment > contentExploration >
/// intentRevision). A message matching nothing defaults to [DialogueAct.followUp]
/// — giving more depth is the safest non-destructive response to an ambiguous
/// turn. Matched keywords are surfaced for explainability.
library;

import 'package:museflow/features/ai/domain/dialogue_act.dart';

/// The classification result: the predicted act plus why it was chosen.
class DialogueActClassification {
  /// The predicted dialogue act.
  final DialogueAct act;

  /// Signal phrases in the user message that matched the winning act
  /// (explainability — the UI / prompt adapter can show why).
  final List<String> matchedKeywords;

  /// Heuristic confidence in [0, 1]: matched-signal density, 0 when unmatched.
  final double confidence;

  const DialogueActClassification({
    required this.act,
    required this.matchedKeywords,
    required this.confidence,
  });
}

/// Classifies a user message into a [DialogueAct].
class DialogueActClassifier {
  const DialogueActClassifier();

  /// Signal phrases per act. Specific enough to avoid cross-act bleed; the
  /// classifier counts distinct matches per act.
  static const Map<DialogueAct, List<String>> signals = {
    DialogueAct.styleAdjustment: [
      '改一下', '改得', '改成', '改个', '改写', '润色', '语气', '风格', '文风',
      '正式', '口语', '换个', '调整',
    ],
    DialogueAct.contentExploration: [
      '如果', '假如', '要是', '试试', '换一种', '另一个方向', '会怎样', '或者',
    ],
    DialogueAct.intentRevision: [
      '不对', '不是这个', '不是这样', '我要的', '我的意思', '重新理解', '错了',
      '偏了', '误解',
    ],
    DialogueAct.followUp: [
      '为什么', '怎么', '详细', '具体', '展开', '继续', '说说', '解释', '深入',
      '讲讲',
    ],
    DialogueAct.injection: [
      '加入', '添加', '插入', '补充', '写一段', '加一段', '增添',
    ],
  };

  /// Tie-break priority: when two acts tie on match count, the earlier one
  /// here wins. Ordered to favor the more actionable interpretation.
  static const List<DialogueAct> _priority = [
    DialogueAct.injection,
    DialogueAct.styleAdjustment,
    DialogueAct.contentExploration,
    DialogueAct.intentRevision,
    DialogueAct.followUp,
  ];

  /// Classifies [message] into a [DialogueAct].
  DialogueActClassification classify(String message) {
    var bestAct = DialogueAct.followUp; // safe default for ambiguous turns
    var bestScore = 0;
    var bestKeywords = const <String>[];

    for (final act in _priority) {
      final matched = <String>[];
      for (final s in signals[act]!) {
        if (message.contains(s)) matched.add(s);
      }
      // Strictly-greater wins → ties keep the higher-priority act (iterated
      // first).
      if (matched.length > bestScore) {
        bestScore = matched.length;
        bestAct = act;
        bestKeywords = matched;
      }
    }

    final confidence =
        bestScore == 0 ? 0.0 : (bestScore / 2.0).clamp(0.0, 1.0).toDouble();

    return DialogueActClassification(
      act: bestAct,
      matchedKeywords: bestKeywords,
      confidence: confidence,
    );
  }
}
