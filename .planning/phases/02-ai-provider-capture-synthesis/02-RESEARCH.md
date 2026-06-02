# Phase 2: AI Provider + Capture Synthesis - Research

**Researched:** 2026-06-02
**Domain:** AI provider integration, SSE streaming, prompt engineering, Chinese text token budgeting
**Confidence:** HIGH

## Summary

Phase 2 builds the core creative AI loop: configure an AI provider, select captured fragments, stream AI-synthesized paragraphs in real time, apply anti-AI-scent treatment, and insert the result into the editor. All dependencies are already installed in `pubspec.yaml` and verified compatible from Phase 0. The `openai_dart` 6.0.0 package provides a production-ready `OpenAIClient` with `createStream()` returning `Stream<ChatStreamEvent>` -- the exact streaming primitive needed. The `super_editor` 0.3.0-dev.51 package exposes `InsertPlainTextAtCaretRequest` for inserting synthesized text at cursor position. The existing codebase provides `SecureStorageService` (api key prefix pattern), `SettingsRepository` (encrypted Hive box), `CaptureNotifier` with `selectedIds`, and `selectedFragmentsProvider` -- all integration points this phase consumes.

The anti-AI-scent system is the product's soul. It requires a dual-layer defense: prompt engineering (persona injection + negative checklist) and post-processing (banned phrase replacement + structural pattern highlighting). Token budget management for Chinese text uses an approximate algorithm (1 Chinese character ~ 1.5-2 tokens for most models). The synthesis flow streams tokens into a right-side slide-out panel with typewriter effect, preserves partial work on interruption, and displays inline error messages with retry.

**Primary recommendation:** Use `openai_dart` `OpenAIClient.withApiKey(apiKey, baseUrl: ...)` as the single adapter for all OpenAI-compatible providers. Build a `PromptPipeline` middleware chain that assembles system prompt -> persona -> banned list -> user content. Use `InsertPlainTextAtCaretRequest` for editor insertion. No new packages needed.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Provider management lives inside the Settings page as a sub-page (设置 → AI 模型). Left panel: saved provider list. Right panel: configuration form.
- **D-02:** Preset providers shown as clickable cards (OpenAI, DeepSeek, Ollama). Clicking a preset pre-fills Base URL, user only needs to enter API Key. "自定义" card for fully manual configuration. Ollama preset has no Key field.
- **D-03:** API Key input uses password field (hidden by default) with eye icon toggle. "测试连接" button sends a minimal API request to validate the key. Immediate feedback on validity.
- **D-04:** Default mode: simple radio selection — one active provider at a time. Settings include "高阶模式" toggle that, when enabled, reveals per-scene provider assignment (e.g., synthesis uses DeepSeek, polish uses GPT-4). Progressive complexity exposure.
- **D-05:** Synthesis result displayed in a slide-out panel from the right side of the capture page. Does not navigate away from the capture workspace. Panel shows streaming text in real time with edit capability.
- **D-06:** Iteration support: "重新生成" button at bottom of panel, with an optional text field for追加指令 (e.g., "换个语气", "多加点描写"). Empty field = plain regeneration. Each generation is independent; user can compare results.
- **D-07:** Confirmed text is inserted at the editor's cursor position (not appended to end). Switches to editor page after insertion so user sees the result in context.
- **D-08:** Dual-layer anti-AI-scent: Prompt layer (first defense) + Post-processing layer (second defense). REQUIREMENTS AI-05 and AI-06 both implemented.
- **D-09:** Post-processing uses a built-in banned phrase list (seeded with common Chinese AI clichés) that users can edit in settings. Add/remove entries to match personal sensitivity.
- **D-10:** Post-processing replacement strategy: simple banned words are auto-replaced with synonyms (e.g., 然而→但是, 综上所述→删除). Complex structural patterns (套话句式) are highlighted for user to manually fix. Hybrid approach — don't over-automate, don't over-interrupt.
- **D-11:** Prompt layer combines persona injection ("你是一位经验丰富的中文小说作者") with negative checklist ("避免以下词汇和句式"). Persona sets the tone, checklist is the safety net. More token cost but higher compliance.
- **D-12:** Token budget auto-calculated based on model's context window: system prompt + persona + banned list + selected fragments + reserved output space. User sees nothing about tokens in normal flow.
- **D-13:** When fragments exceed budget, remove the last-selected fragments first (LIFO). Display "已移除 N 个碎片以保证质量" notice so user knows what was excluded.
- **D-14:** Error handling displays friendly messages directly in the synthesis panel (not dialogs/SnackBar): network failure → "网络连接失败", rate limit → "请求太快，请稍后再试", invalid key → "API Key 无效，请检查设置". Each error includes a "重试" button.
- **D-15:** Streaming display shows tokens in real time (typewriter effect). If stream breaks mid-generation, preserve received content and show "生成中断，可继续编辑或重试". Never lose partial work.

