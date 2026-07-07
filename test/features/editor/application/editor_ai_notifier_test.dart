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
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/application/skill_notifier.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/editor/application/editor_chapter_memory_context_builder.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
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
      EditorChapterMemoryContextBuilder? chapterMemoryContextBuilder,
      bool? autoDeviationCheck,
      _RecordingDeviationNotifier? deviationRecorder,
      _FakeOpenAIAdapter? openAIAdapterOverride,
      _FakeOpenAIAdapter? claudeAdapterOverride,
    }) {
      fakeAdapter = openAIAdapterOverride ?? _FakeOpenAIAdapter();

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
          if (claudeAdapterOverride != null)
            claudeAdapterProvider.overrideWithValue(claudeAdapterOverride),
          activeProviderProvider.overrideWithValue(testProvider),
          activeApiKeyProvider.overrideWithValue(testApiKey),
          editorPromptPipelineProvider.overrideWith(
            (ref) async => EditorPromptPipeline(),
          ),
          tokenAuditServiceProvider.overrideWith(
            (ref) async => auditService ?? _RecordingTokenAuditService(),
          ),
          if (chapterMemoryContextBuilder != null)
            editorChapterMemoryContextBuilderProvider.overrideWith(
              (ref) async => chapterMemoryContextBuilder,
            ),
          if (deviationRecorder != null)
            deviationNotifierProvider.overrideWith(() => deviationRecorder),
          if (autoDeviationCheck != null)
            autoDeviationCheckProvider.overrideWith(
              () => _StaticAutoDeviationCheck(autoDeviationCheck),
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

    group('deviation check gating', () {
      test(
        'does NOT trigger deviation check by default (no hidden 2x cost)',
        () async {
          final recorder = _RecordingDeviationNotifier();
          container = createContainer(deviationRecorder: recorder);
          fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

          container
              .read(editorAINotifierProvider.notifier)
              .startOperation(
                EditorAIOperation.paragraphPolish,
                '原始文字',
                'node-1',
                0,
                4,
              );
          await _pumpAndWait();

          expect(
            recorder.checkedTexts,
            isEmpty,
            reason: '默认关闭 -> 不应触发第二次偏差检测 LLM 调用（成本不翻倍）',
          );
        },
      );

      test('triggers deviation check only when setting is ON', () async {
        final recorder = _RecordingDeviationNotifier();
        container = createContainer(
          deviationRecorder: recorder,
          autoDeviationCheck: true,
        );
        fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
              EditorAIOperation.paragraphPolish,
              '原始文字',
              'node-1',
              0,
              4,
            );
        await _pumpAndWait();

        expect(recorder.checkedTexts, hasLength(1), reason: '用户开启 -> 触发一次偏差检测');
      });
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
        'should use Claude adapter when Claude provider is active',
        () async {
          final openAIAdapter = _FakeOpenAIAdapter();
          final claudeAdapter = _FakeOpenAIAdapter()
            ..streamOutput = Stream.fromIterable(['Claude', '结果']);
          final provider = AIProvider(
            id: 'claude-provider',
            name: 'Claude',
            baseUrl: 'https://api.anthropic.com',
            type: AiProviderType.claude,
            model: 'claude-3-5-haiku-latest',
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
          );
          container = createContainer(
            activeProvider: provider,
            openAIAdapterOverride: openAIAdapter,
            claudeAdapterOverride: claudeAdapter,
          );

          container
              .read(editorAINotifierProvider.notifier)
              .startOperation(
                EditorAIOperation.paragraphPolish,
                '原始文字',
                'node-1',
                0,
                4,
              );
          await _pumpAndWait();

          final state = container.read(editorAINotifierProvider);
          expect(state.progressText, 'Claude结果');
          expect(openAIAdapter.calls, isZero);
          expect(claudeAdapter.calls, 1);
          expect(claudeAdapter.lastBaseUrl, 'https://api.anthropic.com');
          expect(claudeAdapter.lastModel, 'claude-3-5-haiku-latest');
        },
      );

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
        // 然而 is highlight-only: wrapped with markers, not replaced
        expect(state.progressText, contains('【然而】'));
      });

      test('should store anti-AI-scent review signals after stream', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable([
          '与此同时，林风体内灵力翻涌，周身气息骤然拔高。'
              '就在这时，他眼中闪过一丝冷光，磅礴的力量震开石阶。'
              '下一刻，真正的考验才刚刚开始。',
        ]);

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
              EditorAIOperation.paragraphPolish,
              '林风走上石阶。',
              'node-1',
              0,
              7,
            );
        await _pumpAndWait();

        final state = container.read(editorAINotifierProvider);
        expect(state.reviewSignals, isNotEmpty);
        expect(
          state.reviewSignals.map((signal) => signal.title),
          contains('转场套话偏多'),
        );
      });

      test(
        'should store intent preservation review signals after stream',
        () async {
          container = createContainer();
          fakeAdapter.streamOutput = Stream.fromIterable(['林风握着旧物，想起有人说过的话。']);

          container
              .read(editorAINotifierProvider.notifier)
              .startOperation(
                EditorAIOperation.toneRewrite,
                '林风握着青铜玉简，想起苏雪晴在紫霄宫前说过的话。',
                'node-1',
                0,
                24,
              );
          await _pumpAndWait();

          final state = container.read(editorAINotifierProvider);
          expect(
            state.reviewSignals.map((signal) => signal.title),
            contains('原文关键信息可能丢失'),
          );
        },
      );

      test(
        'should inject adjacent chapter memory warnings into prompt',
        () async {
          final chapterRepository = _MemoryChapterRepository([
            _chapter(
              id: 'previous',
              sortOrder: 1,
              text: '林风雨夜守山。苏雪晴递来玉简，赵天磊暗中放出白灵，清虚真人宣布宗门试炼提前。',
            ),
            _chapter(id: 'current', sortOrder: 2, text: '当前章节正文。'),
          ]);
          container = createContainer(
            chapterMemoryContextBuilder: EditorChapterMemoryContextBuilder(
              chapterRepository: chapterRepository,
              summaryCharacterLimit: 26,
            ),
          );
          fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

          container
              .read(editorAINotifierProvider.notifier)
              .startOperation(
                EditorAIOperation.paragraphPolish,
                '当前选中文字',
                'node-1',
                0,
                6,
                manuscriptId: 'm1',
                chapterId: 'current',
              );
          await _pumpAndWait();

          final promptText = fakeAdapter.lastMessages
              .map((message) => message.toJson()['content'])
              .join('\n');
          expect(promptText, contains('上一章节摘要'));
          expect(promptText, contains('记忆复查提示'));
          expect(promptText, contains('截断上下文'));
          expect(promptText, contains('当前选中文字'));
        },
      );
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

    group('multi-turn conversation history', () {
      test(
        'should save conversation turn after successful operation',
        () async {
          container = createContainer();
          fakeAdapter.streamOutput = Stream.fromIterable(['润色后']);

          container
              .read(editorAINotifierProvider.notifier)
              .startOperation(
                EditorAIOperation.paragraphPolish,
                '原文',
                'node-1',
                0,
                2,
                userInstruction: '请润色',
              );
          await _pumpAndWait();

          final state = container.read(editorAINotifierProvider);
          expect(state.conversationHistory, hasLength(1));
          expect(state.conversationHistory.first.userInstruction, '请润色');
          expect(
            state.conversationHistory.first.operation,
            EditorAIOperation.paragraphPolish,
          );
        },
      );

      test('should include history messages in subsequent requests', () async {
        container = createContainer();
        // First turn
        fakeAdapter.streamOutput = Stream.fromIterable(['第一版']);
        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
              EditorAIOperation.toneRewrite,
              '原文',
              'node-1',
              0,
              2,
            );
        await _pumpAndWait();

        // Second turn — should include history
        fakeAdapter.streamOutput = Stream.fromIterable(['第二版']);
        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
              EditorAIOperation.toneRewrite,
              '原文',
              'node-1',
              0,
              2,
              userInstruction: '太平淡了',
            );
        await _pumpAndWait();

        // Verify the adapter received messages with history
        expect(fakeAdapter.lastMessages.length, greaterThan(2));
        // System message + history (user + assistant) + current user message
        final roles = fakeAdapter.lastMessages
            .map((m) => m.toJson()['role'])
            .toList();
        expect(roles.first, 'system');
        // History messages from first turn
        expect(roles, contains('assistant'));
      });

      test('should trim history to maxConversationTurns', () async {
        container = createContainer();

        // Run 6 operations to exceed max of 5
        for (var i = 0; i < 6; i++) {
          fakeAdapter.streamOutput = Stream.fromIterable(['版本$i']);
          container
              .read(editorAINotifierProvider.notifier)
              .startOperation(
                EditorAIOperation.paragraphPolish,
                '原文',
                'node-1',
                0,
                2,
              );
          await _pumpAndWait();
        }

        final state = container.read(editorAINotifierProvider);
        expect(
          state.conversationHistory.length,
          EditorAIState.maxConversationTurns,
        );
        // Oldest turn should be trimmed (turn 0 is gone)
        expect(state.conversationHistory.first.userInstruction, '文段润色');
      });

      test('should clear conversation history on reset', () async {
        container = createContainer();
        fakeAdapter.streamOutput = Stream.fromIterable(['结果']);

        container
            .read(editorAINotifierProvider.notifier)
            .startOperation(
              EditorAIOperation.paragraphPolish,
              '原文',
              'node-1',
              0,
              2,
            );
        await _pumpAndWait();

        expect(
          container.read(editorAINotifierProvider).conversationHistory,
          hasLength(1),
        );

        container.read(editorAINotifierProvider.notifier).reset();

        expect(
          container.read(editorAINotifierProvider).conversationHistory,
          isEmpty,
        );
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
  List<ChatMessage> lastMessages = const [];
  int calls = 0;
  String? lastBaseUrl;
  String? lastModel;

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
    calls += 1;
    lastBaseUrl = baseUrl;
    lastModel = model;
    lastMessages = messages;
    await for (final chunk in streamOutput ?? Stream.fromIterable(['默认文本'])) {
      yield chunk;
    }
    onUsage?.call(usage);
  }
}

