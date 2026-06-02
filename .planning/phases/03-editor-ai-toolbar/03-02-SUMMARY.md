---
phase: 03-editor-ai-toolbar
plan: 02
subsystem: editor
tags: [flutter, super_editor, riverpod, diff, provenance, inline-diff]

requires:
  - phase: 03-editor-ai-toolbar
    plan: 01
    provides: EditorAIState, SentenceSegmenter, EditorAINotifier, FloatingToolbar
provides:
  - DiffStatus enum with pending/accepted/rejected values
  - SentenceDiff immutable entity with isDeletion/isInsertion/isModification
  - DiffResult with pendingCount and allResolved computed properties
  - DiffCalculator for sentence-level diff computation
  - AI provenance attribution system (NamedAttribution with unique id)
  - Inline diff display overlay (red deletions, green insertions)
  - AcceptRejectBar floating action bar for per-sentence accept/reject
  - StatusBar showing pending AI modification count
  - PopScope leave-page warning for unresolved diffs
affects: [03-03-selective-undo]

tech-stack:
  added: []
  patterns: [sentence-level-diff-pairing, provenance-attribution-overlay, accept-reject-floating-bar]

key-files:
  created:
    - lib/features/editor/domain/diff_state.dart
    - lib/features/editor/application/diff_calculator.dart
    - lib/features/editor/infrastructure/provenance_attribution.dart
    - lib/features/editor/presentation/diff_display.dart
    - lib/features/editor/presentation/status_bar.dart
  modified:
    - lib/features/editor/domain/editor_ai_state.dart
    - lib/features/editor/application/editor_ai_notifier.dart
    - lib/features/editor/presentation/editor_page.dart
    - lib/core/presentation/providers.dart

key-decisions:
  - "NamedAttribution with unique id 'ai_provenance' to avoid BackgroundColorAttribution conflict (Pitfall 2)"
  - "Batched delete+insert in single editor.execute() for one undo entry (Pitfall 5)"
  - "Sentinel pattern for DiffResult field in EditorAIState.copyWith"
  - "DiffCalculator uses SentenceSegmenter for Chinese sentence-level pairing"

patterns-established:
  - "Sentence-level diff pairing via DiffCalculator.calculate with equal/unequal sentence count handling"
  - "Provenance attribution via ToggleTextAttributionsRequest through editor command pipeline"
  - "AcceptRejectBar using same SelectionLayerLinks + Follower.withOffset pattern as FloatingToolbar"

requirements-completed: [EDIT-05]

duration: 8min
completed: 2026-06-02
---

# Phase 03 Plan 02: Text Provenance Tracking Summary

**Sentence-level inline diff display with red deletions, green insertions, accept/reject per sentence, blue provenance background on accept, status bar tracking, and leave-page warning**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-02T10:49:27Z
- **Completed:** 2026-06-02T10:58:09Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- DiffStatus enum (pending/accepted/rejected) for tracking sentence diff state
- SentenceDiff immutable entity with computed getters (isDeletion, isInsertion, isModification)
- DiffResult with pendingCount and allResolved computed properties
- DiffCalculator.calculate with sentence-level pairing -- handles equal counts (1:1 modification), more AI sentences (insertions), fewer AI sentences (deletions)
- aiProvenanceAttribution using NamedAttribution with unique id 'ai_provenance' (avoids Pitfall 2 conflict with BackgroundColorAttribution)
- ProvenanceAttributions utility with applyProvenance/removeProvenance via ToggleTextAttributionsRequest
- Extended EditorAIState with diffResult field using sentinel pattern
- EditorAINotifier calculates DiffResult after streaming completes, with acceptSentence/rejectSentence/acceptAll/rejectAll methods
- DiffOverlayBuilder renders inline diff highlights (red strikethrough deletions, green insertions)
- AcceptRejectBar floating widget appears on selection overlapping pending diffs
- StatusBar shows "当前文档有 N 处AI修改待确认" (D-11)
- PopScope leave-page warning dialog for unresolved diffs (D-04)
- Batched delete+insert in single editor.execute() for one undo entry (Pitfall 5)

## Task Commits

Each task was committed atomically:

1. **Task 1: DiffState entities, DiffCalculator, and provenance attribution (TDD)**
   - `51a3f72` (test) - Add failing tests for diff state, calculator, and provenance
   - `e8ab15a` (feat) - Implement DiffState, DiffCalculator, and provenance attribution