### Claude's Discretion
- Exact synthesis prompt template structure (system/persona/content ordering)
- Banned phrase initial seed list content (Chinese AI clichés)
- Auto-replacement synonym mapping table
- Token counting implementation for Chinese text (approximation algorithm)
- PromptPipeline middleware ordering and interface design
- Synthesis panel animation timing and dimensions
- Provider entity data model and Hive storage schema
- "高阶模式" toggle placement in settings UI
- Complex structural pattern detection rules for highlighting

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AI-01 | Unified AI adapter interface supporting OpenAI-compatible APIs (OpenAI, DeepSeek, Ollama) | `openai_dart` `OpenAIClient.withApiKey(apiKey, baseUrl:)` handles all three via custom baseUrl. Verified in source: `openai_client.dart` lines 161-181. |
| AI-03 | Streaming responses (SSE) with real-time text display | `client.chat.completions.createStream()` returns `Stream<ChatStreamEvent>` with `textDelta` accessor. Phase 0 test `sse_streaming_test.dart` validates this end-to-end. |
| AI-04 | PromptPipeline middleware system: system prompt → knowledge injection → skill enforcement → anti-AI-scent → user content | Custom middleware chain in application layer. `ChatCompletionCreateRequest.messages` accepts `List<ChatMessage>` with `SystemMessage`, `UserMessage` types. |
| AI-05 | Anti-AI-scent prompt engineering layer — avoid AI clichés | Persona injection + negative checklist as system messages. D-11 locked. |
| AI-06 | Anti-AI-scent post-processing — detect and replace remaining AI patterns | Banned phrase list with synonym replacement + structural highlighting. D-08/D-09/D-10 locked. |
| AI-07 | Token budget management — smart context window allocation | Approximate Chinese token counting (1 char ~ 1.5-2 tokens). LIFO fragment removal per D-12/D-13. |
| AI-08 | Rate limiting and error handling with graceful offline fallback | Inline panel error display per D-14. `connectivity_plus` for network detection. Stream interruption handling per D-15. |
| MODL-01 | Provider CRUD — add/edit/delete AI providers (name, API Key, Base URL) | Provider entities stored in encrypted Hive box. API keys via existing `SecureStorageService`. |
| MODL-02 | Preset providers for OpenAI, Claude, DeepSeek, Ollama | D-02 locked. Preset cards pre-fill baseUrl. Claude deferred to Phase 6. |
| CAPT-03 | AI synthesizes selected fragments into coherent story paragraph(s) | Reads from `selectedFragmentsProvider` in `capture_provider.dart`. PromptPipeline assembles synthesis prompt. |
| CAPT-04 | Synthesized text is editable before entering main editor | D-05 slide-out panel with editable text. D-07 inserts at cursor via `InsertPlainTextAtCaretRequest`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| AI provider entity/model | Domain | — | Provider is a core domain concept, pure Dart |
| AI provider CRUD/storage | Infrastructure | — | Hive persistence + SecureStorage for keys |
| PromptPipeline assembly | Application | — | Use-case orchestration of middleware chain |
| AI adapter (HTTP streaming) | Infrastructure | — | External API communication via `openai_dart` |
| Anti-AI-scent prompt layer | Application | — | Part of PromptPipeline middleware |
| Anti-AI-scent post-processing | Application | — | Text transformation after AI response |
| Token budget calculation | Application | — | Business logic for context window management |
| Synthesis state management | Presentation (Riverpod) | Application | AsyncNotifier manages streaming state |
| Provider management UI | Presentation | — | Settings sub-page with forms |
| Synthesis panel UI | Presentation | — | Slide-out panel on capture page |
| Editor text insertion | Presentation | — | `InsertPlainTextAtCaretRequest` on super_editor |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| openai_dart | 6.0.0 | OpenAI-compatible API client with streaming | Project constraint (CLAUDE.md). `OpenAIClient.withApiKey(apiKey, baseUrl:)` supports custom base URLs for DeepSeek/Ollama. `createStream()` returns `Stream<ChatStreamEvent>` with SSE parsing built-in. Verified in pub cache source. |
| flutter_riverpod | 3.3.1 | State management | Project constraint. `AsyncNotifier` pattern for streaming state. Already in use throughout codebase. |
| super_editor | 0.3.0-dev.51 | Rich text editor | Phase 0 benchmark winner. `InsertPlainTextAtCaretRequest` verified in source at `text.dart:2070`. |
| hive_ce | 2.19.3 | Local NoSQL storage | Store provider configs, banned phrase list, settings. |
| flutter_secure_storage | 10.3.1 | Encrypted API key storage | Already used by `SecureStorageService` with `api_key_` prefix pattern. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| connectivity_plus | 7.0.0 | Network status detection | Guard API calls when offline. Pre-check before synthesis attempt. |
| uuid | 4.5.1 | Generate unique provider IDs | Provider entity primary keys. |
| go_router | 17.2.3 | Route to settings sub-page | Add `/settings/ai-providers` sub-route. |

### No New Packages Needed
All Phase 2 dependencies are already installed in `pubspec.yaml`. No additional packages required. [VERIFIED: pubspec.yaml and pubspec.lock checked]

## Package Legitimacy Audit

