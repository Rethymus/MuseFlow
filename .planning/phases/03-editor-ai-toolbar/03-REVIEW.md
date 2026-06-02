---
phase: 03-editor-ai-toolbar
reviewed: 2026-06-02T14:30:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - lib/core/presentation/providers.dart
  - lib/features/ai/application/prompt_pipeline.dart
  - lib/features/editor/application/context_anchor_middleware.dart
  - lib/features/editor/application/context_anchor_notifier.dart
  - lib/features/editor/application/diff_calculator.dart
  - lib/features/editor/application/editor_ai_notifier.dart
  - lib/features/editor/application/editor_prompt_pipeline.dart
  - lib/features/editor/application/selective_undo.dart
  - lib/features/editor/application/sentence_segmenter.dart
  - lib/features/editor/domain/context_anchor.dart
  - lib/features/editor/domain/diff_state.dart
  - lib/features/editor/domain/editor_ai_state.dart
  - lib/features/editor/infrastructure/provenance_attribution.dart
  - lib/features/editor/presentation/context_anchor_indicator.dart
  - lib/features/editor/presentation/diff_display.dart
  - lib/features/editor/presentation/editor_page.dart
  - lib/features/editor/presentation/floating_toolbar.dart
  - lib/features/editor/presentation/status_bar.dart
findings:
  critical: 5
  warning: 5
  info: 3
  total: 13
status: issues_found
---

# Phase 03: Code Review Report — Editor AI Toolbar

**Reviewed:** 2026-06-02T14:30:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Reviewed the editor AI toolbar feature implementing floating toolbar, sentence-level diff accept/reject, context anchors, selective undo, and provenance attribution. The architecture is sound — clean separation of domain/application/presentation layers, correct Riverpod patterns, and good use of immutable state. However, five critical bugs were found: two document-corruption-class issues in the diff/accept/reject flow, one crash-prone unsafe cast, and two data-loss risks in the undo system.

## Critical Issues

### CR-01: DiffCalculator offset drift for insertions corrupts downstream accept/reject

**File:** `lib/features/editor/application/diff_calculator.dart:72-84`
**Issue:** When an AI sentence has no original counterpart (insertion), the `offset` counter advances by the AI text length (`offset += ai.length`). However, insertions add text at the current position without "consuming" any original text. The offset should remain unchanged for pure insertions. This causes all subsequent `SentenceDiff.startOffset`/`endOffset` values to be wrong, which cascades into `acceptSentence` and `rejectSentence` operating on incorrect document ranges — potentially corrupting the document.
**Fix:**
```dart
// Line 82: Do NOT advance offset for insertions
// Change:
//   offset += ai.length;
// To:
//   offset += 0; // no original text consumed
```

### CR-02: acceptAll/rejectAll mutate state while iterating, skipping sentences

**File:** `lib/features/editor/application/editor_ai_notifier.dart:318-337`
**Issue:** `acceptAll()` and `rejectAll()` iterate `currentDiff.sentences` by index, calling `acceptSentence(i)` / `rejectSentence(i)` inside the loop. Each call to `_updateSentenceStatus` replaces `state.diffResult` with a new `DiffResult`. The loop variable `currentDiff` is captured once before the loop, so the `sentences` list reference is stale after the first mutation. However, the real problem is that `acceptSentence` at line 207 re-reads `state.diffResult` which has already been mutated — if the document changes between accepts (e.g., text insertion shifting offsets), later indices become incorrect. More critically, because `acceptSentence` modifies the document (deletes + inserts), subsequent sentence offsets in the stale `currentDiff` may no longer match the document state.
**Fix:**
```dart
void acceptAll() {
  final currentDiff = state.diffResult;
  if (currentDiff == null) return;
  // Collect indices first, then process in reverse to preserve offsets
  final pendingIndices = <int>[];
  for (var i = 0; i < currentDiff.sentences.length; i++) {
    if (currentDiff.sentences[i].status == DiffStatus.pending) {
      pendingIndices.add(i);
    }
  }
  // Process in reverse order so earlier offsets remain valid
  for (final i in pendingIndices.reversed) {
    acceptSentence(i);
  }
}
```

### CR-03: Unsafe cast in ContextAnchorMiddleware will crash if non-ContextAnchor types exist

**File:** `lib/features/editor/application/context_anchor_middleware.dart:32`
**Issue:** `anchorRefs.cast<ContextAnchor>()` performs an unchecked cast on every element. If any `AnchorReference` implementation that is not a `ContextAnchor` is present, this throws a `TypeError` at runtime. The `AnchorReference` interface exists specifically to allow different implementations, yet the middleware hard-casts to one concrete type.
**Fix:**
```dart
// Replace line 32:
final anchors = anchorRefs.cast<ContextAnchor>();
// With:
final anchors = anchorRefs.whereType<ContextAnchor>().toList();
```