2. **Task 2: Inline diff display, accept/reject action bar, and status bar**
   - `d715466` (feat) - Inline diff display, accept/reject bar, status bar, leave-page warning

**Plan metadata:** (included in final docs commit)

## Files Created/Modified

- `lib/features/editor/domain/diff_state.dart` - DiffStatus, SentenceDiff, DiffResult immutable entities
- `lib/features/editor/application/diff_calculator.dart` - DiffCalculator with sentence-level pairing
- `lib/features/editor/infrastructure/provenance_attribution.dart` - aiProvenanceAttribution, provenanceColor, ProvenanceAttributions
- `lib/features/editor/presentation/diff_display.dart` - DiffOverlayBuilder, AcceptRejectBar
- `lib/features/editor/presentation/status_bar.dart` - StatusBar widget
- `lib/features/editor/domain/editor_ai_state.dart` - Added diffResult field with sentinel pattern
- `lib/features/editor/application/editor_ai_notifier.dart` - DiffResult calculation, accept/reject methods
- `lib/features/editor/presentation/editor_page.dart` - Integrated overlays, status bar, PopScope
- `lib/core/presentation/providers.dart` - Registered diffCalculatorProvider

## Decisions Made

- **NamedAttribution for provenance**: Used NamedAttribution('ai_provenance') instead of BackgroundColorAttribution to avoid id conflict (Pitfall 2 from RESEARCH.md)
- **Batched editor.execute()**: Delete+insert in single execute call creates one undo entry (Pitfall 5 from RESEARCH.md)
- **Sentinel for diffResult**: Extended EditorAIState.copyWith with sentinel pattern for nullable diffResult field, consistent with existing progressText/error/userInstruction pattern
- **SentenceSegmenter reuse**: DiffCalculator uses SentenceSegmenter for Chinese sentence-level pairing, leveraging existing segmentation infrastructure

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] DiffCalculator cannot be abstract with private constructor**
- **Found during:** Task 1 (provider registration)
- **Issue:** DiffCalculator was declared abstract with private constructor, but diffCalculatorProvider needed to instantiate it
- **Fix:** Removed abstract modifier and private constructor
- **Files modified:** lib/features/editor/application/diff_calculator.dart
- **Verification:** flutter analyze passes
- **Committed in:** e8ab15a

**2. [Rule 3 - Blocking] InsertTextRequest requires attributions parameter**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** InsertTextRequest.attributions is required but was missing in rejectSentence re-insertion case
- **Fix:** Added empty attributions set `{}`
- **Files modified:** lib/features/editor/application/editor_ai_notifier.dart
- **Verification:** flutter analyze passes
- **Committed in:** d715466

**3. [Rule 3 - Blocking] Missing follow_the_leader import in diff_display.dart**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** AcceptRejectBar uses Follower.withOffset and ScreenFollowerBoundary from follow_the_leader
- **Fix:** Added import
- **Files modified:** lib/features/editor/presentation/diff_display.dart
- **Verification:** flutter analyze passes
- **Committed in:** d715466

**4. [Rule 3 - Blocking] Missing provenance_attribution import in editor_ai_notifier.dart**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** acceptSentence uses aiProvenanceAttribution from provenance_attribution.dart
- **Fix:** Added import
- **Files modified:** lib/features/editor/application/editor_ai_notifier.dart
- **Verification:** flutter analyze passes
- **Committed in:** d715466

---

**Total deviations:** 4 auto-fixed (4 blocking)
**Impact on plan:** All auto-fixes necessary for compilation. No scope creep.

## TDD Gate Compliance

RED commit: `51a3f72` - test(03-02): add failing tests
GREEN commit: `e8ab15a` - feat(03-02): implement to pass tests

TDD gate sequence verified: RED -> GREEN commits present in correct order.

## Known Stubs

None - all implemented functionality is wired and functional.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-03-04 mitigated | editor_ai_notifier.dart | All mutations use Editor.execute() requests, preserving undo/redo chain |
| T-03-05 accepted | diff_state.dart | DiffResult is ephemeral in Riverpod state, not persisted |

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Diff state and accept/reject mechanism ready for Plan 03 (selective undo + anchors)
- Provenance attribution system ready for broader text tracking features
- AcceptRejectBar pattern reusable for future floating action bars

---
*Phase: 03-editor-ai-toolbar*
*Completed: 2026-06-02*

## Self-Check: PASSED

All 9 created/modified files verified present. All 3 task commits (51a3f72, e8ab15a, d715466) verified in git log.
