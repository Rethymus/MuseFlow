import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:openai_dart/openai_dart.dart';

import '../fixtures/manuscript_fixtures.dart';
import '../fixtures/xianxia_content.dart';
import 'fake_adapter.dart';
import 'test_container.dart';

void main() {
  group('FakeAdapter', () {
    test(
      'should return synthesis text when messages contain fragment keywords',
      () async {
        final adapter = FakeAdapter();

        final text = await adapter
            .createStream(
              apiKey: 'fake-key-for-testing',
              baseUrl: 'http://localhost:11434/v1',
              model: 'fake-model',
              messages: [ChatMessage.user('请整理这些碎片')],
            )
            .join();

        expect(text, contains('林风'));
        expect(text, contains('筑基'));
      },
    );

    test(
      'should return rewrite text when messages contain rewrite keywords',
      () async {
        final adapter = FakeAdapter();

        final text = await adapter
            .createStream(
              apiKey: 'fake-key-for-testing',
              baseUrl: 'http://localhost:11434/v1',
              model: 'fake-model',
              messages: [ChatMessage.user('请改写语气')],
            )
            .join();

        expect(text, contains('剑光'));
      },
    );

    test(
      'should return polish text when messages contain polish keywords',
      () async {
        final adapter = FakeAdapter();

        final text = await adapter
            .createStream(
              apiKey: 'fake-key-for-testing',
              baseUrl: 'http://localhost:11434/v1',
              model: 'fake-model',
              messages: [ChatMessage.user('请润色文段')],
            )
            .join();

        expect(text.contains('灵力') || text.contains('月华'), isTrue);
      },
    );

    test('should call onUsage after stream completes', () async {
      final adapter = FakeAdapter();
      Usage? capturedUsage;

      await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('碎片：主角发现玉简')],
            onUsage: (usage) => capturedUsage = usage,
          )
          .drain<void>();

      expect(capturedUsage, isNotNull);
      expect(capturedUsage!.promptTokens, greaterThan(0));
      expect(capturedUsage!.completionTokens, greaterThan(0));
      expect(
        capturedUsage!.totalTokens,
        capturedUsage!.promptTokens + capturedUsage!.completionTokens!,
      );
    });

    test('should yield error text when error mode always triggers', () async {
      final adapter = FakeAdapter(errorRate: 1.0, errorText: '网络异常');

      final text = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('碎片')],
          )
          .join();

      expect(text, '网络异常');
    });

    test('should yield empty stream when emptyResponse is true', () async {
      final adapter = FakeAdapter(emptyResponse: true);

      final chunks = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('碎片')],
          )
          .toList();

      expect(chunks, isEmpty);
    });

    test('should return deterministic text for same operation type', () async {
      final adapter = FakeAdapter();
      final messages = [ChatMessage.user('请整理碎片')];

      final first = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: messages,
          )
          .join();
      final second = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: messages,
          )
          .join();

      expect(first, second);
      expect(first, XianxiaContent.synthesis.first);
    });
  });

  group('Automation test container', () {
    test(
      'should create ProviderContainer with repositories and FakeAdapter override',
      () async {
        final container = await createTestContainer();
        addTearDown(() => cleanupTestContainer(container));

        final repository = await container.read(
          manuscriptRepositoryProvider.future,
        );
        final manuscript = await repository.add(
          ManuscriptFixtures.xianxiaManuscript(),
        );
        final adapter = container.read(openaiAdapterProvider);

        expect(repository.getById(manuscript.id), isNotNull);
        expect(adapter, isA<FakeAdapter>());
      },
    );
  });
}
