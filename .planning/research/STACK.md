# Technology Stack

**Project:** MuseFlow -- AI-assisted creative writing tool (Flutter Windows + Android)
**Researched:** 2026-05-31
**Flutter version (local):** 3.44.0 stable / Dart 3.5.4

---

## Overview

MuseFlow is a local-first, cross-platform creative writing assistant. The stack is chosen to serve three hard requirements that most Flutter apps do not face simultaneously:

1. **Rich text editing with a custom floating toolbar** -- the editor is the product
2. **Multi-provider LLM integration** -- OpenAI, Claude, DeepSeek, Ollama through one adapter layer
3. **Offline-first structured storage** -- knowledge base, story structure, manuscripts all live locally

Every choice below is verified against current pub.dev versions and official docs.

---

## Core Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Flutter SDK | 3.44.0 (stable) | Cross-platform UI framework | Project constraint (PROJECT.md). Windows desktop + Android. IME support via TSF on Windows is mature since 3.x. |
| Dart SDK | 3.5.4 | Language | Ships with Flutter. Required for pattern matching, sealed classes, records used throughout. |
| flutter_riverpod | ^3.3.1 | State management | Project constraint (PROJECT.md). Code-gen based providers with `@riverpod` annotation. AsyncNotifier for LLM streaming. |
| riverpod_annotation | ^4.0.3 | Provider annotations | Pairs with riverpod_generator. Compile-time safe provider definitions. |
| riverpod_generator | ^4.0.3 | Code generation for providers | Eliminates boilerplate. Generates `_$NotifierName` base classes. |
| freezed | ^3.2.5 | Immutable data classes | Union types for Result/Either, copyWith generation, JSON serialization. Critical for domain entities. |
| freezed_annotation | ^3.1.0 | Freezed annotations | Runtime companion to freezed code gen. |
| build_runner | latest | Code generation runner | Required by riverpod_generator and freezed. Run with `dart run build_runner watch -d`. |

**Confidence:** HIGH -- verified via pub.dev API and Context7 docs.

---

## Editor Stack

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **appflowy_editor** | ^6.2.0 | Rich text editor | **The clear winner for this project.** First-class `FloatingToolbar` widget that appears on text selection -- exactly the "browser extension style" toolbar MuseFlow needs. Block-based document model. Built by the AppFlowy team for production use. Desktop-optimized `EditorStyle.desktop()`. Custom block components for future story-structure overlays. |

### Why appflowy_editor over flutter_quill

| Criterion | appflowy_editor | flutter_quill |
|-----------|----------------|---------------|
| Floating toolbar | **Built-in `FloatingToolbar` widget** -- production-ready, configurable items | No native floating toolbar; requires custom wrapping |
| Custom block components | First-class API with `BlockComponentBuilder` | Custom embeds via Delta, more complex |
| Desktop support | `EditorStyle.desktop()` with proper padding, cursor, selection | Works but less desktop-tuned |
| Document model | Block-based JSON (structured, queryable for story tracking) | Delta-based (flat operation log, harder to query) |
| Community | Backed by AppFlowy (large OSS project) | Community-maintained, slower releases |
| Toolbar customizability | Item-based: pick from `paragraphItem`, `headingItems`, `markdownFormatItems`, add custom items | Button-based: assemble individual toolbar buttons |

The floating toolbar is a deal-maker. PROJECT.md specifies a "browser extension style" popup menu on text selection. appflowy_editor's `FloatingToolbar` does exactly this with zero custom code:

```dart
FloatingToolbar(
  editorState: editorState,
  editorScrollController: scrollController,
  items: [
    ...markdownFormatItems,  // bold, italic, underline, strikethrough
    linkItem,
    // Add custom AI items here
  ],
  child: AppFlowyEditor(
    editorState: editorState,
    editorScrollController: scrollController,
  ),
)
```

Custom AI actions (tone rewrite, polish, free edit) can be added as custom toolbar items in the floating menu.

**Confidence:** HIGH -- verified via Context7 docs (full code examples for FloatingToolbar), pub.dev version 6.2.0.

---

## AI Integration

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **openai_dart** | ^6.0.0 | OpenAI API client + OpenAI-compatible providers | Type-safe Dart client. Supports custom `baseUrl` -- covers DeepSeek and Ollama (both expose OpenAI-compatible endpoints). Streaming via `createChatCompletionStream()`. |
| **anthropic_sdk_dart** | ^4.0.0 | Claude API client | Dedicated Dart SDK for Anthropic's Messages API with streaming and tool use. Claude has a non-OpenAI-compatible API, so a separate client is necessary. |
| **ollama_dart** | ^2.2.0 | Ollama local LLM client | Dedicated client for Ollama's REST API. Provides model listing, chat, generation. Use alongside openai_dart for Ollama (Ollama supports both its native API and OpenAI-compatible endpoints; ollama_dart gives richer model management). |

### Multi-Model Adapter Architecture

DeepSeek and Ollama expose OpenAI-compatible endpoints. This means `openai_dart` covers three providers with one package:

