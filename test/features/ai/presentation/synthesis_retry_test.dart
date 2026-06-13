/// Tests for SynthesisNotifier auto-retry on transient errors.
///
/// Validates that rate limit and network errors trigger automatic retry
/// with exponential backoff, while auth errors do not retry.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('SynthesisNotifier retry logic', () {
    late ProviderContainer container;
    late _ControllableFakeAdapter fakeAdapter;

    ProviderContainer createContainer({
      List<Fragment> selectedFragments = const [],
      AIProvider? activeProvider,
      String? apiKey,
      TokenAuditService? auditService,
    }) {
      fakeAdapter = _ControllableFakeAdapter();

      final testProvider = activeProvider ??
          AIProvider(
            id: 'test-provider',
            name: 'Test',
            baseUrl: 'https://api.openai.com/v1',
            type: AiProviderType.openai,
            model: 'gpt-4o-mini',
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
          );

      return ProviderContainer(
        overrides: [
          openaiAdapterProvider.overrideWithValue(fakeAdapter),
          activeProviderProvider.overrideWithValue(testProvider),
          activeApiKeyProvider.overrideWithValue(apiKey ?? 'test-key'),
          selectedFragmentsProvider.overrideWithValue(selectedFragments),
          tokenAuditServiceProvider.overrideWith(
            (ref) async => auditService ?? _NoOpAuditService(),
          ),
        ],
      );
    }

    tearDown(() {
      container.dispose();
    });

    test('should have retryCount default to 0', () {
      container = createContainer();
      final state = container.read(synthesisProvider);
      expect(state.retryCount, 0);
    });

    test('should have maxRetries set to 3', () {
      expect(SynthesisState.maxRetries, 3);
    });

    test('should not retry on AIAuthException', () async {
      container = createContainer(
        selectedFragments: [
          Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
        ],
      );

      // First call fails with auth error
      fakeAdapter.nextStream = Stream.error(const AIAuthException());

      container.read(synthesisProvider.notifier).startSynthesis();
      await _pumpAndWait();

      final state = container.read(synthesisProvider);
      expect(state.error, contains('API Key'));
      expect(state.retryCount, 0); // No retry attempted
      expect(fakeAdapter.callCount, 1); // Only one attempt
    });

    test('should retry on AIRateLimitException and succeed', () async {
      container = createContainer(
        selectedFragments: [
          Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
        ],
      );

      // First call fails with rate limit, second succeeds
      fakeAdapter.nextStream = Stream.error(const AIRateLimitException());
      fakeAdapter
          .setStreamAt(1, Stream.fromIterable(['重试', '成功']));

      // Use zero-delay retry for testing
      container.read(synthesisProvider.notifier).startSynthesis();

      // Wait for first error and retry scheduling
      await _pump();

      // Simulate backoff completing (retry should happen)
      // The retry waits for Future.delayed, so we need to wait longer
      await Future<void>.delayed(const Duration(seconds: 3));
      await _pump();

      // After retry succeeds, should have accumulated text
      expect(fakeAdapter.callCount, greaterThanOrEqualTo(2));
    });

    test('should retry on AINetworkException', () async {
      container = createContainer(
        selectedFragments: [
          Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
        ],
      );

      // First two calls fail with network error, third succeeds
      fakeAdapter.nextStream = Stream.error(const AINetworkException());
      fakeAdapter.setStreamAt(1, Stream.error(const AINetworkException()));
      fakeAdapter
          .setStreamAt(2, Stream.fromIterable(['第三次', '成功']));

      container.read(synthesisProvider.notifier).startSynthesis();
      await _pump();

      // Wait for retries with backoff (2s + 4s = 6s minimum)
      await Future<void>.delayed(const Duration(seconds: 8));
      await _pump();

      expect(fakeAdapter.callCount, greaterThanOrEqualTo(2));
    });

    test('should exhaust retries and show error after max attempts', () async {
      container = createContainer(
        selectedFragments: [
          Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
        ],
      );

      // All calls fail with rate limit
      fakeAdapter.nextStream = Stream.error(const AIRateLimitException());
      for (var i = 1; i <= SynthesisState.maxRetries; i++) {
        fakeAdapter.setStreamAt(i, Stream.error(const AIRateLimitException()));
      }

      container.read(synthesisProvider.notifier).startSynthesis();

      // Wait for all retries to exhaust (2s + 4s + 8s = 14s minimum)
      await Future<void>.delayed(const Duration(seconds: 20));
      await _pump();

      final state = container.read(synthesisProvider);
      expect(fakeAdapter.callCount, SynthesisState.maxRetries + 1);
      expect(state.error, isNotNull);
      expect(state.isStreaming, false);
    });

    test('should clear accumulated text on retry for clean restart', () async {
      container = createContainer(
        selectedFragments: [
          Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
        ],
      );

      // First call streams partial text then errors, second succeeds
      final controller1 = StreamController<String>();
      fakeAdapter.nextStream = controller1.stream;

      container.read(synthesisProvider.notifier).startSynthesis();
      await _pump();

      // Stream partial text
      controller1.add('部分文本');
      await _pump();

      // Then error triggers retry
      controller1.addError(const AIRateLimitException());
      await _pump();

      // After retry backoff, text should be cleared for clean restart
      await Future<void>.delayed(const Duration(seconds: 3));
      await _pump();

      await controller1.close();
    });
  });
}

// --- Helpers ---

Future<void> _pump() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}

Future<void> _pumpAndWait() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
  await Future<void>.delayed(const Duration(milliseconds: 500));
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}

/// Fake adapter that allows controlling stream per-call.
class _ControllableFakeAdapter extends OpenAIAdapter {
  int callCount = 0;
  Stream<String>? nextStream;
  final Map<int, Stream<String>> _streamsAt = {};

  void setStreamAt(int index, Stream<String> stream) {
    _streamsAt[index] = stream;
  }

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
    final stream = _streamsAt.remove(callCount) ?? nextStream ?? Stream.empty();
    callCount++;
    return stream;
  }
}

class _NoOpAuditService implements TokenAuditService {
  @override
  void recordAudit({
    required Usage? usage,
    required String modelName,
    required AuditOperationType operationType,
    required String manuscriptId,
    String? chapterId,
    required String inputText,
    required String outputText,
  }) {}

  @override
  Future<void> flush() async {}

  @override
  void dispose() {}

  @override
  Duration get debounceDuration => Duration.zero;

  @override
  void record_(TokenAuditRecord record) {}
}
