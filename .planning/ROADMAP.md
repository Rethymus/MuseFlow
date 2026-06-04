# Roadmap: MuseFlow 灵韵

## Overview

MuseFlow is built from spike to polish in 7 phases. Phase 0 validates existential technical risks (editor choice, CJK IME, large document performance) before committing to architecture. Phase 1 delivers a usable app shell with editor and fragment capture UI -- a real app users can touch. Phase 2 adds AI providers and completes the capture-to-synthesis pipeline, making the core creative loop work end-to-end. Phase 3 layers AI-powered editor features (floating toolbar, provenance tracking, selective undo). Phase 4 builds the knowledge base and skill system that auto-inject context into AI calls. Phase 5 adds story structure tools (foreshadowing, consistency guardian) plus format cleaning and export. Phase 6 rounds out multi-provider support and Android optimization. Each phase delivers one coherent, verifiable capability.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 0: Technical Validation** - Spike editor/IME/packages before committing to architecture (completed 2026-06-01)
- [x] **Phase 1: App Shell + Editor + Capture UI** - Runnable app with navigation, editor, and fragment capture (no AI) (completed 2026-06-01)
- [x] **Phase 2: AI Provider + Capture Synthesis** - AI adapter layer, provider settings, anti-AI-scent, fragment synthesis (completed 2026-06-02)
- [x] **Phase 3: Editor AI Toolbar** - Floating toolbar with AI actions, text provenance, selective undo, context anchor (completed 2026-06-02)
- [x] **Phase 4: Knowledge Base + Skill System** - Character cards, world settings, auto-injection, AI-assisted world-building (completed 2026-06-04)
- [x] **Phase 5: Story Structure + Format + Export** - Foreshadowing tracking, consistency guardian, format cleaning, export (completed 2026-06-04)
- [x] **Phase 6: Multi-Provider + Android Polish** - Claude adapter, model parameters, custom models, Android optimization

## Phase Details

### Phase 0: Technical Validation
**Mode**: mvp
**Goal**: Validate that super_editor handles CJK IME on Windows and performs with 100K+ character Chinese documents before committing any feature code
**Depends on**: Nothing (first phase)
**Requirements**: *(Spike phase -- no v1 requirements mapped. Validates feasibility for TECH-02, EDIT-01, EDIT-04)*
**Success Criteria** (what must be TRUE):
  1. super_editor renders a 100K+ character Chinese document with acceptable scroll performance (< 16ms frame time)
  2. Sogou Pinyin, Wubi, and Microsoft Pinyin IME composition works correctly in super_editor on Windows
  3. All core packages (super_editor, hive_ce, flutter_riverpod, openai_dart, anthropic_sdk_dart) resolve without version conflicts
  4. Streaming SSE tokens can be buffered and batch-inserted into super_editor's MutableDocument without jank
**Risks**: super_editor fails IME or performance benchmarks -- would force editor migration (catastrophic). Mitigated by validating before feature code.
**Plans**: 3 plans

Plans:
- [x] 00-01: Editor benchmark spike -- large Chinese document performance
- [x] 00-02: CJK IME validation spike -- Sogou/Wubi/MSPinyin on Windows
- [x] 00-03: Package compatibility matrix -- resolve all dependencies, verify streaming into editor

### Phase 1: App Shell + Editor + Capture UI
**Mode**: mvp
**Goal**: Users can launch the app, navigate between modules, write in a rich text editor with Chinese IME, and capture/organize inspiration fragments
**Depends on**: Phase 0 (editor/IME validated)
**Requirements**: TECH-01, TECH-02, TECH-03, TECH-04, TECH-05, TECH-06, TECH-07, EDIT-01, EDIT-04, CAPT-01, CAPT-02, CAPT-05
**Success Criteria** (what must be TRUE):
  1. App launches as a native Windows desktop app in under 3 seconds with proper window management (title bar, minimize/maximize/close, remembered size)
  2. User can navigate between modules (capture, editor, settings) via the app shell
  3. Rich text editor supports bold, italic, headings, lists and handles 300K+ character documents without lag
  4. Sogou, Wubi, and Microsoft Pinyin input methods work correctly in the editor
  5. User can create, edit, and organize fragments in bullet-note mode by story/chapter/scene
  6. Floating quick-capture window is accessible from any screen
**UI hint**: yes
**Risks**: Hive CE encryption setup on Windows may require native library configuration. Window size persistence may need platform channel work.
**Plans:** 4/4 plans complete

