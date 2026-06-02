# Requirements: MuseFlow 灵韵

**Defined:** 2026-05-31
**Core Value:** 让AI帮你写好故事，但让读者看不出AI的痕迹。

## v1 Requirements

### Technical Foundation

- [ ] **TECH-01**: App runs as native Windows desktop application with proper window management (title bar, minimize/maximize/close, remember window size)
- [ ] **TECH-02**: System-level IME works correctly on Windows (Sogou, Wubi, Microsoft Pinyin input methods)
- [ ] **TECH-03**: Hive CE database initialized with encrypted storage for sensitive data
- [ ] **TECH-04**: API Keys stored via flutter_secure_storage (Windows Credential Manager / Android Keystore)
- [ ] **TECH-05**: App shell with navigation between modules (settings, capture, editor, knowledge base)
- [ ] **TECH-06**: App launches in under 3 seconds on Windows
- [ ] **TECH-07**: App runs on Android with adaptive layout

### Editor

- [ ] **EDIT-01**: Rich text editor (super_editor) with standard formatting (bold, italic, headings, lists)
- [ ] **EDIT-02**: Select text (word/phrase/paragraph) triggers floating toolbar popup
- [ ] **EDIT-03**: Floating toolbar provides: tone rewrite (语气改写), paragraph polish (文段润色), free input edit (自由输入)
- [ ] **EDIT-04**: Editor handles 300K+ character documents without lag (60fps scrolling)
- [ ] **EDIT-05**: Text provenance tracking — AI-modified text is visually distinguished from human-written text
- [ ] **EDIT-06**: Selective undo for AI modifications (revert AI changes without losing human edits)
- [ ] **EDIT-07**: Context anchor — user can select previous paragraphs as reference context for AI

### Fragment Capture (思维捕捉器)

- [ ] **CAPT-01**: Bullet-note mode for rapid fragment input
- [ ] **CAPT-02**: Fragments organized by story/chapter/scene
- [ ] **CAPT-03**: AI synthesizes selected fragments into coherent story paragraph(s)
- [ ] **CAPT-04**: Synthesized text is editable before entering main editor
- [ ] **CAPT-05**: Floating quick-capture window accessible from any screen

### AI Integration

- [ ] **AI-01**: Unified AI adapter interface supporting OpenAI-compatible APIs (OpenAI, DeepSeek, Ollama)
- [ ] **AI-02**: Claude API adapter (separate client due to different API structure)
- [ ] **AI-03**: Streaming responses (SSE) with real-time text display
- [ ] **AI-04**: PromptPipeline middleware system: system prompt → knowledge injection → skill enforcement → anti-AI-scent → user content
- [ ] **AI-05**: Anti-AI-scent prompt engineering layer — avoid AI clichés (总之, 然而, 综上所述, etc.)
- [ ] **AI-06**: Anti-AI-scent post-processing — detect and replace remaining AI patterns
- [ ] **AI-07**: Token budget management — smart context window allocation
- [ ] **AI-08**: Rate limiting and error handling with graceful offline fallback

### Model Management

- [x] **MODL-01**: Provider CRUD — add/edit/delete AI providers (name, API Key, Base URL)
- [x] **MODL-02**: Preset providers for OpenAI, Claude, DeepSeek, Ollama
- [ ] **MODL-03**: Per-provider model parameter config (Temperature, Top-P, Max Tokens)
- [ ] **MODL-04**: Custom model import support (LocalAI, etc.)

### Knowledge Base

- [ ] **KNOW-01**: Character card CRUD — name, personality, appearance, backstory, aliases
- [ ] **KNOW-02**: World setting CRUD — rules, factions, geography, technology level
- [ ] **KNOW-03**: AI auto-injects relevant character/setting context when writing
- [ ] **KNOW-04**: Name-index based entity matching for fast context lookup
- [ ] **KNOW-05**: Knowledge base quick-insert via keyboard shortcut in editor

### Skill System (世界观模板)

- [ ] **SKIL-01**: AI-assisted world-building — user describes world concept, AI generates complete setting document
- [ ] **SKIL-02**: Setting document includes: power hierarchy, faction relations, rules, taboos, terminology
- [ ] **SKIL-03**: Real-time skill enforcement — AI writes within selected skill's constraints
- [ ] **SKIL-04**: Deviation detection — alert when author writes content contradicting skill settings
- [ ] **SKIL-05**: Multiple skills can be active per project (e.g., "修仙体系" + "门派设定")

### Story Structure

- [ ] **STRC-01**: Foreshadowing tracking — mark and track planted plot threads
- [ ] **STRC-02**: Foreshadowing resolution detection — alert when unresolved threads accumulate
- [ ] **STRC-03**: Plot node management — create/move/connect story milestone nodes
- [ ] **STRC-04**: Character consistency guardian — AI flags when character acts out of established personality
- [ ] **STRC-05**: Logic loop detection — AI identifies contradictions in story timeline or rules