```dart
// OpenAI (default)
final openaiClient = OpenAIClient(
  apiKey: 'sk-...',
);

// DeepSeek (OpenAI-compatible)
final deepseekClient = OpenAIClient(
  baseUrl: 'https://api.deepseek.com/v1',
  apiKey: 'dsk-...',
);

// Ollama (OpenAI-compatible)
final ollamaClient = OpenAIClient(
  baseUrl: 'http://localhost:11434/v1',
);
```

Claude requires its own client due to a different API structure. Build a unified `LLMProvider` abstract interface:

```dart
abstract class LLMProvider {
  Stream<String> chatStream(List<ChatMessage> messages, {LLMConfig? config});
  Future<String> chat(List<ChatMessage> messages, {LLMConfig? config});
}
```

With four implementations: `OpenAIAdapter`, `DeepSeekAdapter`, `OllamaAdapter` (all wrapping openai_dart with different baseUrls), and `ClaudeAdapter` (wrapping anthropic_sdk_dart).

**Confidence:** HIGH -- verified via pub.dev API (versions confirmed), Context7 docs (openai_dart baseUrl configuration examples with Groq, Azure, TogetherAI, FastChat showing the pattern).

---

## Local Storage

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **hive_ce** | ^2.19.3 | Primary local NoSQL database | Community Edition of Hive. Actively maintained (original Hive 2.2.3 hasn't had meaningful updates). Supports encryption (AES-256 CBC), isolate-safe via `IsolatedHive`, automatic TypeAdapter generation with `@GenerateAdapters`, DevTools inspector. |
| **hive_ce_flutter** | ^2.3.4 | Flutter integration for Hive CE | Provides `Hive.initFlutter()` with proper path resolution on all platforms including Windows. |
| **flutter_secure_storage** | ^10.3.1 | Encrypted API key storage | Uses platform-specific secure storage (Windows Credential Manager via `flutter_secure_storage_windows`). For API keys that must never be in plaintext. |

### Why hive_ce over original Hive

| Criterion | hive_ce (2.19.3) | hive (2.2.3) |
|-----------|-------------------|---------------|
| Last updated | Active, frequent releases | Stale, minimal updates |
| TypeAdapter generation | `@GenerateAdapters` annotation, auto-registers | Manual or hive_generator (less maintained) |
| Isolate support | `IsolatedHive` built-in | Limited |
| Flutter Web WASM | Supported | Not supported |
| DevTools inspector | Built-in | None |
| Encryption | AES-256 CBC, same as original | AES-256 CBC |

PROJECT.md specifies Hive as the storage engine. hive_ce is the spiritual continuation that stays API-compatible while adding features. Migration path is clean -- same `Hive.box()`, `box.put()`, `box.get()` API.

### Storage Design

```
Boxes:
  - manuscripts     -> { manuscriptId: Manuscript }
  - chapters        -> { chapterId: Chapter }
  - fragments       -> { fragmentId: Fragment }          // story structure nodes
  - characters      -> { characterId: Character }
  - worldSettings   -> { settingId: WorldSetting }
  - plotNodes       -> { plotNodeId: PlotNode }          // foreshadowing, plot points
  - appSettings     -> { key: dynamic }                  // user preferences, model configs
  - apiKeys         -> encrypted via flutter_secure_storage (NOT in Hive)
```

**Confidence:** HIGH -- verified via pub.dev API (hive_ce 2.19.3, hive_ce_flutter 2.3.4), Context7 docs (encryption, adapter generation examples).

---

## Windows Desktop Support

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **window_manager** | ^0.5.1 | Native window management | Control window size, title bar, minimization behavior. Essential for a desktop-first writing app. |

### Windows IME (Input Method Editor)

Flutter's Windows embedder communicates with Windows Text Services Framework (TSF) natively. Since Flutter 3.x, CJK IME support (Chinese input methods: Wubi, Sogou, etc.) works through the standard `TextField` and text editing widgets. Key points:

- **No special package needed** -- Flutter's built-in `TextInputPlugin` on Windows handles IME composition
- **appflowy_editor** uses its own text input handling that integrates with Flutter's platform channels, so IME support is inherited
- The `TextEditingValue` and `TextEditingDelta` APIs handle composing text (the underlined in-progress text during IME input)
- **Constraint from PROJECT.md**: "Must use system-level IME, must not embed in-app input fields" -- this is satisfied by default Flutter behavior on Windows

**Confidence:** MEDIUM -- verified via Flutter docs (TextInputClient, insertContent API), but Chinese IME specifically with appflowy_editor on Windows should be tested early in development. The appflowy_editor team (AppFlowy itself) is heavily Chinese-user-facing, so IME support is a priority for them.

---

## Navigation & Routing

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **go_router** | ^17.2.3 | Declarative routing | Flutter's recommended router. Deep linking, nested routes, redirect guards. Handles Windows desktop + Android navigation patterns. |

**Confidence:** HIGH -- verified via pub.dev API.

---

## Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid | latest | Generate unique IDs for entities | All domain entities (manuscripts, chapters, characters, plot nodes) |
| logger | latest | Structured logging | Debug and development logging. Use `debugPrint` per project rules for UI debugging. |
| google_fonts | latest | Custom typography | Writer-facing app needs beautiful fonts. appflowy_editor integrates with google_fonts for text styles. |
| markdown | latest | Markdown parsing/rendering | Import/export of fragments and chapters in Markdown format. |
| path_provider | latest | Platform-specific paths | Locate app data directory for Hive initialization and export files. |
| share_plus | latest | Share functionality | Export and share manuscripts from Android. |
| file_picker | latest | File selection | Import/export files on Windows and Android. |
| url_launcher | latest | Open external URLs | Help links, license links, etc. |
| connectivity_plus | latest | Network status detection | Detect offline state for local-first behavior and API call guards. |
| json_annotation | latest | JSON serialization annotations | Pairs with `json_serializable` for DTO serialization. |

---

## Code Generation & Dev Tools

| Tool | Version | Purpose |
|------|---------|---------|
| build_runner | latest | Runs all code generators |
| json_serializable | latest | JSON serialization for DTOs |
| flutter_lints | latest | Lint rules (project uses strict analysis) |

---

## What NOT to Use

| Technology | Why NOT | What to Use Instead |
|------------|---------|-------------------|
| **sqflite / drift** | Overkill for a document-oriented writing app. Relational schema adds friction for flexible story structure. | hive_ce for NoSQL document storage |
| **Isar** | From the same author as Hive but heavier. Adds native binary dependencies. Hive CE is sufficient and lighter. | hive_ce |
| **firebase** | PROJECT.md explicitly excludes cloud sync for MVP. Adds Google dependency, privacy concerns for a creative writing tool. | hive_ce (local-only) |
| **supabase** | Same as firebase -- cloud backend excluded from MVP scope. | hive_ce (local-only) |
| **get_it / injectable** | Riverpod handles dependency injection natively. Adding a separate DI framework creates dual IoC containers. | Riverpod providers for DI |
| **bloc / cubit** | PROJECT mandates Riverpod. Bloc and Riverpod serve the same role. Mixing them is counterproductive. | Riverpod AsyncNotifier |
| **provider** | Legacy state management. Riverpod is the evolution. Using both causes confusion. | Riverpod |
| **shared_preferences** | Inappropriate for structured data. Only useful for trivial key-value settings. Hive boxes handle settings storage better. | hive_ce boxes |
| **flutter_quill** | Lacks built-in floating toolbar. Delta-based model harder to query for story structure. | appflowy_editor |
| **dart_openai** | Older, less maintained OpenAI wrapper. `openai_dart` is the modern, type-safe alternative with broader OpenAI-compatible API support. | openai_dart |
| **http** (raw) | Low-level HTTP client. All LLM SDKs handle their own HTTP. Only needed if building a custom API from scratch. | LLM SDKs (openai_dart, anthropic_sdk_dart, ollama_dart) |

---

## Installation

```bash
# Create Flutter project (if not already scaffolded)
flutter create --org com.museflow --platforms windows,android museflow

# Core framework
flutter pub add flutter_riverpod riverpod_annotation freezed_annotation json_annotation

# Editor
flutter pub add appflowy_editor google_fonts

# AI Integration
flutter pub add openai_dart anthropic_sdk_dart ollama_dart

# Storage
flutter pub add hive_ce hive_ce_flutter flutter_secure_storage

# Desktop
flutter pub add window_manager

# Navigation
flutter pub add go_router

# Supporting
flutter pub add uuid logger markdown path_provider share_plus file_picker url_launcher connectivity_plus

# Dev dependencies
flutter pub add --dev build_runner riverpod_generator freezed json_serializable flutter_lints
```

---

## Platform-Specific Notes

### Windows Desktop
- `window_manager` for native window control (size, title, minimize behavior)
- Flutter's TSF integration handles Chinese/Japanese/Korean IME natively
- `flutter_secure_storage` uses Windows Credential Manager for API key encryption
- Target: install package < 100MB (PROJECT.md constraint)
- File export/import via `file_picker` and `path_provider`

### Android
- Standard Flutter Android embedding
- `flutter_secure_storage` uses Android Keystore for API key encryption
- Share via `share_plus`
- `connectivity_plus` for network state awareness

---

## Sources

| Source | Confidence | What It Verified |
|--------|------------|------------------|
| pub.dev API (live queries) | HIGH | All package versions verified current as of 2026-05-31 |
| Context7 / appflowy_editor docs | HIGH | FloatingToolbar API, custom blocks, EditorState, desktop setup |
| Context7 / Riverpod docs | HIGH | AsyncNotifier, code generation, @riverpod annotation patterns |
| Context7 / openai_dart docs | HIGH | Custom baseUrl for OpenAI-compatible APIs (DeepSeek, Ollama, Groq, Azure) |
| Context7 / hive_ce docs | HIGH | Encryption, adapter generation, isolate support, transactions |
| Context7 / Flutter docs | MEDIUM | Windows TSF/IME integration, TextInputClient API |
| Local Flutter SDK | HIGH | Flutter 3.44.0 stable / Dart 3.5.4 confirmed installed |
