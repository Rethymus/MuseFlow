# Feature Landscape: v1.3 Validation Features

**Domain:** User-perspective validation of a creative writing app via real novel production
**Researched:** 2026-06-06
**Milestone:** v1.3 -- 100-chapter cultivation novel validation pass

---

## Context

v1.3 is not a feature-build milestone. It is a validation milestone: use MuseFlow as a real author to write a 100-chapter (~10K word) cultivation novel, exercising every feature in production conditions, and produce a pain-point report plus automated tests for discovered issues.

All features below already ship in the codebase (v1.0-v1.2). The "features" here are the validation activities, test categories, and deliverables needed to certify the app works end-to-end.

---

## User Journey Map (Validation Sequence)

The validation follows the actual creative workflow a MuseFlow user performs, from cold start to finished export.

```
Step 1: First Launch & Onboarding
  |-- Onboarding wizard (4-step)
  |-- Genre template selection
  |-- World + character creation from template
  |-- AI opening generation (3 variants)
  v
Step 2: World-Building (Knowledge Base)
  |-- Create/edit WorldSettings
  |-- Create/edit CharacterCards
  |-- Generate Skill documents (AI world-building)
  |-- Verify knowledge injection into AI context
  v
Step 3: Fragment Capture & Synthesis
  |-- Bullet-note capture (碎片捕捉)
  |-- AI synthesis from fragments
  |-- Edit synthesized output
  |-- Insert into editor
  v
Step 4: Chapter Management (100 chapters)
  |-- Create chapters (CRUD)
  |-- Reorder chapters (drag)
  |-- Split chapters
  |-- Merge chapters
  |-- Duplicate chapters
  |-- Delete + soft-delete recovery
  |-- Navigate via sidebar
  v
Step 5: Immersive Editing (per chapter, x100)
  |-- Rich text editing (super_editor)
  |-- Floating AI toolbar: tone rewrite
  |-- Floating AI toolbar: paragraph polish
  |-- Floating AI toolbar: free input
  |-- Accept/reject AI suggestions (provenance tracking)
  |-- Selective undo
  |-- Context anchors
  v
Step 6: Story Structure (across chapters)
  |-- Plot node creation/management
  |-- Foreshadowing: plant -> track -> resolve
  |-- Logic loop detection (AI analysis)
  |-- Consistency guardian (character behavior)
  |-- Story arc visualization (graphview)
  v
Step 7: Format & Export
  |-- Format cleaning (punctuation/Markdown/typeset)
  |-- Preview + confirm cleaning
  |-- Export as Markdown (chapter-aware)
  |-- Export as TXT (chapter-aware)
  |-- Export as JSON
  v
Step 8: Statistics & Monitoring
  |-- Writing stats dashboard (global + project)
  |-- Token consumption audit (full tracking)
  |-- Achievement badges
  |-- Writing speed/streak tracking
  v
Step 9: Pain Point Report & Automated Tests
  |-- Document all defects found
  |-- Write Dart scripts for reproducible issues
  |-- Write Flutter integration tests for UI bugs
  |-- Produce cost analysis (token usage)
```

---

## Table Stakes (Must Validate)

These are the validation activities that must complete for v1.3 to ship. Missing any = incomplete validation.

### V1: Full User Journey Walkthrough

| Validation Activity | What to Verify | Depends On | Complexity | Notes |
|---------------------|----------------|------------|------------|-------|
| Cold-start to first-export complete flow | Every screen, every button, every navigation works in sequence | All features | High | Single continuous session recording pain points |
| Onboarding wizard (first-launch) | 4-step flow, skip/resume, genre template auto-load | Onboarding, Templates | Low | Test on clean state; verify redirect logic |
| AI opening generation | 3 variant styles generated, selectable, insertable | AI Provider, Editor | Medium | Requires live API call; verify context injection |
| Fragment capture to synthesis | Bullet notes -> AI synthesis -> edit -> insert | Capture, AI, Editor | Medium | Core workflow; test with real Chinese prose fragments |
| Floating AI toolbar (3 actions) | Tone rewrite, paragraph polish, free input all produce output | Editor, AI | High | Select Chinese text; verify AI response quality + anti-AI-scent |
| Provenance tracking | Accept/reject AI suggestions shows diff correctly | Editor | Medium | Verify diff display, selective undo works after accept/reject |

