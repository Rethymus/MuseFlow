/// Tests for TokenBudgetCalculator.
///
/// Validates AI-07 (token budget management):
/// - Chinese text token estimation with 1.8x multiplier
/// - Budget calculation accounting for system prompt, persona, banned list, reserved output
/// - Fragment selection with LIFO removal per D-13
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';

void main() {
  group('TokenBudgetCalculator', () {
    late TokenBudgetCalculator calculator;

    setUp(() {
      calculator = TokenBudgetCalculator();
    });

    group('estimateTokens', () {
      test('should estimate tokens for Chinese text with 1.8x multiplier', () {
        // 10 Chinese characters
        const text = '剑光如水划破长空，少年拔剑而立。';
        final tokens = calculator.estimateTokens(text);
        // Chinese chars: ~16 chars * 1.8 = 28.8 + punctuation * 1.8
        // Plus 10% safety margin
        expect(tokens, greaterThan(20));
        expect(tokens, lessThan(100));
      });

      test('should estimate tokens for ASCII text with 0.25x multiplier', () {
        const text = 'Hello World Test';
        final tokens = calculator.estimateTokens(text);
        // 16 ASCII chars * 0.25 = 4 + 10% = ~4.4 -> 5 (rounded)
        expect(tokens, greaterThanOrEqualTo(4));
        expect(tokens, lessThan(10));
      });

      test('should estimate tokens for mixed Chinese and ASCII text', () {
        const text = 'Hello 你好 World 世界';
        final tokens = calculator.estimateTokens(text);
        // Chinese: 4 chars * 1.8 = 7.2, ASCII: 13 chars * 0.25 = 3.25
        // Total: 10.45 + 10% = 11.495 -> 12
        expect(tokens, greaterThanOrEqualTo(8));
        expect(tokens, lessThan(30));
      });

      test('should add 10% safety margin', () {
        // 10 Chinese characters (ignoring punctuation for simplicity)
        const text = '一二三四五六七八九十';
        final tokens = calculator.estimateTokens(text);
        // 10 * 1.8 = 18, + 10% = 19.8 -> 20
        expect(tokens, greaterThanOrEqualTo(19));
      });

      test('should return 0 for empty text', () {
        final tokens = calculator.estimateTokens('');
        expect(tokens, equals(0));
      });
    });

    group('calculateBudget', () {
      test('should subtract all components from context window', () {
        final budget = calculator.calculateBudget(
          modelContextWindow: 4096,
          systemPromptTokens: 100,
          personaTokens: 50,
          bannedListTokens: 30,
          reservedOutputTokens: 2000,
        );
        // 4096 - 100 - 50 - 30 - 2000 = 1916
        expect(budget, equals(1916));
      });

      test('should handle large context window', () {
        final budget = calculator.calculateBudget(
          modelContextWindow: 128000,
          systemPromptTokens: 200,
          personaTokens: 100,
          bannedListTokens: 50,
          reservedOutputTokens: 4000,
        );
        // 128000 - 200 - 100 - 50 - 4000 = 123650
        expect(budget, equals(123650));
      });

      test('should return 0 or negative when budget exhausted', () {
        final budget = calculator.calculateBudget(
          modelContextWindow: 1000,
          systemPromptTokens: 500,
          personaTokens: 200,
          bannedListTokens: 100,
          reservedOutputTokens: 800,
        );
        // 1000 - 500 - 200 - 100 - 800 = -600
        expect(budget, lessThanOrEqualTo(0));
      });
    });

    group('selectFragmentsWithinBudget', () {
      test('should include all fragments when within budget', () {
        final fragments = [
          Fragment(id: '1', text: '短碎片', createdAt: DateTime.now()),
          Fragment(id: '2', text: '另一个碎片', createdAt: DateTime.now()),
        ];

        final result = calculator.selectFragmentsWithinBudget(
          fragments,
          10000, // Very large budget
        );

        expect(result.included.length, equals(2));
        expect(result.excludedCount, equals(0));
        expect(result.budgetUsed, greaterThan(0));
        expect(result.budgetTotal, equals(10000));
      });

      test('should exclude fragments from end (LIFO) when over budget per D-13', () {
        final fragments = [
          Fragment(id: '1', text: '短碎片一', createdAt: DateTime.now()),
          Fragment(id: '2', text: '短碎片二', createdAt: DateTime.now()),
          Fragment(id: '3', text: '短碎片三', createdAt: DateTime.now()),
          Fragment(id: '4', text: '这是一个比较长的碎片内容，会占用更多的token预算空间', createdAt: DateTime.now()),
        ];

        // Small budget that can only fit first 2-3 fragments
        final result = calculator.selectFragmentsWithinBudget(
          fragments,
          30, // Very small budget
        );

        expect(result.included.length, lessThan(4));
        expect(result.excludedCount, greaterThan(0));
        expect(result.excludedCount, equals(4 - result.included.length));
        // LIFO: first fragments should be included
        expect(result.included.first.id, equals('1'));
      });

      test('should return empty list when budget is 0', () {
        final fragments = [
          Fragment(id: '1', text: '碎片', createdAt: DateTime.now()),
        ];

        final result = calculator.selectFragmentsWithinBudget(
          fragments,
          0,
        );

        expect(result.included, isEmpty);
        expect(result.excludedCount, equals(1));
      });

      test('should return empty result when no fragments', () {
        final result = calculator.selectFragmentsWithinBudget(
          [],
          10000,
        );

        expect(result.included, isEmpty);
        expect(result.excludedCount, equals(0));
        expect(result.budgetUsed, equals(0));
      });

      test('should set budgetUsed correctly', () {
        final fragments = [
          Fragment(id: '1', text: '短碎片', createdAt: DateTime.now()),
        ];

        final result = calculator.selectFragmentsWithinBudget(
          fragments,
          10000,
        );

        expect(result.budgetUsed, greaterThan(0));
        expect(result.budgetUsed, lessThanOrEqualTo(10000));
      });

      test('should maintain fragment order in included list', () {
        final fragments = [
          Fragment(id: 'a', text: '第一个碎片内容', createdAt: DateTime.now()),
          Fragment(id: 'b', text: '第二个碎片内容', createdAt: DateTime.now()),
          Fragment(id: 'c', text: '第三个碎片内容', createdAt: DateTime.now()),
        ];

        final result = calculator.selectFragmentsWithinBudget(
          fragments,
          10000,
        );

        // Order should be preserved
        expect(result.included[0].id, equals('a'));
        expect(result.included[1].id, equals('b'));
        expect(result.included[2].id, equals('c'));
      });
    });

    group('BudgetResult', () {
      test('should track all fields correctly', () {
        final fragments = [
          Fragment(id: '1', text: '碎片', createdAt: DateTime.now()),
        ];

        final result = calculator.selectFragmentsWithinBudget(
          fragments,
          100,
        );

        expect(result.included, isNotEmpty);
        expect(result.excludedCount, greaterThanOrEqualTo(0));
        expect(result.budgetUsed, greaterThan(0));
        expect(result.budgetTotal, equals(100));
      });
    });
  });
}
