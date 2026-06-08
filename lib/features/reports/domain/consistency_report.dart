import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';

/// A single consistency flag for an entity in a specific chapter.
///
/// Records where an entity's portrayal deviated from the expected value
/// defined in the knowledge base (character card or world setting).
class ConsistencyFlag {
  const ConsistencyFlag({
    required this.chapterIndex,
    required this.field,
    required this.expectedValue,
    required this.observedText,
    required this.severity,
  });

  /// Chapter index where the deviation was observed.
  final int chapterIndex;

  /// The field that deviated (e.g. 'personality', 'eye_color', 'power_level').
  final String field;

  /// Expected value from the knowledge base entity.
  final String expectedValue;

  /// Actual text observed in the chapter content.
  final String observedText;

  /// Severity of the deviation, reusing DeviationSeverity.
  final DeviationSeverity severity;

  ConsistencyFlag copyWith({
    int? chapterIndex,
    String? field,
    String? expectedValue,
    String? observedText,
    DeviationSeverity? severity,
  }) {
    return ConsistencyFlag(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      field: field ?? this.field,
      expectedValue: expectedValue ?? this.expectedValue,
      observedText: observedText ?? this.observedText,
      severity: severity ?? this.severity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsistencyFlag &&
          runtimeType == other.runtimeType &&
          chapterIndex == other.chapterIndex &&
          field == other.field &&
          expectedValue == other.expectedValue &&
          observedText == other.observedText &&
          severity == other.severity;

  @override
  int get hashCode =>
      chapterIndex.hashCode ^
      field.hashCode ^
      expectedValue.hashCode ^
      observedText.hashCode ^
      severity.hashCode;
}

/// Consistency result for a single entity (character or setting).
///
/// Tracks how consistently the entity is portrayed across chapters
/// and lists individual deviation flags.
class EntityConsistencyResult {
  const EntityConsistencyResult({
    required this.entityName,
    required this.entityType,
    required this.chaptersWhereMentioned,
    required this.consistencyScore,
    required this.flags,
  });

  /// Name of the entity (character name, setting name).
  final String entityName;

  /// Type of entity: 'character', 'setting', or 'skill'.
  final String entityType;

  /// Number of chapters where this entity was mentioned.
  final int chaptersWhereMentioned;

  /// Consistency score from 0.0 (completely inconsistent) to 1.0 (fully consistent).
  final double consistencyScore;

  /// Individual consistency flags for this entity.
  final List<ConsistencyFlag> flags;

  EntityConsistencyResult copyWith({
    String? entityName,
    String? entityType,
    int? chaptersWhereMentioned,
    double? consistencyScore,
    List<ConsistencyFlag>? flags,
  }) {
    return EntityConsistencyResult(
      entityName: entityName ?? this.entityName,
      entityType: entityType ?? this.entityType,
      chaptersWhereMentioned:
          chaptersWhereMentioned ?? this.chaptersWhereMentioned,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      flags: flags ?? this.flags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityConsistencyResult &&
          runtimeType == other.runtimeType &&
          entityName == other.entityName &&
          entityType == other.entityType &&
          chaptersWhereMentioned == other.chaptersWhereMentioned &&
          consistencyScore == other.consistencyScore &&
          _listEquals(flags, other.flags);

  @override
  int get hashCode =>
      entityName.hashCode ^
      entityType.hashCode ^
      chaptersWhereMentioned.hashCode ^
      consistencyScore.hashCode;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Knowledge base consistency analysis report.
///
/// Compares character cards and world settings against actual chapter
/// content, tracking consistency drift across the 100-chapter journey.
class ConsistencyReport {
  ConsistencyReport({
    required this.characterResults,
    required this.settingResults,
    required this.overallConsistencyScore,
    required this.driftPerSegment,
  });

  /// Consistency results for each character.
  final List<EntityConsistencyResult> characterResults;

  /// Consistency results for each world setting.
  final List<EntityConsistencyResult> settingResults;

  /// Overall consistency score from 0.0 to 1.0.
  final double overallConsistencyScore;

  /// Consistency score per 10-chapter segment (10 values for 100 chapters).
  /// Shows how consistency drifts over the course of the novel.
  final List<double> driftPerSegment;

  ConsistencyReport copyWith({
    List<EntityConsistencyResult>? characterResults,
    List<EntityConsistencyResult>? settingResults,
    double? overallConsistencyScore,
    List<double>? driftPerSegment,
  }) {
    return ConsistencyReport(
      characterResults: characterResults ?? this.characterResults,
      settingResults: settingResults ?? this.settingResults,
      overallConsistencyScore:
          overallConsistencyScore ?? this.overallConsistencyScore,
      driftPerSegment: driftPerSegment ?? this.driftPerSegment,
    );
  }
}