**Dependencies:** V1 requires a working AI provider with valid API key. Token costs will be real.

### V2: Chapter Management at Scale (100 Chapters)

| Validation Activity | What to Verify | Depends On | Complexity | Notes |
|---------------------|----------------|------------|------------|-------|
| Create 100 chapters | Performance stays acceptable at scale | Manuscript, Chapter repos | Medium | Watch for Hive box growth, sidebar rendering lag |
| Drag-reorder chapters | Sort order persists, no data loss on reorder | Chapter sidebar, Editor | Medium | Test reorder at various positions (start/middle/end) |
| Split chapter | Content divides correctly, both halves preserved | Chapter ops, Editor | Medium | Split at paragraph/character boundaries |
| Merge chapters | Content concatenates correctly, ordering preserved | Chapter ops, Editor | Medium | Merge adjacent chapters with different content |
| Duplicate chapter | Copy creates independent chapter with same content | Chapter ops | Low | Verify edits to duplicate do not affect original |
| Delete + soft-delete | Chapter moves to trash, 30-day purge logic | Chapter repos | Low | Verify cascade behavior |
| Chapter switching in editor | Switching chapters loads correct content, saves previous | EditorWithSidebar | High | Most common operation at 100-chapter scale; test rapid switching |
| Auto-save reliability | 2s debounce + forceSave on transition | ChapterAutoSave | High | Critical for data safety; verify no content loss on fast switching |

**Dependencies:** V2 depends on having a manuscript with 100+ chapters. Build up incrementally during writing.

### V3: Story Structure Integrity

| Validation Activity | What to Verify | Depends On | Complexity | Notes |
|---------------------|----------------|------------|------------|-------|
| Foreshadowing plant-track-resolve cycle | Plant in ch1, track through ch50, resolve in ch80 | Foreshadowing, PlotNode | High | Cross-chapter reference integrity is the key test |
| Logic loop detection | AI identifies unresolved plot threads | Logic guardian, AI | Medium | Verify AI analysis produces meaningful results |
| Consistency guardian | Character behavior stays consistent across 100 chapters | Guardian, CharacterCard, AI | High | Long-range consistency is the hardest validation |
| Story arc visualization with 100 nodes | Graph renders, zoom/pan works, drag persists | graphview, PlotNode | Medium | Performance at scale; verify no rendering freeze |

**Dependencies:** V3 requires chapters with planted foreshadowing and plot nodes -- built up during the writing process.

### V4: Export Fidelity

| Validation Activity | What to Verify | Depends On | Complexity | Notes |
|---------------------|----------------|------------|------------|-------|
| Markdown export (chapter-aware) | Chapter structure preserved, content matches editor | ExportService | Low | Diff editor content vs exported file |
| TXT export (chapter-aware) | Plain text structure preserved | ExportService | Low | Verify chapter separators |
| JSON export | Complete data round-trip | ExportService | Low | Verify JSON parses back correctly |
| Format cleaning | Punctuation fix, Markdown residue removal, typesetting | FormatCleaner | Medium | Test with deliberately messy Chinese text |
| Export of 100-chapter manuscript | Performance at scale, no truncation | ExportService | Medium | Large export stress test |

**Dependencies:** V4 requires a complete manuscript. Can be tested incrementally as chapters accumulate.

### V5: Token Consumption Audit

| Validation Activity | What to Verify | Depends On | Complexity | Notes |
|---------------------|----------------|------------|------------|-------|
| Track tokens per AI call | Capture input/output tokens for every API call | AI adapter, openai_dart | Medium | Need instrumentation in AI adapter layer |
| Aggregate by operation type | Synthesis vs toolbar vs opening vs world-building | Token tracking | Medium | Categorize token usage by feature |
| Cost projection for 100K-word novel | Extrapolate from ~10K-word validation to full novel | Token data | Low | Simple math: (10K cost) * 10 |
| Provider comparison (optional) | Same operation cost across OpenAI/DeepSeek/Ollama | Multi-provider | Low | Nice-to-have, depends on available API keys |

