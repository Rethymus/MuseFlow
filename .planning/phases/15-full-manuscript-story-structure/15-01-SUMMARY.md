---
phase: 15-full-manuscript-story-structure
plan: 01
subsystem: testing
tags: [story-outline, stage-prompts, xianxia, journey-test, test-infrastructure]

# Dependency graph
requires:
  - phase: 14-world-building-first-30-chapters
    provides: Original 30-chapter StoryOutline and journey test infrastructure
provides:
  - 100-chapter story outline with three-stage arc (Golden Core, Nascent Soul, Ascension)
  - StagePrompts helper with forChapterIndex() routing for stage-specific prompts
affects: [15-02, 15-03, 15-04, 15-05, 15-06]

# Tech tracking
tech-stack:
  added: []
  patterns: [static-const-class helper pattern for test data, three-stage arc structure for serial generation]

key-files:
  created:
    - test/journey/helpers/story_outline.dart
    - test/journey/helpers/stage_prompts.dart
  modified: []

key-decisions:
  - "70 new chapters follow D-01 three-stage arc: Golden Core (31-60), Nascent Soul (61-90), Ascension (91-100)"
  - "Multi-conflict threads per D-02: Core Formation failure (Ch 41-50), Wang Lei schemes, Su Yue captured (Ch 55-60), sect war (Ch 75-85), heart demon (Ch 80-88), heavenly tribulation (Ch 96-100)"
  - "StagePrompts returns empty string for indices 0-29 (Phase 14 chapters have no stage prompt)"
  - "Stage prompts 100-200 characters each, providing thematic direction per D-03"

patterns-established:
  - "StagePrompts.forChapterIndex(index) pattern: stage-specific prompt routing by chapter index range"
  - "Three-stage story arc pattern: cultivation stages map to prompt blocks for serial generation"

requirements-completed: [JOURNEY-07, JOURNEY-08, JOURNEY-09, JOURNEY-10]

# Metrics
duration: 6min
completed: 2026-06-08
---

# Phase 15 Plan 01: Story Outline & Stage Prompts Summary

**100-chapter xianxia story outline extended with three-stage arc (Golden Core/Nascent Soul/Ascension) and StagePrompts helper providing stage-specific prompts for downstream serial generation tests**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-08T04:58:55Z
- **Completed:** 2026-06-08T05:05:12Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Extended StoryOutline from 30 to 100 chapters with 70 new entries covering the full three-stage cultivation arc
- Created StagePrompts helper with three stage prompt constants and forChapterIndex() routing method
- All multi-conflict threads present: Core Formation failure, Wang Lei schemes, Su Yue captured, sect war, heart demon, heavenly tribulation
- All foreshadowing threads embedded: mysterious origin (Ch 50-60), Su Yue's secret (Ch 55-65), forbidden zone (Ch 60-70), ancient artifact (Ch 70-80)
- Both files pass dart analyze with zero errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend StoryOutline from 30 to 100 chapters with three-stage arc** - `576464e` (feat)
2. **Task 2: Create StagePrompts helper with three-stage prompt constants** - `be3d441` (feat)

## Files Created/Modified
- `test/journey/helpers/story_outline.dart` - 100-chapter plot outline with three-stage xianxia cultivation arc (first 30 chapters unchanged from Phase 14)
- `test/journey/helpers/stage_prompts.dart` - StagePrompts class with goldenCore, nascentSoul, ascension prompt constants and forChapterIndex() routing

## Decisions Made
- Golden Core stage (Ch 31-60) includes Core Formation failure at Ch 43, recovery through Ch 44-47, success at Ch 50, Su Yue captured at Ch 57-60
- Nascent Soul stage (Ch 61-90) includes Su Yue rescue aftermath, sect war at Ch 74-80, heart demon tribulation at Ch 81-86, forbidden zone seal break at Ch 88-90
- Ascension stage (Ch 91-100) includes origin revelation, heavenly tribulation at Ch 96-98, final battle, and ascension at Ch 100
- StagePrompts returns empty string for Phase 14 chapters (indices 0-29) since they predate stage-specific prompts

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- StoryOutline with 100 chapters ready for Plans 15-02 through 15-06 to consume
- StagePrompts.forChapterIndex() ready for serial generation scripts to inject stage-specific context
- Downstream plans can import both helpers and reference chapters by index 0-99

---
*Phase: 15-full-manuscript-story-structure*
*Completed: 2026-06-08*
