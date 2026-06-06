# Project Research Summary

**Project:** MuseFlow v1.3 -- User-Perspective Full-Flow Validation
**Domain:** AI-assisted Chinese creative writing tool validation via 100-chapter xianxia novel production
**Researched:** 2026-06-06
**Confidence:** HIGH

## Executive Summary

MuseFlow v1.3 is a validation milestone, not a feature-build milestone. The goal is to use the app as a real author to write a 100-chapter (~10K word) cultivation novel, exercising every feature in production conditions. The validation covers nine user-journey stages from cold-start onboarding through export, with a token consumption audit running throughout. This is dogfooding methodology applied systematically: the deliverables are a pain-point report, automated regression tests, and a token cost analysis.

The recommended approach is a two-track strategy. **Track A** is the creative track: manually write the 100-chapter novel using MuseFlow, logging every interruption, UX friction point, and data-loss scare in a structured interruption log. **Track B** is the automation track: build token auditing infrastructure into the existing Clean Architecture, then write Dart test scripts that replay the core flows (chapter CRUD, fragment synthesis, export) with both fake and real AI adapters. Track B's infrastructure must be built before Track A begins in earnest, because token data from early AI calls is irrecoverable if instrumentation is added late.

The dominant risk is the **hidden cost multiplier**. Every editor AI operation silently triggers a deviation detection AI call (`unawaited` fire-and-forget in `editor_ai_notifier.dart`). Combined with the 7-layer prompt middleware chain that injects ~2,000-4,500 tokens of context overhead per call, a single chapter with synthesis + rewrite + polish generates 6 API calls, not the 3 the user sees. Over 100 chapters on GPT-4o this hits $5-6, and with retries, guardian checks, and multi-model testing, costs could reach $20-30. Token auditing instrumentation must be the first thing built.

## Key Findings

### Recommended Stack

The existing production stack (Flutter 3.44.0, super_editor, Riverpod, Hive CE, openai_dart) is validated and out of scope. The only addition needed for v1.3 is **mocktail ^1.0.4** as a dev dependency, replacing hand-rolled fakes in integration tests that need call verification and per-invocation stubbing. Everything else -- `integration_test` SDK, `dart:io` for automation scripts, transitive `test`/`args`/`path` packages -- is already available. Patrol was rejected (no Windows support), mockito was rejected (build_runner overhead per mock class), and golden/screenshot tools were rejected (v1.3 validates data correctness, not pixel fidelity).

**Core additions:**
- **mocktail ^1.0.4**: mocking library for integration test provider overrides -- zero codegen, supports `verify()` for call-count assertions needed by token audit tests
- **integration_test/ SDK** (already present): full user-journey tests via `IntegrationTestWidgetsFlutterBinding` on Windows desktop
- **test/automation/ scripts** (new directory): standalone Dart tests using `ProviderContainer` without widget tree, for the 100-chapter orchestration loop

### Expected Features (Validation Activities)

All features below ship in the codebase from v1.0-v1.2. The "features" here are validation activities organized by dependency order.

**Must validate (table stakes):**
- V2a: Create and manage 100 chapters -- proves core reliability at scale
- V1c: Floating AI toolbar (tone rewrite, paragraph polish, free input) with real Chinese prose -- proves core value
- V2c: Auto-save reliability during rapid chapter operations -- proves data safety
- V4b: Three-format export (Markdown/TXT/JSON) of complete manuscript -- proves output quality

**Should validate (differentiators):**
- V3a: Foreshadowing plant-track-resolve across chapters -- proves structural story management works
- V5: Token consumption audit with cost projection -- proves economic viability for target users
- Anti-AI-scent blind-read test -- proves or disproves the product's soul claim

**Defer:**
- Multi-provider parallel testing, real device testing, accessibility audit, 1000+ chapter stress test

### Architecture Approach

Token auditing and test automation are **observer-sidecar patterns**: they tap into existing streams and repositories without modifying domain logic. The `TokenAuditRecord` is a separate domain entity in its own Hive box with `chapterId` as a foreign-key reference -- it is never mixed into `Chapter` or `Manuscript` entities. Token counting happens at the notifier level (where business context like operation type and chapter ID is available), not inside `OpenAIAdapter` (which lacks that context) and not as a `PromptMiddleware` (which runs before the API call and cannot measure output).

