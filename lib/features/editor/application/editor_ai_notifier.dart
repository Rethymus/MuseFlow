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
import 'package:museflow/features/editor/application/diff_calculator.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/diff_state.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/editor/infrastructure/provenance_attribution.dart';
import 'package:super_editor/super_editor.dart';

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

    // D-15: Inject active anchors into the prompt context
    final activeAnchors = ref.read(contextAnchorNotifierProvider);

    final context = PromptContext(
      fragments: [],
      selectedText: selectedText,
      selectedOperation: operation,
      userInstruction: userInstruction,
      bannedPhrases: bannedPhrases,
      anchors: activeAnchors.isNotEmpty ? activeAnchors : null,
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
        temperature: provider.temperature,
        topP: provider.topP,
        maxTokens: provider.maxTokens,
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

  /// Runs anti-AI-scent post-processing on accumulated text,
  /// then calculates the sentence-level diff result.
  Future<void> _postProcess() async {
    final processor = ref.read(antiAIScentProcessorProvider);
    final bannedPhrases = await _getBannedPhrases();

    final result = processor.process(
      state.progressText ?? '',
      bannedPhrases: bannedPhrases,
    );

    // Calculate sentence-level diff between original and AI text
    final diffResult = DiffCalculator.calculate(
      state.selectedText,
      result.processedText,
      state.selectionNodeId,
      state.selectionStartOffset,
    );

    state = state.copyWith(
      progressText: result.processedText,
      isStreaming: false,
      diffResult: diffResult,
    );

    // D-12: Clear one-time anchors after AI operation completes
    ref.read(contextAnchorNotifierProvider.notifier).clearOneTime();
  }

  /// Accepts a single sentence diff at [index].
  ///
  /// For modifications: deletes original range and inserts AI text with
  /// provenance attribution (D-10).
  /// For deletions: deletes the original range.
  /// For insertions: inserts AI text with provenance.
  ///
  /// Per Pitfall 5: batches delete+insert in a single editor.execute() call
  /// to create one undo entry.
  void acceptSentence(int index) {
    final currentDiff = state.diffResult;
    if (currentDiff == null || index >= currentDiff.sentences.length) return;

    final sentence = currentDiff.sentences[index];
    if (sentence.status != DiffStatus.pending) return;

    final editor = ref.read(editorProvider);
    if (editor == null) return;

    final range = DocumentRange(
      start: DocumentPosition(
        nodeId: sentence.nodeId,
        nodePosition: TextNodePosition(offset: sentence.startOffset),
      ),
      end: DocumentPosition(
        nodeId: sentence.nodeId,
        nodePosition: TextNodePosition(offset: sentence.endOffset),
      ),
    );

    // EDIT-06: Record in selective undo stack before applying
    final undoService = ref.read(selectiveUndoServiceProvider);
    if (sentence.isModification || sentence.isDeletion) {
      undoService.record(
        originalText: sentence.originalText!,
        replacementText: sentence.newText ?? '',
        nodeId: sentence.nodeId,
        startOffset: sentence.startOffset,
        endOffset: sentence.endOffset,
      );
    }

    if (sentence.isModification) {
      // Pitfall 5: batch delete+insert in single execute for one undo entry
      editor.execute([
        DeleteContentRequest(documentRange: range),
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: sentence.nodeId,
            nodePosition: TextNodePosition(offset: sentence.startOffset),
          ),
          textToInsert: sentence.newText!,
          attributions: {aiProvenanceAttribution},
        ),
      ]);
    } else if (sentence.isDeletion) {
      editor.execute([DeleteContentRequest(documentRange: range)]);
    } else if (sentence.isInsertion) {
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: sentence.nodeId,
            nodePosition: TextNodePosition(offset: sentence.startOffset),
          ),
          textToInsert: sentence.newText!,
          attributions: {aiProvenanceAttribution},
        ),
      ]);
    }

    // Update sentence status to accepted
    _updateSentenceStatus(index, DiffStatus.accepted);
  }

  /// Rejects a single sentence diff at [index].
  ///
  /// For modifications: keeps original text (no document change).
  /// For insertions: deletes the inserted range.
  /// For deletions: re-inserts the original text.
  void rejectSentence(int index) {
    final currentDiff = state.diffResult;
    if (currentDiff == null || index >= currentDiff.sentences.length) return;

    final sentence = currentDiff.sentences[index];
    if (sentence.status != DiffStatus.pending) return;

    final editor = ref.read(editorProvider);
    if (editor == null) return;

    if (sentence.isInsertion) {
      // Delete the inserted range
      final range = DocumentRange(
        start: DocumentPosition(
          nodeId: sentence.nodeId,
          nodePosition: TextNodePosition(offset: sentence.startOffset),
        ),
        end: DocumentPosition(
          nodeId: sentence.nodeId,
          nodePosition: TextNodePosition(offset: sentence.endOffset),
        ),
      );
      editor.execute([DeleteContentRequest(documentRange: range)]);
    } else if (sentence.isDeletion) {
      // Re-insert the original text
      editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: sentence.nodeId,
            nodePosition: TextNodePosition(offset: sentence.startOffset),
          ),
          textToInsert: sentence.originalText!,
          attributions: {},
        ),
      ]);
    }
    // For modifications: keep original -- no document change needed

    // Update sentence status to rejected
    _updateSentenceStatus(index, DiffStatus.rejected);
  }

  /// Accepts all pending sentences.
  void acceptAll() {
    final currentDiff = state.diffResult;
    if (currentDiff == null) return;
    for (var i = 0; i < currentDiff.sentences.length; i++) {
      if (currentDiff.sentences[i].status == DiffStatus.pending) {
        acceptSentence(i);
      }
    }
  }

  /// Rejects all pending sentences.
  void rejectAll() {
    final currentDiff = state.diffResult;
    if (currentDiff == null) return;
    for (var i = 0; i < currentDiff.sentences.length; i++) {
      if (currentDiff.sentences[i].status == DiffStatus.pending) {
        rejectSentence(i);
      }
    }
  }

  /// Undoes the last AI modification using the selective undo stack.
  ///
  /// Per EDIT-06: This is separate from Ctrl+Z (which undoes human edits).
  /// Restores the original text without provenance attribution.
  void undoLastAIChange() {
    final undoService = ref.read(selectiveUndoServiceProvider);
    final entry = undoService.popLast();
    if (entry == null) return;

    final editor = ref.read(editorProvider);
    if (editor == null) return;

    final range = DocumentRange(
      start: DocumentPosition(
        nodeId: entry.nodeId,
        nodePosition: TextNodePosition(offset: entry.startOffset),
      ),
      end: DocumentPosition(
        nodeId: entry.nodeId,
        nodePosition: TextNodePosition(offset: entry.endOffset),
      ),
    );

    // Delete the AI replacement and re-insert original text
    // WITHOUT provenance attribution (restoring human text)
    editor.execute([
      DeleteContentRequest(documentRange: range),
      InsertTextRequest(
        documentPosition: DocumentPosition(
          nodeId: entry.nodeId,
          nodePosition: TextNodePosition(offset: entry.startOffset),
        ),
        textToInsert: entry.originalText,
        attributions: {},
      ),
    ]);
  }

  /// Updates the status of a single sentence in the diff result.
  void _updateSentenceStatus(int index, DiffStatus newStatus) {
    final currentDiff = state.diffResult;
    if (currentDiff == null) return;

    final updatedSentences = List<SentenceDiff>.from(currentDiff.sentences);
    updatedSentences[index] = updatedSentences[index].copyWith(status: newStatus);

    state = state.copyWith(
      diffResult: DiffResult(
        sentences: updatedSentences,
        nodeId: currentDiff.nodeId,
      ),
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
