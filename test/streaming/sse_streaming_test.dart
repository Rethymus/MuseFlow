/// SSE streaming integration test for openai_dart with real API.
///
/// Validates end-to-end SSE streaming from an OpenAI-compatible API
/// (OpenAI or DeepSeek) using the openai_dart SDK. Tests Chinese text
/// streaming to verify no encoding issues.
///
/// Set environment variables to run:
///   OPENAI_API_KEY - Required. API key from OpenAI or DeepSeek.
///   OPENAI_BASE_URL - Optional. Defaults to OpenAI. Set to
///     https://api.deepseek.com/v1 for DeepSeek testing.
///
/// If OPENAI_API_KEY is not set, the test SKIPS (does not fail).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SSE Streaming', () {
    late String? apiKey;
    late String? baseUrl;

    setUp(() {
      apiKey = Platform.environment['OPENAI_API_KEY'];
      baseUrl = Platform.environment['OPENAI_BASE_URL'];
    });

    test(
      'streams Chinese text from real API without errors',
      () async {
        if (apiKey == null || apiKey!.isEmpty) {
          markTestSkipped(
            'Set OPENAI_API_KEY env var to run SSE streaming test',
          );
          return;
        }

        final client = OpenAIClient.withApiKey(
          apiKey!,
          baseUrl: baseUrl ?? 'https://api.openai.com/v1',
        );

        final stream = client.chat.completions.createStream(
          ChatCompletionCreateRequest(
            model: 'gpt-4o-mini',
            messages: [
              ChatMessage.user('请用三句话描述一个武侠场景'),
            ],
            maxTokens: 200,
            temperature: 0.7,
          ),
        );

        // StreamingBuffer pattern: collect tokens, measure timing
        final tokens = <String>[];
        final buffer = StringBuffer();
        DateTime? firstTokenTime;
        final streamStart = DateTime.now();
        int totalTokenCount = 0;

        await for (final event in stream) {
          final delta = event.textDelta;
          if (delta != null && delta.isNotEmpty) {
            firstTokenTime ??= DateTime.now();
            tokens.add(delta);
            buffer.write(delta);
            totalTokenCount++;
          }
        }

        final streamEnd = DateTime.now();
        final totalDuration = streamEnd.difference(streamStart);
        final timeToFirst = firstTokenTime?.difference(streamStart);

        // Verify stream completed with content
        expect(tokens, isNotEmpty, reason: 'Stream should produce tokens');
        expect(buffer.toString(), isNotEmpty, reason: 'Buffer should contain text');

        // Verify Chinese characters present (no garbled text)
        final chineseRegex = RegExp(r'[一-鿿]');
        expect(
          chineseRegex.hasMatch(buffer.toString()),
          isTrue,
          reason: 'Response should contain Chinese characters',
        );

        // Verify no garbled characters (no replacement characters)
        expect(
          buffer.toString(),
          isNot(contains('�')),
          reason: 'No Unicode replacement characters (garbled text)',
        );

        // Log metrics for SSE_VALIDATION.md
        // ignore: avoid_print
        print('--- SSE Streaming Metrics ---');
        // ignore: avoid_print
        print('Total tokens received: $totalTokenCount');
        // ignore: avoid_print
        print('Time to first token: ${timeToFirst?.inMilliseconds}ms');
        // ignore: avoid_print
        print('Total streaming duration: ${totalDuration.inMilliseconds}ms');
        if (totalDuration.inMilliseconds > 0) {
          final tokensPerSec =
              (totalTokenCount / totalDuration.inMilliseconds * 1000)
                  .toStringAsFixed(1);
          // ignore: avoid_print
          print('Average tokens/sec: $tokensPerSec');
        }
        // ignore: avoid_print
        print(
          'Response preview: '
          '${buffer.toString().substring(0, buffer.length > 100 ? 100 : buffer.length)}...',
        );

        client.close();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'streaming buffer batches tokens correctly',
      () async {
        // Unit test for the StreamingBuffer pattern without real API
        const batchSize = Duration(milliseconds: 100);
        final receivedTokens = [
          '剑', '光', '如', '水', '，',
          '划', '破', '长', '空', '。',
        ];

        final batches = <List<String>>[];
        var currentBatch = <String>[];
        var lastFlush = DateTime.now();

        for (final token in receivedTokens) {
          currentBatch.add(token);
          final now = DateTime.now();
          if (now.difference(lastFlush) >= batchSize) {
            if (currentBatch.isNotEmpty) {
              batches.add(List.from(currentBatch));
              currentBatch = [];
              lastFlush = now;
            }
          }
        }
        // Flush remaining
        if (currentBatch.isNotEmpty) {
          batches.add(currentBatch);
        }

        // Verify batching occurred
        expect(batches, isNotEmpty, reason: 'Should have at least one batch');
        expect(
          batches.expand((b) => b).join(),
          equals(receivedTokens.join()),
          reason: 'All tokens should be accounted for in batches',
        );

        // ignore: avoid_print
        print('--- Batch Metrics ---');
        // ignore: avoid_print
        print('Total tokens: ${receivedTokens.length}');
        // ignore: avoid_print
        print('Number of batches: ${batches.length}');
        for (var i = 0; i < batches.length; i++) {
          // ignore: avoid_print
          print('Batch ${i + 1}: ${batches[i].join()} (${batches[i].length} tokens)');
        }
      },
    );
  });
}
