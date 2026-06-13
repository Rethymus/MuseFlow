/// Synthesis state management and streaming logic.
///
/// Manages the full fragment-to-paragraph synthesis flow:
/// 1. Read selected fragments from CaptureNotifier
/// 2. Get active AI provider and API key
/// 3. Calculate token budget and trim fragments (LIFO per D-13)
/// 4. Build prompt via PromptPipeline
/// 5. Stream tokens from OpenAIAdapter
/// 6. Post-process with AntiAIScentProcessor
/// 7. Allow editing, regeneration, and editor insertion
///
/// Per CAPT-03: Streaming response with typewriter effect.
/// Per D-14: Inline error messages (not dialogs/SnackBar).
/// Per D-15: Partial content preserved on stream interruption.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/presentation/banned_phrase_settings.dart';
import 'package:museflow/features/capture/presentation/capture_provider.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/editor/application/style_profile_notifier.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:super_editor/super_editor.dart';

/// Immutable state for the synthesis flow.
class SynthesisState {
  /// Accumulated text from streaming + post-processing.
  final String accumulatedText;

  /// Whether streaming is in progress.
  final bool isStreaming;

  /// Whether the user can edit the synthesized text.
  final bool isEditing;

  /// Inline error message per D-14. Null when no error.
  final String? error;

  /// Notice when fragments were trimmed due to token budget per D-13.
  final String? excludedFragmentsNotice;

  /// Highlights from anti-AI-scent processing per AI-06.
  final List<TextHighlight> highlights;

  /// Optional additional instruction for regeneration per D-06.
  final String? additionalInstruction;

  /// Current retry attempt count (0 = no retry yet).
  final int retryCount;

  /// Maximum retry attempts for transient errors.
  static const maxRetries = 3;

  const SynthesisState({
    this.accumulatedText = '',
    this.isStreaming = false,
    this.isEditing = false,
    this.error,
    this.excludedFragmentsNotice,
    this.highlights = const [],
    this.additionalInstruction,
    this.retryCount = 0,
  });

