# Architecture Patterns: MuseFlow AI Writing Assistant

**Domain:** Flutter AI writing assistant (novel/creative writing tool)
**Researched:** 2026-05-31
**Overall confidence:** HIGH (editor selection), MEDIUM (AI adapter patterns -- no Flutter-specific reference implementation exists, design is novel)

---

## Overview

MuseFlow is a human-AI collaborative novel writing tool built on a three-stage creative pipeline: **Capture -> Organize -> Edit**. The architecture must support:

1. A fragment capture system (bullet-journal style inspiration collection)
2. An AI orchestration layer that assembles fragments into coherent prose
3. An immersive rich text editor with selection-triggered floating toolbars
4. A knowledge base that auto-injects character/world context into AI prompts
5. A Skill (world-building template) system that enforces setting consistency in real-time
6. An anti-AI-flavor pipeline that post-processes AI output to feel human-written

The system is **local-first**: all data stored in Hive, all AI calls via user-configured API keys, no cloud dependency.

---

## Component Diagram

```
+-----------------------------------------------------------------------------+
|                              Presentation Layer                              |
|                                                                              |
|  +------------------+  +------------------+  +-----------------------------+ |
|  | CapturePage      |  | OrganizePage     |  | EditorPage                  | |
|  | (FragmentInput)  |  | (AI Assemble UI) |  | (SuperEditor + FloatToolbar)| |
|  +--------+---------+  +--------+---------+  +--------------+--------------+ |
|           |                      |                           |                |
|  +--------+----------------------+---------------------------+--------------+ |
|  |                        Riverpod Providers                                 | |
|  |  captureProvider  organizeProvider  editorProvider  knowledgeProvider     | |
|  +--------+----------------------+---------------------------+--------------+ |
+-----------|----------------------|---------------------------|--------------+
            |                      |                           |
+-----------v----------------------v---------------------------v--------------+
|                           Application Layer                                  |
|                                                                              |
|  +-------------------+  +------------------+  +---------------------------+ |
|  | CaptureUseCase    |  | OrganizeUseCase  |  | EditUseCase               | |
|  | (save fragments)  |  | (AI assemble)    |  | (rewrite/polish/format)   | |
|  +--------+----------+  +--------+---------+  +-------------+-------------+ |
|           |                      |                           |               |
|  +--------v----------------------v---------------------------v-------------+ |
|  |                     PromptPipeline                                      | |
|  |  [Context Assembler] -> [Knowledge Injector] -> [Skill Enforcer]        | |
|  |  -> [Anti-AI-Flavor Injector] -> [Final Prompt]                         | |
|  +--------+----------------------+---------------------------+-------------+ |
|           |                      |                           |               |
|  +--------v----------------------v---------------------------v-------------+ |
|  |                     PostProcessor                                       | |
|  |  [AI Response] -> [Anti-AI Filter] -> [Format Cleaner] -> [Output]      | |
|  +-------------------------------------------------------------------------+ |
+-----------|----------------------|---------------------------|--------------+
            |                      |                           |
+-----------v----------------------v---------------------------v--------------+
|                              Domain Layer                                    |
|                                                                              |
|  +---------------+  +---------------+  +---------------+  +---------------+ |
|  | Fragment      |  | StoryStructure|  | Character     |  | WorldSetting  | |
|  | (inspiration) |  | (plot/foreshadow)| (persona card)|  | (Skill)       | |
|  +-------+-------+  +-------+-------+  +-------+-------+  +-------+-------+ |
|          |                   |                   |                  |         |
|  +-------v-------------------v-------------------v------------------v------+ |
|  |                     Domain Services                                       | |
|  |  FragmentRepository  StoryRepository  CharacterRepository  SkillService | |
|  +-------------------------------------------------------------------------+ |
+-----------|----------------------|---------------------------|--------------+
            |                      |                           |
+-----------v----------------------v---------------------------v--------------+
|                          Infrastructure Layer                                |
|                                                                              |
|  +-------------------+  +-------------------+  +----------------------------+|
|  | AI Adapter        |  | HiveDataSource    |  | SecureStorage              ||
|  | (OpenAI/Claude/   |  | (boxes for each   |  | (API key encryption)       ||
|  |  DeepSeek/Ollama) |  |  entity type)     |  |                            ||
|  +-------------------+  +-------------------+  +----------------------------+|
|                                                                              |
|  +-------------------------------------------------------------------------+ |
|  | Platform Channels (Windows IME, Android input)                          | |
|  +-------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------+
```

