---
phase: 02-ai-provider-capture-synthesis
reviewed: 2026-06-02T12:00:00Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - lib/app.dart
  - lib/core/infrastructure/settings_repository.dart
  - lib/core/presentation/providers.dart
  - lib/features/ai/application/anti_ai_scent_processor.dart
  - lib/features/ai/application/prompt_middlewares/banned_list_middleware.dart
  - lib/features/ai/application/prompt_middlewares/persona_injection_middleware.dart
  - lib/features/ai/application/prompt_middlewares/system_prompt_middleware.dart
  - lib/features/ai/application/prompt_middlewares/user_content_middleware.dart
  - lib/features/ai/application/prompt_pipeline.dart
  - lib/features/ai/application/provider_service.dart
  - lib/features/ai/application/token_budget_calculator.dart
  - lib/features/ai/domain/ai_exception.dart
  - lib/features/ai/domain/ai_provider.dart
  - lib/features/ai/domain/synthesis_request.dart
  - lib/features/ai/infrastructure/openai_adapter.dart
  - lib/features/ai/infrastructure/preset_providers.dart
  - lib/features/ai/infrastructure/provider_repository.dart
  - lib/features/ai/presentation/banned_phrase_settings.dart
  - lib/features/ai/presentation/provider_card.dart
  - lib/features/ai/presentation/provider_management_notifier.dart
  - lib/features/ai/presentation/provider_management_page.dart
  - lib/features/ai/presentation/synthesis_notifier.dart
  - lib/features/ai/presentation/synthesis_panel.dart
  - lib/features/capture/presentation/capture_page.dart
  - lib/features/editor/presentation/editor_page.dart
  - lib/features/settings/presentation/settings_page.dart
  - lib/shared/constants/app_constants.dart
findings:
  critical: 2
  warning: 5
  info: 4
  total: 11
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-06-02T12:00:00Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

Reviewed all 26 source files for Phase 2 (AI provider management, streaming adapter, prompt pipeline, synthesis UX). The architecture follows Clean Architecture conventions well, with clear layer separation. However, the review found 2 critical bugs and 5 warnings. The critical issues are: (1) `SynthesisState.copyWith` cannot clear nullable fields to null, causing stale data to persist across synthesis cycles; (2) `_postProcess` in `SynthesisNotifier` passes an empty banned-phrases list, meaning user-configured banned phrases are never applied during anti-AI-scent post-processing.

## Critical Issues

### CR-01: SynthesisState.copyWith cannot clear nullable fields to null

**File:** `lib/features/ai/presentation/synthesis_notifier.dart:62-79`
**Issue:** The `copyWith` method for `SynthesisState` uses `??` for nullable fields (`error`, `excludedFragmentsNotice`), which means it is impossible to clear these fields back to null. When a new synthesis starts after a previous error, the old `error` and `excludedFragmentsNotice` values persist because `state.copyWith(error: null)` evaluates to `error ?? this.error`, preserving the previous non-null value.

For example, in `_runSynthesis` (line 173), a new synthesis resets state to `SynthesisState(isStreaming: true, additionalInstruction: additionalInstruction)` -- this correctly starts fresh. But in `_postProcess` (line 283), `state.copyWith(...)` cannot clear `error` from a previous run if the current run succeeds. Similarly, `regenerate` calls `_runSynthesis` which creates a fresh state, but any intermediate `copyWith` calls that attempt to clear `error` silently fail.

The same pattern affects `ProviderManagementState.copyWith` in `provider_management_notifier.dart:28-51`, which correctly uses `clearError` / `clearConnectionResult` boolean flags to work around this problem. `SynthesisState` should follow the same pattern but does not.