**Dependencies:** V5 requires instrumentation code. May need a lightweight logging wrapper in the AI adapter layer.

---

## Differentiators (High-Value Validation)

These validation activities go beyond basic pass/fail and produce insights that differentiate MuseFlow from competitors.

| Validation Activity | Value Proposition | Complexity | Notes |
|---------------------|-------------------|------------|-------|
| Anti-AI-scent effectiveness with real Chinese prose | Prove or disprove the core product claim | High | Collect AI-generated paragraphs; blind-test with human readers if possible; compare with/without anti-AI-scent |
| Knowledge injection relevance scoring | Verify AI actually uses injected knowledge, not ignores it | Medium | Test with and without knowledge injection; compare output quality |
| Skill enforcement deviation detection | Trigger deliberate deviations; verify AI catches them | Medium | Write text contradicting established world rules |
| Writing stats accuracy under real workload | Verify word counts, AI ratio, streak calculations match reality | Medium | Known tech debt in stats (CR-01 stale streak, CR-02 nullable copyWith) |
| Large document editor performance (100 chapters) | Verify super_editor handles 100-chapter switching without lag | High | Scrivener's known failure mode; validate MuseFlow avoids it |
| Data loss resistance during rapid operations | Fast chapter switching + editing + AI calls simultaneously | High | Most critical reliability test; writers cannot lose work |

---

## Anti-Features (Explicitly NOT in Scope)

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Performance benchmarking framework | Overkill for validation milestone; manual observation sufficient | Record subjective performance notes (fast/acceptable/laggy) |
| Accessibility audit | Important but separate milestone; not the focus of creative validation | Note accessibility issues in pain-point report if observed |
| Multi-provider parallel testing | Each provider needs separate API key and cost; diminishing returns | Test primary provider (DeepSeek or OpenAI); note provider-specific issues |
| Automated regression test suite for ALL features | Too broad for validation milestone; focus on discovered pain points | Write targeted tests only for bugs actually found during validation |
| Visual/UI design review | Subjective, not a reliability concern | Note glaring issues in pain-point report |
| Load testing with 1000+ chapters | Beyond v1.3 scope; 100 chapters is the declared target | Note performance trajectory; extrapolate if possible |
| Real device testing (Windows/Android physical) | Still deferred from v1.0; requires hardware access | Continue noting as deferred; test on WSL/ emulator |

---

## Feature Dependencies (Validation Execution Order)

```
V1 (User Journey) ──────────────────────────────────────────────
  |-- V1a: Onboarding + Opening     (no deps, first activity)
  |-- V1b: Capture + Synthesis      (after onboarding)
  |-- V1c: AI Toolbar               (after chapter content exists)
  v
V2 (Chapter Management) ────────────────────────────────────────
  |-- V2a: Create 100 chapters      (during writing process)
  |-- V2b: Reorder/split/merge      (after 10+ chapters exist)
  |-- V2c: Auto-save reliability    (continuous throughout)
  v
V3 (Story Structure) ───────────────────────────────────────────
  |-- V3a: Foreshadowing cycle      (needs 30+ chapters planted)
  |-- V3b: Logic/consistency guard  (needs 50+ chapters)
  |-- V3c: Visualization at scale   (needs 20+ plot nodes)
  v
V4 (Export) ─────────────────────────────────────────────────────
  |-- V4a: Format cleaning          (needs messy content)
  |-- V4b: Three-format export      (needs complete manuscript)
  |-- V4c: Large export stress      (needs 100 chapters)
  v
V5 (Token Audit) ───────────────────────────────────────────────
  |-- V5a: Token tracking setup     (before any AI calls, or retroactive)
  |-- V5b: Cost analysis            (after all writing complete)
```

**Critical path:** V5a (token tracking setup) should happen FIRST or very early, otherwise token data for early AI calls is lost. If instrumentation is added late, only post-instrumentation calls are tracked.

---

## Known Risks from Prior Milestones

These are pre-existing issues that validation will stress-test.

