---
phase: 06-multi-provider-android-polish
plan: 02
subsystem: ai
tags: [model-parameters, temperature, topP, maxTokens, model-list, fetch-models, tdd]
dependency_graph:
  requires: [AIProvider entity, OpenAIAdapter, ProviderService, ProviderManagementNotifier]
  provides: [Nullable temperature/topP/maxTokens on AIProvider, fetchModelList on OpenAIAdapter, parameter validation functions, model combo input in provider form]
  affects: [ai_provider, openai_adapter, synthesis_notifier, editor_ai_notifier, provider_management_page, provider_management_notifier, provider_service]
tech_stack:
  added: []
  patterns: [sentinel-based copyWith for nullable fields, parameter validation functions, model list fetching with silent fallback]
key_files:
  created:
    - lib/features/ai/presentation/parameter_validation.dart
    - test/features/ai/presentation/parameter_validation_test.dart
    - test/features/ai/infrastructure/model_list_fetch_test.dart
  modified:
    - lib/features/ai/domain/ai_provider.dart
    - lib/features/ai/infrastructure/openai_adapter.dart
    - lib/features/ai/presentation/synthesis_notifier.dart
    - lib/features/editor/application/editor_ai_notifier.dart
    - lib/features/ai/presentation/provider_management_notifier.dart
    - lib/features/ai/presentation/provider_management_page.dart
    - lib/features/ai/application/provider_service.dart
    - test/features/ai/domain/ai_provider_test.dart
    - test/features/ai/infrastructure/openai_adapter_test.dart
decisions:
  - "D-06-04: Sentinel-based copyWith pattern for AIProvider -- allows distinguishing omitted from explicitly-null parameters without wrapper types"
  - "D-06-05: Parameter validation as pure Dart functions in separate library -- testable without widget framework"
  - "D-06-06: fetchModelList creates a fresh OpenAIClient per call (not cached) to avoid stale connections for one-shot queries"
metrics:
  duration: 8m
  completed: 2026-06-04
  tasks_completed: 2
  tasks_total: 2
  files_modified: 9
  files_created: 3
  tests_added: 34
---

# Phase 6 Plan 02: Model Parameters and Model List Summary

One-liner: Add nullable temperature/topP/maxTokens to AIProvider with sentinel-based copyWith, parameter validation, model list fetching with silent fallback, and provider form UI integration.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend AIProvider entity and OpenAIAdapter with nullable parameters | b1709b8 | ai_provider.dart, openai_adapter.dart, synthesis_notifier.dart, editor_ai_notifier.dart, ai_provider_test.dart, openai_adapter_test.dart |
| 2 | Model parameter UI, model list fetching, and provider form integration | 49bd353 | provider_service.dart, openai_adapter.dart, provider_management_notifier.dart, provider_management_page.dart, parameter_validation.dart, parameter_validation_test.dart, model_list_fetch_test.dart |

## What Was Built

### Task 1: Nullable Model Parameters on AIProvider and OpenAIAdapter
- Added `temperature` (double?), `topP` (double?), `maxTokens` (int?) to AIProvider entity
- Implemented sentinel-based `copyWith` pattern: passing `null` explicitly sets the field to null, omitting preserves the current value
- Extended `fromJson`/`toJson`, `operator ==`, and `hashCode` to include all three fields
- `fromJson` handles missing fields gracefully (defaults to null)
- `OpenAIAdapter.createStream` accepts optional `temperature`, `topP`, `maxTokens` and passes them directly to `ChatCompletionCreateRequest`
- `SynthesisNotifier` and `EditorAINotifier` now forward `provider.temperature`, `provider.topP`, `provider.maxTokens` to `createStream`
- 11 new entity tests + 2 new adapter tests

### Task 2: Parameter Validation, Model List Fetching, and Provider Form
- Created `parameter_validation.dart` library with `parseTemperature`, `parseTopP`, `parseMaxTokens` pure Dart functions
- Validation enforces: temperature 0.0-2.0, topP 0.0-1.0, maxTokens 1-128000, empty string = null, non-numeric = null
- Added `fetchModelList` to `OpenAIAdapter`: uses `client.models.list()` with 5-second timeout, returns empty list on any error (silent fallback per D-08)
- Added `fetchModels` to `ProviderManagementNotifier` with `availableModels` and `isFetchingModels` state fields
- Added `fetchModels` clears `availableModels` on failure (no error message shown per D-08)
- Provider form now has three labeled TextField rows (Temperature, Top-P, Max Tokens) with range hints in Chinese
- Model field converted to combo input with trailing refresh button to fetch model list
- Fetched models appear as a scrollable list of tappable items below the model field
- `ProviderService.createProvider` and `ProviderManagementNotifier.createProvider` accept nullable parameters
- Form's `_handleSave` parses parameters via validation functions and passes to create/update
- `_fillForEdit` populates parameter fields from existing provider; `_fillFromPreset` clears them
- 19 parameter validation tests + 4 model list fetch tests

## Deviations from Plan

None -- plan executed exactly as written.

## Deferred Issues

| Category | Item | File | Status |
|----------|------|------|--------|
| Pre-existing | synthesis_notifier_test.dart fails to compile | test/features/ai/presentation/synthesis_notifier_test.dart | Out of scope -- missing knowledge module files from phase 4/5 |
| Pre-existing | synthesis_notifier.dart line 242: AsyncValue.build() undefined | lib/features/ai/presentation/synthesis_notifier.dart | Out of scope -- pre-existing analyze error |

## Verification Results

- `flutter test test/features/ai/` -- 152 passed, 1 pre-existing failure (synthesis_notifier_test.dart, out of scope)
- `flutter analyze lib/features/ai/` -- 1 pre-existing error (synthesis_notifier.dart line 242, out of scope)
- All 63 plan-related tests pass (ai_provider_test + openai_adapter_test + parameter_validation_test + model_list_fetch_test)

## Self-Check: PASSED

All 12 created/modified files verified present. Both task commits (b1709b8, 49bd353) verified in git log.
