---
phase: 14-world-building-first-30-chapters
plan: 05
subsystem: testing
tags: [flutter, dart, hive, journey-tests, anti-ai-scent, chapter-notifier]
requires:
  - phase: 14-world-building-first-30-chapters
    provides: Phase 14 automated journey validation context and review blockers from 14-04
provides:
  - Per-test Hive temp directory ownership for journey containers
  - Anti-AI-scent regression gate for verifier-listed phrases
  - Production ChapterNotifier coverage for reorder, split, merge, duplicate, and delete
  - Issue-log closure evidence for CR-01, P14-04-AI-01, and chapter operation warnings
affects: [phase-14-validation, journey-tests, anti-ai-scent, manuscript-chapters]
tech-stack:
  added: []
  patterns:
    - JourneyTestContainer owns ProviderContainer plus Hive tempDir
    - Journey chapter operation tests call ChapterNotifier production APIs
key-files:
  created:
    - .planning/phases/14-world-building-first-30-chapters/14-05-PLAN.md
  modified:
    - test/journey/helpers/journey_container.dart
    - lib/features/ai/application/anti_ai_scent_processor.dart
    - test/journey/automated_ui_evidence_test.dart
    - test/journey/chapter_management_test.dart
    - .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md
key-decisions:
  - "Kept createJourneyContainer backwards-compatible while adding JourneyTestContainer ownership metadata."
  - "Validated chapter behavior through ChapterNotifier APIs instead of duplicating split/merge/copy/delete logic in tests."
patterns-established:
  - "Journey Hive cleanup closes Hive and deletes only the container-owned temp directory."
  - "Anti-AI-scent evidence must assert absence of banned phrases, not encode known limitations as passing conditions."
requirements-completed: [JOURNEY-04, JOURNEY-06]
duration: 34min
completed: 2026-06-07T16:34:21Z
---

# Phase 14 Plan 05: Validation Blocker Closure Summary

**Deterministic journey validation hardening for Hive isolation, anti-AI-scent phrase removal, and production chapter operation evidence**

## Performance

- **Duration:** 34 min
- **Started:** 2026-06-07T16:00:00Z
- **Completed:** 2026-06-07T16:34:21Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `JourneyTestContainer` ownership so journey cleanup closes Hive and deletes only its own temp directory.
- Expanded anti-AI-scent processing and regression evidence for `值得注意的是`, `总而言之`, and `需要指出的是`.
- Reworked chapter management validation to use production `ChapterNotifier` APIs for reorder, split, merge, duplicate, and delete.
- Updated `14-ISSUE-LOG.md` with safe closure notes and command-level evidence only.

## Task Commits

Each task was committed atomically:

1. **Task 1: Isolate journey Hive cleanup to the owning test container** - `8212304` (test)
2. **Task 2: Convert anti-AI-scent limitation into a real removal gate** - `4ea0ac3` (fix)
3. **Task 3: Strengthen chapter operation tests through production ChapterNotifier APIs** - `216a241` (test)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `.planning/phases/14-world-building-first-30-chapters/14-05-PLAN.md` - Copied into the worktree because the spawned base did not include the plan file.
- `test/journey/helpers/journey_container.dart` - Adds `JourneyTestContainer`, tempDir ownership tracking, `Hive.close()`, and owned-directory deletion.
- `lib/features/ai/application/anti_ai_scent_processor.dart` - Adds built-in empty replacements for `总而言之` and `需要指出的是`.
- `test/journey/automated_ui_evidence_test.dart` - Asserts all verifier-listed AI-scent phrases are absent and highlighted.
- `test/journey/chapter_management_test.dart` - Routes chapter operation validation through `chapterNotifierProvider.notifier`.
- `.planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` - Records closure evidence for Hive isolation, anti-AI-scent removal, and chapter operation validation.

## Decisions Made

- Kept `createJourneyContainer(...)` returning `ProviderContainer` for backwards compatibility while adding `createJourneyTestContainer(...)` for explicit ownership.
- Treated the plan file missing from the worktree as a blocking setup issue and copied it from the main checkout so summary and commits preserve plan context.
- Preserved existing 1-based chapter setup in repository helper tests while verifying production notifier paths normalize or preserve order according to their implemented behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored missing plan file in worktree**
- **Found during:** Execution start
- **Issue:** `14-05-PLAN.md` existed in the main checkout but was missing from the spawned worktree after base reset.
- **Fix:** Copied the plan into the worktree and committed it with Task 1 so execution artifacts remain self-contained.
- **Files modified:** `.planning/phases/14-world-building-first-30-chapters/14-05-PLAN.md`
- **Verification:** Plan file exists and was included in commit `8212304`.
- **Committed in:** `8212304`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Setup-only recovery; no product or validation scope expansion.

## Issues Encountered

- Initial worktree base assertion reset to `bb86a9b` but printed a short-hash comparison failure; follow-up inspection confirmed HEAD was correctly at `bb86a9b255b258015427b61f859a354d5cf4f529` on `worktree-agent-a5c138f551898b032`.
- The split chapter test initially expected 0-based sort orders after splitting a 1-based fixture set; adjusted the assertion to verify the production method's persisted 1-based sequence for that fixture.

## Verification

- `dart analyze test/journey/helpers/journey_container.dart test/journey/world_building_test.dart test/journey/opening_guide_test.dart test/journey/fragment_synthesis_test.dart test/journey/serial_generation_test.dart test/journey/full_journey_test.dart test/journey/automated_ui_evidence_test.dart test/journey/chapter_management_test.dart`
- `dart analyze lib/features/ai/application/anti_ai_scent_processor.dart test/journey/automated_ui_evidence_test.dart`
- `flutter test test/journey/automated_ui_evidence_test.dart --plain-name "should remove obvious AI-scent phrases from editor output" --timeout 180s`
- `dart analyze test/journey/chapter_management_test.dart`
- `flutter test test/journey/chapter_management_test.dart --timeout 240s`
- `dart analyze test/journey/helpers/journey_container.dart lib/features/ai/application/anti_ai_scent_processor.dart test/journey/automated_ui_evidence_test.dart test/journey/chapter_management_test.dart`
- `flutter test test/journey/automated_ui_evidence_test.dart test/journey/chapter_management_test.dart --timeout 300s`

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CR-01 Hive cleanup risk is closed for journey test containers.
- JOURNEY-06 anti-AI-scent evidence now fails if verifier-listed phrases remain in processed output.
- JOURNEY-04 chapter operation evidence now exercises production notifier operations and is ready for follow-on validation.
- Long GLM serial validation remains outside this plan and is still tracked separately by the phase issue log.

## Self-Check: PASSED

- Found summary file path: `.planning/phases/14-world-building-first-30-chapters/14-05-SUMMARY.md`
- Found task commits: `8212304`, `4ea0ac3`, `216a241`
- Confirmed no `STATE.md` or `ROADMAP.md` modifications were made in this worktree execution.

---
*Phase: 14-world-building-first-30-chapters*
*Completed: 2026-06-07T16:34:21Z*
