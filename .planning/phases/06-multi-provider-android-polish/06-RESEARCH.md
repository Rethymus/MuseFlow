# Phase 6: Multi-Provider + Android Polish - Research

**Researched:** 2026-06-04
**Domain:** AI provider management, model parameters, model list fetching, Flutter integration testing, responsive layout
**Confidence:** HIGH

## Summary

Phase 6 extends the existing AIProvider entity with three nullable model parameters (temperature, topP, maxTokens), adds Claude as a preset provider via Anthropic's OpenAI-compatible endpoint, introduces model list fetching using the openai_dart `client.models.list()` API, and ensures the new provider settings UI works on Android via adaptive layout and integration tests.

The implementation is straightforward because all infrastructure already exists: the `AIProvider` entity uses JSON-based Hive persistence (not TypeAdapters), `OpenAIAdapter` already handles any OpenAI-compatible API via configurable baseUrl, and `openai_dart` v6.0.0 already exposes `ModelsResource.list()` returning `ModelList` with typed `Model` objects. The Claude OpenAI-compatible endpoint at `https://api.anthropic.com/v1/` is officially supported by Anthropic with `temperature`, `topP`, and `maxTokens` all fully supported.

The primary complexity lies in threading the nullable parameters through the entire pipeline: entity -> repository -> service -> notifier -> UI -> adapter -> API request. Each layer needs careful handling of null-as-default semantics.

**Primary recommendation:** Extend the existing entity and adapter directly -- no new abstractions needed. The openai_dart `ChatCompletionCreateRequest` already accepts nullable `temperature`, `topP`, and `maxTokens` fields that are omitted from JSON when null, matching the null-as-default semantics exactly.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Claude is accessed exclusively through its OpenAI-compatible endpoint. No anthropic_sdk_dart dependency is introduced. Claude is added as a preset in `PresetProviders` with the correct baseUrl and model identifier.
- **D-02:** No adapter abstraction layer is created. The existing `OpenAIAdapter` handles all providers since everything uses the OpenAI protocol. `AiProviderType` enum gains a `claude` variant for preset identification, but the adapter layer is unchanged.
- **D-03:** Model parameters (temperature as `double?`, topP as `double?`, maxTokens as `int?`) are added directly to the `AIProvider` entity as nullable fields. No separate value object or settings box storage.
- **D-04:** Null parameter values mean "use the model's default" -- the API request only includes non-null parameters. This avoids overriding model-specific optimal defaults.
- **D-05:** Parameter UI uses TextField-based input rows (not sliders) for precision and simplicity. Each parameter gets one labeled row in the provider settings form. Input validation enforces numeric ranges.
- **D-06:** `AIProvider.copyWith`, `fromJson`, and `toJson` are extended to include the three new nullable fields. Hive adapter is regenerated.
- **D-07:** Custom model import supports both manual model ID entry and automatic model list fetching. The UI uses a combo input: a text field with an optional dropdown populated from the fetched list.
- **D-08:** Model list fetching uses the unified OpenAI-compatible GET /v1/models endpoint. If fetching fails (network error, endpoint not supported), the UI silently falls back to manual text input. No provider-specific fetching logic.
- **D-09:** The existing `custom` type in `AiProviderType` is used for user-added providers. No new provider types are needed beyond adding `claude` for the preset.
- **D-10:** Android scope covers Phase 6 new UI (provider settings with parameters, model list dropdown) plus core flow integration testing (launch, navigation, editor, capture, synthesis, settings).
- **D-11:** Android validation uses integration tests (integration_test package), not manual emulator testing. Core flows are verified programmatically.
- **D-12:** Existing responsive breakpoints in `AppConstants` (600px collapsed, 1000px extended) are the layout foundation. Phase 6 ensures new UI respects these breakpoints on phone-width screens.

### Claude's Discretion
- Exact Claude preset baseUrl and default model identifier.
- Exact parameter input field labels and validation error messages (in Chinese, consistent with existing UI tone).
- Exact integration test scenarios and coverage boundaries.
- Exact Hive adapter type IDs for new fields.
- Visual styling of model-list dropdown widget.

