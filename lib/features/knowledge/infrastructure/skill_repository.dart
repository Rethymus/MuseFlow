import 'package:hive_ce/hive.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:uuid/uuid.dart';

class SkillRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  SkillRepository(this._box);

  Future<SkillDocument> add(SkillDocument document) async {
    try {
      final id = document.id.isEmpty ? _uuid.v4() : document.id;
      final saved = document.copyWith(id: id, createdAt: DateTime.now());
      await _box.put(id, saved.toJson());
      return saved;
    } catch (e) {
      throw StateError('Failed to save skill document: $e');
    }
  }

  List<SkillDocument> getAll() {
    try {
      return _box.values
          .map(
            (json) =>
                SkillDocument.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e) {
      throw StateError('Failed to read skill documents: $e');
    }
  }

  SkillDocument? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return SkillDocument.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (e) {
      throw StateError('Failed to read skill document $id: $e');
    }
  }

  List<SkillDocument> getActive() {
    return getAll().where((document) => document.isActive).toList();
  }

  Future<void> update(SkillDocument document) async {
    try {
      await _box.put(
        document.id,
        document.copyWith(updatedAt: DateTime.now()).toJson(),
      );
    } catch (e) {
      throw StateError('Failed to update skill document ${document.id}: $e');
    }
  }

  Future<void> setActive(String id, bool isActive) async {
    final document = getById(id);
    if (document == null) return;
    await update(document.copyWith(isActive: isActive));
  }

  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete skill document $id: $e');
    }
  }
}
