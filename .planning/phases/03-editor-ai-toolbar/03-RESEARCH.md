# Phase 3: Editor AI Toolbar - Research

**Researched:** 2026-06-02
**Domain:** super_editor floating toolbar, attribution system, document mutation, AI streaming integration
**Confidence:** HIGH

## Summary

Phase 3 adds AI-powered editing capabilities to the MuseFlow editor. Users select text and a floating toolbar appears with three actions: tone rewrite, paragraph polish, and free-form edit. AI modifications are shown as sentence-level inline diffs with per-sentence accept/reject. Modified text is visually distinguished via provenance tracking (blue background attribution). Users can selectively undo AI modifications and set context anchors for reference.

The technical foundation is solid: super_editor (0.3.0-dev.20, cached as 0.3.0-dev.51) provides `SelectionLayerLinks` + `Leader`/`Follower` for floating toolbar positioning, `BackgroundColorAttribution` for provenance highlighting, and `ToggleTextAttributionsRequest`/`DeleteContentRequest`/`InsertTextRequest` for document mutation. The existing `PromptPipeline` middleware architecture and `SynthesisNotifier` streaming pattern are directly reusable. No new external packages are required -- `follow_the_leader` and `overlord` are already transitive dependencies of super_editor.

**Primary recommendation:** Build the floating toolbar using `SelectionLayerLinks.expandedSelectionBoundsLink` + `Follower.withOffset` inside a `SuperEditorLayerBuilder`. Use `BackgroundColorAttribution(Colors.blue.withValues(alpha: 0.1))` for provenance. Extend `PromptPipeline` with a `ContextAnchorMiddleware` for editor AI operations.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Floating toolbar UI | Presentation | -- | Pure UI overlay, positioned relative to editor selection |
| AI operation triggering | Presentation | Application | Toolbar button triggers use case |
| Editor AI use cases (tone/polish/free-input) | Application | -- | Orchestrates prompt building + streaming + post-processing |
| Prompt building for editor operations | Application | Infrastructure | Extends PromptPipeline with editor-specific prompts |
| Diff state management | Domain | -- | Immutable entities for diff tracking |
| Context anchor entities | Domain | -- | Value objects for anchor data |
| Provenance attribution | Infrastructure | -- | super_editor Attribution integration |
| AI streaming | Infrastructure | -- | Reuses OpenAIAdapter |
| Document mutation (text replacement) | Infrastructure | -- | super_editor Editor.execute() requests |

## Standard Stack

### Core (already installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| super_editor | 0.3.0-dev.20 | Rich text editor | Already in use, provides all needed APIs |
| follow_the_leader | (transitive) | Leader/Follower positioning | Positions toolbar relative to selection |
| overlord | (transitive) | CupertinoPopoverToolbar | Pre-built toolbar widget with popover styling |
| flutter_riverpod | ^3.3.1 | State management | Project standard |
| openai_dart | ^6.0.0 | AI API client | Already in use |

### Supporting (to be added as explicit dependencies)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| overlord | 0.4.2 | Popover toolbar widgets | Add as explicit dep for `CupertinoPopoverToolbar` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Follower.withOffset` | `Follower.withAligner` + custom aligner | More control but more complexity; `withOffset` suffices for simple above/below positioning |
| `CupertinoPopoverToolbar` (overlord) | Custom Material toolbar widget | overlord is already a transitive dep and provides production-quality popover styling; custom widget is more work for less polish |
| `BackgroundColorAttribution` | Custom `NamedAttribution` + stylesheet rule | `BackgroundColorAttribution` is built-in and directly renders; custom attribution requires stylesheet integration |

**Installation:**
```bash
# overlord is already a transitive dependency -- add as explicit for clarity
flutter pub add overlord
```

**Version verification:** overlord 0.4.2 is in pubspec.lock as a transitive dependency of super_editor. No version conflict expected.

## Package Legitimacy Audit

> No new packages required. All packages are already resolved in pubspec.lock as direct or transitive dependencies.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| super_editor | pub.dev | 3+ yrs | established | github.com/superlistapp/super_editor | N/A (already installed) | Approved |
| follow_the_leader | pub.dev | 3+ yrs | transitive | github.com/superlistapp/super_editor (mono-repo) | N/A (already installed) | Approved |
| overlord | pub.dev | 2+ yrs | transitive | github.com/superlistapp/super_editor (mono-repo) | N/A (already installed) | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
User selects text in editor
        |
        v
