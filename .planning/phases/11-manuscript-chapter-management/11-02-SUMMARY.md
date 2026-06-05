---
phase: 11-manuscript-chapter-management
plan: 02
subsystem: application, infra
tags: [hive, riverpod, async_notifier, repository, auto_save, debounce, soft_delete, purge]

# Dependency graph
requires:
  - phase: 11-manuscript-chapter-management
    provides: Manuscript/Chapter domain entities, Hive TypeAdapters, ManuscriptGenre utility
provides:
  - ManuscriptRepository with CRUD + soft delete + purge queries
  - ChapterRepository with CRUD + manuscript-scoped queries + document content update
  - ManuscriptPurgeService with 30-day cascade deletion
  - ManuscriptNotifier with create (auto-creates first chapter), save, softDelete, purgeDeleted, searchByTitle
  - ChapterNotifier with loadChapters, add, save, delete, reorder (sequential sortOrder), duplicateChapter, splitChapter, mergeChapters
  - ChapterAutoSave with 2s debounce + forceSave
  - ManuscriptSortMode enum + compareManuscripts comparator
  - All 6 providers registered in providers.dart
affects: [11-03, 11-04, 11-05, 11-06]

# Tech tracking
tech-stack:
  added: []
  patterns: [Hive repository with soft delete, AsyncNotifier two-phase loading, debounced auto-save with dirty flag, sequential sortOrder recalculation]

key-files:
  created:
    - lib/features/manuscript/infrastructure/manuscript_repository.dart
    - lib/features/manuscript/infrastructure/chapter_repository.dart
    - lib/features/manuscript/infrastructure/manuscript_purge_service.dart
    - lib/features/manuscript/application/manuscript_notifier.dart
    - lib/features/manuscript/application/chapter_notifier.dart
    - lib/features/manuscript/application/chapter_auto_save.dart
    - lib/features/manuscript/application/manuscript_sort.dart
    - test/features/manuscript/infrastructure/manuscript_repository_test.dart
    - test/features/manuscript/infrastructure/chapter_repository_test.dart
    - test/features/manuscript/infrastructure/manuscript_purge_service_test.dart
    - test/features/manuscript/application/manuscript_sort_test.dart
    - test/features/manuscript/application/manuscript_notifier_test.dart
    - test/features/manuscript/application/chapter_notifier_test.dart
    - test/features/manuscript/application/chapter_auto_save_test.dart
  modified:
    - lib/core/presentation/providers.dart

key-decisions:
  - "ChapterNotifier uses two-phase loading: build() returns empty list, loadChapters(manuscriptId) populates state"
  - "ManuscriptNotifier.create auto-creates first chapter titled '第一章' with empty content"
  - "ChapterAutoSave._flush uses _isDirty flag to prevent redundant writes (T-11-03 mitigation)"
  - "ChapterNotifier.reorder recalculates ALL sortOrder values to sequential after every operation (T-11-05 mitigation)"
  - "ManuscriptPurgeService returns purged count for startup logging"

patterns-established:
  - "Repository soft-delete pattern: getAll filters deletedAt != null, getAllIncludingDeleted for admin/purge"
  - "Two-phase AsyncNotifier: build() returns empty, loadXxx(id) populates for scoped queries"
  - "Debounced write with dirty flag: onDocumentChanged sets dirty + starts timer, forceSave cancels + flushes"

requirements-completed: [SC-1, SC-2, SC-4]

# Metrics
duration: 17min
completed: 2026-06-05
---

# Phase 11 Plan 02: Application & Infrastructure Layers Summary

**Hive repositories with soft-delete/purge, Riverpod AsyncNotifiers for manuscript/chapter CRUD, debounced auto-save, and sort utility with 68 tests**

## Performance

- **Duration:** 17 min
- **Started:** 2026-06-05T20:08:00Z
- **Completed:** 2026-06-05T20:24:55Z
- **Tasks:** 3
- **Files modified:** 15 (7 source + 7 test + 1 modified)

## Accomplishments

- ManuscriptRepository with full CRUD, soft delete, getAllIncludingDeleted, purgeOlderThan, hardDelete
- ChapterRepository with full CRUD, getByManuscriptId (sorted by sortOrder), updateDocumentContent, deleteByManuscriptId
- ManuscriptPurgeService with 30-day cascade deletion (chapters first, then manuscripts)
- ManuscriptNotifier with create (auto-creates first chapter), save, softDelete, purgeDeleted, searchByTitle
- ChapterNotifier with loadChapters, reorder (sequential sortOrder recalculation), duplicateChapter, splitChapter, mergeChapters
- ChapterAutoSave with 2-second debounce + immediate forceSave, dirty flag to prevent redundant writes
- ManuscriptSortMode enum + compareManuscripts comparator for library sorting
- All 6 providers registered in providers.dart
- 68 total tests passing (25 infrastructure + 15 notifier + 6 auto-save + 22 domain from Plan 01)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create repositories, purge service, and sort utility** - `173fc62` (test/feat combined) -- TDD
2. **Task 2: Create ManuscriptNotifier and ChapterNotifier** - `004b3dc` (feat)
3. **Task 3: Create ChapterAutoSave and register all providers** - `6eb0b7e` (feat)
4. **Documentation: Purge service and sort utility docs** - `f79859b` (docs)

