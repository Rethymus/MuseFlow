# Phase 16: Analysis & Reports - Research

**Researched:** 2026-06-08
**Domain:** Report generation, token cost analysis, anti-AI-scent evaluation, knowledge base consistency auditing
**Confidence:** HIGH

## Summary

Phase 16 is a **report-generation phase** that consumes data produced by Phases 12-15 and synthesizes it into four analytical reports. It does not build new features -- all infrastructure (token audit, deviation detection, anti-AI-scent, knowledge base, export) was shipped in v1.0-v1.2 and validated through Phases 12-15.

The four reports (REPORT-01 through REPORT-04) each require: (1) a data-aggregation service that queries existing repositories, (2) an optional AI-assisted analysis step for natural-language insights, and (3) a presentation page that renders the report in the app. The reports are primarily **read-only analytical views** -- they read from existing Hive boxes and compute derived metrics.

The most architecturally significant finding is that **all four reports can be built purely from existing data sources** without new domain entities or storage boxes. Token audit records, chapter content, character cards, world settings, skill documents, and deviation warnings are already persisted and queryable. The reports layer aggregates, computes derived metrics, and presents results.

**Primary recommendation:** Build four lightweight report services in `lib/features/stats/application/` (or a new `lib/features/reports/` module) that query existing repositories, compute derived metrics, and expose results via Riverpod providers. Presentation pages use existing patterns (ConsumerWidget + AsyncValue.when + fl_chart + StatsSummaryCard). Reports are viewable in-app and exportable as Markdown files using the existing ExportService pattern.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REPORT-01 | Token 消耗分析报告（万字短篇实际成本 + 50万字长篇消耗推算 + 优化建议） | TokenAuditRepository.loadAll() provides all audit records; TokenBudgetCalculator provides estimation logic; extrapolation is pure math from per-chapter averages |
| REPORT-02 | 用户痛点报告（功能缺陷列表 + 体验摩擦点 + 缺失需求建议，按严重程度分类） | Phase 14/15 ISSUE-LOG files establish the format; issues are collected from execution logs, not from app state; report aggregates known issues into a structured document |
| REPORT-03 | 反AI味效果评估（盲读测试：选取若干段落由人判断是否AI生成） | AntiAIScentProcessor provides highlight counts; chapter content is readable from ChapterRepository; blind-read test requires manual human evaluation -- the app can present random excerpts and collect human verdicts |
| REPORT-04 | 知识库一致性衰减分析（100章后角色卡和设定集与实际内容的一致性对比） | CharacterCard/WorldSetting repositories provide reference data; chapter content is queryable; DeviationDetectionService provides AI-powered consistency checking; name matching via NameIndexService |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token cost aggregation & extrapolation | Application (service) | -- | Pure computation on existing TokenAuditRecord data |
| Pain point cataloging | Manual / Documentation | -- | Issues come from human observation during Phases 14-15, not from app state |
| Anti-AI-scent blind-read evaluation | Presentation (UI) | Application (service) | UI presents excerpts, collects human verdicts; service selects random passages |
| Knowledge base consistency analysis | Application (service) | AI/Backend | Queries chapter content + knowledge entities; may use DeviationDetectionService for AI-powered comparison |
| Report rendering & export | Presentation (UI) | -- | Uses existing fl_chart + StatsSummaryCard + Markdown export patterns |
| Report persistence | Database (Hive) | -- | Optional: cached report results stored in a new Hive box, or generated on-demand |

## Standard Stack

### Core (Already in Project)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | State management for report providers | Project constraint [VERIFIED: pubspec.yaml] |
| fl_chart | ^1.2.0 | Chart rendering for report visualizations | Already used in stats/charts/ for bar/pie/line charts [VERIFIED: pubspec.yaml] |
| hive_ce | ^2.19.3 | Local persistence for report cache (optional) | Project storage standard [VERIFIED: pubspec.yaml] |
| markdown | ^7.3.1 | Report export as Markdown files | Already in pubspec.yaml for import/export [VERIFIED: pubspec.yaml] |
| share_plus | ^12.0.0 | Share exported report files | Already in pubspec.yaml for manuscript sharing [VERIFIED: pubspec.yaml] |
| path_provider | ^2.1.5 | File system paths for report export | Already in pubspec.yaml [VERIFIED: pubspec.yaml] |