[SelectionLayerLinks] --positions--> [Leader widgets at selection bounds]
        |
        v
[SuperEditorLayerBuilder] --builds--> [Follower widget = Floating Toolbar]
        |
        v
User clicks AI action (tone/polish/free-input)
        |
        v
[EditorAINotifier] --orchestrates--> [PromptPipeline + ContextAnchorMiddleware]
        |                                      |
        v                                      v
[OpenAIAdapter.createStream()] <--messages-- [Built prompt with anchors + selected text]
        |
        v
[AntiAIScentProcessor.process()] --post-processes--> [Clean text]
        |
        v
[SentenceSegmenter] --splits--> [Individual sentences]
        |
        v
[Inline Diff Display] --shows--> [Red deletions + Green insertions in editor]
        |
        v
User accepts/rejects per sentence
        |
        v
[ToggleTextAttributionsRequest] --applies--> [Provenance blue background]
[DeleteContentRequest + InsertTextRequest] --replaces--> [Selected text with AI text]
```

### Recommended Project Structure
```
lib/features/editor/
├── domain/
│   ├── diff_state.dart              # DiffResult, SentenceDiff, DiffStatus entities
│   └── context_anchor.dart          # ContextAnchor entity (persistent vs one-time)
├── application/
│   ├── editor_ai_notifier.dart      # Riverpod notifier for AI operations (streaming state)
│   ├── sentence_segmenter.dart      # Chinese sentence segmentation utility
│   ├── tone_rewrite_use_case.dart   # Tone rewrite prompt template
│   ├── paragraph_polish_use_case.dart # Paragraph polish prompt template
│   └── context_anchor_middleware.dart # PromptPipeline middleware for anchor injection
├── infrastructure/
│   └── provenance_attribution.dart  # Custom attribution constants for provenance
└── presentation/
    ├── editor_page.dart             # Modified: add floating toolbar overlay
    ├── floating_toolbar.dart        # Floating toolbar widget (3 AI actions)
    ├── diff_display.dart            # Inline diff highlighting widget
    └── context_anchor_indicator.dart # Anchor marker in editor margin
```

### Pattern 1: Floating Toolbar via SelectionLayerLinks + Follower

**What:** Position a floating toolbar above the user's text selection using super_editor's built-in selection leader system.

**When to use:** Whenever a popover needs to follow the user's selection in the document.

**Example:**
```dart
// Source: super_editor example/lib/demos/interaction_spot_checks/toolbar_following_content_in_layer.dart

// 1. Create a LeaderLink for the selection
final _selectionLeaderLink = LeaderLink();

// 2. In SuperEditor, pass SelectionLayerLinks to get leaders positioned at selection
SuperEditor(
  editor: _editor,
  selectionLayerLinks: SelectionLayerLinks(
    expandedSelectionBoundsLink: _selectionLeaderLink,
  ),
  documentOverlayBuilders: [
    // Add custom overlay builder for the floating toolbar
    FunctionalSuperEditorLayerBuilder((context, editContext) {
      return _FloatingToolbarLayer(
        editContext: editContext,
        leaderLink: _selectionLeaderLink,
      );
    }),
    DefaultCaretOverlayBuilder(),
  ],
)

// 3. Build the toolbar as a Follower widget
class _FloatingToolbarLayer extends ContentLayerStatefulWidget { ... }

// In the overlay (or as a separate OverlayPortal):
Follower.withOffset(
  link: _selectionLeaderLink,
  leaderAnchor: Alignment.topCenter,    // Anchor at top of selection
  followerAnchor: Alignment.bottomCenter, // Toolbar appears above
  offset: Offset(0, -8),                // 8px gap above selection
  boundary: ScreenFollowerBoundary(),    // Constrain to screen
  child: _buildToolbarContent(),
)
```

### Pattern 2: Provenance Attribution via BackgroundColorAttribution

**What:** Mark AI-modified text with a subtle blue background using super_editor's built-in attribution system.

**When to use:** After user accepts AI diff, apply provenance marking to the accepted text.

**Example:**
```dart
// Source: super_editor/lib/src/default_editor/attributions.dart

