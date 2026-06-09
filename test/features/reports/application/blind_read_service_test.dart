import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/reports/application/blind_read_service.dart';
import 'package:museflow/features/reports/domain/blind_read_result.dart';

void main() {
  group('BlindReadService', () {
    test(
      'should select one eligible excerpt per chapter when count matches chapters',
      () {
        final service = BlindReadService(
          chapterRepository: _FakeChapterRepository(
            List.generate(
              10,
              (index) => _chapter(
                'c$index',
                'm1',
                '第$index章足够长的段落内容，用来进行反AI味盲读测试，确保长度超过五十个字符并且可以被服务抽取，文本继续补足长度。',
                sortOrder: index + 1,
              ),
            ),
          ),
        );

        final excerpts = service.selectExcerpts(count: 10);

        expect(excerpts, hasLength(10));
        expect(excerpts.map((e) => e.chapterId).toSet(), hasLength(10));
        expect(excerpts.every((e) => e.humanVerdict == null), isTrue);
      },
    );

    test('should filter out paragraphs shorter than minParagraphLength', () {
      final service = BlindReadService(
        chapterRepository: _FakeChapterRepository([
          _chapter(
            'c1',
            'm1',
            '太短\n\n足够长的段落内容应该被保留下来，用于盲读评估，并且长度超过五十个字符，避免抽到无意义片段，还要继续补充一些字数。',
          ),
        ]),
      );

      final excerpts = service.selectExcerpts(
        count: 10,
        minParagraphLength: 50,
      );

      expect(excerpts, hasLength(1));
      expect(excerpts.single.text, isNot(contains('太短')));
    });

    test('should shuffle excerpts so chapter order is randomized', () {
      final chapters = List.generate(
        30,
        (index) => _chapter(
          'c$index',
          'm1',
          '第$index章足够长的段落内容，用来进行反AI味盲读测试，确保长度超过五十个字符并且可以被服务抽取。',
          sortOrder: index + 1,
        ),
      );
      final service = BlindReadService(
        chapterRepository: _FakeChapterRepository(chapters),
        randomSeed: 7,
      );

      final excerpts = service.selectExcerpts(count: 10);

      expect(
        excerpts.map((e) => e.chapterIndex).toList(),
        isNot(List.generate(10, (i) => i + 1)),
      );
    });

    test('should return empty list when no chapters exist', () {
      final service = BlindReadService(
        chapterRepository: _FakeChapterRepository(const []),
      );

      expect(service.selectExcerpts(), isEmpty);
    });

    test('should return empty list when no paragraphs meet minimum length', () {
      final service = BlindReadService(
        chapterRepository: _FakeChapterRepository([
          _chapter('c1', 'm1', '短\n\n也短'),
        ]),
      );

      expect(service.selectExcerpts(), isEmpty);
    });

    test('should compute perfect score when all verdicts are AI generated', () {
      final service = BlindReadService(
        chapterRepository: _FakeChapterRepository(const []),
      );
      final result = service.computeResult([
        _excerpt('a', true),
        _excerpt('b', true),
      ]);

      expect(result.totalJudged, 2);
      expect(result.correctCount, 2);
      expect(result.score, 1.0);
    });

    test(
      'should compute mixed score because all source content is AI generated',
      () {
        final service = BlindReadService(
          chapterRepository: _FakeChapterRepository(const []),
        );
        final result = service.computeResult([
          _excerpt('a', true),
          _excerpt('b', false),
          _excerpt('c', true),
        ]);

        expect(result.totalJudged, 3);
        expect(result.correctCount, 2);
        expect(result.score, closeTo(2 / 3, 0.001));
      },
    );

    test('should exclude skipped excerpts from totalJudged', () {
      final service = BlindReadService(
        chapterRepository: _FakeChapterRepository(const []),
      );
      final result = service.computeResult([
        _excerpt('a', true),
        _excerpt('b', null),
        _excerpt('c', false),
      ]);

      expect(result.totalJudged, 2);
      expect(result.correctCount, 1);
      expect(result.score, 0.5);
    });
  });
}

BlindReadExcerpt _excerpt(String id, bool? verdict) {
  return BlindReadExcerpt(
    text: 'excerpt $id',
    chapterId: id,
    chapterIndex: 1,
    humanVerdict: verdict,
  );
}

Chapter _chapter(
  String id,
  String manuscriptId,
  String content, {
  int sortOrder = 1,
}) {
  return Chapter(
    id: id,
    manuscriptId: manuscriptId,
    title: id,
    sortOrder: sortOrder,
    documentContent: content,
    createdAt: DateTime(2026, 6, 8),
    updatedAt: DateTime(2026, 6, 8),
  );
}

class _FakeChapterRepository implements ChapterRepository {
  _FakeChapterRepository(this.chapters);

  final List<Chapter> chapters;

  @override
  List<Chapter> getAll() => chapters;

  @override
  Future<Chapter> add(Chapter chapter) async => chapter;

  @override
  Chapter? getById(String id) => chapters.where((c) => c.id == id).firstOrNull;

  @override
  List<Chapter> getByManuscriptId(String manuscriptId) =>
      chapters.where((c) => c.manuscriptId == manuscriptId).toList();

  @override
  Future<void> update(Chapter chapter) async {}

  @override
  Future<void> updateDocumentContent(String chapterId, String markdown) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteByManuscriptId(String manuscriptId) async {}
}
