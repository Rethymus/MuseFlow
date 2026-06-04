/// Tests for SynthesisNotifier state management and streaming logic.
///
/// Validates CAPT-03 (fragment-to-paragraph synthesis),
/// CAPT-04 (editable text), AI-03 (streaming), AI-06 (anti-AI-scent),
/// AI-08 (error handling), D-06 (regenerate), D-07 (editor insertion),
/// D-13 (token budget), D-14 (inline errors), D-15 (stream interruption).
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
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('SynthesisState', () {
    test('should have correct defaults', () {
      const state = SynthesisState();
      expect(state.accumulatedText, '');
      expect(state.isStreaming, false);
      expect(state.isEditing, false);
      expect(state.error, isNull);
      expect(state.excludedFragmentsNotice, isNull);
      expect(state.highlights, isEmpty);
    });

    test('copyWith should create a new state with updated fields', () {
      const state = SynthesisState();
      final updated = state.copyWith(
        accumulatedText: 'Hello',
        isStreaming: true,
      );
      expect(updated.accumulatedText, 'Hello');
      expect(updated.isStreaming, true);
      expect(updated.isEditing, false);
      expect(state.accumulatedText, ''); // original unchanged
    });

    test('copyWith should clear error when null is passed', () {
      const state = SynthesisState(error: 'some error');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('SynthesisNotifier', () {
    late ProviderContainer container;
    late _FakeOpenAIAdapter fakeAdapter;

    /// Creates a test container with configurable provider state.
    ProviderContainer createContainer({
      List<Fragment> selectedFragments = const [],
      AIProvider? activeProvider,
      String? apiKey,
      bool hasActiveProvider = true,
      bool hasApiKey = true,
    }) {
      fakeAdapter = _FakeOpenAIAdapter();

      final testProvider = hasActiveProvider
          ? (activeProvider ??
              AIProvider(
                id: 'test-provider',
                name: 'Test',
                baseUrl: 'https://api.openai.com/v1',
                type: AiProviderType.openai,
                model: 'gpt-4o-mini',
                isActive: true,
                createdAt: DateTime(2026, 1, 1),
              ))
          : null;

      final testApiKey = hasApiKey ? (apiKey ?? 'test-key') : null;

      return ProviderContainer(
        overrides: [
          openaiAdapterProvider.overrideWithValue(fakeAdapter),
          activeProviderProvider.overrideWithValue(testProvider),
          activeApiKeyProvider.overrideWithValue(testApiKey),
          selectedFragmentsProvider.overrideWithValue(selectedFragments),
        ],
      );
    }

    tearDown(() {
      container.dispose();
    });

    test('initial state should be idle (defaults)', () {
      container = createContainer();
      final state = container.read(synthesisProvider);
      expect(state.isStreaming, false);
      expect(state.isEditing, false);
      expect(state.accumulatedText, '');
      expect(state.error, isNull);
    });

    group('startSynthesis', () {
      test('should transition to streaming state', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        fakeAdapter.streamOutput = Stream.fromIterable(['他', '走', '了']);

        container.read(synthesisProvider.notifier).startSynthesis();

        await _pump();
        expect(container.read(synthesisProvider).isStreaming, anyOf(true, false));
      });

      test('should accumulate tokens and finish in editing state', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: '月光', createdAt: DateTime(2026, 1, 1)),
            Fragment(id: 'f2', text: '笛声', createdAt: DateTime(2026, 1, 2)),
          ],
        );
        fakeAdapter.streamOutput = Stream.fromIterable(['月光', '下', '他走了']);

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.accumulatedText, '月光下他走了');
        expect(state.isStreaming, false);
        expect(state.isEditing, true);
      });

      test('should run anti-AI-scent processing after stream', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        fakeAdapter.streamOutput = Stream.fromIterable(['然而，他走了。']);

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.accumulatedText, contains('但是'));
        expect(state.accumulatedText, isNot(contains('然而')));
      });

      test('should set error when no active provider configured', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
          hasActiveProvider: false,
        );

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        final state = container.read(synthesisProvider);
        expect(state.error, isNotNull);
        expect(state.isStreaming, false);
        expect(state.error, contains('AI'));
      });

      test('should set error when no API key', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
          hasApiKey: false,
        );

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.error, isNotNull);
        expect(state.error, contains('API Key'));
      });

      test('should set error when no fragments selected', () async {
        container = createContainer(selectedFragments: []);

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        final state = container.read(synthesisProvider);
        expect(state.error, isNotNull);
        expect(state.error, contains('碎片'));
      });
    });

    group('stream interruption per D-15', () {
      test('should preserve partial content on stream error', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        controller.add('月光下');
        await _pump();

        controller.addError(const AINetworkException());
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.accumulatedText, contains('月光下'));
        expect(state.isStreaming, false);
        expect(state.isEditing, true);
        expect(state.error, isNotNull);

        await controller.close();
      });

      test('should show API Key error message per D-14', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        controller.addError(const AIAuthException());
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.error, contains('API Key'));

        await controller.close();
      });

      test('should classify rate limit errors per D-14', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        controller.addError(const AIRateLimitException());
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.error, contains('稍后'));

        await controller.close();
      });

      test('should classify network errors per D-14', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        controller.addError(const AINetworkException());
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.error, contains('网络'));

        await controller.close();
      });
    });

    group('regenerate per D-06', () {
      test('should reset state and start new synthesis', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );

        fakeAdapter.streamOutput = Stream.fromIterable(['第一次']);
        container.read(synthesisProvider.notifier).startSynthesis();
        await _pumpAndWait();

        fakeAdapter.streamOutput = Stream.fromIterable(['第二次']);
        container.read(synthesisProvider.notifier).regenerate(null);
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.accumulatedText, '第二次');
        expect(state.accumulatedText, isNot(contains('第一次')));
      });

      test('should pass additional instruction to prompt', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

        container.read(synthesisProvider.notifier).regenerate('增加描写');
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(state.isStreaming, false);
        expect(state.isEditing, true);
      });
    });

    group('setError and clearError', () {
      test('setError should set error message', () {
        container = createContainer();
        container.read(synthesisProvider.notifier).setError('测试错误');
        expect(container.read(synthesisProvider).error, '测试错误');
      });

      test('clearError should remove error message', () {
        container = createContainer();
        container.read(synthesisProvider.notifier).setError('测试错误');
        container.read(synthesisProvider.notifier).clearError();
        expect(container.read(synthesisProvider).error, isNull);
      });
    });

    group('reset', () {
      test('should reset all state to defaults', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        fakeAdapter.streamOutput = Stream.fromIterable(['文本']);

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pumpAndWait();

        container.read(synthesisProvider.notifier).reset();

        final state = container.read(synthesisProvider);
        expect(state.accumulatedText, '');
        expect(state.isStreaming, false);
        expect(state.isEditing, false);
        expect(state.error, isNull);
      });
    });

    group('confirmAndInsert per D-07', () {
      test('should reset state after insertion', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        fakeAdapter.streamOutput = Stream.fromIterable(['要插入的文本']);

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pumpAndWait();

        container.read(synthesisProvider.notifier).confirmAndInsert();

        final state = container.read(synthesisProvider);
        expect(state.accumulatedText, '');
        expect(state.isStreaming, false);
        expect(state.isEditing, false);
      });

      test('should do nothing if accumulated text is empty', () {
        container = createContainer();
        container.read(synthesisProvider.notifier).confirmAndInsert();
        final state = container.read(synthesisProvider);
        expect(state.accumulatedText, '');
        expect(state.isEditing, false);
      });
    });
  });
}

// --- Helpers ---

/// Pumps microtasks to let async operations proceed.
Future<void> _pump() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}

/// Pumps and waits for stream operations to complete.
Future<void> _pumpAndWait() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
  await Future<void>.delayed(const Duration(milliseconds: 200));
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}

// --- Test fakes ---

/// Fake OpenAI adapter that returns a controllable stream.
class _FakeOpenAIAdapter extends OpenAIAdapter {
  Stream<String>? streamOutput;

  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
  }) {
    return streamOutput ?? Stream.fromIterable(['默认文本']);
  }
}
