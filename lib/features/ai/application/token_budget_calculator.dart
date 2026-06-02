/// Token budget calculator for Chinese text.
///
/// Validates AI-07 (token budget management):
/// - Estimates Chinese text tokens using 1.8x multiplier per character
/// - Calculates available budget after subtracting system prompt, persona,
///   banned list, and reserved output tokens
/// - Selects fragments within budget using LIFO removal per D-13
library;

import 'package:museflow/core/domain/fragment.dart';

/// Result of fragment budget selection.
class BudgetResult {
  /// Fragments that fit within the budget.
  final List<Fragment> included;

  /// Number of fragments excluded due to budget limits.
  final int excludedCount;

  /// Total tokens used by included fragments.
  final int budgetUsed;

  /// Total budget available.
  final int budgetTotal;

  const BudgetResult({
    required this.included,
    required this.excludedCount,
    required this.budgetUsed,
    required this.budgetTotal,
  });

  @override
  String toString() =>
      'BudgetResult(included: ${included.length}, '
      'excluded: $excludedCount, used: $budgetUsed/$budgetTotal)';
}

/// Calculates token budgets for Chinese text.
///
/// Uses a simple approximation:
/// - Chinese characters: 1.8 tokens per character
/// - ASCII characters: 0.25 tokens per character
/// - 10% safety margin added to total
///
/// This is an approximation per RESEARCH.md. For production accuracy,
/// consider using tiktoken or the model's native tokenizer.
class TokenBudgetCalculator {
  /// Estimates the token count for the given [text].
  ///
  /// Uses 1.8x multiplier for Chinese characters and 0.25x for ASCII,
  /// with a 10% safety margin.
  int estimateTokens(String text) {
    if (text.isEmpty) return 0;

    int chineseCount = 0;
    int asciiCount = 0;

    for (final char in text.runes) {
      if (_isChinese(char)) {
        chineseCount++;
      } else {
        asciiCount++;
      }
    }

    final raw = (chineseCount * 1.8 + asciiCount * 0.25);
    // Add 10% safety margin and round up
    return (raw * 1.1).ceil();
  }

  /// Calculates the available token budget for fragment content.
  ///
  /// Subtracts [systemPromptTokens], [personaTokens], [bannedListTokens],
  /// and [reservedOutputTokens] from the [modelContextWindow].
  int calculateBudget({
    required int modelContextWindow,
    required int systemPromptTokens,
    required int personaTokens,
    required int bannedListTokens,
    required int reservedOutputTokens,
  }) {
    return modelContextWindow -
        systemPromptTokens -
        personaTokens -
        bannedListTokens -
        reservedOutputTokens;
  }

  /// Selects fragments that fit within the given [budget].
  ///
  /// Per D-13: Uses LIFO removal -- keeps fragments in selection order
  /// and excludes from the end until within budget.
  ///
  /// Returns a [BudgetResult] with included fragments, excluded count,
  /// and budget usage information.
  BudgetResult selectFragmentsWithinBudget(
    List<Fragment> fragments,
    int budget,
  ) {
    if (fragments.isEmpty || budget <= 0) {
      return BudgetResult(
        included: const [],
        excludedCount: fragments.length,
        budgetUsed: 0,
        budgetTotal: budget,
      );
    }

    final included = <Fragment>[];
    var usedTokens = 0;

    for (final fragment in fragments) {
      final fragmentTokens = estimateTokens(fragment.text);
      if (usedTokens + fragmentTokens <= budget) {
        included.add(fragment);
        usedTokens += fragmentTokens;
      } else {
        // Budget exceeded -- stop adding (LIFO: last fragments excluded)
        break;
      }
    }

    return BudgetResult(
      included: included,
      excludedCount: fragments.length - included.length,
      budgetUsed: usedTokens,
      budgetTotal: budget,
    );
  }

  /// Checks if a code point is a Chinese character.
  bool _isChinese(int codePoint) {
    // CJK Unified Ideographs: U+4E00..U+9FFF
    // CJK Unified Ideographs Extension A: U+3400..U+4DBF
    return (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
        (codePoint >= 0x3400 && codePoint <= 0x4DBF);
  }
}
