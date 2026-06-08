import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  late Box<dynamic> box;
  late ManuscriptRepository repository;

  setUp(() async {
    await setUpHiveTest();
    box = await Hive.openBox<dynamic>('test_manuscripts');
    repository = ManuscriptRepository(box);
  });

  tearDown(() async {
    await tearDownHiveTest();
  });

  Manuscript createManuscript({
    String id = '',
    String title = 'Test Manuscript',
    String genre = '玄幻',
    DateTime? deletedAt,
  }) {
    final now = DateTime.now();
    return Manuscript(
      id: id,
      title: title,
      genre: genre,
      createdAt: now,
      updatedAt: now,
      deletedAt: deletedAt,
    );
  }

  test('add creates manuscript with uuid if id empty, sets createdAt/updatedAt', () async {
    final manuscript = createManuscript(id: '');
    final result = await repository.add(manuscript);

    expect(result.id, isNotEmpty);
    expect(result.createdAt, isNotNull);
    expect(result.updatedAt, isNotNull);
    expect(result.title, equals('Test Manuscript'));

    // Verify stored in box
    final stored = box.get(result.id);
    expect(stored, isNotNull);
  });

  test('add preserves id if provided', () async {
    final manuscript = createManuscript(id: 'custom-id');
    final result = await repository.add(manuscript);

    expect(result.id, equals('custom-id'));
  });

  test('getAll returns only manuscripts where deletedAt is null', () async {
    final now = DateTime.now();
    final active = Manuscript(
      id: 'active',
      title: 'Active',
      genre: '玄幻',
      createdAt: now,
      updatedAt: now,
    );
    final deleted = Manuscript(
      id: 'deleted',
      title: 'Deleted',
      genre: '科幻',
      createdAt: now,
      updatedAt: now,
      deletedAt: now,
    );

    await box.put('active', active.toJson());
    await box.put('deleted', deleted.toJson());

    final results = repository.getAll();
    expect(results.length, equals(1));
    expect(results.first.id, equals('active'));
  });

  test('getById returns manuscript when found', () async {
    final manuscript = createManuscript(id: 'find-me');
    await box.put('find-me', manuscript.toJson());

    final result = repository.getById('find-me');
    expect(result, isNotNull);
    expect(result!.id, equals('find-me'));
  });

  test('getById returns null when not found', () {
    final result = repository.getById('nonexistent');
    expect(result, isNull);
  });

  test('update sets updatedAt and persists', () async {
    final manuscript = createManuscript(id: 'update-me');
    await box.put('update-me', manuscript.toJson());

    final updated = manuscript.copyWith(title: 'Updated Title');
    await repository.update(updated);

    final stored = repository.getById('update-me');
    expect(stored!.title, equals('Updated Title'));
  });

  test('delete removes manuscript from box', () async {
    final manuscript = createManuscript(id: 'delete-me');
    await box.put('delete-me', manuscript.toJson());

    await repository.delete('delete-me');

    final result = repository.getById('delete-me');
    expect(result, isNull);
  });

  test('softDelete sets deletedAt to DateTime.now() and updates entity', () async {
    final manuscript = createManuscript(id: 'soft-delete');
    await box.put('soft-delete', manuscript.toJson());

    await repository.softDelete('soft-delete');

    final stored = repository.getById('soft-delete');
    expect(stored!.deletedAt, isNotNull);

    // Should be filtered from getAll
    final all = repository.getAll();
    expect(all.where((m) => m.id == 'soft-delete'), isEmpty);
  });

  test('getAllIncludingDeleted returns all manuscripts including soft-deleted', () async {
    final now = DateTime.now();
    final active = Manuscript(
      id: 'active',
      title: 'Active',
      genre: '玄幻',
      createdAt: now,
      updatedAt: now,
    );
    final deleted = Manuscript(
      id: 'deleted',
      title: 'Deleted',
      genre: '科幻',
      createdAt: now,
      updatedAt: now,
      deletedAt: now,
    );

    await box.put('active', active.toJson());
    await box.put('deleted', deleted.toJson());

    final results = repository.getAllIncludingDeleted();
    expect(results.length, equals(2));
  });

  test('hardDelete permanently removes manuscript', () async {
    final manuscript = createManuscript(id: 'hard-delete');
    await box.put('hard-delete', manuscript.toJson());

    await repository.hardDelete('hard-delete');

    final result = repository.getById('hard-delete');
    expect(result, isNull);
  });

  test('purgeOlderThan hard-deletes manuscripts with deletedAt older than cutoff', () async {
    final now = DateTime.now();
    final oldDate = now.subtract(const Duration(days: 31));
    final recentDate = now.subtract(const Duration(days: 5));

    final old = Manuscript(
      id: 'old',
      title: 'Old',
      genre: '玄幻',
      createdAt: now,
      updatedAt: now,
      deletedAt: oldDate,
    );
    final recent = Manuscript(
      id: 'recent',
      title: 'Recent',
      genre: '科幻',
      createdAt: now,
      updatedAt: now,
      deletedAt: recentDate,
    );

    await box.put('old', old.toJson());
    await box.put('recent', recent.toJson());

    await repository.purgeOlderThan(const Duration(days: 30));

    // Old should be gone
    expect(repository.getById('old'), isNull);
    // Recent should still exist (in including-deleted list)
    final allDeleted = repository.getAllIncludingDeleted();
    expect(allDeleted.any((m) => m.id == 'recent'), isTrue);
  });
}
