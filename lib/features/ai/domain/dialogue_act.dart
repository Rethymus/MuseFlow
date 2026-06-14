/// PATHs dialogue acts (CI-01).
///
/// Per Mysore et al. (EMNLP 2025 SAC Highlight): human–AI creative collaboration
/// falls into five recurring dialogue acts. Recognizing the current act lets
/// the AI adapt its response strategy rather than treating every turn the same:
///   - [styleAdjustment]: "改语气/换风格" → rephrase with restraint.
///   - [contentExploration]: "如果…会怎样" → offer branching alternatives.
///   - [intentRevision]: "不对，我要的是…" → stop and re-ground on intent.
///   - [followUp]: "为什么/展开" → provide depth, no new content.
///   - [injection]: "加一段/补充" → faithfully insert requested content.
library;

/// The five PATHs collaborative dialogue acts.
enum DialogueAct {
  /// User requests a tone/style change ("改语气", "换风格").
  styleAdjustment('风格调整'),

  /// User explores alternatives / branches ("如果…会怎样", "另一个方向").
  contentExploration('内容探索'),

  /// User corrects the AI's understanding ("不对", "我要的是…").
  intentRevision('意图修订'),

  /// User asks for depth on existing content ("为什么", "展开说说").
  followUp('追问深入'),

  /// User requests new content insertion ("加一段", "补充对话").
  injection('内容注入');

  const DialogueAct(this.label);

  /// Chinese display label for UI / prompt adaptation.
  final String label;
}
