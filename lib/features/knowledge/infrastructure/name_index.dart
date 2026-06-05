import 'package:museflow/features/knowledge/domain/entity_match.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';

/// In-memory index from entity names/aliases to knowledge entity IDs.
class NameIndex {
  final Map<String, List<String>> _nameToIds = {};
  final Map<String, EntityType> _idToType = {};

  void addEntity(String id, EntityType type, List<String> names) {
    if (id.isEmpty) return;
    _idToType[id] = type;
    for (final rawName in names) {
      final name = rawName.trim();
      if (name.runes.length < 2) continue;
      final ids = _nameToIds.putIfAbsent(name, () => <String>[]);
      if (!ids.contains(id)) ids.add(id);
    }
  }

  void removeEntity(String id) {
    _idToType.remove(id);
    final emptyNames = <String>[];
    for (final entry in _nameToIds.entries) {
      entry.value.remove(id);
      if (entry.value.isEmpty) emptyNames.add(entry.key);
    }
    for (final name in emptyNames) {
      _nameToIds.remove(name);
    }
  }

  void clear() {
    _nameToIds.clear();
    _idToType.clear();
  }

  EntityType? typeOf(String id) => _idToType[id];

  Set<String> get allEntityIds => _idToType.keys.toSet();

  List<EntityMatch> findMatches(String text) {
    if (text.isEmpty || _nameToIds.isEmpty) return const [];

    final matches = <EntityMatch>[];
    for (final entry in _nameToIds.entries) {
      final name = entry.key;
      var start = 0;
      while (start < text.length) {
        final index = text.indexOf(name, start);
        if (index == -1) break;
        for (final id in entry.value) {
          final type = _idToType[id];
          if (type == null) continue;
          matches.add(
            EntityMatch(
              entityId: id,
              entityType: type,
              entityName: name,
              position: index,
              length: name.length,
            ),
          );
        }
        start = index + name.length;
      }
    }

    matches.sort((a, b) {
      final byPosition = a.position.compareTo(b.position);
      if (byPosition != 0) return byPosition;
      return b.length.compareTo(a.length);
    });
    return matches;
  }
}
