---
phase: 05-story-structure-format-export
plan: 02
subsystem: story-structure, guardian
tags: [hive, riverpod, flutter, plot-nodes, guardian, ai-checks, tdd]

# Dependency graph
requires:
  - phase: 04-knowledge-base-skill-system
    provides: "Hive adapter pattern, Riverpod provider structure, CharacterCard model"
  - plan: 05-01
    provides: "StoryStructurePage tab structure, ForeshadowingEntry model, Hive adapter pattern"
provides:
  - "PlotNode domain model with writing status and structural role enums"
  - "GuardianAnnotation domain model with finding kind and severity enums"
  - "PlotNodeRepository with CRUD, chapter sorting, order saving"
  - "GuardianAnnotationRepository with CRUD, active queries, dismissal"
  - "PlotNodeNotifier and GuardianNotifier with async state management"
  - "GuardianCheckService with CharacterSource abstraction for testable AI checks"
  - "PlotTimeline and PlotNodeForm for timeline-first node management"
  - "GuardianPanel with manual check trigger, finding cards, and copyable suggestions"
  - "GuardianAnnotationOverlay for editor-side collapsible panel"
affects: [05-03, 05-04]

# Tech tracking
tech-stack:
  added: []
  patterns: "CharacterSource abstraction for testable AI service; copyWith clearX pattern for nullable fields"

key-files:
  created:
    - lib/features/story_structure/domain/plot_node.dart
    - lib/features/story_structure/domain/guardian_annotation.dart
    - lib/features/story_structure/infrastructure/plot_node_repository.dart
    - lib/features/story_structure/infrastructure/guardian_annotation_repository.dart
    - lib/features/story_structure/application/plot_node_notifier.dart
    - lib/features/story_structure/application/guardian_notifier.dart
    - lib/features/story_structure/application/guardian_check_service.dart
    - lib/features/story_structure/presentation/plot_timeline.dart
    - lib/features/story_structure/presentation/plot_node_form.dart
    - lib/features/story_structure/presentation/guardian_panel.dart
    - lib/features/story_structure/presentation/guardian_annotation_overlay.dart
    - test/features/story_structure/domain/plot_node_test.dart
    - test/features/story_structure/domain/guardian_annotation_test.dart
    - test/features/story_structure/infrastructure/plot_node_repository_test.dart
    - test/features/story_structure/application/plot_node_notifier_test.dart
    - test/features/story_structure/application/guardian_check_service_test.dart
    - test/features/story_structure/presentation/guardian_annotation_test.dart
  modified:
    - lib/core/infrastructure/hive_adapters.dart
    - lib/core/presentation/providers.dart
    - lib/main.dart
    - lib/features/story_structure/presentation/story_structure_page.dart

key-decisions:
  - "CharacterSource interface decouples GuardianCheckService from Hive for testing"
  - "copyWith clearX boolean pattern for nullable fields (clearUpdatedAt, clearNodeId, etc.)"
  - "GuardianPanel uses amber (#F59E0B) and violet (#8B5CF6) styling distinct from Phase 3 red/green diff and blue provenance"
  - "GuardianCheckService uses non-streaming OpenAI client for check calls (not streaming adapter)"
  - "PlotNodeForm as AlertDialog following ForeshadowingForm pattern"
  - "StoryStructurePage replaces Plot Timeline and Guardian placeholders with real widgets"

patterns-established:
  - "CharacterSource abstraction: testable AI service without Hive dependency"
  - "copyWith clearX pattern: explicit nullable field clearing without sentinel values"
  - "Guardian check lifecycle: idle/checking/results/error state machine in GuardianNotifier"

requirements-completed: [STRC-03, STRC-04]

# Metrics
duration: 14m
completed: 2026-06-04
---

# Plan 05-02: Plot Node Management and Character Consistency Guardian

PlotNode domain/persistence/UI with timeline-first display, GuardianAnnotation domain/persistence/UI with advisory-only suggestions, and manual character consistency check service with CharacterSource abstraction for testable AI calls.

## Performance

- **Duration:** 14 minutes
- **Tasks:** 4
- **Files modified:** 18 (11 created, 7 modified)
- **Tests:** 53 tests passing (30 domain + 9 infrastructure + 10 application + 4 presentation)

