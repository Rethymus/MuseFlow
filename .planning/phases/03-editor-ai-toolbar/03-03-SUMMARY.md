---
phase: 03-editor-ai-toolbar
plan: 03
subsystem: editor
tags: [flutter, super_editor, riverpod, context-anchor, selective-undo, ai-undo]

requires:
  - phase: 03-editor-ai-toolbar
    plan: 01
    provides: EditorAIState, SentenceSegmenter, EditorAINotifier, FloatingToolbar, EditorPromptPipeline
  - phase: 03-editor-ai-toolbar
    plan: 02
    provides: DiffResult, SentenceDiff, DiffCalculator, ProvenanceAttributions, AcceptRejectBar
provides:
  - ContextAnchor immutable entity with AnchorType enum (persistent/oneTime)
  - ContextAnchorMiddleware for PromptPipeline system message injection
  - SelectiveUndoService with separate AI undo stack
  - ContextAnchorNotifier managing active anchors with max 10 limit
  - ContextAnchorOverlayBuilder rendering gold background for anchored paragraphs
  - Anchor entry button in floating toolbar with persistent/one-time popup
  - Ctrl+Shift+Z keyboard shortcut for AI undo (separate from Ctrl+Z)
  - One-time anchor auto-cleanup after AI operations
affects: [04-knowledge-base]

tech-stack:
  added: [uuid]
  patterns: [anchor-reference-interface, selective-undo-stack, anchor-overlay-layer]

key-files:
  created:
    - lib/features/editor/domain/context_anchor.dart
    - lib/features/editor/application/context_anchor_middleware.dart
    - lib/features/editor/application/context_anchor_notifier.dart
    - lib/features/editor/application/selective_undo.dart
    - lib/features/editor/presentation/context_anchor_indicator.dart
  modified:
    - lib/features/editor/application/editor_prompt_pipeline.dart
    - lib/features/editor/application/editor_ai_notifier.dart
    - lib/features/editor/presentation/floating_toolbar.dart
    - lib/features/editor/presentation/editor_page.dart
    - lib/core/presentation/providers.dart

key-decisions:
  - "ContextAnchor implements AnchorReference interface to avoid cross-feature dependency between editor and AI layers"
  - "Max 10 active anchors limit (T-03-07) to prevent DoS via excessive anchor count"
  - "SelectiveUndoService uses popLast pattern (not undo(Editor)) to keep testable without mocking Editor"
  - "Anchor overlay rendered as background layer (before diff highlights and toolbar) for correct z-ordering"

patterns-established:
  - "AnchorReference interface in AI layer, ContextAnchor implements in editor layer (cross-layer decoupling)"
  - "SelectiveUndoService as plain class managed by Riverpod Provider (not Notifier)"
  - "ContextAnchorNotifier as Notifier<List<ContextAnchor>> with add/remove/clearOneTime/clear"

requirements-completed: [EDIT-06, EDIT-07]

duration: 12min
completed: 2026-06-02
---

# Phase 03 Plan 03: Selective Undo + Context Anchors Summary

**Selective undo with separate AI undo stack (Ctrl+Shift+Z), context anchor system with persistent/one-time modes, anchor entry via floating toolbar pin button, and gold background overlay indicators**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-02T11:02:08Z
- **Completed:** 2026-06-02T11:14:04Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- ContextAnchor immutable entity with AnchorType enum (persistent/oneTime), auto-generated label from first 20 chars, fromType factory
- ContextAnchorMiddleware injects anchor text into PromptPipeline system message as "参考上下文" per D-15
- EditorPromptPipeline updated with ContextAnchorMiddleware between BannedList and Operation middlewares
- SelectiveUndoService with separate AI undo stack -- record on accept, popLast on undo, clear per EDIT-06
- ContextAnchorNotifier manages active anchors with max 10 limit (T-03-07 DoS prevention)
- Anchor entry button (pin icon) in floating toolbar with PopupMenu for persistent/one-time selection per D-13
- SnackBar confirmation on anchor set, warning on max limit reached
- One-time anchors auto-cleared after AI operation completes per D-12
- SelectiveUndoService.record() called on acceptSentence, undoLastAIChange() restores without provenance
- Ctrl+Shift+Z keyboard shortcut for AI undo (separate from Ctrl+Z for human edits) per EDIT-06
- ContextAnchorOverlayBuilder renders gold background (deeper for persistent, lighter for one-time) per D-14
- All overlays coexist: anchor indicators (background) -> diff highlights -> floating toolbar -> accept/reject bar

## Task Commits

Each task was committed atomically:

