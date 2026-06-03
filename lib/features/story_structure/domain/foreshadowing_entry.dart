/// Operating mode for a foreshadowing entry.
///
/// Simple mode is a lightweight checklist for fast tracking.
/// Detailed mode uses the full status flow: planted, developing, resolved, abandoned.
enum ForeshadowingMode {
  simple,
  detailed;

  /// Deserialize from JSON string.
  static ForeshadowingMode fromJsonString(String value) {
    return ForeshadowingMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ForeshadowingMode.simple,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// Status of a foreshadowing entry in the tracking lifecycle.
enum ForeshadowingStatus {
  planted,
  developing,
  resolved,
  abandoned;

  /// Deserialize from JSON string.
  static ForeshadowingStatus fromJsonString(String value) {
    return ForeshadowingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ForeshadowingStatus.planted,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// Location within the editor document where foreshadowing was planted.
///
/// Preserves source context so authors can navigate back to the original text.
class SourceLocation {
  final String nodeId;
  final int startOffset;
  final int endOffset;
  final int? chapter;

  const SourceLocation({
    required this.nodeId,
    required this.startOffset,
    required this.endOffset,
    this.chapter,
  });

  SourceLocation copyWith({
    String? nodeId,
    int? startOffset,
    int? endOffset,
    int? chapter,
  }) {
    return SourceLocation(
      nodeId: nodeId ?? this.nodeId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      chapter: chapter ?? this.chapter,
    );
  }

  factory SourceLocation.fromJson(Map<String, dynamic> json) {
    return SourceLocation(
      nodeId: json['nodeId'] as String,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
      chapter: json['chapter'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'startOffset': startOffset,
      'endOffset': endOffset,
      if (chapter != null) 'chapter': chapter,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SourceLocation &&
        other.nodeId == nodeId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.chapter == chapter;
  }

  @override
  int get hashCode => Object.hash(nodeId, startOffset, endOffset, chapter);

  @override
  String toString() =>
      'SourceLocation(nodeId: $nodeId, startOffset: $startOffset, '
      'endOffset: $endOffset, chapter: $chapter)';
}

/// An immutable foreshadowing entry tracking a story thread.
///
/// Supports simple checklist mode and detailed status-flow mode.
/// Foreshadowing entries track planted clues, their resolution status,
/// and source location in the manuscript.
///
/// Use [copyWith] to create modified copies.
class ForeshadowingEntry {
  final String id;
  final String title;
  final ForeshadowingMode mode;
  final ForeshadowingStatus status;
  final int plantedChapter;
  final int? targetResolutionChapter;
  final int? resolvedChapter;
  final String sourceExcerpt;
  final SourceLocation? sourceLocation;
  final String notes;
  final List<String> linkedPlotNodeIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ForeshadowingEntry({
    required this.id,
    required this.title,
    required this.mode,
    required this.status,
    required this.plantedChapter,
    this.targetResolutionChapter,
    this.resolvedChapter,
    this.sourceExcerpt = '',
    this.sourceLocation,
    this.notes = '',
    this.linkedPlotNodeIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Whether this entry is still open (not resolved or abandoned).
  bool get isOpen =>
      status == ForeshadowingStatus.planted ||
      status == ForeshadowingStatus.developing;

  /// Whether this entry has been resolved.
  bool get isResolved => status == ForeshadowingStatus.resolved;

  /// Whether this entry is overdue based on the given current chapter and threshold.
  ///
  /// An entry is overdue if:
  /// - It is still open (planted or developing), AND
  /// - currentChapter - plantedChapter >= defaultThreshold, OR
  /// - targetResolutionChapter is set and currentChapter > targetResolutionChapter
  bool isOverdue({required int currentChapter, required int defaultThreshold}) {
    if (!isOpen) return false;

    // Threshold overdue: been open too long by chapter count
    if (currentChapter - plantedChapter >= defaultThreshold) return true;

    // Target overdue: past the planned resolution chapter
    if (targetResolutionChapter != null &&
        currentChapter > targetResolutionChapter!) {
      return true;
    }

    return false;
  }

  ForeshadowingEntry copyWith({
    String? id,
    String? title,
    ForeshadowingMode? mode,
    ForeshadowingStatus? status,
    int? plantedChapter,
    int? targetResolutionChapter,
    int? resolvedChapter,
    String? sourceExcerpt,
    SourceLocation? sourceLocation,
    String? notes,
    List<String>? linkedPlotNodeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ForeshadowingEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      plantedChapter: plantedChapter ?? this.plantedChapter,
      targetResolutionChapter:
          targetResolutionChapter ?? this.targetResolutionChapter,
      resolvedChapter: resolvedChapter ?? this.resolvedChapter,
      sourceExcerpt: sourceExcerpt ?? this.sourceExcerpt,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      notes: notes ?? this.notes,
      linkedPlotNodeIds: linkedPlotNodeIds ?? this.linkedPlotNodeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ForeshadowingEntry.fromJson(Map<String, dynamic> json) {
    return ForeshadowingEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      mode: ForeshadowingMode.fromJsonString(json['mode'] as String),
      status: ForeshadowingStatus.fromJsonString(json['status'] as String),
      plantedChapter: json['plantedChapter'] as int,
      targetResolutionChapter: json['targetResolutionChapter'] as int?,
      resolvedChapter: json['resolvedChapter'] as int?,
      sourceExcerpt: json['sourceExcerpt'] as String? ?? '',
      sourceLocation: json['sourceLocation'] != null
          ? SourceLocation.fromJson(
              json['sourceLocation'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String? ?? '',
      linkedPlotNodeIds:
          (json['linkedPlotNodeIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'mode': mode.toJsonString(),
      'status': status.toJsonString(),
      'plantedChapter': plantedChapter,
      'targetResolutionChapter': targetResolutionChapter,
      'resolvedChapter': resolvedChapter,
      'sourceExcerpt': sourceExcerpt,
      'sourceLocation': sourceLocation?.toJson(),
      'notes': notes,
      'linkedPlotNodeIds': linkedPlotNodeIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForeshadowingEntry &&
        other.id == id &&
        other.title == title &&
        other.mode == mode &&
        other.status == status &&
        other.plantedChapter == plantedChapter &&
        other.targetResolutionChapter == targetResolutionChapter &&
        other.resolvedChapter == resolvedChapter &&
        other.sourceExcerpt == sourceExcerpt &&
        other.sourceLocation == sourceLocation &&
        other.notes == notes &&
        _listEquals(other.linkedPlotNodeIds, linkedPlotNodeIds) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        mode,
        status,
        plantedChapter,
        targetResolutionChapter,
        resolvedChapter,
        sourceExcerpt,
        sourceLocation,
        notes,
        Object.hashAll(linkedPlotNodeIds),
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'ForeshadowingEntry(id: $id, title: $title, mode: $mode, '
      'status: $status, plantedChapter: $plantedChapter)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
