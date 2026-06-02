/// Editor AI notifier for streaming state management.
///
/// Manages the editor AI operation flow:
/// 1. Validate provider + API key
/// 2. Build prompt via EditorPromptPipeline
/// 3. Stream tokens from OpenAIAdapter
/// 4. Accumulate tokens in progressText
/// 5. Post-process with AntiAIScentProcessor
/// 6. Support cancel during streaming
///
/// Follows the same pattern as [SynthesisNotifier] for consistency.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/presentation/banned_phrase_settings.dart';
import 'package:museflow/features/ai/presentation/synthesis_notifier.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';

/// Notifier managing editor AI operations with streaming state.
///
/// State transitions:
/// - idle -> streaming (startOperation)
/// - streaming -> idle with progressText (stream complete)
/// - streaming -> idle with error (stream error)
/// - streaming -> idle (cancel)
/// - any -> idle (reset)
class EditorAINotifier extends Notifier<EditorAIState> {
  bool _cancelled = false;

  @override
  EditorAIState build() => const EditorAIState();

  /// Starts an AI operation on the selected text.
  ///
  /// Parameters:
  /// - [operation]: The type of AI operation (tone/polish/free-input)
  /// - [selectedText]: The text selected in the editor
  /// - [selectionNodeId]: The document node ID containing the selection
  /// - [selectionStartOffset]: Start offset within the node
  /// - [selectionEndOffset]: End offset within the node
  /// - [userInstruction]: Custom instruction for free-input operations
  void startOperation(
    EditorAIOperation operation,
    String selectedText,
    String selectionNodeId,
    int selectionStartOffset,
    int selectionEndOffset, {
    String? userInstruction,
  }) {
    // Reset cancel flag
    _cancelled = false;

    // Set state to streaming
    state = EditorAIState(
      isStreaming: true,
      operation: operation,
      selectedText: selectedText,
      selectionNodeId: selectionNodeId,
      selectionStartOffset: selectionStartOffset,
      selectionEndOffset: selectionEndOffset,
      userInstruction: userInstruction,
    );

    // Validate provider
    final provider = ref.read(activeProviderProvider);
    if (provider == null) {
      state = state.copyWith(
        isStreaming: false,
        error: '未配置 AI 模型，请在设置中添加',
      );
      return;
    }

    // Kick off async streaming
    _fetchKeyAndStream(provider, operation, selectedText, userInstruction);
  }

  /// Cancels the current streaming operation.
  void cancel() {
    _cancelled = true;
    state = state.copyWith(isStreaming: false);
  }

  /// Resets state to idle.
  void reset() {
    _cancelled = false;
    state = const EditorAIState();
  }

  Future<void> _fetchKeyAndStream(
    AIProvider provider,
    EditorAIOperation operation,
    String selectedText,
    String? userInstruction,
  ) async {
    // Get API key
    final apiKey = ref.read(activeApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(
        isStreaming: false,
        error: 'API Key 无效，请检查设置',
      );
      return;
    }

    // Build prompt via editor pipeline
    final pipeline = EditorPromptPipeline();
    final bannedPhrases = await _getBannedPhrases();

    final context = PromptContext(
      fragments: [],
      selectedText: selectedText,
      selectedOperation: operation,
      userInstruction: userInstruction,
      bannedPhrases: bannedPhrases,
    );
    final messages = pipeline.build(context);

    // Start streaming
    final adapter = ref.read(openaiAdapterProvider);
    try {
      final stream = adapter.createStream(
        apiKey: apiKey,
        baseUrl: provider.baseUrl,
        model: provider.model,
        messages: messages,
      );

      await for (final token in stream) {
        if (_cancelled) return;
        state = state.copyWith(
          progressText: (state.progressText ?? '') + token,
        );
      }

      // Stream complete -- run anti-AI-scent processing
      if (!_cancelled) {
        await _postProcess();
      }
    } on AIException catch (e) {
      if (!_cancelled) {
        _handleStreamError(e);
      }
    } catch (e) {
      if (!_cancelled) {
        state = state.copyWith(
          isStreaming: false,
          error: '生成中断，请重试',
        );
      }
    }
  }

  /// Runs anti-AI-scent post-processing on accumulated text.
  Future<void> _postProcess() async {
    final processor = ref.read(antiAIScentProcessorProvider);
    final bannedPhrases = await _getBannedPhrases();

    final result = processor.process(
      state.progressText ?? '',
      bannedPhrases: bannedPhrases,
    );

    state = state.copyWith(
      progressText: result.processedText,
      isStreaming: false,
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
      errorMessage = '生成中断，请重试';
    }

    state = state.copyWith(
      isStreaming: false,
      error: errorMessage,
    );
  }

  /// Gets banned phrases from settings, or returns empty list.
  Future<List<String>> _getBannedPhrases() async {
    final phrasesAsync = ref.read(bannedPhrasesProvider);
    return phrasesAsync.asData?.value ?? [];
  }
}

/// Provider for the editor AI notifier.
final editorAINotifierProvider =
    NotifierProvider<EditorAINotifier, EditorAIState>(
  EditorAINotifier.new,
);