### Supporting (Existing, Reused)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| openai_dart | ^6.0.0 | AI-powered report analysis (optional insights) | When reports include AI-generated optimization suggestions or consistency analysis |
| uuid | ^4.5.1 | Unique IDs for report entities (if persisted) | When report results are cached as Hive entities |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AI-powered consistency analysis (REPORT-04) | Pure keyword/regex matching | AI analysis is more nuanced but requires API calls and costs tokens. Keyword matching is free but less accurate for semantic drift. |
| New Hive box for cached reports | Generate on-demand every time | Caching avoids recomputation but adds storage complexity. For this phase, on-demand generation is simpler and sufficient. |
| PDF report export | Markdown export only | PDF requires additional packages (e.g., pdf, printing). Markdown is already supported and sufficient for developer/user analysis. |

**No new packages needed for this phase.** All dependencies are already in pubspec.yaml.

## Package Legitimacy Audit

> No new packages are installed in this phase. All dependencies are existing project dependencies verified in prior phases.

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| (no new packages) | -- | -- | N/A |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
[TokenAuditRepository]  [ChapterRepository]  [Knowledge Repositories]
         |                       |                      |
         v                       v                      v
[TokenCostReportService] [BlindReadService]  [ConsistencyAnalysisService]
         |                       |                      |
         +-------+-------+-------+-------+-------+------+
                 |                       |
                 v                       v
          [ReportAggregator]     [PainPointCollector]
                 |                       |
                 v                       v
        [ReportProviders (Riverpod AsyncNotifier)]
                 |
                 v
    [Report Pages (ConsumerWidget + fl_chart)]
                 |
                 v
        [Markdown Export / share_plus]
```

Data flow: Existing repositories (read-only) -> Report services (pure computation) -> Riverpod providers -> Presentation pages -> Optional export.

### Recommended Project Structure

```
lib/features/reports/                    # New feature module
  application/
    token_cost_report_service.dart       # REPORT-01: aggregation + extrapolation
    pain_point_report_service.dart       # REPORT-02: issue catalog builder
    blind_read_service.dart              # REPORT-03: excerpt selector
    consistency_analysis_service.dart    # REPORT-04: knowledge drift detector
    report_export_service.dart           # Common Markdown/TXT report export
  domain/
    token_cost_report.dart               # REPORT-01 data model
    pain_point_report.dart               # REPORT-02 data model
    blind_read_result.dart               # REPORT-03 data model
    consistency_report.dart              # REPORT-04 data model
    report_export_bundle.dart            # Shared export model
  presentation/
    reports_hub_page.dart                # Entry: 4 report cards
    token_cost_report_page.dart          # REPORT-01 detail page
    pain_point_report_page.dart          # REPORT-02 detail page
    blind_read_page.dart                 # REPORT-03 interactive page
    consistency_report_page.dart         # REPORT-04 detail page
    charts/
      cost_breakdown_chart.dart          # Per-operation-type pie chart
      cost_projection_chart.dart         # Short vs long extrapolation bar chart
      consistency_drift_chart.dart       # Per-chapter consistency trend line
```

### Pattern 1: Report Service (Application Layer)

**What:** A stateless service that reads from existing repositories and computes derived metrics.
**When to use:** For each of the four reports.

```dart
// Pattern: Report service reads existing data, computes derived metrics
class TokenCostReportService {
  final TokenAuditRepository _auditRepository;
  final TokenBudgetCalculator _calculator;

  TokenCostReportService(this._auditRepository, this._calculator);

