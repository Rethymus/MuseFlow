/// Tests for EditorAINotifier state management and streaming logic.
///
/// Validates the editor AI operation flow:
/// 1. startOperation validates provider + API key
/// 2. Streams tokens from OpenAIAdapter
/// 3. Accumulates tokens in progressText
/// 4. Runs AntiAIScentProcessor post-processing
/// 5. Cancel stops streaming
/// 6. Reset clears state
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/features/editor/application/editor_ai_notifier.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('EditorAINotifier', () {
    late ProviderContainer container;
    late _FakeOpenAIAdapter fakeAdapter;

    ProviderContainer createContainer({
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
          editorPromptPipelineProvider.overrideWith(
            (ref) async => EditorPromptPipeline(),
          ),
        ],
      );
    }

    tearDown(() {
      container.dispose();
    });

    test('initial state should be idle', () {
      container = createContainer();
      final state = container.read(editorAINotifierProvider);
      expect(state.isStreaming, false);
      expect(state.operation, isNull);
      expect(state.progressText, isNull);
      expect(state.error, isNull);
      expect(state.selectedText, '');
    });

    group('startOperation', () {
      test('should set error when no active provider', () {
        container = createContainer(hasActiveProvider: false);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '测试文字',
              'node-1',
              0,
              10,
            );

        final state = container.read(editorAINotifierProvider);
        expect(state.error, isNotNull);
        expect(state.error, contains('AI'));
        expect(state.isStreaming, false);
      });

      test('should set error when no API key', () async {
        container = createContainer(hasApiKey: false);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '测试文字',
              'node-1',
              0,
              10,
            );
        await _pump();

        final state = container.read(editorAINotifierProvider);
        expect(state.error, isNotNull);
        expect(state.error, contains('API Key'));
        expect(state.isStreaming, false);
      });

      test('should accumulate tokens during streaming', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['月光', '下', '他走了']);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '月光洒在窗台上',
              'node-1',
              0,
              7,
            );
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.progressText, '月光下他走了');
        expect(state.isStreaming, false);
      });

      test('should set operation type in state', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.paragraphPolish,
              '测试',
              'node-1',
              0,
              2,
            );
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.operation, EditorAIOperation.paragraphPolish);
      });

      test('should store selectedText and selection range in state', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '选中文字',
              'node-42',
              5,
              10,
            );
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.selectedText, '选中文字');
        expect(state.selectionNodeId, 'node-42');
        expect(state.selectionStartOffset, 5);
        expect(state.selectionEndOffset, 10);
      });

      test('should run anti-AI-scent post-processing after stream', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['然而，他走了。']);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '然而他走了',
              'node-1',
              0,
              5,
            );
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        // Anti-AI-scent should replace 然而 with 但是
        expect(state.progressText, contains('但是'));
        expect(state.progressText, isNot(contains('然而')));
      });
    });

    group('freeInput with userInstruction', () {
      test('should store userInstruction in state', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['改好了']);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.freeInput,
              '原文',
              'node-1',
              0,
              2,
              userInstruction: '请改得更生动',
            );
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.userInstruction, '请改得更生动');
      });
    });

    group('cancel', () {
      test('should stop streaming when cancelled', () async {
        container = createContainer();
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '测试',
              'node-1',
              0,
              2,
            );
        await _pump();

        controller.add('第一');
        await _pump();

        container.read(editorAINotifierProvider.notifier).cancel();
        await _pump();

        controller.add('第二');
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.isStreaming, false);
        // Should have first token but not second
        expect(state.progressText, contains('第一'));

        await controller.close();
      });
    });

    group('reset', () {
      test('should clear all state to defaults', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['文本']);

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '测试',
              'node-1',
              0,
              2,
            );
        await _pumpAndWait();

        container.read(editorAINotifierProvider.notifier).reset();

        final state = container.read(editorAINotifierProvider);
        expect(state.isStreaming, false);
        expect(state.operation, isNull);
        expect(state.progressText, isNull);
        expect(state.error, isNull);
        expect(state.selectedText, '');
      });
    });

    group('stream errors', () {
      test('should set Chinese error on auth failure', () async {
        container = createContainer();
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '测试',
              'node-1',
              0,
              2,
            );
        await _pump();

        controller.addError(const AIAuthException());
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.error, contains('API Key'));
        expect(state.isStreaming, false);

        await controller.close();
      });

      test('should set Chinese error on network failure', () async {
        container = createContainer();
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '测试',
              'node-1',
              0,
              2,
            );
        await _pump();

        controller.addError(const AINetworkException());
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.error, contains('网络'));
        expect(state.isStreaming, false);

        await controller.close();
      });

      test('should set Chinese error on rate limit', () async {
        container = createContainer();
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(editorAINotifierProvider.notifier).startOperation(
              EditorAIOperation.toneRewrite,
              '测试',
              'node-1',
              0,
              2,
            );
        await _pump();

        controller.addError(const AIRateLimitException());
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.error, contains('稍后'));
        expect(state.isStreaming, false);

        await controller.close();
      });
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
  await Future<void>.delayed(const Duration(milliseconds: 200));
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}

// --- Test fakes ---

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
