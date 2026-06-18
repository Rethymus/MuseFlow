---
phase: mc-02-trigger-surface
plan: 01
quick_id: 260618-s4
type: tdd
wave: 1
depends_on: ["260618-jn6"]
tags: [mc-02, summary-refresh, trigger-surface, orphan-cleanup, tdd]
requirements: [MC-02-slice4]
---

# Phase mc-02-trigger-surface Plan 01: Complete the summary-trigger surface Summary

**One-liner:** MC-02 slice 4 — completes the chapter-summary fire-and-forget trigger surface for add/duplicate/split/merge/delete (slice 3 wired only `save`), force-refreshing split/merge where content was REPLACED (correctness bug: stale summary marked fresh by negative-growth check), and cleaning up orphan `ChapterSummary` rows on delete/merge via new `ChapterSummaryRefreshService.deleteSummary`.

## Outcome

Two real gaps from slice 3 closed:

1. **Correctness bug — splitChapter / mergeChapters factually-wrong summary injection.** The original chapter's content is REPLACED with a subset (splitChapter: `beforeContent`; mergeChapters: `combinedContent`). `ChapterSummaryStalenessChecker.isStale` returns `false` when `currentWordCount <= sourceWordCount` (negative growth), so the now-factually-wrong whole-chapter summary was marked fresh and re-injected on the next editor AI call. Fix: force-refresh (`service.refresh`, bypassing staleness) for the original/merged chapter.
2. **Orphan hygiene — delete / mergeChapters(chapter2).** Deleted/merged-away chapters left orphan `ChapterSummary` rows; `ChapterSummaryRepository.getByManuscriptId` returned them. Fix: new `ChapterSummaryRefreshService.deleteSummary(chapterId)` + `_deleteSummary` fire-and-forget helper, called from `delete(id)` and `mergeChapters` (for chapter2).

Plus symmetric surface completion: `add` and `duplicateChapter` now also refresh on the PERSISTED chapter (captured from `repository.add` return — input id is often empty, the repository assigns the real uuid).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | RED+GREEN: `ChapterSummaryRefreshService.deleteSummary` | `baab7b9` | `chapter_summary_refresh_service.dart`, `chapter_summary_refresh_service_test.dart` |
| 2 | Complete trigger surface in `ChapterNotifier` (add/dup/split/merge/delete, force path for split/merge) | `edf0497` | `chapter_notifier.dart` |
| 3 | Wiring tests (3 new) + full verification gates | `f14d775` | `chapter_notifier_test.dart` |

## Verification Gates

All five gates from the plan PASSED:

### Gate 1 — `chapter_summary_refresh_service_test.dart`
```
00:00 +6: ChapterSummaryRefreshService.deleteSummary T7: deleteSummary(chapterId) removes the stored row -> getByChapterId returns null after
00:00 +7: ChapterSummaryRefreshService.deleteSummary T8 (reliability): repository.delete throws StateError -> service RE-THROWS (same surfacing posture as put/summarize)
00:00 +8: All tests passed!
```
6 existing + 2 new (T7 orphan removal, T8 reliability rethrow) = 8/8 GREEN.

### Gate 2 — `chapter_notifier_test.dart`
```
00:00 +9: T-wire-1: delete(id) triggers _deleteSummary -> recordingService.deleteSummaryCalls contains id
00:00 +10: T-wire-2: splitChapter FORCE-refreshes BOTH original (beforeContent) and created (afterContent) — 2 refreshCalls, 0 refreshIfNeededCalls
00:00 +11: T-wire-3: mergeChapters FORCE-refreshes chapter1 (combined content) and calls _deleteSummary on chapter2 (orphan cleanup)
00:00 +12: All tests passed!
```
9 existing (untouched, no provider override → service null → helpers no-op) + 3 new wiring tests = 12/12 GREEN.

### Gate 3 — Full manuscript suite
```
00:08 +146 ~1: All tests passed!
```
146 tests pass, 1 pre-existing skip. No regression.

### Gate 4 — `flutter analyze`
```
Analyzing MuseFlow...
No issues found! (ran in 3.5s)
```