### Deferred Ideas (OUT OF SCOPE)
- Abstract adapter interface for future non-OpenAI providers (not needed now, defer until a genuinely incompatible API must be supported).
- Retrospective Android touch optimization for all Phase 1-5 pages (Phase 6 only covers new UI + core flow testing).
- Per-model parameters (separate from per-provider) -- current decision is per-provider only.
- Provider-specific model list fetching logic (Ollama /api/tags etc.) -- unified /v1/models only for MVP.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AI-02 | Claude API adapter (separate client due to different API structure) | Solved via D-01: Claude uses OpenAI-compatible endpoint at `https://api.anthropic.com/v1/`. No separate client needed. Existing `OpenAIAdapter` handles it. [VERIFIED: platform.claude.com/docs/en/api/openai-sdk] |
| MODL-03 | Per-provider model parameter config (Temperature, Top-P, Max Tokens) | Solved via D-03/D-04: Nullable fields on `AIProvider` entity, forwarded to `ChatCompletionCreateRequest` which already supports all three as nullable. [VERIFIED: openai_dart 6.0.0 source] |
| MODL-04 | Custom model import support (LocalAI, etc.) | Solved via D-07/D-08: `openai_dart` exposes `client.models.list()` returning typed `ModelList`. UI combo input with manual fallback. [VERIFIED: openai_dart ModelsResource source] |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Model parameters (temperature/topP/maxTokens) | Domain (entity) | Application (service) | Parameters are entity fields per D-03. Service forwards them to adapter. |
| Claude preset configuration | Infrastructure (PresetProviders) | -- | Static preset data. Only infra knows baseUrl/model. |
| Model list fetching | Infrastructure (OpenAIAdapter) | Application (new service method) | Adapter owns the OpenAI client. Service method wraps the call. |
| Parameter input validation | Presentation (UI form) | -- | UI validates user input before setting entity fields. |
| Null-as-default parameter forwarding | Infrastructure (OpenAIAdapter) | -- | Adapter constructs `ChatCompletionCreateRequest` -- only includes non-null params. |
| Android adaptive layout | Presentation (UI) | -- | Layout decisions are purely presentational per breakpoints. |
| Integration tests | Test tier | -- | integration_test package, separate from unit test infrastructure. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| openai_dart | ^6.0.0 | AI API client + model listing | Already in pubspec. `ChatCompletionCreateRequest` supports `temperature` (double?), `topP` (double?), `maxTokens` (int?) natively. `ModelsResource.list()` returns typed `ModelList`. [VERIFIED: source at .pub-cache] |
| flutter_riverpod | ^3.3.1 | State management | Project constraint. New notifier methods for model list fetching follow existing patterns. |
| hive_ce | ^2.19.3 | Local storage | AIProvider uses JSON-based Box<dynamic> persistence (not TypeAdapters). toJson/fromJson extended for new fields. |
| integration_test | (Flutter SDK) | Integration tests | Flutter SDK package for on-device testing. Added to dev_dependencies with sdk: flutter. [VERIFIED: Flutter SDK 3.44.0] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_test | (Flutter SDK) | Unit/widget tests | Existing test infrastructure. Tests for parameter validation, entity extension. |
| freezed | ^3.2.5 | Immutable data classes | If AIProvider is migrated to freezed in the future. Currently hand-written per existing pattern. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual TextField validation | flutter_form_builder | Overkill for 3 numeric fields. Manual validation simpler and matches existing form pattern. |
| Autocomplete dropdown widget | flutter_typeahead | Adds a dependency for one field. Custom combo input using TextField + PopupMenuButton is simpler. |

**Installation:**
```bash
# No new pub.dev packages needed. Only SDK package addition:
# Add to pubspec.yaml under dev_dependencies:
#   integration_test:
#     sdk: flutter
flutter pub get
```

**Version verification:**
```
openai_dart: 6.0.0 (verified in .pub-cache, pubspec.yaml)
flutter_riverpod: 3.3.1 (pubspec.yaml)
hive_ce: 2.19.3 (pubspec.yaml)
Flutter SDK: 3.44.0 (flutter --version)
Dart SDK: 3.12.0 (dart --version)
```

## Package Legitimacy Audit

> No new third-party packages are installed in this phase. All changes extend existing code. The only addition is `integration_test` which is a Flutter SDK package (not on pub.dev).

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| integration_test | Flutter SDK | N/A | N/A | flutter/flutter | N/A | SDK package -- approved |
| openai_dart | pub.dev | Existing | Existing | dl borderWidth/openai_dart | N/A | Already installed |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
User taps "Claude" preset card
       |
       v
