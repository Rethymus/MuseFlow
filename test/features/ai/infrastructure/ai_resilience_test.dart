/// Tests for the AI reliability fixes surfaced by the real BigModel key
/// (quick-260617-wma):
/// - AIException.toString() must surface [message] (no more "Instance of...").
/// - OpenAIAdapter.retryStream must recover from early transient failures
///   and must NOT retry auth errors or mid-stream failures.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';

void main() {
  group('AIException.toString', () {
    test('should surface the classified message instead of "Instance of..."',
        () {
      const message = 'ApiException: 502 Bad Gateway from upstream';
      final error = AIStreamException(message);

      final str = error.toString();

      expect(str, contains('AIStreamException'));
      expect(str, contains(message));
      expect(str, isNot(contains('Instance of')));
    });

    test('each subclass surfaces its own runtimeType + message', () {
      expect(AIAuthException('k1').toString(), contains('k1'));
      expect(AIRateLimitException('k2').toString(), contains('k2'));
      expect(AINetworkException('k3').toString(), contains('k3'));
    });
  });

  group('OpenAIAdapter.retryStream', () {
    // Backoff of zero keeps the suite instant while still exercising the
    // retry loop.
    Duration zeroBackoff(int _) => Duration.zero;

    Stream<String> failImmediately(AIException e) async* {
      throw e;
    }

    Stream<String> yieldAll(List<String> deltas) async* {
      for (final d in deltas) {
        yield d;
      }
    }

    Stream<String> yieldThenFail(List<String> deltas, AIException e) async* {
      for (final d in deltas) {
        yield d;
      }
      throw e;
    }

    test('should recover after transient failures then yield output', () async {
      var i = 0;
      Stream<String> factory() {
        final k = i++;
        if (k == 0) return failImmediately(const AIStreamException('boom1'));
        if (k == 1) return failImmediately(const AIRateLimitException('boom2'));
        return yieldAll(const ['hello', 'world']);
      }

      final out = await OpenAIAdapter.retryStream(
        factory,
        backoff: zeroBackoff,
      ).join();

      expect(out, 'helloworld');
      expect(i, 3, reason: 'factory invoked initial + 2 retries');
    });

    test('should NOT retry auth errors — surface immediately', () async {
      var i = 0;
      Stream<String> factory() {
        i++;
        return failImmediately(const AIAuthException('bad key'));
      }

      await expectLater(
        OpenAIAdapter.retryStream(factory, backoff: zeroBackoff).join(),
        throwsA(isA<AIAuthException>()),
      );
      expect(i, 1, reason: 'auth errors are not retryable');
    });

    test('should NOT retry once a token has been emitted (mid-stream failure)',
        () async {
      var i = 0;
      Stream<String> factory() {
        i++;
        return yieldThenFail(
          const ['partial'],
          const AIStreamException('mid-stream'),
        );
      }

      await expectLater(
        OpenAIAdapter.retryStream(factory, backoff: zeroBackoff).join(),
        throwsA(isA<AIStreamException>()),
      );
      expect(i, 1, reason: 'committed stream must not be restarted');
    });

    test('should give up after maxRetries exhausted', () async {
      var i = 0;
      Stream<String> factory() {
        i++;
        return failImmediately(const AINetworkException('down'));
      }

      await expectLater(
        OpenAIAdapter.retryStream(
          factory,
          maxRetries: 2,
          backoff: zeroBackoff,
        ).join(),
        throwsA(isA<AINetworkException>()),
      );
      expect(i, 3, reason: 'initial + maxRetries(2) = 3 total attempts');
    });

    test('should pass through a clean stream with no retry', () async {
      var i = 0;
      Stream<String> factory() {
        i++;
        return yieldAll(const ['a', 'b', 'c']);
      }

      final out = await OpenAIAdapter.retryStream(
        factory,
        backoff: zeroBackoff,
      ).join();

      expect(out, 'abc');
      expect(i, 1);
    });
  });
}