## Accomplishments
- PlotNode immutable model with PlotNodeWritingStatus and PlotNodeStructuralRole enums
- GuardianAnnotation immutable model with GuardianFindingKind and GuardianSeverity enums
- PlotNodeRepository with chapter sorting, manual order saving
- GuardianAnnotationRepository with active/dismiss queries
- PlotNodeNotifier and GuardianNotifier with Riverpod AsyncNotifier pattern
- GuardianCheckService with CharacterSource interface for testable AI calls
- Prompt building with relevant character context by name/alias matching
- Defensive JSON parsing handling code blocks, malformed input, missing fields
- PlotTimeline with chapter-grouped node cards and role/status chips
- PlotNodeForm as AlertDialog for create and edit
- GuardianPanel with manual check trigger, finding cards, copyable suggestions
- GuardianAnnotationOverlay as collapsible editor-side panel
- StoryStructurePage replaces Plot Timeline and Guardian tab placeholders

## Task Commits

1. **Task 1: PlotNode and GuardianAnnotation domain models** - `d6bbe25` (test) + `ad286b1` (feat)
2. **Task 2: Plot and guardian repositories/providers/notifiers** - `fab7273` (test) + `51288e2` (feat)
3. **Task 3: Manual character consistency guardian service** - `57fde7c` (test) + `d5ad1c8` (feat)
4. **Task 4: Plot timeline UI and editor guardian annotations** - `9021c13` (feat)

## Decisions Made
- CharacterSource interface abstracts character data access so GuardianCheckService can be tested without Hive
- copyWith clearX boolean pattern for nullable fields avoids sentinel value complexity
- Guardian styling uses amber/violet palette distinct from Phase 3 red/green diff and blue provenance
- Non-streaming OpenAI client for guardian checks (simpler response parsing than streaming)
- PlotNodeForm follows ForeshadowingForm AlertDialog pattern for consistency

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] copyWith nullable field handling**
- **Found during:** Task 1 GREEN phase
- **Issue:** `copyWith(updatedAt: null)` kept old value because `??` treats null as "use default"
- **Fix:** Added `clearUpdatedAt`, `clearNodeId`, etc. boolean parameters to copyWith
- **Files modified:** plot_node.dart, guardian_annotation.dart
- **Commit:** ad286b1

**2. [Rule 1 - Bug] Test import path for Hive test helper**
- **Found during:** Task 2 GREEN phase
- **Issue:** Repository test used wrong relative import path `../../../../helpers/` instead of `../../../helpers/`
- **Fix:** Corrected to `../../../helpers/hive_test_helper.dart`
- **Files modified:** plot_node_repository_test.dart
- **Commit:** 51288e2

**3. [Rule 1 - Bug] GuardianPanel missing Text widget closing parenthesis**
- **Found during:** Task 4 flutter analyze
- **Issue:** `Text('你仍然是最终判断者。')` had `textAlign` outside the Text widget
- **Fix:** Moved `textAlign` inside the Text widget constructor
- **Files modified:** guardian_panel.dart
- **Commit:** 9021c13

**4. [Rule 1 - Bug] Unused colorScheme variables in PlotTimeline**
- **Found during:** Task 4 flutter analyze
- **Issue:** Two `colorScheme` declarations not referenced
- **Fix:** Removed unused variable declarations
- **Files modified:** plot_timeline.dart
- **Commit:** 9021c13

---

**Total deviations:** 4 auto-fixed (1 copyWith pattern, 1 import path, 2 lint issues)
**Impact on plan:** Minor cleanups only. No scope creep.

## Deferred Issues

- **Notifier tests blocked by pre-existing compilation errors:** `synthesis_notifier.dart` uses `pipeline.build(context)` which doesn't exist on `AsyncValue<PromptPipeline>`, and `editor_ai_notifier.dart` has ambiguous imports. Both cause compilation failures for any test importing `providers.dart`. The existing `foreshadowing_notifier_test.dart` has the same issue. This is out of scope for Plan 05-02.

## Next Phase Readiness
- PlotNode model, repository, notifier ready for Plan 05-03 (logic/timeline/world/skill guardian)
- GuardianCheckService and GuardianNotifier ready for additional check types in 05-03
- StoryStructurePage Plot Timeline and Guardian tabs active, Finish & Export still placeholder for 05-04
- GuardianAnnotationOverlay ready for editor integration in later plans

---
*Phase: 05-story-structure-format-export*
*Completed: 2026-06-04*

## Self-Check: PASSED

- All 11 created files verified present
- All 7 commits verified in git log
- 53 tests passing across 5 test suites
- `flutter analyze` reports 0 errors (4 info-level lints only)