  /// Creates a copy with the given fields replaced.
  SynthesisState copyWith({
    String? accumulatedText,
    bool? isStreaming,
    bool? isEditing,
    String? error,
    String? excludedFragmentsNotice,
    List<TextHighlight>? highlights,
    String? additionalInstruction,
    int? retryCount,
  }) {
    return SynthesisState(
      accumulatedText: accumulatedText ?? this.accumulatedText,
      isStreaming: isStreaming ?? this.isStreaming,
      isEditing: isEditing ?? this.isEditing,
      error: error,
      excludedFragmentsNotice: excludedFragmentsNotice,
      highlights: highlights ?? this.highlights,
      additionalInstruction:
          additionalInstruction ?? this.additionalInstruction,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Notifier managing the synthesis state machine.
///
/// State transitions:
/// - idle -> streaming (startSynthesis)
/// - streaming -> editing (stream complete + anti-AI-scent)
/// - streaming -> editing+error (stream error per D-15)
/// - editing -> streaming (regenerate per D-06)
/// - editing -> idle (confirmAndInsert per D-07)
class SynthesisNotifier extends Notifier<SynthesisState> {
  @override
  SynthesisState build() => const SynthesisState();

  /// Starts a new synthesis from selected fragments.
  ///
  /// Flow: validate -> budget -> prompt -> stream -> post-process
  void startSynthesis() {
    _runSynthesis(null);
  }

  /// Regenerates synthesis with optional additional instruction per D-06.
  void regenerate(String? instruction) {
    _runSynthesis(instruction);
  }

  /// Sets an inline error message per D-14.
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Resets state to idle.
  void reset() {
    state = const SynthesisState();
  }

  /// Updates the accumulated text (user edits in the panel per CAPT-04).
  void updateText(String text) {
    state = state.copyWith(accumulatedText: text);
  }

  /// Inserts the accumulated text into the editor at cursor per D-07.
  void confirmAndInsert() {
    if (state.accumulatedText.isEmpty) return;

    final textToInsert = state.accumulatedText;
    final editor = ref.read(editorProvider);
    if (editor != null) {
      editor.execute([InsertPlainTextAtCaretRequest(textToInsert)]);
      ref.read(writingStatsCollectorProvider.future).then((collector) {
        collector.recordAiInsertion(textToInsert);
      });
    }

    // Reset state after insertion
    state = const SynthesisState();
  }

  void _runSynthesis(String? additionalInstruction) {
    // Reset state to streaming
    state = SynthesisState(
      isStreaming: true,
      additionalInstruction: additionalInstruction,
    );

    // Get selected fragments
    final fragments = ref.read(selectedFragmentsProvider);
    if (fragments.isEmpty) {
      state = state.copyWith(isStreaming: false, error: '请先选择至少一个碎片');
      return;
    }

    // Get active provider
    final provider = ref.read(activeProviderProvider);
    if (provider == null) {
      state = state.copyWith(isStreaming: false, error: '未配置 AI 模型，请在设置中添加');
      return;
    }

    // Kick off async streaming
    _fetchKeyAndStream(provider, fragments, additionalInstruction);
  }

  Future<void> _fetchKeyAndStream(
    AIProvider provider,
    List<Fragment> fragments,
    String? additionalInstruction,
  ) async {
    // Get API key (synchronous read -- activeApiKeyProvider wraps the async fetch)
    final apiKey = ref.read(activeApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(isStreaming: false, error: 'API Key 无效，请检查设置');
      return;
    }

    // Token budget calculation per D-13
    final budgetCalculator = ref.read(tokenBudgetCalculatorProvider);
    final budgetResult = budgetCalculator.selectFragmentsWithinBudget(
      fragments,
      3000, // Conservative budget for fragment content
    );

    String? excludedNotice;
    if (budgetResult.excludedCount > 0) {
      excludedNotice = '已移除 ${budgetResult.excludedCount} 个碎片以保证质量';
    }

    state = state.copyWith(excludedFragmentsNotice: excludedNotice);

    // Build prompt via pipeline
    final pipeline = await ref.read(promptPipelineProvider.future);
    if (!ref.mounted) return;
    final bannedPhrases = await _getBannedPhrases();
    if (!ref.mounted) return;

    final context = PromptContext(
      fragments: budgetResult.included,
      additionalInstruction: additionalInstruction,
      bannedPhrases: bannedPhrases,
      styleProfile: ref.read(styleProfileNotifierProvider).profile,
    );
    final messages = pipeline.build(context);

    // Capture input text for audit (approximate from fragments)
    final inputText = budgetResult.included.map((f) => f.text).join('\n');

    // Get audit service
    final auditService = await ref.read(tokenAuditServiceProvider.future);

    // Resolve manuscript context from loaded chapters, if available.
    // Synthesis runs in the capture tab where manuscript context may not exist,
    // so we gracefully fall back to empty string when no chapter is loaded.
    final chapters = ref.read(chapterNotifierProvider);
    final manuscriptId =
        chapters.asData?.value.firstOrNull?.manuscriptId ?? '';

    // Start streaming with adapter routed by active provider type
    final adapter = ref.read(activeAdapterProvider);
    int retryAttempt = 0;

    while (retryAttempt <= SynthesisState.maxRetries) {
      try {
        // Clear partial text on retry for clean stream restart
        if (retryAttempt > 0) {
          state = state.copyWith(
            accumulatedText: '',
            error: null,
          );
        }

        final stream = adapter.createStream(
          apiKey: apiKey,
          baseUrl: provider.baseUrl,
          model: provider.model,
          messages: messages,
          temperature: provider.temperature,
          topP: provider.topP,
          maxTokens: provider.maxTokens,
          onUsage: (usage) {
            // Record audit after stream completes successfully
            auditService.recordAudit(
              usage: usage,
              modelName: provider.model,
              operationType: AuditOperationType.synthesis,
              manuscriptId: manuscriptId,
              chapterId: null,
              inputText: inputText,
              outputText: state.accumulatedText,
            );
          },
        );

        await for (final token in stream) {
          if (!ref.mounted) return;
          state = state.copyWith(
            accumulatedText: state.accumulatedText + token,
            retryCount: retryAttempt,
          );
        }

        // Stream complete -- run anti-AI-scent processing
        if (!ref.mounted) return;
        await _postProcess();
        return; // Success — exit retry loop
      } on AIException catch (e) {
        if (!ref.mounted) return;

        // Auth errors are permanent — don't retry
        if (e is AIAuthException || retryAttempt >= SynthesisState.maxRetries) {
          _handleStreamError(e);
          return;
        }

        // Transient error — retry with exponential backoff
        retryAttempt++;
        state = state.copyWith(
          retryCount: retryAttempt,
          accumulatedText: '',
          error: null,
        );

        final backoffSeconds = 2 * (1 << (retryAttempt - 1)); // 2s, 4s, 8s
        await Future.delayed(Duration(seconds: backoffSeconds));
        if (!ref.mounted) return;
      } catch (e) {
        if (!ref.mounted) return;
        state = state.copyWith(
          isStreaming: false,
          isEditing: true,
          error: '生成中断，可继续编辑或重试',
        );
        return;
      }
    }
  }

  /// Runs anti-AI-scent post-processing on accumulated text.
  /// Per CR-02 fix: uses user-configured banned phrases, not hardcoded empty list.
  Future<void> _postProcess() async {
    final processor = ref.read(antiAIScentProcessorProvider);
    final bannedPhrases = await _getBannedPhrases();
    if (!ref.mounted) return;

    final result = processor.process(
      state.accumulatedText,
      bannedPhrases: bannedPhrases,
    );

    state = state.copyWith(
      accumulatedText: result.processedText,
      highlights: result.highlights,
      isStreaming: false,
      isEditing: true,
    );
  }

  /// Handles stream errors with Chinese messages per D-14.
  void _handleStreamError(AIException e) {
    String errorMessage;
    if (e is AIAuthException) {
      errorMessage = 'API Key 无效，请检查设置';
    } else if (e is AIRateLimitException) {
      errorMessage = '请求太快，请稍后再试';
    } else if (e is AINetworkException) {
      errorMessage = '网络连接失败，请检查网络';
    } else {
      errorMessage = '生成中断，可继续编辑或重试';
    }

    state = state.copyWith(
      isStreaming: false,
      isEditing: true,
      error: errorMessage,
    );
  }

  /// Gets banned phrases from settings, or returns empty list.
  Future<List<String>> _getBannedPhrases() async {
    final phrasesAsync = ref.read(bannedPhrasesProvider);
    return phrasesAsync.asData?.value ?? [];
  }
}

/// Provider for the synthesis notifier.
final synthesisProvider = NotifierProvider<SynthesisNotifier, SynthesisState>(
  SynthesisNotifier.new,
);
