---
phase: 03-editor-ai-toolbar
verified: 2026-06-02T12:00:00Z
status: gaps_found
score: 15/17 must-haves verified
overrides_applied: 0
re_verification: false
gaps:
  - truth: "After accepting all sentences, the accepted text has a blue provenance background"
    status: failed
    reason: "ProvenanceAttributions.applyProvenance is never called in the accept flow. EditorAINotifier.acceptSentence inserts text with aiProvenanceAttribution via InsertTextRequest but never calls ProvenanceAttributions to render a visible blue background overlay. The ProvenanceAttributions utility class and provenanceColor constant exist but are unused in the accept pipeline."
    artifacts:
      - path: "lib/features/editor/application/editor_ai_notifier.dart"
        issue: "acceptSentence does not call ProvenanceAttributions.applyProvenance; accepted text gets no visible blue background"
      - path: "lib/features/editor/infrastructure/provenance_attribution.dart"
        issue: "applyProvenance/removeProvenance methods exist but are never invoked by any code path"
    missing:
      - "Call ProvenanceAttributions.applyProvenance(editor, range) after accepting a sentence, or render provenance color via the diff overlay for accepted sentences"
  - truth: "Anchored paragraphs show gold background with pin icon in the editor margin"
    status: failed
    reason: "The ContextAnchorOverlayBuilder and _AnchorIndicator use a CustomPaint with IgnorePointer but the painter draws a rect at (0,0) with full canvas size. Since the overlay is wrapped in IgnorePointer inside a Stack with no explicit size constraints, the CustomPaint widget has zero intrinsic size and renders nothing visible. No pin icon is rendered either -- the code only draws a colored rect via CustomPaint."
    artifacts:
      - path: "lib/features/editor/presentation/context_anchor_indicator.dart"
        issue: "_AnchorIndicator uses CustomPaint with no size constraints inside IgnorePointer/Stack; painter draws at (0,0) with no positioning logic; pin icon (D-14) is missing from implementation"
    missing:
      - "Implement anchor overlay with proper layout-based positioning (use document layout to find node position) and render a pin icon widget alongside the gold background"
deferred: []
human_verification:
  - test: "Select text in the editor and verify floating toolbar appears"
    expected: "A floating toolbar with three action buttons (语气改写, 文段润色, 自由输入) and a pin icon appears positioned below the selection"
    why_human: "Requires running the Flutter app and interacting with the editor UI"
  - test: "Click each AI action button and verify streaming progress"
    expected: "Progress bar with cancel button replaces the toolbar during streaming; cancel stops the operation"
    why_human: "Requires live AI provider connection and visual verification"
  - test: "After AI operation completes, verify sentence-level inline diff appears"
    expected: "Red strikethrough for deletions, green background for insertions, visible on pending sentences"
    why_human: "Visual overlay rendering cannot be verified via grep"
  - test: "Accept a sentence and verify provenance blue background appears"
    expected: "Accepted text should show a subtle blue background indicating AI provenance"
    why_human: "Visual appearance of provenance background cannot be verified programmatically; current code does not render it"
  - test: "Set a context anchor and verify gold background + pin icon"
    expected: "Anchored paragraph shows gold background with a pin icon in the margin"
    why_human: "Visual overlay rendering cannot be verified programmatically; current code has rendering issues"
  - test: "Press Ctrl+Shift+Z after accepting AI changes"
    expected: "Last AI modification is undone, restoring original text without affecting Ctrl+Z undo stack"
    why_human: "Keyboard shortcut behavior requires running app"
  - test: "Navigate away from editor with pending diffs"
    expected: "Confirmation dialog appears asking whether to stay or discard pending AI modifications"
    why_human: "Dialog interaction requires running app"
---

# Phase 03: Editor AI Toolbar Verification Report

