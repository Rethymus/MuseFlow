# Phase 6: Multi-Provider + Android Polish - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 6 rounds out multi-provider support and ensures Android usability. It delivers: Claude as an OpenAI-compatible preset, per-provider model parameters (Temperature/Top-P/Max Tokens), custom model import with optional model-list fetching, and Android adaptive layout with integration tests for core flows.

**In scope:**
- Claude preset via OpenAI-compatible endpoint (no anthropic_sdk_dart).
- Model parameters (temperature, topP, maxTokens) as nullable fields on AIProvider entity.
- Model list fetching via unified GET /v1/models endpoint with manual-input fallback.
- Android layout adaptation for Phase 6 new UI + core flow integration tests.
- Provider settings UI updated to include parameter inputs and model-list dropdown.

**Out of scope:**
- anthropic_sdk_dart integration or dedicated Claude API adapter.
- Abstract adapter interface / adapter pattern refactoring (not needed — single OpenAI protocol).
- Full retrospective Android touch optimization of all Phase 1-5 pages.
- New AI capabilities, new features beyond provider management and Android polish.

</domain>

<decisions>
## Implementation Decisions

### Claude Provider Access
- **D-01:** Claude is accessed exclusively through its OpenAI-compatible endpoint. No anthropic_sdk_dart dependency is introduced. Claude is added as a preset in `PresetProviders` with the correct baseUrl and model identifier.
- **D-02:** No adapter abstraction layer is created. The existing `OpenAIAdapter` handles all providers since everything uses the OpenAI protocol. `AiProviderType` enum gains a `claude` variant for preset identification, but the adapter layer is unchanged.

### Model Parameters
- **D-03:** Model parameters (temperature as `double?`, topP as `double?`, maxTokens as `int?`) are added directly to the `AIProvider` entity as nullable fields. No separate value object or settings box storage.
- **D-04:** Null parameter values mean "use the model's default" — the API request only includes non-null parameters. This avoids overriding model-specific optimal defaults.
- **D-05:** Parameter UI uses TextField-based input rows (not sliders) for precision and simplicity. Each parameter gets one labeled row in the provider settings form. Input validation enforces numeric ranges.
- **D-06:** `AIProvider.copyWith`, `fromJson`, and `toJson` are extended to include the three new nullable fields. Hive adapter is regenerated.

### Custom Model Import
- **D-07:** Custom model import supports both manual model ID entry and automatic model list fetching. The UI uses a combo input: a text field with an optional dropdown populated from the fetched list.
- **D-08:** Model list fetching uses the unified OpenAI-compatible GET /v1/models endpoint. If fetching fails (network error, endpoint not supported), the UI silently falls back to manual text input. No provider-specific fetching logic.
- **D-09:** The existing `custom` type in `AiProviderType` is used for user-added providers. No new provider types are needed beyond adding `claude` for the preset.

### Android Adaptation
- **D-10:** Android scope covers Phase 6 new UI (provider settings with parameters, model list dropdown) plus core flow integration testing (launch, navigation, editor, capture, synthesis, settings).
- **D-11:** Android validation uses integration tests (integration_test package), not manual emulator testing. Core flows are verified programmatically.
- **D-12:** Existing responsive breakpoints in `AppConstants` (600px collapsed, 1000px extended) are the layout foundation. Phase 6 ensures new UI respects these breakpoints on phone-width screens.

### Verification Closure Decisions
- **D-13:** Phase 6 verification should use **core automated coverage** as the pass gate: domain/entity serialization, preset provider config, adapter parameter forwarding, parameter validation, model-list fetching/fallback, and provider-management responsive widget behavior must be covered by green automated tests. Full device/emulator and real API execution are not required for the automated pass gate in the current Linux/WSL environment.
- **D-14:** Android layout verification may use widget-level narrow-width tests as the local substitute for physical Android execution. Specifically, provider management must be verified around the 600px breakpoint with no overflow and with a usable list/form switching flow. Physical Android touch testing remains manual UAT, not an automated blocker.
- **D-15:** Real Claude API streaming with live credentials is manual UAT, not an automated release gate. Automated tests should verify Claude preset identity, HTTPS OpenAI-compatible endpoint configuration, model ID propagation, and request parameter forwarding without requiring secrets or network calls.
- **D-16:** `/gsd:validate-phase 6` is allowed to fix test blockers and add missing tests required to make `06-VALIDATION.md` compliant. The validation pass may update tests, small testability seams, and narrow correctness fixes needed for tests to compile and run; it should not reopen Phase 6 product scope or add new provider features.

### Claude's Discretion
- Exact Claude preset baseUrl and default model identifier.
- Exact parameter input field labels and validation error messages (in Chinese, consistent with existing UI tone).
- Exact integration test scenarios and coverage boundaries.
- Exact Hive adapter type IDs for new fields.
- Visual styling of model-list dropdown widget.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Definition
- `.planning/PROJECT.md` — Core value, local-first constraints, provider management scope.
- `.planning/REQUIREMENTS.md` — Phase 6 requirement IDs AI-02, MODL-03, MODL-04.
- `.planning/ROADMAP.md` §Phase 6 — Phase goal, success criteria, risks, three planned work items.
- `.planning/STATE.md` — Current project position and accumulated decisions (D-15 through D-20).
- `CLAUDE.md` — Project stack, coding standards, Riverpod/Clean Architecture/testing expectations.

