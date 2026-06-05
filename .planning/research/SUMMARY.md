# Project Research Summary

**Project:** MuseFlow (AI-assisted creative writing tool for Chinese novelists)
**Domain:** Flutter desktop+mobile AI writing assistant
**Researched:** 2026-05-31
**Confidence:** HIGH

## Executive Summary

MuseFlow is a local-first, human-AI collaborative novel writing tool targeting Chinese web novel authors on Windows and Android. The product differentiates through a three-stage creative pipeline (Capture -> Organize -> Edit) with an anti-AI-scent system that makes AI-assisted text read as human-written -- the single most important feature for Chinese authors facing platform bans on AI content. The competitive landscape includes Sudowrite (Western), NovelAI (privacy-focused), and Biling/Moyu AI (Chinese market), but no existing tool combines fragment-based capture with anti-AI-scent and story structure tracking.

The recommended approach is a Clean Architecture Flutter application using Riverpod for state management, Hive CE for local storage, and a multi-provider AI adapter layer supporting OpenAI, Claude, DeepSeek, and Ollama. The architecture centers on a PromptPipeline middleware chain that assembles context (knowledge base injection, skill enforcement, anti-AI-flavor instructions) before every AI call, paired with a PostProcessor pipeline that filters AI cliches and normalizes Chinese punctuation. The rich text editor must support floating selection toolbars, Chinese IME composition on Windows, and large documents (300K+ characters).

The key risks are: (1) CJK IME composition breaking on Windows -- existential for the target market, (2) large document performance degradation in the rich text editor, (3) AI content detection by Chinese novel platforms, and (4) token budget exhaustion from knowledge base injection. All four are mitigable with correct editor choice (super_editor), chapter-based document chunking, multi-layer anti-AI-scent systems, and relevance-based context selection. The editor choice is the most consequential technical decision and must be validated with a benchmark spike before any feature code is written.

## Editor Decision: super_editor

**Recommendation: Use super_editor, NOT appflowy_editor.**

This resolves a conflict between research files. STACK.md recommends appflowy_editor 6.2.0 for its built-in `FloatingToolbar` widget. ARCHITECTURE.md and PITFALLS.md both recommend super_editor. After weighing the evidence against project requirements:

| Criterion | appflowy_editor | super_editor | Weight | Winner |
|-----------|----------------|--------------|--------|--------|
| Built-in floating toolbar | Yes -- `FloatingToolbar` widget, zero custom code | No built-in, but `OverlayPortal` + `Follower` pattern documented | Medium | appflowy_editor |
| CJK IME on Windows | Inherited from Flutter TSF; no dedicated IME changelog entries | Dedicated desktop IME support since July 2022, actively maintained | **Critical** | **super_editor** |
| Large document performance (300K+ chars) | Block-based, re-layouts blocks on change | Partial layout/invalidation -- only re-layouts affected regions | **Critical** | **super_editor** |
| Custom node types | `BlockComponentBuilder` for custom blocks | `ComponentBuilder` pattern for custom renderers | Medium | Tie |
| Prose writing focus | Designed for block-editor/productivity (Notion alternative) | General purpose, document model suits prose | Low | super_editor |
| Dependency footprint | Larger (AppFlowy ecosystem baggage) | Lighter | Low | super_editor |

**Verdict:** The project targets Chinese novel authors on Windows. CJK IME compatibility and 300K+ character performance are existential requirements, not nice-to-haves. A floating toolbar can be built with super_editor's `OverlayPortal`/`Follower` pattern (well-documented in Context7). IME correctness and large document performance cannot be retrofitted. The wrong editor choice would require a complete rewrite.

**Validation spike required:** Before Phase 1 feature work, create a benchmark comparing super_editor with a 100K+ character Chinese document. Test keystroke latency, memory usage, scroll performance, and IME composition with Sogou Pinyin and Wubi.

## Key Findings

### Recommended Stack

Flutter 3.44.0 / Dart 3.5.4 provides the foundation. Riverpod (with code generation) handles state management and dependency injection. Hive CE provides local NoSQL storage with encryption support. The AI layer uses openai_dart (covers OpenAI, DeepSeek, Ollama via custom baseUrl), anthropic_sdk_dart (Claude), and ollama_dart (local models). Go_router handles cross-platform navigation. Window_manager handles Windows desktop window behavior.

**Core technologies:**
- **super_editor**: Rich text editor -- CJK IME support, partial layout for large documents, popover toolbar pattern
- **flutter_riverpod + riverpod_generator**: State management -- code-gen providers, AsyncNotifier for AI streaming
- **hive_ce + hive_ce_flutter**: Local storage -- active fork of Hive, encryption, isolate support, type adapter generation
- **openai_dart**: AI API client -- type-safe, custom baseUrl covers OpenAI/DeepSeek/Ollama
- **anthropic_sdk_dart**: Claude API client -- required because Claude has a non-OpenAI-compatible API
- **flutter_secure_storage**: API key encryption -- uses Windows Credential Manager / Android Keystore
- **freezed**: Immutable data classes -- union types for Result/Either, copyWith generation
- **go_router**: Declarative routing -- nested routes, deep linking, redirect guards
- **window_manager**: Windows desktop -- native window control

