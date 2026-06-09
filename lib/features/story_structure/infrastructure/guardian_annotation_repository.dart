import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing [GuardianAnnotation] entities in a Hive box.
///
/// Provides CRUD operations with active-only queries and dismissal support.
class GuardianAnnotationRepository {
  final Box<dynamic> _box;
  final _uuid = const Uuid();

  GuardianAnnotationRepository(this._box);

  /// Adds a new guardian annotation to the box.
  ///
  /// If the annotation has an empty [id], a new UUID is generated.
  Future<GuardianAnnotation> add(GuardianAnnotation annotation) async {
    try {
      final id = annotation.id.isEmpty ? _uuid.v4() : annotation.id;
      final now = DateTime.now();
      final newAnnotation = GuardianAnnotation(
        id: id,
        kind: annotation.kind,
        severity: annotation.severity,
        message: annotation.message,
        reason: annotation.reason,
        suggestedFix: annotation.suggestedFix,
        nodeId: annotation.nodeId,
        startOffset: annotation.startOffset,
        endOffset: annotation.endOffset,
        sourceText: annotation.sourceText,
        createdAt: now,
        characterIds: annotation.characterIds,
        worldSettingIds: annotation.worldSettingIds,
        skillIds: annotation.skillIds,
        plotNodeIds: annotation.plotNodeIds,
        foreshadowingIds: annotation.foreshadowingIds,
      );
      await _box.put(id, newAnnotation.toJson());
      return newAnnotation;
    } catch (e) {
      throw StateError('Failed to save guardian annotation: $e');
    }
  }

  /// Returns all guardian annotations.
  List<GuardianAnnotation> getAll() {
    try {
      return _box.values
          .map(
            (json) => GuardianAnnotation.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw StateError('Failed to read guardian annotations: $e');
    }
  }

  /// Returns only active (not dismissed) annotations.
  List<GuardianAnnotation> getActive() {
    return getAll().where((a) => !a.isDismissed).toList();
  }

  /// Returns an annotation by its ID, or null if not found.
  GuardianAnnotation? getById(String id) {
    try {
      final json = _box.get(id);
      if (json == null) return null;
      return GuardianAnnotation.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read guardian annotation $id: $e');
    }
  }

  /// Updates an existing guardian annotation.
  Future<void> update(GuardianAnnotation annotation) async {
    try {
      await _box.put(annotation.id, annotation.toJson());
    } catch (e) {
      throw StateError(
        'Failed to update guardian annotation ${annotation.id}: $e',
      );
    }
  }

  /// Dismisses an annotation by setting [dismissedAt] to now.
  Future<void> dismiss(String id) async {
    try {
      final annotation = getById(id);
      if (annotation == null) return;
      final dismissed = annotation.copyWith(dismissedAt: DateTime.now());
      await _box.put(id, dismissed.toJson());
    } catch (e) {
      throw StateError('Failed to dismiss guardian annotation $id: $e');
    }
  }

  /// Deletes a guardian annotation by its ID.
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete guardian annotation $id: $e');
    }
  }

  /// Returns annotations related to a specific node ID.
  List<GuardianAnnotation> getByNodeId(String nodeId) {
    return getAll().where((a) => a.nodeId == nodeId).toList();
  }
}
