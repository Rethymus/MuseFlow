/// Tests for AIAdapter abstract interface extraction (Task 1 of Plan 13-01).
///
/// Validates:
/// - AIAdapter abstract class exists with createStream method
/// - OpenAIAdapter implements AIAdapter
/// - openaiAdapterProvider is typed as `Provider<AIAdapter>`
/// - Existing consumers still work after the refactor
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('AIAdapter interface', () {
    test('should exist as abstract class with createStream method', () {
      // AIAdapter should be constructable only via subclasses (abstract).
      // We verify the type exists and OpenAIAdapter can be assigned to it.
      final adapter = OpenAIAdapter();
      expect(adapter, isA<AIAdapter>());
    });

    test('OpenAIAdapter should implement AIAdapter', () {
      final adapter = OpenAIAdapter();
      expect(adapter, isA<AIAdapter>());
      // Verify createStream is callable through the interface type
      final AIAdapter typedAdapter = adapter;
      expect(typedAdapter.createStream, isA<Function>());
    });

    test('openaiAdapterProvider should return type AIAdapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final adapter = container.read(openaiAdapterProvider);
      expect(adapter, isA<AIAdapter>());
      expect(adapter, isA<OpenAIAdapter>());
    });

    test('openaiAdapterProvider should be overridable with AIAdapter subclass',
        () {
      final fakeAdapter = _TestAIAdapter();
      final container = ProviderContainer(
        overrides: [
          openaiAdapterProvider.overrideWithValue(fakeAdapter),
        ],
      );
      addTearDown(container.dispose);

      final adapter = container.read(openaiAdapterProvider);
      expect(adapter, isA<AIAdapter>());
      expect(adapter, isA<_TestAIAdapter>());
    });

    test(
        'existing consumers should work with openaiAdapterProvider returning AIAdapter',
        () async {
      // Verify that downstream services can use the provider without issue.
      // The provider returns AIAdapter, which has createStream -- same as before.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final adapter = container.read(openaiAdapterProvider);
      // Verify the adapter has the createStream method with expected signature
      expect(
        adapter.createStream(
          apiKey: 'test',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
          messages: [
            ChatMessage.user('Hello'),
          ],
        ),
        isA<Stream<String>>(),
      );
    });
  });
}

/// Minimal AIAdapter implementation for override testing.
class _TestAIAdapter implements AIAdapter {
  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  }) {
    return Stream.fromIterable(['test output']);
  }
}