> slopcheck checks PyPI (Python registry) but these are Dart packages on pub.dev. Cross-ecosystem check produces false SLOP results. Legitimacy verified via pub.dev pub cache and pubspec.lock resolution.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| openai_dart | pub.dev | ~2 yrs | High | github.com/davidmigloz/langchain_dart | N/A (Dart) | Approved — verified in pub cache |
| anthropic_sdk_dart | pub.dev | ~2 yrs | High | github.com/davidmigloz/langchain_dart | N/A (Dart) | Approved — verified in pub cache (Phase 6 only) |
| ollama_dart | pub.dev | ~1 yr | Medium | github.com/davidmigloz/langchain_dart | N/A (Dart) | Approved — verified in pub cache |
| flutter_riverpod | pub.dev | ~4 yrs | Very High | github.com/rrousselGit/riverpod | N/A (Dart) | Approved — verified in pub cache |
| super_editor | pub.dev | ~3 yrs | High | github.com/superlistapp/super_editor | N/A (Dart) | Approved — verified in pub cache |
| hive_ce | pub.dev | ~2 yrs | High | github.com/IO-Design-LLC/hive_ce | N/A (Dart) | Approved — verified in pub cache |
| flutter_secure_storage | pub.dev | ~5 yrs | Very High | github.com/mogol/flutter_secure_storage | N/A (Dart) | Approved — verified in pub cache |
| connectivity_plus | pub.dev | ~4 yrs | Very High | github.com/fluttercommunity/plus_plugins | N/A (Dart) | Approved — verified in pub cache |
| go_router | pub.dev | ~3 yrs | Very High | github.com/flutter/packages | N/A (Dart) | Approved — verified in pub cache |

**Packages removed due to slopcheck [SLOP] verdict:** None (slopcheck ran against wrong registry — all packages verified on pub.dev)
**Packages flagged as suspicious [SUS]:** None

*All packages verified via pubspec.lock resolution and pub cache presence on disk. No new packages introduced in this phase.*

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ ProviderList │  │ ProviderForm │  │ SynthesisPanel   │   │
│  │ (Settings)   │  │ (Settings)   │  │ (Capture slide)  │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘   │
│         │                 │                    │             │
│  ┌──────┴─────────────────┴──────┐   ┌────────┴─────────┐   │
│  │  ProviderNotifier (Riverpod)  │   │ SynthesisNotifier│   │
│  │  - CRUD provider configs      │   │ - Stream state   │   │
│  │  - Active provider selection  │   │ - Error display  │   │
│  └──────────────┬────────────────┘   └────────┬─────────┘   │
└─────────────────┼──────────────────────────────┼─────────────┘
                  │                              │
┌─────────────────┼──────────────────────────────┼─────────────┐
│          Application Layer                     │             │
│                 │                              │             │
│  ┌──────────────┴──────────┐   ┌───────────────┴──────────┐  │
│  │  ProviderService        │   │  SynthesisUseCase        │  │
│  │  - Create/Update/Delete │   │  - Select fragments      │  │
│  │  - Validate connection  │   │  - Run PromptPipeline    │  │
│  └──────────────┬──────────┘   │  - Manage token budget   │  │
│                 │              │  - Apply post-processing  │  │
│  ┌──────────────┴──────────┐   └───────────────┬──────────┘  │
│  │  PromptPipeline         │                   │             │
│  │  1. SystemPrompt        │   ┌───────────────┴──────────┐  │
│  │  2. PersonaInjection    │   │  AntiAIScentProcessor   │  │
│  │  3. BannedListChecklist │   │  - Replace banned words  │  │
│  │  4. UserContent         │   │  - Highlight patterns    │  │
│  │  (→ ChatMessage list)   │   └──────────────────────────┘  │
│  └─────────────────────────┘                                 │
└──────────────────────────────────────────────────────────────┘
                  │
