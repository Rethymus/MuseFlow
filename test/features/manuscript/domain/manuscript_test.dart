import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';

void main() {
  group('Manuscript', () {
    test(
      'fromJson(toJson()) roundtrip preserves all fields including deletedAt null, characterCardIds empty list, coverLetter default',
      () {
        final now = DateTime.now();
        final manuscript = Manuscript(
          id: 'test-id',
          title: 'Test Manuscript',
          genre: '玄幻',
          createdAt: now,
          updatedAt: now,
          coverLetter: '测',
        );

        final json = manuscript.toJson();
        final roundtrip = Manuscript.fromJson(json);

        expect(roundtrip.id, 'test-id');
        expect(roundtrip.title, 'Test Manuscript');
        expect(roundtrip.description, isNull);
        expect(roundtrip.genre, '玄幻');
        expect(roundtrip.targetWordCount, 0);
        expect(roundtrip.status, '构思中');
        expect(roundtrip.worldSettingId, isNull);
        expect(roundtrip.characterCardIds, const <String>[]);
        expect(roundtrip.createdAt, now);
        expect(roundtrip.updatedAt, now);
        expect(roundtrip.deletedAt, isNull);
        expect(roundtrip.coverLetter, '测');
      },
    );

    test('copyWith(coverLetter: ...) updates only coverLetter', () {
      final now = DateTime.now();
      final manuscript = Manuscript(
        id: 'test-id',
        title: 'Test Manuscript',
        genre: '科幻',
        targetWordCount: 50000,
        status: '写作中',
        characterCardIds: const ['card-1', 'card-2'],
        worldSettingId: 'ws-1',
        description: 'A description',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        coverLetter: '测',
      );

      final updated = manuscript.copyWith(coverLetter: '修');

      expect(updated.id, 'test-id');
      expect(updated.title, 'Test Manuscript');
      expect(updated.genre, '科幻');
      expect(updated.targetWordCount, 50000);
      expect(updated.status, '写作中');
      expect(updated.characterCardIds, const ['card-1', 'card-2']);
      expect(updated.worldSettingId, 'ws-1');
      expect(updated.description, 'A description');
      expect(updated.coverLetter, '修');
      expect(updated.deletedAt, isNull);
    });

    test('equality compares all fields', () {
      final now = DateTime.now();
      final m1 = Manuscript(
        id: 'id-1',
        title: 'Title',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
        coverLetter: '玄',
      );
      final m2 = Manuscript(
        id: 'id-1',
        title: 'Title',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
        coverLetter: '玄',
      );

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
    });

    test('inequality detects different fields', () {
      final now = DateTime.now();
      final m1 = Manuscript(
        id: 'id-1',
        title: 'Title A',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
        coverLetter: '玄',
      );
      final m2 = Manuscript(
        id: 'id-1',
        title: 'Title B',
        genre: '玄幻',
        createdAt: now,
        updatedAt: now,
        coverLetter: '玄',
      );

      expect(m1, isNot(equals(m2)));
    });

    test('fromJson handles nullable fields and defaults from JSON', () {
      final json = <String, dynamic>{
        'id': 'id-x',
        'title': 'Title X',
        'genre': '都市',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-02T00:00:00.000',
        // description omitted -> null
        // targetWordCount omitted -> 0
        // status omitted -> '构思中'
        // characterCardIds omitted -> []
        // deletedAt omitted -> null
        // coverLetter omitted -> ''
      };

      final m = Manuscript.fromJson(json);

      expect(m.description, isNull);
      expect(m.targetWordCount, 0);
      expect(m.status, '构思中');
      expect(m.characterCardIds, const <String>[]);
      expect(m.deletedAt, isNull);
      expect(m.worldSettingId, isNull);
    });
  });
}