**Phase Goal:** Users can select text in the editor and get AI-powered actions via a floating toolbar: tone rewrite, paragraph polish, free-form edit -- with provenance tracking and selective undo
**Verified:** 2026-06-02T12:00:00Z
**Status:** gaps_found
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User selects text in the editor and a floating toolbar appears positioned at the selection | VERIFIED | floating_toolbar.dart: FloatingToolbar uses SelectionLayerLinks + Follower.withOffset, listens to composer.selectionNotifier, shows when selection is expanded |
| 2 | Floating toolbar shows three AI action buttons horizontally: 语气改写, 文段润色, 自由输入 | VERIFIED | floating_toolbar.dart: _ToolbarContent Row contains three _ActionButton widgets with correct labels and icons |
| 3 | Clicking 自由输入 expands an inline text field below the toolbar for user instructions | VERIFIED | floating_toolbar.dart: _FreeInputField with hint "输入修改指令...", maxLength 500 (T-03-01), submit on Enter, cancel (X) collapses |
| 4 | Clicking any AI action shows a progress bar with cancel button in place of the toolbar | VERIFIED | floating_toolbar.dart: _StreamingProgress with LinearProgressIndicator + "取消" TextButton; editor_page.dart overlays wired |
| 5 | AI operation streams tokens and completes successfully using PromptPipeline + OpenAIAdapter | VERIFIED | editor_ai_notifier.dart: startOperation builds PromptContext, calls EditorPromptPipeline.build(), streams via adapter.createStream(), accumulates tokens, runs _postProcess() |
| 6 | Toolbar flips above selection when selection is near the bottom of the screen | FAILED | floating_toolbar.dart _buildFollower: hardcoded leaderAnchor: Alignment.bottomCenter, no flip logic. Plan D-08 specifies "if selection vertical center is in bottom 40%, flip to above" -- not implemented |
| 7 | After an AI operation completes, the result is shown as sentence-level inline diff in the editor | VERIFIED | editor_ai_notifier.dart _postProcess: calls DiffCalculator.calculate, stores in state.diffResult. DiffOverlayBuilder registered in editor_page.dart documentOverlayBuilders |
| 8 | Deleted sentences are shown with red strikethrough, inserted sentences shown with green background | VERIFIED | diff_display.dart: _deletionColor = Color(0x33FF0000) red 20% opacity, _insertionColor = Color(0x3300FF00) green 20% opacity; _DiffHighlightPainter draws rect + strikethrough for deletions |
| 9 | User can accept or reject individual sentences via a floating action bar on selection | VERIFIED | diff_display.dart AcceptRejectBar: appears when selection overlaps pending diffs, shows "接受"/"拒绝" buttons, calls acceptSentence/rejectSentence |
| 10 | After accepting all sentences, the accepted text has a blue provenance background | FAILED | editor_ai_notifier.dart acceptSentence: inserts text with aiProvenanceAttribution via InsertTextRequest but NEVER calls ProvenanceAttributions.applyProvenance(). ProvenanceAttributions class exists in provenance_attribution.dart but is dead code -- never invoked |
| 11 | Status bar shows count of pending AI modifications | VERIFIED | status_bar.dart: StatusBar shows "当前文档有 N 处AI修改待确认" when pendingCount > 0, hidden when allResolved |
| 12 | User can undo an AI modification without losing their own human edits | VERIFIED | selective_undo.dart: SelectiveUndoService with record/popLast. editor_ai_notifier.dart undoLastAIChange: pops entry, deletes replacement, re-inserts original WITHOUT provenance |
| 13 | AI undo stack is separate from the document undo stack (Ctrl+Z undoes human edits, not AI accepts) | VERIFIED | selective_undo.dart: separate _undoStack list. editor_page.dart: Ctrl+Shift+Z bound to _UndoAIIntent -> undoLastAIChange(). Ctrl+Z is super_editor's built-in undo |
| 14 | User can set a context anchor by selecting text and using the floating toolbar button | VERIFIED | floating_toolbar.dart: _AnchorButton with PopupMenuButton showing "持久锚点"/"本次参考". _setAnchor creates ContextAnchor.fromType and adds to notifier |
| 15 | Persistent anchors remain active until manually removed; one-time anchors clear after AI operation | VERIFIED | context_anchor_notifier.dart: clearOneTime() keeps persistent. editor_ai_notifier.dart _postProcess: calls clearOneTime() after AI operation |
| 16 | Anchored paragraphs show gold background with pin icon in the editor margin | FAILED | context_anchor_indicator.dart: _AnchorIndicator uses CustomPaint inside IgnorePointer/Stack with no size constraints. Painter draws rect at (0,0) with no positioning. No pin icon rendered. Overlay produces zero visible output |
| 17 | Anchor content is automatically injected into the PromptPipeline system message | VERIFIED | context_anchor_middleware.dart: ContextAnchorMiddleware extends PromptMiddleware, casts anchors to ContextAnchor, builds system message "以下是作者指定的参考上下文...". editor_prompt_pipeline.dart: middleware in correct position (after BannedList, before Operation) |