Plans:
- [x] 01-01: App shell with window management, navigation, and Hive/secure storage initialization
- [x] 01-02: Rich text editor integration (super_editor) with formatting and large document support
- [x] 01-03: Fragment capture UI -- bullet-note mode, organization by story/chapter/scene
- [x] 01-04: Quick-capture floating window and Android adaptive layout

**Wave 1** *(foundation — everything depends on this)*
- 01-01: App shell + storage infrastructure + sidebar navigation

**Wave 2** *(parallel — editor and capture are independent)*
- 01-02: Rich text editor with formatting toolbar
- 01-03: Fragment capture workspace with tagging

**Wave 3** *(blocked on Wave 1 + 01-03)*
- 01-04: Quick-capture overlay + adaptive layout

**Cross-cutting constraints:**
- `AppConstants` layout breakpoints shared across 01-01, 01-04
- `CaptureNotifier` provider created in 01-03, consumed by 01-04

### Phase 2: AI Provider + Capture Synthesis
**Mode**: mvp
**Goal**: Users can configure an AI provider, and the fragment capture flow works end-to-end: select fragments, AI synthesizes them into coherent story paragraphs, user edits before sending to editor
**Depends on**: Phase 1 (app shell, editor, capture UI)
**Requirements**: AI-01, AI-03, AI-04, AI-05, AI-06, AI-07, AI-08, MODL-01, MODL-02, CAPT-03, CAPT-04
**Success Criteria** (what must be TRUE):
  1. User can add an OpenAI-compatible provider (name, API Key, Base URL) and select it for use
  2. Preset providers (OpenAI, DeepSeek, Ollama) are available as one-click configurations
  3. User selects fragments and triggers AI synthesis -- streaming response appears in real time
  4. Synthesized text is editable before being placed into the editor
  5. Anti-AI-scent layer is active: generated text avoids AI cliches (总之, 然而, 综上所述, etc.) via prompt engineering and post-processing
  6. AI errors (network failure, rate limit, invalid key) display graceful messages, not crashes
**UI hint**: yes
**Risks**: Anti-AI-scent effectiveness is unproven until tested with real Chinese prose and detection tools. Token budget estimation for Chinese text needs empirical validation.
**Plans:** 3/3 plans complete

Plans:
- [x] 02-01-PLAN.md — Provider management: domain entity, repository, presets, service, settings UI with CRUD and routing
- [x] 02-02-PLAN.md — AI engine: OpenAI adapter with streaming, PromptPipeline middleware chain, anti-AI-scent processor, token budget calculator
- [x] 02-03-PLAN.md — Synthesis UX: SynthesisNotifier, slide-out panel with streaming display, editor insertion, banned phrase settings

**Wave 1** *(foundation — provider entity and management UI)*
- 02-01: Provider domain + repository + presets + service + settings UI

**Wave 2** *(depends on 02-01 for provider entity)*
- 02-02: OpenAI adapter + PromptPipeline + anti-AI-scent + token budget

**Wave 3** *(depends on 02-01 + 02-02)*
- 02-03: SynthesisNotifier + panel + capture page integration + editor insertion

**Cross-cutting constraints:**
- `AIProvider` entity and `ProviderService` created in 02-01, consumed by 02-02 and 02-03
- `OpenAIAdapter`, `PromptPipeline`, `AntiAIScentProcessor` created in 02-02, consumed by 02-03
- `CaptureNotifier.selectedIds` / `selectedFragmentsProvider` from Phase 1 consumed by 02-03
- `EditorPage._editor` exposed via provider in 02-03 for text insertion

### Phase 3: Editor AI Toolbar
**Mode**: mvp
**Goal**: Users can select text in the editor and get AI-powered actions via a floating toolbar: tone rewrite, paragraph polish, free-form edit -- with provenance tracking and selective undo
**Depends on**: Phase 2 (AI provider, PromptPipeline, anti-AI-scent)
**Requirements**: EDIT-02, EDIT-03, EDIT-05, EDIT-06, EDIT-07
**Success Criteria** (what must be TRUE):
  1. User selects text (word/phrase/paragraph) and a floating toolbar appears at the selection
  2. Floating toolbar provides three AI actions: tone rewrite (语气改写), paragraph polish (文段润色), free input edit (自由输入)
  3. AI-modified text is visually distinguished from human-written text (provenance tracking)
  4. User can selectively undo AI modifications without losing their own human edits
  5. User can select previous paragraphs as reference context for AI operations (context anchor)