PresetProviders.all (adds Claude with baseUrl: https://api.anthropic.com/v1/)
       |
       v
ProviderManagementPage form pre-fills fields
       |
       v
User edits params (temperature/topP/maxTokens) --> TextField rows validate ranges
       |
       v
User clicks "Fetch Models" button (or field focus)
       |
       v
ProviderManagementNotifier.fetchModels()
       |
       v
OpenAIAdapter.fetchModelList(apiKey, baseUrl)  <-- uses OpenAIClient.models.list()
       |
       v
ModelList.data (List<Model> with .id fields)
       |  (on failure: silent fallback, empty list)
       v
UI shows dropdown below TextField (user picks or types manually)
       |
       v
User clicks "Save" --> ProviderService.createProvider() --> Hive Box JSON + SecureStorage
       |
       v
Active provider selected --> SynthesisNotifier/EditorAINotifier reads provider
       |
       v
OpenAIAdapter.createStream() constructs ChatCompletionCreateRequest
  with temperature/topP/maxTokens only when non-null (D-04)
       |
       v
Streaming response flows back to UI
```

### Recommended Project Structure
```
lib/
├── features/ai/
│   ├── domain/
│   │   └── ai_provider.dart          # EXTEND: add claude type, temperature, topP, maxTokens
│   ├── infrastructure/
│   │   ├── openai_adapter.dart       # EXTEND: add fetchModelList(), forward params
│   │   ├── preset_providers.dart     # EXTEND: add Claude preset
│   │   └── provider_repository.dart  # UNCHANGED: already uses toJson/fromJson
│   ├── application/
│   │   └── provider_service.dart     # EXTEND: accept params in createProvider
│   └── presentation/
│       ├── provider_management_notifier.dart  # EXTEND: add fetchModels(), param state
│       ├── provider_management_page.dart       # EXTEND: param inputs, model dropdown, responsive
│       └── provider_card.dart                  # EXTEND: add claude icon/description
integration_test/                     # NEW: integration test directory
├── app_test.dart                     # Core flow integration tests
└── test_driver/
    └── integration_test.dart         # Test driver for integration tests
```

### Pattern 1: Nullable Parameter Forwarding (Null-as-Default)
**What:** When AIProvider has null parameter values, the API request omits them entirely, letting the model use its own defaults.
**When to use:** Every call site that constructs a `ChatCompletionCreateRequest` from provider data.
**Example:**
```dart
// Source: openai_dart 6.0.0 ChatCompletionCreateRequest source
// The request class already handles null correctly -- toJson() omits null fields:
//   if (temperature != null) 'temperature': temperature,
//   if (topP != null) 'top_p': topP,
//   if (maxTokens != null) 'max_tokens': maxTokens,

// OpenAIAdapter.createStream extension:
final request = ChatCompletionCreateRequest(
  model: model,
  messages: messages,
  // Only include when provider has non-null values (D-04)
  temperature: provider.temperature,  // nullable double
  topP: provider.topP,                // nullable double
  maxTokens: provider.maxTokens,      // nullable int
);
```

### Pattern 2: Model List Fetching with Silent Fallback
**What:** Fetch available models from GET /v1/models. On failure, silently return empty list and let user type manually.
**When to use:** When user opens model selection field or explicitly requests model list.
**Example:**
```dart
// Source: openai_dart 6.0.0 ModelsResource source
Future<List<String>> fetchModelList({
  required String apiKey,
  required String baseUrl,
}) async {
  try {
    final client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
    final modelList = await client.models.list();
    client.close();
    return modelList.data.map((m) => m.id).toList();
  } catch (_) {
    // D-08: silent fallback on any error
    return [];
  }
}
```

### Pattern 3: Android Responsive Layout for Provider Settings
**What:** Switch from fixed-width Row to LayoutBuilder-based adaptive layout using AppConstants breakpoints.
**When to use:** Provider management page when screen width < 600px (phone).
**Example:**
```dart
// Use LayoutBuilder to switch between desktop Row and mobile Column
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < AppConstants.sidebarCollapsedBreakpoint) {
      // Mobile: stacked layout, full-width panels
      return Column(children: [expandedList, form]);
    } else {
      // Desktop: side-by-side
      return Row(children: [sizedLeftPanel, expandedForm]);
    }
  },
)
```

### Anti-Patterns to Avoid
- **Passing SynthesisRequest.temperature to the API directly:** SynthesisRequest has its own temperature default (0.7). The provider's temperature should take precedence when set. SynthesisRequest.temperature is for per-synthesis overrides, not the same as provider-level defaults.
- **Creating a separate Hive box for model parameters:** D-03 explicitly puts parameters directly on AIProvider. The existing `ai_providers` box already stores JSON via toJson/fromJson -- no new box needed.
- **Registering a Hive TypeAdapter for AIProvider:** AIProvider is NOT stored as a typed Hive object. It uses `Box<dynamic>` with JSON maps. The D-06 reference to "Hive adapter regeneration" means updating toJson/fromJson, not creating a TypeAdapter.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Model list fetching | Custom HTTP GET to /v1/models with manual JSON parsing | `OpenAIClient.models.list()` returning typed `ModelList` | openai_dart already has `ModelsResource` with typed `Model` and `ModelList` classes. [VERIFIED: openai_dart source] |
| Parameter serialization in API request | Manual JSON construction with conditional fields | `ChatCompletionCreateRequest` with nullable fields | The request class `toJson()` already uses `if (temperature != null)` pattern. Null fields are automatically omitted. [VERIFIED: openai_dart source] |
| Claude API integration | anthropic_sdk_dart or custom HTTP adapter | Existing `OpenAIAdapter` with Claude's OpenAI-compatible endpoint | Anthropic officially supports OpenAI SDK compatibility at `https://api.anthropic.com/v1/`. [VERIFIED: platform.claude.com/docs/en/api/openai-sdk] |
| Combo dropdown widget | Custom overlay/positioned widget | TextField + PopupMenuButton or RawAutocomplete | Flutter Material components handle overlay positioning, focus, and dismissal. |

