---
phase: 11-manuscript-chapter-management
plan: 01
subsystem: domain, infra
tags: [hive, typeadapter, dart, entity, immutable, manuscript, chapter, super_editor_markdown]

# Dependency graph
requires:
  - phase: 00-scaffolding
    provides: HiveTypeIds registry, Fragment entity pattern, hive_adapters.dart
provides:
  - Manuscript domain entity (immutable, copyWith, fromJson/toJson, equality)
  - Chapter domain entity (immutable, copyWith, computed wordCount, fromJson/toJson)
  - ManuscriptGenre utility (14 presets, WCAG AA color mapping, status constants)
  - ChapterExport model (title, sortOrder, content for structured export)
  - ManuscriptAdapter Hive TypeAdapter (typeId=2)
  - ChapterAdapter Hive TypeAdapter (typeId=9)
  - super_editor_markdown package installed
affects: [11-02, 11-03, 11-04, 11-05, 11-06]

# Tech tracking
tech-stack:
  added: [super_editor_markdown ^0.2.0]
  patterns: [immutable entity with copyWith/fromJson/toJson, Hive TypeAdapter delegation, computed getter for wordCount]

key-files:
  created:
    - lib/features/manuscript/domain/manuscript.dart
    - lib/features/manuscript/domain/chapter.dart
    - lib/features/manuscript/domain/manuscript_genre.dart
    - lib/features/manuscript/domain/chapter_export.dart
    - test/features/manuscript/domain/manuscript_test.dart
    - test/features/manuscript/domain/manuscript_genre_test.dart
    - test/features/manuscript/domain/chapter_test.dart
    - test/features/manuscript/domain/chapter_export_test.dart
  modified:
    - lib/core/infrastructure/hive_adapters.dart
    - lib/main.dart
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "ManuscriptGenre maps 14 preset genres to 14 visually distinct opaque colors with WCAG AA contrast"
  - "Chapter.wordCount is a computed getter using whitespace-stripped character count"
  - "Chapter documentContent stores serialized Markdown (NOT JSON) per RESEARCH.md correction"
  - "super_editor_markdown installed despite deprecated status (merged into super_editor core)"

patterns-established:
  - "Manuscript feature module at lib/features/manuscript/ with domain/ layer"
  - "Hive TypeAdapter delegation pattern: read -> fromJson, write -> toJson"

requirements-completed: [SC-1, SC-2, SC-3, SC-5, SC-6]

# Metrics
duration: 6min
completed: 2026-06-05
---

# Phase 11 Plan 01: Domain Entities & Hive Adapters Summary

**Manuscript/Chapter immutable entities with Hive TypeAdapters, ManuscriptGenre color utility, ChapterExport model, and super_editor_markdown installed**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-05T19:57:36Z
- **Completed:** 2026-06-05T20:03:27Z
- **Tasks:** 3
- **Files modified:** 12 (4 source + 4 test + 2 modified + 2 pubspec)

## Accomplishments

- Manuscript entity with all 12 D-03 fields (id, title, description, genre, targetWordCount, status, worldSettingId, characterCardIds, createdAt, updatedAt, deletedAt, coverLetter)
- Chapter entity with all 8 D-04 fields plus computed wordCount getter
- ManuscriptGenre utility with 14 preset genres mapped to distinct WCAG AA-compliant colors, plus status/chapterStatus constants
- ChapterExport model ready for export integration
- ManuscriptAdapter (typeId=2) and ChapterAdapter (typeId=9) registered in Hive
- super_editor_markdown installed for Markdown serialization
- 22 domain unit tests passing

## Task Commits

Each task was committed atomically:

1. **Task 1: Install super_editor_markdown and create Manuscript + ManuscriptGenre entities** - `f168e3f` (feat) -- TDD: tests first, then implementation
2. **Task 2: Create Chapter and ChapterExport entities** - `c86c21c` (feat) -- TDD: tests first, then implementation
3. **Task 3: Add Hive TypeAdapters and register in main.dart** - `27d20d1` (feat)

## Files Created/Modified

- `lib/features/manuscript/domain/manuscript.dart` - Manuscript immutable entity with copyWith, fromJson/toJson, equality (12 fields)
- `lib/features/manuscript/domain/chapter.dart` - Chapter immutable entity with computed wordCount (8 fields)
- `lib/features/manuscript/domain/manuscript_genre.dart` - 14 genre presets with color mapping, status constants
- `lib/features/manuscript/domain/chapter_export.dart` - ChapterExport model for structured export
- `lib/core/infrastructure/hive_adapters.dart` - Added ManuscriptAdapter (typeId=2), ChapterAdapter (typeId=9), chapter type ID
- `lib/main.dart` - Added Hive.registerAdapter calls for ManuscriptAdapter and ChapterAdapter
- `pubspec.yaml` - Added super_editor_markdown dependency
- `test/features/manuscript/domain/manuscript_test.dart` - 5 Manuscript unit tests
- `test/features/manuscript/domain/manuscript_genre_test.dart` - 6 ManuscriptGenre unit tests
- `test/features/manuscript/domain/chapter_test.dart` - 6 Chapter unit tests
- `test/features/manuscript/domain/chapter_export_test.dart` - 5 ChapterExport unit tests

## Decisions Made

- ManuscriptGenre uses 14 distinct colors: warm/bold for 8 male-frequency genres (indigo, teal, blue, violet, amber-700, amber-800, red-800, gray-700) and soft/elegant for 6 female-frequency genres (cyan, purple-900, pink, emerald, sky, fuchsia)
- Chapter.wordCount counts all characters excluding whitespace, which is the standard Chinese text metric
- super_editor_markdown installed despite being marked deprecated (replaced by super_editor core) -- it still resolves and provides the serialization API

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed character count test expectation**
- **Found during:** Task 2 (Chapter test)
- **Issue:** Test expected 16 characters but the string `'第一回 悟彻菩提真妙理\n断魔归正合元神'` has 17 characters after whitespace removal
- **Fix:** Corrected test expectation from 16 to 17
- **Files modified:** test/features/manuscript/domain/chapter_test.dart
- **Verification:** All 11 Chapter+ChapterExport tests pass
- **Committed in:** c86c21c (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Trivial -- test expectation correction only. No scope creep.

## Issues Encountered

- super_editor_markdown 0.2.0 is marked as discontinued (replaced by super_editor core). The package still installs and resolves correctly against super_editor ^0.3.0-dev.20. No functional impact -- the Markdown serialization API is available.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All domain entities ready for downstream plans (repositories, notifiers, UI widgets)
- Hive TypeAdapters registered, persistence layer can be built in Plan 02
- ManuscriptGenre color mapping ready for library card UI
- ChapterExport ready for export integration

---
*Phase: 11-manuscript-chapter-management*
*Completed: 2026-06-05*

## Self-Check: PASSED

All 9 created files verified present. All 3 task commits verified in git log (f168e3f, c86c21c, 27d20d1).
