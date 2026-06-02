---
phase: 02-ai-provider-capture-synthesis
plan: 01
subsystem: ai-provider
tags: [domain, infrastructure, application, presentation, tdd]
dependency_graph:
  requires: [SecureStorageService, Hive, openai_dart]
  provides: [AIProvider entity, ProviderRepository, ProviderService, ProviderManagementPage]
  affects: [settings_page, app_router, providers]
tech_stack:
  added: [openai_dart v6.0.0 (ChatCompletionCreateRequest, OpenAIClient.withApiKey, typed exceptions)]
  patterns: [manual immutable entity, sealed exception hierarchy, Notifier + FutureProvider composition]
key_files:
  created:
    - lib/features/ai/domain/ai_provider.dart
    - lib/features/ai/domain/ai_exception.dart
    - lib/features/ai/infrastructure/provider_repository.dart
    - lib/features/ai/infrastructure/preset_providers.dart
    - lib/features/ai/application/provider_service.dart
    - lib/features/ai/presentation/provider_card.dart
    - lib/features/ai/presentation/provider_management_notifier.dart
    - lib/features/ai/presentation/provider_management_page.dart
    - test/features/ai/domain/ai_provider_test.dart
    - test/features/ai/infrastructure/preset_providers_test.dart
    - test/features/ai/infrastructure/provider_repository_test.dart
    - test/features/ai/application/provider_service_test.dart
  modified:
    - lib/core/presentation/providers.dart
    - lib/features/settings/presentation/settings_page.dart
    - lib/app.dart
    - lib/shared/constants/app_constants.dart
decisions:
  - D-01: Left/right panel layout for provider management (list + form)
  - D-02: Preset cards pre-fill form fields; Ollama hides API Key input
  - D-03: API Key obscured with eye toggle; test connection with inline feedback
  - D-04: RadioGroup for active provider selection; advanced mode placeholder disabled
  - D-14: Chinese error messages in AIException sealed hierarchy
  - Used openai_dart v6 API (OpenAIClient.withApiKey, chat.completions.create, typed exceptions)
metrics:
  duration: 11m
  completed: "2026-06-02"
  tasks: 2
  files_created: 13
  files_modified: 4
  tests: 41
---

# Phase 2 Plan 1: AI Provider Management Summary

Manual immutable entity, Hive+SecureStorage persistence, provider service with testConnection, preset definitions, and settings sub-page with provider list + configuration form.

## What Was Built

**Task 1: Domain entity, repository, presets, and service (TDD)**
- `AIProvider` entity: manual immutable class with `id`, `name`, `baseUrl`, `type` (enum: openai/deepseek/ollama/custom), `model`, `isActive`, `createdAt`; `copyWith`, `fromJson`/`toJson`, `==`/`hashCode`
- `AIException` sealed hierarchy: `AIAuthException`, `AIRateLimitException`, `AINetworkException`, `AIStreamException` with Chinese `userMessage` getters
- `ProviderRepository`: Hive box `ai_providers` for provider JSON maps; CRUD + `SecureStorageService` for API keys; delete removes key from both stores
- `PresetProviders`: OpenAI (`https://api.openai.com/v1`, `gpt-4o-mini`), DeepSeek (`https://api.deepseek.com/v1`, `deepseek-chat`), Ollama (`http://localhost:11434/v1`, `llama3`); `requiresApiKey` returns false for Ollama
- `ProviderService`: `createProvider`, `updateProvider`, `deleteProvider`, `setActiveProvider` (one-at-a-time), `testConnection` (minimal chat completion via `openai_dart` v6 with exception classification), `getApiKey`, `updateApiKey`
- 41 tests across domain/infrastructure/application layers

