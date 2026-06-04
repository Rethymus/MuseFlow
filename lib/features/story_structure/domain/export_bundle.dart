import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

/// Complete export bundle containing manuscript text and all structured story data.
///
/// Per FRMT-04: JSON export includes manuscript text plus foreshadowing entries,
/// plot nodes, guardian annotations, character cards, world settings, skill
/// documents, active skill IDs, and metadata.
///
/// This is the data contract for all export formats. TXT and Markdown use
/// only the manuscript text; JSON includes the full bundle.
class ExportBundle {
  /// Schema version for forward-compatible migration.
  final String schemaVersion;

  /// Timestamp of export generation.
  final DateTime? exportedAt;

  /// The manuscript text content.
  final String manuscriptText;

  /// All foreshadowing entries.
  final List<ForeshadowingEntry> foreshadowingEntries;

  /// All plot nodes.
  final List<PlotNode> plotNodes;

  /// All guardian annotations.
  final List<GuardianAnnotation> guardianAnnotations;

  /// Character card data as JSON maps.
  final List<Map<String, dynamic>> characterCards;

  /// World setting data as JSON maps.
  final List<Map<String, dynamic>> worldSettings;

  /// Skill document data as JSON maps.
  final List<Map<String, dynamic>> skillDocuments;

  /// IDs of currently active skills.
  final List<String> activeSkillIds;

  /// Additional metadata (app version, etc.).
  final Map<String, dynamic> metadata;

  const ExportBundle({
    required this.schemaVersion,
    this.exportedAt,
    required this.manuscriptText,
    this.foreshadowingEntries = const [],
    this.plotNodes = const [],
    this.guardianAnnotations = const [],
    this.characterCards = const [],
    this.worldSettings = const [],
    this.skillDocuments = const [],
    this.activeSkillIds = const [],
    this.metadata = const {},
  });

  /// Creates an ExportBundle from a JSON map.
  factory ExportBundle.fromJson(Map<String, dynamic> json) {
    return ExportBundle(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      exportedAt: json['exportedAt'] != null
          ? DateTime.parse(json['exportedAt'] as String)
          : null,
      manuscriptText: json['manuscriptText'] as String? ?? '',
      foreshadowingEntries: (json['foreshadowingEntries'] as List<dynamic>)
          .map((e) => ForeshadowingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      plotNodes: (json['plotNodes'] as List<dynamic>)
          .map((e) => PlotNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      guardianAnnotations: (json['guardianAnnotations'] as List<dynamic>)
          .map(
              (e) => GuardianAnnotation.fromJson(e as Map<String, dynamic>))
          .toList(),
      characterCards: (json['characterCards'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      worldSettings: (json['worldSettings'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      skillDocuments: (json['skillDocuments'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      activeSkillIds:
          (json['activeSkillIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Serializes this bundle to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt?.toIso8601String(),
      'manuscriptText': manuscriptText,
      'foreshadowingEntries':
          foreshadowingEntries.map((e) => e.toJson()).toList(),
      'plotNodes': plotNodes.map((e) => e.toJson()).toList(),
      'guardianAnnotations':
          guardianAnnotations.map((e) => e.toJson()).toList(),
      'characterCards': characterCards,
      'worldSettings': worldSettings,
      'skillDocuments': skillDocuments,
      'activeSkillIds': activeSkillIds,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportBundle &&
        other.schemaVersion == schemaVersion &&
        other.exportedAt == exportedAt &&
        other.manuscriptText == manuscriptText &&
        _listEquals(other.foreshadowingEntries, foreshadowingEntries) &&
        _listEquals(other.plotNodes, plotNodes) &&
        _listEquals(other.guardianAnnotations, guardianAnnotations) &&
        _mapListEquals(other.characterCards, characterCards) &&
        _mapListEquals(other.worldSettings, worldSettings) &&
        _mapListEquals(other.skillDocuments, skillDocuments) &&
        _listEquals(other.activeSkillIds, activeSkillIds) &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        exportedAt,
        manuscriptText,
        Object.hashAll(foreshadowingEntries),
        Object.hashAll(plotNodes),
        Object.hashAll(guardianAnnotations),
        Object.hashAll(characterCards),
        Object.hashAll(worldSettings),
        Object.hashAll(skillDocuments),
        Object.hashAll(activeSkillIds),
        metadata,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapListEquals(
      List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_mapEquals(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