  Future<TokenCostReport> generate() async {
    final records = await _auditRepository.loadAll();
    // Aggregate by operation type, chapter, model
    // Extrapolate to 500k-char novel
    // Generate optimization suggestions
    return TokenCostReport(...);
  }
}
```

### Pattern 2: Report Provider (Riverpod)

**What:** AsyncNotifier that loads report data on demand.
**When to use:** For each report page.

```dart
// Pattern: Report provider wraps service for UI consumption
@riverpod
class TokenCostReport extends _$TokenCostReport {
  @override
  Future<TokenCostReport> build() async {
    final service = ref.watch(tokenCostReportServiceProvider);
    return service.generate();
  }
}
```

### Pattern 3: Report Export

**What:** Converts report data model to Markdown/TXT string for file export.
**When to use:** When user wants to export a report.

```dart
// Pattern: Reuse ExportService file-writing pattern
class ReportExportService {
  String buildMarkdown(TokenCostReport report) {
    final buffer = StringBuffer();
    buffer.writeln('# Token 消耗分析报告');
    buffer.writeln('## 实际消耗（万字短篇）');
    // ... structured sections
    return buffer.toString();
  }
}
```

### Anti-Patterns to Avoid

- **Storing reports in Hive unnecessarily:** Reports are computed views of existing data. Unless caching is needed for offline/performance, generate on-demand. Premature caching adds migration burden.
- **REPORT-02 as app feature:** The pain point report is a human-curated document, not an app-computed metric. Do NOT try to build an automated issue-detection system inside the app. The report aggregates known issues from Phase 14/15 execution logs.
- **REPORT-03 fully automated:** Blind-read testing requires human judgment by definition. The app should present excerpts and collect verdicts, not try to AI-evaluate itself.
- **Creating new Hive boxes for each report:** Use on-demand generation. If caching is needed, a single `report_cache` box suffices for all four reports.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token estimation | Custom tokenizer | TokenBudgetCalculator (already in project) | Existing 1.8x Chinese / 0.25x ASCII heuristic with 10% margin |
| Text export | Custom file writer | ExportService file-writing pattern | Existing injectable FileWriter abstraction |
| Chart rendering | Custom Canvas painting | fl_chart (BarChart, PieChart, LineChart) | Already used in stats/charts/ |
| Summary cards | Custom stat widgets | StatsSummaryCard (already in project) | Consistent with existing stats pages |
| Knowledge entity matching | Custom string matching | NameIndexService | Existing name matching with alias support |
| Deviation detection | Custom consistency checker | DeviationDetectionService | Existing AI-powered deviation detection with structured results |

**Key insight:** This phase is primarily a data-aggregation and presentation layer over existing infrastructure. The "don't hand-roll" list is long because the heavy lifting was done in Phases 5, 9, 12, and 14.

## Common Pitfalls

### Pitfall 1: REPORT-02 Automation Trap

**What goes wrong:** Trying to automatically detect pain points from app state, which requires NLP/sentiment analysis and is fragile.
**Why it happens:** Engineers want everything automated, but pain points come from human observation during 100-chapter journey testing.
**How to avoid:** REPORT-02 is a structured document that aggregates known issues from Phase 14/15 ISSUE-LOG files. It should be generated as a Markdown document with categories, not computed from app telemetry.
**Warning signs:** Writing code that tries to detect "friction" or "missing features" from click patterns.

### Pitfall 2: Token Cost Extrapolation Accuracy

**What goes wrong:** Naive linear extrapolation (100 chapters * 50x = cost for 50万字) ignores that token costs are not linear with content length.
**Why it happens:** Assuming per-chapter cost is constant regardless of novel length.
**How to avoid:** Use actual per-chapter audit data for the 1万字 baseline. For extrapolation, clearly label it as "estimation" and provide a range (low/high) based on observed variance in per-chapter costs. Note that knowledge injection context grows with chapter count (more characters/settings referenced).
**Warning signs:** A single extrapolated number without confidence range or methodology explanation.

### Pitfall 3: REPORT-03 Blind-Read Scope Creep

**What goes wrong:** Building a full A/B testing framework with statistical analysis, which is research-level work.
**Why it happens:** Over-engineering the "blind read" concept.
**How to avoid:** Keep it simple: select N random paragraphs from the 100-chapter manuscript, present them one at a time, let the human judge "AI generated" or "human written", and tally results. The "blind read" in the requirement means human evaluation, not automated detection.
**Warning signs:** Designing double-blind protocols, sample size calculators, or statistical significance tests.

### Pitfall 4: Knowledge Consistency Without AI

**What goes wrong:** Trying to compare character cards against chapter content using only keyword matching, which misses semantic drift.
**Why it happens:** Avoiding AI API calls to save tokens.
**How to avoid:** For REPORT-04, use the existing DeviationDetectionService which already does AI-powered consistency checking. The cost is bounded (one check per chapter or per sampled chapter). Alternatively, do keyword-level checks for concrete attributes (character names, place names, power levels) and flag semantic drift for human review.
**Warning signs:** A consistency report that only checks if character names appear, not whether personality/behavior matches the card.

### Pitfall 5: Report Page Navigation Fragmentation

**What goes wrong:** Adding four separate routes for four reports, cluttering the navigation.
**Why it happens:** Treating each report as a separate top-level feature.
**How to avoid:** Create a single "Reports Hub" page accessible from the stats section. The hub shows four report cards with brief summaries. Each card navigates to its detail page. Add a single route like `/stats/reports` or make reports a tab within the existing stats section.
**Warning signs:** Four new top-level navigation entries for reports.

## Code Examples

### REPORT-01: Token Cost Aggregation

```dart
// TokenCostReport aggregates audit data and extrapolates to 50万字
class TokenCostReport {
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCalls;
  final double actualWordCount;       // ~1万字 from 100 chapters
  final Map<AuditOperationType, int> costByType;
  final Map<String, int> costByChapter;
  final TokenCostProjection projection;
  final List<String> optimizationSuggestions;
}