**Key insight:** This phase requires almost no new infrastructure. Every capability already exists in openai_dart or the existing codebase. The work is wiring existing capabilities together.

## Common Pitfalls

### Pitfall 1: Claude Temperature Range Mismatch
**What goes wrong:** Setting temperature > 1.0 for Claude API calls. Claude caps temperature at 1.0, while OpenAI allows up to 2.0.
**Why it happens:** Validation is applied uniformly across all provider types without considering provider-specific limits.
**How to avoid:** Either (a) validate temperature range per provider type (Claude: 0-1, others: 0-2), or (b) set a universal range of 0-1 since all providers support it. Recommendation: use 0-2 as the TextField validation range since Claude's OpenAI compatibility layer silently caps at 1.0 rather than erroring.
**Warning signs:** Claude requests with temperature > 1.0 produce unexpectedly deterministic output.

### Pitfall 2: Null vs Zero Confusion for Parameters
**What goes wrong:** User clears a parameter field and it saves as 0 instead of null, or a TextController empty string maps to 0 instead of null.
**Why it happens:** `double.tryParse('')` returns null correctly, but `int.tryParse('')` also returns null. The pitfall is in the UI -> entity mapping logic.
**How to avoid:** Explicitly handle empty TextField as null (not 0). Use `text.isEmpty ? null : double.tryParse(text)` pattern. Validate that parsed values are within range.
**Warning signs:** Provider sends temperature: 0 to API, making output completely deterministic.

### Pitfall 3: testConnection Uses Wrong Model for Claude
**What goes wrong:** `ProviderService.testConnection` hardcodes `gpt-4o-mini` as the model for test requests. This model does not exist on Claude's API.
**Why it happens:** The test connection method was written assuming OpenAI only.
**How to avoid:** Update `testConnection` to accept a model parameter, or use the provider's configured model for the test request instead of a hardcoded model name.
**Warning signs:** Claude preset shows "connection failed" even with correct API key and baseUrl.

### Pitfall 4: Model List Fetch Blocks UI
**What goes wrong:** Fetching model list with a slow or unreachable endpoint blocks the form, making the provider settings page feel frozen.
**Why it happens:** Model list fetch is awaited in the UI build method or in a synchronous callback.
**How to avoid:** Use a FutureProvider or async method with loading state. Show a small spinner in the model dropdown area while fetching. D-08 specifies silent fallback -- the fetch should timeout after ~5 seconds.
**Warning signs:** Provider settings page freezes for 10+ seconds when opening with a slow endpoint.

