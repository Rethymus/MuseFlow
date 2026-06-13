/// Tests for [LexicalSignature] and [LexicalTerm] value objects.
///
/// Validates immutability, empty sentinel, JSON round-trip, equality, and
/// copyWith behavior for the lexical-signature dimension of an
/// [AuthorStyleProfile].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/editor/domain/lexical_signature.dart';

void main() {
  group('LexicalSignature', () {
    test('empty should be empty', () {
      const sig = LexicalSignature.empty;
      expect(sig.isEmpty, isTrue);
      expect(sig.topTerms, isEmpty);
    });

    test('non-empty signature should not be isEmpty', () {
      const sig = LexicalSignature(
        topTerms: [LexicalTerm(term: '剑意', score: 10, frequency: 5)],
      );
      expect(sig.isEmpty, isFalse);
    });

    test('fromJson(toJson(sig)) should round-trip preserving topTerms', () {
      const sig = LexicalSignature(
        topTerms: [
          LexicalTerm(term: '剑意', score: 7.5, frequency: 5),
          LexicalTerm(term: '凌厉', score: 4.5, frequency: 3),
        ],
      );
      final restored = LexicalSignature.fromJson(sig.toJson());
      expect(restored.topTerms.length, sig.topTerms.length);
      expect(restored.topTerms.first.term, '剑意');
      expect(restored.topTerms.first.score, 7.5);
      expect(restored.topTerms.first.frequency, 5);
      expect(restored.topTerms.last.term, '凌厉');
    });

    test('== should compare all topTerms term+score+frequency', () {
      const a = LexicalSignature(
        topTerms: [LexicalTerm(term: '剑意', score: 10.0, frequency: 5)],
      );
      const b = LexicalSignature(
        topTerms: [LexicalTerm(term: '剑意', score: 10.0, frequency: 5)],
      );
      const c = LexicalSignature(
        topTerms: [LexicalTerm(term: '剑意', score: 9.0, frequency: 5)],
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('copyWith should only override provided fields', () {
      const original = LexicalSignature(
        topTerms: [LexicalTerm(term: '剑意', score: 10.0, frequency: 5)],
      );
      final updated = original.copyWith(
        topTerms: const [LexicalTerm(term: '凌厉', score: 8.0, frequency: 4)],
      );
      expect(updated.topTerms.first.term, '凌厉');
      // Unchanged shape via copyWith default (no topTerms arg) preserves original.
      final untouched = original.copyWith();
      expect(untouched.topTerms.first.term, '剑意');
    });
  });

  group('LexicalTerm', () {
    test('fromJson/toJson should round-trip', () {
      const term = LexicalTerm(term: '剑意', score: 7.5, frequency: 5);
      final restored = LexicalTerm.fromJson(term.toJson());
      expect(restored.term, '剑意');
      expect(restored.score, 7.5);
      expect(restored.frequency, 5);
    });

    test('== should compare term+score+frequency', () {
      const a = LexicalTerm(term: '剑意', score: 7.5, frequency: 5);
      const b = LexicalTerm(term: '剑意', score: 7.5, frequency: 5);
      const c = LexicalTerm(term: '剑意', score: 7.5, frequency: 6);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });
}