┌─────────────────┼────────────────────────────────────────────┐
│       Infrastructure Layer                                   │
│                 │                                            │
│  ┌──────────────┴──────────┐   ┌─────────────────────────┐  │
│  │  OpenAIAdapter          │   │  ProviderRepository     │  │
│  │  - createStream()       │   │  - Hive CRUD            │  │
│  │  - Error classification │   │  - SecureStorage keys   │  │
│  │  - AbortTrigger support │   └─────────────────────────┘  │
│  └─────────────────────────┘                                │
│                                                              │
│  ┌─────────────────────────┐   ┌─────────────────────────┐  │
│  │  openai_dart SDK        │   │  SecureStorageService   │  │
│  │  OpenAIClient           │   │  (api_key_<providerId>) │  │
│  │  .withApiKey(baseUrl:)  │   └─────────────────────────┘  │
│  └─────────────────────────┘                                │
└──────────────────────────────────────────────────────────────┘
```

Data flow for synthesis:
1. User selects fragments in Capture page -> `selectedFragmentsProvider` holds selection
2. User clicks "AI 整理" -> `SynthesisNotifier` reads selected fragments
3. `SynthesisUseCase` calls `PromptPipeline` to build `ChatMessage` list
4. `TokenBudgetCalculator` checks if fragments fit, trims LIFO if needed
5. `OpenAIAdapter.createStream()` starts SSE connection
6. Tokens stream back -> `SynthesisNotifier` updates panel text in real time
7. Stream completes -> `AntiAIScentProcessor` runs post-processing
8. User edits in panel -> clicks "确认插入"
9. Text inserted at editor cursor via `InsertPlainTextAtCaretRequest`

### Recommended Project Structure
```
lib/features/ai/
├── domain/
│   ├── ai_provider.dart              # Provider entity (name, baseUrl, isActive, type)
│   ├── synthesis_request.dart        # Value object: fragments + instructions + config
│   └── ai_exception.dart             # Typed AI errors (network, rateLimit, auth)
├── application/
│   ├── provider_service.dart         # CRUD orchestration for providers
│   ├── synthesis_use_case.dart       # Fragment-to-paragraph synthesis flow
│   ├── prompt_pipeline.dart          # Middleware chain for prompt assembly
│   ├── prompt_middlewares/
│   │   ├── system_prompt_middleware.dart      # Base system instructions
│   │   ├── persona_injection_middleware.dart  # "你是经验丰富的小说作者"
│   │   ├── banned_list_middleware.dart        # Negative checklist injection
│   │   └── user_content_middleware.dart       # Fragment content assembly
│   ├── anti_ai_scent_processor.dart  # Post-processing: banned words + highlighting
│   └── token_budget_calculator.dart  # Chinese text token estimation
├── infrastructure/
│   ├── openai_adapter.dart           # OpenAI-compatible API adapter (streaming)
│   ├── provider_repository.dart      # Hive-backed provider persistence
│   └── preset_providers.dart         # OpenAI/DeepSeek/Ollama preset configs
└── presentation/
    ├── provider_management_page.dart # Settings sub-page: provider list + form
    ├── provider_card.dart            # Preset/custom provider card widget
    ├── synthesis_panel.dart          # Slide-out panel on capture page
    ├── synthesis_notifier.dart       # Riverpod AsyncNotifier for stream state
    └── banned_phrase_settings.dart   # Editable banned phrase list in settings
```

### Pattern 1: OpenAI-Compatible Adapter (Single Client for All Providers)
**What:** One `OpenAIAdapter` class wraps `OpenAIClient`, configured per-provider with custom `baseUrl`.
**When to use:** All OpenAI-compatible providers (OpenAI, DeepSeek, Ollama, any custom endpoint).
**Example:**
```dart
// Source: Verified from openai_dart source at pub cache
// openai_client.dart lines 161-181
import 'package:openai_dart/openai_dart.dart';

class OpenAIAdapter {
  OpenAIClient? _client;
  String? _lastProviderId;

  /// Creates or reuses client for the given provider config.
  /// DeepSeek: baseUrl = 'https://api.deepseek.com/v1'
  /// Ollama: baseUrl = 'http://localhost:11434/v1', apiKey = 'ollama' (dummy)
  /// OpenAI: baseUrl = 'https://api.openai.com/v1'
  Stream<ChatStreamEvent> createStream(
    String apiKey,
    String baseUrl,
    List<ChatMessage> messages, {
    String model = 'gpt-4o-mini',
    int? maxTokens,
    double? temperature,
    Future<void>? abortTrigger,
  }) {
    _client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
    return _client!.chat.completions.createStream(
      ChatCompletionCreateRequest(
        model: model,
        messages: messages,
        maxTokens: maxTokens,
        temperature: temperature,
      ),
      abortTrigger: abortTrigger,
    );
  }

  void dispose() {
    _client?.close();
  }
}
```

### Pattern 2: PromptPipeline Middleware Chain
**What:** Ordered list of middleware functions that each transform a `PromptContext`, producing the final `List<ChatMessage>`.
**When to use:** Every AI synthesis call.
**Example:**
```dart
// Claude's discretion — interface design
class PromptContext {
  final List<Fragment> fragments;
  final String? additionalInstruction;
  final List<String> bannedPhrases;
  final List<ChatMessage> messages;
  final int tokenBudget;

  PromptContext({
    required this.fragments,
    this.additionalInstruction,
    required this.bannedPhrases,
    List<ChatMessage>? messages,
    required this.tokenBudget,
  }) : messages = messages ?? [];
}

abstract class PromptMiddleware {
  PromptContext apply(PromptContext context);
}

class PromptPipeline {
  final List<PromptMiddleware> _middlewares;

  PromptPipeline(this._middlewares);

  List<ChatMessage> build(PromptContext context) {
    var current = context;
    for (final middleware in _middlewares) {
      current = middleware.apply(current);
    }
    return current.messages;
  }
}
```

### Pattern 3: Synthesis AsyncNotifier with Stream Handling
**What:** Riverpod `AsyncNotifier` that manages synthesis state, subscribes to SSE stream, and handles errors/partial content.
**When to use:** Synthesis panel UI consumes this.
**Example:**
```dart
// Based on existing CaptureNotifier pattern in capture_provider.dart
class SynthesisState {
  final String accumulatedText;
  final bool isStreaming;
  final bool isEditing;
  final String? error;
  final String? excludedFragmentsNotice; // D-13: "已移除 N 个碎片"

  const SynthesisState({
    this.accumulatedText = '',
    this.isStreaming = false,
    this.isEditing = false,
    this.error,
    this.excludedFragmentsNotice,
  });