**UI hint**: yes
**Risks**: Floating toolbar positioning with super_editor's OverlayPortal/Follower pattern needs prototyping. Selective undo with provenance tracking adds document model complexity.
**Plans:** 3/3 plans complete

Plans:
- [x] 03-01-PLAN.md — Floating toolbar: SelectionLayerLinks + Follower, three AI actions, free-input, progress bar, smart flip
- [x] 03-02-PLAN.md — Provenance tracking: inline diff display, accept/reject per sentence, blue attribution, status bar
- [x] 03-03-PLAN.md — Selective undo + context anchors: AI undo stack, anchor entities, middleware injection, visual indicators

**Wave 1** *(foundation — floating toolbar + AI operation engine)*
- 03-01: Floating toolbar, EditorAINotifier, EditorPromptPipeline, SentenceSegmenter

**Wave 2** *(depends on 03-01 for EditorAIState and streaming)*
- 03-02: Diff state entities, inline diff display, accept/reject, provenance attribution, status bar

**Wave 3** *(depends on 03-01 + 03-02)*
- 03-03: Selective undo service, context anchors, middleware injection, anchor indicators

**Cross-cutting constraints:**
- `PromptContext` extended with `selectedText` and `anchors` fields in 03-01, consumed by 03-02 and 03-03
- `EditorAINotifier` created in 03-01, extended with accept/reject in 03-02, extended with undo + anchors in 03-03
- `EditorPromptPipeline` created in 03-01, extended with `ContextAnchorMiddleware` in 03-03

### Phase 4: Knowledge Base + Skill System
**Mode**: mvp
**Goal**: Users maintain character cards and world settings, AI auto-injects relevant context when writing, and AI assists in creating complete world-building documents that enforce constraints during writing
**Depends on**: Phase 3 (editor with AI integration, PromptPipeline)
**Requirements**: KNOW-01, KNOW-02, KNOW-03, KNOW-04, KNOW-05, SKIL-01, SKIL-02, SKIL-03, SKIL-04, SKIL-05
**Success Criteria** (what must be TRUE):
  1. User can create, edit, and delete character cards (name, personality, appearance, backstory, aliases)
  2. User can create, edit, and delete world settings (rules, factions, geography, technology level)
  3. AI automatically injects relevant character/setting context when generating or editing text -- no manual selection required
  4. User describes a world concept and AI generates a complete setting document (power hierarchy, faction relations, rules, taboos, terminology)
  5. AI flags when author writes content contradicting active skill settings (deviation detection)
  6. Multiple skills can be active per project (e.g., "修仙体系" + "门派设定")
**UI hint**: yes
**Risks**: Name-index entity matching for auto-injection may produce false positives with Chinese names. Token budget can be exhausted by large knowledge bases -- relevance scoring is critical.
**Plans:** 5/5 plans complete

Plans:
- [x] 04-01: Knowledge base CRUD -- character cards and world settings with Hive persistence
- [x] 04-02: Name-index entity matching and AI auto-injection into PromptPipeline
- [x] 04-03: Skill system -- AI-assisted world-building document generation
- [x] 04-04: Real-time skill enforcement, deviation detection, and multi-skill activation
- [x] 04-05: Knowledge base quick-insert via keyboard shortcut in editor

**Wave 1** *(foundation — entities, repositories, notifiers, UI)*
- 04-01: Knowledge base CRUD — CharacterCard, WorldSetting, Hive adapters, repositories, notifiers, knowledge base page

**Wave 2** *(parallel — name index and skill generation are independent)*
- 04-02: Name-index entity matching + KnowledgeInjectionMiddleware for auto-injection
- 04-03: Skill system — SkillDocument entity, AI-assisted generation, multi-step wizard

**Wave 3** *(parallel — depends on Wave 1 + 2)*
- 04-04: SkillEnforcementMiddleware, deviation detection, multi-skill activation UI
- 04-05: Ctrl+K quick-insert dialog for knowledge references in editor

**Cross-cutting constraints:**
- `KnowledgeEntity` abstract base and `EntityType` enum created in 04-01, consumed by 04-02 through 04-05
- `NameIndex` created in 04-02, consumed by 04-02's KnowledgeInjectionMiddleware
- `SkillDocument` and `SkillRepository` created in 04-03, consumed by 04-04 and 04-05
- `CharacterCardNotifier`/`WorldSettingNotifier` created in 04-01, presentation layer uses notifiers not repositories

