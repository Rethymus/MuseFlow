# Domain Pitfalls: v1.3 用户视角全流程验证

**Domain:** Comprehensive user-perspective validation of an AI-assisted Chinese creative writing tool by writing a real 100-chapter xianxia novel.
**Researched:** 2026-06-06
**Confidence:** HIGH (codebase-verified + web research)

---

## Critical Pitfalls

Mistakes that invalidate the validation exercise, cause runaway costs, or produce misleading results.

### Pitfall 1: Token Consumption Death Spiral

**What goes wrong:** The validation silently burns through API budget because every AI call injects full context (knowledge base + skill constraints + chapter summaries + banned phrases + system prompt). Over 100 chapters with multiple AI operations per chapter, costs compound quadratically rather than linearly.

**Why it happens:** The prompt pipeline has 7+ middleware layers that each append to the system message. MuseFlow's middleware chain is: `SystemPromptMiddleware -> PersonaInjectionMiddleware -> BannedListMiddleware -> KnowledgeInjectionMiddleware -> SkillEnforcementMiddleware -> ContextAnchorMiddleware -> ChapterContextMiddleware -> EditorOperationMiddleware`. Every single AI call pays the full middleware tax. The knowledge injection middleware alone caps at 30% of token budget and loads up to 5 entities. The skill enforcement middleware caps at 20%. Together that is 50% of every request budget just for context, before the actual content.

**Consequences:** A 100-chapter novel with ~100 words per chapter (~10,000 characters total Chinese text) looks cheap on paper. But the real cost is per-AI-operation overhead. If each chapter involves 3 AI operations (synthesis + tone rewrite + polish), that is 300 API calls. Each call carries ~2,000-4,000 tokens of system/context overhead. At DeepSeek V3.2 pricing ($0.14/1M input, $0.28/1M output), this is modest (~$0.20-0.50). But on GPT-4o ($2.50/1M input, $10.00/1M output) or Claude Sonnet ($3.00/1M input, $15.00/1M output), the same 300 calls cost $3-8. If the user tests with multiple models or regenerates frequently, costs can hit $20-50 for a single validation pass.

The hidden trap: **deviation detection runs automatically after every editor AI operation** (see `editor_ai_notifier.dart` line 200-206: `unawaited(ref.read(deviationNotifierProvider.notifier).checkDeviations(...))`). This means every single editor AI operation triggers an ADDITIONAL AI call for deviation checking. Total API calls become: synthesis (1) + tone rewrite (1) + polish (1) + deviation checks (3) = 6 calls per chapter. Over 100 chapters = 600 API calls, each carrying full context. Costs double or triple compared to what the user sees in the UI.

**Prevention:**
1. **Instrument token counting per operation** before starting the 100-chapter run. Add a `TokenAuditLog` that records input/output tokens for every API call with operation type, model, and chapter number.
2. **Calculate worst-case budget before starting**: Estimate per-chapter cost = (synthesis + rewrite + polish + deviation) x (context overhead + output). Multiply by 100. Present this to the user as a "validation budget estimate."
3. **Make deviation detection opt-in per chapter** rather than automatic during validation. The `unawaited` call is fire-and-forget; its cost is invisible.
4. **Use cheapest model for validation**: DeepSeek V3.2 at $0.14/$0.28 per 1M tokens for routine operations. Reserve GPT-4o/Claude for quality-critical chapters only.
5. **Test context injection budget**: Before writing 100 chapters, verify that `KnowledgeInjectionMiddleware` (30% cap) and `SkillEnforcementMiddleware` (20% cap) actually enforce their limits correctly with real xianxia data.

**Detection:**
- API dashboard showing unexpected token usage spikes
- Token cost per chapter increasing over time (indicates context accumulation leak)
- More API calls logged than user-initiated AI operations (hidden deviation checks)

**Validation phase:** Must be addressed in the token audit phase before writing begins.

---

### Pitfall 2: Knowledge Base Consistency Erosion Across 100 Chapters

