// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/reports/domain/blind_read_result.dart';

class BlindReadService {
  BlindReadService({
    required ChapterRepository chapterRepository,
    int? randomSeed,
  })  : _chapterRepository = chapterRepository,
        _randomSeed = randomSeed;

  final ChapterRepository _chapterRepository;
  final int? _randomSeed;

  List<BlindReadExcerpt> selectExcerpts({
    String? manuscriptId,
    int count = 10,
    int minParagraphLength = 50,
  }) {
    if (count <= 0 || minParagraphLength < 0) return const [];

    final chapters = (manuscriptId == null || manuscriptId.isEmpty
            ? _chapterRepository.getAll()
            : _chapterRepository.getByManuscriptId(manuscriptId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final excerpts = <BlindReadExcerpt>[];
    for (final chapter in chapters) {
      final paragraphs = chapter.documentContent
          .split(RegExp(r'\n\s*\n'))
          .map((paragraph) => paragraph.trim())
          .where((paragraph) => paragraph.length >= minParagraphLength);
      for (final paragraph in paragraphs) {
        excerpts.add(
          BlindReadExcerpt(
            text: paragraph,
            chapterId: chapter.id,
            chapterIndex: chapter.sortOrder,
          ),
        );
      }
    }

    if (excerpts.isEmpty) return const [];
    excerpts.shuffle(_randomSeed == null ? Random() : Random(_randomSeed));
    return excerpts.take(count).toList(growable: false);
  }

  BlindReadResult computeResult(List<BlindReadExcerpt> excerpts) {
    final judged = excerpts.where((excerpt) => excerpt.humanVerdict != null);
    final correctCount = judged.where((excerpt) => excerpt.humanVerdict == true).length;
    return BlindReadResult(
      excerpts: List.unmodifiable(excerpts),
      correctCount: correctCount,
    );
  }
}
