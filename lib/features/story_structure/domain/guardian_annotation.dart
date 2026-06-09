/// Type of finding from a guardian consistency check.
enum GuardianFindingKind {
  characterConsistency,
  timelineContradiction,
  worldRuleConflict,
  skillRuleConflict,
  unresolvedForeshadowing;

  /// Deserialize from JSON string.
  static GuardianFindingKind fromJsonString(String value) {
    return GuardianFindingKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GuardianFindingKind.characterConsistency,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// Severity level of a guardian finding.
enum GuardianSeverity {
  low,
  medium,
  high;

  /// Deserialize from JSON string.
  static GuardianSeverity fromJsonString(String value) {
    return GuardianSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GuardianSeverity.low,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// An immutable advisory annotation from a guardian consistency check.
///
/// Guardian annotations represent AI-detected potential issues with character
/// consistency, timeline logic, world rules, or unresolved story threads.
/// They are advisory only and never auto-apply to manuscript text.
///
/// Use [copyWith] to create modified copies.
class GuardianAnnotation {
  final String id;
  final GuardianFindingKind kind;
  final GuardianSeverity severity;
  final String message;
  final String reason;
  final String? suggestedFix;
  final String? nodeId;
  final int? startOffset;
  final int? endOffset;
  final String? sourceText;
  final DateTime createdAt;
  final DateTime? dismissedAt;
  final List<String> characterIds;
  final List<String> worldSettingIds;
  final List<String> skillIds;
  final List<String> plotNodeIds;
  final List<String> foreshadowingIds;

  GuardianAnnotation({
    required this.id,
    required this.kind,
    required this.severity,
    required this.message,
    required this.reason,
    this.suggestedFix,
    this.nodeId,
    this.startOffset,
    this.endOffset,
    this.sourceText,
    required this.createdAt,
    this.dismissedAt,
    this.characterIds = const [],
    this.worldSettingIds = const [],
    this.skillIds = const [],
    this.plotNodeIds = const [],
    this.foreshadowingIds = const [],
  });

  /// Whether this annotation has been dismissed by the author.
  bool get isDismissed => dismissedAt != null;

  /// Whether this annotation has a precise location in the manuscript.
  ///
  /// True only when [nodeId], [startOffset], and [endOffset] are all non-null.
  bool get hasExactLocation =>
      nodeId != null && startOffset != null && endOffset != null;

  /// Creates a copy with the given fields replaced.
  ///
  /// Pass [clearNodeId], [clearStartOffset], [clearEndOffset],
  /// [clearSourceText], [clearSuggestedFix], or [clearDismissedAt]
  /// as `true` to explicitly set those fields to null.
  GuardianAnnotation copyWith({
    String? id,
    GuardianFindingKind? kind,
    GuardianSeverity? severity,
    String? message,
    String? reason,
    String? suggestedFix,
    String? nodeId,
    int? startOffset,
    int? endOffset,
    String? sourceText,
    DateTime? createdAt,
    DateTime? dismissedAt,
    List<String>? characterIds,
    List<String>? worldSettingIds,
    List<String>? skillIds,
    List<String>? plotNodeIds,
    List<String>? foreshadowingIds,
    bool clearSuggestedFix = false,
    bool clearNodeId = false,
    bool clearStartOffset = false,
    bool clearEndOffset = false,
    bool clearSourceText = false,
    bool clearDismissedAt = false,
  }) {
    return GuardianAnnotation(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      reason: reason ?? this.reason,
      suggestedFix: clearSuggestedFix
          ? null
          : (suggestedFix ?? this.suggestedFix),
      nodeId: clearNodeId ? null : (nodeId ?? this.nodeId),
      startOffset: clearStartOffset ? null : (startOffset ?? this.startOffset),
      endOffset: clearEndOffset ? null : (endOffset ?? this.endOffset),
      sourceText: clearSourceText ? null : (sourceText ?? this.sourceText),
      createdAt: createdAt ?? this.createdAt,
      dismissedAt: clearDismissedAt ? null : (dismissedAt ?? this.dismissedAt),
      characterIds: characterIds ?? this.characterIds,
      worldSettingIds: worldSettingIds ?? this.worldSettingIds,
      skillIds: skillIds ?? this.skillIds,
      plotNodeIds: plotNodeIds ?? this.plotNodeIds,
      foreshadowingIds: foreshadowingIds ?? this.foreshadowingIds,
    );
  }

  factory GuardianAnnotation.fromJson(Map<String, dynamic> json) {
    return GuardianAnnotation(
      id: json['id'] as String,
      kind: GuardianFindingKind.fromJsonString(
        json['kind'] as String? ?? 'characterConsistency',
      ),
      severity: GuardianSeverity.fromJsonString(
        json['severity'] as String? ?? 'low',
      ),
      message: json['message'] as String,
      reason: json['reason'] as String,
      suggestedFix: json['suggestedFix'] as String?,
      nodeId: json['nodeId'] as String?,
      startOffset: json['startOffset'] as int?,
      endOffset: json['endOffset'] as int?,
      sourceText: json['sourceText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dismissedAt: json['dismissedAt'] != null
          ? DateTime.parse(json['dismissedAt'] as String)
          : null,
      characterIds:
          (json['characterIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      worldSettingIds:
          (json['worldSettingIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
      skillIds:
          (json['skillIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      plotNodeIds:
          (json['plotNodeIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      foreshadowingIds:
          (json['foreshadowingIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.toJsonString(),
      'severity': severity.toJsonString(),
      'message': message,
      'reason': reason,
      'suggestedFix': suggestedFix,
      'nodeId': nodeId,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'sourceText': sourceText,
      'createdAt': createdAt.toIso8601String(),
      'dismissedAt': dismissedAt?.toIso8601String(),
      'characterIds': characterIds,
      'worldSettingIds': worldSettingIds,
      'skillIds': skillIds,
      'plotNodeIds': plotNodeIds,
      'foreshadowingIds': foreshadowingIds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuardianAnnotation &&
        other.id == id &&
        other.kind == kind &&
        other.severity == severity &&
        other.message == message &&
        other.reason == reason &&
        other.suggestedFix == suggestedFix &&
        other.nodeId == nodeId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.sourceText == sourceText &&
        other.createdAt == createdAt &&
        other.dismissedAt == dismissedAt &&
        _listEquals(other.characterIds, characterIds) &&
        _listEquals(other.worldSettingIds, worldSettingIds) &&
        _listEquals(other.skillIds, skillIds) &&
        _listEquals(other.plotNodeIds, plotNodeIds) &&
        _listEquals(other.foreshadowingIds, foreshadowingIds);
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    severity,
    message,
    reason,
    suggestedFix,
    nodeId,
    startOffset,
    endOffset,
    sourceText,
    createdAt,
    dismissedAt,
    Object.hashAll(characterIds),
    Object.hashAll(worldSettingIds),
    Object.hashAll(skillIds),
    Object.hashAll(plotNodeIds),
    Object.hashAll(foreshadowingIds),
  );

  @override
  String toString() =>
      'GuardianAnnotation(id: $id, kind: $kind, severity: $severity)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
