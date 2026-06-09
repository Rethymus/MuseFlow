import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

void main() {
  group('Chapter', () {
    test(
      'wordCount returns 0 for empty documentContent, returns Chinese character count excluding whitespace for non-empty',
      () {
        final now = DateTime.now();
        final empty = Chapter(
          id: 'ch-1',
          manuscriptId: 'ms-1',
          title: 'Empty Chapter',
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        );
        expect(empty.wordCount, 0);

        final withContent = Chapter(
          id: 'ch-2',
          manuscriptId: 'ms-1',
          title: 'Chapter with Content',
          sortOrder: 1,
          documentContent: '第一回 悟彻菩提真妙理\n断魔归正合元神',
          createdAt: now,
          updatedAt: now,
        );
        // "第一回悟彻菩提真妙理断魔归正合元神" = 17 chars (whitespace excluded)
        expect(withContent.wordCount, 17);
      },
    );

    test(
      'fromJson(toJson()) roundtrip preserves all fields including default status and empty documentContent',
      () {
        final now = DateTime.now();
        final chapter = Chapter(
          id: 'ch-3',
          manuscriptId: 'ms-1',
          title: 'Test Chapter',
          sortOrder: 2,
          status: '初稿',
          documentContent: '# Hello\n\nSome content here.',
          createdAt: now,
          updatedAt: now,
        );

        final json = chapter.toJson();
        final roundtrip = Chapter.fromJson(json);

        expect(roundtrip.id, 'ch-3');
        expect(roundtrip.manuscriptId, 'ms-1');
        expect(roundtrip.title, 'Test Chapter');
        expect(roundtrip.sortOrder, 2);
        expect(roundtrip.status, '初稿');
        expect(roundtrip.documentContent, '# Hello\n\nSome content here.');
        expect(roundtrip.createdAt, now);
        expect(roundtrip.updatedAt, now);
      },
    );

    test(
      'fromJson applies default status and documentContent when omitted',
      () {
        final json = <String, dynamic>{
          'id': 'ch-4',
          'manuscriptId': 'ms-2',
          'title': 'Default Chapter',
          'sortOrder': 0,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
          // status omitted -> '草稿'
          // documentContent omitted -> ''
        };

        final chapter = Chapter.fromJson(json);

        expect(chapter.status, '草稿');
        expect(chapter.documentContent, '');
      },
    );

    test(
      'equality compares all fields including manuscriptId and sortOrder',
      () {
        final now = DateTime.now();
        final c1 = Chapter(
          id: 'ch-5',
          manuscriptId: 'ms-1',
          title: 'Same Title',
          sortOrder: 3,
          documentContent: 'content',
          createdAt: now,
          updatedAt: now,
        );
        final c2 = Chapter(
          id: 'ch-5',
          manuscriptId: 'ms-1',
          title: 'Same Title',
          sortOrder: 3,
          documentContent: 'content',
          createdAt: now,
          updatedAt: now,
        );

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
      },
    );

    test('inequality detects different sortOrder or manuscriptId', () {
      final now = DateTime.now();
      final c1 = Chapter(
        id: 'ch-6',
        manuscriptId: 'ms-1',
        title: 'Title',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      final c2 = Chapter(
        id: 'ch-6',
        manuscriptId: 'ms-2', // different
        title: 'Title',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      final c3 = Chapter(
        id: 'ch-6',
        manuscriptId: 'ms-1',
        title: 'Title',
        sortOrder: 1, // different
        createdAt: now,
        updatedAt: now,
      );

      expect(c1, isNot(equals(c2)));
      expect(c1, isNot(equals(c3)));
    });

    test('copyWith updates only specified fields', () {
      final now = DateTime.now();
      final chapter = Chapter(
        id: 'ch-7',
        manuscriptId: 'ms-1',
        title: 'Original',
        sortOrder: 0,
        status: '草稿',
        documentContent: 'original content',
        createdAt: now,
        updatedAt: now,
      );

      final updated = chapter.copyWith(
        title: 'Updated',
        documentContent: 'new content',
      );

      expect(updated.id, 'ch-7');
      expect(updated.manuscriptId, 'ms-1');
      expect(updated.title, 'Updated');
      expect(updated.sortOrder, 0);
      expect(updated.status, '草稿');
      expect(updated.documentContent, 'new content');
    });

    test(
      'fromJson throws domain FormatException for malformed required fields',
      () {
        final valid = <String, dynamic>{
          'id': 'ch-8',
          'manuscriptId': 'ms-1',
          'title': 'Safe Chapter',
          'sortOrder': 0,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-02T00:00:00.000',
        };

        final malformedCases = <Map<String, dynamic>>[
          {...valid, 'id': 42},
          {...valid, 'manuscriptId': null},
          {...valid, 'title': <String>[]},
          {...valid, 'sortOrder': '1'},
          {...valid, 'createdAt': 'not-a-date'},
          {...valid, 'updatedAt': 123},
        ];

        for (final json in malformedCases) {
          expect(
            () => Chapter.fromJson(json),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                contains('Invalid Chapter JSON'),
              ),
            ),
          );
        }
      },
    );

    test(
      'fromJson throws domain FormatException for malformed optional fields',
      () {
        final valid = <String, dynamic>{
          'id': 'ch-9',
          'manuscriptId': 'ms-1',
          'title': 'Safe Chapter',
          'sortOrder': 0,
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-02T00:00:00.000',
        };

        final malformedCases = <Map<String, dynamic>>[
          {...valid, 'status': false},
          {...valid, 'documentContent': 9},
        ];

        for (final json in malformedCases) {
          expect(
            () => Chapter.fromJson(json),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                contains('Invalid Chapter JSON'),
              ),
            ),
          );
        }
      },
    );
  });
}
