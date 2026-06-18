---
phase: mc-02-write-side
plan: 01
quick_id: 260618-jn6
subsystem: manuscript
tags: [mc-02, chapter-summary, ai-adapter, fire-and-forget, tdd]
requirements: [MC-02-write-side, MC-02-slice3]
requires:
  - MC-02-slice1 (ChapterSummarizationService pure capability — d5db5e0/preceding)
  - MC-02-slice2 (ChapterSummaryRepository + staleness + builder injection — 260618-h4h)
provides:
  - "ChapterSummaryRefreshService.write-side (decision+summarize+persist)"
  - "Live production caller path for ChapterSummarizationService.summarize()"
affects:
  - "ChapterNotifier.save (now fires unawaited summary refresh)"
  - "EditorChapterMemoryContextBuilder (read-side now receives fresh summaries)"
tech-stack:
  added: []
  patterns:
    - "Provider-chain mirror of editor_ai_notifier (activeProviderProvider + activeApiKeyProvider + activeAdapterProvider)"
    - "fire-and-forget unawaited side-effect with try/catch+debugPrint isolation (wma/0ae)"
    - "TDD RED-GREEN-REFACTOR across 3 atomic commits"
key-files:
  created:
    - lib/features/manuscript/application/chapter_summary_refresh_service.dart
    - test/features/manuscript/application/chapter_summary_refresh_service_test.dart
  modified:
    - lib/core/presentation/providers_ai.dart
    - lib/core/presentation/providers.dart
    - lib/features/manuscript/application/chapter_notifier.dart
decisions:
  - "Service RE-THROWS AIException/StateError (surfaced); trigger in ChapterNotifier.save CATCHES+logs+drops — separation of concerns (wma/0ae)"
  - "minSummaryChars=20 guard skips near-empty stub chapters (avoid wasted LLM calls + noise summaries)"
  - "force refresh() bypasses BOTH freshness check AND min-length guard — explicit user/system intent to summarize now"
  - "_FakeSummaryRepository uses implements (not extends) to bypass Hive Box ctor; only put/getByChapterId stubbed"
  - "Provider chain returns null when no provider/apiKey/repo — fire-and-forget trigger skips cleanly"
metrics:
  duration: ~12min
  tasks: 3
  files: 5
  completed: 2026-06-18
---

# Phase MC-02-write-side Plan 01: ChapterSummaryRefreshService Summary

Closed the MC-02 chapter-summary WRITE SIDE that slices 1+2 left open: `ChapterSummarizationService.summarize()` had ZERO production callers, so `EditorChapterMemoryContextBuilder` always fell back to truncating raw chapter text. This plan adds the decision+summarize+persist step (`ChapterSummaryRefreshService`), a Riverpod provider bridge, and a fire-and-forget trigger in `ChapterNotifier.save` — turning the dead MC-02 loop into a live write→persist→read cycle without changing any existing read-side contract.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 RED | `d0d9c6c` | test(mc-02): add RED tests for ChapterSummaryRefreshService write-side decision logic |
| Task 2 GREEN | `a656136` | feat(mc-02): implement ChapterSummaryRefreshService write-side (decision+summarize+persist) |
| Task 3 Wiring | `4173b4d` | feat(mc-02): wire ChapterSummaryRefreshService provider + ChapterNotifier.save fire-and-forget trigger |

## Verification Gates (all passed)

1. `flutter test test/features/manuscript/application/chapter_summary_refresh_service_test.dart` → 6/6 GREEN
2. `flutter test test/features/manuscript/application/` → 55 passed, 1 pre-existing skip (no regression)
3. `flutter test test/features/manuscript/` → 141 passed, 1 pre-existing skip (no ChapterNotifier regression)
4. `flutter analyze` → 0 issues across whole repo

## Dead-Loop Closure Proof (Gate 5+6 grep)

Production `summarize()` caller chain (was previously ZERO production callers):

```
$ grep -rn "summarize(" lib/
lib/features/manuscript/application/chapter_summarization_service.dart:42:  Future<ChapterSummary> summarize(           ← definition
lib/features/manuscript/application/chapter_summary_refresh_service.dart:86:    final summary = await summarizationService.summarize(   ← NEW production caller
```

