---
phase: 08-onboarding-guide
plan: 02
subsystem: ui, wizard
tags: [flutter, pageview, onboarding, genre-selection, grid-view]

# Dependency graph
requires:
  - phase: 08-onboarding-guide/01
    provides: OnboardingProgress model, OnboardingProgressRepository, go_router redirect guard, /onboarding route
provides:
  - OnboardingWizardPage with 4-step PageView and navigation controls
  - GenreStepPage with 14 genre cards in 3-column grid
  - GenreOption built-in domain model (8 male + 6 female channels)
  - Standalone onboardingRepositoryProvider for wizard persistence
  - Stub pages for World/Character/Opening steps
affects: [08-03, 08-04, 08-05]

# Tech tracking
tech-stack:
  added: []
patterns:
  - "Feature-scoped provider: onboardingRepositoryProvider avoids coupling to broken providers.dart chain"
  - "Built-in GenreOption const data: avoids dependency on unimplemented Phase 7 WorldTemplateRepository"
  - "AnimatedContainer for selection highlight with border color transition"
  - "NeverScrollableScrollPhysics on PageView: button-only navigation, no swipe"

key-files:
  created:
    - lib/features/onboarding/domain/genre_option.dart
    - lib/features/onboarding/presentation/onboarding_wizard_page.dart
    - lib/features/onboarding/presentation/onboarding_providers.dart
    - lib/features/onboarding/presentation/wizard_steps/genre_step_page.dart
    - test/features/onboarding/presentation/onboarding_wizard_test.dart
  modified:
    - lib/features/onboarding/presentation/onboarding_wizard_page.dart

key-decisions:
  - "Created GenreOption built-in model instead of depending on Phase 7 WorldTemplateRepository which is not yet implemented"
  - "Created standalone onboardingRepositoryProvider to decouple wizard from broken providers.dart import chain (43 errors from missing knowledge/skill files)"
  - "Combined Task 1 and Task 2 into single feat commit due to mutual dependency (wizard imports GenreStepPage)"
  - "Fixed redundant tags (e.g. 都市 tag on 都市 card) to avoid title/tag text duplication in tests"

patterns-established:
  - "Feature-scoped provider for wizard pages that need persistence without shared provider chain"
  - "Built-in const data list pattern for onboarding genres (could be replaced by Phase 7 templates later)"

requirements-completed: [ONBD-02, ONBD-03]

# Metrics
duration: 14m
completed: 2026-06-04
---

# Phase 8 Plan 02: Onboarding Wizard UI Summary

**4-step PageView wizard with animated progress dots, genre grid selection with 14 built-in Chinese novel categories, and standalone persistence provider**

## Performance

- **Duration:** 14 min
- **Started:** 2026-06-04T13:40:46Z
- **Completed:** 2026-06-04T13:54:52Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Full OnboardingWizardPage with 4-step PageView, animated progress dots, next/previous/skip/close navigation
- GenreStepPage displaying 14 genre cards in a 3-column grid with selection highlight and channel/tag badges
- GenreOption built-in domain model with 8 male-channel and 6 female-channel Chinese novel categories
- Standalone onboardingRepositoryProvider breaking the dependency on the broken providers.dart chain
- 20 tests passing: 8 wizard navigation tests, 4 genre step tests, 5 domain model tests, 3 repository tests

## Task Commits

Each task was committed atomically:

1. **Task 1+2: Create OnboardingWizardPage with PageView and GenreStepPage** - `1562907` (feat)
2. **Test suite for wizard, genre step, and domain model** - `9998637` (test)

## Files Created/Modified
- `lib/features/onboarding/domain/genre_option.dart` - Built-in genre data model with 14 Chinese novel categories as const list
- `lib/features/onboarding/presentation/onboarding_wizard_page.dart` - Full wizard host replacing placeholder stub, with PageView, progress dots, navigation controls, and stub step pages
- `lib/features/onboarding/presentation/onboarding_providers.dart` - Standalone onboardingRepositoryProvider for wizard persistence
- `lib/features/onboarding/presentation/wizard_steps/genre_step_page.dart` - Genre selection grid with AutomaticKeepAliveClientMixin, card selection highlight, _PassiveTag badges
- `test/features/onboarding/presentation/onboarding_wizard_test.dart` - 20 tests covering wizard navigation, genre grid, selection callbacks, domain validation, repository persistence