class _MemoryChapterRepository extends ChapterRepository {
  _MemoryChapterRepository(this.chapters) : super(_FakeBox());

  final List<Chapter> chapters;

  @override
  List<Chapter> getByManuscriptId(String manuscriptId) {
    return chapters
        .where((chapter) => chapter.manuscriptId == manuscriptId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}

Chapter _chapter({
  required String id,
  required int sortOrder,
  required String text,
}) {
  return Chapter(
    id: id,
    manuscriptId: 'm1',
    title: '第$sortOrder章',
    sortOrder: sortOrder,
    documentContent: text,
    createdAt: DateTime(2026, 1, sortOrder),
    updatedAt: DateTime(2026, 1, sortOrder),
  );
}

class _FakeBox implements Box<dynamic> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

/// Records every [DeviationNotifier.checkDeviations] invocation so tests can
/// assert whether the hidden second LLM call fired.
class _RecordingDeviationNotifier extends DeviationNotifier {
  final List<String> checkedTexts = [];

  @override
  Future<DeviationResult> build() async => const DeviationResult(warnings: []);

  @override
  Future<void> checkDeviations(String text) async {
    checkedTexts.add(text);
  }
}

/// Static override for [autoDeviationCheckProvider] to force the opt-in state
/// deterministically in tests.
class _StaticAutoDeviationCheck extends AutoDeviationCheckNotifier {
  _StaticAutoDeviationCheck(this.value);

  final bool value;

  @override
  bool build() => value;
}