class TokenCostProjection {
  final double targetWordCount;        // 50万字
  final double multiplier;             // targetWordCount / actualWordCount
  final int estimatedInputTokens;
  final int estimatedOutputTokens;
  final int estimatedCalls;
  final double lowEstimateMultiplier;  // variance-adjusted low
  final double highEstimateMultiplier; // variance-adjusted high
}
```

### REPORT-03: Blind-Read Excerpt Selection

```dart
// BlindReadService selects random passages for human evaluation
class BlindReadService {
  final ChapterRepository _chapterRepository;
  final Random _random;

  Future<List<BlindReadExcerpt>> selectExcerpts({
    required String manuscriptId,
    int count = 10,
    int minParagraphLength = 50,
  }) async {
    // Load all chapters, extract paragraphs >= minParagraphLength
    // Randomly select `count` paragraphs
    // Shuffle to randomize chapter distribution
  }
}

class BlindReadExcerpt {
  final String text;
  final String chapterId;
  final int chapterIndex;
  bool? humanVerdict;  // null = not yet judged, true = AI, false = human
}
```

### REPORT-04: Consistency Analysis

```dart
// ConsistencyAnalysisService compares knowledge base against chapter content
class ConsistencyAnalysisService {
  final CharacterCardRepository _characterRepo;
  final WorldSettingRepository _worldSettingRepo;
  final SkillRepository _skillRepo;
  final ChapterRepository _chapterRepo;
  final NameIndexService _nameIndex;
  // Optional: DeviationDetectionService for AI-powered checks

  Future<ConsistencyReport> analyze(String manuscriptId) async {
    // 1. Load all knowledge entities (characters, settings, skills)
    // 2. Load all chapter content
    // 3. For each entity, check presence/consistency across chapters
    // 4. Track drift: does chapter 90's portrayal match chapter 1's character card?
    // 5. Summarize: which entities drifted, how much, which chapters
  }
}

class ConsistencyReport {
  final List<EntityConsistencyResult> characterResults;
  final List<EntityConsistencyResult> settingResults;
  final List<SkillConsistencyResult> skillResults;
  final double overallConsistencyScore; // 0.0 - 1.0
}

