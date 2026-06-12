/// Selective undo service for AI modifications.
///
/// Manages an AI undo stack that is separate from the document's built-in
/// undo/redo system. This allows users to revert AI changes (Ctrl+Shift+Z)
/// without losing their own human edits (Ctrl+Z).
///
/// Per EDIT-06: The AI undo stack tracks operations independently.
/// When the user accepts an AI sentence, the original text is recorded
/// here so it can be restored later.
library;

/// An entry in the AI undo stack recording a single AI text replacement.
///
/// Immutable -- created when an AI modification is accepted.
class UndoEntry {
  /// The original human-authored text before AI modification.
  final String originalText;

  /// The AI-generated replacement text.
  final String replacementText;

  /// The document node ID containing the modified text.
  final String nodeId;

  /// Character offset where the modification starts within the node.
  final int startOffset;

  /// Character offset where the modification ends within the node.
  final int endOffset;

  /// When this undo entry was recorded.
  final DateTime timestamp;

  const UndoEntry({
    required this.originalText,
    required this.replacementText,
    required this.nodeId,
    required this.startOffset,
    required this.endOffset,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UndoEntry &&
        other.originalText == originalText &&
        other.replacementText == replacementText &&
        other.nodeId == nodeId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
    originalText,
    replacementText,
    nodeId,
    startOffset,
    endOffset,
    timestamp,
  );

  @override
  String toString() =>
      'UndoEntry(nodeId: $nodeId, range: $startOffset..$endOffset, '
      'original: $originalText, replacement: $replacementText)';
}

/// Service managing the AI-specific undo stack.
///
/// This stack is separate from the document's built-in undo system.
/// Ctrl+Z undoes human edits; Ctrl+Shift+Z (via this service) undoes
/// AI accepts.
///
/// Per EDIT-02: Maximum undo steps capped at [maxLimit] (default 20).
/// Not a Riverpod notifier -- it is stateful but simple, managed by
/// a Riverpod Provider.
class SelectiveUndoService {
  /// Maximum number of AI undo entries retained.
  ///
  /// When the stack exceeds this limit, the oldest entry is evicted.
  /// Per EDIT-02: Default 20 steps for user-friendly version comparison.
  final int maxLimit;

  final List<UndoEntry> _undoStack = [];

  /// Creates a selective undo service with an optional [maxLimit].
  ///
  /// Defaults to 20 entries per EDIT-02.
  SelectiveUndoService({this.maxLimit = 20});

  /// Whether there is an AI operation that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// The number of entries in the undo stack.
  int get stackLength => _undoStack.length;

  /// The most recent undo entry, or null if the stack is empty.
  UndoEntry? get lastEntry =>
      _undoStack.isNotEmpty ? _undoStack.last : null;

  /// All entries in chronological order (oldest first).
  ///
  /// Useful for version comparison (A/B/C selection per EDIT-02).
  List<UndoEntry> get entries => List.unmodifiable(_undoStack);

  /// Records an AI text replacement in the undo stack.
  ///
  /// Call this when a user accepts an AI sentence modification.
  /// The [originalText] is preserved so it can be restored later.
  ///
  /// If the stack exceeds [maxLimit], the oldest entry is evicted.
  void record({
    required String originalText,
    required String replacementText,
    required String nodeId,
    required int startOffset,
    required int endOffset,
  }) {
    _undoStack.add(
      UndoEntry(
        originalText: originalText,
        replacementText: replacementText,
        nodeId: nodeId,
        startOffset: startOffset,
        endOffset: endOffset,
        timestamp: DateTime.now(),
      ),
    );

    // Evict oldest entries when exceeding max limit
    while (_undoStack.length > maxLimit) {
      _undoStack.removeAt(0);
    }
  }

  /// Removes and returns the most recent undo entry.
  ///
  /// Returns null if the stack is empty.
  UndoEntry? popLast() {
    if (_undoStack.isEmpty) return null;
    return _undoStack.removeLast();
  }

  /// Empties the undo stack.
  void clear() {
    _undoStack.clear();
  }
}