### CR-04: SelectiveUndoService records stale endOffset — undo corrupts document

**File:** `lib/features/editor/application/editor_ai_notifier.dart:226-236` and `lib/features/editor/application/selective_undo.dart:95-112`
**Issue:** When `acceptSentence` records an undo entry, it captures `sentence.startOffset` and `sentence.endOffset` as the range of the **original** text. After acceptance, the AI replacement text occupies that range — but `replacementText.length` may differ from `originalText.length`. The `UndoEntry.endOffset` still reflects the old range. When `undoLastAIChange()` is called, it uses `entry.startOffset..entry.endOffset` to delete the range, which may be too short (leaving AI text fragments) or too long (deleting human text after the replacement).
**Fix:**
```dart
// In acceptSentence, record the range based on the replacement text length:
undoService.record(
  originalText: sentence.originalText!,
  replacementText: sentence.newText ?? '',
  nodeId: sentence.nodeId,
  startOffset: sentence.startOffset,
  // endOffset should reflect the range AFTER acceptance (replaced text length)
  endOffset: sentence.startOffset + (sentence.newText?.length ?? 0),
);
```

### CR-05: Synchronous read of async providers returns null before data loads

**File:** `lib/features/editor/application/editor_ai_notifier.dart:106` and `lib/features/editor/application/editor_ai_notifier.dart:414`
**Issue:** `ref.read(activeApiKeyProvider)` and `ref.read(bannedPhrasesProvider)` read from providers that wrap `FutureProvider` values via `.asData?.value`. If the async data has not yet loaded (e.g., on first app launch or after a provider rebuild), these return `null`. For the API key, this triggers a false "API Key invalid" error even when a valid key exists — it just hasn't loaded yet. For banned phrases, it silently returns an empty list, which is less severe but still incorrect.
**Fix:**
```dart
// Option A: Check if data is available and show a loading state
final apiKeyAsync = ref.read(apiKeyFutureProvider);
if (apiKeyAsync is AsyncLoading) {
  state = state.copyWith(isStreaming: false, error: '正在加载配置，请稍后重试');
  return;
}
final apiKey = apiKeyAsync.asData?.value;
if (apiKey == null || apiKey.isEmpty) {
  state = state.copyWith(isStreaming: false, error: 'API Key 无效，请检查设置');
  return;
}
```

## Warnings

### WR-01: EditorOperationMiddleware assumes first message is always system message

**File:** `lib/features/editor/application/editor_prompt_pipeline.dart:63-69`
**Issue:** The middleware checks `context.messages.isEmpty` and if not, appends to `context.messages[0]` by calling `replaceSystemMessage(0, ...)`. This assumes the first message is always a system message. If the pipeline ordering changes or a middleware is removed that normally creates the system message, the operation instruction would be appended to whatever message happens to be at index 0, potentially producing malformed prompts.
**Fix:**
```dart
if (context.messages.isEmpty) {
  return context.addMessage(ChatMessage.system(instruction));
}
// Verify first message is actually a system message before appending
final firstMessage = context.messages[0];
final firstContent = _extractContent(firstMessage);
if (firstContent.isEmpty) {
  return context.addMessage(ChatMessage.system(instruction));
}
return context.replaceSystemMessage(0, '$firstContent\n\n$instruction');
```

### WR-02: _extractContent uses dynamic typing and relies on toJson() structure

**File:** `lib/features/editor/application/editor_prompt_pipeline.dart:73-78`
**Issue:** `_extractContent(dynamic message)` accepts a `dynamic` parameter and calls `message.toJson()`. The `ChatMessage` type from `openai_dart` may not expose a `toJson()` method, or its JSON structure may differ from what's assumed. This will throw a `NoSuchMethodError` at runtime if the API changes. The parameter should be typed as `ChatMessage` and use the proper API to extract content.
**Fix:**
```dart
String _extractContent(ChatMessage message) {
  // Use the ChatMessage API directly rather than toJson()
  // Check openai_dart docs for the correct content accessor
  try {
    final json = message.toJson();
    final content = json['content'];
    if (content is String) return content;
    if (content is List) {
      return content
          .whereType<Map>()
          .map((c) => c['text'] ?? '')
          .join();
    }
  } catch (_) {
    // Fallback: use toString()
  }
  return '';
}
```

### WR-03: getSelectedText can throw RangeError if offsets exceed node text length