### Expected Features

**Must have (table stakes):**
- Rich text editor with basic formatting and Chinese IME support
- Selection-based floating menu for AI actions (rewrite, polish, custom edit)
- Undo/redo with AI action rollback
- Chapter/section organization
- Dark mode and focus mode
- Word count and progress tracking
- Auto-save
- Text continuation, rewrite, and polish
- Custom API key input with base URL support
- Multiple model support (OpenAI/Claude/DeepSeek/Ollama)
- Character profiles and story settings (knowledge base)
- Context injection into AI calls
- Export to TXT/DOCX with format cleanup

**Should have (competitive differentiators):**
- Fragment capture mode (bullet-journal inspiration input) -- unique to MuseFlow
- Fragment-to-paragraph AI synthesis -- unique to MuseFlow
- Anti-AI-scent via prompt engineering (invisible to user) -- core product soul
- Automatic knowledge injection (AI reads relevant context without user selecting)
- Foreshadowing and plot thread tracking -- no competitor does this well
- Character consistency guardian -- flags contradictions with established traits
- World-building Skill system (AI-assisted creation + real-time deviation guard)
- Tone/style matching to author voice

**Defer (v2+):**
- Visual story canvas / timeline
- Platform-specific export templates (Qidian/Jinjiang/Tomato)
- Style/voice learning from author's previous writing
- AI feedback/critique mode
- Logic loop detection
- iOS/macOS support, cloud sync, social features

### Architecture Approach

The system follows Clean Architecture with strict dependency direction: Presentation -> Application -> Domain <- Infrastructure. Domain layer is pure Dart with zero external dependencies. The core architectural pattern is a **PromptPipeline middleware chain** in the Application layer that assembles AI prompts through sequential stages. AI providers are abstracted behind an `AIProvider` interface with concrete adapters registered in an `AIProviderRegistry`.

**Major components:**
1. **PromptPipeline** (Application layer) -- middleware chain for context injection, skill enforcement, anti-AI-scent
2. **PostProcessor pipeline** (Application layer) -- filters AI cliches, normalizes Chinese punctuation, checks consistency
3. **AI Adapter layer** (Infrastructure) -- provider abstraction with OpenAI/DeepSeek/Ollama and Claude adapters
4. **Knowledge Base** (Domain + Infrastructure) -- character profiles, world settings, story structure in Hive with auto-injection indexes
5. **Fragment Capture system** (Domain + Presentation) -- bullet-journal input feeding into AI synthesis
6. **super_editor integration** (Presentation) -- rich text editor with custom floating toolbar and text provenance

### Critical Pitfalls

1. **CJK IME composition breaks on Windows** -- Validate with Sogou, Wubi, Microsoft Pinyin in Phase 0. Use super_editor with dedicated desktop IME support.
2. **Rich text editor dies with large documents** -- Chinese novels reach 300K-1M characters. Use super_editor partial layout + chapter-based chunking. Never load more than 2-3 chapters.
3. **Token limit kills novel-length context** -- 30 character profiles + world settings can consume 40K-56K tokens. Implement relevance-based context selection and per-model context window awareness.
4. **AI content detection on Chinese platforms** -- Existential risk. Multi-layer anti-AI-scent (prompt + post-processing + style injection). Validate with detection tools.
5. **Editor choice is irreversible** -- Migrating editors after features are built is catastrophic. Benchmark spike before any feature code.

## Implications for Roadmap

### Phase 0: Technical Validation Spikes

**Rationale:** Three existential technical risks must be resolved before any feature code. Editor choice, IME compatibility, and large document performance determine feasibility of the entire project.
**Delivers:** Validated editor choice, IME compatibility report, performance benchmarks, package compatibility matrix
**Addresses:** Risk validation
**Avoids:** Pitfalls 1.1 (CJK IME), 1.2 (large documents), 1.3 (package compatibility)

### Phase 1: Foundation + Editor Core

**Rationale:** Domain entities and repository interfaces are the base everything depends on. Editor integration with floating toolbar and chapter organization is the most complex single component. Hive migration strategy and prompt template system must exist before feature work.
**Delivers:** Domain entities, repository interfaces, Hive with migration support, app shell with navigation, super_editor integration with floating toolbar, chapter-based document model, text provenance, prompt template skeleton
**Addresses:** Editor, chapters, dark mode, auto-save, word count, undo/redo, focus mode
**Avoids:** Pitfalls 5.1 (hardcoded prompts), 5.2 (no provenance), 5.5 (Hive migration)

### Phase 2: AI Infrastructure + Core AI Features

**Rationale:** AI adapter layer with multi-provider support is a stated requirement. PromptPipeline and anti-AI-scent are the product's soul. Fragment-to-paragraph synthesis validates the full pipeline.
**Delivers:** AI provider abstraction, OpenAI adapter, PromptPipeline middleware chain, anti-AI-scent system, streaming handling, token budget calculator, settings page, fragment-to-paragraph synthesis, basic knowledge base CRUD
**Uses:** openai_dart, flutter_secure_storage, Riverpod AsyncNotifier
**Implements:** PromptPipeline, PostProcessor, AI Adapter layer, KnowledgeInjector
**Avoids:** Pitfalls 2.1 (token limits), 2.2 (streaming), 2.3 (injection), 2.4 (cost), 2.5 (coupling), 2.6 (AI slop)

