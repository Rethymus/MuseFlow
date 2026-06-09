import 'package:museflow/features/knowledge/domain/entity_type.dart';

/// Match result returned by [NameIndex] when a knowledge entity name appears
/// in user text.
class EntityMatch {
  final String entityId;
  final EntityType entityType;
  final String entityName;
  final int position;
  final int length;

  const EntityMatch({
    required this.entityId,
    required this.entityType,
    required this.entityName,
    required this.position,
    required this.length,
  });

  EntityMatch copyWith({
    String? entityId,
    EntityType? entityType,
    String? entityName,
    int? position,
    int? length,
  }) {
    return EntityMatch(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      entityName: entityName ?? this.entityName,
      position: position ?? this.position,
      length: length ?? this.length,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityMatch &&
          runtimeType == other.runtimeType &&
          entityId == other.entityId &&
          entityType == other.entityType &&
          entityName == other.entityName &&
          position == other.position &&
          length == other.length;

  @override
  int get hashCode =>
      Object.hash(entityId, entityType, entityName, position, length);
}