| Risk | Source | Validation Impact |
|------|--------|-------------------|
| Anti-AI-scent effectiveness unproven | PROJECT.md Known Issues | V1c will be first real test |
| Stats bugs (CR-01 stale streak, CR-02 nullable copyWith) | v1.1 audit | V5 may surface these |
| WR-02 counters cleared before async write | v1.1 audit | V5 token tracking could trigger this |
| 5 gap-closure rounds in v1.2 | v1.2 retrospective | V2c auto-save is the most stressed feature |
| Template prose quality unreviewed | v1.1 audit | V1a onboarding uses templates |
| Phase 10 dart:ui in domain layer | v1.1 audit | V3c visualization at scale |
| 9 pending human verification items | v1.1 audit | All will be touched during validation |

---

## MVP Recommendation (Validation Priority)

**Priority 1 -- Must complete:**
1. V2a: Create and manage 100 chapters (proves core reliability)
2. V1c: AI toolbar validation with real Chinese prose (proves core value)
3. V2c: Auto-save reliability during rapid chapter operations (proves data safety)
4. V4b: Three-format export of complete manuscript (proves output quality)

**Priority 2 -- Should complete:**
5. V3a: Foreshadowing plant-track-resolve across chapters (proves differentiation)
6. V5: Token consumption audit with cost projection (proves economic viability)
7. V1d: Anti-AI-scent blind test (proves or disproves product soul)

**Priority 3 -- Nice to have:**
8. V3c: Visualization at scale (proves graphview handles load)
9. V1a: Full onboarding replay on clean state (proves first-run experience)
10. Provider comparison cost analysis

**Defer:** Multi-provider testing, real device testing, accessibility audit, 1000+ chapter stress test.

---

## Expected Validation Outcomes

### Deliverables

| Deliverable | Format | Value |
|-------------|--------|-------|
| Pain-point report | Structured markdown (defects + UX issues + missing features) | Input for v1.4 planning |
| Automated tests | Dart test files (unit + widget + integration) | Regression protection for discovered bugs |
| Token cost analysis | Markdown with tables/charts | Economic viability data for target users |
| 100-chapter cultivation novel | ~10K words, Chinese prose | Proof the app produces real creative output |
| Three-format exports | .md + .txt + .json files | Proof of export fidelity |

### Expected Findings (Hypotheses)

Based on codebase analysis and industry patterns:

1. **Auto-save edge cases at scale** -- v1.2 had 5 gap-closure rounds around lifecycle. 100-chapter stress will likely surface 2-3 more edge cases.
2. **Anti-AI-scent partial effectiveness** -- Prompt-based approach will reduce but not eliminate AI patterns in Chinese prose. Expect 60-70% effectiveness.
3. **Knowledge injection relevance** -- NameIndex matcher works well for exact name matches but may miss pronouns or nicknames across 100 chapters.
4. **Editor performance plateau** -- super_editor handles individual chapters well, but sidebar rendering 100 chapter titles may need virtualization.
5. **Token cost surprises** -- Knowledge injection inflates prompt tokens significantly. Cost per chapter may be higher than expected due to growing world-building context.
6. **Export formatting edge cases** -- 100 chapters with mixed formatting (AI + manual edits) will expose format cleaning gaps.

---

## Sources

| Source | Confidence | What It Informed |
|--------|------------|------------------|
| Project codebase analysis (app.dart routing, 183 source files, 117 test files) | HIGH | User journey map, feature dependencies, test patterns |
| v1.0/v1.1/v1.2 milestone audits and retrospectives | HIGH | Known risks, tech debt, gap patterns |
| PROJECT.md active requirements list | HIGH | Validation scope boundaries |
| Scrivener large-project failure reports (Literature & Latte forum, KBoards) | MEDIUM | What breaks at scale in writing tools (typing lag, compile bugs, data loss) |
| JetBrains dogfooding methodology (JetBrains Blog) | MEDIUM | Validation approach structure |
| FinOps generative AI cost tracking (finops.org) | MEDIUM | Token audit methodology |
| Flutter integration testing docs (docs.flutter.dev) | HIGH | Test infrastructure approach |
| Stack Overflow complex Flutter flow testing | LOW | Integration test patterns for multi-screen workflows |

---

*Features researched: 2026-06-06 for v1.3 validation milestone*
