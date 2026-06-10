# Requirements: MuseFlow 灵韵 v1.4

**Defined:** 2026-06-11
**Core Value:** 让AI帮你写好故事，但让读者看不出AI的痕迹。

## v1.4 Requirements

Requirements for AI辅助创作体验深度优化 milestone. Each maps to roadmap phases.

### Author Style Learning

- [ ] **STYLE-01**: User can view their AuthorStyleProfile showing analysis across 5+ dimensions (sentence length distribution, rhythm patterns, vocabulary preferences, rhetoric habits, emotional tone)
- [ ] **STYLE-02**: AI prompts dynamically adapt to match author's writing style instead of using a fixed one-line persona instruction
- [ ] **STYLE-03**: System automatically extracts 3-5 high-quality paragraphs from author's existing chapters as few-shot style samples injected into AI prompts
- [ ] **STYLE-04**: AI-generated text is compared against author's AuthorStyleProfile and style deviations are highlighted in the diff review view

### Anti-AI-Scent Enhancement

- [ ] **AISC-01**: User can manage a categorized banned phrase library with 200+ entries across categories (transitions, modifiers, summaries, genre clichés)
- [ ] **AISC-02**: System detects AI semantic patterns beyond keyword matching (info density uniformity, emotion curve flatness, over-balanced descriptions, unnaturally perfect logic)
- [ ] **AISC-03**: User can view a style thermometer dashboard showing AI-scent score (0-100), style consistency with author profile, literary quality score, and readability metrics
- [ ] **AISC-04**: Post-processing pipeline detects and highlights 20+ structural patterns, repetition structures, modifier overload, passive voice frequency, and monotonous declarative sentences

### Knowledge Base Intelligence

- [ ] **KNOW-01**: Knowledge injection supports fuzzy matching (edit distance ≤2), automatic alias extraction from character descriptions, and pronoun coreference resolution
- [ ] **KNOW-02**: User can define and manage character relationships (mentor, enemy, family, lover, etc.) in a relationship graph, and related info is injected into AI prompts
- [ ] **KNOW-03**: Knowledge injection prioritizes chapter-active characters over related characters over global characters, with adaptive token budget allocation
- [ ] **KNOW-04**: User receives real-time foreshadowing reminders in the editor sidebar when writing chapters involving characters or locations associated with unresolved foreshadowing entries

### Long-form Intelligence

- [ ] **LFIN-01**: AI context chain includes previous 3 chapter summaries (decreasing detail), current chapter outline/goal, and story arc position (rising/falling/climax)
- [ ] **LFIN-02**: User can engage in multi-turn AI conversations (e.g., "polish this" → "too flowery" → "better") with conversation history managed within token budget
- [ ] **LFIN-03**: System offers 3 directional plot continuation suggestions based on current story context; user selects a direction before AI generates expanded content

### Editor & UX Enhancement

- [ ] **EDIT-01**: AI floating toolbar adds expand (detail enhancement), compress (text condensation), dialogue generation, and scene description operations alongside existing tone rewrite and polish
- [ ] **EDIT-02**: AI operation history maintains up to 20 undo steps with cross-operation comparison (view versions A/B/C side by side)
- [ ] **EDIT-03**: Web build renders correctly on narrow viewports with responsive layout adaptations for mobile web testing
- [ ] **EDIT-04**: Writing progress dashboard shows daily creation rhythm heatmap, AI-assisted vs manual ratio visualization, chapter completion tracking, and estimated completion time

## v1.5 Requirements (Deferred)

### Multi-turn Dialog Persistence
- **LFIN-05**: AI conversation history persists across editor sessions within a chapter

### Collaborative Editing
- **COLLAB-01**: Multiple users can edit the same manuscript simultaneously

### Cloud Sync
- **SYNC-01**: Manuscripts and settings sync across devices via cloud storage

### iOS/macOS Support
- **PLATFORM-01**: MuseFlow runs natively on iOS and macOS

## Out of Scope

| Feature | Reason |
|---------|--------|
| 一键生成全书 | Violates core principle — author must remain in control |
| 云端同步/账户系统 | Local-first privacy is a product constraint; defer to v1.5+ |
| iOS/macOS平台 | Focus remains on Windows/Android/Web |
| 实时协作/多人编辑 | Single-author creative tool |
| 多模型微调/训练 | Beyond product positioning |
| 通用AI聊天 | Must remain a focused creative writing tool |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| STYLE-01 | TBD | Pending |
| STYLE-02 | TBD | Pending |
| STYLE-03 | TBD | Pending |
| STYLE-04 | TBD | Pending |
| AISC-01 | TBD | Pending |
| AISC-02 | TBD | Pending |
| AISC-03 | TBD | Pending |
| AISC-04 | TBD | Pending |
| KNOW-01 | TBD | Pending |
| KNOW-02 | TBD | Pending |
| KNOW-03 | TBD | Pending |
| KNOW-04 | TBD | Pending |
| LFIN-01 | TBD | Pending |
| LFIN-02 | TBD | Pending |
| LFIN-03 | TBD | Pending |
| EDIT-01 | TBD | Pending |
| EDIT-02 | TBD | Pending |
| EDIT-03 | TBD | Pending |
| EDIT-04 | TBD | Pending |

**Coverage:**
- v1.4 requirements: 18 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 18 ⚠️

---
*Requirements defined: 2026-06-11*
*Last updated: 2026-06-11 after v1.4 milestone initialization*