// Define provenance attribution constant
const aiProvenanceAttribution = BackgroundColorAttribution(
  Color(0x1A0000FF), // Colors.blue.withValues(alpha: 0.1)
);

// Apply provenance to a text range via Editor request
editor.execute([
  ToggleTextAttributionsRequest(
    documentRange: DocumentRange(
      start: DocumentPosition(nodeId: nodeId, nodePosition: TextNodePosition(offset: start)),
      end: DocumentPosition(nodeId: nodeId, nodePosition: TextNodePosition(offset: end)),
    ),
    attributions: {aiProvenanceAttribution},
  ),
]);

// Remove provenance when user accepts (attribution auto-removed on toggle)
editor.execute([
  ToggleTextAttributionsRequest(
    documentRange: acceptedRange,
    attributions: {aiProvenanceAttribution},
  ),
]);
```

### Pattern 3: Document Mutation for Text Replacement

**What:** Replace selected text with AI-generated content using super_editor's request system.

**When to use:** When user accepts an AI diff sentence -- delete old text, insert new text with provenance.

**Example:**
```dart
// Source: super_editor/lib/src/default_editor/multi_node_editing.dart, text.dart

// Step 1: Delete the selected range
editor.execute([
  DeleteContentRequest(
    documentRange: DocumentRange(
      start: DocumentPosition(nodeId: nodeId, nodePosition: TextNodePosition(offset: oldStart)),
      end: DocumentPosition(nodeId: nodeId, nodePosition: TextNodePosition(offset: oldEnd)),
    ),
  ),
]);

// Step 2: Insert new text at the resulting caret position with provenance attribution
editor.execute([
  InsertTextRequest(
    documentPosition: editor.composer.selection!.extent,
    textToInsert: newAiText,
    attributions: {aiProvenanceAttribution},
  ),
]);
```

### Pattern 4: Selection Change Listening

**What:** React to text selection changes to show/hide the floating toolbar.

**When to use:** To toggle toolbar visibility when selection becomes expanded/collapsed.

**Example:**
```dart
// Source: super_editor/lib/src/core/document_composer.dart

// Option A: ValueListenable (simpler, no reason info)
editor.composer.selectionNotifier.addListener(() {
  final selection = editor.composer.selection;
  if (selection != null && !selection.isCollapsed) {
    _showToolbar();
  } else {
    _hideToolbar();
  }
});

// Option B: Stream (includes SelectionChangeType reason)
editor.composer.selectionChanges.listen((change) {
  // change.selection, change.reason
});
```

### Pattern 5: PromptPipeline Extension for Editor Operations

**What:** Add editor-specific middleware to the existing PromptPipeline for tone/polish/free-input operations.

**When to use:** Every editor AI operation needs context anchors injected into the prompt.

**Example:**
```dart
// Source: lib/features/ai/application/prompt_pipeline.dart

// Create editor-specific pipeline with additional ContextAnchorMiddleware
class EditorPromptPipeline extends PromptPipeline {
  EditorPromptPipeline.withEditorMiddlewares()
    : super(middlewares: [
        SystemPromptMiddleware(),
        PersonaInjectionMiddleware(),
        BannedListMiddleware(),
        ContextAnchorMiddleware(),  // NEW: injects anchor context
        EditorOperationMiddleware(), // NEW: operation-specific system prompt
        UserContentMiddleware(),
      ]);
}

