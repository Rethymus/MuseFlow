---
phase: 15-full-manuscript-story-structure
plan: 06
subsystem: testing
tags: [flutter-test, e2e, xianxia, token-audit, issue-log]

requires:
  - phase: 15-full-manuscript-story-structure
    provides: 15-02 extended StoryOutline to 100 chapters
provides:
  - 100-chapter deterministic and GLM full journey E2E coverage
  - Stage prompt and previous chapter summary injection in full journey generation
  - Phase 15 structured issue log template for JOURNEY-07 through JOURNEY-10
affects: [phase-15-validation, journey-tests, token-audit, issue-tracking]

tech-stack:
  added: []
  patterns:
    - deterministic E2E adapter with explicit synthesis/opening/chapter routing
    - previous chapter summary prompt context injection

key-files:
  created:
    - .planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md
  modified:
    - test/journey/full_journey_test.dart

key-decisions:
  - "Use StoryOutline.chapters[index] matching in the deterministic adapter so opening-guide prompts containing 第/林风 do not consume chapter indices."
  - "Keep issue log empty at creation time and reserve P15-XX-FUNC/UX/NEED IDs for findings discovered by later executors."

patterns-established:
  - "Full journey generation composes stage prompt, previous chapter summary, and current outline point into one PromptContext fragment."
  - "Phase issue logs start with zeroed summary statistics and no pre-populated findings."

requirements-completed: [JOURNEY-07, JOURNEY-10]

duration: unknown
completed: 2026-06-08
---

# Phase 15 Plan 06: Full Journey 100-Chapter E2E Summary

**Full journey E2E now validates world-building through 100 generated chapters with stage prompts, continuity summaries, D-11 bounds, and 101-call token audit coverage.**

## Performance

- **Duration:** unknown
- **Started:** not captured due initial worktree-base assertion recovery
- **Completed:** 2026-06-08
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments

- Extended `test/journey/full_journey_test.dart` from 30 to 100 chapter generation for deterministic and GLM paths.
- Injected `StagePrompts.forChapterIndex(index)` and previous chapter summaries into each chapter generation prompt.
- Updated full journey token audit expectations to `totalCalls >= 101` for synthesis plus 100 chapter calls.
- Created `.planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md` with empty issue table, zeroed counts, severity guide, evidence hygiene, and verification checklist.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend E2E full journey test from 30 to 100 chapters** - `8fe3a10` (test)
2. **Task 2: Create Phase 15 structured issue log template** - `a86cfce` (docs)

**Plan metadata:** pending final summary commit

## Files Created/Modified

- `test/journey/full_journey_test.dart` - 100-chapter E2E full journey generation with stage prompts, previous-summary continuity, D-11 bounds, GLM 60-minute timeout, and `>=101` token audit assertion.
- `.planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md` - Phase 15 structured issue log template for JOURNEY-07 through JOURNEY-10 findings.

## Decisions Made

- Deterministic adapter chapter routing now checks `StoryOutline.chapters[_chapterIndex]` instead of broad `第`/`林风` markers to avoid opening-guide prompts being mistaken for chapter prompts.
- Deterministic fragment synthesis uses a fixed local response so the chapter counter remains reserved for the 100 chapter loop.
- Issue log starts empty with zero statistics because this plan creates the tracking template rather than recording discovered issues.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented deterministic opening/synthesis calls from consuming chapter indices**
- **Found during:** Task 1 (Extend E2E full journey test from 30 to 100 chapters)
- **Issue:** The deterministic adapter classified prompts containing `第` and `林风` as chapter generation. Opening-guide and synthesis prompts could consume chapter indices before Phase D, causing chapter 100 to fall through or fail bounds.
- **Fix:** Added explicit synthesis handling and changed chapter detection to match the expected `StoryOutline.chapters[_chapterIndex]` text.
- **Files modified:** `test/journey/full_journey_test.dart`
- **Verification:** `dart analyze test/journey/full_journey_test.dart` and deterministic 100-chapter full journey test passed.
- **Committed in:** `8fe3a10`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The fix was required for deterministic 100-chapter correctness and did not expand user-facing scope.

## Issues Encountered

- Initial worktree-base assertion command reset to `8d52ccc` but compared full hash to short hash and reported failure after successful reset. Current branch remained `worktree-agent-a36e9d42281f88b46` at the expected base, so execution continued safely.
- No GLM credentialed test was run because the deterministic verification path was sufficient for this autonomous plan and GLM test remains skipped unless `GLM_API_KEY` is present.

## Verification

- `dart analyze test/journey/full_journey_test.dart` — passed.
- `flutter test test/journey/full_journey_test.dart -j 1 --plain-name "should complete deterministic full xianxia journey to 100 chapters" --timeout 600s` — passed.
- `test -f .planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md && rg -c "Issue Log" .planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md` — passed with count `1`.
- `wc -l .planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md` — passed with `104` lines.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required for deterministic verification. GLM credentialed validation still requires `GLM_API_KEY` when intentionally running the live API path.

## Next Phase Readiness

- Full 100-chapter E2E coverage is ready for subsequent Phase 15 validation plans.
- The issue log is ready for later executors to record JOURNEY-07 through JOURNEY-10 findings.

## Self-Check: PASSED

- Found created file: `.planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md`
- Found modified file: `test/journey/full_journey_test.dart`
- Found task commit: `8fe3a10`
- Found task commit: `a86cfce`

---
*Phase: 15-full-manuscript-story-structure*
*Completed: 2026-06-08*