1. **Task 1: ContextAnchor entity, middleware, SelectiveUndoService, and anchor indicators (TDD)**
   - `04759be` (test) - Add failing tests for all three components
   - `e1bd0e3` (feat) - Implement ContextAnchor, middleware, SelectiveUndo, anchor overlay, providers
2. **Task 2: Anchor entry via floating toolbar, one-time cleanup, and EditorPage integration**
   - `b476203` (feat) - Anchor button, one-time cleanup, AI undo, Ctrl+Shift+Z, overlay integration

**Plan metadata:** (included in final docs commit)

## Files Created/Modified

- `lib/features/editor/domain/context_anchor.dart` - ContextAnchor entity with AnchorType enum, AnchorReference implementation
- `lib/features/editor/application/context_anchor_middleware.dart` - PromptMiddleware injecting anchor context into system message
- `lib/features/editor/application/context_anchor_notifier.dart` - Notifier<List<ContextAnchor>> with add/remove/clearOneTime
- `lib/features/editor/application/selective_undo.dart` - UndoEntry entity + SelectiveUndoService with separate AI undo stack
- `lib/features/editor/presentation/context_anchor_indicator.dart` - ContextAnchorOverlayBuilder with gold background highlights
- `lib/features/editor/application/editor_prompt_pipeline.dart` - Added ContextAnchorMiddleware to pipeline ordering
- `lib/features/editor/application/editor_ai_notifier.dart` - Anchor injection, one-time cleanup, undoLastAIChange, accept records
- `lib/features/editor/presentation/floating_toolbar.dart` - Pin button with persistent/one-time popup menu
- `lib/features/editor/presentation/editor_page.dart` - Anchor overlay, Ctrl+Shift+Z shortcut, _UndoAIIntent
- `lib/core/presentation/providers.dart` - Registered SelectiveUndoService, exported ContextAnchorNotifier

## Decisions Made

- **AnchorReference interface pattern**: ContextAnchor in editor domain implements AnchorReference defined in AI layer. This avoids circular dependency while allowing PromptContext.anchors to be typed as List<AnchorReference>?.
- **SelectiveUndoService as plain class**: Not a Riverpod Notifier -- it is stateful but simple, managed by a Provider. The undo stack doesn't need reactive state since it's only read during undo operations.
- **Max 10 anchor limit**: T-03-07 threat mitigation. Users rarely need more than 10 reference paragraphs. SnackBar warning on limit reached.
- **popLast pattern for SelectiveUndoService**: Returns the entry and removes it, rather than accepting an Editor parameter. Keeps the service testable without mocking Editor. The caller (EditorAINotifier) handles the actual editor mutation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ContextAnchor must implement AnchorReference**
- **Found during:** Task 1 (TDD GREEN phase, test compilation)
- **Issue:** ContextAnchor didn't implement AnchorReference interface, causing type mismatch when passed to PromptContext.anchors
- **Fix:** Added `implements AnchorReference` and `@override` on text/label getters, imported prompt_pipeline.dart
- **Files modified:** lib/features/editor/domain/context_anchor.dart
- **Verification:** All 23 tests pass
- **Committed in:** e1bd0e3

**2. [Rule 1 - Bug] Removed redundant imports causing analyzer warnings**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** Imports for context_anchor_notifier.dart, selective_undo.dart, context_anchor.dart were unused because providers.dart re-exports them
- **Fix:** Removed unused imports from editor_ai_notifier.dart and floating_toolbar.dart
- **Files modified:** lib/features/editor/application/editor_ai_notifier.dart, lib/features/editor/presentation/floating_toolbar.dart
- **Verification:** flutter analyze shows zero issues
- **Committed in:** b476203

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes necessary for compilation and clean analyze. No scope creep.

## TDD Gate Compliance

RED commit: `04759be` - test(03-03): add failing tests
GREEN commit: `e1bd0e3` - feat(03-03): implement to pass tests

TDD gate sequence verified: RED -> GREEN commits present in correct order.

## Known Stubs

None - all implemented functionality is wired and functional.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-03-06 mitigated | context_anchor_middleware.dart | Anchor text included as reference context, not executable instruction |
| T-03-07 mitigated | context_anchor_notifier.dart | Max 10 active anchors enforced, SnackBar warning on limit |

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Context anchor system ready for Phase 4 (knowledge base integration -- anchors can reference character cards)
- SelectiveUndoService ready for broader undo features
- Phase 3 fully complete: all EDIT requirements (EDIT-02, EDIT-03, EDIT-05, EDIT-06, EDIT-07) covered

---
*Phase: 03-editor-ai-toolbar*
*Completed: 2026-06-02*

## Self-Check: PASSED

All 14 created/modified files verified present. All 3 task commits (04759be, e1bd0e3, b476203) verified in git log.