// ContextAnchorMiddleware reads anchors from PromptContext and injects them
class ContextAnchorMiddleware extends PromptMiddleware {
  @override
  PromptContext apply(PromptContext context) {
    if (context.anchors.isEmpty) return context;
    
    final anchorText = context.anchors
      .map((a) => '【${a.label}】\n${a.text}')
      .join('\n\n');
    
    return context.addMessage(
      ChatMessage.system('以下是作者指定的参考上下文：\n\n$anchorText'),
    );
  }
}
```

### Anti-Patterns to Avoid

- **Don't use OverlayPortal for the toolbar:** super_editor's document overlay system (`SuperEditorLayerBuilder`) integrates with the editor's coordinate system. Using Flutter's `OverlayPortal` directly would require manual coordinate transformation.
- **Don't mutate AttributedText directly:** Always use `Editor.execute()` with requests. Direct mutation bypasses the editor's undo/redo system and reaction chain.
- **Don't store diff state in the document:** Diff state (pending AI modifications) should be in a separate Riverpod notifier, not in the document model. The document only stores final accepted text.
- **Don't use word-level diff for Chinese:** Chinese has no word boundaries. Sentence-level diff (splitting on `。！？…`) is the natural granularity.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Floating toolbar positioning | Custom `CompositedTransformTarget`/`Follower` | `SelectionLayerLinks` + `Follower` from follow_the_leader | super_editor already positions leaders at selection bounds; re-implementing is error-prone |
| Text diff algorithm | Custom Myers diff | `diff` package or simple sentence-by-sentence comparison | For sentence-level diff, a simple old-vs-new sentence pairing is sufficient; full Myers diff is overkill |
| Popover styling | Custom Material popup | `CupertinoPopoverToolbar` from overlord | Production-quality popover with proper shadows, rounded corners, animation |
| AI streaming state machine | Custom state management | `SynthesisNotifier` pattern (AsyncNotifier) | Already battle-tested in Phase 2; same streaming + error handling pattern |
| Prompt assembly | Custom prompt building | `PromptPipeline` middleware chain | Extensible, testable, already handles system prompt + persona + banned list |

**Key insight:** The hardest parts (selection tracking, overlay positioning, text mutation, AI streaming) are all solved by existing infrastructure. Phase 3 is primarily an integration and UI layer.

## Common Pitfalls

### Pitfall 1: SelectionLayerLinks Not Updating After Document Mutation
**What goes wrong:** After replacing text via `DeleteContentRequest` + `InsertTextRequest`, the `SelectionLayerLinks` leaders may not update because the selection changed programmatically.
**Why it happens:** The selection change notification may fire before the document layout has re-laid out.
**How to avoid:** Use `WidgetsBinding.instance.addPostFrameCallback` to re-evaluate toolbar position after mutations. Or listen to `editor.document` changes to trigger re-layout.
**Warning signs:** Toolbar appears at wrong position after accepting a diff.

### Pitfall 2: Attribution Overlap Conflicts
**What goes wrong:** Applying `BackgroundColorAttribution` for provenance conflicts with existing `BackgroundColorAttribution` spans (e.g., from selection highlight).
**Why it happens:** `BackgroundColorAttribution` uses `id: 'background_color'` -- all instances share the same ID and cannot overlap.
**How to avoid:** Use a custom `NamedAttribution` with a unique ID (e.g., `'ai_provenance'`) and handle rendering via a custom `StyleRule` in the stylesheet. Or use `CustomUnderlineAttribution` instead of background color.
**Warning signs:** Provenance highlight disappears when text is selected.

### Pitfall 3: Chinese Sentence Boundary Edge Cases
**What goes wrong:** Sentence segmentation splits incorrectly on `...` inside quotes, or misses `……` (double ellipsis), or splits on `。` inside decimal numbers.
**Why it happens:** Naive regex `(?<=[。！？…])` doesn't handle these edge cases.
**How to avoid:** Use a stateful parser that tracks quote context (`"" '' 《》`) and handles `……` as a single boundary. Skip `。` inside numbers (rare in fiction but possible).
**Warning signs:** Diff shows garbled sentence boundaries, especially around dialogue.

### Pitfall 4: Toolbar Appearing During IME Composition
**What goes wrong:** User is composing Chinese text via IME (underlined composing region), selection changes fire, toolbar appears and disappears rapidly.
**Why it happens:** IME composition creates transient selection changes.
**How to avoid:** Check `composer.composingRegion` -- if non-null, suppress toolbar. Or add a debounce (200ms) before showing toolbar.
**Warning signs:** Toolbar flickers during Chinese input.

### Pitfall 5: Diff Acceptance Undo Contamination
**What goes wrong:** User accepts a diff, then presses Ctrl+Z, which undoes the accept -- but also undoes unrelated prior edits.
**Why it happens:** `DeleteContentRequest` and `InsertTextRequest` are individually undoable. Multiple operations in sequence create multiple undo entries.
**How to avoid:** Use `editor.execute([...multiple requests...])` in a single batch -- super_editor groups them into one undo entry. Or implement a custom `EditCommand` that performs delete+insert atomically.
**Warning signs:** Ctrl+Z after diff acceptance reverts more than expected.

## Code Examples

Verified patterns from source code:

### Floating Toolbar with SelectionLayerLinks
```dart
// Source: super_editor-0.3.0-dev.51/lib/src/default_editor/super_editor.dart
// Source: super_editor example/lib/demos/interaction_spot_checks/toolbar_following_content_in_layer.dart