**What goes wrong:** Character personalities, world rules, power hierarchies, and geographic details drift over 100 chapters. The knowledge base starts correct but becomes stale as the story evolves. Characters gain new abilities, factions shift, and the cultivation system changes -- but the knowledge base entries are never updated to reflect in-story developments.

**Why it happens:** MuseFlow's knowledge base (CharacterCard, WorldSetting, SkillDocument) is static data. It reflects the author's initial vision, not the story's current state. The `KnowledgeInjectionMiddleware` scans for name matches in the current text and injects the stored entity context. But if a character named "林月" was introduced as a mortal in chapter 1 and becomes a Golden Core cultivator by chapter 50, the knowledge base still says "mortal" unless the author manually updates the card.

The `GuardianCheckService` and `LogicGuardianService` can detect inconsistencies, but they are manual-trigger only. The `DeviationDetectionService` runs automatically but only checks against active skill constraints, not character cards. There is no mechanism to flag "this character's current behavior contradicts their knowledge base entry."

Over 100 chapters of xianxia with cultivation progression, character growth, faction changes, and geography expansion, the knowledge base becomes a liability: it feeds the AI stale context that makes the AI generate text contradicting recent chapters.

**Consequences:**
- AI generates text that contradicts established plot developments
- Characters "forget" they learned new techniques or changed allegiances
- The guardian checks produce false positives (flagging correct text as inconsistent with stale KB)
- Author loses trust in the knowledge base and stops maintaining it

**Prevention:**
1. **Establish a "chapter milestone" KB update protocol**: Every 10 chapters, pause to update character cards, world settings, and skill documents with in-story developments.
2. **Add a "last verified chapter" field** to knowledge entities. If `currentChapter - lastVerifiedChapter > 10`, surface a reminder to review.
3. **Test the NameIndex matching with xianxia names**: Names like "天机老人" (Heavenly Secret Elder), "紫霄宫" (Purple Heaven Palace), and cultivation terms like "金丹期" must be correctly matched by `name_index_service.dart`. Verify before the run.
4. **Create a "story state snapshot" test**: At key chapters (25, 50, 75), export the current story state (all KB entries + all PlotNodes + all ForeshadowingEntries) and verify consistency with actual manuscript text.
5. **The deviation detection should be extended to character cards**, not just skill documents. Currently `DeviationDetectionService` only checks against `SkillDocument` constraints.

**Detection:**
- Guardian checks find contradictions that are actually KB staleness, not AI errors
- Characters referenced in chapter 80 behave as described in chapter 1's KB entry
- Author finds themselves mentally tracking "what the AI knows" vs "what actually happened"

**Validation phase:** Chapter milestone reviews (every 10 chapters). Also, the consistency verification phase.

---

### Pitfall 3: Anti-AI-Scent Bypass on Structured AI Operations

**What goes wrong:** The anti-AI-scent system (`AntiAIScentProcessor`) only post-processes the final text output. But AI "flavor" manifests at multiple levels beyond banned phrases: sentence structure uniformity, emotional beat patterns, transition formula, and paragraph rhythm. The current system catches phrase-level cliches (14 entries in `_synonymMap` + 3 structural patterns) but misses the deeper structural tells that accumulate over 100 chapters.

**Why it happens:** The `AntiAIScentProcessor` has two modes: (1) auto-replace banned phrases from a 14-entry synonym map, and (2) highlight structural patterns via 3 regex rules. This covers obvious tells like "然而" and "综上所述" but misses:
- **Repetitive sentence rhythm**: AI tends to produce uniform sentence lengths. Chinese xianxia requires varied pacing (short punchy action, flowing description, terse dialogue).
- **Transition formula**: AI overuses "与此同时", "就在这时", "不料" as chapter-connecting tissue. These are not in the banned list.
- **Emotional uniformity**: AI writes emotional beats at consistent intensity. Real xianxia alternates between bombastic power descriptions and quiet character moments.
- **Cultivation cliche patterns**: "只见他周身灵气涌动，一股磅礴的力量从体内爆发而出" -- this specific xianxia cliche is genre-appropriate but screams "AI wrote this" when repeated across 30 chapters.
- **Ending patterns**: AI tends to end chapters with cliffhanger hooks that feel formulaic. Real authors vary chapter endings (cliffhanger, resolution, contemplation, humor).

