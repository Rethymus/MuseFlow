---
phase: 03-editor-ai-toolbar
plan: 01
subsystem: editor
tags: [flutter, super_editor, riverpod, ai-streaming, floating-toolbar, chinese-nlp]

requires:
  - phase: 02-ai-provider-capture
    provides: OpenAIAdapter streaming, PromptPipeline middleware chain, AntiAIScentProcessor, provider management
provides:
  - EditorAIState immutable entity with EditorAIOperation enum
  - SentenceSegmenter Chinese sentence segmentation utility
  - EditorPromptPipeline with operation-specific middleware
  - EditorAINotifier for streaming state management with cancel support
  - FloatingToolbar overlay with SelectionLayerLinks + Follower positioning
  - Three AI actions: tone rewrite, paragraph polish, free-input
affects: [03-02-provenance, 03-03-selective-undo]

tech-stack:
  added: [follow_the_leader]
  patterns: [sentinel-based-copywith, content-layer-proxy-widget, selection-leaders-document-layer]

key-files:
  created:
    - lib/features/editor/domain/editor_ai_state.dart
    - lib/features/editor/application/sentence_segmenter.dart
    - lib/features/editor/application/editor_prompt_pipeline.dart
    - lib/features/editor/application/editor_ai_notifier.dart
    - lib/features/editor/presentation/floating_toolbar.dart
  modified:
    - lib/features/ai/application/prompt_pipeline.dart
    - lib/core/presentation/providers.dart
    - lib/features/editor/presentation/editor_page.dart
    - pubspec.yaml

key-decisions:
  - "Sentinel pattern for EditorAIState.copyWith to distinguish 'not passed' from 'explicitly null'"
  - "ContentLayerProxyWidget to wrap ConsumerWidget inside ContentLayerWidget overlay system"
  - "SelectionLeadersDocumentLayer as separate overlay builder for leader positioning"
  - "follow_the_leader added as explicit dependency (was transitive)"

patterns-established:
  - "Sentinel-based copyWith for nullable fields that should preserve on omission"
  - "EditorPromptPipeline extends PromptPipeline with editor-specific middlewares"
  - "Floating toolbar overlay via SelectionLayerLinks + Follower.withOffset + ContentLayerProxyWidget"

requirements-completed: [EDIT-02, EDIT-03]

duration: 18min
completed: 2026-06-02
---

# Phase 03 Plan 01: Floating Toolbar + Editor AI Actions Summary

**Floating toolbar overlay with SelectionLayerLinks + Follower positioning, three AI actions (tone/polish/free-input), streaming progress with cancel, and EditorAINotifier state management**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-02T10:28:04Z
- **Completed:** 2026-06-02T10:46:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- EditorAIState immutable entity with EditorAIOperation enum (Chinese labels: 语气改写, 文段润色, 自由输入)
- SentenceSegmenter Chinese sentence segmentation on 。！？… boundaries with consecutive punctuation grouping
- EditorPromptPipeline extending PromptPipeline with EditorOperationMiddleware and EditorUserContentMiddleware
- EditorAINotifier with streaming state, cancel support, anti-AI-scent post-processing, and Chinese error messages
- FloatingToolbar overlay using SelectionLayerLinks + Follower.withOffset for positioning
- Three AI action buttons with free-input inline text field (500 char limit per T-03-01)
- Streaming progress display with indeterminate progress bar and cancel button
- IME composition suppression (Pitfall 4)

## Task Commits

Each task was committed atomically:

1. **Task 1: EditorAIState, SentenceSegmenter, EditorPromptPipeline, EditorAINotifier**
   - `5456d4d` (test) - Add failing tests for all four components
   - `d88d366` (feat) - Implement all four components to pass tests
2. **Task 2: Floating toolbar overlay with AI action buttons**
   - `f2f11f8` (feat) - FloatingToolbar, EditorPage integration, follow_the_leader dependency

**Plan metadata:** (included in final docs commit)

## Files Created/Modified
- `lib/features/editor/domain/editor_ai_state.dart` - EditorAIState entity + EditorAIOperation enum with Chinese labels
- `lib/features/editor/application/sentence_segmenter.dart` - Chinese sentence segmentation utility
- `lib/features/editor/application/editor_prompt_pipeline.dart` - EditorPromptPipeline + EditorOperationMiddleware + EditorUserContentMiddleware
- `lib/features/editor/application/editor_ai_notifier.dart` - EditorAINotifier streaming state management
- `lib/features/editor/presentation/floating_toolbar.dart` - FloatingToolbar overlay widget with AI actions
- `lib/features/ai/application/prompt_pipeline.dart` - Extended PromptContext with selectedText, anchors, selectedOperation, userInstruction
- `lib/core/presentation/providers.dart` - Registered editorAINotifierProvider, editorPromptPipelineProvider, exports
- `lib/features/editor/presentation/editor_page.dart` - Integrated SelectionLayerLinks + overlay builders
- `pubspec.yaml` - Added follow_the_leader as direct dependency