**Score:** 15/17 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/editor/domain/editor_ai_state.dart` | EditorAIState immutable entity with EditorAIOperation enum | VERIFIED | 119 lines. Sentinel-based copyWith. EditorAIOperation with Chinese labels. diffResult field added |
| `lib/features/editor/application/editor_ai_notifier.dart` | EditorAINotifier streaming state, cancel, accept/reject, undo | VERIFIED | 424 lines. Full streaming pipeline, cancel flag, accept/reject with editor.execute(), undoLastAIChange via SelectiveUndoService |
| `lib/features/editor/application/editor_prompt_pipeline.dart` | EditorPromptPipeline with operation-specific middleware | VERIFIED | 106 lines. 6 middlewares in correct order. EditorOperationMiddleware + EditorUserContentMiddleware |
| `lib/features/editor/application/sentence_segmenter.dart` | Chinese sentence segmentation on 。！？… | VERIFIED | 72 lines. Stateful parser handles consecutive punctuation, double ellipsis |
| `lib/features/editor/presentation/floating_toolbar.dart` | FloatingToolbar with SelectionLayerLinks + Follower | VERIFIED | 583 lines. Full implementation with _ToolbarContent, _FreeInputField, _StreamingProgress, _AnchorButton |
| `lib/features/editor/domain/diff_state.dart` | DiffResult, SentenceDiff, DiffStatus entities | VERIFIED | 154 lines. Immutable with copyWith, equality, computed getters |
| `lib/features/editor/application/diff_calculator.dart` | Sentence-level diff computation | VERIFIED | 89 lines. Uses SentenceSegmenter, handles equal/unequal sentence counts |
| `lib/features/editor/infrastructure/provenance_attribution.dart` | AI provenance NamedAttribution + utility | VERIFIED | 57 lines. aiProvenanceAttribution with unique id, ProvenanceAttributions class (but never called) |
| `lib/features/editor/presentation/diff_display.dart` | Inline diff overlay + AcceptRejectBar | VERIFIED | 347 lines. DiffOverlayBuilder, AcceptRejectBar with selection overlap detection |
| `lib/features/editor/presentation/status_bar.dart` | StatusBar showing pending count | VERIFIED | 45 lines. Chinese text, hidden when allResolved |
| `lib/features/editor/domain/context_anchor.dart` | ContextAnchor entity with AnchorType | VERIFIED | 143 lines. Implements AnchorReference, fromType factory, label auto-generation |
| `lib/features/editor/application/context_anchor_middleware.dart` | PromptMiddleware injecting anchor text | VERIFIED | 44 lines. Casts anchors, builds system message with labels |
| `lib/features/editor/application/selective_undo.dart` | SelectiveUndoService with separate AI undo stack | VERIFIED | 127 lines. UndoEntry entity, record/popLast/clear |
| `lib/features/editor/presentation/context_anchor_indicator.dart` | Anchor overlay with gold background + pin icon | STUB | 137 lines. CustomPaint with no sizing/positioning. No pin icon. Produces zero visible output |
| `lib/features/editor/application/context_anchor_notifier.dart` | Notifier managing active anchors with max 10 limit | VERIFIED | 53 lines. add/remove/clearOneTime/clear, maxActiveAnchors = 10 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| floating_toolbar.dart | editor_page.dart | SelectionLayerLinks + Follower.withOffset | WIRED | editor_page.dart passes _selectionLinks to FloatingToolbar; SelectionLeadersDocumentLayer positioned in overlay builders |
| editor_ai_notifier.dart | openai_adapter.dart | OpenAIAdapter.createStream() | WIRED | editor_ai_notifier.dart line 135: adapter.createStream(apiKey, baseUrl, model, messages) |
| editor_prompt_pipeline.dart | prompt_pipeline.dart | extends PromptPipeline | WIRED | EditorPromptPipeline extends PromptPipeline with correct middleware chain |
| context_anchor_middleware.dart | prompt_pipeline.dart | PromptMiddleware.apply() | WIRED | ContextAnchorMiddleware extends PromptMiddleware, reads context.anchors |
| editor_ai_notifier.dart | selective_undo.dart | SelectiveUndoService.record/popLast | WIRED | acceptSentence calls undoService.record(); undoLastAIChange calls undoService.popLast() |
| context_anchor_indicator.dart | context_anchor.dart | Reads anchor list to render | WIRED | _AnchorOverlay watches contextAnchorNotifierProvider |
| floating_toolbar.dart | context_anchor.dart | Anchor entry button | WIRED | _AnchorButton with PopupMenuButton -> _setAnchor creates ContextAnchor |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| FloatingToolbar | editorAIState | editorAINotifierProvider | Yes -- streams from OpenAIAdapter | FLOWING |
| DiffOverlayBuilder | aiState.diffResult | editorAINotifierProvider | Yes -- DiffCalculator.calculate on stream complete | FLOWING |
| StatusBar | diffResult.pendingCount | editorAINotifierProvider | Yes -- computed from SentenceDiff list | FLOWING |
| AcceptRejectBar | diffResult sentences | editorAINotifierProvider | Yes -- pending sentences from calculate | FLOWING |
| ContextAnchorOverlayBuilder | anchors | contextAnchorNotifierProvider | Yes -- user-created ContextAnchor list | FLOWING |
| ContextAnchorMiddleware | context.anchors | EditorAINotifier.startOperation | Yes -- reads from contextAnchorNotifierProvider | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All editor tests pass (102 tests) | `flutter test test/features/editor/ --reporter compact` | 102 tests, 0 failures | PASS |
| flutter analyze on overlay files | `flutter analyze lib/features/editor/presentation/diff_display.dart lib/features/editor/presentation/context_anchor_indicator.dart` | No issues found | PASS |
| flutter analyze on full editor | `flutter analyze lib/features/editor/` | 1 warning: unused import in diff_state.dart | PASS (warning only) |

### Probe Execution

No probes declared for this phase. Step 7c: SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-----------|-------------|--------|----------|
| EDIT-02 | 03-01 | Select text triggers floating toolbar popup | SATISFIED | FloatingToolbar listens to selectionNotifier, shows on expanded selection |
| EDIT-03 | 03-01 | Floating toolbar provides tone rewrite, paragraph polish, free input | SATISFIED | _ToolbarContent with three _ActionButton widgets, correct Chinese labels |
| EDIT-05 | 03-02 | AI-modified text visually distinguished from human-written text | PARTIAL | DiffResult data model works (sentence-level diff), inline diff overlay renders red/green, but provenance blue background on accepted text is NOT rendered (dead code) |
| EDIT-06 | 03-03 | Selective undo for AI modifications (revert AI without losing human edits) | SATISFIED | SelectiveUndoService with separate stack, Ctrl+Shift+Z shortcut, undoLastAIChange restores without provenance |
| EDIT-07 | 03-03 | Context anchor -- user can select paragraphs as reference context for AI | PARTIAL | Data model and injection work (ContextAnchor, ContextAnchorMiddleware), but gold background + pin icon overlay does not render visibly |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/editor/presentation/context_anchor_indicator.dart` | 305 | Comment says "This is a placeholder that provides the visual indication" | Warning | _DiffHighlightPainter acknowledged as placeholder; precise character-level bounding boxes not implemented |
| `lib/features/editor/infrastructure/provenance_attribution.dart` | 1-57 | Dead code -- ProvenanceAttributions.applyProvenance/removeProvenance never called | Warning | Provenance utility exists but no code path invokes it |
| `lib/features/editor/domain/diff_state.dart` | 7 | Unused import: super_editor/super_editor.dart | Info | flutter analyze warning; DocumentRange type removed from DiffResult |