**Fix:**
```dart
SynthesisState copyWith({
  String? accumulatedText,
  bool? isStreaming,
  bool? isEditing,
  String? error,
  bool clearError = false,
  String? excludedFragmentsNotice,
  bool clearExcludedNotice = false,
  List<TextHighlight>? highlights,
  String? additionalInstruction,
}) {
  return SynthesisState(
    accumulatedText: accumulatedText ?? this.accumulatedText,
    isStreaming: isStreaming ?? this.isStreaming,
    isEditing: isEditing ?? this.isEditing,
    error: clearError ? null : (error ?? this.error),
    excludedFragmentsNotice:
        clearExcludedNotice ? null : (excludedFragmentsNotice ?? this.excludedFragmentsNotice),
    highlights: highlights ?? this.highlights,
    additionalInstruction: additionalInstruction ?? this.additionalInstruction,
  );
}
```

Then in `_postProcess`, clear the error explicitly:
```dart
state = state.copyWith(
  accumulatedText: result.processedText,
  highlights: result.highlights,
  isStreaming: false,
  isEditing: true,
  clearError: true,
  clearExcludedNotice: true,
);
```

### CR-02: Post-processing bypasses user-configured banned phrases

**File:** `lib/features/ai/presentation/synthesis_notifier.dart:274-289`
**Issue:** The `_postProcess` method creates a hard-coded empty list `bannedPhrases = <String>[]` (line 276) and passes it to `processor.process()`. This means the user's configured banned phrases (stored via `BannedPhraseSettingsPage` and loaded in `_getBannedPhrases`) are only used for the *prompt* (middleware layer), but never for the *post-processing* phase. The `AntiAIScentProcessor.process()` method accepts `bannedPhrases` as extra phrases to delete, and these are applied in Phase 1b of processing. By passing an empty list, the user's custom banned phrases are never removed from the generated text -- only the built-in synonym map entries are replaced.

The `_getBannedPhrases` method exists (line 312) and is called during prompt building (line 235), but its result is not passed to `_postProcess`.

**Fix:**
```dart
void _postProcess(List<String> bannedPhrases) {
  final processor = ref.read(antiAIScentProcessorProvider);

  final result = processor.process(
    state.accumulatedText,
    bannedPhrases: bannedPhrases,
  );

  state = state.copyWith(
    accumulatedText: result.processedText,
    highlights: result.highlights,
    isStreaming: false,
    isEditing: true,
    clearError: true,
  );
}
```

And in `_fetchKeyAndStream`, pass the phrases through:
```dart
final bannedPhrases = await _getBannedPhrases();
// ... build pipeline with bannedPhrases ...
// ... after streaming ...
_postProcess(bannedPhrases);
```

## Warnings

### WR-01: OpenAIAdapter resurrects disposed state silently

**File:** `lib/features/ai/infrastructure/openai_adapter.dart:124-126`
**Issue:** In `_getOrCreateClient`, if `_disposed` is true, it silently resets `_disposed = false` and continues. This means a `dispose()` call followed by `createStream()` will resurrect the adapter in an inconsistent state -- the cached API key and base URL are cleared by `dispose()` (lines 111-112), but the adapter acts as if it was never disposed. The caller has no indication this happened. If `dispose()` was called intentionally (e.g., cleanup on logout), this resurrection is a logic error.

**Fix:** Either throw an exception when used after disposal, or remove the dispose/resurrect pattern and rely solely on provider invalidation:
```dart
OpenAIClient _getOrCreateClient(String apiKey, String baseUrl) {
  if (_disposed) {
    throw StateError('OpenAIAdapter has been disposed');
  }
  // ... rest unchanged ...
}
```

### WR-02: Test connection hardcodes model to gpt-4o-mini

**File:** `lib/features/ai/application/provider_service.dart:114`
**Issue:** `testConnection` hardcodes `model: 'gpt-4o-mini'` in the test request. If the user is configuring a DeepSeek or Ollama provider, sending a `gpt-4o-mini` model name may fail or produce misleading results. The model parameter should match the provider being configured.

**Fix:** Accept the model as a parameter:
```dart
Future<void> testConnection({
  required String apiKey,
  required String baseUrl,
  required String model,
}) async {
  // ... use model parameter instead of hardcoded value ...
      model: model,
  // ...
}
```
Update callers in `provider_management_notifier.dart` and `provider_management_page.dart` to pass the current model value.

### WR-03: SynthesisNotifier does not cancel in-flight stream on reset/dispose