Trigger wiring (Gate 6):

```
$ grep -n "_maybeRefreshSummary\|chapterSummaryRefreshServiceProvider" \
    lib/features/manuscript/application/chapter_notifier.dart \
    lib/core/presentation/providers_ai.dart
chapter_notifier.dart:44:    unawaited(_maybeRefreshSummary(chapter));
chapter_notifier.dart:52:  Future<void> _maybeRefreshSummary(Chapter chapter) async {
chapter_notifier.dart:54:      final service = await ref.read(chapterSummaryRefreshServiceProvider.future);
providers_ai.dart:210:final chapterSummaryRefreshServiceProvider =
```

Live loop: `ChapterNotifier.save` → `unawaited(_maybeRefreshSummary)` → `chapterSummaryRefreshServiceProvider` → `ChapterSummaryRefreshService.refreshIfNeeded` → `summarizationService.summarize` (LLM) → `summaryRepository.put` (Hive) → READ via existing `EditorChapterMemoryContextBuilder._storedFreshSummary`.

## Reliability Posture (wma/0ae lessons applied)

- **Service SURFACES errors:** `_summarizeAndPut` rethrows both `AIException` (from `summarize`) and `StateError` (from `put`). Verified by T6 GREEN test (`expectLater(..., throwsA(isA<AIStreamException>()))` + `repository.putCallCount == 0` confirms no partial put).
- **Trigger SWALLOWS errors:** `ChapterNotifier._maybeRefreshSummary` wraps the call in `try/catch (e) { debugPrint('ChapterSummaryRefresh skipped for ${chapter.id}: $e'); }` so the user's chapter save NEVER fails because of a flaky LLM stream or Hive write.
- **DoS protection (T-mc02-02):** `minSummaryChars=20` skips stub chapters; freshness fast path returns stored summary without any LLM call when not stale — only chapters that grew ≥50 chars AND ≥20% hit the LLM.

## Deviations from Plan

None — plan executed exactly as written. All three tasks landed in TDD discipline (RED compile failure → GREEN 6/6 → wiring).

## TDD Gate Compliance

- ✅ RED gate: `d0d9c6c` (`test(mc-02): add RED tests ...`) — verified compile failure on missing `ChapterSummaryRefreshService`.
- ✅ GREEN gate: `a656136` (`feat(mc-02): implement ...`) — verified 6/6 tests pass after implementation.
- ✅ (No separate REFACTOR commit — code clean as-written, analyze 0.)

## Deferred Items (Out of Scope per design_decisions_locked #4)

The plan intentionally scopes only `ChapterNotifier.save` as the summary-refresh trigger. The following chapter-mutation operations are NOT wired for summary refresh in this plan, but may benefit from a future quick task:

- `ChapterNotifier.add` (new chapter) — likely not worth summarizing on creation (typically near-empty at add-time; will be summarized on first save).
- `ChapterNotifier.splitChapter` — original chapter's summary becomes stale; new chapter has no summary.
- `ChapterNotifier.mergeChapters` — merged chapter needs fresh summary; deleted chapter's summary should be cleaned up.
- `ChapterNotifier.duplicateChapter` — duplicate gets a fresh chapterId, no stored summary (correct as-is — next save triggers refresh).
- `ChapterNotifier.delete` — orphaned `ChapterSummary` row in Hive (could be cleaned up for tidiness).

These are deferred — `save` is the primary write trigger and covers the steady-state authoring loop. Split/merge/delete cleanup tracked in STATE.md as a future quick task candidate.

## Self-Check: PASSED

- ✅ `lib/features/manuscript/application/chapter_summary_refresh_service.dart` EXISTS (95 lines)
- ✅ `test/features/manuscript/application/chapter_summary_refresh_service_test.dart` EXISTS (272 lines)
- ✅ Commit `d0d9c6c` FOUND in git log
- ✅ Commit `a656136` FOUND in git log
- ✅ Commit `4173b4d` FOUND in git log
- ✅ Production caller of `summarize()` FOUND at `chapter_summary_refresh_service.dart:86`