---

## Component Boundaries

### What Talks to What

| Component | Talks To | Communication Pattern |
|-----------|----------|-----------------------|
| **Presentation (Pages/Widgets)** | Application Layer (via Riverpod providers) | Watches providers, dispatches actions via notifier methods |
| **Riverpod Providers** | Application UseCases | Providers instantiate and call UseCases; UseCases return domain entities |
| **Application UseCases** | Domain Repositories (interfaces) + PromptPipeline | UseCases orchestrate business flow; depend on repository abstractions |
| **PromptPipeline** | Domain entities + AI Adapter | Reads context from domain, constructs prompt, calls AI adapter |
| **PostProcessor** | AI Adapter output | Receives raw AI text, applies filters, returns cleaned text |
| **Domain Repositories (interfaces)** | Defined in Domain, implemented in Infrastructure | Dependency inversion: Application depends on abstractions |
| **HiveDataSource** | Hive boxes | Concrete data persistence; typed boxes per entity |
| **AI Adapter** | External HTTP APIs (OpenAI, Claude, DeepSeek, Ollama) | HTTP client with provider-specific request formatting |
| **SecureStorage** | flutter_secure_storage | Platform-specific encrypted storage for API keys |
| **SuperEditor** | EditorPage (Presentation) | Editor emits selection events; page shows/hides floating toolbar |

### Dependency Direction (Strict)

```
Presentation -> Application -> Domain <- Infrastructure
```

- Domain has ZERO external dependencies (pure Dart)
- Application depends on Domain interfaces only
- Infrastructure implements Domain interfaces
- Presentation depends on Application only (never touches Infrastructure directly)

---

## Editor Architecture

### Recommendation: Super Editor

**Confidence: HIGH**

Super Editor is the clear choice for MuseFlow for three reasons:

1. **First-class popover toolbar support.** Super Editor provides `OverlayPortal` + `Follower` widgets specifically designed for selection-triggered floating toolbars. The `SelectionLayerLinks` + `Follower.withAligner` pattern positions the toolbar relative to the selected text bounds. This is exactly MuseFlow's core interaction pattern (select text -> popup with rewrite/polish/custom).

2. **Custom document model.** Super Editor's `MutableDocument` + `MutableDocumentComposer` architecture gives full control over the document structure. MuseFlow needs custom node types for story elements (plot markers, character references, foreshadowing anchors) that go beyond basic rich text.

3. **Extensible component builders.** The `ComponentBuilder` pattern allows registering custom renderers for custom node types. MuseFlow can add specialized inline decorations (e.g., highlighting text that references a character, marking foreshadowing) without forking the editor.

**Why NOT flutter_quill:** Quill's toolbar is a fixed toolbar widget, not a selection popup. Its document model (Quill Delta) is less flexible for custom node types. Would require significant workaround for floating contextual menus.

**Why NOT AppFlowy Editor:** While it has a nice `FloatingToolbar`, it carries AppFlowy's architectural baggage. It is designed for block-editor / productivity use cases, not prose writing. The dependency footprint is larger.

### Floating Toolbar Implementation Pattern

