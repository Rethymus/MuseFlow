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

/// A review signal that points the author to a chapter worth checking.
class NarrativeQualitySignal {
  const NarrativeQualitySignal({
    required this.chapterIndex,
    required this.category,
    required this.title,
    required this.evidence,
    required this.suggestion,
    required this.severity,
  });

  /// Zero-based chapter index in the analyzed manuscript.
  final int chapterIndex;

  /// Signal group, for example immersion, character, style, or setting.
  final String category;

  /// Short author-facing label.
  final String title;

  /// Local evidence that triggered the signal.
  final String evidence;

  /// Author-facing review suggestion. This should not rewrite prose.
  final String suggestion;

  /// Severity of the signal.
  final DeviationSeverity severity;

  NarrativeQualitySignal copyWith({
    int? chapterIndex,
    String? category,
    String? title,
    String? evidence,
    String? suggestion,
    DeviationSeverity? severity,
  }) {
    return NarrativeQualitySignal(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      category: category ?? this.category,
      title: title ?? this.title,
      evidence: evidence ?? this.evidence,
      suggestion: suggestion ?? this.suggestion,
      severity: severity ?? this.severity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeQualitySignal &&
          runtimeType == other.runtimeType &&
          chapterIndex == other.chapterIndex &&
          category == other.category &&
          title == other.title &&
          evidence == other.evidence &&
          suggestion == other.suggestion &&
          severity == other.severity;

  @override
  int get hashCode =>
      chapterIndex.hashCode ^
      category.hashCode ^
      title.hashCode ^
      evidence.hashCode ^
      suggestion.hashCode ^
      severity.hashCode;
}

/// Local, deterministic narrative quality summary for creator review.
class NarrativeQualitySnapshot {
  const NarrativeQualitySnapshot({
    required this.immersionScore,
    required this.characterAnchoringScore,
    required this.antiAiScentScore,
    required this.signals,
  });

  const NarrativeQualitySnapshot.empty()
    : immersionScore = 0.0,
      characterAnchoringScore = 0.0,
      antiAiScentScore = 0.0,
      signals = const [];

  /// Higher means chapters include more concrete scene/action/sensory anchors.
  final double immersionScore;

  /// Higher means character mentions are more often supported by behavior,
  /// emotion, relation, or voice clues.
  final double characterAnchoringScore;

  /// Higher means fewer generic AI-scent phrases were detected.
  final double antiAiScentScore;

  /// Ordered review signals for the author.
  final List<NarrativeQualitySignal> signals;

  NarrativeQualitySnapshot copyWith({
    double? immersionScore,
    double? characterAnchoringScore,
    double? antiAiScentScore,
    List<NarrativeQualitySignal>? signals,
  }) {
    return NarrativeQualitySnapshot(
      immersionScore: immersionScore ?? this.immersionScore,
      characterAnchoringScore:
          characterAnchoringScore ?? this.characterAnchoringScore,
      antiAiScentScore: antiAiScentScore ?? this.antiAiScentScore,
      signals: signals ?? this.signals,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeQualitySnapshot &&
          runtimeType == other.runtimeType &&
          immersionScore == other.immersionScore &&
          characterAnchoringScore == other.characterAnchoringScore &&
          antiAiScentScore == other.antiAiScentScore &&
          EntityConsistencyResult._listEquals(signals, other.signals);

  @override
  int get hashCode =>
      immersionScore.hashCode ^
      characterAnchoringScore.hashCode ^
      antiAiScentScore.hashCode;
}

/// A local signal that adjacent chapter memory may be stale or underused.
class ChapterMemoryFreshnessSignal {
  const ChapterMemoryFreshnessSignal({
    required this.chapterIndex,
    required this.direction,
    required this.summary,
    required this.overlapScore,
    required this.missingTerms,
    required this.evidence,
    required this.suggestion,
    required this.severity,
  });

  /// Zero-based chapter index being reviewed.
  final int chapterIndex;

  /// Adjacent memory direction: previous or next.
  final String direction;

  /// Local memory preview derived from the adjacent chapter.
  final String summary;

  /// Term overlap score from 0.0 to 1.0.
  final double overlapScore;

  /// Meaningful terms present in the memory preview but absent locally.
  final List<String> missingTerms;

  /// Local evidence that triggered this signal.
  final String evidence;

  /// Author-facing review suggestion.
  final String suggestion;

  /// Severity of the signal.
  final DeviationSeverity severity;

  ChapterMemoryFreshnessSignal copyWith({
    int? chapterIndex,
    String? direction,
    String? summary,
    double? overlapScore,
    List<String>? missingTerms,
    String? evidence,
    String? suggestion,
    DeviationSeverity? severity,
  }) {
    return ChapterMemoryFreshnessSignal(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      direction: direction ?? this.direction,
      summary: summary ?? this.summary,
      overlapScore: overlapScore ?? this.overlapScore,
      missingTerms: missingTerms ?? this.missingTerms,
      evidence: evidence ?? this.evidence,
      suggestion: suggestion ?? this.suggestion,
      severity: severity ?? this.severity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterMemoryFreshnessSignal &&
          runtimeType == other.runtimeType &&
          chapterIndex == other.chapterIndex &&
          direction == other.direction &&
          summary == other.summary &&
          overlapScore == other.overlapScore &&
          EntityConsistencyResult._listEquals(
            missingTerms,
            other.missingTerms,
          ) &&
          evidence == other.evidence &&
          suggestion == other.suggestion &&
          severity == other.severity;

  @override
  int get hashCode =>
      chapterIndex.hashCode ^
      direction.hashCode ^
      summary.hashCode ^
      overlapScore.hashCode ^
      evidence.hashCode ^
      suggestion.hashCode ^
      severity.hashCode;
}

/// Local snapshot of whether adjacent chapter memory appears usable.
class ChapterMemoryFreshnessSnapshot {
  const ChapterMemoryFreshnessSnapshot({
    required this.averageOverlapScore,
    required this.staleSummaryCount,
    required this.signals,
  });

  const ChapterMemoryFreshnessSnapshot.empty()
    : averageOverlapScore = 0.0,
      staleSummaryCount = 0,
      signals = const [];

  /// Average adjacent-memory overlap score. Higher means healthier.
  final double averageOverlapScore;

  /// Number of adjacent memory previews that need author review.
  final int staleSummaryCount;

  /// Ordered review signals for the author.
  final List<ChapterMemoryFreshnessSignal> signals;

  ChapterMemoryFreshnessSnapshot copyWith({
    double? averageOverlapScore,
    int? staleSummaryCount,
    List<ChapterMemoryFreshnessSignal>? signals,
  }) {
    return ChapterMemoryFreshnessSnapshot(
      averageOverlapScore: averageOverlapScore ?? this.averageOverlapScore,
      staleSummaryCount: staleSummaryCount ?? this.staleSummaryCount,
      signals: signals ?? this.signals,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterMemoryFreshnessSnapshot &&
          runtimeType == other.runtimeType &&
          averageOverlapScore == other.averageOverlapScore &&
          staleSummaryCount == other.staleSummaryCount &&
          EntityConsistencyResult._listEquals(signals, other.signals);

  @override
  int get hashCode => averageOverlapScore.hashCode ^ staleSummaryCount.hashCode;
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
    this.narrativeQuality = const NarrativeQualitySnapshot.empty(),
    this.memoryFreshness = const ChapterMemoryFreshnessSnapshot.empty(),
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

  /// Creator-facing local quality signals for reviewing narrative strength.
  final NarrativeQualitySnapshot narrativeQuality;

  /// Adjacent chapter memory freshness review for long-form continuity.
  final ChapterMemoryFreshnessSnapshot memoryFreshness;

  ConsistencyReport copyWith({
    List<EntityConsistencyResult>? characterResults,
    List<EntityConsistencyResult>? settingResults,
    double? overallConsistencyScore,
    List<double>? driftPerSegment,
    NarrativeQualitySnapshot? narrativeQuality,
    ChapterMemoryFreshnessSnapshot? memoryFreshness,
  }) {
    return ConsistencyReport(
      characterResults: characterResults ?? this.characterResults,
      settingResults: settingResults ?? this.settingResults,
      overallConsistencyScore:
          overallConsistencyScore ?? this.overallConsistencyScore,
      driftPerSegment: driftPerSegment ?? this.driftPerSegment,
      narrativeQuality: narrativeQuality ?? this.narrativeQuality,
      memoryFreshness: memoryFreshness ?? this.memoryFreshness,
    );
  }
}
