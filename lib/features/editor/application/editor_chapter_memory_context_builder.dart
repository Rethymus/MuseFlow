import 'package:museflow/features/editor/application/chapter_memory_warning_builder.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';

/// Adjacent chapter memory prepared for editor AI prompts.
class EditorChapterMemoryContext {
  const EditorChapterMemoryContext({
    this.previousChapterSummary,
    this.nextChapterSummary,
    this.previousChapterMemoryWarning,
    this.nextChapterMemoryWarning,
  });

  final String? previousChapterSummary;
  final String? nextChapterSummary;
  final String? previousChapterMemoryWarning;
  final String? nextChapterMemoryWarning;

  bool get isEmpty =>
      previousChapterSummary == null &&
      nextChapterSummary == null &&
      previousChapterMemoryWarning == null &&
      nextChapterMemoryWarning == null;
}

/// Builds adjacent chapter context for real editor AI calls.
///
/// The app does not persist a separate chapter-summary field yet, so this
/// builder derives a bounded prompt summary from the current neighboring
/// chapter text. The freshness warning still matters when the bounded summary
/// is too front-loaded or stale-looking compared with the full adjacent text.
class EditorChapterMemoryContextBuilder {
  const EditorChapterMemoryContextBuilder({
    required this.chapterRepository,
    this.warningBuilder = const ChapterMemoryWarningBuilder(),
    this.summaryCharacterLimit = 220,
  });

  final ChapterRepository chapterRepository;
  final ChapterMemoryWarningBuilder warningBuilder;
  final int summaryCharacterLimit;

  EditorChapterMemoryContext build({
    required String manuscriptId,
    required String chapterId,
  }) {
    if (manuscriptId.trim().isEmpty || chapterId.trim().isEmpty) {
      return const EditorChapterMemoryContext();
    }

    final chapters = chapterRepository.getByManuscriptId(manuscriptId);
    final currentIndex = chapters.indexWhere(
      (chapter) => chapter.id == chapterId,
    );
    if (currentIndex < 0) return const EditorChapterMemoryContext();

    final previous = currentIndex > 0 ? chapters[currentIndex - 1] : null;
    final next = currentIndex < chapters.length - 1
        ? chapters[currentIndex + 1]
        : null;

    return EditorChapterMemoryContext(
      previousChapterSummary: _summary(previous),
      nextChapterSummary: _summary(next),
      previousChapterMemoryWarning: _warning(
        previous,
        ChapterMemoryDirection.previous,
      ),
      nextChapterMemoryWarning: _warning(next, ChapterMemoryDirection.next),
    );
  }

  String? _summary(Chapter? chapter) {
    if (chapter == null) return null;
    final text = _compactWhitespace(chapter.documentContent);
    if (text.isEmpty) return null;
    if (text.length <= summaryCharacterLimit) return text;
    return '${text.substring(0, summaryCharacterLimit)}...';
  }

  String? _warning(Chapter? chapter, ChapterMemoryDirection direction) {
    if (chapter == null) return null;
    final summary = _summary(chapter);
    if (summary == null) return null;
    final staleWarning = warningBuilder.buildWarning(
      summary: summary,
      adjacentChapterText: chapter.documentContent,
      direction: direction,
    );
    if (staleWarning != null) return staleWarning;
    return _truncationWarning(
      summary: summary,
      adjacentChapterText: chapter.documentContent,
      direction: direction,
    );
  }

  String? _truncationWarning({
    required String summary,
    required String adjacentChapterText,
    required ChapterMemoryDirection direction,
  }) {
    final fullText = _compactWhitespace(adjacentChapterText);
    if (fullText.length <= summaryCharacterLimit) return null;

    final missingTerms = _extractReviewTerms(
      fullText,
    ).where((term) => !summary.contains(term)).take(4).toList(growable: false);
    if (missingTerms.length < 3) return null;

    final directionLabel = switch (direction) {
      ChapterMemoryDirection.previous => '上一章',
      ChapterMemoryDirection.next => '下一章',
    };
    return '$directionLabel 摘要为截断上下文，缺少 ${missingTerms.join('、')}；'
        '请复查相邻章节后文是否包含会影响本次改写的事实。';
  }

  List<String> _extractReviewTerms(String text) {
    final matches = RegExp(
      r'[\u4e00-\u9fff]{2,8}',
    ).allMatches(text).map((match) => match.group(0)!);
    final terms = <String>{};
    for (final match in matches) {
      if (_memoryStopTerms.contains(match)) continue;
      if (match.length <= 4) {
        terms.add(match);
      } else {
        for (var start = 0; start < match.length - 1; start += 2) {
          final end = start + 4 > match.length ? match.length : start + 4;
          final term = match.substring(start, end);
          if (!_memoryStopTerms.contains(term)) terms.add(term);
        }
      }
    }
    return terms.toList(growable: false);
  }

  String _compactWhitespace(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static const Set<String> _memoryStopTerms = {
    '一个',
    '一种',
    '这里',
    '他们',
    '自己',
    '这个',
    '那个',
    '已经',
    '开始',
    '继续',
    '只是',
    '没有',
    '还是',
    '不是',
    '成为',
    '知道',
    '看见',
    '听见',
  };
}