### Human Verification Required

### 1. Floating Toolbar Appearance and Actions

**Test:** Launch the app, select text in the editor
**Expected:** Floating toolbar appears below selection with three AI action buttons and a pin icon
**Why human:** Requires running Flutter app with editor content

### 2. AI Streaming and Diff Display

**Test:** Click an AI action button with an active provider
**Expected:** Progress bar replaces toolbar; after completion, inline diff shows red/green highlights
**Why human:** Requires live AI API connection

### 3. Provenance Background on Accepted Text

**Test:** Accept an AI sentence modification
**Expected:** Accepted text shows subtle blue background (provenance marker)
**Why human:** Current code does NOT render provenance background -- this is a gap that needs fixing before this can pass

### 4. Context Anchor Visual Indicators

**Test:** Set a persistent anchor via the pin button
**Expected:** Anchored paragraph shows gold background with pin icon in the margin
**Why human:** Current code has rendering issues -- overlay produces no visible output

### 5. Selective Undo via Ctrl+Shift+Z

**Test:** Accept AI changes, then press Ctrl+Shift+Z
**Expected:** Last AI modification is undone, original text restored, Ctrl+Z still undoes human edits separately
**Why human:** Keyboard shortcut behavior requires running app

### 6. Leave-Page Warning

**Test:** Navigate away from editor with pending AI diffs
**Expected:** Dialog: "有 N 处未确认的AI修改，确定离开吗？" with stay/discard options
**Why human:** PopScope dialog requires running app

