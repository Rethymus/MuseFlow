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

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/presentation/banned_phrase_settings.dart';
import 'package:museflow/features/editor/application/diff_calculator.dart';
import 'package:museflow/features/editor/application/editor_chapter_memory_context_builder.dart';
import 'package:museflow/features/editor/application/intent_preservation_analyzer.dart';
import 'package:museflow/features/editor/application/style_deviation_notifier.dart';
import 'package:museflow/features/editor/application/style_profile_notifier.dart';
import 'package:museflow/features/editor/domain/diff_state.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/editor/infrastructure/provenance_attribution.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:openai_dart/openai_dart.dart';
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
  /// - [manuscriptId]: Optional manuscript ID for audit tracking
  /// - [chapterId]: Optional chapter ID for audit tracking
  void startOperation(
    EditorAIOperation operation,
    String selectedText,
    String selectionNodeId,
    int selectionStartOffset,
    int selectionEndOffset, {
    String? userInstruction,
    String? manuscriptId,
    String? chapterId,
  }) {
    // Reset cancel flag
    _cancelled = false;

    // Set state to streaming (preserve conversation history)
    state = EditorAIState(
      isStreaming: true,
      operation: operation,
      selectedText: selectedText,
      selectionNodeId: selectionNodeId,
      selectionStartOffset: selectionStartOffset,
      selectionEndOffset: selectionEndOffset,
      userInstruction: userInstruction,
      conversationHistory: state.conversationHistory,
    );

    // Validate provider
    final provider = ref.read(activeProviderProvider);
    if (provider == null) {
      state = state.copyWith(isStreaming: false, error: '未配置 AI 模型，请在设置中添加');
      return;
    }

    // Kick off async streaming
    _fetchKeyAndStream(
      provider,
      operation,
      selectedText,
      userInstruction,
      manuscriptId,
      chapterId,
    );
  }

  /// Cancels the current streaming operation.
  void cancel() {
    _cancelled = true;
    state = state.copyWith(isStreaming: false);
  }

  /// Resets state to idle and clears conversation history.
  void reset() {
    _cancelled = false;
    state = const EditorAIState();
  }

  Future<void> _fetchKeyAndStream(
    AIProvider provider,
    EditorAIOperation operation,
    String selectedText,
    String? userInstruction,
    String? manuscriptId,
    String? chapterId,
  ) async {
    // Get API key
    final apiKey = ref.read(activeApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(isStreaming: false, error: 'API Key 无效，请检查设置');
      return;
    }

    // Build prompt via editor pipeline
    final pipeline = await ref.read(editorPromptPipelineProvider.future);
    final bannedPhrases = await _getBannedPhrases();

    // D-15: Inject active anchors into the prompt context
    final activeAnchors = ref.read(contextAnchorNotifierProvider);
    final chapterMemory = await _buildChapterMemoryContext(
      manuscriptId: manuscriptId,
      chapterId: chapterId,
    );

    final context = PromptContext(
      fragments: [],
      selectedText: selectedText,
      selectedOperation: operation,
      userInstruction: userInstruction,
      bannedPhrases: bannedPhrases,
      anchors: activeAnchors.isNotEmpty ? activeAnchors : null,
      previousChapterSummary: chapterMemory.previousChapterSummary,
      nextChapterSummary: chapterMemory.nextChapterSummary,
      previousChapterMemoryWarning: chapterMemory.previousChapterMemoryWarning,
      nextChapterMemoryWarning: chapterMemory.nextChapterMemoryWarning,
      chapterContextChain: chapterMemory.chapterContextChain,
      styleProfile: ref.read(styleProfileNotifierProvider).profile,
    );
    var messages = pipeline.build(context);

    // Inject multi-turn conversation history if available
    final history = state.conversationHistory;
    if (history.isNotEmpty) {
      messages = _injectConversationHistory(messages, history);
    }

    // Capture input text for audit (use selected text)
    final inputText = selectedText;

    // Get audit service
    final auditService = await ref.read(tokenAuditServiceProvider.future);

    // Map operation to audit operation type
    final auditOperationType = switch (operation) {
      EditorAIOperation.toneRewrite => AuditOperationType.rewrite,
      EditorAIOperation.paragraphPolish => AuditOperationType.polish,
      EditorAIOperation.freeInput => AuditOperationType.freeInput,
      EditorAIOperation.expand => AuditOperationType.expand,
      EditorAIOperation.compress => AuditOperationType.compress,
      EditorAIOperation.dialogue => AuditOperationType.dialogue,
      EditorAIOperation.scene => AuditOperationType.scene,
    };

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
        onUsage: (usage) {
          // Record audit after stream completes successfully
          auditService.recordAudit(
            usage: usage,
            modelName: provider.model,
            operationType: auditOperationType,
            manuscriptId: manuscriptId ?? '',
            chapterId: chapterId,
            inputText: inputText,
            outputText: state.progressText ?? '',
          );
        },
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
        state = state.copyWith(isStreaming: false, error: '生成中断，请重试');
      }
    }
  }

  Future<EditorChapterMemoryContext> _buildChapterMemoryContext({
    required String? manuscriptId,
    required String? chapterId,
  }) async {
    if (manuscriptId == null ||
        manuscriptId.trim().isEmpty ||
        chapterId == null ||
        chapterId.trim().isEmpty) {
      return const EditorChapterMemoryContext();
    }

    try {
      final builder = await ref.read(
        editorChapterMemoryContextBuilderProvider.future,
      );
      return builder.build(manuscriptId: manuscriptId, chapterId: chapterId);
    } catch (_) {
      return const EditorChapterMemoryContext();
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
    final intentSignals = const IntentPreservationAnalyzer().analyze(
      originalText: state.selectedText,
      aiText: result.processedText,
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
      reviewSignals: [...result.reviewSignals, ...intentSignals],
    );

    // Save conversation turn for multi-turn refinement
    final currentOp = state.operation;
    if (currentOp != null) {
      _saveConversationTurn(currentOp, result.processedText);
    }

    // D-12: Clear one-time anchors after AI operation completes
    ref.read(contextAnchorNotifierProvider.notifier).clearOneTime();

    // Phase 4: advisory consistency warnings for active skill constraints.
    unawaited(
      ref
          .read(deviationNotifierProvider.notifier)
          .checkDeviations(result.processedText)
          .catchError((_) {}),
    );

    // Phase 19: analyze AI output against author style profile for thermometer.
    ref.read(styleDeviationNotifierProvider.notifier).analyzeText(
      result.processedText,
    );
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
  /// AI output is only previewed until accepted, so rejecting a pending diff
  /// never mutates the document. It simply marks the sentence as rejected.
  void rejectSentence(int index) {
    final currentDiff = state.diffResult;
    if (currentDiff == null || index >= currentDiff.sentences.length) return;

    final sentence = currentDiff.sentences[index];
    if (sentence.status != DiffStatus.pending) return;

    // Update sentence status to rejected
    _updateSentenceStatus(index, DiffStatus.rejected);
  }

  /// Accepts all pending sentences.
  void acceptAll() {
    final currentDiff = state.diffResult;
    if (currentDiff == null) return;
    for (var i = currentDiff.sentences.length - 1; i >= 0; i--) {
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
    updatedSentences[index] = updatedSentences[index].copyWith(
      status: newStatus,
    );

    state = state.copyWith(
      diffResult: DiffResult(
        sentences: updatedSentences,
        nodeId: currentDiff.nodeId,
      ),
    );
  }

  /// Saves the current operation as a conversation turn for multi-turn context.
  void _saveConversationTurn(EditorAIOperation operation, String aiResponse) {
    final instruction = state.userInstruction ?? operation.label;
    final turn = ConversationTurn(
      userInstruction: instruction,
      aiResponse: aiResponse,
      operation: operation,
    );

    final updatedHistory = [
      ...state.conversationHistory,
      turn,
    ];

    // Trim to max conversation turns for token budget
    final trimmedHistory = updatedHistory.length > EditorAIState.maxConversationTurns
        ? updatedHistory.sublist(
            updatedHistory.length - EditorAIState.maxConversationTurns,
          )
        : updatedHistory;

    state = state.copyWith(conversationHistory: trimmedHistory);
  }

  /// Injects multi-turn conversation history into the message list.
  ///
  /// History messages are inserted after the system message and before
  /// the current user message, giving the AI context of the refinement chain.
  List<ChatMessage> _injectConversationHistory(
    List<ChatMessage> messages,
    List<ConversationTurn> history,
  ) {
    if (messages.isEmpty) return messages;

    final systemMessage = messages.first;
    final remaining = messages.skip(1).toList();

    // Flatten all history turns into chat messages
    final historyMessages = <ChatMessage>[];
    for (final turn in history) {
      historyMessages.addAll(turn.toChatMessages());
    }

    return [systemMessage, ...historyMessages, ...remaining];
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

    state = state.copyWith(isStreaming: false, error: errorMessage);
  }

  /// Gets banned phrases from settings, or returns empty list.
  Future<List<String>> _getBannedPhrases() async {
    final phrasesAsync = ref.read(bannedPhrasesProvider);
    return phrasesAsync.asData?.value ?? [];
  }
}

/// Provider for the editor AI notifier.
final editorAINotifierProvider =
    NotifierProvider<EditorAINotifier, EditorAIState>(EditorAINotifier.new);