```
User selects text
      |
      v
MutableDocumentComposer.selectionNotifier fires
      |
      v
EditorPage._hideOrShowToolbar() checks:
  - selection != null?
  - selection.isCollapsed? (ignore collapsed)
  - What node type is selected?
      |
      v
If expanded text selection:
  - _popoverToolbarController.show()
  - Follower.withAligner positions toolbar above selection
  - Toolbar shows: [Rewrite] [Polish] [Custom Edit]
      |
      v
User taps action (e.g., "Rewrite"):
  - Extracts selected text via composer.selection
  - Dispatches to EditUseCase with action type
  - UseCase builds prompt via PromptPipeline
  - AI returns rewritten text
  - Replace selection in MutableDocument via Editor.execute()
```

### Windows IME Integration

Flutter's Windows embedding handles IME natively via `TextInputPlugin` which bridges Win32 IMM32/TSF messages. Super Editor uses Flutter's standard text input system. Key considerations:

- **No custom IME code needed.** Super Editor delegates to Flutter's `TextEditingValue` which already handles composition strings for CJK input methods (Wubi, Sogou, Microsoft Pinyin).
- **IME candidate positioning.** Super Editor's document layout computes caret positions correctly; Flutter's engine maps these to Win32 `SetCompositionWindow` calls. If candidate window mispositions occur, use `TextInput.attach` with explicit `TextEditingValue` selection updates.
- **Test with multiple IMEs.** Must verify: Microsoft Pinyin, Sogou, Wubi, Google Japanese Input. Flutter 3.24+ has significantly improved Windows IME support.

---

## Data Flow

### 1. Fragment Capture Flow

```
User types fragments (bullet-journal style)
      |
      v
CapturePage widget calls ref.read(captureProvider.notifier).addFragment(text)
      |
      v
CaptureNotifier.addFragment() invokes CaptureUseCase(fragments)
      |
      v
CaptureUseCase validates -> Fragment entity created
      |
      v
FragmentRepository.save() -> HiveDataSource writes to 'fragments' box
      |
      v
State update propagates: captureProvider emits new fragment list
```

### 2. AI Organize Flow (Fragments -> Prose)

```
User selects fragments, taps "Organize into paragraph"
      |
      v
OrganizePage calls ref.read(organizeProvider.notifier).assemble(fragmentIds)
      |
      v
OrganizeNotifier invokes OrganizeUseCase(fragmentIds)
      |
      v
OrganizeUseCase:
  1. Fetches fragments from FragmentRepository
  2. Fetches relevant characters from CharacterRepository (knowledge base)
  3. Fetches relevant world settings from SkillService
  4. Builds prompt via PromptPipeline:
     a. System prompt: "You are a creative writing assistant..."
     b. Context: character cards + world settings (auto-injected)
     c. Skill enforcement: "Maintain consistency with [setting name]..."
     d. Anti-AI-flavor instructions: "Avoid these phrases and patterns..."
     e. User content: the fragments to organize
  5. Calls AI Adapter with assembled prompt
  6. Receives AI response
  7. Passes through PostProcessor:
     a. Anti-AI-flavor filter (regex-based phrase replacement)
     b. Format cleaner (punctuation normalization, markdown cleanup)
  8. Returns polished paragraph
      |
      v
OrganizeNotifier emits result -> UI displays draft paragraph
      |
      v
User accepts -> EditorPage opens with draft in SuperEditor
```

### 3. Editor Polish Flow (Selection Rewrite)

```
User selects text in SuperEditor -> floating toolbar appears
      |
      v
User taps "Polish" (or "Rewrite", "Custom Edit")
      |
      v
EditorPage extracts selected text via DocumentComposer.selection
      |
      v
Calls ref.read(editorProvider.notifier).polishSelection(text, action)
      |
      v
EditorNotifier invokes EditUseCase(text, action)
      |
      v
EditUseCase:
  1. Retrieves current story context (chapter, nearby text, active characters)
  2. Builds action-specific prompt via PromptPipeline:
     - Polish: "Refine this prose while preserving the author's voice..."
     - Rewrite: "Rewrite this passage in [tone] style..."
     - Custom: user-provided instruction + selected text
  3. Injects knowledge base context (active characters in scene)
  4. Injects Skill constraints (world rules that apply)
  5. Injects anti-AI-flavor instructions
  6. Calls AI Adapter
  7. PostProcess: anti-AI filter + format cleanup
  8. Returns replacement text
      |
      v
EditorNotifier receives replacement text
      |
      v
UI replaces selection in SuperEditor via Editor.execute() command
```

