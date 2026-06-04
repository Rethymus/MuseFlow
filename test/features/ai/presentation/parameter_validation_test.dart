/// Tests for parameter validation logic used in the provider management form.
///
/// These are pure Dart function tests -- no widget tests.
/// The parsing functions are the same ones used in the form UI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/presentation/parameter_validation.dart';

void main() {
  group('parseTemperature', () {
    test('should parse valid temperature within range', () {
      expect(parseTemperature('1.5'), 1.5);
    });

    test('should parse 0.0 as valid temperature', () {
      expect(parseTemperature('0.0'), 0.0);
    });

    test('should parse 2.0 as valid temperature (upper bound)', () {
      expect(parseTemperature('2.0'), 2.0);
    });

    test('should return null for empty string', () {
      expect(parseTemperature(''), isNull);
    });

    test('should return null for out-of-range temperature (3.0)', () {
      expect(parseTemperature('3.0'), isNull);
    });

    test('should return null for negative temperature', () {
      expect(parseTemperature('-0.5'), isNull);
    });

    test('should return null for non-numeric input', () {
      expect(parseTemperature('abc'), isNull);
    });
  });

  group('parseTopP', () {
    test('should parse valid topP within range', () {
      expect(parseTopP('0.9'), 0.9);
    });

    test('should parse 0.0 as valid topP', () {
      expect(parseTopP('0.0'), 0.0);
    });

    test('should parse 1.0 as valid topP (upper bound)', () {
      expect(parseTopP('1.0'), 1.0);
    });

    test('should return null for empty string', () {
      expect(parseTopP(''), isNull);
    });

    test('should return null for out-of-range topP (1.5)', () {
      expect(parseTopP('1.5'), isNull);
    });

    test('should return null for non-numeric input', () {
      expect(parseTopP('xyz'), isNull);
    });
  });

  group('parseMaxTokens', () {
    test('should parse valid maxTokens', () {
      expect(parseMaxTokens('4096'), 4096);
    });

    test('should parse 1 as valid maxTokens (lower bound)', () {
      expect(parseMaxTokens('1'), 1);
    });

    test('should parse 128000 as valid maxTokens (upper bound)', () {
      expect(parseMaxTokens('128000'), 128000);
    });

    test('should return null for empty string', () {
      expect(parseMaxTokens(''), isNull);
    });

    test('should return null for 0 (out of range)', () {
      expect(parseMaxTokens('0'), isNull);
    });

    test('should return null for negative value', () {
      expect(parseMaxTokens('-100'), isNull);
    });

    test('should return null for non-numeric input', () {
      expect(parseMaxTokens('abc'), isNull);
    });
  });
}