### Pitfall 5: RadioGroup Widget Availability
**What goes wrong:** `RadioGroup` is used in `provider_management_page.dart` but is not imported from any package. It appears to be a Flutter Material widget but may not exist in all Flutter versions.
**Why it happens:** The widget was introduced in recent Flutter versions and may not be widely known.
**How to avoid:** Verify RadioGroup availability in Flutter 3.44.0 before relying on it in new code. If it's a custom widget, ensure it's properly defined.
**Warning signs:** Compilation errors referencing RadioGroup.

### Pitfall 6: Forgetting to Update Equality/HashCode
**What goes wrong:** Adding temperature/topP/maxTokens to AIProvider but forgetting to include them in `operator ==` and `hashCode`.
**Why it happens:** The fields are nullable and easy to miss in the equality check.
**How to avoid:** Include all three new fields in `operator ==` comparison and `Object.hash` call. Existing pattern already includes all fields -- follow it.
**Warning signs:** Provider comparison fails after parameter update, causing stale state in UI.

## Code Examples

### Adding Parameters to AIProvider Entity
```dart
// Source: existing ai_provider.dart pattern
class AIProvider {
  final String id;
  final String name;
  final String baseUrl;
  final AiProviderType type;
  final String model;
  final bool isActive;
  final DateTime createdAt;
  // NEW: per-provider model parameters (D-03)
  final double? temperature;
  final double? topP;
  final int? maxTokens;

  const AIProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.type,
    required this.model,
    this.isActive = false,
    required this.createdAt,
    // NEW: nullable parameters
    this.temperature,
    this.topP,
    this.maxTokens,
  });
}
```

### Forwarding Parameters to API Request
```dart
// Source: openai_dart 6.0.0 ChatCompletionCreateRequest
// The request constructor accepts nullable types directly
Stream<String> createStream({
  required String apiKey,
  required String baseUrl,
  required String model,
  required List<ChatMessage> messages,
  // NEW: optional parameters (D-04: null = use model default)
  double? temperature,
  double? topP,
  int? maxTokens,
}) {
  _validateBaseUrl(baseUrl);
  final client = _getOrCreateClient(apiKey, baseUrl);

  final request = ChatCompletionCreateRequest(
    model: model,
    messages: messages,
    // Null fields are automatically omitted from JSON (verified in source)
    temperature: temperature,
    topP: topP,
    maxTokens: maxTokens,
  );

  return client.chat.completions.createStream(request)
      .map((event) => event.textDelta ?? '')
      .where((delta) => delta.isNotEmpty)
      .handleError((error) => throw classifyException(error));
}
```

### Claude Preset in PresetProviders
```dart
// Source: existing preset_providers.dart pattern
// Add Claude preset to the all getter:
AIProvider(
  id: 'preset-claude',
  name: 'Claude',
  baseUrl: 'https://api.anthropic.com/v1/',
  type: AiProviderType.claude,
  model: 'claude-sonnet-4-20250514',  // [VERIFIED: platform.claude.com docs]
  createdAt: now,
),
```

### Model List Fetching Method
```dart
// Source: openai_dart 6.0.0 ModelsResource.list()
Future<List<String>> fetchModelList({
  required String apiKey,
  required String baseUrl,
}) async {
  try {
    final client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
    final modelList = await client.models.list().timeout(
      const Duration(seconds: 5),
    );
    client.close();
    return modelList.data.map((m) => m.id).toList();
  } catch (_) {
    // D-08: silent fallback
    return [];
  }
}
```

