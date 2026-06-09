import 'dart:math';

/// Builds preflight warnings for adjacent chapter summaries.
///
/// The warning is meant for AI prompt construction: it does not judge the
/// manuscript, but tells the model and author-facing workflow when a stored
/// summary looks thin or stale compared with the current adjacent chapter text.
class ChapterMemoryWarningBuilder {
  const ChapterMemoryWarningBuilder();

  /// Returns a concise warning when [summary] no longer appears well aligned
  /// with [adjacentChapterText].
  ///
  /// Returns `null` for empty input, very thin summaries, or healthy overlap.
  String? buildWarning({
    required String summary,
    required String adjacentChapterText,
    required ChapterMemoryDirection direction,
  }) {
    final normalizedSummary = _compact(summary);
    final normalizedAdjacent = _compact(adjacentChapterText);
    if (normalizedSummary.isEmpty || normalizedAdjacent.isEmpty) return null;

    final terms = _extractMemoryTerms(normalizedSummary);
    if (terms.length < 3) return null;

    final matched = terms.where(normalizedAdjacent.contains).toSet();
    final missing = terms.where((term) => !matched.contains(term)).toList();
    final termOverlapScore = matched.length / terms.length;
    final continuityScore = _characterContinuityScore(
      normalizedSummary,
      normalizedAdjacent,
    );
    final overlapScore = max(termOverlapScore, continuityScore);

    if (overlapScore >= 0.4 || missing.length < 3) return null;

    final directionLabel = switch (direction) {
      ChapterMemoryDirection.previous => '上一章',
      ChapterMemoryDirection.next => '下一章',
    };
    final severity = overlapScore < 0.25 ? '偏低' : '不足';
    final percent = (overlapScore * 100).round();
    final missingPreview = missing.take(4).join('、');

    return '$directionLabel 摘要与当前相邻正文重合度$severity（约 $percent%），'
        '缺少 $missingPreview；请先复查该摘要是否仍准确。';
  }

  String _compact(String text) => text.replaceAll(RegExp(r'\s+'), '');

  List<String> _extractMemoryTerms(String text) {
    final terms = <String>{};
    final chineseMatches = RegExp(
      r'[\u4e00-\u9fff]{2,8}',
    ).allMatches(text).map((match) => match.group(0)!);
    for (final match in chineseMatches) {
      terms.addAll(_splitChineseTerm(match));
    }
    final latinMatches = RegExp(
      r'[A-Za-z][A-Za-z0-9_-]{2,}',
    ).allMatches(text).map((match) => match.group(0)!.toLowerCase());
    terms.addAll(latinMatches);
    return terms
        .where((term) => !_memoryStopTerms.contains(term))
        .take(24)
        .toList(growable: false);
  }

  List<String> _splitChineseTerm(String term) {
    if (term.length <= 4) return [term];
    final chunks = <String>[];
    for (var start = 0; start < term.length - 1; start += 2) {
      final end = min(start + 4, term.length);
      chunks.add(term.substring(start, end));
    }
    return chunks;
  }

  double _characterContinuityScore(String source, String target) {
    final sourceUnits = _chineseBigrams(source);
    if (sourceUnits.isEmpty) return 0.0;
    final targetUnits = _chineseBigrams(target).toSet();
    if (targetUnits.isEmpty) return 0.0;
    final matched = sourceUnits.where(targetUnits.contains).length;
    return (matched / sourceUnits.length).clamp(0.0, 1.0);
  }

  List<String> _chineseBigrams(String text) {
    final chars = text
        .replaceAll(RegExp(r'[^\u4e00-\u9fff]'), '')
        .runes
        .map(String.fromCharCode)
        .toList(growable: false);
    if (chars.length < 2) return const [];
    return List.generate(
      chars.length - 1,
      (index) => '${chars[index]}${chars[index + 1]}',
      growable: false,
    );
  }

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

enum ChapterMemoryDirection { previous, next }