class EntityConsistencyResult {
  final String entityName;
  final String entityType;  // character / setting / skill
  final int chaptersWhereMentioned;
  final List<ConsistencyFlag> flags;
}

class ConsistencyFlag {
  final int chapterIndex;
  final String field;        // e.g. "personality", "power_level"
  final String expectedValue;
  final String observedText;
  final DeviationSeverity severity;
}
```

### Existing Pattern: Chart with fl_chart (from chapter_token_bar_chart.dart)

```dart
// Source: lib/features/stats/presentation/charts/chapter_token_bar_chart.dart
// Pattern: BarChart with fl_chart for token distribution
BarChart(
  BarChartData(
    maxY: maxY <= 0 ? 1 : maxY * 1.2,
    gridData: const FlGridData(show: false),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Text('Ch${value.toInt() + 1}'),
        ),
      ),
    ),
    barGroups: barGroups,
  ),
);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Token counting via tiktoken | TokenBudgetCalculator estimation | Phase 12 (D-12) | Estimation sufficient for cost analysis; exact counts not needed for reports |
| Manual issue tracking | Structured ISSUE-LOG format | Phase 14 | Established format for pain point cataloging |
| No anti-AI-scent validation | Automated phrase removal + manual blind-read | Phase 14 | AntiAIScentProcessor proven to remove 3+ phrases; blind-read is the human validation step |

**Deprecated/outdated:**
- None for this phase -- all infrastructure is current

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Reports generated on-demand without Hive caching is acceptable | Architecture Patterns | If reports are slow to generate (unlikely with ~100 records), caching may be needed |
| A2 | REPORT-02 pain points come from human observation during Phases 14-15, not from app telemetry | Common Pitfalls | If the expectation is automated issue detection, the scope expands significantly |
| A3 | REPORT-03 blind-read is a simple human-in-the-loop evaluation, not a statistical experiment | Common Pitfalls | If statistical rigor is expected, sampling methodology needs professional review |
| A4 | DeviationDetectionService can be reused for REPORT-04 consistency analysis | Code Examples | If deviation detection only checks Skill documents (not character cards), additional AI prompts may be needed |
| A5 | No new packages needed -- all capabilities exist in current pubspec.yaml | Standard Stack | If Markdown rendering for in-app report preview is needed, a markdown widget package may be required |
| A6 | Token cost extrapolation uses simple linear scaling with variance bounds | Common Pitfalls | If token costs scale non-linearly with content length, the projection will be inaccurate |

## Open Questions

1. **REPORT-04: DeviationDetectionService scope limitation**
   - What we know: DeviationDetectionService currently only checks against active SkillDocuments, not against CharacterCard or WorldSetting entities directly.
   - What's unclear: Whether REPORT-04 should analyze character/setting consistency using the same service, or build a new AI-prompted check that compares character cards against chapter text.
   - Recommendation: Build a new consistency check that compares CharacterCard.toContextString() against chapter content using keyword matching (for concrete attributes like names, appearance traits) and optionally AI evaluation (for personality/behavior drift). This can be a new method in a ConsistencyAnalysisService that does NOT modify DeviationDetectionService.

2. **REPORT-02: Scope of automation**
   - What we know: Phase 14 found 6 issues, Phase 15 found 0 issues. These are documented in ISSUE-LOG files.
   - What's unclear: Whether REPORT-02 should only catalog known issues from Phase 14/15 execution, or also include a "discovery" component where the app proactively identifies UX friction.
   - Recommendation: REPORT-02 should be a structured document aggregating known issues from Phase 14/15 ISSUE-LOGs plus any new observations during Phase 16. It is NOT an automated issue detection system.