### 4. Knowledge Base Auto-Injection

```
Trigger: Any AI call (organize, polish, rewrite, skill check)
      |
      v
PromptPipeline.assemble() calls KnowledgeInjector
      |
      v
KnowledgeInjector:
  1. Receives the text content being processed
  2. Extracts entity mentions (character names, location names, story terms)
     via simple text matching against knowledge base indexes
  3. Loads relevant Character entities from CharacterRepository
  4. Loads relevant WorldSetting rules from SkillService
  5. Ranks relevance by:
     - Direct name mention (highest)
     - Current chapter/scene association
     - Recent usage frequency
  6. Assembles context block:
     ```
     [Active Characters]
     - Name: Li Wei | Personality: ... | Current state: ...
     [World Rules]
     - Cultivation system: ... | Geography: ...
     ```
  7. Returns context block for prompt injection
      |
      v
PromptPipeline inserts context block before user content in prompt
```

### 5. Skill Enforcement Flow (Real-time)

```
Trigger: User writes or AI generates text
      |
      v
SkillEnforcer monitors text changes (debounced, ~500ms)
      |
      v
SkillEnforcer.check(text, activeWorldSetting):
  1. Loads world rules from SkillService
  2. For each rule, checks if text violates:
     - Character behavior consistency (e.g., "Li Wei never speaks formally")
     - World mechanics (e.g., "Qi cultivation requires meditation first")
     - Plot constraints (e.g., "The sword was destroyed in chapter 3")
  3. If violation detected:
     - Returns Warning object with rule reference + explanation
     - UI shows subtle inline indicator (not blocking)
  4. If no violation: silent
      |
      v
Warning displayed as inline annotation in editor
User can acknowledge or modify text
```

---

## AI Prompt Pipeline Architecture

The PromptPipeline is the heart of MuseFlow's AI integration. It is a **middleware chain pattern** where each stage transforms the prompt.

### Pipeline Stages (in order)

```dart
/// Domain layer - pure Dart
class PromptPipeline {
  final List<PromptMiddleware> _middlewares;

  PromptPipeline(this._middlewares);

  PromptAssembly assemble(PromptRequest request) {
    var context = PromptContext.fromRequest(request);
    for (final middleware in _middlewares) {
      context = middleware.process(context);
    }
    return context.toAssembly();
  }
}

abstract class PromptMiddleware {
  PromptContext process(PromptContext context);
}
```

### Middleware Implementations

| Middleware | Input | Output | Purpose |
|------------|-------|--------|---------|
| **SystemPromptMiddleware** | Raw request | Adds system role message | Sets AI behavior, tone, creative writing persona |
| **KnowledgeInjectionMiddleware** | Request + empty context block | Adds relevant character/setting context | Auto-injects knowledge base entries |
| **SkillEnforcementMiddleware** | Request + context | Adds world-rule constraints | Injects "you must maintain these rules" instructions |
| **AntiAIFlavorMiddleware** | Request + accumulated prompt | Adds banned-phrases list | Instructs AI to avoid cliched patterns |
| **ContentMiddleware** | User's actual content | Adds user content as final block | The fragments/text to process |

### Post-Processor Pipeline (AI Response -> Final Output)

```dart
abstract class ResponsePostProcessor {
  String process(String aiResponse, ProcessingContext context);
}
```

