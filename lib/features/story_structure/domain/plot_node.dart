/// Writing status for a plot node in the story structure.
enum PlotNodeWritingStatus {
  notStarted,
  drafting,
  complete,
  needsRevision;

  /// Deserialize from JSON string.
  static PlotNodeWritingStatus fromJsonString(String value) {
    return PlotNodeWritingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlotNodeWritingStatus.notStarted,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// Structural role of a plot node within the story arc.
enum PlotNodeStructuralRole {
  setup,
  development,
  turn,
  climax,
  resolution;

  /// Deserialize from JSON string.
  static PlotNodeStructuralRole fromJsonString(String value) {
    return PlotNodeStructuralRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlotNodeStructuralRole.setup,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;
}

/// An immutable plot node representing a story milestone in the timeline.
///
/// Plot nodes track major story beats with chapter placement, structural role,
/// writing status, and relational links to other nodes, characters, and
/// foreshadowing entries.
///
/// Use [copyWith] to create modified copies.
class PlotNode {
  final String id;
  final String title;
  final int chapter;
  final String summary;
  final List<String> involvedCharacterIds;
  final List<String> involvedCharacterNames;
  final List<String> linkedForeshadowingIds;
  final PlotNodeWritingStatus writingStatus;
  final PlotNodeStructuralRole structuralRole;
  final List<String> causeNodeIds;
  final List<String> consequenceNodeIds;
  final List<String> relatedNodeIds;
  final int manualOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PlotNode({
    required this.id,
    required this.title,
    required this.chapter,
    this.summary = '',
    this.involvedCharacterIds = const [],
    this.involvedCharacterNames = const [],
    this.linkedForeshadowingIds = const [],
    this.writingStatus = PlotNodeWritingStatus.notStarted,
    this.structuralRole = PlotNodeStructuralRole.setup,
    this.causeNodeIds = const [],
    this.consequenceNodeIds = const [],
    this.relatedNodeIds = const [],
    this.manualOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a copy with the given fields replaced.
  ///
  /// Pass [clearUpdatedAt] as `true` to explicitly set [updatedAt] to null.
  PlotNode copyWith({
    String? id,
    String? title,
    int? chapter,
    String? summary,
    List<String>? involvedCharacterIds,
    List<String>? involvedCharacterNames,
    List<String>? linkedForeshadowingIds,
    PlotNodeWritingStatus? writingStatus,
    PlotNodeStructuralRole? structuralRole,
    List<String>? causeNodeIds,
    List<String>? consequenceNodeIds,
    List<String>? relatedNodeIds,
    int? manualOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return PlotNode(
      id: id ?? this.id,
      title: title ?? this.title,
      chapter: chapter ?? this.chapter,
      summary: summary ?? this.summary,
      involvedCharacterIds: involvedCharacterIds ?? this.involvedCharacterIds,
      involvedCharacterNames:
          involvedCharacterNames ?? this.involvedCharacterNames,
      linkedForeshadowingIds:
          linkedForeshadowingIds ?? this.linkedForeshadowingIds,
      writingStatus: writingStatus ?? this.writingStatus,
      structuralRole: structuralRole ?? this.structuralRole,
      causeNodeIds: causeNodeIds ?? this.causeNodeIds,
      consequenceNodeIds: consequenceNodeIds ?? this.consequenceNodeIds,
      relatedNodeIds: relatedNodeIds ?? this.relatedNodeIds,
      manualOrder: manualOrder ?? this.manualOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }

  factory PlotNode.fromJson(Map<String, dynamic> json) {
    return PlotNode(
      id: json['id'] as String,
      title: json['title'] as String,
      chapter: json['chapter'] as int,
      summary: json['summary'] as String? ?? '',
      involvedCharacterIds:
          (json['involvedCharacterIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      involvedCharacterNames:
          (json['involvedCharacterNames'] as List<dynamic>?)?.cast<String>() ??
              const [],
      linkedForeshadowingIds:
          (json['linkedForeshadowingIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      writingStatus: PlotNodeWritingStatus.fromJsonString(
        json['writingStatus'] as String? ?? 'notStarted',
      ),
      structuralRole: PlotNodeStructuralRole.fromJsonString(
        json['structuralRole'] as String? ?? 'setup',
      ),
      causeNodeIds:
          (json['causeNodeIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      consequenceNodeIds:
          (json['consequenceNodeIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      relatedNodeIds:
          (json['relatedNodeIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      manualOrder: json['manualOrder'] as int? ?? 0,
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
      'chapter': chapter,
      'summary': summary,
      'involvedCharacterIds': involvedCharacterIds,
      'involvedCharacterNames': involvedCharacterNames,
      'linkedForeshadowingIds': linkedForeshadowingIds,
      'writingStatus': writingStatus.toJsonString(),
      'structuralRole': structuralRole.toJsonString(),
      'causeNodeIds': causeNodeIds,
      'consequenceNodeIds': consequenceNodeIds,
      'relatedNodeIds': relatedNodeIds,
      'manualOrder': manualOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlotNode &&
        other.id == id &&
        other.title == title &&
        other.chapter == chapter &&
        other.summary == summary &&
        _listEquals(other.involvedCharacterIds, involvedCharacterIds) &&
        _listEquals(other.involvedCharacterNames, involvedCharacterNames) &&
        _listEquals(other.linkedForeshadowingIds, linkedForeshadowingIds) &&
        other.writingStatus == writingStatus &&
        other.structuralRole == structuralRole &&
        _listEquals(other.causeNodeIds, causeNodeIds) &&
        _listEquals(other.consequenceNodeIds, consequenceNodeIds) &&
        _listEquals(other.relatedNodeIds, relatedNodeIds) &&
        other.manualOrder == manualOrder &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        chapter,
        summary,
        Object.hashAll(involvedCharacterIds),
        Object.hashAll(involvedCharacterNames),
        Object.hashAll(linkedForeshadowingIds),
        writingStatus,
        structuralRole,
        Object.hashAll(causeNodeIds),
        Object.hashAll(consequenceNodeIds),
        Object.hashAll(relatedNodeIds),
        manualOrder,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'PlotNode(id: $id, title: $title, chapter: $chapter, '
      'status: $writingStatus, role: $structuralRole)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