## Decisions Made
- Created `GenreOption` built-in domain model instead of depending on `WorldTemplateRepository` from Phase 7, which has planning artifacts but no actual code committed. This avoids blocking the onboarding wizard on unimplemented infrastructure.
- Created `onboardingRepositoryProvider` as a standalone provider in `onboarding_providers.dart` instead of using `onboardingProgressProvider` from `providers.dart`, because `providers.dart` has 43 compilation errors from missing knowledge/skill feature files. The wizard page now compiles independently.
- Combined Tasks 1 and 2 into a single commit because `OnboardingWizardPage` directly imports `GenreStepPage` as a PageView child -- they cannot be committed separately without breaking the build.
- Fixed redundant tag values (e.g. `tags: ['都市', '生活']` changed to `tags: ['商战', '生活']`) where the tag duplicated the card title, causing test ambiguity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Phase 7 WorldTemplateRepository does not exist in codebase**
- **Found during:** Task 1 setup (reading reference files)
- **Issue:** Plan references `worldTemplateRepositoryProvider`, `WorldTemplateRepository`, `_TemplateCard`, `_PassiveTag` from Phase 7 template infrastructure. These files were never committed to git despite Phase 7 planning artifacts existing on disk.
- **Fix:** Created `GenreOption` built-in domain model with 14 const genre entries and `GenreStepPage` using the same card pattern but with local data. The genre step can be refactored to use WorldTemplateRepository once Phase 7 code is implemented.
- **Files modified:** Created `lib/features/onboarding/domain/genre_option.dart`
- **Verification:** All 20 tests pass including genre grid rendering and selection
- **Committed in:** `1562907` (Task 1+2 commit)

**2. [Rule 3 - Blocking] providers.dart has 43 compilation errors from missing imports**
- **Found during:** Task 1 (test compilation)
- **Issue:** `providers.dart` imports knowledge/skill application files that don't exist in the codebase. Importing it in test files causes cascading compilation failures.
- **Fix:** Created standalone `onboardingRepositoryProvider` in `lib/features/onboarding/presentation/onboarding_providers.dart` that opens its own Hive box, bypassing the broken provider chain.
- **Files modified:** Created `lib/features/onboarding/presentation/onboarding_providers.dart`
- **Verification:** `flutter analyze lib/features/onboarding/` reports no issues; all 20 tests pass
- **Committed in:** `1562907` (Task 1+2 commit)

**3. [Rule 2 - Missing Critical] Fixed genre tag/title text duplication**
- **Found during:** Task 2 (test execution)
- **Issue:** Several genre cards had tags that duplicated their title (e.g. `都市` card with `tags: ['都市', '生活']`), causing `findsOneWidget` to fail with "Found 2 widgets with text 都市".
- **Fix:** Replaced redundant tags with non-overlapping alternatives (都市->商战, 历史->穿越, 军事->战场, 灵异->怪谈, 穿越->重生, 娱乐圈->明星).
- **Files modified:** `lib/features/onboarding/domain/genre_option.dart`
- **Verification:** All tests pass, each title appears exactly once in the widget tree
- **Committed in:** `1562907` (Task 1+2 commit)

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 missing critical)
**Impact on plan:** Deviations were necessary due to Phase 7 code not being committed and pre-existing providers.dart compilation errors. The wizard functions correctly with built-in data and can be refactored to use WorldTemplateRepository once Phase 7 is implemented.

## Issues Encountered
- Worktree branch was behind the 08-01 merge commit -- resolved by rebasing onto commit `16439e0`
- `Icons.martial_arts` does not exist in Flutter 3.44.0 -- replaced with `Icons.sports_kabaddi`
- `withOpacity` is deprecated in Flutter 3.44.0 -- replaced with `withValues(alpha: 0.3)`
- Pre-existing analyze errors in `providers.dart` (43 errors from missing knowledge/skill files) -- out of scope, not fixed

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 08-03 can proceed: GenreStepPage provides genre selection, OnboardingWizardPage has stub slots for World/Character steps
- Plan 08-04 can use GenreStepPage selection to drive AI generation
- Plan 08-05 can replace the OpeningStepPage stub
- The standalone onboardingRepositoryProvider should eventually be unified with the shared providers.dart once Phase 7 code is committed

---
*Phase: 08-onboarding-guide*
*Completed: 2026-06-04*