## Files Created/Modified

- `lib/features/manuscript/infrastructure/manuscript_repository.dart` - Hive box wrapper: CRUD + soft delete + getAllIncludingDeleted + purgeOlderThan + hardDelete (150 lines)
- `lib/features/manuscript/infrastructure/chapter_repository.dart` - Hive box wrapper: CRUD + getByManuscriptId + updateDocumentContent + deleteByManuscriptId (131 lines)
- `lib/features/manuscript/infrastructure/manuscript_purge_service.dart` - 30-day cascade purge service (60 lines)
- `lib/features/manuscript/application/manuscript_notifier.dart` - AsyncNotifier for manuscript CRUD with auto-chapter creation (99 lines)
- `lib/features/manuscript/application/chapter_notifier.dart` - AsyncNotifier for chapter CRUD with reorder, split, merge, duplicate (209 lines)
- `lib/features/manuscript/application/chapter_auto_save.dart` - Debounced (2s) + forced auto-save with dirty flag (68 lines)
- `lib/features/manuscript/application/manuscript_sort.dart` - SortMode enum + comparator function (40 lines)
- `lib/core/presentation/providers.dart` - Added 6 manuscript/chapter providers + imports
- `test/features/manuscript/infrastructure/manuscript_repository_test.dart` - 11 ManuscriptRepository tests
- `test/features/manuscript/infrastructure/chapter_repository_test.dart` - 8 ChapterRepository tests
- `test/features/manuscript/infrastructure/manuscript_purge_service_test.dart` - 3 ManuscriptPurgeService tests
- `test/features/manuscript/application/manuscript_sort_test.dart` - 4 ManuscriptSort tests
- `test/features/manuscript/application/manuscript_notifier_test.dart` - 6 ManuscriptNotifier tests
- `test/features/manuscript/application/chapter_notifier_test.dart` - 9 ChapterNotifier tests
- `test/features/manuscript/application/chapter_auto_save_test.dart` - 6 ChapterAutoSave tests

## Decisions Made

- ChapterNotifier uses two-phase loading (build returns empty, loadChapters populates) to avoid needing a FamilyAsyncNotifier while maintaining manuscript-scoped queries
- _refreshWith accepts optional manuscriptId parameter so add/save operations work even when state was previously empty
- ManuscriptNotifier.create auto-creates a first chapter titled "第一章" with empty content, matching D-17 quick-create flow
- ManuscriptPurgeService returns purged count for app startup logging/debugging

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed ChapterNotifier._refreshWith on empty state**
- **Found during:** Task 2 (ChapterNotifier add test)
- **Issue:** `_refreshWith` could not determine manuscriptId when state was empty after build()
- **Fix:** Added optional manuscriptId parameter to `_refreshWith`, callers pass it from the chapter entity they operate on
- **Files modified:** lib/features/manuscript/application/chapter_notifier.dart
- **Verification:** All 9 ChapterNotifier tests pass including add test
- **Committed in:** 004b3dc (Task 2 commit)

**2. [Rule 3 - Blocking] Used Hive test helper instead of fake Box implementations**
- **Found during:** Task 1 (infrastructure tests)
- **Issue:** Custom `_FakeBox` class could not satisfy Hive's `Box<dynamic>` interface due to type mismatch on `get(dynamic key)` vs `get(String key)`
- **Fix:** Rewrote tests to use real Hive in-memory boxes with `setUpHiveTest()`/`tearDownHiveTest()` pattern from existing test helpers
- **Files modified:** All 3 infrastructure test files
- **Verification:** All 25 infrastructure tests pass
- **Committed in:** 173fc62 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 bug fix, 1 blocking)
**Impact on plan:** Both auto-fixes necessary for correctness and test execution. No scope creep.

## Issues Encountered

None - all tasks executed smoothly after the initial test infrastructure adjustment.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All application and infrastructure layers ready for UI plans (library page, chapter sidebar, editor integration)
- Providers registered and injectable via Riverpod
- ChapterAutoSave ready for integration with SuperEditor document change listeners
- ManuscriptSortMode ready for library page sort toggle UI
- ChapterNotifier split/merge/duplicate ready for chapter context menu integration

---
*Phase: 11-manuscript-chapter-management*
*Completed: 2026-06-05*

## Self-Check: PASSED