The current banned phrase list is seeded from general Chinese AI writing, not xianxia-specific patterns.

**Consequences:**
- The 100-chapter novel passes the `AntiAIScentProcessor` but fails the "human reader" test
- Over 100 chapters, the accumulated structural patterns become glaringly obvious
- Validation reports "anti-AI-scent working" when it is only catching the easy cases

**Prevention:**
1. **Expand the banned list with xianxia-specific cliches** before validation: compile 30-50 genre-specific phrases that AI overuses in cultivation novels (e.g., "灵气涌动", "磅礴的力量", "眼中闪过一丝", "不由得", "竟是").
2. **Add a "chapter diversity" metric**: After each chapter, compute sentence length variance, paragraph length variance, and transition phrase frequency. Flag chapters where these metrics fall within AI-typical ranges.
3. **Build a structural pattern detector** that checks for: (a) consecutive sentences of similar length, (b) repeated paragraph-opening patterns, (c) chapter-ending formula detection.
4. **The validation must include a "blind read" test**: Have a human reader (or a second LLM acting as critic) read 5-10 chapters and rate "does this feel AI-generated?" without knowing which passages were AI-assisted.
5. **Track "AI provenance ratio" per chapter**: The `aiProvenanceAttribution` in the editor marks AI-generated sentences. For the 100-chapter run, track what percentage of final text carries AI provenance. If >40% is AI-attributed, the "anti-AI-scent" claim needs scrutiny regardless of phrase-level checks.

**Detection:**
- Reading 5 consecutive chapters and noticing uniform rhythm
- The same transition phrases appearing every 2-3 chapters
- Banned phrase replacement count trending toward zero (AI learned to avoid the banned list)

**Validation phase:** Continuous throughout writing. Dedicated anti-AI-scent audit after every 25 chapters.

---

### Pitfall 4: Test Script Assumptions Break With Real Creative Data

**What goes wrong:** Automated validation scripts (Dart test scripts) are written against predictable test data, but real creative writing produces edge cases the scripts never anticipated. Chinese text segmentation, mixed punctuation styles, markdown artifacts from AI output, and variable-length paragraphs all break assumptions baked into the test infrastructure.

