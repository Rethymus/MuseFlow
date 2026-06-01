import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/application/fragment_service.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/presentation/providers.dart';

/// State for the capture page.
///
/// Tracks the fragment list, selection state, active filter, and loading status.
class CaptureState {
  final List<Fragment> fragments;
  final Set<String> selectedIds;
  final String activeFilter;
  final bool isLoading;

  const CaptureState({
    this.fragments = const [],
    this.selectedIds = const {},
    this.activeFilter = '全部',
    this.isLoading = true,
  });

  CaptureState copyWith({
    List<Fragment>? fragments,
    Set<String>? selectedIds,
    String? activeFilter,
    bool? isLoading,
  }) {
    return CaptureState(
      fragments: fragments ?? this.fragments,
      selectedIds: selectedIds ?? this.selectedIds,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier managing capture page state using Riverpod 3.x Notifier.
///
/// Handles fragment CRUD, tag filtering, and multi-select.
/// Initializes from the FragmentRepository FutureProvider.
class CaptureNotifier extends Notifier<CaptureState> {
  @override
  CaptureState build() {
    // Listen to the async repository -- once available, load fragments
    final repositoryAsync = ref.watch(fragmentRepositoryProvider);
    repositoryAsync.whenData((repository) {
      _loadFragments(FragmentService(repository));
    });
    return const CaptureState();
  }

  FragmentService? _service;

  void _loadFragments(FragmentService service) {
    _service = service;
    final fragments = service.listFragmentsByTag(state.activeFilter);
    state = state.copyWith(fragments: fragments, isLoading: false);
  }

  /// Reloads fragments using the current service and filter.
  void _reload() {
    if (_service == null) return;
    final fragments = _service!.listFragmentsByTag(state.activeFilter);
    state = state.copyWith(fragments: fragments, isLoading: false);
  }

  /// Adds a new fragment with the given text and optional tags.
  void addFragment(String text, {List<String>? tags}) {
    if (_service == null) return;
    _service!.createFragment(text, tags: tags);
    _reload();
  }

  /// Removes a fragment by ID and reloads the list.
  Future<void> deleteFragment(String id) async {
    if (_service == null) return;
    await _service!.removeFragment(id);
    final newSelected = Set<String>.of(state.selectedIds)..remove(id);
    state = state.copyWith(selectedIds: newSelected);
    _reload();
  }

  /// Toggles selection state for a fragment.
  void toggleSelect(String id) {
    final newSelected = Set<String>.of(state.selectedIds);
    if (newSelected.contains(id)) {
      newSelected.remove(id);
    } else {
      newSelected.add(id);
    }
    state = state.copyWith(selectedIds: newSelected);
  }

  /// Selects all currently visible fragment IDs.
  void selectAll() {
    final allIds = state.fragments.map((f) => f.id).toSet();
    state = state.copyWith(selectedIds: allIds);
  }

  /// Clears the selection.
  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  /// Sets the active filter tag and reloads the filtered list.
  void setFilter(String tag) {
    state = state.copyWith(activeFilter: tag);
    _reload();
  }

  /// Updates the tags on a fragment.
  Future<void> updateTags(String id, List<String> tags) async {
    if (_service == null) return;
    await _service!.updateFragmentTags(id, tags);
    _reload();
  }
}

/// Provides the capture page state via [CaptureNotifier].
///
/// Watches [fragmentRepositoryProvider] and loads fragments once available.
final captureProvider = NotifierProvider<CaptureNotifier, CaptureState>(
  CaptureNotifier.new,
);

/// Simple notifier holding the input field text.
class CaptureInputNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

/// Controller for the fragment input TextField text.
final captureInputProvider =
    NotifierProvider<CaptureInputNotifier, String>(
  CaptureInputNotifier.new,
);

/// Simple notifier holding the active filter tag.
class FragmentFilterNotifier extends Notifier<String> {
  @override
  String build() => '全部';
}

/// Active filter tag state. Defaults to '全部' (All).
final fragmentFilterProvider =
    NotifierProvider<FragmentFilterNotifier, String>(
  FragmentFilterNotifier.new,
);

/// Computed provider returning fragments that are currently selected.
final selectedFragmentsProvider = Provider<List<Fragment>>((ref) {
  final captureState = ref.watch(captureProvider);
  final selectedIds = captureState.selectedIds;
  return captureState.fragments
      .where((f) => selectedIds.contains(f.id))
      .toList();
});