## Decisions Made
- **Sentinel pattern for copyWith**: Used `Object` sentinel to distinguish "not passed" from "explicitly null" for nullable fields (progressText, error, userInstruction). This preserves error state across copyWith calls that don't explicitly clear it.
- **ContentLayerProxyWidget**: Wrapped the ConsumerStatefulWidget FloatingToolbar in ContentLayerProxyWidget to satisfy the ContentLayerWidget return type required by SuperEditorLayerBuilder.
- **SelectionLeadersDocumentLayer**: Created as a separate overlay builder (not embedded in FloatingToolbar) so leader widgets are positioned before the Follower widget tries to follow them.
- **follow_the_leader explicit dep**: Added as direct dependency since FloatingToolbar imports Follower and ScreenFollowerBoundary directly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed EditorAIState.copyWith clearing error on omission**
- **Found during:** Task 1 (TDD GREEN phase)
- **Issue:** copyWith without error parameter was clearing error to null instead of preserving it
- **Fix:** Implemented sentinel pattern using `Object` constant to distinguish "not passed" from "explicitly null"
- **Files modified:** lib/features/editor/domain/editor_ai_state.dart
- **Verification:** Test "copyWith should allow setting error" passes -- error preserved across copyWith calls
- **Committed in:** d88d366

**2. [Rule 1 - Bug] Fixed SentenceSegmenter consecutive punctuation handling**
- **Found during:** Task 1 (TDD GREEN phase)
- **Issue:** Consecutive identical punctuation (e.g., ！！！) was split into separate sentences instead of grouped
- **Fix:** Implemented lookahead to group consecutive identical sentence-ending punctuation into one boundary
- **Files modified:** lib/features/editor/application/sentence_segmenter.dart
- **Verification:** Test "should handle consecutive punctuation marks" passes
- **Committed in:** d88d366

**3. [Rule 3 - Blocking] Added follow_the_leader as direct dependency**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** FloatingToolbar imports Follower and ScreenFollowerBoundary from follow_the_leader which was only a transitive dependency
- **Fix:** Ran `flutter pub add follow_the_leader`
- **Files modified:** pubspec.yaml, pubspec.lock
- **Verification:** flutter analyze shows zero errors
- **Committed in:** f2f11f8

**4. [Rule 3 - Blocking] Fixed ContentLayerWidget type mismatch**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** FloatingToolbar (ConsumerStatefulWidget) not returnable from ContentLayerWidget function
- **Fix:** Wrapped FloatingToolbar in ContentLayerProxyWidget, added SelectionLeadersDocumentLayer as separate overlay builder
- **Files modified:** lib/features/editor/presentation/editor_page.dart
- **Verification:** flutter analyze shows zero errors
- **Committed in:** f2f11f8

---

**Total deviations:** 4 auto-fixed (2 bugs, 2 blocking)
**Impact on plan:** All auto-fixes necessary for correctness and compilation. No scope creep.

## Issues Encountered
- Test expectation mismatch for SentenceSegmenter double ellipsis: original test expected '嗯……好吧。' as one sentence but '然后呢……我不知道。' as two sentences. Fixed the "multiple types" test to be consistent with the "double ellipsis" test (both split on ……).

## TDD Gate Compliance

RED commit: `5456d4d` - test(03-01): add failing tests
GREEN commit: `d88d366` - feat(03-01): implement to pass tests

TDD gate sequence verified: RED -> GREEN commits present in correct order.

## Known Stubs

None - all implemented functionality is wired and functional.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-03-01 mitigated | floating_toolbar.dart | Free-input TextField has maxLength: 500 per threat model |
| T-03-02 mitigated | editor_ai_notifier.dart | Error messages are user-friendly Chinese strings, never expose API keys |
| T-03-03 deferred | editor_ai_notifier.dart | Token budget calculation not yet applied to editor operations (reuses Phase 2 pattern) |

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Floating toolbar and AI actions ready for Plans 02 (provenance tracking) and 03 (selective undo + anchors)
- EditorAINotifier provides streaming state that Plan 02's diff display will consume
- EditorPromptPipeline ready for ContextAnchorMiddleware injection in Plan 03
- SentenceSegmenter ready for per-sentence diff display in Plan 02

---
*Phase: 03-editor-ai-toolbar*
*Completed: 2026-06-02*
