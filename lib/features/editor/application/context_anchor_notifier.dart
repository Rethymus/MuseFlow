/// Notifier managing the list of active context anchors.
///
/// Provides add, remove, and clear operations for context anchors.
/// Registered as a Riverpod Notifier provider.
///
/// Per D-12: Persistent anchors remain until manually removed;
/// one-time anchors are cleared after each AI operation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/features/editor/domain/context_anchor.dart';

/// Maximum number of active anchors allowed (T-03-07: DoS prevention).
const maxActiveAnchors = 10;

/// Notifier managing the list of active context anchors.
class ContextAnchorNotifier extends Notifier<List<ContextAnchor>> {
  @override
  List<ContextAnchor> build() => [];

  /// Adds an anchor to the active list.
  ///
  /// Returns `true` if added, `false` if the maximum limit is reached.
  bool add(ContextAnchor anchor) {
    if (state.length >= maxActiveAnchors) return false;
    state = [...state, anchor];
    return true;
  }

  /// Removes an anchor by its ID.
  void remove(String anchorId) {
    state = state.where((a) => a.id != anchorId).toList();
  }

  /// Clears all one-time anchors (isPersistent == false).
  ///
  /// Called after an AI operation completes per D-12.
  void clearOneTime() {
    state = state.where((a) => a.isPersistent).toList();
  }

  /// Clears all anchors.
  void clear() {
    state = [];
  }
}

/// Provider for the context anchor notifier.
final contextAnchorNotifierProvider =
    NotifierProvider<ContextAnchorNotifier, List<ContextAnchor>>(
  ContextAnchorNotifier.new,
);
