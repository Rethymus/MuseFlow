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
  ///
  /// Only includes sections that have content. Omitted counts are appended
  /// as a note when non-zero.
  String formatAsPrompt() {
    final buffer = StringBuffer();

    // Manuscript excerpt (always present)
    buffer.writeln('## 待检查文本');
    buffer.writeln(manuscriptExcerpt);
    buffer.writeln();

    // Relevant characters
    if (relevantCharacters.isNotEmpty) {
      buffer.writeln('## 相关角色设定');
      for (final card in relevantCharacters) {
        buffer.writeln(card.toContextString);
        buffer.writeln();
      }
    }

    // Relevant world settings
    if (relevantWorldSettings.isNotEmpty) {
      buffer.writeln('## 相关世界设定');
      for (final setting in relevantWorldSettings) {
        buffer.writeln('- ${setting.name}: ${setting.rules}');
        buffer.writeln();
      }
    }

    // Skill constraints
    if (skillConstraints.isNotEmpty) {
      buffer.writeln('## 活跃技能约束');
      for (final constraint in skillConstraints) {
        buffer.writeln('- $constraint');
      }
      buffer.writeln();
    }

    // Plot summaries
    if (plotSummaries.isNotEmpty) {
      buffer.writeln('## 相关情节节点');
      for (final node in plotSummaries) {
        buffer.writeln('- 第${node.chapter}章 ${node.title}: ${node.summary}');
      }
      buffer.writeln();
    }

    // Unresolved foreshadowing
    if (unresolvedForeshadowing.isNotEmpty) {
      buffer.writeln('## 未解决的伏笔');
      for (final entry in unresolvedForeshadowing) {
        buffer.writeln(
          '- 第${entry.plantedChapter}章埋设: ${entry.title}'
          '${entry.notes.isNotEmpty ? " — ${entry.notes}" : ""}',
        );
      }
      buffer.writeln();
    }

    // Omitted counts note
    final totalOmitted =
        omittedCharacterCount +
        omittedWorldSettingCount +
        omittedSkillCount +
        omittedPlotNodeCount +
        omittedForeshadowingCount;
    if (tokenBudget > 0 && totalOmitted > 0) {
      buffer.writeln('## 省略说明');
      buffer.writeln('因 token 预算限制，以下数据被省略：');
      if (omittedCharacterCount > 0) {
        buffer.writeln('- 角色设定: $omittedCharacterCount 条');
      }
      if (omittedWorldSettingCount > 0) {
        buffer.writeln('- 世界设定: $omittedWorldSettingCount 条');
      }
      if (omittedSkillCount > 0) {
        buffer.writeln('- 技能约束: $omittedSkillCount 条');
      }
      if (omittedPlotNodeCount > 0) {
        buffer.writeln('- 情节节点: $omittedPlotNodeCount 条');
      }
      if (omittedForeshadowingCount > 0) {
        buffer.writeln('- 伏笔条目: $omittedForeshadowingCount 条');
      }
    }

    return buffer.toString();
  }
}

/// Assembles bounded context for guardian checks.
///
/// Relevance rules:
/// - Characters/world settings whose names or aliases occur in checked text
/// - Plot nodes matching current chapter first, then by chapter proximity
/// - Skill constraints in constraints-only form
/// - Unresolved foreshadowing near current chapter
/// - Never includes the entire knowledge base by default
class GuardianContextBuilder {
  final TokenBudgetCalculator _tokenBudgetCalculator;
  final int _tokenBudget;

  GuardianContextBuilder({
    required this._tokenBudgetCalculator,
    required this._tokenBudget,
  });

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
    var usedTokens = _tokenBudgetCalculator.estimateTokens(checkedText);
    var remainingBudget = _tokenBudget - usedTokens;

    // Select relevant characters by name/alias match
    final relevantChars = _selectRelevantCharacters(
      characters: characters,
      checkedText: checkedText,
      budget: remainingBudget,
    );
    usedTokens += relevantChars.tokensUsed;
    remainingBudget -= relevantChars.tokensUsed;

    // Select relevant world settings by name/alias match
    final relevantWorlds = _selectRelevantWorldSettings(
      worldSettings: worldSettings,
      checkedText: checkedText,
      budget: remainingBudget,
    );
    usedTokens += relevantWorlds.tokensUsed;
    remainingBudget -= relevantWorlds.tokensUsed;

    // Select skill constraints
    final selectedSkills = _selectSkillConstraints(
      constraints: skillConstraints,
      budget: remainingBudget,
    );
    usedTokens += selectedSkills.tokensUsed;
    remainingBudget -= selectedSkills.tokensUsed;

    // Select plot nodes (current chapter first, then by proximity)
    final selectedPlots = _selectPlotNodes(
      plotNodes: plotNodes,
      currentChapter: currentChapter,
      budget: remainingBudget,
    );
    usedTokens += selectedPlots.tokensUsed;
    remainingBudget -= selectedPlots.tokensUsed;

