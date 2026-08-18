import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/sidebar.dart';

/// D-7 follow-up: navigation destinations must be exposed to assistive tech.
///
/// Verification note: Flutter web CDP accessibility dumps initially showed
/// the on-screen rail with zero navigation semantics. Framework-level
/// inspection showed both the rail (role=button) and the bottom bar
/// (role=tab) DO expose labelled semantics nodes; the web observation was a
/// semantics-serialization/timing artifact (a page reload resets the
/// semantics enable-state). These tests pin the semantics contract by
/// walking the semantics tree directly, which works for both roles —
/// `find.bySemanticsLabel` does not match role=tab nodes.
void main() {
  testWidgets('extended rail exposes all six destination labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveSidebar(currentIndex: 1, onDestinationSelected: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = _collectLabels(tester);
    for (final label in ['捕捉器', '编辑器', '知识库', '故事结构', '统计', '设置']) {
      expect(
        _hasLabel(labels, label),
        isTrue,
        reason:
            'rail destination "$label" must be exposed to semantics '
            '(got: $labels)',
      );
    }
    handle.dispose();
  });

  testWidgets('bottom bar exposes the five primary destination labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 830);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AdaptiveSidebar(
            currentIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = _collectLabels(tester);
    for (final label in ['捕捉器', '编辑器', '知识库', '故事结构', '统计']) {
      expect(
        _hasLabel(labels, label),
        isTrue,
        reason:
            'bottom destination "$label" must be exposed to semantics '
            '(got: $labels)',
      );
    }
    handle.dispose();
  });
}

/// M3 appends tab-index announcements to labels ('捕捉器\nTab 1 of 5'),
/// so match on the label line rather than the whole string.
bool _hasLabel(Set<String> labels, String label) {
  return labels.any((l) => l == label || l.startsWith('$label\n'));
}

/// Walks the semantics tree and collects every non-empty node label.
Set<String> _collectLabels(WidgetTester tester) {
  final labels = <String>{};
  void walk(SemanticsNode? node) {
    if (node == null) return;
    if (node.label.isNotEmpty) {
      labels.add(node.label);
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  // ignore: deprecated_member_use
  walk(tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode);
  return labels;
}
