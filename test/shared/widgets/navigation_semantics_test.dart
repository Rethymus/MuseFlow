/// Ground-truth semantics checks for the navigation chrome: each
/// destination must expose SemanticsAction.tap at the Flutter level so
/// assistive technologies (screen readers, UIA InvokePattern clients)
/// can activate it — regardless of what any single OS bridge surfaces.
library;

import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/shared/theme/app_theme.dart';
import 'package:museflow/shared/widgets/app_sidebar.dart';
import 'package:museflow/shared/widgets/app_tab_bar.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: appTheme(Brightness.dark),
    home: Scaffold(body: child),
  );

  testWidgets('sidebar destination exposes label + tap action', (tester) async {
    var tapped = false;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        AppSidebar(
          selectedIndex: 0,
          destinations: const [
            AppSidebarDestination(icon: Icons.bolt_outlined, label: '捕捉器'),
            AppSidebarDestination(icon: Icons.settings_outlined, label: '设置'),
          ],
          onDestinationSelected: (_) => tapped = true,
        ),
      ),
    );

    await tester.pump();
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^设置')).first,
    );
    final data = node.getSemanticsData();
    expect(
      data.hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'Semantics(onTap:) must expose the tap action',
    );

    // Activating the semantic action must invoke the callback.
    // The deprecated accessor is the one bound to the test's widget tree;
    // rootPipelineOwner's owner is a different instance in test env.
    // ignore: deprecated_member_use
    final owner = tester.binding.pipelineOwner.semanticsOwner!;
    owner.performAction(node.id, SemanticsAction.tap);
    expect(tapped, isTrue);
    handle.dispose();
  });

  testWidgets('tab destination exposes label + tap action', (tester) async {
    var tapped = false;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        AppTabBar(
          selectedIndex: 0,
          destinations: const [
            AppSidebarDestination(icon: Icons.bolt_outlined, label: '捕捉'),
            AppSidebarDestination(icon: Icons.settings_outlined, label: '文稿'),
          ],
          onDestinationSelected: (_) => tapped = true,
        ),
      ),
    );

    await tester.pump();
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^文稿')).first,
    );
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'Semantics(onTap:) must expose the tap action',
    );

    // The deprecated accessor is the one bound to the test's widget tree;
    // rootPipelineOwner's owner is a different instance in test env.
    // ignore: deprecated_member_use
    final owner = tester.binding.pipelineOwner.semanticsOwner!;
    owner.performAction(node.id, SemanticsAction.tap);
    expect(tapped, isTrue);
    handle.dispose();
  });

  testWidgets('sidebar selected destination carries selected state', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AppSidebar(
          selectedIndex: 1,
          destinations: const [
            AppSidebarDestination(icon: Icons.bolt_outlined, label: '捕捉器'),
            AppSidebarDestination(icon: Icons.settings_outlined, label: '设置'),
          ],
          onDestinationSelected: (_) {},
        ),
      ),
    );

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        AppSidebar(
          selectedIndex: 1,
          destinations: const [
            AppSidebarDestination(icon: Icons.bolt_outlined, label: '捕捉器'),
            AppSidebarDestination(icon: Icons.settings_outlined, label: '设置'),
          ],
          onDestinationSelected: (_) {},
        ),
      ),
    );
    await tester.pump();
    final data = tester
        .getSemantics(find.bySemanticsLabel(RegExp('^设置')).first)
        .getSemanticsData();
    expect(
      data.flagsCollection.isSelected,
      isNot(Tristate.none),
      reason: 'selected state must be observable by assistive tech',
    );
    handle.dispose();
  });
}
