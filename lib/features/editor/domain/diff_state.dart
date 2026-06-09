/// Text provenance tracking domain entities.
///
/// Contains [DiffResult], [SentenceDiff], and [DiffStatus] for tracking
/// sentence-level inline diffs between original and AI-modified text.
library;

/// Status of a single sentence diff after AI modification.
enum DiffStatus {
  /// Awaiting user decision.
  pending,

  /// User accepted the AI modification.
  accepted,

  /// User rejected the AI modification.
  rejected,
}

/// A single sentence-level diff between original and AI text.
///
/// Immutable entity. Use [copyWith] to create modified copies.
///
/// Three diff types:
/// - **Modification**: both [originalText] and [newText] are non-null
/// - **Deletion**: [originalText] is non-null, [newText] is null
/// - **Insertion**: [originalText] is null, [newText] is non-null
class SentenceDiff {
  /// The original sentence text, or null for pure insertions.
  final String? originalText;

  /// The AI-generated sentence text, or null for pure deletions.
  final String? newText;

  /// Current status of this diff (pending/accepted/rejected).
  final DiffStatus status;

  /// The document node ID containing this sentence.
  final String nodeId;

  /// Character offset where this sentence starts within the node.
  final int startOffset;

  /// Character offset where this sentence ends within the node.
  final int endOffset;

  const SentenceDiff({
    required this.originalText,
    required this.newText,
    required this.status,
    required this.nodeId,
    required this.startOffset,
    required this.endOffset,
  });

  /// Whether this is a deletion (original removed, no replacement).
  bool get isDeletion => originalText != null && newText == null;

  /// Whether this is an insertion (new text, no original).
  bool get isInsertion => originalText == null && newText != null;

  /// Whether this is a modification (both original and new text present).
  bool get isModification => originalText != null && newText != null;

  /// Creates a copy with the given fields replaced.
  SentenceDiff copyWith({
    String? originalText,
    String? newText,
    DiffStatus? status,
    String? nodeId,
    int? startOffset,
    int? endOffset,
  }) {
    return SentenceDiff(
      originalText: originalText ?? this.originalText,
      newText: newText ?? this.newText,
      status: status ?? this.status,
      nodeId: nodeId ?? this.nodeId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SentenceDiff &&
        other.originalText == originalText &&
        other.newText == newText &&
        other.status == status &&
        other.nodeId == nodeId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset;
  }

  @override
  int get hashCode => Object.hash(
    originalText,
    newText,
    status,
    nodeId,
    startOffset,
    endOffset,
  );

  @override
  String toString() =>
      'SentenceDiff(original: $originalText, new: $newText, status: $status, '
      'nodeId: $nodeId, offset: $startOffset..$endOffset)';
}

/// Result of comparing original text with AI-generated text.
///
/// Contains a list of [SentenceDiff] entries, each representing a single
/// sentence-level change. Immutable -- use [copyWith] to update individual
/// sentence statuses.
class DiffResult {
  /// The list of sentence-level diffs.
  final List<SentenceDiff> sentences;

  /// The document node ID for the original text range.
  final String nodeId;

  const DiffResult({required this.sentences, required this.nodeId});

  /// Number of sentences still awaiting user decision.
  int get pendingCount =>
      sentences.where((s) => s.status == DiffStatus.pending).length;

  /// Whether all sentences have been accepted or rejected.
  bool get allResolved => pendingCount == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiffResult &&
        _listEquals(other.sentences, sentences) &&
        other.nodeId == nodeId;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(sentences), nodeId);

  @override
  String toString() =>
      'DiffResult(nodeId: $nodeId, sentences: ${sentences.length}, pending: $pendingCount)';

  static bool _listEquals(List<SentenceDiff> a, List<SentenceDiff> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