// In EditorPage, create links and pass to SuperEditor
final _selectionLinks = SelectionLayerLinks();

SuperEditor(
  editor: _editor,
  selectionLayerLinks: _selectionLinks,
  documentOverlayBuilders: [
    FunctionalSuperEditorLayerBuilder((context, editContext) {
      return _buildFloatingToolbarOverlay(editContext);
    }),
    DefaultCaretOverlayBuilder(),
  ],
)

// The overlay builder returns a widget that uses Follower
Widget _buildFloatingToolbarOverlay(SuperEditorContext editContext) {
  return ValueListenableBuilder<DocumentSelection?>(
    valueListenable: editContext.composer.selectionNotifier,
    builder: (context, selection, _) {
      if (selection == null || selection.isCollapsed) {
        return const SizedBox();
      }
      return Follower.withOffset(
        link: _selectionLinks.expandedSelectionBoundsLink,
        leaderAnchor: Alignment.topCenter,
        followerAnchor: Alignment.bottomCenter,
        offset: const Offset(0, -8),
        boundary: const ScreenFollowerBoundary(),
        child: SuperEditorPopover(
          popoverFocusNode: _toolbarFocusNode,
          editorFocusNode: editContext.editorFocusNode,
          child: _AiToolbarContent(),
        ),
      );
    },
  );
}
```

### BackgroundColorAttribution for Provenance
```dart
// Source: super_editor-0.3.0-dev.51/lib/src/default_editor/attributions.dart (lines 110-139)

class BackgroundColorAttribution implements Attribution {
  const BackgroundColorAttribution(this.color);

  @override
  String get id => 'background_color';

  final Color color;

  @override
  bool canMergeWith(Attribution other) {
    return this == other;
  }
}

// Usage: apply provenance highlight
const provenanceColor = Color(0x1A2196F3); // blue with 10% opacity
editor.execute([
  ToggleTextAttributionsRequest(
    documentRange: targetRange,
    attributions: {BackgroundColorAttribution(provenanceColor)},
  ),
]);
```

### InsertTextRequest with Attributions
```dart
// Source: super_editor-0.3.0-dev.51/lib/src/default_editor/text.dart (lines 2150-2178)

class InsertTextRequest implements EditRequest {
  InsertTextRequest({
    required this.documentPosition,
    required this.textToInsert,
    required this.attributions,
    this.createdAt,
  });

  final DocumentPosition documentPosition;
  final String textToInsert;
  final Set<Attribution> attributions;
  final DateTime? createdAt;
}

// Usage: insert AI-generated text with provenance
editor.execute([
  InsertTextRequest(
    documentPosition: insertionPosition,
    textToInsert: aiGeneratedText,
    attributions: {BackgroundColorAttribution(provenanceColor)},
  ),
]);
```

### DeleteContentRequest for Range Deletion
```dart
// Source: super_editor-0.3.0-dev.51/lib/src/default_editor/multi_node_editing.dart (lines 765-773)

class DeleteContentRequest implements EditRequest {
  DeleteContentRequest({required this.documentRange});
  final DocumentRange documentRange;
}

// Usage: delete old text before inserting replacement
editor.execute([
  DeleteContentRequest(documentRange: selectionRange),
]);
// Then insert new text at the resulting caret position
```

### PromptMiddleware Extension Pattern
```dart
// Source: lib/features/ai/application/prompt_pipeline.dart

class ContextAnchorMiddleware extends PromptMiddleware {
  const ContextAnchorMiddleware();