**File:** `lib/features/ai/presentation/synthesis_notifier.dart:149-170`
**Issue:** `reset()` sets state to idle but does not cancel any in-flight streaming operation. If `_fetchKeyAndStream` is running its `await for` loop (line 254), calling `reset()` or starting a new `startSynthesis()` will leave the previous stream subscription active. The old stream will continue writing to `state` via `copyWith`, overwriting the new synthesis state. This can cause ghost text from a cancelled synthesis to appear in the UI.

**Fix:** Track the stream subscription and cancel it on reset:
```dart
StreamSubscription<String>? _activeStream;

void reset() {
  _activeStream?.cancel();
  _activeStream = null;
  state = const SynthesisState();
}
```

### WR-04: PersonaInjectionMiddleware and BannedListMiddleware duplicate _extractContent logic

**File:** `lib/features/ai/application/prompt_middlewares/persona_injection_middleware.dart:43-48`
**File:** `lib/features/ai/application/prompt_middlewares/banned_list_middleware.dart:41-45`
**Issue:** Both middlewares contain an identical `_extractContent` helper that uses `message.toJson()` to extract the content string. This duplicated logic is fragile -- if the `ChatMessage` serialization format changes, both must be updated in lockstep. More importantly, the approach of deserializing to JSON just to read the content is brittle and could break if `openai_dart` changes its serialization format.

**Fix:** Extract a shared utility method, or better yet, use the typed `ChatMessage` API directly. If `openai_dart` does not expose a content getter, create a single shared helper in the pipeline module:
```dart
// In prompt_pipeline.dart
String extractMessageContent(ChatMessage message) {
  final json = message.toJson();
  final content = json['content'];
  return content is String ? content : '';
}
```

### WR-05: Presentation layer export of editorProvider breaks layer boundary

**File:** `lib/core/presentation/providers.dart:16-17`
**Issue:** The `providers.dart` file (core/presentation layer) re-exports `editorProvider` from `features/editor/presentation/editor_page.dart`. This creates a cross-feature dependency where core depends on a specific feature. Additionally, `editorProvider` is defined in `editor_page.dart` but imported through this re-export in `synthesis_notifier.dart`, making it hard to trace the dependency origin.

**Fix:** Move the `EditorHolderNotifier` and `editorProvider` definition to a dedicated file like `lib/features/editor/presentation/editor_provider.dart` (which already exists and is imported by `editor_page.dart`). Import it directly from `synthesis_notifier.dart` instead of through the core re-export. Remove the re-export from `core/presentation/providers.dart`.

## Info

### IN-01: SynthesisRequest domain class is unused

**File:** `lib/features/ai/domain/synthesis_request.dart`
**Issue:** The `SynthesisRequest` value object is defined in the domain layer but never referenced anywhere in the codebase. `SynthesisNotifier` uses inline fields instead of a `SynthesisRequest` object. Either use it or remove it to avoid dead code.

### IN-02: Magic number for token budget in synthesis

**File:** `lib/features/ai/presentation/synthesis_notifier.dart:223`
**Issue:** The fragment content budget is hardcoded as `3000` with no explanation of how this value was derived. This should be a named constant or computed dynamically based on the active provider's model context window.

### IN-03: PresetProviders.all creates new DateTime on every access

**File:** `lib/features/ai/infrastructure/preset_providers.dart:16-17`
**Issue:** `PresetProviders.all` creates a new `DateTime.now()` on every call. Since these are template objects that get new IDs when saved, the `createdAt` timestamp is unused. Consider using a static constant or removing the timestamp from presets.

### IN-04: ProviderCard exposes baseUrl in description

**File:** `lib/features/ai/presentation/provider_card.dart:91-93`
**Issue:** The OpenAI and DeepSeek card descriptions include the full base URL (e.g., `'GPT-4o Mini, https://api.openai.com/v1'`). This is potentially confusing UI text that exposes infrastructure details to non-technical users. Consider showing only the model name or a simplified description.

---

_Reviewed: 2026-06-02T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