### Parameter Input Validation Pattern
```dart
// Source: TextField-based input rows per D-05
double? _parseTemperature(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  final value = double.tryParse(text.trim());
  if (value == null) return null;
  if (value < 0 || value > 2) return null; // Invalid range
  return value;
}

int? _parseMaxTokens(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  final value = int.tryParse(text.trim());
  if (value == null) return null;
  if (value < 1 || value > 128000) return null;
  return value;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| anthropic_sdk_dart for Claude | Claude OpenAI-compatible endpoint | 2025 (Anthropic announcement) | D-01: No need for separate Claude client. Single OpenAIAdapter handles all. [VERIFIED: platform.claude.com] |
| Separate model list per provider | Unified GET /v1/models | openai_dart 6.0.0 | D-08: One method works for OpenAI, DeepSeek, Ollama, and Claude. [VERIFIED: openai_dart source] |
| Manual emulator testing | integration_test package | Flutter 2.x+ | D-11: Programmatic integration tests replace manual testing. |

**Deprecated/outdated:**
- `anthropic_sdk_dart` dependency in pubspec.yaml: Listed but not used for Claude access per D-01. Can be removed in a cleanup pass, but not blocking for this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Claude's default model for Chinese prose is `claude-sonnet-4-20250514`. The planner should confirm the optimal model ID. | Claude Preset | Wrong model ID causes poor quality for Chinese text |
| A2 | Claude's OpenAI-compatible endpoint supports GET /v1/models for model listing. Not explicitly documented in the compatibility page. | Model List Fetching | May need to fall back to hardcoded model list for Claude |
| A3 | `RadioGroup` widget is available in Flutter 3.44.0 Material library. Used without import in existing code. | Anti-Patterns | May need replacement widget |
| A4 | The `integration_test` package setup requires creating `integration_test/` directory and `test_driver/integration_test.dart`. Pattern may vary. | Integration Tests | Wrong setup pattern causes test runner failures |
| A5 | DeepSeek's API supports GET /v1/models endpoint. Not verified against DeepSeek docs. | Model List Fetching | DeepSeek model list fetch fails, user types manually (acceptable per D-08) |

**If this table is empty:** All claims in this research were verified or cited -- no user confirmation needed.

## Open Questions

1. **Claude model ID for Chinese prose**
   - What we know: Anthropic offers `claude-sonnet-4-20250514`, `claude-opus-4-20250514`, `claude-haiku-3-5-20241022`. Sonnet 4 is a good balance of quality and cost.
   - What's unclear: Which model is best for Chinese creative writing specifically.
   - Recommendation: Use `claude-sonnet-4-20250514` as default preset. Users can change it.

2. **Whether Claude's OpenAI-compatible endpoint supports GET /v1/models**
   - What we know: Anthropic has a native `GET /v1/models` endpoint documented at platform.claude.com. The OpenAI compatibility layer supports many endpoints.
   - What's unclear: Whether the OpenAI compatibility layer specifically proxies the models list endpoint.
   - Recommendation: Implement with silent fallback per D-08. If it works, great. If not, user types manually.

3. **Integration test Android emulator availability**
   - What we know: Android platform directory exists in the project. Flutter 3.44.0 supports integration tests.
   - What's unclear: Whether an Android emulator is available in the CI/dev environment for running integration tests.
   - Recommendation: Start with integration tests that can run on Windows desktop (integration_test works on desktop too). Android-specific tests can be validated manually or in CI with an emulator.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build, tests, integration tests | Yes | 3.44.0 | -- |
| Dart SDK | Compilation | Yes | 3.12.0 | -- |
| openai_dart | Model list fetching, chat completions | Yes | 6.0.0 | -- |
| hive_ce | Provider persistence | Yes | 2.19.3 | -- |
| Android emulator | Integration tests (Android) | Unknown | -- | Run integration tests on Windows desktop instead |
| build_runner | Code generation (if needed) | Yes | 2.15.0 | -- |

**Missing dependencies with no fallback:**
- None -- all core dependencies are available.

**Missing dependencies with fallback:**
- Android emulator: Integration tests can run on Windows desktop via `flutter test integration_test/`. Android-specific layout testing requires an emulator or physical device.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (unit/widget) + integration_test (integration) |
| Config file | none -- Flutter test convention |
| Quick run command | `flutter test test/features/ai/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AI-02 | Claude preset appears in PresetProviders.all with correct baseUrl and model | unit | `flutter test test/features/ai/infrastructure/preset_providers_test.dart` | Yes (extend) |
| AI-02 | AiProviderType.claude enum variant exists and serializes correctly | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | Yes (extend) |
| AI-02 | OpenAIAdapter works with Claude baseUrl and model | unit | `flutter test test/features/ai/infrastructure/openai_adapter_test.dart` | Yes (extend) |
| MODL-03 | AIProvider entity accepts nullable temperature, topP, maxTokens | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | Yes (extend) |
| MODL-03 | copyWith handles new nullable fields correctly (null preservation) | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | Yes (extend) |
| MODL-03 | fromJson/toJson roundtrip includes new fields | unit | `flutter test test/features/ai/domain/ai_provider_test.dart` | Yes (extend) |
| MODL-03 | OpenAIAdapter.createStream forwards non-null parameters to request | unit | `flutter test test/features/ai/infrastructure/openai_adapter_test.dart` | Yes (extend) |
| MODL-03 | Null parameters are omitted from API request | unit | `flutter test test/features/ai/infrastructure/openai_adapter_test.dart` | Yes (extend) |
| MODL-03 | Parameter input validation rejects out-of-range values | unit | NEW -- `test/features/ai/presentation/parameter_validation_test.dart` | Wave 0 |
| MODL-04 | Model list fetching returns model IDs | unit | NEW -- `test/features/ai/infrastructure/model_list_fetch_test.dart` | Wave 0 |
| MODL-04 | Model list fetch failure returns empty list (silent fallback) | unit | NEW -- `test/features/ai/infrastructure/model_list_fetch_test.dart` | Wave 0 |
| D-10 | Provider settings page renders on narrow screens without overflow | widget | NEW -- `test/features/ai/presentation/provider_management_responsive_test.dart` | Wave 0 |
| D-11 | Core flow integration test (launch, navigate, settings) | integration | NEW -- `integration_test/app_test.dart` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/ai/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green + integration tests pass on desktop

