/// Editor AI state management domain entities.
///
/// Contains [EditorAIState] (immutable state for editor AI operations)
/// and [EditorAIOperation] enum (tone rewrite, paragraph polish, free-input).
library;

import 'package:museflow/features/editor/domain/diff_state.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:openai_dart/openai_dart.dart';

/// Types of AI operations available in the editor floating toolbar.
///
/// Each operation has a Chinese label for display in the UI.
enum EditorAIOperation {
  /// Tone/voice rewrite -- adjust narrative style while preserving meaning.
  toneRewrite('语气改写'),

  /// Paragraph polish -- improve literary quality of the text.
  paragraphPolish('文段润色'),

  /// Free-input -- user provides custom editing instructions.
  freeInput('自由输入'),

  /// Expand -- enrich text with more details, sensory descriptions, and depth.
  expand('扩写'),

  /// Compress -- condense text while preserving core meaning.
  compress('缩写'),

  /// Dialogue generation -- convert narrative description into character dialogue.
  dialogue('对话生成'),

  /// Scene description -- enrich with vivid sensory and atmospheric details.
  scene('场景描写');

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

  /// Multi-turn conversation history for iterative refinement.
  ///
  /// Each entry represents one turn: the user's instruction and the AI's
  /// output. When non-empty, subsequent operations include this history
  /// in the prompt so the AI can refine based on previous feedback.
  final List<ConversationTurn> conversationHistory;

  /// Maximum number of conversation turns to retain for token budget.
  static const maxConversationTurns = 5;

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
    this.conversationHistory = const [],
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
    List<ConversationTurn>? conversationHistory,
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
      conversationHistory: conversationHistory ?? this.conversationHistory,
    );
  }
}

/// A single turn in a multi-turn AI conversation for iterative refinement.
///
/// Stores the user's feedback instruction and the AI's response text
/// so that subsequent turns can reference the full conversation context.
class ConversationTurn {
  /// The user's instruction for this turn (e.g., "太华丽了，朴素一点").
  final String userInstruction;

  /// The AI's response text for this turn.
  final String aiResponse;

  /// The operation type used in this turn.
  final EditorAIOperation operation;

  const ConversationTurn({
    required this.userInstruction,
    required this.aiResponse,
    required this.operation,
  });

  /// Converts this turn to chat messages for the AI API.
  List<ChatMessage> toChatMessages() {
    return [
      ChatMessage.user(userInstruction),
      ChatMessage.assistant(content: aiResponse),
    ];
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationTurn &&
        other.userInstruction == userInstruction &&
        other.aiResponse == aiResponse;
  }

  @override
  int get hashCode => Object.hash(userInstruction, aiResponse);
}
