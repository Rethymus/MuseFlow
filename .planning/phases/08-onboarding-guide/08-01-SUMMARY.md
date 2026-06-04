---
phase: 08-onboarding-guide
plan: 01
subsystem: routing, infrastructure
tags: [go_router, hive, redirect-guard, first-run, onboarding]

# Dependency graph
requires:
  - phase: 01-app-shell-editor-capture-ui
    provides: go_router setup, AppConstants, app.dart structure
provides:
  - OnboardingProgress immutable value object with JSON serialization
  - OnboardingProgressRepository for Hive settings box persistence
  - go_router redirect callback for first-run detection
  - /onboarding top-level route (full-screen, outside StatefulShellRoute)
  - onboardingProgressProvider registered in providers.dart
affects: [08-02, 08-03, 08-04, 08-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Redirect guard: go_router redirect callback reads Hive box directly for first-run detection"
    - "Top-level onboarding route outside StatefulShellRoute for full-screen display"
    - "SettingsRepository.box getter for sibling repository access"

key-files:
  created:
    - lib/features/onboarding/domain/onboarding_progress.dart
    - lib/features/onboarding/infrastructure/onboarding_progress_repository.dart
    - lib/features/onboarding/presentation/onboarding_wizard_page.dart
    - test/features/onboarding/application/onboarding_progress_test.dart
    - test/features/onboarding/application/onboarding_redirect_test.dart
  modified:
    - lib/app.dart
    - lib/shared/constants/app_constants.dart
    - lib/core/presentation/providers.dart
    - lib/core/infrastructure/settings_repository.dart

key-decisions:
  - "Manual immutable class pattern (not freezed) for OnboardingProgress — consistent with existing domain models like ForeshadowingEntry"
  - "OnboardingProgressRepository takes Box<dynamic> directly — follows SettingsRepository pattern"
  - "Added box getter to SettingsRepository for sibling repository access — avoids opening box twice"
  - "OnboardingWizardPage stub created now to avoid compile errors — full implementation deferred to Plan 08-02"

patterns-established:
  - "Redirect guard: _handleRedirect reads Hive.box('settings') for first-run flags"
  - "Top-level route for full-screen flows (onboarding outside StatefulShellRoute.indexedStack)"

requirements-completed: [ONBD-01, ONBD-03, ONBD-06]

# Metrics
duration: 6m
completed: 2026-06-04
---

# Phase 8 Plan 01: First-Run Detection & Redirect Summary

**go_router redirect guard with Hive-based first-run detection, OnboardingProgress domain model, and progress persistence via settings box**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-04T13:29:03Z
- **Completed:** 2026-06-04T13:35:13Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- OnboardingProgress immutable value object with fromJson/toJson and graceful malformed-data fallback (T-08-02, T-08-03)
- OnboardingProgressRepository persisting wizard progress and completion flag in Hive settings box
- go_router redirect callback detecting fresh installs and routing to /onboarding
- Top-level /onboarding route outside StatefulShellRoute for full-screen wizard display
- 23 tests passing (15 domain/repository + 8 redirect guard)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create OnboardingProgress domain model and repository** - `6c9ed52` (feat)
2. **Task 2: Add onboarding route constant and go_router redirect guard** - `e895ea2` (feat)
3. **Task 3: Register onboardingProgressProvider in providers.dart** - `b7815ae` (feat)

## Files Created/Modified
- `lib/features/onboarding/domain/onboarding_progress.dart` - Immutable value object tracking wizard step, completed steps, and optional selections
- `lib/features/onboarding/infrastructure/onboarding_progress_repository.dart` - Hive settings box persistence with saveProgress, getProgress, markCompleted, isCompleted
- `lib/features/onboarding/presentation/onboarding_wizard_page.dart` - Placeholder stub for Plan 08-02 full implementation
- `lib/app.dart` - Added _handleRedirect callback and top-level /onboarding GoRoute
- `lib/shared/constants/app_constants.dart` - Added onboarding route constant
- `lib/core/presentation/providers.dart` - Registered onboardingProgressProvider depending on settingsRepositoryProvider
- `lib/core/infrastructure/settings_repository.dart` - Added box getter for sibling repository access
- `test/features/onboarding/application/onboarding_progress_test.dart` - 15 tests for model and repository
- `test/features/onboarding/application/onboarding_redirect_test.dart` - 8 tests for redirect guard logic

## Decisions Made
- Used manual immutable class pattern (not freezed) for OnboardingProgress to match existing codebase conventions (ForeshadowingEntry, PlotNode)
- Added `box` getter to SettingsRepository so OnboardingProgressRepository can share the same encrypted Hive box without opening it separately
- Created OnboardingWizardPage placeholder stub to avoid compile errors in app.dart import; full UI implementation deferred to Plan 08-02
- Redirect callback uses try-catch around Hive.box('settings') read to handle case where box is not yet open during initial app startup

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Pre-existing analyze errors in providers.dart (43 errors from missing knowledge/skill feature files) — out of scope, deferred
- Test import path for hive_test_helper.dart needed correction from `../../../../helpers/` to `../../../helpers/` — fixed immediately

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 08-02 can proceed: OnboardingWizardPage stub exists, route is registered, OnboardingProgress model and repository are ready
- Plan 08-03 can use OnboardingProgressRepository.markCompleted() to finalize onboarding
- The redirect guard will automatically route fresh installs to the wizard once the full page is implemented

---
*Phase: 08-onboarding-guide*
*Completed: 2026-06-04*

## Self-Check: PASSED

All 6 created files verified present. All 4 commits verified in git log.
