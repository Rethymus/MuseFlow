import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing Fragment entities in a Hive box.
///
/// Provides CRUD operations over fragments stored in local Hive storage.
class FragmentRepository {
  final Box<Fragment> _box;
  final _uuid = const Uuid();

  FragmentRepository(this._box);

  /// Adds a new fragment with auto-generated ID and timestamp.
  ///
  /// Returns the created Fragment with id and createdAt set.
  Fragment addFragment(String text, {List<String>? tags}) {
    final now = DateTime.now();
    final fragment = Fragment(
      id: _uuid.v4(),
      text: text,
      tags: tags ?? [],
      createdAt: now,
    );
    _box.put(fragment.id, fragment);
    return fragment;
  }

  /// Returns all fragments in the box.
  List<Fragment> getAllFragments() {
    return _box.values.toList();
  }

  /// Deletes a fragment by its ID.
  Future<void> deleteFragment(String id) async {
    await _box.delete(id);
  }

  /// Returns fragments that have the specified tag.
  List<Fragment> getFragmentsByTag(String tag) {
    return _box.values
        .where((fragment) => fragment.tags.contains(tag))
        .toList();
  }

  /// Updates an existing fragment.
  Future<void> updateFragment(Fragment fragment) async {
    await _box.put(fragment.id, fragment);
  }
}
