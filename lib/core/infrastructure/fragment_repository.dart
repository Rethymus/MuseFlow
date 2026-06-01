import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing Fragment entities in a Hive box.
///
/// Provides CRUD operations over fragments stored in local Hive storage.
/// All operations are wrapped in error handling to prevent silent failures.
class FragmentRepository {
  final Box<Fragment> _box;
  final _uuid = const Uuid();

  FragmentRepository(this._box);

  /// Adds a new fragment with auto-generated ID and timestamp.
  ///
  /// Returns the created Fragment with id and createdAt set.
  /// Throws [StateError] if the write fails.
  Future<Fragment> addFragment(String text, {List<String>? tags}) async {
    final now = DateTime.now();
    final fragment = Fragment(
      id: _uuid.v4(),
      text: text,
      tags: tags ?? [],
      createdAt: now,
    );
    try {
      await _box.put(fragment.id, fragment);
      return fragment;
    } catch (e) {
      throw StateError('Failed to save fragment: $e');
    }
  }

  /// Returns all fragments in the box.
  List<Fragment> getAllFragments() {
    try {
      return _box.values.toList();
    } catch (e) {
      throw StateError('Failed to read fragments: $e');
    }
  }

  /// Deletes a fragment by its ID.
  Future<void> deleteFragment(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StateError('Failed to delete fragment $id: $e');
    }
  }

  /// Returns fragments that have the specified tag.
  List<Fragment> getFragmentsByTag(String tag) {
    try {
      return _box.values
          .where((fragment) => fragment.tags.contains(tag))
          .toList();
    } catch (e) {
      throw StateError('Failed to query fragments by tag: $e');
    }
  }

  /// Updates an existing fragment.
  Future<void> updateFragment(Fragment fragment) async {
    try {
      await _box.put(fragment.id, fragment);
    } catch (e) {
      throw StateError('Failed to update fragment ${fragment.id}: $e');
    }
  }
}
