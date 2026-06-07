---
phase: 13-automation-test-harness
plan: 03
plan_name: Flutter Integration Flow Tests
subsystem: automation-test-harness
tags:
  - flutter-integration-test
  - widget-finders
  - fake-adapter
  - hive-test
requires:
  - phase: 13-automation-test-harness
    plan: 01
    provides: AIAdapter abstraction and FakeAdapter provider override
provides:
  - TEST-02 manuscript UI integration flow coverage
  - Stable ValueKeys for manuscript, chapter, AI toolbar, and export finders
  - Error scenario integration tests for empty state, AI anomaly, delete navigation, and rapid operations
affects:
  - integration_test
  - lib/features/manuscript/presentation
  - lib/features/editor/presentation
  - lib/features/story_structure/presentation
tech-stack:
  added: []
  patterns:
    - IntegrationTestWidgetsFlutterBinding with ProviderScope FakeAdapter overrides
    - Hive temp directory lifecycle via test/helpers/hive_test_helper.dart
    - Stable ValueKey-based widget finders for UI automation
key-files:
  created:
    - integration_test/manuscript_flow_test.dart
  modified:
    - lib/features/manuscript/presentation/manuscript_create_dialog.dart
    - lib/features/manuscript/presentation/chapter_sidebar.dart
    - lib/features/manuscript/presentation/chapter_create_dialog.dart
    - lib/features/editor/presentation/floating_toolbar.dart
    - lib/features/story_structure/presentation/export_dialog.dart
key-decisions:
  - "D-03-01: Integration tests override activeProviderProvider and activeApiKeyProvider alongside openaiAdapterProvider so FakeAdapter execution never depends on real local credentials."
  - "D-03-02: Export flow uses ExportDialog directly to verify the required Markdown path and export_button finder without coupling to unrelated story-structure navigation setup."
patterns-established:
  - "Bounded widget pumps: integration tests use short pump intervals instead of unbounded pumpAndSettle where persistent desktop animations can keep frames scheduled."
requirements-completed:
  - TEST-02
metrics:
  completed_at: "2026-06-07T08:41:48Z"
  duration_minutes: 45
  tasks_completed: 2
  files_created: 1
  files_modified: 5
  tests_added: 9
---

# Phase 13 Plan 03: Flutter Integration Flow Tests Summary

## One-Liner

Flutter integration tests now drive manuscript creation, chapter creation, FakeAdapter AI output, export success, and four required error scenarios through stable widget finders.

## Performance

- **Duration:** 45 min
- **Started:** 2026-06-07T07:56:00Z
- **Completed:** 2026-06-07T08:41:48Z
- **Tasks:** 2
- **Files created:** 1
- **Files modified:** 5
- **Tests added:** 9 integration tests

## Accomplishments

- Added six stable `ValueKey` finders across existing presentation widgets for manuscript title, manuscript genre, chapter creation, chapter title, AI synthesis, and export actions.
- Created `integration_test/manuscript_flow_test.dart` with 5 main-flow tests covering launch/empty state, manuscript creation, chapter creation, AI generation, and export.
- Added 4 error scenario tests covering empty library state, FakeAdapter AI anomaly output, post-delete navigation stability, and rapid chapter operations.
- Reused the existing Hive test helper pattern and registered all required Hive adapters, including manuscript/chapter/token audit adapters.
- Ensured AI tests override `openaiAdapterProvider`, `activeProviderProvider`, and `activeApiKeyProvider`, preventing real API key access.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add 6 ValueKeys to existing widgets for integration test finders** — `25f0ca9` (`test`)
2. **Task 2: Flutter integration tests for UI flow and error scenarios (TEST-02)** — `6add52b` (`test`)

## Files Created/Modified

- `integration_test/manuscript_flow_test.dart` — 9 Flutter integration tests using FakeAdapter and temporary Hive storage.
- `lib/features/manuscript/presentation/manuscript_create_dialog.dart` — added `manuscript_title` and `manuscript_genre` keys.
- `lib/features/manuscript/presentation/chapter_sidebar.dart` — added `add_chapter_button` key.
- `lib/features/manuscript/presentation/chapter_create_dialog.dart` — added `chapter_title_field` key.
- `lib/features/editor/presentation/floating_toolbar.dart` — added `ai_synthesis_button` key and forwarded `super.key` through `_ActionButton`.
- `lib/features/story_structure/presentation/export_dialog.dart` — added `export_button` key.

## Decisions Made

- Overrode active provider and API key providers in the integration test app pump so FakeAdapter can execute editor AI flows without real credentials.
- Tested export through `ExportDialog` directly because the plan-required export behavior and `export_button` finder live in that dialog, while story-structure navigation is not the focus of TEST-02.
- Used bounded pump helpers for desktop integration tests to avoid unbounded waits from persistent Flutter desktop animations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added provider credential overrides for FakeAdapter execution**
- **Found during:** Task 2 integration test verification.
- **Issue:** Overriding only `openaiAdapterProvider` left `activeProviderProvider` and `activeApiKeyProvider` unset, so editor AI operations stopped before FakeAdapter streaming.
- **Fix:** Added deterministic fake `AIProvider` storage plus ProviderScope overrides for active provider and API key.
- **Files modified:** `integration_test/manuscript_flow_test.dart`
- **Verification:** `flutter test --no-pub integration_test/manuscript_flow_test.dart` passed all 9 tests.
- **Committed in:** `6add52b`

