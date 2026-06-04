# Phase 6: Multi-Provider + Android Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 06-Multi-Provider + Android Polish
**Areas discussed:** Claude Adapter Architecture, Model Parameters Storage & UI, Custom Model Import, Android Adaptation Scope

---

## Claude Adapter Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Abstract unified interface | Define AIAdapter abstract class, OpenAIAdapter and ClaudeAdapter implement it. Clean but requires refactoring. | |
| Route by type | if/switch at call site: type==claude → ClaudeAdapter, else → OpenAIAdapter. Simple but repetitive. | |
| Minimal change | Only ClaudeAdapter, no abstraction. Two adapters in parallel. Fast but accumulates if/else. | |

**User's choice:** None of the above — user decided to use only OpenAI-compatible protocol. No anthropic_sdk_dart, no adapter abstraction needed. Claude accessed via OpenAI-compatible endpoint.

**Follow-up — Claude接入方式:**

| Option | Description | Selected |
|--------|-------------|----------|
| Claude OpenAI-compatible preset | Add Claude as a preset in PresetProviders with correct baseUrl/model. No anthropic_sdk_dart. | ✓ |
| No Claude preset at all | Users configure Claude manually via custom type. | |

**Notes:** Claude's Chinese capability is inferior to other OpenAI-protocol providers, so dedicated adapter is unnecessary. Simplifies Phase 6 significantly — plan 06-01 scope reduces from "Claude API adapter" to "Claude preset addition".

---

## Model Parameters Storage & UI

### Parameter Storage Location

| Option | Description | Selected |
|--------|-------------|----------|
| Add to AIProvider entity | Nullable fields (temperature, topP, maxTokens) directly on entity. Simple, parameters follow provider. | ✓ |
| Independent value object | Separate ModelParameters linked by provider ID. Cleaner but over-engineered for MVP. | |
| Settings box storage | Key-value in Hive settings box. Flexible but messy for queries/migration. | |

### Default Value Handling

| Option | Description | Selected |
|--------|-------------|----------|
| nullable + null=model default | Null means "use model default", only non-null params sent to API. Flexible, avoids overriding model defaults. | ✓ |
| Fixed defaults | temperature=0.7, topP=1.0, maxTokens=2048. Always sent. Simple but may not suit all models. | |
| Per-type defaults | Different defaults per provider type. Medium complexity. | |

### Parameter UI Style

| Option | Description | Selected |
|--------|-------------|----------|
| TextField inputs | One labeled row per parameter with numeric validation. Clean and precise. | ✓ |
| Slider + input hybrid | Slider for temperature/topP, input for maxTokens. More visual but Flutter Slider precision is tricky. | |

**Notes:** Parameters are per-provider (not per-model). UI should feel lightweight — three extra fields in the existing provider form.

---

## Custom Model Import

### Import UX

| Option | Description | Selected |
|--------|-------------|----------|
| Manual config only | User fills name + baseUrl + model ID + apiKey. Current flow with clearer UI. | |
| Auto-fetch model list | Pull available models from endpoint, user picks from list. | |
| Both coexist | Manual input + optional model list fetching. User can use either. | ✓ |

**User's choice:** Both manual input and auto-fetch should coexist.

### Model List Fetching Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Unified /v1/models endpoint | Standard OpenAI-compatible endpoint. Most services support it. Fallback to manual on failure. | ✓ |
| Per-type fetching | Different endpoints per provider (Ollama /api/tags, etc.). More complete but more maintenance. | |

### List + Manual Coexistence

| Option | Description | Selected |
|--------|-------------|----------|
| Dropdown + manual input | Text field with optional dropdown from fetched list. Fetch failure → manual only. | ✓ |
| Force list selection | Must pick from list. Fetch failure = error. More rigid. | |

**Notes:** Model list fetching is an optional helper — never blocks manual input. UI should feel like autocomplete.

---

## Android Adaptation Scope

### Optimization Breadth

| Option | Description | Selected |
|--------|-------------|----------|
| New features + core flow verification | Phase 6 UI touch adaptation + test core flows (launch, nav, editor, capture, synthesis, settings). Fix existing pages only if broken. | ✓ |
| Full retrospective optimization | Touch-optimize all Phase 1-5 pages. Large scope, could consume entire phase. | |
| New features only | Only ensure Phase 6 UI works on phone. Don't test existing features. | |

### Android Testing Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Emulator manual verification | Manual testing on Android emulator. Quick but not repeatable. | |
| Integration test coverage | integration_test package for core Android flows. Repeatable and verifiable. | ✓ |

**Notes:** Existing responsive breakpoints (600px/1000px) are the layout foundation. Integration tests should cover: launch → navigate → settings → add provider → verify active.

---

## Claude's Discretion

- Exact Claude preset baseUrl and default model identifier
- Exact parameter input field labels and validation error messages (Chinese)
- Exact integration test scenarios and coverage boundaries
- Exact Hive adapter type IDs for new fields
- Visual styling of model-list dropdown widget

## Deferred Ideas

- Abstract adapter interface for future non-OpenAI providers
- Retrospective Android touch optimization for all Phase 1-5 pages
- Per-model parameters (separate from per-provider)
- Provider-specific model list fetching logic (Ollama /api/tags etc.)
