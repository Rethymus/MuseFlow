import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';

void main() {
  group('AIAdapter', () {
    test('should declare OpenAIAdapter-compatible createStream interface', () {
      final AIAdapter adapter = OpenAIAdapter();

      expect(adapter, isA<AIAdapter>());
      expect(
        adapter.createStream(
          apiKey: 'fake-key-for-testing',
          baseUrl: 'http://localhost:11434/v1',
          model: 'fake-model',
          messages: const [],
        ),
        isA<Stream<String>>(),
      );
    });

    test('should allow OpenAIAdapter runtime conformance checks', () {
      expect(OpenAIAdapter(), isA<AIAdapter>());
    });

    test('should expose openaiAdapterProvider as AIAdapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final adapter = container.read(openaiAdapterProvider);

      expect(adapter, isA<AIAdapter>());
    });
  });
}
