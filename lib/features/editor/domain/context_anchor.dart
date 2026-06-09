/// Context anchor domain entities.
///
/// Contains [ContextAnchor] (immutable entity for designating reference
/// paragraphs for AI operations) and [AnchorType] enum (persistent vs one-time).
///
/// Per D-12: Persistent anchors remain until manually removed;
/// one-time anchors clear after AI operation.
/// Per D-14: Anchored paragraphs show gold background with pin icon.
library;

import 'package:museflow/features/ai/application/prompt_pipeline.dart';

/// Type of context anchor determining its lifecycle.
enum AnchorType {
  /// Remains active until manually removed by the user.
  persistent,

  /// Clears automatically after the next AI operation completes.
  oneTime,
}

/// Immutable entity representing a user-designated reference paragraph.
///
/// Anchors let users mark specific text passages as context for AI operations.
/// The anchor text is injected into the AI prompt as a system message.
///
/// Per D-14: The [label] is auto-generated from the first 20 characters of
/// [text], with "..." appended if longer.
class ContextAnchor implements AnchorReference {
  /// Unique identifier (UUID).
  final String id;

  /// The anchored paragraph text content.
  @override
  final String text;

  /// The super_editor document node ID containing the anchored text.
  final String nodeId;

  /// Character offset where the anchor starts within the node.
  final int startOffset;

  /// Character offset where the anchor ends within the node.
  final int endOffset;

  /// Whether this anchor persists across AI operations.
  ///
  /// `true` = persistent (removes manually), `false` = one-time (clears after use).
  final bool isPersistent;

  /// When this anchor was created.
  final DateTime createdAt;

  /// Auto-generated label from the first 20 characters of [text].
  @override
  String get label {
    if (text.length <= 20) return text;
    return '${text.substring(0, 20)}...';
  }

  /// Creates a [ContextAnchor] with all fields specified.
  const ContextAnchor({
    required this.id,
    required this.text,
    required this.nodeId,
    required this.startOffset,
    required this.endOffset,
    required this.isPersistent,
    required this.createdAt,
  });

  /// Creates a [ContextAnchor] from an [AnchorType] instead of raw bool.
  factory ContextAnchor.fromType({
    required String id,
    required String text,
    required String nodeId,
    required int startOffset,
    required int endOffset,
    required AnchorType type,
    required DateTime createdAt,
  }) {
    return ContextAnchor(
      id: id,
      text: text,
      nodeId: nodeId,
      startOffset: startOffset,
      endOffset: endOffset,
      isPersistent: type == AnchorType.persistent,
      createdAt: createdAt,
    );
  }

  /// Creates a copy with the given fields replaced.
  ContextAnchor copyWith({
    String? id,
    String? text,
    String? nodeId,
    int? startOffset,
    int? endOffset,
    bool? isPersistent,
    DateTime? createdAt,
  }) {
    return ContextAnchor(
      id: id ?? this.id,
      text: text ?? this.text,
      nodeId: nodeId ?? this.nodeId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      isPersistent: isPersistent ?? this.isPersistent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContextAnchor &&
        other.id == id &&
        other.text == text &&
        other.nodeId == nodeId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.isPersistent == isPersistent &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    text,
    nodeId,
    startOffset,
    endOffset,
    isPersistent,
    createdAt,
  );

  @override
  String toString() =>
      'ContextAnchor(id: $id, label: $label, persistent: $isPersistent, '
      'nodeId: $nodeId, range: $startOffset..$endOffset)';
}