### Phase 3: Multi-Provider + Story Intelligence

**Rationale:** Add Claude/DeepSeek/Ollama adapters following the OpenAI pattern. Build story structure features that differentiate MuseFlow: foreshadowing tracking, character consistency, Skill enforcement.
**Delivers:** All AI adapters, format cleaner, export, character consistency guardian, foreshadowing tracking, Skill enforcement, story structure page
**Avoids:** Pitfalls 3.2 (character consistency), 3.3 (story continuity), 4.3 (platform formats)

### Phase 4: Polish + Android Optimization

**Rationale:** Desktop is stable. Optimize for Android, validate anti-AI-scent with real users, add brainstorming/describe modes.
**Delivers:** Android optimization, anti-AI-scent validation, advanced AI modes, UX polish

### Phase Ordering Rationale

- Phase 0 first because editor choice is irreversible and existential risks must be validated
- Phase 1 before Phase 2 because all AI features depend on the editor working with Chinese text
- Phase 2 before Phase 3 because story intelligence requires stable editor and AI infrastructure
- Multi-provider in Phase 3 (not Phase 2) to avoid scope creep; OpenAI alone validates architecture
- Android last because Windows desktop is primary per PROJECT.md

### Research Flags

Phases needing deeper research during planning:
- **Phase 0:** Editor benchmark with real Chinese text -- no documentation substitute for measurement
- **Phase 2:** Anti-AI-scent effectiveness validation -- generate samples, run through detection tools
- **Phase 2:** Token budget calculation for Chinese text -- empirical validation needed
- **Phase 3:** Chinese novel platform export format specs -- change frequently, verify at implementation time

Phases with standard patterns (skip research-phase):
- **Phase 1:** Domain entities, Hive setup, Riverpod providers are well-documented
- **Phase 3:** Additional AI adapters follow Phase 2's OpenAI pattern

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified via pub.dev and Context7. Flutter 3.44.0 confirmed locally. |
| Features | MEDIUM | Competitive analysis from fresh fetches. Training knowledge for some Chinese tools needs verification. |
| Architecture | HIGH | Established patterns (middleware, adapter, repository). Super Editor toolbar documented. No Flutter-specific AI orchestration reference. |
| Pitfalls | HIGH | CJK IME issues in Flutter tracker. Large doc performance is architectural. Token math deterministic. AI detection is arms race. |

**Overall confidence:** HIGH

### Gaps to Address

- **Anti-AI-scent effectiveness is unproven:** Banned phrase lists are from domain knowledge, not empirical testing. Must validate with real Chinese prose and AI detection tools in Phase 2.
- **super_editor CJK IME on Windows needs hands-on validation:** Documentation suggests strong support but only real testing with Sogou, Wubi, Microsoft Pinyin on Windows confirms. Phase 0 spike required.
- **Chinese novel platform format specs are stale:** Export format requirements for Qidian/Jinjiang/Tomato not freshly verified. Defer to Phase 3.
- **Streaming SSE into super_editor:** Buffering tokens and batch-inserting into MutableDocument needs prototyping. No reference implementation found.
- **Token counting for Chinese text:** Estimates of 1-2 tokens per character are approximate. Build and validate token estimation utility in Phase 2.

## Sources

### Primary (HIGH confidence)
- Context7 / super_editor docs -- popover toolbar, document model, ComponentBuilder, IME support
- Context7 / appflowy_editor docs -- FloatingToolbar API, BlockComponentBuilder
- Context7 / Riverpod docs -- AsyncNotifier, code generation, @riverpod annotation
- Context7 / openai_dart docs -- custom baseUrl for OpenAI-compatible APIs
- Context7 / hive_ce docs -- encryption, adapter generation, isolate support
- Context7 / Flutter docs -- Windows TSF/IME integration, TextInputClient, Isolate.run()
- pub.dev API -- all package versions verified 2026-05-31
- Flutter GitHub issue tracker -- #66896, #101553, #118917 (CJK IME)

### Secondary (MEDIUM confidence)
- Sudowrite.com homepage (fetched 2026-05-31) -- Describe, Write, Expand, Story Bible, Canvas
- Biling AI homepage (fetched 2026-05-31) -- full novel feature menu
- MetaCat homepage (fetched 2026-05-31) -- general writing tool
- Jasper.ai homepage (fetched 2026-05-31) -- marketing focus
- OWASP LLM Top 10 -- prompt injection guidance

### Tertiary (LOW confidence, needs validation)
- Training knowledge: NovelAI, Moyu AI, Xinghuo features -- not freshly verified
- Anti-AI-scent banned phrase lists -- need empirical testing
- Chinese novel platform export specs -- change frequently

---
*Research completed: 2026-05-31*
*Ready for roadmap: yes*
