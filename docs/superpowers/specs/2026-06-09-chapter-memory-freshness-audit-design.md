# Chapter Memory Freshness Audit Design

Date: 2026-06-09

## Context

MuseFlow's README promises an author-led writing workflow where AI helps keep
characters, world rules, foreshadowing, and chapter continuity visible. The GSD
research backlog identifies a concrete weak point in that promise:
`ChapterContextMiddleware` can inject adjacent chapter summaries, but those
summaries can drift from the actual manuscript after rewrites, splits, merges,
or reorder operations.

External research on AI-assisted long-form fiction points to the same failure
mode. The frontier is less about generating more words and more about memory,
planning, temporal consistency, character continuity, and preserving author
agency. MuseFlow should therefore make stale context visible before it misleads
the next AI operation.

## Goal

Add a lightweight local audit that tells the author when chapter memory looks
stale or thin.

The report should answer:

- Which chapter-adjacent summaries are likely to misrepresent the real text?
- What local evidence caused that suspicion?
- What should the author review before asking AI to continue or polish?

## Scope

This change extends the existing consistency report path:

- Add memory freshness domain types to `ConsistencyReport`.
- Compute deterministic local freshness signals in `ConsistencyAnalysisService`.
- Surface a new section on `ConsistencyReportPage`.
- Export the same evidence in Markdown.
- Add focused tests for domain, service, UI, and export behavior.

No new AI calls, storage migrations, background jobs, or automatic rewrites are
introduced. The audit is a review aid, not a judge.

## Data Model

Add `ChapterMemoryFreshnessSignal`:

- `chapterIndex`
- `direction` (`previous` or `next`)
- `summary`
- `overlapScore`
- `missingTerms`
- `evidence`
- `suggestion`
- `severity`

Add `ChapterMemoryFreshnessSnapshot`:

- `averageOverlapScore`
- `staleSummaryCount`
- `signals`

Add `memoryFreshness` to `ConsistencyReport`.

Scores use `0.0..1.0`, where higher means the supplied summary appears better
aligned with the referenced chapter text.

## Heuristics

The service compares each chapter's stored adjacent summary fields against the
actual adjacent chapter text:

- Extract meaningful Chinese and alphanumeric terms from the summary.
- Ignore common connector words and very short particles.
- Compute how many summary terms appear in the referenced chapter.
- Flag stale memory when overlap is low and the summary contains enough terms
  to be meaningful.
- Escalate severity when several named terms are missing.

This intentionally avoids semantic overclaiming. A low score means "review this
context before relying on it", not "the summary is wrong".

## UI

On the consistency report page:

- Add a "章节记忆新鲜度" section after narrative quality review.
- Show average overlap and stale summary count with compact score cards.
- List signals with chapter number, previous/next direction, overlap score,
  missing terms, evidence, and suggestion.
- Keep the empty state concise: "暂无明显过期的章节记忆。"

## Export

`ReportExportService.buildConsistencyMarkdown()` adds a "章节记忆新鲜度" section:

- Average overlap score.
- Stale summary count.
- Review items with chapter direction, missing terms, evidence, and suggestion.

## Testing

Focused verification:

- Domain tests for the snapshot and signal models.
- Service tests for stale previous/next summaries and healthy summaries.
- Export test for the Markdown section.
- Page test for the new section and empty state.

Regression commands:

- `dart format --set-exit-if-changed .`
- `flutter analyze lib/features/reports test/features/reports`
- `flutter test test/features/reports`

## Non-Goals

- No automatic summary regeneration.
- No AI-based semantic comparison.
- No new chapter summary storage schema.
- No claim that the tool can prove narrative truth.
