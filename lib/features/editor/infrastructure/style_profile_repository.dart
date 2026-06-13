/// Repository for persisting [AuthorStyleProfile] entities in Hive.
///
/// One profile per manuscript, keyed by manuscriptId.
library;

import 'package:hive_ce/hive.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';

/// Repository for [AuthorStyleProfile] persistence.
///
/// Uses a Hive box named 'style_profiles'. Each entry is keyed by
/// manuscriptId and stores the profile as a JSON map.
class StyleProfileRepository {
  final Box<dynamic> _box;

  StyleProfileRepository(this._box);

  /// Returns the style profile for the given manuscript, or null.
  AuthorStyleProfile? getByManuscript(String manuscriptId) {
    try {
      final json = _box.get(manuscriptId);
      if (json == null) return null;
      return AuthorStyleProfile.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      throw StateError('Failed to read style profile for $manuscriptId: $e');
    }
  }

  /// Saves (inserts or updates) a style profile.
  Future<void> save(AuthorStyleProfile profile) async {
    try {
      await _box.put(profile.manuscriptId, profile.toJson());
    } catch (e) {
      throw StateError(
        'Failed to save style profile for ${profile.manuscriptId}: $e',
      );
    }
  }

  /// Deletes the style profile for the given manuscript.
  ///
  /// Does not throw if the manuscriptId does not exist.
  Future<void> delete(String manuscriptId) async {
    try {
      await _box.delete(manuscriptId);
    } catch (e) {
      throw StateError('Failed to delete style profile for $manuscriptId: $e');
    }
  }

  /// Returns all stored style profiles.
  List<AuthorStyleProfile> getAll() {
    try {
      return _box.values
          .map(
            (json) => AuthorStyleProfile.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw StateError('Failed to read style profiles: $e');
    }
  }
}