### Phase 5: Story Structure + Format + Export
**Mode**: mvp
**Goal**: Users can track foreshadowing threads, manage plot nodes, and rely on AI to catch character inconsistencies and story contradictions -- then clean formatting and export their work
**Depends on**: Phase 4 (knowledge base with character data for consistency checks)
**Requirements**: STRC-01, STRC-02, STRC-03, STRC-04, STRC-05, FRMT-01, FRMT-02, FRMT-03, FRMT-04
**Success Criteria** (what must be TRUE):
  1. User can mark and track planted foreshadowing threads, with alerts when unresolved threads accumulate
  2. User can create, move, and connect story milestone nodes (plot node management)
  3. AI flags when a character acts inconsistently with their established personality (consistency guardian)
  4. AI identifies contradictions in story timeline or rules (logic loop detection)
  5. One-click typeset beautify fixes punctuation (half/full-width mixing), removes Markdown residuals, and applies proper indentation/spacing
  6. User can export to plain text, Markdown, or JSON format
**UI hint**: yes
**Risks**: Logic loop detection is AI-dependent and may produce false positives. Foreshadowing resolution detection requires tracking state across chapters. Format cleaning edge cases in Chinese punctuation are numerous.
**Plans:** 4/4 plans complete

Plans:
- [x] 05-01: Foreshadowing tracking and resolution detection
- [x] 05-02: Plot node management and character consistency guardian
- [x] 05-03: Logic loop detection via AI analysis
- [x] 05-04: Format cleaning (punctuation, Markdown residuals, typeset) and export (TXT/MD/JSON)

### Phase 6: Multi-Provider + Android Polish
**Mode**: mvp
**Goal**: Users can use Claude as an AI provider via OpenAI-compatible endpoint, configure per-provider model parameters, import custom models via model list fetching, and the app works smoothly on Android with responsive layout
**Depends on**: Phase 5 (all features complete, polishing existing functionality)
**Requirements**: AI-02, MODL-03, MODL-04
**Success Criteria** (what must be TRUE):
  1. User can add Claude as a preset AI provider (via Anthropic's OpenAI-compatible endpoint, no anthropic_sdk_dart)
  2. User can configure per-provider model parameters (Temperature, Top-P, Max Tokens)
  3. User can discover models via GET /v1/models or manually enter model IDs (custom model import)
  4. Provider management page renders on Android with responsive layout at 600px breakpoint
**UI hint**: yes
**Risks**: Claude's OpenAI-compatible endpoint may not support GET /v1/models (mitigated by silent fallback per D-08). Android layout adaptation may surface touch/IME issues not seen on Windows.
**Plans:** 3/3 plans executed

Plans:
- [x] 06-01-PLAN.md — Claude preset via OpenAI-compatible endpoint, AiProviderType.claude, testConnection fix, UI wiring
- [x] 06-02-PLAN.md — Per-provider model parameters (temperature/topP/maxTokens), model list fetching, parameter UI
- [x] 06-03-PLAN.md — Responsive provider management layout for Android, integration tests for core flow

**Wave 1** *(foundation — Claude preset + enum variant)*
- 06-01: Claude preset + enum variant + testConnection fix + UI wiring

**Wave 2** *(depends on 06-01 for claude enum)*
- 06-02: Nullable parameter fields + adapter forwarding + parameter UI + model list fetching

**Wave 3** *(depends on 06-02 for final provider management page)*
- 06-03: Responsive layout adaptation + integration tests

**Cross-cutting constraints:**
- `AiProviderType.claude` enum variant created in 06-01, consumed by 06-01 UI and 06-02 form
- `AIProvider` nullable parameter fields (temperature/topP/maxTokens) created in 06-02, must not conflict with 06-01 entity changes
- `OpenAIAdapter.createStream` extended with nullable parameters in 06-02, consumed by SynthesisNotifier and EditorAINotifier
- `provider_management_page.dart` modified in all three plans -- sequential waves prevent file conflicts

## Progress

**Execution Order:**
Phases execute in numeric order: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Technical Validation | 3/3 | Complete   | 2026-06-01 |
| 1. App Shell + Editor + Capture UI | 4/4 | Complete   | 2026-06-01 |
| 2. AI Provider + Capture Synthesis | 3/3 | Complete    | 2026-06-02 |
| 3. Editor AI Toolbar | 3/3 | Complete   | 2026-06-02 |
| 4. Knowledge Base + Skill System | 5/5 | Complete | 2026-06-04 |
| 5. Story Structure + Format + Export | 3/4 | In Progress|  |
| 6. Multi-Provider + Android Polish | 3/3 | Complete | 2026-06-04 |
