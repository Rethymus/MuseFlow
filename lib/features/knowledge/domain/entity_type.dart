/// Types of knowledge entities in the knowledge base.
///
/// Each type corresponds to a tab/section in the knowledge base UI
/// and determines how the entity is rendered in AI context injection.
enum EntityType {
  /// Character card -- personality, appearance, backstory.
  character('角色'),

  /// World setting -- rules, factions, geography, tech level.
  setting('世界观'),

  /// Skill / ability definition (future use).
  skill('技能');

  const EntityType(this.label);

  /// Chinese display label for UI.
  final String label;
}
