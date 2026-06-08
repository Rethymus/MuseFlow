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
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
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
      TokenAuditService? auditService,
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
          tokenAuditServiceProvider.overrideWith(
            (ref) async => auditService ?? _RecordingTokenAuditService(),
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

      test(
        'should record token audit after successful stream completion',
        () async {
          final auditService = _RecordingTokenAuditService();
          container = createContainer(auditService: auditService);
          fakeAdapter.streamOutput = Stream.fromIterable(['润色', '结果']);
          fakeAdapter.usage = const Usage(
            promptTokens: 13,
            completionTokens: 7,
            totalTokens: 20,
          );

          container
              .read(editorAINotifierProvider.notifier)
              .startOperation(
                EditorAIOperation.paragraphPolish,
                '原始文字',
                'node-1',
                0,
                4,
                manuscriptId: 'manuscript-1',
                chapterId: 'chapter-1',
              );
          await _pumpAndWait();

          expect(auditService.calls, hasLength(1));
          final call = auditService.calls.single;
          expect(call.usage, same(fakeAdapter.usage));
          expect(call.modelName, 'gpt-4o-mini');
          expect(call.operationType, AuditOperationType.polish);
          expect(call.manuscriptId, 'manuscript-1');
          expect(call.chapterId, 'chapter-1');
          expect(call.inputText, '原始文字');
          expect(call.outputText, '润色结果');
        },
      );

      test('should set operation type in state', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
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
  Usage? usage;

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
  }) async* {
    await for (final chunk in streamOutput ?? Stream.fromIterable(['默认文本'])) {
      yield chunk;
    }
    onUsage?.call(usage);
  }
}

class _RecordingTokenAuditService extends TokenAuditService {
  _RecordingTokenAuditService()
    : super(_NoopTokenAuditRepository(), TokenBudgetCalculator());

  final List<_AuditCall> calls = [];

  @override
  void recordAudit({
    required Usage? usage,
    required String modelName,
    required AuditOperationType operationType,
    required String manuscriptId,
    String? chapterId,
    required String inputText,
    required String outputText,
  }) {
    calls.add(
      _AuditCall(
        usage: usage,
        modelName: modelName,
        operationType: operationType,
        manuscriptId: manuscriptId,
        chapterId: chapterId,
        inputText: inputText,
        outputText: outputText,
      ),
    );
  }
}

class _AuditCall {
  const _AuditCall({
    required this.usage,
    required this.modelName,
    required this.operationType,
    required this.manuscriptId,
    required this.chapterId,
    required this.inputText,
    required this.outputText,
  });

  final Usage? usage;
  final String modelName;
  final AuditOperationType operationType;
  final String manuscriptId;
  final String? chapterId;
  final String inputText;
  final String outputText;
}

class _NoopTokenAuditRepository implements TokenAuditRepository {
  @override
  Future<void> clearAll() async {}

  @override
  int get count => 0;

  @override
  Future<void> enforceLimit(int maxRecords) async {}

  @override
  Future<List<TokenAuditRecord>> loadAll() async => const [];

  @override
  Future<void> saveAll(List<TokenAuditRecord> records) async {}

  @override
  Future<TokenAuditSnapshot> buildSnapshot() async =>
      const TokenAuditSnapshot();
}