### Wave 0 Gaps
- [ ] `test/features/ai/presentation/parameter_validation_test.dart` -- covers MODL-03 validation
- [ ] `test/features/ai/infrastructure/model_list_fetch_test.dart` -- covers MODL-04 model list
- [ ] `test/features/ai/presentation/provider_management_responsive_test.dart` -- covers D-10 responsive layout
- [ ] `integration_test/app_test.dart` -- covers D-11 core flow integration tests
- [ ] `integration_test/test_driver/integration_test.dart` -- test driver for integration tests

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | API key stored in flutter_secure_storage (Windows Credential Manager / Android Keystore) |
| V3 Session Management | no | No user sessions -- local-only app |
| V4 Access Control | no | Single-user local app |
| V5 Input Validation | yes | Numeric parameter validation (range checks), URL validation |
| V6 Cryptography | yes | API key encryption via flutter_secure_storage |

### Known Threat Patterns for Flutter/Dart + AI APIs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API key exposure in logs | Information Disclosure | Never log API keys. Use debugPrint for UI only. |
| Malicious baseUrl injection | Tampering | HTTPS enforcement (existing _validateBaseUrl). Validate URL format before model list fetch. |
| Parameter injection | Tampering | Numeric range validation on all parameter inputs. Reject non-numeric values. |
| Model list response tampering | Spoofing | Model list is for user convenience only -- user can always override manually. No security impact from tampered list. |

## Sources

### Primary (HIGH confidence)
- openai_dart 6.0.0 source (`.pub-cache/hosted/pub.dev/openai_dart-6.0.0/`) -- ChatCompletionCreateRequest temperature/topP/maxTokens nullable fields, ModelsResource.list() API, ModelList/Model types
- Existing codebase -- AIProvider entity, OpenAIAdapter, PresetProviders, ProviderRepository, ProviderService, ProviderManagementNotifier, ProviderManagementPage
- Flutter SDK 3.44.0 -- RadioGroup widget, integration_test package

### Secondary (MEDIUM confidence)
- [platform.claude.com/docs/en/api/openai-sdk](https://platform.claude.com/docs/en/api/openai-sdk) -- Claude OpenAI-compatible endpoint: baseUrl `https://api.anthropic.com/v1/`, model names, temperature capped at 1.0, fully supports topP and maxTokens

### Tertiary (LOW confidence)
- Claude model ID `claude-sonnet-4-20250514` for Chinese prose -- assumed based on available models, not specifically tested for Chinese creative writing quality
- DeepSeek GET /v1/models endpoint support -- assumed compatible based on OpenAI-compatible API claim, not verified against DeepSeek docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all libraries already in project, verified against source code
- Architecture: HIGH - extending existing patterns, no new abstractions needed
- Pitfalls: HIGH - verified against openai_dart source and Claude API docs
- Claude endpoint: MEDIUM - verified against official docs, but model ID for Chinese prose is assumed

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (30 days -- stable libraries, Claude endpoint unlikely to change)