### Format & Export

- [ ] **FRMT-01**: Punctuation fixer — normalize half-width/full-width mixing (Chinese punctuation standard)
- [ ] **FRMT-02**: Markdown residual cleaner — remove stray asterisks, hash marks, HTML tags
- [ ] **FRMT-03**: One-click typeset beautify — indentation, line spacing, paragraph breaks
- [ ] **FRMT-04**: Export to plain text / Markdown / JSON

## v2 Requirements

### Preset Templates

- **TMPL-01**: Genre template library — 修仙, 武侠, 都市, 科幻, 玄幻 preset world-building packs
- **TMPL-02**: One-click apply preset template to new project

### Advanced Features

- **ADVN-01**: Story arc visualization — simple node-link diagram of plot structure
- **ADVN-02**: Opening guide — interactive questionnaire to generate 3 different-style openings
- **ADVN-03**: Writing analytics — word count, writing speed, AI usage ratio
- **ADVN-04**: Multi-chapter outline builder with story curve visualization

### Platform Expansion

- **PLAT-01**: Novel platform export templates (起点, 晋江, 番茄)
- **PLAT-02**: macOS / iOS support
- **PLAT-03**: Cloud sync (optional)

### Short Drama (短剧)

- **DRAM-01**: Screenplay format editor
- **DRAM-02**: AI-assisted script writing with scene/dialogue/action structure
- **DRAM-03**: Script-to-storyboard conversion

## Out of Scope

| Feature | Reason |
|---------|--------|
| One-click full novel generation | Core philosophy violation — forced segmented interaction |
| Real-time collaboration / multi-user | Single-author creation tool |
| Cloud account system / login | All data local-first in v1 |
| Built-in AI content detector | Anti-AI-scent handled via prompt engineering, not detection |
| Voice-to-text input | Out of scope for text-focused tool |
| Image generation | Text-only creation tool |
| Subscription / payment system | No cloud service in v1 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TECH-01 | Phase 1 | Pending |
| TECH-02 | Phase 1 | Pending |
| TECH-03 | Phase 1 | Pending |
| TECH-04 | Phase 1 | Pending |
| TECH-05 | Phase 1 | Pending |
| TECH-06 | Phase 1 | Pending |
| TECH-07 | Phase 1 | Pending |
| EDIT-01 | Phase 1 | Pending |
| EDIT-04 | Phase 1 | Pending |
| CAPT-01 | Phase 1 | Pending |
| CAPT-02 | Phase 1 | Pending |
| CAPT-05 | Phase 1 | Pending |
| AI-01 | Phase 2 | Pending |
| AI-03 | Phase 2 | Pending |
| AI-04 | Phase 2 | Pending |
| AI-05 | Phase 2 | Pending |
| AI-06 | Phase 2 | Pending |
| AI-07 | Phase 2 | Pending |
| AI-08 | Phase 2 | Pending |
| MODL-01 | Phase 2 | Complete (02-01) |
| MODL-02 | Phase 2 | Complete (02-01) |
| CAPT-03 | Phase 2 | Pending |
| CAPT-04 | Phase 2 | Pending |
| EDIT-02 | Phase 3 | Pending |
| EDIT-03 | Phase 3 | Pending |
| EDIT-05 | Phase 3 | Pending |
| EDIT-06 | Phase 3 | Pending |
| EDIT-07 | Phase 3 | Pending |
| KNOW-01 | Phase 4 | Pending |
| KNOW-02 | Phase 4 | Pending |
| KNOW-03 | Phase 4 | Pending |
| KNOW-04 | Phase 4 | Pending |
| KNOW-05 | Phase 4 | Pending |
| SKIL-01 | Phase 4 | Pending |
| SKIL-02 | Phase 4 | Pending |
| SKIL-03 | Phase 4 | Pending |
| SKIL-04 | Phase 4 | Pending |
| SKIL-05 | Phase 4 | Pending |
| STRC-01 | Phase 5 | Pending |
| STRC-02 | Phase 5 | Pending |
| STRC-03 | Phase 5 | Pending |
| STRC-04 | Phase 5 | Pending |
| STRC-05 | Phase 5 | Pending |
| FRMT-01 | Phase 5 | Pending |
| FRMT-02 | Phase 5 | Pending |
| FRMT-03 | Phase 5 | Pending |
| FRMT-04 | Phase 5 | Pending |
| AI-02 | Phase 6 | Pending |
| MODL-03 | Phase 6 | Pending |
| MODL-04 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 50 total
- Mapped to phases: 50
- Unmapped: 0

---
*Requirements defined: 2026-05-31*
*Last updated: 2026-05-31 after roadmap creation*