**Why it happens:** The test suite currently has 117 test files passing with 930 tests. These tests use controlled inputs. Real xianxia text contains:
- Mixed punctuation: `……` (six-dot ellipsis), `——` (em-dash), `「」` (CJK quotes) alongside `""` (standard quotes)
- AI output with markdown remnants: `**` bold markers, `#` headings, ``` code fences
- Name variations: "林月" vs "月儿" vs "小月" (affectionate/diminutive forms) -- the `NameIndex` may not match all forms
- Cultivation terms used as both nouns and verbs: "他正在修炼" vs "这套修炼功法"
- Extremely short chapters (some xianxia chapters are 50-80 words) and long chapters (300+ words)
- Nested dialogue: `林月说："师父曾说：'修炼之人，心要静。'你知道吗？"` -- triple-nested quotes

The `ForeshadowingReminderService` uses `plantedChapter` as an integer, but real manuscripts might have chapters renumbered, split, or merged. The `PlotNode` positions tracked in `node_position_repository.dart` could become stale.

**Consequences:**
- Tests pass but real usage breaks
- False confidence from green test suite that does not cover real edge cases
- Time wasted debugging test infrastructure instead of finding real product issues

**Prevention:**
1. **Generate test fixtures from actual 100-chapter output**: After writing the first 10 chapters, extract representative text samples and create test fixtures from them.
2. **Test the anti-AI-scent processor with real xianxia prose**, not just the built-in test phrases. Feed it AI-generated xianxia paragraphs and verify it catches the right patterns without mangling the text.
3. **Test export pipeline with 100-chapter data**: The `ExportService` must handle 100 chapters of mixed content. Test Markdown, TXT, and JSON export with full-scale data before trusting the results.
4. **Test Hive with realistic data volume**: 100 chapters + 100 PlotNodes + 50 ForeshadowingEntries + 20 CharacterCards + 5 WorldSettings + 3 SkillDocuments + writing stats. This is ~300+ Hive objects. Verify performance and reliability.
5. **Validate format cleaner with real AI output**: `FormatCleaner` was built for v1.0-era output. Test it against the actual AI models being used for validation.

**Detection:**
- Test failures only after real data is introduced
- Export output contains formatting artifacts
- Knowledge base name matching misses obvious character references

**Validation phase:** After writing first 10 chapters, create test fixtures. After 50 chapters, run full integration test suite.

---

### Pitfall 5: Context Anchor and Chapter Summary Staleness

**What goes wrong:** The `ChapterContextMiddleware` injects `previousChapterSummary` and `nextChapterSummary` into AI prompts, but these summaries are only useful if they are kept current. As chapters are written, rewritten, split, and merged, the summaries drift from actual content. By chapter 80, the "previous chapter summary" might describe events that no longer exist in the manuscript.

**Why it happens:** The chapter context middleware (line 18-43) simply appends whatever summaries are provided in the `PromptContext`. It has no mechanism to verify that summaries match actual chapter content. The summaries are generated at some point (likely when the chapter is first written) but not automatically refreshed when:
- A chapter is rewritten with different events
- A chapter is split into two chapters
- Chapter order is changed
- Characters or settings are retroactively changed

**Consequences:**
- AI generates text that contradicts the actual previous chapter
- The "context-aware" AI feature becomes counterproductive, introducing confusion instead of continuity
- Author notices AI "doesn't remember" what just happened

**Prevention:**
1. **Add a "summary freshness" check**: Before injecting a chapter summary, compare its key entities (character names, location names) against the actual chapter text. If mismatch is detected, flag for re-generation.
2. **Regenerate chapter summaries on chapter edit**: When a chapter is modified, mark its summary as stale and regenerate on the next AI operation.
3. **During the 100-chapter validation, manually verify summaries at milestones** (chapters 25, 50, 75).
4. **Test with deliberately inconsistent summaries**: Inject a wrong summary and verify that the generated text is noticeably affected. This proves the summaries matter.

**Detection:**
- AI references events that did not happen in the previous chapter
- AI uses character names or locations that were not in adjacent chapters
- Author instinctively ignores the "AI suggestions" because they feel wrong

**Validation phase:** Continuous. Dedicated check at chapter milestones.

---

## Moderate Pitfalls

### Pitfall 6: Hive Box Corruption Under Sustained Write Load

**What goes wrong:** Writing 100 chapters generates sustained write activity to Hive boxes. `ChapterAutoSave` triggers on debounced intervals, stats collection writes session data, and knowledge base edits all hit Hive simultaneously. Hive CE's write model is append-only with periodic compaction. Under sustained load, a crash or power loss during compaction can corrupt the box.

**Prevention:**
1. **Enable Hive CE encryption for the manuscript box** -- encrypted boxes have additional integrity checks via AES-256 CBC that detect corruption.
2. **Implement periodic JSON export as backup**: Every 10 chapters, auto-export the manuscript as JSON. This is cheap insurance against data loss.
3. **Test recovery from a mid-compaction crash**: Force-kill the app during a Hive write and verify data integrity on restart.
4. **The `forceSave` mechanism (per D-dispose-no-flush) should be tested with 100-chapter data**: Verify that explicit awaited saves actually flush to disk.

---

### Pitfall 7: Foreshadowing Tracking Collapse at Scale

**What goes wrong:** A 100-chapter xianxia novel naturally generates 30-50 foreshadowing threads. The `ForeshadowingReminderService` computes reminders deterministically based on `plantedChapter`, `targetResolutionChapter`, and `defaultThreshold`. But the reminder logic uses simple integer subtraction (`currentChapter - e.plantedChapter >= defaultThreshold`). This creates two problems:
- **Reminder fatigue**: By chapter 50, there are 20+ unresolved threads, each generating a reminder every chapter. The author learns to ignore all reminders.
- **False urgency**: Threads planted in chapter 1 with a 20-chapter threshold trigger "overdue" at chapter 21, even if the author intentionally deferred them.

**Prevention:**
1. **Set xianxia-appropriate thresholds**: Cultivation novels often plant seeds that resolve 50+ chapters later. Use `defaultThreshold = 30` for the validation run.
2. **Group reminders by urgency, not just count**: Separate "truly overdue" from "approaching deadline" from "newly planted."
3. **Track "resolution intent"**: Allow marking a foreshadowing entry as "deferred to next arc" to suppress reminders without marking it resolved.

---

### Pitfall 8: Single-Model Validation Bias

**What goes wrong:** The entire 100-chapter validation is done with one AI model (e.g., DeepSeek V3.2 for cost reasons). The results only validate the product for that model's specific output patterns. Switching to GPT-4o or Claude produces different writing style, different cliche patterns, and different consistency behavior.

**Why it happens:** The `EditorPromptPipeline` and `PromptPipeline` use the same middleware chain regardless of model. But models respond differently to the same prompt. DeepSeek V3.2 might produce more "网文风格" (web novel style) text naturally, while Claude might produce more literary but less genre-appropriate text. The anti-AI-scent system is tuned for one model's output patterns.

**Prevention:**
1. **Write at least 10 chapters with each of 3 models**: DeepSeek (cost-effective), GPT-4o (quality benchmark), Claude (alternative style). Compare anti-AI-scent effectiveness across models.
2. **Verify the `TokenBudgetCalculator` approximation (1.8x for Chinese)** against actual token counts from each model's tokenizer. The 1.8x estimate may be accurate for GPT-4's o200k_base but wrong for DeepSeek's tokenizer.
3. **Document model-specific strengths/weaknesses** discovered during validation.

---

### Pitfall 9: Story Structure Visualization Unusable at 100 Nodes

**What goes wrong:** The story arc visualization (built in v1.1 Phase 10) works well with 10-20 PlotNodes. At 100 chapters with multiple plot nodes per chapter, the graph becomes an unreadable hairball. Node labels overlap, edges cross chaotically, and the minimap becomes too dense to navigate.

**Prevention:**
1. **Test the visualization at 50+ nodes before writing all 100 chapters**.
2. **Use the story arc page only for arc-level views** (grouping nodes by arc rather than showing all).
3. **Validate that the `story_arc_graph.dart` rendering does not degrade frame rate below 30fps** with 100 nodes.
4. **Consider whether 100 chapters actually NEED 100+ PlotNodes**: xianxia short stories (~10,000 words total) might only need 20-30 major plot nodes. Guide the author to create only structurally significant nodes, not one per chapter.

---

### Pitfall 10: Validation Confounds Product Feedback

**What goes wrong:** The person doing the validation (writing the 100-chapter novel) is simultaneously testing the product and being a user. They conflate "this is hard because the tool is buggy" with "this is hard because writing a novel is hard." The validation report mixes genuine product issues with expected creative writing challenges.

**Prevention:**
1. **Maintain a structured "interruption log"**: Every time the writing flow is interrupted by a tool issue, log it separately from creative difficulties.
2. **Distinguish three categories in the pain report**: (a) bugs/crashes, (b) UX friction, (c) feature gaps. Only (a) and (b) are product issues.
3. **Write the first 10 chapters without any AI assistance** to establish a baseline of "what writing feels like without the tool." Then write chapters 11-20 with the tool. This creates a direct comparison.
4. **Time-box the validation**: Set a per-chapter time limit. If a chapter takes >30 minutes due to tool issues (not creative block), flag it as a product problem.

---

## Minor Pitfalls

### Pitfall 11: Export Format Edge Cases

**What goes wrong:** Exporting 100 chapters in Markdown/TXT/JSON reveals edge cases: chapter titles with special characters, empty chapters, chapters with only AI-rejected text, extremely long single-paragraph chapters.

**Prevention:** Test export after every 10 chapters. Verify all three formats parse correctly.

---

### Pitfall 12: Writing Stats Accuracy Drift

**What goes wrong:** The `WritingStatsCollector` tracks word counts and AI interaction counts, but its accuracy depends on consistent editor event firing. If the app crashes, restarts, or chapters are switched rapidly, session data may be incomplete.

**Prevention:** Treat stats as directional indicators, not precise measurements. Verify stats at milestones by comparing reported totals against manually counted chapters.

---

### Pitfall 13: Banned Phrase List Inadequacy for Xianxia

**What goes wrong:** The 14-entry `_synonymMap` in `AntiAIScentProcessor` targets general Chinese AI writing patterns. Xianxia-specific AI cliches are not covered. The user-added banned phrases (from `bannedPhraseSettings`) must carry the genre-specific load, but the validation starts with an empty custom list.

**Prevention:** Pre-populate the banned phrases list with 20-30 xianxia-specific cliches before starting the validation run. Draw from known AI-generated xianxia samples.

---

## Phase-Specific Warnings

| Validation Phase | Likely Pitfall | Mitigation |
|------------------|---------------|------------|
| World-building setup | KB entities too sparse for xianxia (Pitfall 2) | Use the xianxia template to seed rich character cards and world settings |
| First 10 chapters | Token budget estimation wrong (Pitfall 1) | Run token audit before and after first 10 chapters, adjust model/provider |
| Chapters 10-30 | Foreshadowing reminder fatigue (Pitfall 7) | Set xianxia-appropriate thresholds, defer non-urgent threads |
| Chapters 30-50 | Knowledge base staleness (Pitfall 2) | Mandatory KB review at chapter 30 and 50 |
| Chapters 50-75 | Anti-AI-scent effectiveness plateaus (Pitfall 3) | Run blind-read test at chapter 50 with fresh eyes |
| Chapters 75-100 | Export and data integrity (Pitfall 4, 6) | Test full export at chapter 75, verify no data loss |
| Full pass | Single-model bias (Pitfall 8) | Write at least 10 chapters with alternative models |
| Pain report writing | Validation confound (Pitfall 10) | Use structured interruption log, separate bugs from creative challenges |

---

## Token Cost Analysis: 100-Chapter Xianxia Validation

### Per-Operation Token Budget Breakdown

Based on codebase analysis of the middleware chain:

| Middleware | Budget Cap | Typical Chinese Token Cost |
|-----------|------------|---------------------------|
| SystemPromptMiddleware | Base | ~200-400 tokens |
| PersonaInjectionMiddleware | Base | ~300-500 tokens |
| BannedListMiddleware | Variable | ~100-300 tokens (14 phrases) |
| KnowledgeInjectionMiddleware | 30% of total | ~500-1,500 tokens (2-3 entities) |
| SkillEnforcementMiddleware | 20% of total | ~400-800 tokens (1-2 skills) |
| ContextAnchorMiddleware | Variable | ~0-500 tokens |
| ChapterContextMiddleware | Variable | ~200-400 tokens (2 summaries) |
| EditorOperationMiddleware | Base | ~50-100 tokens |
| **Total context overhead** | | **~1,750-4,500 tokens per call** |

### Per-Chapter Cost Estimate (3 AI operations + 3 hidden deviation checks = 6 API calls)

| Model | Input (per call) | Output (per call) | Cost per Chapter (6 calls) | Cost for 100 Chapters |
|-------|-----------------|-------------------|---------------------------|----------------------|
| DeepSeek V3.2 | ~3,000 tok | ~500 tok | ~$0.003 | ~$0.30 |
| DeepSeek V3.1 | ~3,000 tok | ~500 tok | ~$0.006 | ~$0.60 |
| GPT-4o | ~3,000 tok | ~500 tok | ~$0.050 | ~$5.00 |
| Claude Sonnet | ~3,000 tok | ~500 tok | ~$0.060 | ~$6.00 |

### Hidden Cost Multipliers

| Factor | Multiplier | Trigger |
|--------|-----------|---------|
| Regeneration (user retries) | 1.5-2x | Average 1 retry per 3 operations |
| Guardian checks (manual trigger) | +1 call per check | Every 10 chapters |
| Knowledge base updates via AI | +1 call per entity | Every 10 chapters |
| Multi-model testing | 2-3x | Testing with multiple models |
| **Worst case (GPT-4o, retries, guardian, multi-model)** | | **~$20-30** |

### Red Flags to Watch

1. **Token usage per chapter trending upward** -- indicates context leak or growing KB injection
2. **More than 6 API calls per chapter on average** -- hidden operations consuming budget
3. **Input tokens > 5,000 per call** -- context injection exceeds reasonable budget
4. **Total cost exceeding 2x the estimate** -- stop and audit

---

## Sources

| Source | Confidence | What It Verified |
|--------|------------|------------------|
| Codebase analysis (token_budget_calculator.dart, prompt_pipeline.dart, knowledge_injection_middleware.dart, skill_enforcement_middleware.dart, chapter_context_middleware.dart, editor_ai_notifier.dart, deviation_detection_service.dart) | HIGH | Exact middleware budget caps, hidden deviation calls, token estimation formula |
| [Context Is a Budget](https://foojay.io/today/context-is-a-budget-eight-levers-and-three-workflow-patterns/) | MEDIUM | Token optimization patterns, context engineering strategies |
| [The Context Window Trap](https://www.rockcybermusings.com/p/the-context-window-trap-why-1m-tokens) | MEDIUM | Context inflation making agents costlier |
| [Lost in Stories: Consistency Bugs in Long Story Generation by LLMs](https://arxiv.org/html/2603.05890v1) | HIGH | Academic study on LLM consistency degradation over long narratives |
| [Token Cost Trap: Why AI Agent ROI Breaks at Scale](https://medium.com/@klaushofenbitzer/token-cost-trap-why-your-ai-agents-roi-breaks-at-scale-and-how-to-fix-it-4e4a9f6f5b9a) | MEDIUM | Quadratic cost growth in agent loops |
| [DeepSeek API Pricing](https://api-docs.deepseek.com/quick_start/pricing) | HIGH | Per-token pricing for cost estimates |
| [Chinese Language Tokenization Efficiency](https://arxiv.org/html/2604.14210v1) | HIGH | Chinese token overhead ~1.09x for GPT-5.4-mini |
| [C-ReD: Chinese AI Text Detection Benchmark](https://arxiv.org/html/2604.11796v1) | MEDIUM | Systematic approaches to Chinese AI text detection |
| [Detect AI-Generated Text via Stylometric Features](https://aclanthology.org/2025.ccl-1.64.pdf) | MEDIUM | Stylometric detection achieving 91.8% F1 on Chinese text |
| [Pangram Labs: Comprehensive Guide to Spotting AI Writing Patterns](https://www.pangram.com/blog/comprehensive-guide-to-spotting-ai-writing-patterns) | MEDIUM | AI writing tells beyond phrase-level detection |
| [Epos AI: Long-Term Memory for Novels](https://epos-ai.ch/en/blog/ai-long-term-memory-novel-writing.html) | MEDIUM | Context window limitations for 100K+ word manuscripts |
| [Indie Hackers: AI Novel Consistency Lessons](https://www.indiehackers.com/post/i-built-an-ai-that-writes-full-length-novels-with-consistent-characters-heres-what-i-learned-f0d3211a8a) | LOW-MEDIUM | Practitioner experience with character drift at 60K+ words |
| [AI Agent Loop Token Costs](https://www.augmentcode.com/guides/ai-agent-loop-token-cost-context-constraints) | MEDIUM | Quadratic input token cost in agent loops |
| Hive CE GitHub issues | MEDIUM | Known reliability concerns with sustained write loads |
| v1.2 Milestone Audit | HIGH | Current test count (930), tech debt, human verification pending items |

---
*Pitfalls researched: 2026-06-06 for v1.3 validation milestone*
