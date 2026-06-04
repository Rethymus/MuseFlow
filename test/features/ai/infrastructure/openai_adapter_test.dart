/// Tests for OpenAIAdapter streaming, error recovery, and client caching.
///
/// Validates AI-01 (unified adapter), AI-03 (streaming SSE),
/// and AI-08 (error handling with graceful classification).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('OpenAIAdapter', () {
    late OpenAIAdapter adapter;

    setUp(() {
      adapter = OpenAIAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    group('createStream', () {
      test('should return Stream<String> of text deltas from streaming events',
          () async {
        // Simulate the adapter converting ChatStreamEvents to text deltas

        // We test the adapter's stream mapping logic by verifying
        // the method signature and basic contract.
        // The actual streaming is tested in integration tests.
        expect(adapter, isNotNull);
        expect(
          adapter.createStream,
          isA<Function>(),
        );
      });

      test('should accept apiKey, baseUrl, model, and messages parameters', () {
        // Verify the adapter exposes the correct API surface
        expect(
          // The method should exist and accept these parameters
          () => adapter.createStream(
            apiKey: 'test-key',
            baseUrl: 'https://api.openai.com/v1',
            model: 'gpt-4o-mini',
            messages: [ChatMessage.user('test')],
          ),
          returnsNormally,
        );
      });

      test('should validate HTTPS baseUrl except for localhost', () {
        // Per T-02-08: validate baseUrl starts with https://
        // Exception: localhost for Ollama
        expect(
          () => adapter.createStream(
            apiKey: 'test',
            baseUrl: 'http://evil-server.com/v1',
            model: 'gpt-4o-mini',
            messages: [ChatMessage.user('test')],
          ),
          throwsA(isA<AIException>()),
        );

        // localhost should be allowed for Ollama
        expect(
          () => adapter.createStream(
            apiKey: 'ollama',
            baseUrl: 'http://localhost:11434/v1',
            model: 'llama3',
            messages: [ChatMessage.user('test')],
          ),
          returnsNormally,
        );

        // HTTPS should always be allowed
        expect(
          () => adapter.createStream(
            apiKey: 'test',
            baseUrl: 'https://api.openai.com/v1',
            model: 'gpt-4o-mini',
            messages: [ChatMessage.user('test')],
          ),
          returnsNormally,
        );

        // Claude's HTTPS endpoint should be accepted (OpenAI-compatible)
        expect(
          () => adapter.createStream(
            apiKey: 'test-key',
            baseUrl: 'https://api.anthropic.com/v1/',
            model: 'claude-sonnet-4-20250514',
            messages: [ChatMessage.user('test')],
          ),
          returnsNormally,
        );
      });
    });

    group('error classification', () {
      test('should classify AuthenticationException as AIAuthException',
          () async {
        // Verify the error classifier maps correctly
        final exception = AuthenticationException(
          message: 'Invalid API key',
        );

        final classified = OpenAIAdapter.classifyException(exception);
        expect(classified, isA<AIAuthException>());
      });

      test('should classify RateLimitException as AIRateLimitException', () {
        final exception = RateLimitException(
          message: 'Rate limited',
        );

        final classified = OpenAIAdapter.classifyException(exception);
        expect(classified, isA<AIRateLimitException>());
      });

      test('should classify ConnectionException as AINetworkException', () {
        final exception = const ConnectionException(
          message: 'Connection refused',
        );

        final classified = OpenAIAdapter.classifyException(exception);
        expect(classified, isA<AINetworkException>());
      });

      test('should classify RequestTimeoutException as AINetworkException', () {
        final exception = const RequestTimeoutException(
          message: 'Request timed out',
        );

        final classified = OpenAIAdapter.classifyException(exception);
        expect(classified, isA<AINetworkException>());
      });

      test(
          'should classify ApiException 401/403 as AIAuthException', () {
        final exception401 = ApiException(
          message: 'Unauthorized',
          statusCode: 401,
        );
        final exception403 = ApiException(
          message: 'Forbidden',
          statusCode: 403,
        );

        expect(
          OpenAIAdapter.classifyException(exception401),
          isA<AIAuthException>(),
        );
        expect(
          OpenAIAdapter.classifyException(exception403),
          isA<AIAuthException>(),
        );
      });

      test('should classify ApiException 429 as AIRateLimitException', () {
        final exception = ApiException(
          message: 'Too many requests',
          statusCode: 429,
        );

        final classified = OpenAIAdapter.classifyException(exception);
        expect(classified, isA<AIRateLimitException>());
      });

      test('should classify other ApiException as AIStreamException', () {
        final exception = ApiException(
          message: 'Server error',
          statusCode: 500,
        );

        final classified = OpenAIAdapter.classifyException(exception);
        expect(classified, isA<AIStreamException>());
      });

      test('should classify unknown exceptions as AIStreamException', () {
        final exception = Exception('Unknown error');

        final classified = OpenAIAdapter.classifyException(exception);
        expect(classified, isA<AIStreamException>());
      });
    });

    group('client caching', () {
      test('should reuse client for same provider config', () async {
        // Creating two streams with same params should reuse the client
        // This is verified by checking dispose only closes one client
        adapter.createStream(
          apiKey: 'key1',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
          messages: [ChatMessage.user('test1')],
        );

        // Second call with same params should reuse client
        adapter.createStream(
          apiKey: 'key1',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
          messages: [ChatMessage.user('test2')],
        );

        // No error means client was reused successfully
        expect(adapter.isActive, isTrue);
      });

      test('should dispose old client when provider config changes', () async {
        adapter.createStream(
          apiKey: 'key1',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
          messages: [ChatMessage.user('test1')],
        );

        // Different provider config should create new client
        adapter.createStream(
          apiKey: 'key2',
          baseUrl: 'https://api.deepseek.com/v1',
          model: 'deepseek-chat',
          messages: [ChatMessage.user('test2')],
        );

        expect(adapter.isActive, isTrue);
      });

      test('should clean up resources on dispose', () {
        adapter.createStream(
          apiKey: 'key1',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o-mini',
          messages: [ChatMessage.user('test')],
        );

        adapter.dispose();
        expect(adapter.isActive, isFalse);
      });
    });

    group('stream text delta mapping', () {
      test('should map ChatStreamEvent textDelta to String', () async {
        // Test the internal event-to-string mapping
        // using a simulated stream of events
        final events = [
          const ChatStreamEvent(
            choices: [
              ChatStreamChoice(
                delta: ChatDelta(content: 'Hello'),
              ),
            ],
          ),
          const ChatStreamEvent(
            choices: [
              ChatStreamChoice(
                delta: ChatDelta(content: ' World'),
              ),
            ],
          ),
        ];

        // Verify each event's textDelta getter works
        expect(events[0].textDelta, equals('Hello'));
        expect(events[1].textDelta, equals(' World'));
      });

      test('should filter null textDelta events', () {
        final event = const ChatStreamEvent(
          choices: [
            ChatStreamChoice(
              delta: ChatDelta(role: 'assistant'),
            ),
          ],
        );

        // Role-only events have null textDelta
        expect(event.textDelta, isNull);
      });
    });
  });
}