3. **Report navigation placement**
   - What we know: Existing routes include `/stats`, `/stats/project`, `/stats/tokens`. WritingStatsPage has action buttons for "当前作品" and "Token 消耗".
   - What's unclear: Whether reports should be a new top-level route (`/reports`), a sub-route under stats (`/stats/reports`), or a tab within the stats section.
   - Recommendation: Add `/stats/reports` as a hub page, with sub-routes for each report detail. Add a "分析报告" button to WritingStatsPage actions, consistent with existing navigation patterns.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | Yes | 3.44.0 | -- |
| Dart SDK | All | Yes | 3.5.4+ | -- |
| GLM API Key | REPORT-04 AI analysis (optional) | Conditional | -- | Keyword-based consistency check without AI |
| fl_chart | Report charts | Yes | ^1.2.0 | -- |
| share_plus | Report export | Yes | ^12.0.0 | -- |
| path_provider | Report file export | Yes | ^2.1.5 | -- |

**Missing dependencies with no fallback:** none

**Missing dependencies with fallback:**
- GLM API Key: If not available, REPORT-04 consistency analysis uses keyword matching only (no AI-powered semantic drift detection). REPORT-01 optimization suggestions use template-based recommendations instead of AI-generated analysis.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none -- see Wave 0 |
| Quick run command | `flutter test test/features/reports/ --timeout 120s` |
| Full suite command | `flutter test test/journey/ test/features/reports/ --timeout 300s` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPORT-01 | Token cost aggregation from audit records | unit | `flutter test test/features/reports/application/token_cost_report_service_test.dart -x` | Wave 0 |
| REPORT-01 | 50万字 extrapolation calculation | unit | `flutter test test/features/reports/application/token_cost_report_service_test.dart -x` | Wave 0 |
| REPORT-01 | Report page renders summary cards and charts | widget | `flutter test test/features/reports/presentation/token_cost_report_page_test.dart -x` | Wave 0 |
| REPORT-02 | Pain point report builds structured issue list | unit | `flutter test test/features/reports/application/pain_point_report_service_test.dart -x` | Wave 0 |
| REPORT-03 | Blind-read excerpt selection and verdict collection | unit | `flutter test test/features/reports/application/blind_read_service_test.dart -x` | Wave 0 |
| REPORT-03 | Blind-read page presents excerpt and collects verdict | widget | `flutter test test/features/reports/presentation/blind_read_page_test.dart -x` | Wave 0 |
| REPORT-04 | Consistency analysis compares characters against chapters | unit | `flutter test test/features/reports/application/consistency_analysis_service_test.dart -x` | Wave 0 |
| REPORT-04 | Consistency report page renders drift chart | widget | `flutter test test/features/reports/presentation/consistency_report_page_test.dart -x` | Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/features/reports/ --timeout 120s`
- **Per wave merge:** `flutter test test/features/reports/ test/journey/ --timeout 300s`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/features/reports/` directory -- covers all REPORT-01 through REPORT-04
- [ ] `test/features/reports/application/` -- service-level unit tests
- [ ] `test/features/reports/presentation/` -- widget tests for report pages
- [ ] Report test fixtures (sample audit records, chapters, knowledge entities)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Reports are local-only, no auth required |
| V3 Session Management | no | No sessions involved |
| V4 Access Control | no | All data is local, single-user |
| V5 Input Validation | yes | Blind-read verdict input validation (REPORT-03) |
| V6 Cryptography | no | No encryption needed for reports |

### Known Threat Patterns for Flutter/Dart Reports

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Report export path traversal | Tampering | Validate export paths stay within app directory |
| Markdown injection in report content | Tampering | Sanitize AI-generated text before rendering |

## Sources

### Primary (HIGH confidence)

- Codebase analysis of `lib/features/stats/`, `lib/features/knowledge/`, `lib/features/story_structure/`, `lib/features/ai/` -- all modules examined directly
- `.planning/ROADMAP.md` -- Phase 16 requirements and success criteria
- `.planning/REQUIREMENTS.md` -- REPORT-01 through REPORT-04 definitions
- `.planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` -- 6 known issues for REPORT-02
- `.planning/phases/15-full-manuscript-story-structure/15-ISSUE-LOG.md` -- 0 new issues
- `.planning/phases/15-full-manuscript-story-structure/15-VERIFICATION.md` -- 4/4 truths verified