  SynthesisState copyWith({...}) => SynthesisState(...);
}
```

### Pattern 4: Editor Insertion at Cursor
**What:** Insert synthesized text at the editor's current cursor position using super_editor's request system.
**When to use:** After user confirms edited synthesis text.
**Example:**
```dart
// Source: Verified from super_editor source at text.dart:2070
// InsertPlainTextAtCaretRequest handles:
// - Collapsed selection: inserts at caret
// - Expanded selection: deletes selection, then inserts
// - Non-text node: creates text node automatically
editor.execute([
  InsertPlainTextAtCaretRequest(synthesizedText),
]);
```

### Anti-Patterns to Avoid
- **Creating separate adapter classes for each provider:** OpenAI, DeepSeek, and Ollama all use the same OpenAI-compatible API. One `OpenAIAdapter` with configurable `baseUrl` handles all three. Separate adapters = unnecessary complexity.
- **Storing API keys in Hive:** API keys MUST go through `SecureStorageService` (platform credential manager). Hive is not encrypted by default for arbitrary values. The existing `SecureStorageService.saveApiKey(providerId, key)` pattern is the correct approach.
- **Using `StreamController` to wrap openai_dart stream:** The `createStream()` method already returns a Dart `Stream<ChatStreamEvent>`. Wrapping it in another `StreamController` adds complexity for no benefit. Use `await for` or `listen()` directly.
- **Displaying AI errors in SnackBar/dialog:** D-14 explicitly requires errors in the synthesis panel inline. Never use dialogs or SnackBar for AI errors.
- **Running post-processing during streaming:** Anti-AI-scent post-processing runs AFTER the full stream completes. Running it on partial text would produce incorrect replacements (e.g., matching half a banned phrase).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SSE stream parsing | Custom SSE parser | `openai_dart` `createStream()` | Handles SSE protocol, JSON parsing, error recovery, abort triggers. Verified in Phase 0 test. |
| API key encryption | Custom encryption | `SecureStorageService` (flutter_secure_storage) | Uses Windows Credential Manager / Android Keystore. Already implemented. |
| Provider config persistence | Custom file format | Hive encrypted box via `SettingsRepository` | Already initialized, already encrypted. Add provider keys to the existing box. |
| Chinese token counting | Exact tokenization | Approximate algorithm | Tiktoken and similar tokenizers require native code or WASM. For budget estimation, 1 Chinese char ~ 1.5-2 tokens is sufficient (GPT-4/o tokenization). Label as approximate. |
| HTTP client for AI | Raw `http` calls | `openai_dart` `OpenAIClient` | Handles retries, timeouts, SSE framing, error parsing. |

**Key insight:** `openai_dart` is a complete client, not just a request builder. Do not wrap HTTP calls manually -- use `OpenAIClient.withApiKey()` and `chat.completions.createStream()`.

## Common Pitfalls

### Pitfall 1: Stream Error Handling Loses Partial Content
**What goes wrong:** If the SSE stream fails mid-generation (network drop, API error), received tokens are discarded.
**Why it happens:** The `await for` loop throws an exception, and the accumulated buffer is in a local variable that gets destroyed.
**How to avoid:** Use try-catch around the stream loop. On error, preserve the accumulated buffer. D-15: "生成中断，可继续编辑或重试". Never lose partial work.
**Warning signs:** Synthesis panel shows empty text after a stream interruption.

### Pitfall 2: Ollama "No API Key" Configuration
**What goes wrong:** Ollama does not require an API key (local server). Sending an empty/null key to `OpenAIClient.withApiKey()` may cause errors.
**Why it happens:** `OpenAIClient.withApiKey()` expects a non-null String. Ollama accepts any dummy value for the API key header.
**How to avoid:** Use a placeholder value like `'ollama'` or `'local'` for Ollama's API key. The `baseUrl` (`http://localhost:11434/v1`) is what matters. D-02: "Ollama preset has no Key field" -- but the adapter still needs a non-null string internally.
**Warning signs:** Ollama connection test fails with auth error despite correct base URL.

### Pitfall 3: Token Budget Underestimation for Chinese
**What goes wrong:** Chinese text tokenization is not 1:1 character-to-token. GPT-4/o uses ~1.5-2 tokens per Chinese character. Underestimating leads to context overflow errors.
**Why it happens:** Developers assume 1 char = 1 token (true for English-like text, false for Chinese).
**How to avoid:** Use a conservative multiplier (1.8x) for Chinese token estimation. Add a 10% safety margin. D-12: auto-calculate with reserved output space.
**Warning signs:** API returns "context length exceeded" error despite budget check passing.

### Pitfall 4: Provider Client Lifecycle (Memory Leak)
**What goes wrong:** Creating a new `OpenAIClient` for each synthesis request without closing the old one.
**Why it happens:** `OpenAIClient` wraps an `http.Client` that holds TCP connections. Not closing leaks sockets.
**How to avoid:** Reuse the client instance for the same provider. Close on provider switch or dispose. The adapter should cache the current client and only recreate when provider changes.
**Warning signs:** Memory usage grows with each synthesis request. TCP connection exhaustion.

