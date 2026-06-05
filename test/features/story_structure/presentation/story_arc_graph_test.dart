import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_notifier.dart';
import 'package:museflow/features/story_structure/application/node_position_notifier.dart';
import 'package:museflow/features/story_structure/application/plot_node_notifier.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/presentation/story_arc/story_arc_graph.dart';
import 'package:museflow/features/story_structure/presentation/story_structure_page.dart';

void main() {
  PlotNode node({
    required String id,
    String title = '初遇',
    List<String> consequenceNodeIds = const [],
  }) {
    return PlotNode(
      id: id,
      title: title,
      chapter: 1,
      consequenceNodeIds: consequenceNodeIds,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  testWidgets('should show empty graph state when no plot nodes exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          plotNodeNotifierProvider.overrideWith(
            () => _FakePlotNodeNotifier([]),
          ),
          nodePositionNotifierProvider.overrideWith(
            () => _FakeNodePositionNotifier(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: StoryArcGraph())),
      ),
    );
    await tester.pump();

    expect(find.text('暂无剧情节点'), findsOneWidget);
    expect(find.text('创建情节点来可视化你的故事弧线结构'), findsOneWidget);
    expect(find.text('创建第一个节点'), findsOneWidget);
  });

  testWidgets('should render plot nodes in graph', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          plotNodeNotifierProvider.overrideWith(
            () => _FakePlotNodeNotifier([
              node(id: 'pn-1', consequenceNodeIds: ['pn-2']),
              node(id: 'pn-2', title: '高潮节点'),
            ]),
          ),
          nodePositionNotifierProvider.overrideWith(
            () => _FakeNodePositionNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, height: 600, child: StoryArcGraph()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('初遇'), findsOneWidget);
    expect(find.text('高潮节点'), findsOneWidget);
  });
  testWidgets('should rebuild FAB for graph and guardian tab changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foreshadowingNotifierProvider.overrideWith(
            () => _FakeForeshadowingNotifier(),
          ),
          plotNodeNotifierProvider.overrideWith(
            () => _FakePlotNodeNotifier([]),
          ),
          nodePositionNotifierProvider.overrideWith(
            () => _FakeNodePositionNotifier(),
          ),
        ],
        child: const MaterialApp(home: StoryStructurePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('新建伏笔'), findsOneWidget);

    await tester.tap(find.text('弧线图'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('新建情节点'), findsOneWidget);

    await tester.tap(find.text('守护'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('新建情节点'), findsNothing);
  });
}

class _FakeForeshadowingNotifier extends ForeshadowingNotifier {
  @override
  Future<List<ForeshadowingEntry>> build() async => const [];
}

class _FakePlotNodeNotifier extends PlotNodeNotifier {
  final List<PlotNode> nodes;

  _FakePlotNodeNotifier(this.nodes);

  @override
  Future<List<PlotNode>> build() async => nodes;
}

class _FakeNodePositionNotifier extends NodePositionNotifier {
  @override
  Future<Map<String, Offset>> build() async => const {};
}