### Secondary (MEDIUM confidence)

- `.planning/phases/15-full-manuscript-story-structure/15-CONTEXT.md` -- Phase 15 patterns, canonical refs
- `.planning/phases/14-world-building-first-30-chapters/14-CONTEXT.md` -- Phase 14 patterns (referenced)

### Tertiary (LOW confidence)

- None -- all findings are from direct codebase analysis

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new packages; all existing dependencies verified in pubspec.yaml
- Architecture: HIGH -- follows established Clean Architecture + Riverpod patterns from stats/knowledge modules
- Pitfalls: HIGH -- derived from direct analysis of existing issue logs and code limitations

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (stable -- depends on existing infrastructure)

---

## Appendix: Key Data Sources for Reports

### REPORT-01: Token Cost Analysis

**Input data:**
- `TokenAuditRepository.loadAll()` -- all audit records with inputTokens, outputTokens, modelName, operationType, manuscriptId, chapterId, timestamp
- `AuditOperationType` enum -- 8 operation types in 4 groups (organize, edit, worldview, template)
- `TokenBudgetCalculator.estimateTokens()` -- for validation cross-check

**Computation:**
1. Aggregate totals: sum inputTokens, outputTokens, totalCalls
2. Actual word count: sum of all chapter content lengths (from ChapterRepository)
3. Per-operation-type breakdown: group records by operationType
4. Per-chapter breakdown: group records by chapterId
5. 50万字 extrapolation: (500000 / actualWordCount) * totalTokens, with variance range
6. Optimization suggestions: template-based rules (e.g., "batch operations reduce overhead", "use cheaper models for drafts")

### REPORT-02: Pain Point Catalog

**Input data:**
- Phase 14 ISSUE-LOG: 6 issues (1 high/closed, 3 medium, 2 low)
- Phase 15 ISSUE-LOG: 0 issues (all automated tests passed)
- STATE.md Deferred Items: IME testing, physical device testing
- Human observations from Phases 14-15

**Computation:**
1. Aggregate all issues from Phase 14-15 ISSUE-LOGs
2. Classify by category: 功能缺陷, 体验摩擦, 缺失需求
3. Sort by severity: 高 > 中 > 低
4. Add deferred items as "missing needs"
5. Generate Markdown document with structured sections

### REPORT-03: Anti-AI-Scent Evaluation

**Input data:**
- Chapter content from ChapterRepository (100 chapters, ~300-500 chars each)
- AntiAIScentProcessor.synonymKeys -- list of banned phrases that were auto-removed
- ProcessingResult.highlights from processing each chapter

**Computation:**
1. Select N random paragraphs (e.g., 10-15) from 100 chapters
2. Present each paragraph to human evaluator
3. Human judges "AI generated" (true) or "human written" (false)
4. Tally: how many did the human correctly identify as AI-generated?
5. Compare against AntiAIScentProcessor highlight counts (lower highlights = better anti-AI-scent)

### REPORT-04: Knowledge Base Consistency

**Input data:**
- CharacterCardRepository: character cards with name, personality, appearance, backstory
- WorldSettingRepository: settings with rules, factions, geography, techLevel
- SkillRepository: active skill documents with structured sections
- ChapterRepository: 100 chapters of generated content
- NameIndexService: name matching with aliases
- DeviationDetectionService: AI-powered deviation detection (optional)

**Computation:**
1. For each character card: check name/alias presence across all 100 chapters
2. For concrete attributes (appearance, power level): keyword search in chapter text
3. For semantic attributes (personality, behavior): optionally use AI evaluation
4. For world settings: check rule/faction/technology consistency
5. For skills: use DeviationDetectionService results (87 warnings across 30 chapters from Phase 14)
6. Compute drift score: how much did portrayal change from chapter 1 to chapter 100?
7. Flag entities with highest drift for human review
