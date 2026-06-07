---
phase: 14-world-building-first-30-chapters
reviewed: 2026-06-08T12:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/features/ai/infrastructure/openai_adapter.dart
  - test/journey/deviation_warning_widget_test.dart
  - test/journey/full_journey_test.dart
  - test/journey/helpers/d11_bounds.dart
  - test/journey/serial_generation_test.dart
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-06-08T12:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed one production file (`openai_adapter.dart`) and four test files (two journey tests, one helper, one widget test). Previous review findings CR-01 (HTTPS bypass in `fetchModelList`) and CR-02 (client leak in `fetchModelList`) have been fixed -- `_validateBaseUrl` is now called and `finally` ensures `client.close()`. The WR-02 silent disposal resurrection remains unfixed. New findings: both deterministic test adapters contain a Unicode handling bug (`String.fromCharCode` used on code points instead of code units), multiple test helper functions use `dynamic` types suppressing compile-time safety, and credential-sanitization logic is duplicated across three locations.

## Critical Issues

### CR-01: Deterministic adapters emit wrong characters for supplementary-plane code points

**File:** `test/journey/full_journey_test.dart:400-402` and `test/journey/serial_generation_test.dart:440-442`
**Issue:** Both `_DeterministicFullJourneyAdapter` and `_DeterministicJourneyAdapter` iterate over `response.runes` (which yields Unicode code points / scalar values) and then call `String.fromCharCode(codePoint)`. The `String.fromCharCode` constructor takes a UTF-16 code unit, not a Unicode code point. For any code point above U+FFFF (supplementary plane characters such as emoji or CJK Extension-B), this produces two garbage replacement characters instead of the intended character.

The test data currently contains only BMP CJK text, so the bug does not trigger. However, the adapter is fundamentally incorrect. If test data is ever extended with emoji or rare characters -- a reasonable expectation for a creative writing tool -- streaming simulation will silently corrupt output.

**Fix:**
```dart
// Replace (in both adapters):
for (final codePoint in response.runes) {
  yield String.fromCharCode(codePoint);
}

// With:
yield response;
```
Or if deliberate per-character yielding is needed for streaming simulation:
```dart
for (final codePoint in response.runes) {
  yield String.fromCharCodes([codePoint]);
}
```

## Warnings

### WR-01: Disposed adapter silently resurrects on next use (unfixed from prior review)

**File:** `lib/features/ai/infrastructure/openai_adapter.dart:207-209`
**Issue:** `_getOrCreateClient` unconditionally resets `_disposed = false` whenever it is called after disposal. This means calling `createStream` or `fetchModelList` on a disposed adapter silently brings it back to life with a new client, masking programming errors where the adapter is used after explicit disposal. The `dispose` method exists specifically to release resources; callers who invoke it should not be able to accidentally resume operations. The `isActive` getter will return `true` again after resurrection, making lifecycle management unreliable.

**Fix:**
```dart
OpenAIClient _getOrCreateClient(String apiKey, String baseUrl) {
  if (_disposed) {
    throw StateError('OpenAIAdapter has been disposed. Create a new instance.');
  }
  // ... rest unchanged
}
```

### WR-02: Untyped `dynamic` parameters suppress compile-time safety in test helpers

**File:** `test/journey/full_journey_test.dart:275-282,320`
**Issue:** The `_generateChapter` helper uses `dynamic` for the `adapter`, `auditService`, and `chapterRepository` parameters. The `_createThirtyChapters` helper also uses `dynamic chapterRepository`. This suppresses all compile-time type checking. If the API of any of these objects changes (e.g., `recordAudit` is renamed, `updateDocumentContent` signature changes), the test fails at runtime with `NoSuchMethodError` instead of at compile time. All concrete types (`AIAdapter`, `TokenAuditService`, `ChapterRepository`) are available for import.

**Fix:** Import and use the concrete types:
```dart
Future<String> _generateChapter({
  required int index,
  required PromptPipeline pipeline,
  required AIAdapter adapter,
  required String apiKey,
  required String baseUrl,
  required String model,
  required Manuscript manuscript,
  required Chapter chapter,
  required TokenAuditService auditService,
  required ChapterRepository chapterRepository,
}) async { ... }

Future<List<Chapter>> _createThirtyChapters(
  ChapterRepository chapterRepository,
  String manuscriptId,
) async { ... }
```

### WR-03: Duplicate credential-sanitization logic across test files and production code

**File:** `test/journey/full_journey_test.dart:342-361` and `test/journey/serial_generation_test.dart:287-306`
**Issue:** The `_safeExceptionDiagnostic` function is identically duplicated in both test files. This is the same logic that exists as `OpenAIAdapter._safeDiagnostic` (private, line 139-158) in the production code. Any regex fix or enhancement must be applied in three places. Duplication of security-sensitive code (credential sanitization) is particularly risky because a fix applied to only one copy leaves the others vulnerable.

**Fix:** Make `OpenAIAdapter._safeDiagnostic` public (rename to `safeDiagnostic`), then call `OpenAIAdapter.safeDiagnostic` from tests. Alternatively, extract to a shared utility in `test/journey/helpers/`.

## Info

### IN-01: `_safeExceptionDiagnostic` in tests duplicates production `OpenAIAdapter._safeDiagnostic`

**File:** `test/journey/full_journey_test.dart:342-361`, `test/journey/serial_generation_test.dart:287-306`, `lib/features/ai/infrastructure/openai_adapter.dart:139-158`
**Issue:** As noted in WR-03, the credential-sanitization regex logic exists in three places. The production method is `static` and could be made accessible for test reuse with a simple rename.

**Fix:** Rename `_safeDiagnostic` to `safeDiagnostic` in `openai_adapter.dart` and call `OpenAIAdapter.safeDiagnostic` from both test files.

### IN-02: World-building setup duplicated across journey test files

**File:** `test/journey/full_journey_test.dart:102-138` and `test/journey/serial_generation_test.dart:308-341`
**Issue:** `_phaseAWorldBuilding` in `full_journey_test.dart` and `_setupWorldBuilding` in `serial_generation_test.dart` perform identical setup: load xianxia template, create draft, add four character cards, add skill rules, refresh name index. This is ~30 lines of identical code duplicated between the two files.

**Fix:** Extract world-building setup into a shared helper function in `test/journey/helpers/` (e.g., `setupXianxiaWorld`).

### IN-03: `_JourneyResult.snapshot` typed as `dynamic` loses type safety

**File:** `test/journey/serial_generation_test.dart:470`
**Issue:** The `_JourneyResult` class declares `snapshot` as `dynamic`, losing type information. The actual type returned by `auditRepository.buildSnapshot()` is known and should be used. Properties accessed on `snapshot` (`.totalCalls`, `.totalInputTokens`, `.totalOutputTokens`) get no compile-time validation.

**Fix:** Import the snapshot type and use it in the class:
```dart
final TokenAuditSnapshot snapshot;
```

---

_Reviewed: 2026-06-08T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
