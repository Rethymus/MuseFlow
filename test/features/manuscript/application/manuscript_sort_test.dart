import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/application/manuscript_sort.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';

void main() {
  final now = DateTime.now();

  Manuscript create({
    String id = 'test',
    String title = 'Test',
    String genre = '玄幻',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Manuscript(
      id: id,
      title: title,
      genre: genre,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('compareManuscripts', () {
    test('recentEdit sorts by updatedAt descending', () {
      final older = create(
        id: 'older',
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
      final newer = create(
        id: 'newer',
        updatedAt: now.add(const Duration(hours: 1)),
      );

      // newer should come before older (descending)
      final result = compareManuscripts(
        older,
        newer,
        ManuscriptSortMode.recentEdit,
      );
      expect(
        result,
        greaterThan(0),
      ); // older > newer means older sorts after newer

      final reverse = compareManuscripts(
        newer,
        older,
        ManuscriptSortMode.recentEdit,
      );
      expect(
        reverse,
        lessThan(0),
      ); // newer < older means newer sorts before older
    });

    test('creationDate sorts by createdAt descending', () {
      final older = create(
        id: 'older',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final newer = create(id: 'newer', createdAt: now);

      final result = compareManuscripts(
        older,
        newer,
        ManuscriptSortMode.creationDate,
      );
      expect(result, greaterThan(0));
    });

    test('titleAlphabetical sorts by title ascending', () {
      final alpha = create(id: 'a', title: 'Alpha');
      final beta = create(id: 'b', title: 'Beta');

      final result = compareManuscripts(
        alpha,
        beta,
        ManuscriptSortMode.titleAlphabetical,
      );
      expect(result, lessThan(0)); // 'Alpha' < 'Beta'
    });

    test('sort can be used with List.sort', () {
      final items = [
        create(id: 'c', title: 'Charlie', updatedAt: now),
        create(
          id: 'a',
          title: 'Alpha',
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        create(
          id: 'b',
          title: 'Bravo',
          updatedAt: now.add(const Duration(hours: 1)),
        ),
      ];

      items.sort(
        (a, b) => compareManuscripts(a, b, ManuscriptSortMode.recentEdit),
      );

      // Most recently updated first
      expect(items[0].id, equals('b'));
      expect(items[1].id, equals('c'));
      expect(items[2].id, equals('a'));
    });
  });
}