### Pitfall 5: Post-Processing Replaces Inside Words
**What goes wrong:** Banned phrase "然而" is replaced in a word like "忽然然而" (unlikely but possible with compound patterns).
**Why it happens:** Simple `String.replaceAll()` does not respect word boundaries. Chinese has no spaces, so word boundaries are ambiguous.
**How to avoid:** Use regex with appropriate boundary matching. For Chinese, check that the character before and after the match is a punctuation mark, sentence start/end, or whitespace. Post-processing is Claude's discretion -- the planner should flag boundary-aware matching.
**Warning signs:** Legitimate Chinese text gets garbled by over-aggressive replacement.

### Pitfall 6: Editor Not Focused When Inserting
**What goes wrong:** After synthesis, switching to editor page and calling `InsertPlainTextAtCaretRequest` fails because the editor has no selection/cursor.
**Why it happens:** D-07 says "switches to editor page after insertion." But if the editor page hasn't been rendered yet, the `Editor` object may not have a valid composer selection.
**How to avoid:** Insert text BEFORE switching pages (while editor is still mounted in the widget tree via StatefulShellRoute.indexedStack). Then navigate. The `StatefulShellRoute.indexedStack` pattern preserves all branch widgets, so the Editor widget is always mounted.
**Warning signs:** Text silently fails to appear in editor after synthesis confirmation.

## Code Examples

### Creating an OpenAI-Compatible Client with Custom Base URL
```dart
// Source: Verified from openai_dart source — openai_client.dart:161-181
import 'package:openai_dart/openai_dart.dart';

// OpenAI
final openaiClient = OpenAIClient.withApiKey(
  'sk-...',
  baseUrl: 'https://api.openai.com/v1',
);

// DeepSeek
final deepseekClient = OpenAIClient.withApiKey(
  'sk-...',
  baseUrl: 'https://api.deepseek.com/v1',  // DeepSeek's OpenAI-compatible endpoint
);

// Ollama (local)
final ollamaClient = OpenAIClient.withApiKey(
  'ollama',  // Dummy key — Ollama ignores auth
  baseUrl: 'http://localhost:11434/v1',
);
```

### Streaming with Error Recovery and Partial Content Preservation
```dart
// Source: Verified from openai_dart source — chat_resource.dart:200-233, chat_stream_event.dart:107-110
import 'package:openai_dart/openai_dart.dart';

Future<void> synthesizeWithRecovery(
  OpenAIClient client,
  List<ChatMessage> messages,
  void Function(String token) onToken,
  void Function(String fullText, String? error) onComplete,
) async {
  final buffer = StringBuffer();

  try {
    final stream = client.chat.completions.createStream(
      ChatCompletionCreateRequest(
        model: 'gpt-4o-mini',
        messages: messages,
        maxTokens: 1000,
      ),
    );

    await for (final event in stream) {
      // textDelta is a convenience getter: event.choices?.firstOrNull?.delta.content
      final delta = event.textDelta;
      if (delta != null && delta.isNotEmpty) {
        buffer.write(delta);
        onToken(delta);
      }
    }

    onComplete(buffer.toString(), null);
  } catch (e) {
    // D-15: preserve partial content on stream interruption
    // Never lose partial work
    onComplete(buffer.toString(), _classifyError(e));
  }
}

String _classifyError(Object error) {
  if (error.toString().contains('401') || error.toString().contains('Unauthorized')) {
    return 'API Key 无效，请检查设置';
  } else if (error.toString().contains('429')) {
    return '请求太快，请稍后再试';
  } else if (error.toString().contains('SocketException') || error.toString().contains('Connection')) {
    return '网络连接失败';
  }
  return '生成中断，可继续编辑或重试';
}
```

### Inserting Synthesized Text at Cursor in super_editor
```dart
// Source: Verified from super_editor source — text.dart:2070-2148
// InsertPlainTextAtCaretRequest handles:
// - Collapsed selection: inserts at caret position
// - Expanded selection: deletes selected content first, then inserts
// - Non-text caret position: creates a new ParagraphNode automatically
import 'package:super_editor/super_editor.dart';

void insertSynthesizedText(Editor editor, String text) {
  editor.execute([
    InsertPlainTextAtCaretRequest(text),
  ]);
}

// Note: InsertPlainTextAtCaretRequest does NOT insert new nodes for newlines.
// If text contains '\n', those become newline characters in the current node,
// which may not render as paragraph breaks. For multi-paragraph insertion,
// use InsertNodeAfterNodeRequest with separate ParagraphNodes.
```

### ChatMessage Construction for PromptPipeline
```dart
// Source: Verified from openai_dart source — chat_message.dart:31-99
import 'package:openai_dart/openai_dart.dart';

// System message (persona + instructions)
final systemMessage = ChatMessage.system(
  '你是一位经验丰富的中文小说作者。你的任务是将碎片化的灵感整理成流畅的故事段落。'
  '\n\n避免以下词汇和句式：'
  '- 总之、然而、综上所述、值得注意的是'
  '- 首先其次最后、一方面另一方面'
  '- 毫无疑问、不可否认'
  '- 用"总的来说"作为段落结尾'
  '\n写作风格：自然、有温度、像人写的。',
);

// User message (fragment content)
final userMessage = ChatMessage.user(
  '请将以下灵感碎片整理成一个连贯的故事段落：\n\n'
  '1. 剑光划破夜空\n'
  '2. 老者站在悬崖边，白发随风飘扬\n'
  '3. 少年握紧拳头，眼中闪过决然',
);

final messages = [systemMessage, userMessage];
```