  @override
  PromptContext apply(PromptContext context) {
    if (context.anchors.isEmpty) return context;

    final buffer = StringBuffer('以下是作者指定的参考上下文，请在改写时参考：\n');
    for (final anchor in context.anchors) {
      buffer.write('\n【${anchor.label}】\n${anchor.text}\n');
    }

    return context.addMessage(ChatMessage.system(buffer.toString()));
  }
}
```

### SynthesisNotifier Pattern for Editor AI State
```dart
// Source: lib/features/ai/presentation/synthesis_notifier.dart

// Same pattern: Notifier<SynthesisState> with streaming
class EditorAINotifier extends Notifier<EditorAIState> {
  @override
  EditorAIState build() => const EditorAIState();

  void startToneRewrite(DocumentRange range, String selectedText) {
    state = EditorAIState(isStreaming: true, originalRange: range);
    _streamAI(operation: 'tone_rewrite', text: selectedText);
  }

  Future<void> _streamAI({required String operation, required String text}) async {
    final adapter = ref.read(openaiAdapterProvider);
    final pipeline = ref.read(editorPromptPipelineProvider);
    // ... build prompt, stream, post-process ...
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| super_editor `FloatingToolbar` widget | `SelectionLayerLinks` + `Follower` pattern | 0.3.0-dev series | The old `FloatingToolbar` was removed; use the Leader/Follower pattern instead |
| `DocumentComposer.selection` direct read | `composer.selectionNotifier` (ValueListenable) | 0.3.0 | Reactive selection listening via ValueListenable |
| Manual overlay positioning | `SuperEditorLayerBuilder` + `ContentLayerWidget` | 0.3.0 | Document overlays integrate with editor coordinate system |
| `overlord` CupertinoPopoverToolbar | Already available as transitive dep | Current | No need to add custom toolbar styling |

**Deprecated/outdated:**
- `FloatingToolbar` widget: Removed in 0.3.0-dev series. Use `Follower` + `SelectionLayerLinks` instead.
- Direct `DocumentComposer.selection` polling: Use `selectionNotifier` ValueListenable for reactive updates.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `BackgroundColorAttribution` with same color value won't conflict with itself on overlapping ranges | Pitfall 2 | May need custom `NamedAttribution` with unique ID instead; higher implementation effort |
| A2 | `overlord` 0.4.2 `CupertinoPopoverToolbar` API matches what the super_editor examples show | Standard Stack | May need to verify exact constructor signature; minor risk |
| A3 | `editor.execute([...multiple requests...])` batches into single undo entry | Pitfall 5 | May need custom `EditCommand` for atomic delete+insert; medium effort |
| A4 | Chinese sentence boundaries are adequately handled by `。！？…` characters | Pitfall 3 | Edge cases with quotes/numbers may require more sophisticated parser |
| A5 | `ScreenFollowerBoundary` is available in follow_the_leader 0.5.3 | Pattern 1 | May need `WidgetFollowerBoundary` with a viewport key instead |

## Open Questions (RESOLVED)

1. **Diff display approach: inline replacement vs side-by-side?** → **RESOLVED in Plan 02**
   - Decision: Use overlay highlights -- red background (0x33FF0000) for deletions, green background (0x3300FF00) for insertions. Rendered via DiffOverlayBuilder using editor document layout positioning. Accept/reject via floating AcceptRejectBar on selection.
   - Plan reference: 03-02-PLAN.md Task 2

2. **Batch undo for diff acceptance** → **RESOLVED in Plan 02**
   - Decision: Batch delete+insert in a single `editor.execute()` call per RESEARCH.md Pitfall 5. If this doesn't produce a single undo entry, fallback to custom `ReplaceTextRangeCommand` (deferred to execution spike).
   - Plan reference: 03-02-PLAN.md Task 2 behavior section

3. **Toolbar conflict with fixed EditorToolbar** → **RESOLVED in Plan 01**
   - Decision: Floating toolbar and fixed EditorToolbar serve different purposes (AI actions vs formatting) and coexist without conflict. Floating toolbar uses smart flip (D-08) and suppresses during IME composition (Pitfall 4). No proximity detection needed -- they occupy different screen regions.
   - Plan reference: 03-01-PLAN.md Task 2 action section

## Environment Availability

> No external dependencies required beyond what's already installed.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | 3.44.0 | -- |
| super_editor | Editor features | ✓ | 0.3.0-dev.20 | -- |
| follow_the_leader | Toolbar positioning | ✓ (transitive) | 0.5.3 | -- |
| overlord | Popover toolbar styling | ✓ (transitive) | 0.4.2 | Custom Material widget |
| openai_dart | AI streaming | ✓ | 6.0.0 | -- |
| flutter_riverpod | State management | ✓ | 3.3.1 | -- |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Dart SDK) |
| Config file | none -- standard flutter_test |
| Quick run command | `flutter test test/features/editor/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EDIT-02 | Selection triggers floating toolbar | widget | `flutter test test/features/editor/floating_toolbar_test.dart` | ❌ Wave 0 |
| EDIT-03 | Three AI actions available in toolbar | widget | `flutter test test/features/editor/floating_toolbar_test.dart` | ❌ Wave 0 |
| EDIT-05 | AI-modified text has provenance highlight | unit | `flutter test test/features/editor/provenance_test.dart` | ❌ Wave 0 |
| EDIT-06 | Selective undo reverts AI changes only | unit | `flutter test test/features/editor/selective_undo_test.dart` | ❌ Wave 0 |
| EDIT-07 | Context anchor injected into prompt | unit | `flutter test test/features/editor/context_anchor_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/editor/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/editor/floating_toolbar_test.dart` -- covers EDIT-02, EDIT-03
- [ ] `test/features/editor/provenance_test.dart` -- covers EDIT-05
- [ ] `test/features/editor/selective_undo_test.dart` -- covers EDIT-06
- [ ] `test/features/editor/context_anchor_test.dart` -- covers EDIT-07
- [ ] `test/features/editor/sentence_segmenter_test.dart` -- covers sentence segmentation utility
- [ ] `test/features/editor/diff_state_test.dart` -- covers diff state entities

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | API keys already handled in Phase 2 |
| V3 Session Management | no | No sessions in local-first app |
| V4 Access Control | no | Single-user app |
| V5 Input Validation | yes | Validate free-input text length, sanitize before sending to AI |
| V6 Cryptography | no | API key encryption already in Phase 2 |

### Known Threat Patterns for Flutter + super_editor

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Prompt injection via free-input | Tampering | Limit free-input length, don't include raw user input in system prompt |
| API key exposure in error messages | Information Disclosure | Reuse Phase 2 error classification (AIException hierarchy) |
| Excessive AI token usage | Denial of Service | Token budget calculator already exists; apply same limits to editor operations |

## Sources

### Primary (HIGH confidence)
- super_editor 0.3.0-dev.51 source: `/home/re/.pub-cache/hosted/pub.dev/super_editor-0.3.0-dev.51/` -- SelectionLayerLinks, SuperEditorLayerBuilder, attributions, document mutation requests
- attributed_text 0.4.7 source: `/home/re/.pub-cache/hosted/pub.dev/attributed_text-0.4.7/` -- Attribution interface, NamedAttribution, addAttribution/removeAttribution
- follow_the_leader 0.5.3 source: `/home/re/.pub-cache/hosted/pub.dev/follow_the_leader-0.5.3/` -- Follower, Leader, LeaderLink, FollowerBoundary
- overlord 0.4.2 source: `/home/re/.pub-cache/hosted/pub.dev/overlord-0.4.2/` -- CupertinoPopoverToolbar, CupertinoPopoverMenu
- Existing codebase: `lib/features/ai/application/prompt_pipeline.dart`, `lib/features/ai/presentation/synthesis_notifier.dart`

### Secondary (MEDIUM confidence)
- super_editor example: `example/lib/demos/interaction_spot_checks/toolbar_following_content_in_layer.dart` -- working toolbar-following-content pattern
- super_editor example: `example/lib/demos/in_the_lab/selected_text_colors_demo.dart` -- custom overlay builders with color styling

### Tertiary (LOW confidence)
- Training data: Chinese sentence segmentation patterns -- needs validation with real Chinese fiction text

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages verified in pub cache and pubspec.lock
- Architecture: HIGH -- patterns verified from source code and examples
- Pitfalls: MEDIUM -- based on source code analysis + training knowledge for Chinese text edge cases

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (30 days -- super_editor 0.3.0-dev API is still evolving)
