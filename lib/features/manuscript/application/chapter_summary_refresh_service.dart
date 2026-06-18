import 'package:museflow/features/manuscript/application/chapter_summarization_service.dart';
import 'package:museflow/features/manuscript/application/chapter_summary_staleness_checker.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_summary_repository.dart';

/// Outcome of a [ChapterSummaryRefreshService] call (MC-02 slice 3).
///
/// [refreshed] is true iff the service called the LLM and persisted a new or
/// updated [ChapterSummary]; false iff it took a no-op fast path (fresh stored
/// summary or sub-minimum-length chapter). [summary] is null only when the
/// chapter was skipped for being below [ChapterSummaryRefreshService.minSummaryChars].
class RefreshOutcome {
  const RefreshOutcome({required this.refreshed, this.summary});

  final bool refreshed;
  final ChapterSummary? summary;
}

/// Decides whether a chapter's stored AI summary needs refreshing, and when
/// it does, calls [ChapterSummarizationService.summarize] + persists the result
/// via [ChapterSummaryRepository] (MC-02 slice 3 WRITE SIDE).
///
/// Reliability posture (lessons from quick-260617-wma + quick-260618-0ae):
/// - The SERVICE rethrows [AIException] (from `summarize`) and [StateError]
///   (from `put`). It never silently swallows. This is the contract — the
///   service's job is to produce+persist a summary.
/// - The fire-and-forget TRIGGER in [ChapterNotifier.save] is where errors are
///   caught+logged+dropped — separation of concerns: the trigger is an async
///   side-effect that MUST NOT kill the main save flow.
///
/// Decision branches:
/// 1. `wordCount < minSummaryChars` → skip (no wasted API call on near-empty).
/// 2. stored fresh (per [stalenessChecker]) → no-op fast path, return stored.
/// 3. stored stale OR no stored summary → summarize + put (overwrite by id).
/// [refresh] forces a summarize+put ignoring freshness (but NOT the staleness
/// decision tree — it bypasses only the freshness check, not the min-length
/// guard per design decision #4).
class ChapterSummaryRefreshService {
  ChapterSummaryRefreshService({
    required this.summarizationService,
    required this.summaryRepository,
    ChapterSummaryStalenessChecker? stalenessChecker,
  }) : stalenessChecker = stalenessChecker ?? const ChapterSummaryStalenessChecker();

  final ChapterSummarizationService summarizationService;
  final ChapterSummaryRepository summaryRepository;
  final ChapterSummaryStalenessChecker stalenessChecker;

  /// Minimum non-blank char count at which a chapter is worth summarizing.
  /// Chapters below this (stubs, half-formed notes) are skipped to avoid
  /// wasting LLM tokens and producing noise summaries.
  static const int minSummaryChars = 20;

  /// Refreshes [chapter]'s summary if and only if (a) it is at least
  /// [minSummaryChars] long AND (b) either no summary is stored OR the
  /// stored one is stale per [stalenessChecker].
  ///
  /// Never swallows [AIException]/[StateError] — callers (the fire-and-forget
  /// trigger in [ChapterNotifier]) MUST catch them.
  Future<RefreshOutcome> refreshIfNeeded(Chapter chapter, {DateTime? now}) async {
    final wordCount = chapter.wordCount;
    if (wordCount < minSummaryChars) {
      return const RefreshOutcome(refreshed: false, summary: null);
    }
    final stored = summaryRepository.getByChapterId(chapter.id);
    if (stored != null && !stalenessChecker.isStale(stored, wordCount)) {
      return RefreshOutcome(refreshed: false, summary: stored);
    }
    return _summarizeAndPut(chapter, storedId: stored?.id, now: now);
  }

  /// Force-refresh: always summarize + put, ignoring freshness. Bypasses the
  /// min-length guard too — explicit user/system intent to summarize now.
  Future<RefreshOutcome> refresh(Chapter chapter, {DateTime? now}) async {
    final stored = summaryRepository.getByChapterId(chapter.id);
    return _summarizeAndPut(chapter, storedId: stored?.id, now: now);
  }

  Future<RefreshOutcome> _summarizeAndPut(
    Chapter chapter, {
    String? storedId,
    DateTime? now,
  }) async {
    // summarize() rethrows AIException — SURFACED per wma/0ae.
    final summary = await summarizationService.summarize(
      chapter,
      summaryId: storedId,
      now: now,
    );
    // put() wraps Hive errors in StateError — also surfaced.
    await summaryRepository.put(summary);
    return RefreshOutcome(refreshed: true, summary: summary);
  }
}