### Hive Storage Schema for Provider Config
```dart
// Follows existing pattern from settings_repository.dart and fragment_repository.dart

// Provider entity stored as JSON map in Hive box 'ai_providers'
// Key: provider.id (UUID)
// Value: {
//   'id': 'uuid',
//   'name': 'DeepSeek',
//   'baseUrl': 'https://api.deepseek.com/v1',
//   'type': 'deepseek', // openai | deepseek | ollama | custom
//   'model': 'deepseek-chat',
//   'isActive': true,
//   'createdAt': '2026-06-02T...',
// }
//
// API Key stored separately via SecureStorageService:
// await secureStorage.saveApiKey(provider.id, apiKey);
// Note: API key is NOT stored in Hive — only in platform secure storage.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| openai_dart `OpenAI()` class | `OpenAIClient()` with `OpenAIConfig` | openai_dart 5.x→6.x | Client API changed. Use `OpenAIClient.withApiKey(apiKey, baseUrl:)` constructor. |
| super_editor `DocumentEditor` class | `Editor` with `execute()` method | super_editor 0.2.x→0.3.x | API simplified. `createDefaultDocumentEditor()` still works but `Editor` is the current abstraction. |
| Hive 2.x (original) | hive_ce (community edition) | 2024 | Original Hive stale. hive_ce adds adapter generation, isolate support, WASM. |
| Manual SSE parsing | `openai_dart` built-in SSE | openai_dart 2.x+ | No need to parse Server-Sent Events manually. `createStream()` handles it. |

**Deprecated/outdated:**
- `OpenAI()` constructor (pre-6.x): Use `OpenAIClient.withApiKey()` instead.
- `DocumentEditor` (pre-0.3.x): Use `Editor` and `createDefaultDocumentEditor()`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Chinese token ratio is ~1.5-2 tokens per character for GPT-4/o models | Token Budget | Context overflow if ratio is higher for specific models |
| A2 | Ollama accepts dummy API key 'ollama' via OpenAI-compatible endpoint | Adapter Pattern | Ollama connection fails if auth header is rejected |
| A3 | `InsertPlainTextAtCaretRequest` works while editor is in background branch of StatefulShellRoute | Editor Insertion | Text insertion fails if editor widget is not active |
| A4 | DeepSeek's OpenAI-compatible endpoint is `https://api.deepseek.com/v1` | Preset Providers | Wrong base URL causes connection failure |
| A5 | Newline characters in synthesized text will render correctly via `InsertPlainTextAtCaretRequest` | Editor Insertion | Multi-paragraph insertion may need node-level operations |
| A6 | Anti-AI-scent banned phrase list can be effectively seeded from domain knowledge (not empirically validated) | Anti-AI-Scent | Banned list misses actual AI patterns or over-corrects |

## Open Questions

1. **DeepSeek model name for synthesis**
   - What we know: DeepSeek uses `deepseek-chat` as the default model identifier. OpenAI uses `gpt-4o-mini` or similar.
   - What's unclear: Whether to expose model selection in Phase 2 or hardcode per preset.
   - Recommendation: Hardcode a default model per preset (OpenAI: `gpt-4o-mini`, DeepSeek: `deepseek-chat`, Ollama: `llama3`). Per-provider model config is Phase 6 (MODL-03).

2. **Synthesis panel dimensions and behavior on narrow screens**
   - What we know: D-05 says "slide-out panel from right side." Width and animation are Claude's discretion.
   - What's unclear: How it behaves on Android (narrow screens).
   - Recommendation: Desktop: fixed ~400px panel. Android: bottom sheet or full-screen overlay. Android optimization is Phase 6 but the panel should not break on small screens.

3. **Token budget reserved output space**
   - What we know: D-12 says "reserved output space." We need to reserve tokens for the generated response.
   - What's unclear: How many tokens to reserve. A typical synthesis of 3-5 fragments should produce ~500-1000 Chinese characters (~1000-2000 tokens).
   - Recommendation: Reserve 2000 tokens for output by default. Adjustable if needed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build + run | Available | 3.44.0 (stable) | — |
| Dart SDK | Compile | Available | 3.12.0 | — |
| openai_dart | AI streaming | Available | 6.0.0 (pub cache) | — |
| super_editor | Editor insertion | Available | 0.3.0-dev.51 (pub cache) | — |
| flutter_secure_storage | API key storage | Available | 10.3.1 (pub cache) | — |
| hive_ce | Provider persistence | Available | 2.19.3 (pub cache) | — |
| connectivity_plus | Network detection | Available | 7.0.0+ (pub cache) | Skip network check if unavailable |
| Network access | AI API calls | Available | — (OpenAI reachable) | — |
| OpenAI/DeepSeek API key | Integration test | Needs user input | — | Skip live tests, use mock |

**Missing dependencies with no fallback:**
- None — all required packages are installed and resolved.

