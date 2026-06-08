---
phase: 15-full-manuscript-story-structure
plan: 04
subsystem: testing
tags: [flutter, dart, journey-tests, format-cleaning, export-validation]

requires:
  - phase: 15-full-manuscript-story-structure
    provides: 100-chapter StoryOutline helper and production FormatCleaner/ExportService interfaces
provides:
  - JOURNEY-08 format cleaning validation across all 100 chapters
  - JOURNEY-09 Markdown/TXT/JSON export validation across all 100 chapters
affects: [phase-15-validation, journey-tests, export-validation]

tech-stack:
  added: []
  patterns:
    - Pure Dart service validation through journey-scoped Flutter tests
    - 100-chapter deterministic fixtures without external AI calls

key-files:
  created:
    - test/journey/format_cleaning_test.dart
    - test/journey/export_validation_test.dart
  modified:
    - lib/features/story_structure/application/format_cleaner.dart

key-decisions:
  - "FormatCleaner must remove Markdown code fences as residue, preserving enclosed prose for D-08 correctness."
  - "Export validation expands outline content deterministically to satisfy D-09 30,000-50,000 character range without AI calls."

patterns-established:
  - "Journey-scale tests use StoryOutline.chapters as deterministic 100-chapter source data."
  - "Export assertions validate structure, metadata, content consistency, and size as separate layers."

requirements-completed: [JOURNEY-08, JOURNEY-09]

duration: 47min
completed: 2026-06-08
---

# Phase 15 Plan 04: Format Cleaning and Export Validation Summary

**100-chapter automated validation for format cleaning residue removal and three-format manuscript export integrity**

## Performance

- **Duration:** 47 min
- **Started:** 2026-06-08T04:58:12Z
- **Completed:** 2026-06-08T05:45:39Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `test/journey/format_cleaning_test.dart` to validate D-08 across 100 chapters: Markdown residue, CJK/ASCII punctuation mixing, layout anomalies, and idempotency.
- Added `test/journey/export_validation_test.dart` to validate D-09 across Markdown, TXT, and JSON with structure, metadata, content consistency, and file-size assertions.
- Auto-fixed `FormatCleaner` to strip Markdown code fences so injected and real code-fence residue is removed by the cleaning pipeline.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create format cleaning validation test for 100 chapters** - `747cf54` (test)
2. **Task 2: Create three-format export validation test for 100 chapters** - `c2d16e8` (test)

**Plan metadata:** pending final docs commit

## Files Created/Modified

- `test/journey/format_cleaning_test.dart` - 100-chapter FormatCleaner journey validation for D-08 categories and idempotency.
- `test/journey/export_validation_test.dart` - 100-chapter ExportService validation for Markdown, TXT, JSON, cross-format content, and size bounds.
- `lib/features/story_structure/application/format_cleaner.dart` - Adds code-fence removal pass to Markdown cleanup.

## Decisions Made

- FormatCleaner code-fence removal is required for D-08 correctness because code fences are Markdown residue and the plan explicitly asserts no ``` remains after cleaning.
- Export tests use deterministic content expansion from StoryOutline rather than AI output to keep tests stable, local, and within the D-09 30,000-50,000 character size bounds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] FormatCleaner did not remove Markdown code fences**
- **Found during:** Task 1 (format cleaning validation)
- **Issue:** The new D-08 test failed because `FormatCleaner.clean()` removed headings and emphasis but left ``` fences intact.
- **Fix:** Added `_cleanMarkdownCodeFences()` to strip fenced code markers while preserving enclosed prose.
- **Files modified:** `lib/features/story_structure/application/format_cleaner.dart`
- **Verification:** `dart analyze lib/features/story_structure/application/format_cleaner.dart test/journey/format_cleaning_test.dart` and `flutter test test/journey/format_cleaning_test.dart -j 1 --timeout 120s` passed.
- **Committed in:** `747cf54`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for D-08 correctness; no architecture or external dependency changes.

## Issues Encountered

- Initial export fixture content was below the D-09 30,000-character lower bound; expanded deterministic chapter content and re-ran tests successfully.
- Initial export test used `(_, __)` and triggered an analyzer info; changed to `(_, _)` to keep analysis clean.

## Verification

- `dart analyze test/journey/format_cleaning_test.dart test/journey/export_validation_test.dart` — passed with no issues.
- `flutter test test/journey/format_cleaning_test.dart -j 1 --timeout 120s` — passed, 6 tests.
- `flutter test test/journey/export_validation_test.dart -j 1 --timeout 120s` — passed, 6 tests.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- JOURNEY-08 and JOURNEY-09 automated validation are ready for Phase 15 verification.
- Tests use `FakeAdapter` and no-op file writing, so no GLM key or filesystem export setup is required.

## Self-Check: PASSED

- Created files exist: `test/journey/format_cleaning_test.dart`, `test/journey/export_validation_test.dart`, `.planning/phases/15-full-manuscript-story-structure/15-04-SUMMARY.md`.
- Modified production file exists: `lib/features/story_structure/application/format_cleaner.dart`.
- Task commits exist: `747cf54`, `c2d16e8`.
- Shared orchestrator artifacts `STATE.md` and `ROADMAP.md` were not modified.

---
*Phase: 15-full-manuscript-story-structure*
*Completed: 2026-06-08*
