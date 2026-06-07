import 'package:flutter_test/flutter_test.dart';
import 'package:openai_dart/openai_dart.dart';

import '../fixtures/xianxia_content.dart';
import 'fake_adapter.dart';

void main() {
  group('FakeAdapter', () {
    test('should returns deterministic synthesis text when fragments provided', () async {
      final adapter = FakeAdapter();

      final text = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('碎片：主角在悬崖边缘发现一枚古老玉简')],
          )
          .join();

      expect(text, contains('林风'));
      expect(text, contains('筑基'));
    });

    test('should returns deterministic rewrite text when rewrite requested', () async {
      final adapter = FakeAdapter();

      final text = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('请改写这段文字的语气')],
          )
          .join();

      expect(text, contains('剑光'));
    });

    test('should returns deterministic polish text when polish requested', () async {
      final adapter = FakeAdapter();

      final text = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('请润色这段文段')],
          )
          .join();

      expect(text.contains('灵力') || text.contains('月华'), isTrue);
    });

    test('should calls onUsage after stream completes', () async {
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

    test('should returns error text when errorRate is 1.0', () async {
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

    test('should returns empty stream when emptyResponse is true', () async {
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

    test('should is deterministic across repeated calls', () async {
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

    test('should falls back to freeInput for unknown operation type', () async {
      final adapter = FakeAdapter();

      final text = await adapter
          .createStream(
            apiKey: 'fake-key-for-testing',
            baseUrl: 'http://localhost:11434/v1',
            model: 'fake-model',
            messages: [ChatMessage.user('介绍这把古剑的来历')],
          )
          .join();

      expect(text, contains('斩仙'));
    });
  });
}
