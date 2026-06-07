---
phase: 14-world-building-first-30-chapters
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/features/ai/application/anti_ai_scent_processor.dart
  - lib/features/ai/infrastructure/openai_adapter.dart
findings:
  critical: 2
  warning: 2
  info: 1
  total: 5
status: issues_found
---

# Phase 14: Code Review Report (Production Files)

**Reviewed:** 2026-06-08T00:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the 2 production files modified during Phase 14 (plans 05 and 06): the anti-AI-scent processor and the OpenAI adapter. Two critical security/correctness issues were found in `openai_adapter.dart`: the `fetchModelList` method bypasses HTTPS enforcement (leaking API keys over plaintext HTTP), and the client created inside `fetchModelList` is never closed when an exception occurs. In `anti_ai_scent_processor.dart`, highlight positions recorded during early replacement phases become stale after subsequent text mutations, producing incorrect offsets in the public `ProcessingResult.highlights` list. A post-dispose reactivation in the adapter silently hides resource leaks.

## Critical Issues

### CR-01: fetchModelList bypasses HTTPS baseUrl validation, leaking API keys over plaintext HTTP

**File:** `lib/features/ai/infrastructure/openai_adapter.dart:170-186`
**Issue:** `createStream` calls `_validateBaseUrl(baseUrl)` at line 56, enforcing HTTPS (T-02-08) to prevent API key leakage. However, `fetchModelList` creates a new `OpenAIClient` directly at line 176 without calling `_validateBaseUrl`. A caller providing `http://evil-server.com/v1` with a real API key will send that key in plaintext over the network. This contradicts the class-level security invariant documented at line 7 ("HTTPS enforcement per T-02-08").

The caller `provider_management_notifier.dart:277` passes user-provided `baseUrl` directly to this method, so user input reaches the network unvalidated.

**Fix:** Add `_validateBaseUrl(baseUrl)` at the start of `fetchModelList`, before the empty-key early return:

```dart
Future<List<String>> fetchModelList({
  required String apiKey,
  required String baseUrl,
}) async {
  _validateBaseUrl(baseUrl);
  if (apiKey.isEmpty) return [];
  // ... rest unchanged
}
```

### CR-02: fetchModelList leaks OpenAIClient when the HTTP call throws

**File:** `lib/features/ai/infrastructure/openai_adapter.dart:175-185`
**Issue:** At line 176, a new `OpenAIClient` is created. On the happy path (line 180), `client.close()` is called. But if `client.models.list()` or `.timeout()` throws at line 177, execution jumps to the `catch` block at line 182 and the client is never closed. Since `fetchModelList` is called every time a user opens the model picker (via `provider_management_notifier.dart:277`), repeated network errors accumulate leaked TCP connections and socket handles.

**Fix:** Use a try/finally to guarantee cleanup:

```dart
Future<List<String>> fetchModelList({
  required String apiKey,
  required String baseUrl,
}) async {
  _validateBaseUrl(baseUrl);
  if (apiKey.isEmpty) return [];
  final client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
  try {
    final modelList = await client.models.list().timeout(
      const Duration(seconds: 5),
    );
    return modelList.data.map((m) => m.id).toList();
  } catch (_) {
    return [];
  } finally {
    client.close();
  }
}
```

## Warnings

### WR-01: Highlight positions in ProcessingResult become stale after multi-phase text mutations

**File:** `lib/features/ai/application/anti_ai_scent_processor.dart:127-144,216-220,286-290`
**Issue:** The `process` method runs three phases sequentially: auto-replacement (line 127), extra banned phrases (line 131), and structural highlights (line 139). Each phase mutates `processedText` by inserting or deleting characters, but highlights recorded in earlier phases store `start`/`end` positions relative to the text at the time they were found, not the final text. After phases 1 and 1b shorten the string (deleting banned phrases), the structural highlighting phase runs on a shorter string. Conversely, highlights from phases 1 and 1b are not adjusted for subsequent mutations by other phases.

For example, processing `"然而，他不仅聪明而且勤奋。"` first replaces `"然而"` with `"但是"` (shifting all positions by -1), then wraps `"不仅聪明而且"` with brackets (inserting 2 characters). The final `highlights` list contains positions from three different coordinate systems that do not correspond to `processedText`.

Currently no production code in `lib/` reads the `start`/`end` values (only tests consume them), so this has no runtime impact yet. However, the fields are part of the public API and will produce incorrect offsets once a UI consumer tries to highlight the original locations.

**Fix:** After all three phases complete, either (a) track cumulative offset adjustments and apply them retroactively to earlier highlights, or (b) record the original text positions during processing and compute final positions in a post-processing pass. A simpler approach is to defer highlight creation to a final pass that re-finds all patterns in the already-processed text.

### WR-02: _disposed flag silently resets, allowing post-dispose adapter reuse without warning

**File:** `lib/features/ai/infrastructure/openai_adapter.dart:205-207`
**Issue:** When `_getOrCreateClient` is called after `dispose()`, it silently resets `_disposed = false` and creates a new client. This means calling `createStream` on a disposed adapter "works" -- it allocates a new TCP connection and caches new credentials. The `isActive` getter (line 161) will return `true` again. This violates the expected semantics of `dispose()`: callers reasonably expect that a disposed object is dead and will throw if used. Silent reactivation hides resource leaks (the old client was already closed, but the caller thought the adapter was inert) and makes lifecycle bugs harder to detect.

**Fix:** Throw an explicit error instead of silently resetting:

```dart
OpenAIClient _getOrCreateClient(String apiKey, String baseUrl) {
  if (_disposed) {
    throw StateError('OpenAIAdapter has been disposed. Create a new instance.');
  }
  // ... rest unchanged
}
```

## Info

### IN-01: _isAtValidBoundary uses UTF-16 code-unit indexing that could split surrogate pairs

**File:** `lib/features/ai/application/anti_ai_scent_processor.dart:252-253`
**Issue:** `text[index - 1]` and `text[afterIndex]` access the string by UTF-16 code unit. For supplementary-plane Unicode characters (e.g., rare CJK Extension B characters, emoji), this would return a lone surrogate half rather than a full code point, causing `_isCjkChar` to return `false` for a character that is actually CJK. In practice, all characters in the synonym map and structural patterns are BMP (Basic Multilingual Plane) CJK, so this is not currently triggered. The risk is purely theoretical given the Chinese text domain, but the method's doc comment does not document this limitation.

**Fix:** For consistency with `_isCjkChar` (which uses `char.runes.first`), extract code points via `text.runes` rather than indexing by code unit. Alternatively, document the BMP-only limitation in the method's doc comment and move on.

---

_Reviewed: 2026-06-08T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