**Major components (new):**
1. **TokenAuditRecord + TokenAuditRepository** -- domain entity and Hive persistence for per-call token records
2. **TokenAuditNotifier** -- aggregates audit records for presentation (total cost, per-chapter breakdown)
3. **Automation test scripts** -- `test/automation/` with `ScenarioRunner`, `AssertionCollector`, `FakeXianxiaAdapter` for replayable validation

**Modified components (minimal):**
- `SynthesisNotifier._fetchKeyAndStream()` and `EditorAINotifier._fetchKeyAndStream()` -- add token counting before/after stream
- `providers.dart` -- register 2-3 new providers
- `writing_stats_page.dart` -- add token audit summary section

**Explicitly unchanged:** `OpenAIAdapter`, `PromptPipeline`/`PromptMiddleware`, `TokenBudgetCalculator`, `ChapterAutoSave`, all domain entities (`Chapter`, `Manuscript`), `WritingStatsCollector`.

### Critical Pitfalls

1. **Token consumption death spiral** -- Hidden deviation detection calls double API costs. Every editor AI operation triggers an unawaited deviation check. Over 100 chapters this means 600 API calls, not 300. Prevent by instrumenting token counting per operation before starting, and making deviation detection opt-in during validation.

2. **Knowledge base consistency erosion** -- Character cards and world settings are static data that go stale as the story evolves. A character introduced as mortal in chapter 1 becomes a Golden Core cultivator by chapter 50, but the KB still says mortal unless manually updated. Prevent with mandatory KB review every 10 chapters.

3. **Anti-AI-scent bypass on structural patterns** -- The `AntiAIScentProcessor` catches phrase-level cliches (14-entry synonym map) but misses sentence rhythm uniformity, transition formula, and cultivation-specific structural patterns that accumulate over 100 chapters. Prevent by expanding the banned list with xianxia-specific cliches and running blind-read tests every 25 chapters.

4. **Test script assumptions break with real creative data** -- Automated scripts written against predictable data break on mixed CJK punctuation, markdown remnants in AI output, name variations (formal vs diminutive), and variable-length chapters. Prevent by generating test fixtures from the first 10 real chapters before trusting the automation suite.

5. **Context anchor and chapter summary staleness** -- Chapter summaries injected into AI prompts drift from actual content as chapters are rewritten, split, or reordered. By chapter 80, the "previous chapter summary" may describe events that no longer exist. Prevent with manual summary verification at milestones (chapters 25, 50, 75).

## Implications for Roadmap

Based on combined research, the validation should proceed in 5 phases ordered by dependency and risk:

### Phase 1: Token Audit Infrastructure
**Rationale:** Token auditing must be built before any AI calls happen, because per-call token data is irrecoverable retroactively. The hidden deviation detection calls (Pitfall 1) make this the highest-priority infrastructure.
**Delivers:** `TokenAuditRecord`, `TokenAuditRepository`, Hive box, unit tests, and integration into `SynthesisNotifier` + `EditorAINotifier`
**Addresses:** V5a (token tracking setup)
**Avoids:** Pitfall 1 (token death spiral) by making costs visible from the first call
**Research flag:** Standard patterns -- follows existing `WritingStatsCollector`/`WritingStatsRepository` conventions exactly

### Phase 2: Automation Test Harness
**Rationale:** Build the `FakeXianxiaAdapter`, `ScenarioRunner`, and `AssertionCollector` before writing chapters. This enables replayable validation and catches infrastructure bugs early. Can be built in parallel with Phase 1.
**Delivers:** `test/automation/` directory with 5 files, `ProviderContainer` helper, canned xianxia text fixtures
**Addresses:** Test automation foundation for all subsequent phases
**Avoids:** Pitfall 4 (test assumptions) by generating fixtures from first 10 real chapters
**Research flag:** Standard patterns -- extends existing `_FakeOpenAIAdapter` pattern from `synthesis_notifier_test.dart`