**File:** `lib/features/editor/presentation/floating_toolbar.dart:219-235`
**Issue:** `_getSelectedText` extracts a substring using `node.text.toPlainText().substring(start, end)` without bounds checking. If the document has been modified since the selection was made (e.g., another user's edit in a collaborative scenario, or rapid edits), `start` or `end` may exceed the text length, causing a `RangeError`.
**Fix:**
```dart
String _getSelectedText(DocumentSelection selection) {
  final document = widget.editor.document;
  final nodeId = selection.base.nodeId;
  final node = document.getNodeById(nodeId);
  if (node is! TextNode) return '';

  final plainText = node.text.toPlainText();
  final baseOffset = (selection.base.nodePosition as TextNodePosition).offset;
  final extentOffset = (selection.extent.nodePosition as TextNodePosition).offset;
  final start = baseOffset < extentOffset ? baseOffset : extentOffset;
  final end = baseOffset < extentOffset ? extentOffset : baseOffset;

  if (start == end || start >= plainText.length) return '';
  final safeEnd = end.clamp(0, plainText.length);
  return plainText.substring(start, safeEnd);
}
```

### WR-04: DiffHighlightPainter covers entire node instead of sentence range

**File:** `lib/features/editor/presentation/diff_display.dart:308-346`
**Issue:** The `_DiffHighlightPainter.paint()` draws a rectangle covering `Rect.fromLTWH(0, 0, size.width, size.height)` — the entire widget area. Since `_SentenceHighlight` returns a `CustomPaint` without explicit sizing, it inherits the parent's size, which is the full node area. This means the highlight covers the entire paragraph, not just the sentence. The `startOffset`/`endOffset` fields are stored but never used in the paint method.
**Fix:** The painter needs access to the text layout to calculate character-level bounding boxes. As a minimum viable fix, document this limitation and add a TODO for proper text layout integration:
```dart
@override
void paint(Canvas canvas, Size size) {
  // TODO: Use text layout to get precise character bounding boxes
  // for startOffset..endOffset range instead of covering the full node.
  final paint = Paint()..color = color;
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
}
```

### WR-05: EditorPromptPipeline instantiates directly instead of using provider

**File:** `lib/features/editor/application/editor_ai_notifier.dart:116`
**Issue:** `final pipeline = EditorPromptPipeline();` creates a new instance directly instead of using `ref.read(editorPromptPipelineProvider)`. While `EditorPromptPipeline` is currently stateless, bypassing the provider graph breaks the dependency injection pattern established in `providers.dart`. If middleware configuration ever needs to be dynamic (e.g., user-configurable system prompt), this bypass would miss it.
**Fix:**
```dart
final pipeline = ref.read(editorPromptPipelineProvider);
```

## Info

### IN-01: Unused import — `banned_phrase_settings.dart` in editor_ai_notifier

**File:** `lib/features/editor/application/editor_ai_notifier.dart:19`
**Issue:** `banned_phrase_settings.dart` is imported for `bannedPhrasesProvider`, but the provider is only used inside `_getBannedPhrases()`. This is a presentation-layer file being imported in an application-layer file, violating the Clean Architecture dependency rule (application should not depend on presentation).
**Fix:** Move `bannedPhrasesProvider` to the application layer or a shared providers file.

### IN-02: Duplicate selection offset extraction logic

**File:** `lib/features/editor/presentation/floating_toolbar.dart:143-148, 194-200, 225-230`
**Issue:** The pattern of extracting `baseOffset`, `extentOffset`, `start`, `end` from a `DocumentSelection` is repeated three times in `FloatingToolbar` and once in `diff_display.dart`. This should be extracted into a shared utility.
**Fix:**
```dart
// Add to a shared utility file:
({int start, int end, String nodeId}) extractSelectionRange(DocumentSelection selection) {
  final baseOffset = (selection.base.nodePosition as TextNodePosition).offset;
  final extentOffset = (selection.extent.nodePosition as TextNodePosition).offset;
  return (
    start: baseOffset < extentOffset ? baseOffset : extentOffset,
    end: baseOffset < extentOffset ? extentOffset : baseOffset,
    nodeId: selection.base.nodeId,
  );
}
```

### IN-03: UndoEntry.timestamp included in equality check

**File:** `lib/features/editor/application/selective_undo.dart:44-52`
**Issue:** The `UndoEntry.==` operator includes `timestamp` in the comparison. Two entries with identical content but different creation times will not be equal. This is technically correct for identity semantics but could cause issues if entries are compared in tests or deduplication logic.
**Fix:** Consider whether `timestamp` should participate in equality. If not, remove it from `==` and `hashCode`.

---

_Reviewed: 2026-06-02T14:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
