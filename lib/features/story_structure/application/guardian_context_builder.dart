import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';

/// Token-bounded context bundle assembled for guardian checks.
///
/// Contains only the relevant story data within a token budget,
/// never the entire knowledge base. Exposes omitted counts so
/// the caller can warn about truncated context.
class GuardianContextBundle {
  final String manuscriptExcerpt;
  final List<CharacterCard> relevantCharacters;
  final List<WorldSetting> relevantWorldSettings;
  final List<String> skillConstraints;
  final List<PlotNode> plotSummaries;
  final List<ForeshadowingEntry> unresolvedForeshadowing;
  final int omittedCharacterCount;
  final int omittedWorldSettingCount;
  final int omittedSkillCount;
  final int omittedPlotNodeCount;
  final int omittedForeshadowingCount;
  final int totalTokensUsed;
  final int tokenBudget;

  const GuardianContextBundle({
    required this.manuscriptExcerpt,
    required this.relevantCharacters,
    required this.relevantWorldSettings,
    required this.skillConstraints,
    required this.plotSummaries,
    required this.unresolvedForeshadowing,
    required this.omittedCharacterCount,
    required this.omittedWorldSettingCount,
    required this.omittedSkillCount,
    required this.omittedPlotNodeCount,
    required this.omittedForeshadowingCount,
    required this.totalTokensUsed,
    required this.tokenBudget,
  });

  /// Budget usage as a percentage (0-100).
  double get budgetUsagePercent =>
      tokenBudget > 0 ? (totalTokensUsed / tokenBudget) * 100 : 0.0;

  /// Formats the bundle as a structured prompt string for AI guardian checks.
  String formatAsPrompt() {
    // TODO: implement
    throw UnimplementedError();
  }
}

/// Assembles bounded context for guardian checks.
///
/// Selects relevant characters, world settings, skill constraints,
/// plot nodes, and foreshadowing entries based on the checked text
/// and current chapter, respecting the token budget.
class GuardianContextBuilder {
  final TokenBudgetCalculator _tokenBudgetCalculator;
  final int _tokenBudget;

  GuardianContextBuilder({
    required TokenBudgetCalculator tokenBudgetCalculator,
    required int tokenBudget,
  })  : _tokenBudgetCalculator = tokenBudgetCalculator,
        _tokenBudget = tokenBudget;

  /// Builds a bounded context bundle for guardian checks.
  GuardianContextBundle build({
    required String checkedText,
    required int currentChapter,
    required List<CharacterCard> characters,
    required List<WorldSetting> worldSettings,
    required List<String> skillConstraints,
    required List<PlotNode> plotNodes,
    required List<ForeshadowingEntry> foreshadowingEntries,
  }) {
    // TODO: implement
    throw UnimplementedError();
  }
}