### Prior Phase Context
- `.planning/phases/02-ai-provider-capture-synthesis/` — Provider entity design, OpenAIAdapter, PromptPipeline, anti-AI-scent. Phase 6 extends entities created here.
- `.planning/phases/05-story-structure-format-export/05-CONTEXT.md` — Most recent context, D-19/D-20 for Android simplified layouts and empty states.

### Existing Code (Critical)
- `lib/features/ai/domain/ai_provider.dart` — AIProvider entity to extend with parameter fields and AiProviderType enum to add `claude`.
- `lib/features/ai/infrastructure/openai_adapter.dart` — OpenAIAdapter, unchanged but referenced for understanding streaming flow.
- `lib/features/ai/infrastructure/preset_providers.dart` — PresetProviders to add Claude preset.
- `lib/features/ai/infrastructure/provider_repository.dart` — Hive persistence, adapter regeneration needed.
- `lib/features/ai/application/provider_service.dart` — ProviderService, testConnection may need adjustment for Claude endpoint.
- `lib/features/ai/presentation/provider_management_notifier.dart` — ProviderManagementNotifier, may need model-list fetching method.
- `lib/core/presentation/providers.dart` — Central provider exports, may need new providers for model list.
- `lib/shared/constants/app_constants.dart` — Responsive breakpoints for Android layout work.
- `.planning/phases/06-multi-provider-android-polish/06-VALIDATION.md` — Current validation artifact is draft/non-compliant and must be updated by `/gsd:validate-phase 6` using D-13 through D-16.
- `.planning/v1.0-MILESTONE-AUDIT.md` — Milestone audit identifies Phase 6 validation and missing verification as critical blockers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **AIProvider entity and copyWith:** Directly extensible with nullable parameter fields. toJson/fromJson pattern established.
- **OpenAIAdapter:** Already handles all OpenAI-compatible providers via configurable baseUrl. No changes needed for Claude.
- **PresetProviders:** Simple static list pattern. Adding a Claude preset is a 10-line addition.
- **ProviderManagementNotifier and ProviderManagementState:** Established pattern for provider settings UI. Can be extended with model-list fetching and parameter state.
- **AppConstants breakpoints:** 600px/1000px breakpoints already define adaptive layout thresholds.

### Established Patterns
- Domain entities are immutable with copyWith. New nullable fields follow this pattern.
- Hive adapters use generated TypeAdapters. Field additions require `dart run build_runner`.
- Provider settings UI follows a form-based master-detail pattern (list left, form right on desktop; stacked on mobile).
- Error handling uses AIException hierarchy (AIAuthException, AIRateLimitException, AINetworkException).
- Riverpod Notifier pattern for page-level state management.

### Integration Points
- `AIProvider` entity changes ripple to: repository (Hive adapter), provider service, management notifier, settings UI, and all providers that read AIProvider.
- `PromptPipeline.createStream` and `SynthesisNotifier` read provider parameters — need to pass temperature/topP/maxTokens to the API request when non-null.
- `OpenAIAdapter.createStream` currently takes a fixed `ChatCompletionCreateRequest` without temperature/topP/maxTokens. Needs to accept and forward optional parameters.
- Model-list fetching is a new capability: needs a service method, a provider, and UI integration into the model input field.
- Android integration tests require `integration_test` package setup and test app configuration.
- Phase 6 validation currently has recorded test blockers from `06-03-SUMMARY.md`; validation closure should first make the automated provider-management responsive and model/parameter tests compile in the current tree, then classify device/API-dependent checks as manual UAT.

</code_context>

<specifics>
## Specific Ideas

- The Claude preset should use the OpenAI-compatible endpoint format and a reasonable default model for Chinese prose (researcher should verify the current recommended model ID).
- Parameter inputs should feel lightweight — not a full "model configuration page". Just three extra fields in the existing provider form.
- Model list dropdown should feel like autocomplete: type to filter, click to select, or ignore the dropdown and type manually.
- Integration tests should cover the critical user path: launch → navigate to settings → see providers → add a provider with parameters → verify it's active.
- For local verification, prefer deterministic widget/unit tests over live services: mock/fake provider data, verify request construction, and treat real Claude credentials and Android touch behavior as manual UAT rows.

</specifics>

<deferred>
## Deferred Ideas

- Abstract adapter interface for future non-OpenAI providers (not needed now, defer until a genuinely incompatible API must be supported).
- Retrospective Android touch optimization for all Phase 1-5 pages (Phase 6 only covers new UI + core flow testing).
- Per-model parameters (separate from per-provider) — current decision is per-provider only.
- Provider-specific model list fetching logic (Ollama /api/tags etc.) — unified /v1/models only for MVP.

</deferred>

---

*Phase: 6-Multi-Provider + Android Polish*
*Context gathered: 2026-06-04*
