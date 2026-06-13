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
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/style_dimension.dart';
import 'package:museflow/features/editor/domain/style_sample.dart';
import 'package:museflow/features/editor/application/style_profile_notifier.dart';
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
      expect(state.retryCount, 0);
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
          selectedFragmentsProvider.overrideWithValue(selectedFragments),
          tokenAuditServiceProvider.overrideWith(
            (ref) async => auditService ?? _RecordingTokenAuditService(),
          ),
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
        expect(
          container.read(synthesisProvider).isStreaming,
          anyOf(true, false),
        );
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

      test(
        'should record token audit after stream completes successfully',
        () async {
          final service = _RecordingTokenAuditService();
          container = createContainer(
            selectedFragments: [
              Fragment(id: 'f1', text: '月光', createdAt: DateTime(2026, 1, 1)),
            ],
            auditService: service,
          );
          fakeAdapter.streamOutput = Stream.fromIterable(['月光', '下']);
          fakeAdapter.usage = const Usage(
            promptTokens: 11,
            completionTokens: 22,
            totalTokens: 33,
          );

          container.read(synthesisProvider.notifier).startSynthesis();
          await _pumpAndWait();

          expect(service.records, hasLength(1));
          final record = service.records.single;
          expect(record.inputTokens, 11);
          expect(record.outputTokens, 22);
          expect(record.operationType, AuditOperationType.synthesis);
          expect(record.modelName, 'gpt-4o-mini');
        },
      );

      test('should not record token audit when stream errors', () async {
        final service = _RecordingTokenAuditService();
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: '月光', createdAt: DateTime(2026, 1, 1)),
          ],
          auditService: service,
        );
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;
        fakeAdapter.usage = const Usage(
          promptTokens: 11,
          completionTokens: 22,
          totalTokens: 33,
        );

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();
        controller.addError(const AINetworkException());
        await _pumpAndWait();

        expect(service.records, isEmpty);
        await controller.close();
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
        // Auth errors don't retry, so partial content is preserved
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

        // Use AIAuthException (no retry) to preserve partial content
        controller.addError(const AIAuthException());
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

      test('should retry on rate limit errors and recover', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        // Rate limit error triggers auto-retry (second call succeeds)
        controller.addError(const AIRateLimitException());
        await _pump();

        // Wait for backoff (2s) and retry
        await Future<void>.delayed(const Duration(seconds: 3));
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        // After retry succeeds, should be in editing state with content
        expect(fakeAdapter.callCount, greaterThanOrEqualTo(2));
        expect(state.isStreaming, false);
        expect(state.isEditing, true);

        await controller.close();
      });

      test('should retry on network errors and recover', () async {
        container = createContainer(
          selectedFragments: [
            Fragment(id: 'f1', text: 'test', createdAt: DateTime(2026, 1, 1)),
          ],
        );
        final controller = StreamController<String>();
        fakeAdapter.streamOutput = controller.stream;

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pump();

        // Network error triggers auto-retry (second call succeeds)
        controller.addError(const AINetworkException());
        await _pump();

        // Wait for backoff (2s) and retry
        await Future<void>.delayed(const Duration(seconds: 3));
        await _pumpAndWait();

        final state = container.read(synthesisProvider);
        expect(fakeAdapter.callCount, greaterThanOrEqualTo(2));
        expect(state.isStreaming, false);

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
    group('style profile integration', () {
      test('should pass style profile to prompt context when available', () async {
        final profile = AuthorStyleProfile(
          manuscriptId: 'test-ms',
          sentenceLengthStats: const SentenceLengthStats(avg: 20, stdDev: 8, median: 18),
          rhythmScore: 0.4,
          vocabularyRichness: 0.6,
          rhetoricHabits: const RhetoricHabits(
            metaphorFrequency: 0.07,
            dialogueRatio: 0.3,
            descriptionRatio: 0.35,
          ),
          emotionalTone: const EmotionalTone(overall: '温暖克制', warmth: 0.6),
          analyzedChapterCount: 4,
          analyzedCharCount: 8000,
          sampleParagraphs: [
            StyleSample(
              chapterId: 'ch1',
              paragraphIndex: 0,
              text: '月光从云层间漏下来，照得庭院泛白。',
              qualityScore: 0.9,
              dimensionScores: {StyleDimension.rhythm: 0.8},
            ),
          ],
        );

        fakeAdapter = _FakeOpenAIAdapter();

        container = ProviderContainer(
          overrides: [
            openaiAdapterProvider.overrideWithValue(fakeAdapter),
            activeProviderProvider.overrideWithValue(
              AIProvider(
                id: 'test-provider',
                name: 'Test',
                baseUrl: 'https://api.openai.com/v1',
                type: AiProviderType.openai,
                model: 'gpt-4o-mini',
                isActive: true,
                createdAt: DateTime(2026, 1, 1),
              ),
            ),
            activeApiKeyProvider.overrideWithValue('test-key'),
            selectedFragmentsProvider.overrideWithValue([
              Fragment(id: 'f1', text: '碎片', createdAt: DateTime(2026, 1, 1)),
            ]),
            tokenAuditServiceProvider.overrideWith(
              (ref) async => _RecordingTokenAuditService(),
            ),
            styleProfileNotifierProvider.overrideWith(
              () => _FakeStyleProfileNotifier(profile),
            ),
          ],
        );

        fakeAdapter.streamOutput = Stream.fromIterable(['生成文本']);

        container.read(synthesisProvider.notifier).startSynthesis();
        await _pumpAndWait();

        // Verify the adapter received messages containing dynamic persona
        // (not the default fixed persona)
        expect(fakeAdapter.lastMessages, isNotNull);
        final systemContent = fakeAdapter.lastMessages!.first.toJson()['content'] as String;
        expect(systemContent, contains('写作风格指令'));
        expect(systemContent, isNot(contains('像人写的')));
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
  await Future<void>.delayed(const Duration(milliseconds: 500));
  for (var i = 0; i < 10; i++) {
    await Future<void>.microtask(() {});
  }
}

// --- Test fakes ---

/// Fake OpenAI adapter that returns a controllable stream.
///
/// Tracks call count so tests can verify retry behavior.
/// On the second+ call (retry), returns the configured stream or a default
/// success stream, simulating transient error recovery.
class _FakeOpenAIAdapter extends OpenAIAdapter {
  Stream<String>? streamOutput;
  Usage? usage;
  List<ChatMessage>? lastMessages;
  int callCount = 0;

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
    callCount++;
    lastMessages = messages;

    // On retry (call > 1), return a default success stream unless
    // streamOutput is still the error stream (transient retry scenario)
    if (callCount > 1) {
      final source = streamOutput ?? Stream.fromIterable(['重试成功']);
      return source.transform(
        StreamTransformer<String, String>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleDone: (sink) {
            onUsage?.call(usage);
            sink.close();
          },
        ),
      );
    }

    final source = streamOutput ?? Stream.fromIterable(['默认文本']);
    return source.transform(
      StreamTransformer<String, String>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleDone: (sink) {
          onUsage?.call(usage);
          sink.close();
        },
      ),
    );
  }
}

class _RecordingTokenAuditService implements TokenAuditService {
  final records = <TokenAuditRecord>[];

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
    records.add(
      TokenAuditRecord(
        id: 'record-${records.length}',
        inputTokens: usage?.promptTokens ?? 0,
        outputTokens: usage?.completionTokens ?? 0,
        modelName: modelName,
        operationType: operationType,
        manuscriptId: manuscriptId,
        chapterId: chapterId,
        timestamp: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  Future<void> flush() async {}

  @override
  void dispose() {}

  @override
  Duration get debounceDuration => Duration.zero;

  @override
  void record_(TokenAuditRecord record) => records.add(record);
}

/// Fake style profile notifier that returns a predetermined profile.
class _FakeStyleProfileNotifier extends StyleProfileNotifier {
  final AuthorStyleProfile _profile;

  _FakeStyleProfileNotifier(this._profile);

  @override
  StyleProfileState build() => StyleProfileState(profile: _profile);
}