### Phase 3: World-Building and First 30 Chapters
**Rationale:** The world-building phase seeds the knowledge base that all subsequent AI operations depend on. Writing the first 30 chapters validates the core creative loop (fragment capture -> synthesis -> editing -> save) and generates enough data to test at scale.
**Delivers:** Xianxia knowledge base (characters, world settings, skills), first 30 chapters of the novel, initial pain-point log entries
**Addresses:** V1a (onboarding), V1b (capture + synthesis), V1c (AI toolbar), V2a (chapter CRUD), V2c (auto-save), V3a (foreshadowing planting), V5b (token data collection starts)
**Avoids:** Pitfall 2 (KB staleness) via mandatory review at chapter 30, Pitfall 3 (anti-AI-scent) via blind-read test at chapter 25
**Research flag:** Needs deeper research -- the creative writing workflow is inherently unpredictable; plan for iterative pain-point triage

### Phase 4: Full Manuscript (Chapters 31-100) and Story Structure
**Rationale:** Chapters 31-100 stress-test the features that only matter at scale: foreshadowing resolution, consistency guardian, visualization with 50+ nodes, and 100-chapter export. Story structure validation requires accumulated plot threads.
**Delivers:** Complete 100-chapter manuscript, foreshadowing resolution validation, consistency guardian results, story arc visualization at scale, three-format export validation
**Addresses:** V2b (reorder/split/merge), V3a (foreshadowing resolution), V3b (logic/consistency guard), V3c (visualization at 100 nodes), V4a (format cleaning), V4b (three-format export), V4c (large export stress test)
**Avoids:** Pitfall 5 (summary staleness) via manual verification at chapters 50, 75, Pitfall 7 (foreshadowing fatigue) by setting xianxia-appropriate thresholds, Pitfall 9 (visualization overload) by testing at 50 nodes before continuing to 100
**Research flag:** Needs deeper research -- story structure at 100 chapters has no established patterns in the codebase; Phase 10 (v1.1) built the graph but never tested at this scale

### Phase 5: Analysis, Pain-Point Report, and Automated Tests
**Rationale:** Final synthesis of all validation data. The token audit report, pain-point report, and automated regression tests for discovered bugs are the milestone's ship deliverables.
**Delivers:** Token cost analysis with per-chapter breakdown, structured pain-point report (bugs / UX friction / feature gaps), automated regression tests for discovered issues, 100-chapter novel as proof artifact, three-format exported files
**Addresses:** V5b (cost analysis), V1d (anti-AI-scent effectiveness assessment), all remaining validation deliverables
**Avoids:** Pitfall 8 (single-model bias) by writing at least 10 chapters with alternative models during analysis phase, Pitfall 10 (validation confound) by using the structured interruption log to separate bugs from creative challenges
**Research flag:** Standard patterns -- report generation follows established markdown conventions; test writing follows existing unit/widget test patterns

### Phase Ordering Rationale

- Phase 1 (token audit) must come first because token data is irrecoverable if AI calls happen before instrumentation is in place. The hidden deviation detection calls make this a budget concern, not just a nice-to-have metric.
- Phase 2 (automation harness) should run in parallel with Phase 1 because it has zero coupling to token audit code -- it is pure test infrastructure.
- Phase 3 (first 30 chapters) cannot start until Phase 1 is complete, because every chapter involves AI calls that must be audited. The 30-chapter boundary provides the first meaningful checkpoint for KB freshness, foreshadowing tracking, and anti-AI-scent effectiveness.
- Phase 4 (chapters 31-100) depends on Phase 3's accumulated state. The scale-dependent features (100-node visualization, 100-chapter export, cross-chapter consistency) only become testable with sufficient chapter count.
- Phase 5 (analysis) is the synthesis phase that consumes data from all prior phases. It must come last.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** The creative writing workflow is inherently human-driven. The plan needs to define how to structure the "manual writing" sessions alongside automated validation, and how to handle the tension between "write naturally" and "test systematically."
- **Phase 4:** Story structure visualization at 100 nodes has never been tested. The plan should budget time for performance debugging if the graph becomes unusable.

