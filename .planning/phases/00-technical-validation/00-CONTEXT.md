# Phase 0: Technical Validation - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Validate Flutter editor viability for Chinese novel writing on Windows — benchmark super_editor AND appflowy_editor against CJK IME compatibility, large document performance, and API extensibility. Verify all core package dependencies resolve without conflict. Validate SSE streaming from real AI APIs into the editor without jank.

This phase produces a **reusable Flutter project skeleton** (not a throwaway spike) with all dependencies installed, ready for Phase 1 to build upon.

**In scope:**
- Dual-editor benchmark (super_editor vs appflowy_editor)
- CJK IME validation (automated + manual)
- Package compatibility verification (all CLAUDE.md dependencies)
- SSE streaming validation via real OpenAI/DeepSeek API
- Flutter project scaffold with four-layer architecture

**Out of scope:**
- Any feature development (capture UI, settings, knowledge base, etc.)
- Anti-AI-scent validation (Phase 2)
- Android testing (Phase 6)
- Ollama local model testing

</domain>

<decisions>
## Implementation Decisions

### Editor Benchmark Strategy
- **D-01:** Test BOTH super_editor AND appflowy_editor with identical benchmark suite for direct comparison
- **D-02:** Weighted scoring: IME compatibility 40% + large document performance 30% + API extensibility 20% + community activity 10%
- **D-03:** API extensibility evaluates three capabilities: custom block components (story structure overlays), floating toolbar API (AI action menu), document model queryability (provenance tracking, marker location)
- **D-04:** Editor selection result determines which editor proceeds to Phase 1; update CLAUDE.md tech stack accordingly

### Project Scaffold
- **D-05:** Create full Flutter project skeleton (not throwaway test harness) — Phase 1 builds directly on it
- **D-06:** Install ALL dependencies from CLAUDE.md tech stack in one step (validates package compatibility as a byproduct)
- **D-07:** Directory structure follows CLAUDE.md four-layer architecture: `core/domain/`, `core/application/`, `core/infrastructure/`, `core/presentation/`, `features/`, `shared/`

### IME Testing
- **D-08:** Dual validation: automated TextEditingDelta composition simulation + manual keyboard testing
- **D-09:** Manual testing covers 3 input methods only: Sogou Pinyin, Wubi, Microsoft Pinyin (per ROADMAP.md)
- **D-10:** Automated tests simulate composing → committed text lifecycle to catch regressions

### SSE Streaming Validation
- **D-11:** Full end-to-end: connect to real OpenAI or DeepSeek API, stream SSE tokens, insert into editor
- **D-12:** Do NOT test Ollama (local environment constraints) — Ollama validation deferred to Phase 6
- **D-13:** User must provide an API Key (OpenAI or DeepSeek) for streaming tests

### Claude's Discretion
- Exact benchmark methodology (document size steps, frame time measurement approach)
- Specific test text generation for Chinese document benchmarks
- Automated test structure and naming conventions
- How to present benchmark comparison results

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Definition
- `.planning/PROJECT.md` — Project vision, core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — Full v1 requirements (50 items) with traceability; Phase 0 validates TECH-02, EDIT-01, EDIT-04
- `.planning/ROADMAP.md` §Phase 0 — Success criteria (4 items), risks, plan list (00-01 to 00-03)
- `.planning/STATE.md` — Current project position (Phase 0, ready to plan)

### Architecture & Standards
- `CLAUDE.md` §Technology Stack — Full dependency list, version constraints, "What NOT to Use" section
- `CLAUDE.md` §Architecture — Four-layer architecture rules, directory structure, dependency direction constraints
- `.claude/rules/02-museflow-architecture.md` — Layer responsibilities, directory structure, key constraints
- `.claude/rules/03-flutter-standards.md` — Immutability, Widget rules, Riverpod patterns, testing standards

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code

### Established Patterns
- Four-layer Clean Architecture: `domain/ → application/ → infrastructure/ → presentation/`
- Riverpod with code generation (`@riverpod` annotation, `AsyncNotifier`)
- Freezed for immutable data classes with `copyWith`
- Hive CE for NoSQL storage with encryption

### Integration Points
- Editor is the foundation — Phase 1 (editor integration), Phase 2 (AI streaming), Phase 3 (floating toolbar) all depend on this choice
- Package compatibility affects all subsequent phases

</code_context>

<specifics>
## Specific Ideas

- Editor comparison should produce a concrete scorecard/decision matrix, not just pass/fail
- The winning editor's API patterns should be documented during the spike to inform Phase 1 planning
- Automated IME tests should be written as reusable widget tests, not throwaway scripts

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 0-Technical Validation*
*Context gathered: 2026-05-31*
