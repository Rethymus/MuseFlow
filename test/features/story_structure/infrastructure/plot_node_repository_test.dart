import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/infrastructure/plot_node_repository.dart';

void main() {
  late Box<dynamic> box;
  late PlotNodeRepository repository;

  setUp(() async {
    box = await Hive.openBox<dynamic>('test_plot_nodes');
    repository = PlotNodeRepository(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  group('PlotNodeRepository', () {
    final testNode = PlotNode(
      id: 'pn-1',
      title: 'Inciting incident',
      chapter: 1,
      summary: 'A stranger arrives',
      writingStatus: PlotNodeWritingStatus.drafting,
      structuralRole: PlotNodeStructuralRole.setup,
      manualOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    test('should add a plot node and retrieve it', () async {
      final added = await repository.add(testNode);

      expect(added.id, isNotEmpty);
      expect(added.title, 'Inciting incident');
      expect(added.createdAt, isNotNull);

      final retrieved = repository.getById(added.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Inciting incident');
    });

    test('should generate UUID when id is empty', () async {
      final noId = testNode.copyWith(id: '');
      final added = await repository.add(noId);

      expect(added.id, isNotEmpty);
      expect(added.id, isNot(equals('')));
    });

    test('should return all plot nodes', () async {
      await repository.add(testNode);
      await repository.add(testNode.copyWith(
        id: 'pn-2',
        title: 'Rising action',
        chapter: 3,
      ));

      final all = repository.getAll();
      expect(all, hasLength(2));
    });

    test('should update a plot node', () async {
      final added = await repository.add(testNode);
      await repository.update(added.copyWith(title: 'Updated title'));

      final retrieved = repository.getById(added.id);
      expect(retrieved!.title, 'Updated title');
      expect(retrieved.updatedAt, isNotNull);
    });

    test('should delete a plot node', () async {
      final added = await repository.add(testNode);
      await repository.delete(added.id);

      final retrieved = repository.getById(added.id);
      expect(retrieved, isNull);
    });

    test('should return null for non-existent ID', () {
      final result = repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('should get nodes by chapter', () async {
      await repository.add(testNode.copyWith(id: 'pn-1', chapter: 1));
      await repository.add(testNode.copyWith(id: 'pn-2', chapter: 1));
      await repository.add(testNode.copyWith(id: 'pn-3', chapter: 2));

      final chapter1 = repository.getByChapter(1);
      expect(chapter1, hasLength(2));

      final chapter2 = repository.getByChapter(2);
      expect(chapter2, hasLength(1));
    });

    test('should sort nodes by chapter then manualOrder', () async {
      await repository.add(testNode.copyWith(
        id: 'pn-b',
        title: 'Second',
        chapter: 1,
        manualOrder: 1,
      ));
      await repository.add(testNode.copyWith(
        id: 'pn-a',
        title: 'First',
        chapter: 1,
        manualOrder: 0,
      ));
      await repository.add(testNode.copyWith(
        id: 'pn-c',
        title: 'Third chapter',
        chapter: 2,
        manualOrder: 0,
      ));

      final sorted = repository.getAll();
      expect(sorted[0].title, 'First');
      expect(sorted[1].title, 'Second');
      expect(sorted[2].title, 'Third chapter');
    });

    test('should save order for a list of nodes', () async {
      final n1 = await repository.add(testNode.copyWith(id: 'pn-1', manualOrder: 0));
      final n2 = await repository.add(testNode.copyWith(id: 'pn-2', manualOrder: 1));

      await repository.saveOrder([n2.id, n1.id]);

      final all = repository.getAll();
      // After reorder, pn-2 should have lower manualOrder than pn-1
      final reordered = all.where((n) => n.chapter == n1.chapter).toList()
        ..sort((a, b) => a.manualOrder.compareTo(b.manualOrder));
      expect(reordered.first.id, 'pn-2');
      expect(reordered.last.id, 'pn-1');
    });
  });
}