    // Select unresolved foreshadowing near current chapter
    final selectedForeshadowing = _selectForeshadowing(
      entries: foreshadowingEntries,
      currentChapter: currentChapter,
      budget: remainingBudget,
    );
    usedTokens += selectedForeshadowing.tokensUsed;

    return GuardianContextBundle(
      manuscriptExcerpt: checkedText,
      relevantCharacters: relevantChars.items,
      relevantWorldSettings: relevantWorlds.items,
      skillConstraints: selectedSkills.items,
      plotSummaries: selectedPlots.items,
      unresolvedForeshadowing: selectedForeshadowing.items,
      omittedCharacterCount: relevantChars.omittedCount,
      omittedWorldSettingCount: relevantWorlds.omittedCount,
      omittedSkillCount: selectedSkills.omittedCount,
      omittedPlotNodeCount: selectedPlots.omittedCount,
      omittedForeshadowingCount: selectedForeshadowing.omittedCount,
      totalTokensUsed: usedTokens,
      tokenBudget: _tokenBudget,
    );
  }

  /// Finds characters whose name or any alias appears in the checked text.
  List<CharacterCard> _findCharactersByText(
    List<CharacterCard> characters,
    String text,
  ) {
    final lowerText = text.toLowerCase();
    return characters.where((card) {
      if (lowerText.contains(card.name.toLowerCase())) return true;
      return card.aliases.any(
        (alias) => lowerText.contains(alias.toLowerCase()),
      );
    }).toList();
  }

  /// Finds world settings whose name or any alias appears in the checked text.
  List<WorldSetting> _findWorldSettingsByText(
    List<WorldSetting> settings,
    String text,
  ) {
    final lowerText = text.toLowerCase();
    return settings.where((setting) {
      if (lowerText.contains(setting.name.toLowerCase())) return true;
      return setting.aliases.any(
        (alias) => lowerText.contains(alias.toLowerCase()),
      );
    }).toList();
  }

  _BudgetResult<CharacterCard> _selectRelevantCharacters({
    required List<CharacterCard> characters,
    required String checkedText,
    required int budget,
  }) {
    final relevant = _findCharactersByText(characters, checkedText);
    return _fitWithinBudget(relevant, budget, (card) => card.toContextString);
  }

  _BudgetResult<WorldSetting> _selectRelevantWorldSettings({
    required List<WorldSetting> worldSettings,
    required String checkedText,
    required int budget,
  }) {
    final relevant = _findWorldSettingsByText(worldSettings, checkedText);
    return _fitWithinBudget(relevant, budget, (s) => '${s.name}: ${s.rules}');
  }

  _BudgetResult<String> _selectSkillConstraints({
    required List<String> constraints,
    required int budget,
  }) {
    return _fitWithinBudget(constraints, budget, (c) => c);
  }

  _BudgetResult<PlotNode> _selectPlotNodes({
    required List<PlotNode> plotNodes,
    required int currentChapter,
    required int budget,
  }) {
    // Sort: current chapter first, then by chapter proximity
    final sorted = List<PlotNode>.from(plotNodes)
      ..sort((a, b) {
        final aDiff = (a.chapter - currentChapter).abs();
        final bDiff = (b.chapter - currentChapter).abs();
        return aDiff.compareTo(bDiff);
      });
    return _fitWithinBudget(
      sorted,
      budget,
      (n) => '第${n.chapter}章 ${n.title}: ${n.summary}',
    );
  }

  _BudgetResult<ForeshadowingEntry> _selectForeshadowing({
    required List<ForeshadowingEntry> entries,
    required int currentChapter,
    required int budget,
  }) {
    // Only unresolved entries, sorted by proximity to current chapter
    final unresolved = entries.where((e) => e.isOpen).toList()
      ..sort((a, b) {
        final aDiff = (a.plantedChapter - currentChapter).abs();
        final bDiff = (b.plantedChapter - currentChapter).abs();
        return aDiff.compareTo(bDiff);
      });
    return _fitWithinBudget(
      unresolved,
      budget,
      (e) => '${e.title}: ${e.notes}',
    );
  }

  /// Generic budget-fitting: includes items in order until budget exhausted.
  _BudgetResult<T> _fitWithinBudget<T>(
    List<T> items,
    int budget,
    String Function(T) serializer,
  ) {
    if (items.isEmpty || budget <= 0) {
      return _BudgetResult(
        items: const [],
        tokensUsed: 0,
        omittedCount: items.length,
      );
    }

    final included = <T>[];
    var usedTokens = 0;

    for (final item in items) {
      final text = serializer(item);
      final tokens = _tokenBudgetCalculator.estimateTokens(text);
      if (usedTokens + tokens <= budget) {
        included.add(item);
        usedTokens += tokens;
      } else {
        // Budget exceeded, stop adding
        break;
      }
    }

    return _BudgetResult(
      items: included,
      tokensUsed: usedTokens,
      omittedCount: items.length - included.length,
    );
  }
}

/// Internal helper for budget-fitting results.
class _BudgetResult<T> {
  final List<T> items;
  final int tokensUsed;
  final int omittedCount;

  const _BudgetResult({
    required this.items,
    required this.tokensUsed,
    required this.omittedCount,
  });
}