Phases with standard patterns (skip additional research):
- **Phase 1:** Follows `WritingStatsCollector`/`WritingStatsRepository` conventions exactly. Well-documented in codebase.
- **Phase 2:** Extends existing `_FakeOpenAIAdapter` pattern. Well-documented in `synthesis_notifier_test.dart`.
- **Phase 5:** Report generation and regression test writing follow established project conventions.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Only one new dependency (mocktail). Existing infrastructure verified with 930+ passing tests. Flutter integration test SDK confirmed working on Windows. |
| Features | HIGH | All features ship in v1.0-v1.2. Validation activities are clearly scoped with dependency ordering. Feature dependencies mapped from codebase analysis. |
| Architecture | HIGH | Observer-sidecar pattern is clean and follows existing codebase conventions. Modified components are minimal (2 notifiers + providers.dart + 1 page). Direct codebase analysis of 50+ files confirms integration points. |
| Pitfalls | HIGH | Critical pitfalls (token spiral, KB staleness, anti-AI-scent bypass) are codebase-verified with specific file/line references. Token cost estimates backed by actual middleware budget caps and current model pricing. |

**Overall confidence:** HIGH

### Gaps to Address

- **Anti-AI-scent effectiveness for xianxia prose is unproven.** The 14-entry synonym map targets general Chinese AI patterns, not genre-specific ones. The validation itself is the first real test. The plan should budget time to expand the banned phrase list before writing begins.
- **Chapter summary regeneration mechanism does not exist.** Summaries go stale when chapters are edited, split, or reordered. The plan should define whether to build an auto-regeneration feature or rely on manual verification at milestones.
- **Deviation detection scope is limited to skill documents.** It does not check against character cards or world settings. The plan should decide whether to extend deviation detection scope or accept this limitation during validation.
- **Token estimation accuracy (1.8x multiplier for Chinese) is approximate.** OpenAI's `stream_options: { include_usage: true }` could provide exact counts but requires adapter changes. The plan should decide whether estimated tokens are sufficient for v1.3 or if exact counts are needed.
- **Real creative data may surface unknown edge cases.** Mixed CJK punctuation, nested dialogue, and markdown remnants from AI output are predicted but not yet observed at scale. The first 10 chapters will reveal the actual edge case landscape.

## Sources

### Primary (HIGH confidence)
- Project codebase analysis -- 183 source files, 117 test files, 930+ passing tests, all architecture decisions verified against actual code
- pub.dev API (live queries) -- mocktail ^1.0.4 verified current
- Context7 / Flutter integration_test docs -- Windows desktop support, binding API, performance profiling
- Context7 / mocktail docs -- zero-codegen API, verify/capture patterns
- Context7 / Riverpod docs -- ProviderContainer override patterns, AsyncNotifier conventions
- DeepSeek API pricing page -- per-token costs for budget projections
- v1.0/v1.1/v1.2 milestone audits and retrospectives -- known risks, tech debt, gap patterns

### Secondary (MEDIUM confidence)
- "Context Is a Budget" (foojay.io) -- token optimization patterns for context engineering
- "Lost in Stories: Consistency Bugs in Long Story Generation by LLMs" (arXiv) -- academic study on LLM consistency degradation over long narratives
- "Token Cost Trap: Why AI Agent ROI Breaks at Scale" (Medium) -- quadratic cost growth patterns in agent loops
- "C-ReD: Chinese AI Text Detection Benchmark" (arXiv) -- systematic approaches to Chinese AI text detection
- Scrivener large-project failure reports (Literature & Latte forum, KBoards) -- what breaks at scale in writing tools
- JetBrains dogfooding methodology (JetBrains Blog) -- validation approach structure
- Hive CE GitHub issues -- reliability concerns with sustained write loads

### Tertiary (LOW confidence)
- "Chinese Language Tokenization Efficiency" (arXiv) -- Chinese token overhead ratios vary by model
- "Detect AI-Generated Text via Stylometric Features" (ACL Anthology) -- 91.8% F1 on Chinese text via stylometric detection
- Pangram Labs AI writing pattern guide -- structural AI detection beyond phrase-level
- Stack Overflow complex Flutter flow testing -- integration test patterns for multi-screen workflows

---
*Research completed: 2026-06-06*
*Ready for roadmap: yes*