### Gate 5 — grep trigger surface
```
39:    unawaited(_maybeRefreshSummary(persisted));           # add
49:    unawaited(_maybeRefreshSummary(chapter));             # save (slice 3, unchanged)
64:  Future<void> _maybeRefreshSummary(Chapter chapter, {bool force = false}) async {
85:  Future<void> _deleteSummary(String chapterId) async {
102:    unawaited(_deleteSummary(id));                       # delete (orphan cleanup)
177:    unawaited(_maybeRefreshSummary(created));             # duplicateChapter
206:      _maybeRefreshSummary(... force: true);              # splitChapter — original (FORCE)
241:    unawaited(_maybeRefreshSummary(created, force: true)); # splitChapter — created (FORCE)
264:    unawaited(_deleteSummary(chapterId2));                # mergeChapters — chapter2 orphan
279:      _maybeRefreshSummary(... force: true);              # mergeChapters — chapter1 (FORCE)
```
Surface complete across add / save / delete / duplicateChapter / splitChapter (both halves) / mergeChapters (chapter1 refresh + chapter2 orphan).

## Key Decisions

1. **Force path vs. staleness check for split/merge.** The plan's `verified_facts` flagged the root cause: `isStale` returns false on negative growth, but split/merge REPLACE content (not grow). The `force=true` branch in `_maybeRefreshSummary` calls `service.refresh` to bypass the staleness check entirely — this is a content-replacement semantic, not a content-growth semantic.
2. **`deleteSummary` lives on the SERVICE, not the repository.** Mirrors the slice 3 layering: the repository is a pure persistence boundary, the service owns the refresh + lifecycle contract. The notifier depends on the service abstraction, not the repository.
3. **`_RecordingRefreshService implements ChapterSummaryRefreshService` (not extends).** Mirrors `_FakeSummaryRepository` pattern from the sibling test: `implements` on a concrete class bypasses the real ctor (needs live AI adapter + Hive box) while `noSuchMethod` acts as a tripwire for any unexpected member access. The three exercised methods (refreshIfNeeded/refresh/deleteSummary) are explicitly stubbed.
4. **Capture `repository.add` return — never discard.** The repository assigns the real uuid for empty input ids. The wiring captures `final persisted/created = await repository.add(...)` so refresh targets the correct id. Pre-slice-4 code discarded this return — a latent correctness gap that would have refreshed an empty/non-existent id.

## Reliability Posture (unchanged from slice 3 wma/0ae)

- **SERVICE** (`ChapterSummaryRefreshService.deleteSummary`): rethrows `StateError` from `summaryRepository.delete`. Never silently swallows. Verified by T8.
- **TRIGGER** (`_maybeRefreshSummary` / `_deleteSummary` in `ChapterNotifier`): catch + `debugPrint` + drop. Fire-and-forget async side-effects MUST NOT kill the user's main chapter op (add/delete/split/merge). The main op already succeeded (chapter persisted) before the trigger runs.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all paths are wired to real service methods.

## Threat Flags

None — no new network/auth/file-access surface introduced. The trigger surface only invokes existing reviewed service methods.

## Files

- `lib/features/manuscript/application/chapter_summary_refresh_service.dart` — `deleteSummary` added (+13 lines)
- `lib/features/manuscript/application/chapter_notifier.dart` — `_maybeRefreshSummary{force}`, `_deleteSummary`, wiring across add/delete/duplicateChapter/splitChapter/mergeChapters (+64 net)
- `test/features/manuscript/application/chapter_summary_refresh_service_test.dart` — T7+T8 + `_FakeSummaryRepository.delete` + `deleteError` mode
- `test/features/manuscript/application/chapter_notifier_test.dart` — T-wire-1/2/3 + `_RecordingRefreshService`

No file exceeds the 800-line cap. Largest modified file: `chapter_notifier.dart` at 314 lines.

## Self-Check: PASSED

- `chapter_summary_refresh_service.dart` exists, has `deleteSummary` method — FOUND
- `chapter_notifier.dart` exists, has `_maybeRefreshSummary{force}` + `_deleteSummary` — FOUND
- 3 commits exist: `baab7b9`, `edf0497`, `f14d775` — all FOUND in git log
- All verification gates GREEN — FOUND
