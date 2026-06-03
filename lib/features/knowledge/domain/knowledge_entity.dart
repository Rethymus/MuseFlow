import 'package:museflow/features/knowledge/domain/entity_type.dart';

/// Abstract contract for all knowledge base entities.
///
/// Knowledge entities are the objects that get injected into AI prompts
/// during writing. The [toContextString] method produces the formatted
/// text that the AI model receives.
///
/// All implementations must be immutable with [copyWith] support.
abstract class KnowledgeEntity {
  /// Display name shown in UI lists and search results.
  String get displayName;

  /// The type classification of this entity.
  EntityType get entityType;

  /// All names this entity is known by, including aliases.
  ///
  /// Used for search matching and AI context reference resolution.
  /// First element is always [displayName], followed by aliases.
  List<String> get allNames;

  /// Formatted multi-line string for AI prompt injection.
  ///
  /// Each entity type formats differently:
  /// - CharacterCard: personality, appearance, backstory
  /// - WorldSetting: rules, factions, geography, techLevel
  String get toContextString;
}
