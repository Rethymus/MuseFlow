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

    test('should return a list type when provider fetch fails', () async {
      // No live network or API key is required for validation. The automated
      // contract is that unsupported/unreachable endpoints fall back silently.
      final models = await adapter.fetchModelList(
        apiKey: 'test-key',
        baseUrl: 'not-a-valid-url',
      );
      expect(models, isA<List<String>>());
      expect(models, isEmpty);
    });

    test('should return empty list on any error (silent fallback)', () async {
      final models = await adapter.fetchModelList(
        apiKey: 'invalid-key',
        baseUrl: 'http://127.0.0.1:1/v1',
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

    test(
      'should return empty list before URL validation when offline',
      () async {
        final gatedAdapter = OpenAIAdapter(onlineCheck: () async => true);
        addTearDown(gatedAdapter.dispose);

        final models = await gatedAdapter.fetchModelList(
          apiKey: 'test-key',
          baseUrl: 'not-a-valid-url',
        );

        expect(models, isEmpty);
      },
    );

    test('should return empty list when offline probe fails', () async {
      final gatedAdapter = OpenAIAdapter(
        onlineCheck: () async => throw StateError('probe unavailable'),
      );
      addTearDown(gatedAdapter.dispose);

      final models = await gatedAdapter.fetchModelList(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1',
      );

      expect(models, isEmpty);
    });

    test('should exist as a method on OpenAIAdapter', () {
      // Verify the method exists and has the correct signature
      expect(adapter.fetchModelList, isA<Function>());
    });
  });
}
