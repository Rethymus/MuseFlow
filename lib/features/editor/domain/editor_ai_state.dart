/// Editor AI state management domain entities.
///
/// Contains [EditorAIState] (immutable state for editor AI operations)
/// and [EditorAIOperation] enum (tone rewrite, paragraph polish, free-input).
library;

import 'package:museflow/features/editor/domain/diff_state.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';

/// Types of AI operations available in the editor floating toolbar.
///
/// Each operation has a Chinese label for display in the UI.
enum EditorAIOperation {
  /// Tone/voice rewrite -- adjust narrative style while preserving meaning.
  toneRewrite('语气改写'),

  /// Paragraph polish -- improve literary quality of the text.
  paragraphPolish('文段润色'),

  /// Free-input -- user provides custom editing instructions.
  freeInput('自由输入');

  /// Chinese display label for this operation.
  final String label;

  const EditorAIOperation(this.label);
}

/// Sentinel value indicating a field was not passed to [copyWith].
///
/// Allows distinguishing between "not passed" (preserve existing value)
/// and "explicitly set to null" (clear the value).
const _sentinel = Object();

/// Immutable state for the editor AI operation flow.
///
/// Tracks the current AI operation, streaming progress, selection context,
/// and error state. Follows the same pattern as [SynthesisState] for
/// consistency across the codebase.
class EditorAIState {
  /// Whether an AI streaming operation is in progress.
  final bool isStreaming;

  /// The current AI operation type, or null when idle.
  final EditorAIOperation? operation;

  /// Accumulated text from streaming. Shows real-time progress.
  final String? progressText;

  /// Inline error message (Chinese). Null when no error.
  final String? error;

  /// The text that was selected in the editor when the operation started.
  final String selectedText;

  /// The document node ID containing the selection.
  final String selectionNodeId;

  /// Character offset where the selection starts within the node.
  final int selectionStartOffset;

  /// Character offset where the selection ends within the node.
  final int selectionEndOffset;

  /// User's custom instruction for free-input operations.
  final String? userInstruction;

  /// The diff result after an AI operation completes, or null when no diff.
  final DiffResult? diffResult;

  /// Author-facing anti-AI-scent review signals for the latest AI output.
  final List<ReviewSignal> reviewSignals;

  /// Creates an [EditorAIState] with sensible defaults (idle state).
  const EditorAIState({
    this.isStreaming = false,
    this.operation,
    this.progressText,
    this.error,
    this.selectedText = '',
    this.selectionNodeId = '',
    this.selectionStartOffset = 0,
    this.selectionEndOffset = 0,
    this.userInstruction,
    this.diffResult,
    this.reviewSignals = const [],
  });

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields ([progressText], [error], [userInstruction]) use a
  /// sentinel pattern: omitting them preserves the existing value, while
  /// passing `null` explicitly clears them.
  EditorAIState copyWith({
    bool? isStreaming,
    EditorAIOperation? operation,
    Object? progressText = _sentinel,
    Object? error = _sentinel,
    String? selectedText,
    String? selectionNodeId,
    int? selectionStartOffset,
    int? selectionEndOffset,
    Object? userInstruction = _sentinel,
    Object? diffResult = _sentinel,
    List<ReviewSignal>? reviewSignals,
  }) {
    return EditorAIState(
      isStreaming: isStreaming ?? this.isStreaming,
      operation: operation ?? this.operation,
      progressText: progressText == _sentinel
          ? this.progressText
          : progressText as String?,
      error: error == _sentinel ? this.error : error as String?,
      selectedText: selectedText ?? this.selectedText,
      selectionNodeId: selectionNodeId ?? this.selectionNodeId,
      selectionStartOffset: selectionStartOffset ?? this.selectionStartOffset,
      selectionEndOffset: selectionEndOffset ?? this.selectionEndOffset,
      userInstruction: userInstruction == _sentinel
          ? this.userInstruction
          : userInstruction as String?,
      diffResult: diffResult == _sentinel
          ? this.diffResult
          : diffResult as DiffResult?,
      reviewSignals: reviewSignals ?? this.reviewSignals,
    );
  }
}
