---
phase: 05-story-structure-format-export
plan: 04
subsystem: story-structure, export
tags: [format-cleaner, export, chinese-punctuation, markdown-cleanup, flutter, riverpod, tdd]

# Dependency graph
requires:
  - phase: 05-story-structure-format-export/05-01
    provides: ForeshadowingEntry domain, ForeshadowingNotifier
  - phase: 05-story-structure-format-export/05-02
    provides: PlotNode domain, PlotNodeNotifier, GuardianAnnotation, GuardianNotifier
  - phase: 04-knowledge-base-skill-system
    provides: CharacterCard, WorldSetting, SkillDocument, notifiers
provides:
  - FormatCleanResult and FormatChange domain models
  - Deterministic FormatCleaner with punctuation, Markdown, whitespace passes
  - ExportBundle with complete structured story data
  - ExportService with TXT, Markdown, JSON builders and injectable file writer
  - FormatCleanPreviewDialog with preview-first confirmation flow
  - ExportDialog with format selection and local path picker
  - Story structure page Finish & Export section integration
  - SettingsRepository lastExportPath methods
affects: [phase-06-export-enhancements, story-structure-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Deterministic cleanup passes with structured change preview"
    - "Injectable file writer abstraction for export testability"
    - "Preview-first flow: no mutation before explicit confirmation"

key-files:
  created:
    - lib/features/story_structure/domain/format_clean_result.dart
    - lib/features/story_structure/domain/export_bundle.dart
    - lib/features/story_structure/application/format_cleaner.dart
    - lib/features/story_structure/application/export_service.dart
    - lib/features/story_structure/presentation/format_clean_preview_dialog.dart
    - lib/features/story_structure/presentation/export_dialog.dart
    - test/features/story_structure/application/format_cleaner_test.dart
    - test/features/story_structure/domain/export_bundle_test.dart
    - test/features/story_structure/application/export_service_test.dart
    - test/features/story_structure/presentation/format_export_test.dart
  modified:
    - lib/features/story_structure/presentation/story_structure_page.dart
    - lib/core/infrastructure/settings_repository.dart
    - lib/core/presentation/providers.dart

key-decisions:
  - "FormatCleaner is pure deterministic with no AI dependency"
  - "ExportService uses injectable FileWriter for testability"
  - "ExportDialog path input is a text field fallback; production uses file_picker"
  - "JSON export is complete per D-16: manuscript + all structured story data"

patterns-established:
  - "Format cleanup preview: FormatCleaner.clean() returns FormatCleanResult with changes list, UI disables Apply until preview generated"
  - "Export bundle: ExportBundle aggregates all story data into single serializable object with schema version"
  - "File writer injection: ExportService takes FileWriter typedef for dart:io / test swappability"

requirements-completed: [FRMT-01, FRMT-02, FRMT-03, FRMT-04]

# Metrics
duration: 23min
completed: 2026-06-04
---

# Phase 5 Plan 04: Format Cleaning and Export Summary

**Deterministic format cleaner with Chinese punctuation/Markdown/whitespace passes, preview-first confirmation dialog, and complete TXT/Markdown/JSON export to local files**

## Performance

- **Duration:** 23 min
- **Started:** 2026-06-04T02:22:07Z
- **Completed:** 2026-06-04T02:45:49Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- FormatCleaner with 6 deterministic passes: punctuation normalization, Markdown heading/list/emphasis/HTML cleaning, whitespace normalization, paragraph spacing collapse
- Conservative CJK punctuation conversion that preserves URLs, decimal numbers, file paths, model versions, and English abbreviations
- ExportBundle aggregating manuscript text with foreshadowing, plot nodes, guardian annotations, character cards, world settings, skill documents, and metadata
- ExportService with TXT/Markdown/JSON builders and injectable file writer for testability
- FormatCleanPreviewDialog requiring explicit preview generation before Apply is enabled
- ExportDialog with format selector, local path picker, progress/success/error states
- All 59 plan tests pass (32 format cleaner + 20 export + 7 UI), 204 total story_structure tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Format clean result model and deterministic cleaner** - `1162a53` (feat) [TDD: RED+GREEN]
2. **Task 2: ExportBundle and ExportService** - `3e09e7a` (feat) [TDD: RED+GREEN]
3. **Task 3: Preview-first cleanup and export UI integration** - `be0a34f` (feat)

## Files Created/Modified
- `lib/features/story_structure/domain/format_clean_result.dart` - FormatCleanResult, FormatChange, FormatChangeCategory models
- `lib/features/story_structure/domain/export_bundle.dart` - ExportBundle with complete structured story data and JSON serialization
- `lib/features/story_structure/application/format_cleaner.dart` - Deterministic FormatCleaner with 6 cleanup passes and FormatCleanOptions
- `lib/features/story_structure/application/export_service.dart` - ExportService with TXT/Markdown/JSON builders, ExportFormat enum, FileWriter typedef
- `lib/features/story_structure/presentation/format_clean_preview_dialog.dart` - Preview-first dialog with change categories and explicit Apply
- `lib/features/story_structure/presentation/export_dialog.dart` - Export dialog with format selection, path picker, progress states
- `lib/features/story_structure/presentation/story_structure_page.dart` - Replaced placeholder with real Finish & Export section
- `lib/core/infrastructure/settings_repository.dart` - Added getLastExportPath/saveLastExportPath (D-18)
- `lib/core/presentation/providers.dart` - Added exportServiceProvider with dart:io file writer
- `test/features/story_structure/application/format_cleaner_test.dart` - 32 tests: punctuation, Markdown, whitespace, idempotence, options
- `test/features/story_structure/domain/export_bundle_test.dart` - 4 tests: serialization round-trip
- `test/features/story_structure/application/export_service_test.dart` - 16 tests: TXT/Markdown/JSON builders, file writing, format selection
- `test/features/story_structure/presentation/format_export_test.dart` - 7 tests: preview flow, export dialog, path feedback

## Decisions Made
- FormatCleaner is pure deterministic with no AI dependency -- format cleanup remains available offline
- ExportService uses injectable FileWriter typedef for testability -- production uses dart:io, tests use in-memory recorder
- ExportDialog path input is a text field fallback; production integration will swap in FilePicker.platform.saveFile
- JSON export is complete per D-16: manuscript text plus all foreshadowing, plot nodes, guardian annotations, character cards, world settings, skill documents, active skill IDs, and metadata
- Chinese punctuation normalization uses context-aware checks to preserve URLs, decimals, abbreviations, file paths, and model versions

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] URL punctuation corruption in FormatCleaner**
- **Found during:** Task 1 (FormatCleaner implementation)
- **Issue:** Half-width colon in `https:` was being converted to full-width `https：`, corrupting URLs
- **Fix:** Added protocol-colon detection to `_isInUrl` method, checking for `http`/`https` prefix before the colon
- **Files modified:** lib/features/story_structure/application/format_cleaner.dart
- **Verification:** Test "should NOT corrupt URLs" passes
- **Committed in:** 1162a53 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Bug fix necessary for correctness. No scope creep.

## Known Stubs

| Stub | File | Description | Intentional |
|------|------|-------------|-------------|
| Path input dialog | export_dialog.dart:_PathInputDialog | Text field fallback for file_picker; production will use FilePicker.platform.saveFile | Yes - file_picker integration at production call site |

## Issues Encountered
- super_editor's MutableDocument does not expose `.nodes` getter -- it implements `Iterable<DocumentNode>`, so direct iteration with `for (final node in document)` works correctly
- Riverpod version in this project does not have `valueOrNull` on AsyncValue -- used `.asData?.value` instead

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Format cleanup and export fully functional with tests
- JSON export includes complete structured story data for local backup/migration
- FormatCleanPreviewDialog and ExportDialog are reusable widgets
- Production integration should replace _PathInputDialog with FilePicker.platform.saveFile

---
*Phase: 05-story-structure-format-export*
*Completed: 2026-06-04*

## Self-Check: PASSED

All 11 created files verified present. All 4 commit hashes verified in git log.