### Gaps Summary

Two gaps block full goal achievement:

**Gap 1 -- Provenance background not rendered (EDIT-05 partial):** The `ProvenanceAttributions` utility class exists with `applyProvenance`/`removeProvenance` methods, and `aiProvenanceAttribution` / `provenanceColor` constants are defined. However, `EditorAINotifier.acceptSentence` never calls `ProvenanceAttributions.applyProvenance()`. The `InsertTextRequest` includes `aiProvenanceAttribution` in its attributions set, which marks the text in the document model, but no overlay or stylesheet renders the blue background color. The provenance infrastructure is dead code.

**Gap 2 -- Anchor overlay not rendering (EDIT-07 partial):** The `ContextAnchorOverlayBuilder` is wired into `editor_page.dart`'s `documentOverlayBuilders` and reads from `contextAnchorNotifierProvider`. However, `_AnchorIndicator` uses `CustomPaint` inside an `IgnorePointer`/`Stack` with no explicit size constraints, so the painter receives zero-size canvas and renders nothing. Additionally, no pin icon widget is rendered -- the plan specifies "a pin icon in the left margin" but the implementation only draws a colored rectangle via `CustomPaint`. The data model and injection pipeline work correctly; only the visual indicator is broken.

**Minor -- Toolbar flip logic not implemented:** The plan (D-08) specifies the toolbar should flip above the selection when the selection is in the bottom 40% of the viewport. The current implementation uses fixed bottom positioning with no flip logic.

---

_Verified: 2026-06-02T12:00:00Z_
_Verifier: Claude (gsd-verifier)_