**2. [Rule 3 - Blocking Issue] Rebuilt Flutter plugin symlinks offline**
- **Found during:** Task 2 verification.
- **Issue:** The first integration test run could not generate Linux build files because Flutter plugin symlink directories were missing.
- **Fix:** Ran `flutter pub get --offline` to regenerate local plugin symlinks without installing new packages.
- **Files modified:** none.
- **Verification:** Subsequent integration test build succeeded and all 9 integration tests passed.
- **Committed in:** not applicable (environment repair only)

**3. [Rule 1 - Bug] Flushed token audit writes before Hive teardown**
- **Found during:** Task 2 integration test verification.
- **Issue:** Editor AI tests scheduled debounced token audit writes; teardown closed Hive before the timer flushed, causing post-test `Box has already been closed` errors.
- **Fix:** Added `_flushTokenAudit()` calls after AI operation assertions.
- **Files modified:** `integration_test/manuscript_flow_test.dart`
- **Verification:** `flutter test --no-pub integration_test/manuscript_flow_test.dart` passed all 9 tests.
- **Committed in:** `6add52b`

**4. [Rule 1 - Bug] Avoided unbounded waits from persistent desktop animations**
- **Found during:** Task 2 integration test verification.
- **Issue:** `pumpAndSettle()` hung on desktop integration tests while persistent animations remained scheduled.
- **Fix:** Added bounded `_pumpFrame()` helper and explicit widget-tree disposal for editor tests that mount SuperEditor.
- **Files modified:** `integration_test/manuscript_flow_test.dart`
- **Verification:** `flutter test --no-pub integration_test/manuscript_flow_test.dart` passed all 9 tests.
- **Committed in:** `6add52b`

---

**Total deviations:** 4 auto-fixed (2 bugs, 1 missing critical functionality, 1 blocking environment repair)
**Impact on plan:** All fixes were required to make the planned integration tests deterministic and credential-safe. No product scope was added.

## Issues Encountered

- `flutter analyze` without `--no-pub` attempted to contact pub.dev and failed due network refusal. Re-ran analyzer with `--no-pub`, which is appropriate after dependencies were already available locally.
- Full `flutter test --no-pub` still reports 24 pre-existing unrelated failures in `synthesis_notifier_test.dart` and related suites. This matches the Phase 12 deferred item and was not caused by this plan.

## Verification

- `flutter analyze --no-pub integration_test/manuscript_flow_test.dart` — passed.
- `flutter test --no-pub integration_test/manuscript_flow_test.dart` — passed, 9/9 tests.
- `flutter analyze --no-pub lib/features/manuscript/presentation/manuscript_create_dialog.dart lib/features/manuscript/presentation/chapter_sidebar.dart lib/features/manuscript/presentation/chapter_create_dialog.dart lib/features/editor/presentation/floating_toolbar.dart lib/features/story_structure/presentation/export_dialog.dart` — no errors; reports two pre-existing info-level issues in `chapter_sidebar.dart` unrelated to key additions.
- `flutter test --no-pub` — failed with 24 pre-existing unrelated failures; not fixed under scope boundary.

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `lib/features/story_structure/presentation/export_dialog.dart` | 48 | Existing placeholder comment for future `file_picker` integration; not introduced by this plan. |
| `lib/features/editor/presentation/floating_toolbar.dart` | 244-245 | Existing TODO to pass manuscript/chapter IDs to token audit context; not introduced by this plan and tracked as Phase 12/14 deferred context wiring. |

## Threat Flags

None. This plan introduced no new production network endpoints, auth paths, file access patterns, or schema changes. Test-only Hive temp storage and FakeAdapter overrides follow the threat model mitigations.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- TEST-02 is complete and can be used by later automation phases as the user-facing manuscript flow smoke test.
- Stable widget keys are available for verifier agents and future integration tests.
- Remaining full-suite failures are pre-existing and should stay tracked outside this plan.

## Self-Check: PASSED

Created files verified:

- `integration_test/manuscript_flow_test.dart`

Modified files verified:

- `lib/features/manuscript/presentation/manuscript_create_dialog.dart`
- `lib/features/manuscript/presentation/chapter_sidebar.dart`
- `lib/features/manuscript/presentation/chapter_create_dialog.dart`
- `lib/features/editor/presentation/floating_toolbar.dart`
- `lib/features/story_structure/presentation/export_dialog.dart`

Commits verified:

- `25f0ca9` — task 1 widget key commit exists.
- `6add52b` — task 2 integration test commit exists.

No shared orchestrator artifacts (`STATE.md`, `ROADMAP.md`) were modified by this executor.

---
*Phase: 13-automation-test-harness*
*Completed: 2026-06-07*
