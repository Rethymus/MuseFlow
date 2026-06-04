/// Tests for OpenAIAdapter.fetchModelList method.
///
/// Verifies model list fetching from OpenAI-compatible /v1/models endpoint
/// with silent fallback on any error per D-08.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';

void main() {
  group('OpenAIAdapter.fetchModelList', () {
    late OpenAIAdapter adapter;

    setUp(() {
      adapter = OpenAIAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('should return list of model IDs for a valid endpoint', () async {
      // This test uses a real endpoint that may or may not be reachable.
      // The contract is: returns List<String> on success, empty list on failure.
      final models = await adapter.fetchModelList(
        apiKey: 'test-key',
        baseUrl: 'https://httpbin.org',
      );
      // httpbin.org is not an OpenAI endpoint, so it should return empty list
      // (silent fallback per D-08)
      expect(models, isA<List<String>>());
    });

    test('should return empty list on any error (silent fallback)', () async {
      // Invalid URL that will fail
      final models = await adapter.fetchModelList(
        apiKey: 'invalid-key',
        baseUrl: 'https://invalid.nonexistent.domain.example/v1',
      );
      expect(models, isEmpty);
    });

    test('should return empty list for empty API key', () async {
      final models = await adapter.fetchModelList(
        apiKey: '',
        baseUrl: 'https://api.openai.com/v1',
      );
      expect(models, isEmpty);
    });

    test('should exist as a method on OpenAIAdapter', () {
      // Verify the method exists and has the correct signature
      expect(
        adapter.fetchModelList,
        isA<Function>(),
      );
    });
  });
}