| Processor | What It Does |
|-----------|-------------|
| **AntiAIFlavorFilter** | Regex-based removal of AI-common phrases ("Furthermore", "In conclusion", "It is worth noting", "Little did they know") |
| **PunctuationNormalizer** | Fixes mixed Chinese/English punctuation, redundant punctuation |
| **MarkdownCleaner** | Strips residual markdown artifacts (#, **, etc.) |
| **ConsistencyChecker** | Cross-references output against character/setting knowledge; flags potential inconsistencies |

---

## AI Adapter Architecture (Multi-Provider)

### Provider Abstraction

```dart
/// Domain layer interface
abstract class AIProvider {
  Future<String> complete(ProviderRequest request);
  Stream<String> completeStream(ProviderRequest request);
  String get providerId;  // e.g., 'openai', 'claude', 'deepseek', 'ollama'
}

/// Infrastructure layer
class ProviderRequest {
  final String model;
  final List<Message> messages;  // system + user + assistant turns
  final double temperature;
  final int maxTokens;
}

class Message {
  final String role;    // 'system', 'user', 'assistant'
  final String content;
}
```

### Concrete Adapters

Each AI provider has its own request format. The adapter normalizes:

| Provider | Endpoint Format | Auth | Notes |
|----------|----------------|------|-------|
| **OpenAI** | `POST /v1/chat/completions` | `Bearer {key}` | GPT-4o, GPT-4o-mini |
| **Claude** | `POST /v1/messages` | `x-api-key: {key}` | Different message format (system is separate param) |
| **DeepSeek** | `POST /v1/chat/completions` (OpenAI-compatible) | `Bearer {key}` | Same format as OpenAI |
| **Ollama** | `POST /api/chat` or `/api/generate` | None (local) | Local inference, no API key needed |

### Configuration Model

```dart
/// Stored in Hive, API key in flutter_secure_storage
class AIProviderConfig {
  final String providerId;
  final String displayName;
  final String apiKey;        // fetched from SecureStorage at runtime
  final String baseUrl;       // user-customizable for self-hosted
  final String model;
  final double temperature;
  final int maxTokens;
}
```

### Provider Registry

```dart
class AIProviderRegistry {
  final Map<String, AIProvider> _providers;

  void register(String id, AIProvider provider);
  AIProvider get(String id);
  List<String> get availableProviders;
}
```

The registry is populated at app startup based on which providers have configured API keys. Users add providers via the "AI Model Market" settings page.

---

## Knowledge Base Architecture

### Entity Model

```
Character
  - id, name, aliases[]
  - personality traits
  - speech patterns
  - backstory summary
  - current state (changes per chapter)
  - relationships[] -> Character

WorldSetting (Skill)
  - id, name, description
  - rules[] (mechanics, constraints)
  - locations[]
  - items[]
  - factions[]

StoryStructure
  - chapters[] -> {title, summary, plotNodes[]}
  - plotNodes[] -> {type: foreshadowing|resolution|twist, description, status: planted|resolved}
  - timeline[] -> {event, chapter, characters[]}

Fragment
  - id, content, tags[], createdAt
  - sourceType: capture|import|idea
  - linkedCharacters[]
  - linkedWorldSetting
```

### Auto-Injection Index

For efficient knowledge base lookup during prompt assembly:

```
CharacterNameIndex: Map<String, Character>
  - Built at load time from all Character entities
  - Maps every name + alias to the Character entity
  - Used by KnowledgeInjector for text scanning

WorldRuleIndex: Map<String, List<WorldRule>>
  - Maps keywords/concepts to applicable world rules
  - Used by SkillEnforcementMiddleware

PlotNodeTracker: tracks foreshadowing plant/resolution status
  - Used by ConsistencyChecker to flag unresolved threads
```

### Storage Layout (Hive Boxes)

| Box Name | Key Type | Value Type | Encryption |
|----------|----------|------------|------------|
| `fragments` | `String` (uuid) | `Fragment` (JSON) | No |
| `characters` | `String` (uuid) | `Character` (JSON) | No |
| `world_settings` | `String` (uuid) | `WorldSetting` (JSON) | No |
| `stories` | `String` (uuid) | `StoryStructure` (JSON) | No |
| `chapters` | `String` (uuid) | `Chapter` (JSON) | No |
| `ai_configs` | `String` (providerId) | `AIProviderConfig` (JSON) | No |
| `api_keys` | `String` (providerId) | `String` (encrypted key) | Yes (AES-256) |
| `preferences` | `String` (key) | `dynamic` | No |

---

## Story Structure Tracking

### Foreshadowing System

```
User marks text as "foreshadowing" (via editor annotation)
      |
      v
Creates PlotNode(type: foreshadowing, status: planted)
  - Links to text range in document
  - Links to relevant characters/settings
  - Stores expected resolution hint
      |
      v
PlotNodeTracker maintains:
  - Open threads: foreshadowing nodes with status=planted
  - Resolved threads: status=resolved, linked to resolution chapter
      |
      v
Consistency checks:
  - At chapter end: warn about unresolved foreshadowing
  - At story end: list all unresolved threads
  - During AI generation: remind AI about open foreshadowing
```

### Character Consistency Guard

```
Before any AI call involving a character:
  1. Load Character entity (personality, speech patterns, current state)
  2. Load relationship map (who this character knows, how they interact)
  3. Inject into prompt: "Character {name} is {personality}. They speak in {style}.
     They are currently {state}. Their relationship with {other} is {relationship}."
  4. Post-generation: check for violations (e.g., formal character using slang)
```

---

## Directory Structure

```
lib/
  core/
    domain/
      entities/
        fragment.dart
        character.dart
        world_setting.dart
        story_structure.dart
        plot_node.dart
        chapter.dart
        ai_provider_config.dart
      value_objects/
        text_selection.dart
        prompt_context.dart
        ai_response.dart
      repositories/
        fragment_repository.dart       (abstract)
        character_repository.dart      (abstract)
        world_setting_repository.dart  (abstract)
        story_repository.dart          (abstract)
        ai_config_repository.dart      (abstract)
      services/
        prompt_pipeline.dart
        post_processor.dart
        knowledge_injector.dart
        skill_enforcer.dart
        consistency_checker.dart

    application/
      use_cases/
        capture_fragment_use_case.dart
        organize_fragments_use_case.dart
        edit_text_use_case.dart
        manage_character_use_case.dart
        manage_world_setting_use_case.dart
        track_plot_use_case.dart
      dtos/
        fragment_input.dart
        organize_request.dart
        edit_request.dart

    infrastructure/
      ai_adapters/
        ai_provider.dart               (abstract)
        openai_adapter.dart
        claude_adapter.dart
        deepseek_adapter.dart
        ollama_adapter.dart
        ai_provider_registry.dart
      repositories/
        hive_fragment_repository.dart
        hive_character_repository.dart
        hive_world_setting_repository.dart
        hive_story_repository.dart
        hive_ai_config_repository.dart
      datasources/
        hive_datasource.dart
        secure_storage_datasource.dart
      post_processors/
        anti_ai_flavor_filter.dart
        punctuation_normalizer.dart
        markdown_cleaner.dart

    presentation/
      pages/
        capture_page.dart
        organize_page.dart
        editor_page.dart
        characters_page.dart
        world_settings_page.dart
        story_structure_page.dart
        settings_page.dart
      widgets/
        floating_toolbar.dart          (selection popup)
        fragment_card.dart
        character_card.dart
        plot_timeline.dart
        foreshadowing_marker.dart
        consistency_warning.dart
      providers/
        capture_provider.dart
        organize_provider.dart
        editor_provider.dart
        character_provider.dart
        world_setting_provider.dart
        story_provider.dart
        ai_config_provider.dart

  shared/
    theme/
      app_theme.dart
      typography.dart
    constants/
      prompt_templates.dart            (anti-AI-flavor phrases, system prompts)
      ai_defaults.dart
    utils/
      text_utils.dart
      json_converters.dart
```

---

## Build Order (Dependencies)

The build order is determined by what components depend on what. Each phase must be buildable and testable on its own.

### Phase 1: Foundation (No UI, No AI)

**What:** Domain entities + Repository interfaces + Hive data source + Basic app shell

**Why first:** Everything depends on domain entities. Repository interfaces define contracts. Hive setup validates data persistence. App shell provides navigation scaffold.

**Components:**
- Domain entities (Fragment, Character, WorldSetting, StoryStructure)
- Repository interfaces (abstract classes)
- HiveDataSource (boxes, type adapters)
- SecureStorageDataSource
- Basic MaterialApp shell with navigation (empty pages)
- Riverpod setup and provider infrastructure

**Testable:** Domain entity unit tests, Hive read/write tests

### Phase 2: Capture Feature (First User-Visible Feature)

**What:** Fragment capture page + fragment persistence + bullet-journal UI

**Why second:** Simplest feature. Validates the full stack (UI -> UseCase -> Repository -> Hive) with a single entity type. No AI dependency.

**Components:**
- CaptureFragmentUseCase
- HiveFragmentRepository (implements FragmentRepository)
- CapturePage UI
- CaptureProvider (Riverpod)
- FragmentCard widget

**Testable:** CaptureUseCase tests, CapturePage widget tests, full capture flow

### Phase 3: AI Infrastructure (The Engine)

**What:** AI adapter layer + Provider registry + PromptPipeline + basic settings UI

**Why third:** Before any AI features work, the adapter infrastructure must be solid. This phase validates API connectivity, streaming, and error handling.

**Components:**
- AIProvider interface
- OpenAI adapter (start with one provider)
- AIProviderRegistry
- AIConfigRepository + SecureStorage
- PromptPipeline (with SystemPromptMiddleware + ContentMiddleware only)
- PostProcessor (basic AntiAIFlavorFilter)
- SettingsPage (API key input, provider selection)

**Testable:** AI adapter integration tests (with mocked HTTP), PromptPipeline unit tests, settings flow tests

### Phase 4: Organize Feature (AI Assemble)

**What:** Fragment -> AI paragraph assembly + KnowledgeInjector

**Why fourth:** First AI-dependent feature. Requires Phase 3's AI infrastructure. Also introduces the knowledge base auto-injection system.

**Components:**
- OrganizeFragmentsUseCase
- KnowledgeInjector service
- KnowledgeInjectionMiddleware
- Character + WorldSetting entities already exist from Phase 1
- OrganizePage UI
- OrganizeProvider

**Testable:** OrganizeUseCase tests (with mocked AI), KnowledgeInjector unit tests, organize flow widget tests

### Phase 5: Editor (The Core Experience)

**What:** Super Editor integration + floating toolbar + EditUseCase

**Why fifth:** Editor depends on AI infrastructure (for polish/rewrite actions) and on the document model. Super Editor integration is complex and needs dedicated focus.

**Components:**
- SuperEditor integration and configuration
- FloatingToolbar widget (selection popup with rewrite/polish/custom)
- EditTextUseCase
- EditorProvider
- EditorPage
- Text selection extraction and replacement logic

**Testable:** Editor widget tests, floating toolbar interaction tests, edit flow tests

### Phase 6: Knowledge Base & Characters

**What:** Character management UI + World settings (Skill) management + enhanced knowledge injection

**Why sixth:** With editor working, add the knowledge base features that enrich AI output. Character cards and world settings were entities since Phase 1; now add full CRUD UI and deeper injection.

**Components:**
- ManageCharacterUseCase + CharacterPage
- ManageWorldSettingUseCase + WorldSettingsPage
- SkillEnforcementMiddleware
- CharacterNameIndex (auto-injection lookup)
- WorldRuleIndex
- ConsistencyChecker (post-processor)

**Testable:** Character CRUD tests, Skill enforcement tests, consistency check tests

### Phase 7: Story Structure & Skill Enforcement

**What:** Plot tracking + foreshadowing system + real-time Skill enforcement

**Why seventh:** Most complex domain feature. Depends on editor (for annotations) and knowledge base (for consistency checks).

**Components:**
- TrackPlotUseCase
- PlotNode entity operations
- ForeshadowingMarker (editor annotation widget)
- ConsistencyWarning widget
- SkillEnforcer service (debounced monitoring)
- StoryStructurePage
- PlotTimeline widget

**Testable:** Plot tracking tests, foreshadowing lifecycle tests, Skill enforcement integration tests

### Phase 8: Polish & Multi-Provider

**What:** Additional AI adapters (Claude, DeepSeek, Ollama) + format cleaner + anti-AI-flavor tuning

**Why last:** These are additive. The first provider (OpenAI) works from Phase 3. Additional providers follow the same adapter pattern. Anti-AI-flavor tuning requires real-world testing.

**Components:**
- ClaudeAdapter, DeepSeekAdapter, OllamaAdapter
- PunctuationNormalizer, MarkdownCleaner (post-processors)
- Anti-AI-flavor phrase list tuning
- AI Model Market UI (provider selection, configuration)
- Export functionality (JSON, TXT)

**Testable:** Each adapter's integration tests, post-processor unit tests, export tests

---

## Anti-Patterns to Avoid

### 1. Fat Providers (Riverpod)

**Bad:** A single provider that holds all editor state, AI state, and knowledge base state.

**Good:** One provider per bounded context. `editorProvider` manages editor state. `knowledgeProvider` manages knowledge base. `aiProvider` manages AI calls. They communicate through UseCases, not through each other's state.

### 2. AI Response in Domain Entities

**Bad:** Storing raw AI responses as domain entity fields (e.g., `Fragment.aiGeneratedText`).

**Good:** AI responses are ephemeral in the Application layer. User accepts/edits them, then the *accepted text* becomes domain data. The AI's involvement is an implementation detail, not a domain concept.

### 3. Synchronous AI Calls

**Bad:** Blocking the UI thread while waiting for AI response.

**Good:** All AI calls return `Stream<String>` (streaming). UI shows typing-indicator while streaming. Use Riverpod's `AsyncValue` pattern to handle loading/data/error states.

### 4. Monolithic Prompt Construction

**Bad:** One massive string concatenation function that builds prompts.

**Good:** PromptPipeline middleware chain. Each concern (system prompt, knowledge injection, skill enforcement, anti-AI flavor, user content) is a separate middleware. Testable in isolation. Composable.

### 5. Editor Knows About AI

**Bad:** EditorPage directly calls AI adapters.

**Good:** EditorPage dispatches to EditorProvider, which calls EditUseCase, which orchestrates PromptPipeline + AI Adapter + PostProcessor. The editor widget tree has zero knowledge of AI.

---

## Scalability Considerations

| Concern | At 10 fragments | At 1,000 fragments | At 10,000+ fragments |
|---------|----------------|-------------------|---------------------|
| Fragment listing | ListView | ListView.builder (lazy) | Pagination + search |
| Knowledge lookup | Full scan | NameIndex map | Inverted index (character names -> entities) |
| AI prompt size | Include all context | Top-5 relevant by score | Top-5 + summarization of remainder |
| Story structure | In-memory tree | In-memory tree | Lazy-load chapters |
| Hive performance | Single box | Single box fine | Consider box-per-project |

MuseFlow is a single-user local tool. The realistic scale ceiling is a few hundred fragments and characters per project. Performance optimization beyond Hive indexes is premature.

---

## Sources

- Super Editor documentation via Context7: /superlistapp/super_editor (popover toolbar, document model, component builders)
- Flutter Quill documentation via Context7: /singerdmx/flutter-quill (toolbar architecture)
- AppFlowy Editor documentation via Context7: /appflowy-io/appflowy-editor (floating toolbar)
- Riverpod documentation via Context7: /websites/pub_dev_flutter_riverpod_3_3_0 (provider patterns, family modifiers, AsyncNotifier)
- Hive documentation via Context7: /isar/hive (boxes, type adapters, encryption)
- Flutter Windows IME: Flutter engine source (shell/platform/windows/text_input_plugin)
- Project requirements: .planning/PROJECT.md
