---
phase: 05-story-structure-format-export
plan: 03
subsystem: story-structure, guardian
tags: [riverpod, flutter, guardian, ai-checks, tdd, context-building]

# Dependency graph
requires:
  - plan: 05-01
    provides: "ForeshadowingEntry model, ForeshadowingNotifier"
  - plan: 05-02
    provides: "PlotNode model, GuardianAnnotation model, GuardianCheckService, GuardianNotifier, GuardianPanel"
provides:
  - "GuardianContextBuilder with token-bounded story context assembly"
  - "GuardianContextBundle with relevance-based section selection"
  - "LogicGuardianService with timeline/world/skill/foreshadowing detection"
  - "Extended GuardianNotifier with checkLogic and checkCurrentChapter"
  - "Extended GuardianPanel with kind filters and multi-check buttons"
affects: [05-04]

# Tech tracking
tech-stack:
  added: []
  patterns: "Generic budget-fitting with _BudgetResult<T>; combined check orchestrating multiple AI services"

key-files:
  created:
    - lib/features/story_structure/application/guardian_context_builder.dart
    - lib/features/story_structure/application/logic_guardian_service.dart
    - test/features/story_structure/application/guardian_context_builder_test.dart
    - test/features/story_structure/application/logic_guardian_service_test.dart
  modified:
    - lib/features/story_structure/application/guardian_notifier.dart
    - lib/features/story_structure/presentation/guardian_panel.dart
    - lib/core/presentation/providers.dart

key-decisions:
  - "GuardianContextBuilder receives data as method parameters, not via Riverpod, for testability"
  - "LogicGuardianService mirrors GuardianCheckService pattern but focuses on logic contradictions"
  - "Skill constraints passed as plain List<String> since skill infrastructure not yet in codebase"
  - "Combined checkCurrentChapter runs character + logic checks sequentially, both non-blocking"
  - "GuardianPanel filter chips replace single check button with multi-action layout"

patterns-established:
  - "Generic _BudgetResult<T>: reusable budget-fitting for any item type with token estimation"
  - "Combined guardian check: orchestrates multiple AI services, merges results, non-blocking per-service"
  - "Kind-based finding filter: GuardianFilter enum with chip-based filter row in panel"

requirements-completed: [STRC-05, STRC-04]

# Metrics
duration: 7m
completed: 2026-06-04
---

# Plan 05-03: Logic Guardian and Bounded Context

Token-bounded GuardianContextBuilder assembling relevant story context by name/alias matching and chapter proximity, LogicGuardianService detecting timeline/world/skill/foreshadowing contradictions via AI, and extended GuardianNotifier/Panel with combined checks and kind-based filters.

## Performance

- **Duration:** 7 minutes
- **Tasks:** 3
- **Files modified:** 7 (4 created, 3 modified)
- **Tests:** 35 tests passing (19 context builder + 16 logic guardian)

## Accomplishments
- GuardianContextBuilder with relevance-based character/world/plot/foreshadowing selection
- Token budget bounding via generic _BudgetResult<T> pattern
- GuardianContextBundle with formatAsPrompt for structured AI prompt generation
- Omitted counts exposed per section for transparency
- LogicGuardianService with strict JSON parsing handling code blocks, prose-embedded, malformed input
- Timeline contradiction, world rule conflict, skill rule conflict, unresolved foreshadowing detection
- Non-blocking error handling: malformed JSON returns empty results, never throws
- GuardianNotifier extended with checkLogic and checkCurrentChapter methods
- Combined check orchestrates character + logic services sequentially
- GuardianPanel with Check selected text, Check current chapter buttons
- Finding kind filter chips: character, timeline, world, skill, foreshadowing
- API key missing state shows setup guidance without hiding story structure CRUD

## Task Commits

1. **Task 1: GuardianContextBuilder for bounded story context** - `fe564fd` (test) + `0cacba9` (feat)
2. **Task 2: LogicGuardianService with strict JSON parsing** - `e13e1a4` (test) + `c7debf0` (feat)
3. **Task 3: Integrate logic checks into guardian notifier and panel** - `9c23fe1` (feat)

## Decisions Made
- GuardianContextBuilder receives all data as method parameters for pure testability without Riverpod
- LogicGuardianService mirrors GuardianCheckService constructor pattern (apiKey, baseUrl, model)
- Skill constraints passed as List<String> since SkillDocument infrastructure not yet in codebase at this commit
- Combined check runs services sequentially with per-service non-blocking error handling
- GuardianPanel uses GuardianFilter enum with custom filter chip widgets

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- None. Pre-existing compilation issues in synthesis_notifier.dart and editor_ai_notifier.dart are out of scope.

## Next Phase Readiness
- GuardianContextBuilder and LogicGuardianService ready for Plan 05-04 (Finish & Export)
- Skill constraints can be wired when skill infrastructure merges from phase 04
- GuardianPanel kind filters ready for additional finding types
- Combined check pattern (checkCurrentChapter) can be extended with more services

## Self-Check: PASSED

- All 4 created files verified present
- All 3 modified files verified present
- All 5 commits verified in git log
- 35 tests passing across 2 test suites
- `flutter analyze` reports 0 new errors (all pre-existing)

---
*Phase: 05-story-structure-format-export*
*Completed: 2026-06-04*