**Task 2: Provider management settings UI and routing**
- `ProviderManagementPage`: `ConsumerStatefulWidget` with left panel (preset cards + saved provider list with `RadioGroup`) and right panel (config form with type selector, name/URL/model/API key fields)
- `ProviderCard`: preset display widget with icon and description
- `ProviderManagementNotifier`: Riverpod state management wrapping `ProviderService`
- Settings page updated: "AI 模型" navigation item with `Icons.smart_toy_outlined`
- GoRouter updated: `/settings/ai-providers` sub-route under settings branch
- `AppConstants.aiProviders` route constant
- API Key field with eye toggle (obscured/unobscured)
- Test Connection button with inline green checkmark / red error feedback
- Advanced mode toggle (disabled, "即将推出" subtitle)
- Flutter analyze: zero errors

## Decisions Made

1. **openai_dart v6 API**: Used `OpenAIClient.withApiKey(apiKey, baseUrl: url)` and `client.chat.completions.create(...)` with typed exceptions (`AuthenticationException`, `RateLimitException`, `ConnectionException`, `ApiException`) instead of the older v5-style API
2. **In-memory SecureStorage mock**: Tests use `_InMemorySecureStorage` implementing the `SecureStorageService` interface to avoid platform channel dependency in test environment
3. **RadioGroup migration**: Used Flutter 3.44 `RadioGroup<T>` ancestor widget instead of deprecated `Radio.groupValue`/`Radio.onChanged` pattern
4. **Notifier pattern**: `ProviderManagementNotifier` extracts service from `AsyncValue` via `asData?.value` to avoid `await` on non-Future `AsyncValue.whenData()`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed openai_dart v6 API mismatch**
- **Found during:** Task 1 implementation
- **Issue:** Plan referenced v5-style API (`OpenAIClient(apiKey: ..., baseUrl: Uri)`, `CreateChatCompletionRequest`, `ChatCompletionModel.modelString`)
- **Fix:** Updated to v6 API: `OpenAIClient.withApiKey(apiKey, baseUrl: string)`, `ChatCompletionCreateRequest`, `ChatMessage.user()`, typed exception hierarchy
- **Files modified:** `lib/features/ai/application/provider_service.dart`
- **Commit:** 9d0d9bc

**2. [Rule 1 - Bug] Fixed const expression error in ChatMessage**
- **Found during:** Task 1 test run
- **Issue:** `ChatMessage.user('Hi')` is not a const expression, cannot be used in `const ChatCompletionCreateRequest`
- **Fix:** Removed `const` from request construction
- **Files modified:** `lib/features/ai/application/provider_service.dart`
- **Commit:** 9d0d9bc

**3. [Rule 1 - Bug] Fixed AsyncValue.whenData() await warnings**
- **Found during:** Task 2 analyze
- **Issue:** `await serviceAsync.whenData(...)` -- `whenData` returns `AsyncValue`, not `Future`
- **Fix:** Refactored notifier to extract service via `asData?.value` helper method
- **Files modified:** `lib/features/ai/presentation/provider_management_notifier.dart`
- **Commit:** 2f4a310

**4. [Rule 2 - Security] Added updateApiKey public method to ProviderService**
- **Found during:** Task 2 implementation
- **Issue:** UI layer was accessing `service._secureStorage` (private) to update API keys during provider edit
- **Fix:** Added `updateApiKey(providerId, apiKey)` public method to ProviderService
- **Files modified:** `lib/features/ai/application/provider_service.dart`
- **Commit:** 2f4a310

## Test Results

- 41/41 tests passing
- Domain: 12 tests (AiProviderType + AIProvider entity)
- Infrastructure: 17 tests (PresetProviders 10 + ProviderRepository 7)
- Application: 12 tests (ProviderService CRUD 8 + AIException 4)

## Verification

- `flutter test test/features/ai/` -- 41 tests pass
- `flutter analyze` -- zero errors
- Settings page has "AI 模型" navigation item
- GoRouter configured with `/settings/ai-providers` sub-route

## Self-Check: PASSED

All 13 created files verified present. Both commits (9d0d9bc, 2f4a310) verified in git log.
