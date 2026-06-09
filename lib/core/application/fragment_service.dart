import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/core/infrastructure/fragment_repository.dart';

/// Application-layer use case for fragment operations.
///
/// Orchestrates CRUD operations between the presentation layer
/// and the FragmentRepository. Handles sorting, filtering, and
/// tag management logic.
class FragmentService {
  final FragmentRepository _repository;

  FragmentService(this._repository);

  /// Creates a new fragment with the given text and optional tags.
  Future<Fragment> createFragment(String text, {List<String>? tags}) async {
    return _repository.addFragment(text, tags: tags);
  }

  /// Returns all fragments sorted by createdAt descending (newest first).
  List<Fragment> listFragments() {
    final fragments = List<Fragment>.of(_repository.getAllFragments());
    fragments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return fragments;
  }

  /// Returns fragments filtered by tag.
  ///
  /// If [tag] is '全部' (All), returns all fragments sorted by createdAt.
  /// Otherwise delegates to the repository's getFragmentsByTag.
  List<Fragment> listFragmentsByTag(String tag) {
    if (tag == '全部') {
      return listFragments();
    }
    final fragments = List<Fragment>.of(_repository.getFragmentsByTag(tag));
    fragments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return fragments;
  }

  /// Removes a fragment by its ID.
  Future<void> removeFragment(String id) async {
    await _repository.deleteFragment(id);
  }

  /// Updates the tags on a fragment.
  ///
  /// Sets updatedAt to DateTime.now() to track the modification.
  Future<void> updateFragmentTags(String id, List<String> tags) async {
    final fragments = _repository.getAllFragments();
    final fragment = fragments.firstWhere(
      (f) => f.id == id,
      orElse: () => throw StateError('Fragment not found: $id'),
    );
    final updated = fragment.copyWith(tags: tags, updatedAt: DateTime.now());
    await _repository.updateFragment(updated);
  }

  /// Returns the default tag list for filter chips.
  List<String> getDefaultTags() {
    return FragmentTags.defaults;
  }
}