**Missing dependencies with fallback:**
- API key for integration testing: skip live tests, use mock server (existing pattern from `test/streaming/test_api_server.dart`).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none — standard Flutter test setup |
| Quick run command | `flutter test test/features/ai/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AI-01 | OpenAI adapter connects with custom baseUrl | unit | `flutter test test/features/ai/adapter/openai_adapter_test.dart` | Wave 0 |
| AI-03 | SSE streaming produces tokens incrementally | unit | `flutter test test/features/ai/adapter/streaming_test.dart` | Wave 0 |
| AI-04 | PromptPipeline assembles correct message list | unit | `flutter test test/features/ai/application/prompt_pipeline_test.dart` | Wave 0 |
| AI-05 | Anti-AI-scent prompt layer injects persona + checklist | unit | `flutter test test/features/ai/application/anti_ai_scent_prompt_test.dart` | Wave 0 |
| AI-06 | Post-processing replaces banned phrases and highlights patterns | unit | `flutter test test/features/ai/application/anti_ai_scent_post_test.dart` | Wave 0 |
| AI-07 | Token budget calculator estimates and trims correctly | unit | `flutter test test/features/ai/application/token_budget_test.dart` | Wave 0 |
| AI-08 | Error classification maps to user-friendly messages | unit | `flutter test test/features/ai/adapter/error_handling_test.dart` | Wave 0 |
| MODL-01 | Provider CRUD persists to Hive and SecureStorage | unit | `flutter test test/features/ai/infrastructure/provider_repository_test.dart` | Wave 0 |
| MODL-02 | Preset providers have correct baseUrl and defaults | unit | `flutter test test/features/ai/infrastructure/preset_providers_test.dart` | Wave 0 |
| CAPT-03 | Synthesis use case assembles fragments into prompt | unit | `flutter test test/features/ai/application/synthesis_use_case_test.dart` | Wave 0 |
| CAPT-04 | Synthesis panel state manages streaming, editing, errors | unit | `flutter test test/features/ai/presentation/synthesis_notifier_test.dart` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/ai/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/ai/` directory — all test files needed
- [ ] `test/features/ai/test_helpers/` — mock OpenAIClient, mock SecureStorage
- [ ] Existing `test/streaming/` tests provide SSE + editor insertion patterns to reuse

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | API key validation via "测试连接" button |
| V3 Session Management | no | No user sessions (local-only app) |
| V4 Access Control | no | Single-user local app |
| V5 Input Validation | yes | Provider name, baseUrl, API key format validation |
| V6 Cryptography | yes | `flutter_secure_storage` for API keys (Windows Credential Manager / Android Keystore) |

### Known Threat Patterns for Flutter + AI APIs

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API key exposure in logs/debug output | Information Disclosure | Never log API keys. Use `debugPrint` for non-sensitive data only. Filter keys from error messages. |
| API key stored in plaintext | Tampering | `SecureStorageService` uses platform secure storage. Never store keys in Hive plaintext. |
| Man-in-the-middle on API calls | Tampering | `openai_dart` uses HTTPS by default. Enforce HTTPS for all provider base URLs. |
| Prompt injection via user fragments | Elevation of Privilege | Fragments are user content. System prompt is immutable. User content is clearly separated in the message structure. |
| Stream hijacking/response injection | Spoofing | `openai_dart` handles SSE parsing with JSON validation. Responses are displayed as text, not executed. |

## Sources

### Primary (HIGH confidence)
- `openai_dart` 6.0.0 source code (pub cache) — `OpenAIClient`, `ChatCompletionsResource.createStream()`, `ChatStreamEvent`, `ChatMessage` API verified by reading source files
- `super_editor` 0.3.0-dev.51 source code (pub cache) — `InsertPlainTextAtCaretRequest`, `InsertTextRequest` verified by reading `text.dart:2070-2148`
- Project source code — all existing files in `lib/` read and analyzed for integration points
- `pubspec.yaml` + `pubspec.lock` — all dependency versions verified as resolved

### Secondary (MEDIUM confidence)
- Phase 0 test `test/streaming/sse_streaming_test.dart` — SSE streaming pattern validated with real API
- Phase 0 test `test/streaming/sse_editor_insertion_test.dart` — batch insertion pattern validated with super_editor
- Phase 1 code patterns — `CaptureNotifier`, `FragmentService`, `SecureStorageService` as established patterns

### Tertiary (LOW confidence)
- Chinese token estimation (1 char ~ 1.5-2 tokens) — based on general knowledge of GPT-4/o tokenization, not empirically measured in this project [ASSUMED]
- DeepSeek base URL `https://api.deepseek.com/v1` — commonly documented but not verified via live API call in this session [ASSUMED]
- Anti-AI-scent banned phrase effectiveness — domain knowledge, not empirically validated against AI detection tools [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages installed, verified in pub cache, API surfaces inspected in source code
- Architecture: HIGH — four-layer architecture established in Phase 0/1, integration points identified in existing code
- Pitfalls: HIGH — streaming error recovery, Ollama auth, Chinese tokenization issues identified from Phase 0 testing and source code analysis
- Anti-AI-scent effectiveness: MEDIUM — dual-layer approach is sound but actual effectiveness against AI detectors is untested

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (30 days — stable stack, no fast-moving dependencies)
