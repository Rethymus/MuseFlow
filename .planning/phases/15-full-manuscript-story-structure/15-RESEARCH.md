# Phase 15: Full Manuscript & Story Structure - Research

**Researched:** 2026-06-08
**Domain:** User journey validation at 100-chapter scale (story structure, format cleaning, export, statistics)
**Confidence:** HIGH

## Summary

Phase 15 is a **validation-only phase** that extends the Phase 14 xianxia manuscript from 30 chapters to 100 chapters and validates four requirements (JOURNEY-07 through JOURNEY-10) at scale. All features under test were built in Phases 5 (story structure, format cleaning, export), 9 (writing statistics), and 12 (token audit). No new production code is expected -- only test scripts extending the Phase 14 journey test infrastructure.

The research examined every service class, domain entity, and test helper that Phase 15 will invoke. All APIs are confirmed to exist, take the expected parameters, and return the documented types. The ForeshadowingEntry lifecycle (planted -> developing -> resolved), FormatCleaner pass pipeline (5 passes), ExportService three-format output, and WritingStatsCollector + TokenAuditRepository data flows are all fully wired and testable from dart test scripts using ProviderContainer overrides.

**Primary recommendation:** Extend the existing `test/journey/` test infrastructure with 4 new test files and 2 modified helpers (story_outline.dart extension + stage_prompts.dart). Each test file targets one JOURNEY requirement with automated assertions. The 70-chapter generation reuses the serial_generation_test.dart pattern with stage-specific prompts and previous-chapter summary injection.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Three-stage story arc -- Ch 31-60 Golden Core (with failed attempt/retry), Ch 61-90 Nascent Soul (tribulation/inner demons), Ch 91-100 Ascension ending
- **D-02:** Multi-conflict parallel threads -- Core Formation failure, sect scheming, senior sister captured, sect war, heart demon tribulation, heavenly tribulation
- **D-03:** Reuse Phase 14 serial_generation_test pattern + stage-specific prompts (Golden Core / Nascent Soul / Ascension each get new scene prompts)
- **D-04:** Previous chapter summary injection -- each chapter generation injects the previous chapter's summary as context
- **D-05:** 3-4 main foreshadowing threads -- planted in chapters 1-30, resolved by chapter 100
- **D-06:** Automated data-layer tests + manual UI spot-checks for foreshadowing
- **D-07:** Verify Skill guardian deviation detection works across 100 chapters (Phase 14 had 87 warnings for 30 chapters)
- **D-08:** Full 100-chapter format cleaning with three assertion categories: Markdown residue, CJK punctuation normalization, layout normalization
- **D-09:** Three-format export with multi-layer assertions (structure, content, metadata, file size)
- **D-10:** Three metric range assertions -- total word count 27k-55k, AI usage rate 95-100%, writing speed > 0
- **D-11:** Token audit record completeness -- >= 100 records, total input/output tokens in reasonable range
- **Inherited from Phase 14:** Automated-first + manual spot-checks (D-01), real GLM API (D-02), 2-3s serial delay with stop-on-error (D-03/D-04), structured issue log (D-06), xianxia world + character cards + Skill rules unchanged (D-07/08/09), 300-500 chars per chapter with enforceD11Bounds (D-11)

### Claude's Discretion
- Specific plot outlines for each stage (chapter count allocation, plot nodes)
- Content of 3-4 foreshadowing threads (specific settings for origin, secret, forbidden zone, artifact)
- Stage prompt wording for Golden Core / Nascent Soul / Ascension
- Previous chapter summary generation method (AI-generated vs. simple truncation)
- Format cleaning assertion regex details
- Export JSON metadata field verification list
- Automated test script structure and segmentation strategy
- Foreshadowing UI spot-check specific steps

### Deferred Ideas (OUT OF SCOPE)
- Complete novel package (100 chapters + summary + character map + world setting digest) in `docs/sample-novel/`
- Bilingual README (Chinese + English)
- Full-feature automated screenshots via integration_test
- Sync to remote repository
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JOURNEY-07 | Story structure validation (foreshadowing planting -> cross-chapter tracking -> resolution), logic loop detection and consistency guardian | ForeshadowingNotifier API supports add/save/markResolved/markAbandoned. ForeshadowingEntry has status lifecycle (planted->developing->resolved). ForeshadowingReminderService generates overdue reminders. DeviationDetectionService processes all 100 chapters. |
| JOURNEY-08 | Format cleaning validation (punctuation fix, layout beautification, Markdown residual cleanup) | FormatCleaner has 5 passes (whitespace, punctuation, markdown headings/lists/emphasis/HTML, paragraph spacing). FormatCleanResult has changes list with categories. All passes are deterministic and testable. |
| JOURNEY-09 | Three-format export validation (Markdown with chapter titles, TXT plain text, JSON with full metadata) | ExportService has buildMarkdown/buildTxt/buildJson methods. ExportBundle contains chapters (List<ChapterExport>), foreshadowing entries, plot nodes, guardian annotations, character cards, world settings, skill documents, metadata. ChapterExport has title, sortOrder, content. |
| JOURNEY-10 | Writing statistics validation (word count, AI usage rate, writing speed), data accurate at 100-chapter scale | StatsSnapshot has totalUnits, humanUnits, aiUnits, aiAssistRatio computed field. WritingStatsCollector has recordAiInsertion method. TokenAuditRepository has buildSnapshot returning totalCalls/totalInputTokens/totalOutputTokens. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 70-chapter generation (Ch 31-100) | Test / Dart VM | API (GLM via OpenAIAdapter) | Test script owns orchestration; GLM API provides content. No UI involved. |
| Foreshadowing lifecycle (JOURNEY-07) | Test / Dart VM | Domain (ForeshadowingEntry) | Test calls ForeshadowingNotifier API directly. Domain entities define state machine. |
| Deviation detection (JOURNEY-07) | Test / Dart VM | API (GLM via DeviationDetectionService) | Test orchestrates chapter-by-chapter calls. Each call hits GLM API for consistency checking. |
| Format cleaning (JOURNEY-08) | Test / Dart VM | Application (FormatCleaner) | FormatCleaner is pure Dart, no I/O. Test invokes clean() and asserts FormatCleanResult. |
| Three-format export (JOURNEY-09) | Test / Dart VM | Application (ExportService) | ExportService builds content strings; test asserts structure without filesystem writes. |
| Writing statistics (JOURNEY-10) | Test / Dart VM | Infrastructure (Hive) | Test reads data from repositories backed by in-memory Hive boxes. |
| Token audit (JOURNEY-10) | Test / Dart VM | Infrastructure (Hive) | Test reads TokenAuditRepository.buildSnapshot() after flushing. |

## Standard Stack

### Core (All Inherited -- No New Packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | ProviderContainer + overrides for test DI | Project constraint. Journey tests use ProviderContainer with overrides for real GLM or FakeAdapter. |
| hive_ce | ^2.19.3 | In-memory test boxes for persistence | Project storage layer. Journey tests open 14 Hive boxes in temp directories. |
| openai_dart | ^6.0.0 | GLM API streaming calls via OpenAI-compatible endpoint | Real AI generation. Usage type for token capture. |
| flutter_test | SDK | Test framework and assertions | Standard Flutter test infrastructure. |

### Test Infrastructure (All Pre-existing from Phase 13/14)

| Component | File | Purpose |
|-----------|------|---------|
| JourneyTestContainer | test/journey/helpers/journey_container.dart | ProviderContainer factory with Hive init + 14 boxes + provider overrides |
| FakeAdapter | test/automation/helpers/fake_adapter.dart | Deterministic AI adapter for no-credential test paths |
| enforceD11Bounds | test/journey/helpers/d11_bounds.dart | Post-processing: 300-500 char bounds with sentence-boundary truncation |
| StoryOutline | test/journey/helpers/story_outline.dart | 30-chapter plot point fixtures |
| XianxiaFixtures | test/journey/helpers/xianxia_fixtures.dart | Character cards + Skill rules |

### No New Packages Required

This phase installs zero packages. All code is test scripts and test helpers.

## Package Legitimacy Audit

No packages to audit -- this is a validation-only phase with no external dependencies beyond the existing project stack.

## Architecture Patterns

### System Architecture Diagram

```
[Phase 14 World State]
  (30 chapters + characters + skills + world setting)
       |
       v
[70-Chapter Generation Script]  <-- extends serial_generation_test.dart
  |-- Stage Prompts (Golden Core / Nascent Soul / Ascension)
  |-- Previous Chapter Summary Injection (D-04)
  |-- enforceD11Bounds post-processing (D-11)
  |-- GLM API (real) or Deterministic Adapter (no-credential)
  |
  |---> ChapterRepository (100 chapters persisted)
  |---> TokenAuditService (100+ audit records)
  |
  v
[JOURNEY-07: Foreshadowing Test]
  |-- ForeshadowingNotifier.add() -> 3-4 entries
  |-- Status transitions: planted -> developing -> resolved
  |-- ForeshadowingReminderService.remindersForChapter()
  |-- DeviationDetectionService.detectDeviations() x 100 chapters
  |
  v
[JOURNEY-08: Format Cleaning Test]
  |-- FormatCleaner.clean() on each of 100 chapters
  |-- Assert: no Markdown residue, no CJK punctuation mixing, no layout anomalies
  |-- Assert: idempotent (double-clean produces no additional changes)
  |
  v
[JOURNEY-09: Export Validation Test]
  |-- ExportService.buildMarkdown() -> assert ## chapter titles, sequential order
  |-- ExportService.buildTxt() -> assert no Markdown syntax
  |-- ExportService.buildJson() -> assert chapters.length == 100, metadata present
  |-- Cross-format: same content in all three formats
  |
  v
[JOURNEY-10: Statistics Accuracy Test]
  |-- StatsSnapshot: totalUnits in 27k-55k range
  |-- StatsSnapshot: aiAssistRatio near 1.0 (95-100%)
  |-- TokenAuditRepository.buildSnapshot(): totalCalls >= 100
  |-- Individual audit record field validation
```

### Recommended Project Structure

```
test/
  journey/
    helpers/
      journey_container.dart              # UNCHANGED from Phase 14
      xianxia_fixtures.dart              # UNCHANGED from Phase 14
      d11_bounds.dart                    # UNCHANGED from Phase 14
      story_outline.dart                 # EXTEND: add chapters 31-100
      stage_prompts.dart                 # NEW: three-stage prompt definitions
    serial_generation_test.dart          # EXTEND: add 70-chapter test (ch 31-100)
    full_journey_test.dart               # EXTEND: E2E to 100 chapters
    foreshadowing_lifecycle_test.dart    # NEW: JOURNEY-07
    format_cleaning_test.dart            # NEW: JOURNEY-08
    export_validation_test.dart          # NEW: JOURNEY-09
    statistics_accuracy_test.dart        # NEW: JOURNEY-10
    automated_ui_evidence_test.dart      # EXTEND: add JOURNEY-07/08/09/10 checks
```

### Pattern 1: ProviderContainer Journey Test

**What:** Each test creates a ProviderContainer with Hive temp dir, real or deterministic AI adapter, and provider overrides.
**When to use:** Every journey test file.
**Example:**

```dart
// Source: test/journey/helpers/journey_container.dart (Phase 14)
final container = await createJourneyContainer(
  apiKey: Platform.environment['GLM_API_KEY'] ?? 'journey-local-test-key',
  baseUrl: Platform.environment['GLM_BASE_URL'] ?? 'https://open.bigmodel.cn/api/paas/v4',
  model: Platform.environment['GLM_MODEL'] ?? 'glm-4-flash',
  aiAdapter: deterministicAdapter, // or null for real GLM
);
// ... run test ...
await cleanupJourneyContainer(container);
```

### Pattern 2: Foreshadowing Lifecycle Assertion

**What:** Create entries, transition through statuses, verify state at each step.
**When to use:** JOURNEY-07 test.
**Example:**

```dart
// Source: lib/features/story_structure/application/foreshadowing_notifier.dart
final notifier = container.read(foreshadowingNotifierProvider.notifier);
await notifier.add(ForeshadowingEntry(
  id: 'fs-mysterious-origin',
  title: '神秘身世',
  mode: ForeshadowingMode.detailed,
  status: ForeshadowingStatus.planted,
  plantedChapter: 3,
  targetResolutionChapter: 90,
  sourceExcerpt: '...',
  createdAt: DateTime.now(),
));
// Transition to developing
await notifier.save(entry.copyWith(status: ForeshadowingStatus.developing));
// Resolve
await notifier.markResolved(entry.id, resolvedChapter: 92);
```

### Pattern 3: FormatCleaner Batch Assertion

**What:** Run FormatCleaner on each chapter, assert no residuals remain.
**When to use:** JOURNEY-08 test.
**Example:**

```dart
// Source: lib/features/story_structure/application/format_cleaner.dart
final cleaner = const FormatCleaner();
for (final chapter in chapters) {
  final result = cleaner.clean(chapter.documentContent);
  // Markdown residue assertion
  expect(result.cleanedText, isNot(matches(r'(^|\n)#{1,6}\s')));
  // No triple+ blank lines
  expect(result.cleanedText, isNot(matches(r'\n{4,}')));
  // Idempotent
  final secondPass = cleaner.clean(result.cleanedText);
  expect(secondPass.changes, isEmpty, reason: 'Ch ${chapter.sortOrder}: not idempotent');
}
```

### Pattern 4: ExportService Three-Format Build

**What:** Build ExportBundle from 100 chapters, assert each format's properties.
**When to use:** JOURNEY-09 test.
**Example:**

```dart
// Source: lib/features/story_structure/application/export_service.dart
final exportService = ExportService(fileWriter: (_, __) async {});
final bundle = ExportBundle(
  schemaVersion: '1.0',
  manuscriptText: fullText,
  chapters: chapterExports, // 100 ChapterExport items
  foreshadowingEntries: foreshadowingList,
  // ... other fields
);
final md = exportService.buildMarkdown(bundle);
final mdHeaders = RegExp(r'^## .+$', multiLine: true).allMatches(md);
expect(mdHeaders.length, equals(100));
```

### Anti-Patterns to Avoid

- **Do not modify production code to add test-only hooks.** All services already expose the necessary APIs (FormatCleaner.clean(), ExportService.buildXxx(), ForeshadowingNotifier CRUD, WritingStatsCollector.recordAiInsertion()).
- **Do not open new Hive boxes beyond the 14 already in journey_container.dart.** The existing boxes cover all features needed.
- **Do not bypass enforceD11Bounds.** Every chapter generated (deterministic or real GLM) must go through the same post-processing as Phase 14.
- **Do not create a new DeterministicAdapter class.** Extend or reuse the existing `_DeterministicJourneyAdapter` / `_DeterministicFullJourneyAdapter` pattern from Phase 14 serial_generation_test.dart and full_journey_test.dart.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Format cleanup | Custom regex replacement | FormatCleaner.clean() | 5-pass pipeline with conservative context checks (URLs, decimals, file paths). Hand-rolled regex will corrupt valid content. |
| Export content generation | Manual string concatenation | ExportService.buildMarkdown/buildTxt/buildJson | Handles chapter sorting, line ending normalization, JSON encoding with indent. |
| Foreshadowing state tracking | Custom status enum + map | ForeshadowingNotifier + ForeshadowingEntry.copyWith() | Entry has isOverdue(), isOpen, isResolved computed getters plus Hive-persisted state. |
| Token audit counting | Manual tallying | TokenAuditRepository.buildSnapshot() | Aggregates from Hive box with proper sorting, handles empty state. |
| Writing statistics | Manual unit counting | WritingStatsCollector.recordAiInsertion() + StatsSnapshot.aiAssistRatio | Debatched writing, proper human/AI unit tracking. |

**Key insight:** All services in this phase are pure Dart (FormatCleaner, ExportService, ForeshadowingReminderService) or backed by Hive repositories. They are designed for testability and require no mocking.

## Common Pitfalls

### Pitfall 1: GLM API Rate Limiting at 100 Chapters
**What goes wrong:** 70 sequential GLM calls with 2-3s delay may hit rate limits or time out.
**Why it happens:** Phase 14 generated 30 chapters in ~20 minutes. 70 chapters will take ~40-50 minutes. API may throttle sustained requests.
**How to avoid:** Keep 3-second delays between calls. Set test timeout to 60 minutes. Use stop-on-error (rethrow on first failure). Log progress with chapter number and elapsed time.
**Warning signs:** Test hangs without progress for > 60 seconds after a chapter generation log.

### Pitfall 2: Hive Box Key Collisions Between Test Runs
**What goes wrong:** If a test container is not properly cleaned up, subsequent tests see stale data.
**Why it happens:** Hive boxes are opened in temp directories but if cleanup fails (exception before tearDown), the directory persists.
**How to avoid:** Always use try/finally for cleanup. The existing `cleanupJourneyContainer()` disposes container, closes Hive, deletes temp dir. Wrap test bodies in try/finally.
**Warning signs:** Test fails with "Box already exists" or data from a previous test run appears.

### Pitfall 3: Deterministic Adapter Chapter Count Mismatch
**What goes wrong:** The `_DeterministicJourneyAdapter` from Phase 14 uses `_chapterIndex` that only covers 30 chapters (via `index % StoryOutline.chapters.length`). With 100 chapters, the modulo wraps around.
**Why it happens:** StoryOutline.chapters has 30 entries. Chapters 31-100 need new plot points or the adapter repeats.
**How to avoid:** Extend StoryOutline.chapters to 100 entries. Update the deterministic adapter to use the full 100-entry outline.
**Warning signs:** Deterministic test shows repeated/identical chapter content after chapter 30.

### Pitfall 4: WritingStatsCollector Debounce Timing in Tests
**What goes wrong:** WritingStatsCollector uses a 30-second debounce timer. Tests that read stats immediately after recording may see zero values.
**Why it happens:** The 30s Timer has not fired yet. flush() must be called explicitly in tests.
**How to avoid:** Always call `auditService.flush()` before reading statistics. The existing tests already do this (serial_generation_test.dart line 239).
**Warning signs:** StatsSnapshot shows totalUnits=0 despite recording insertions.

### Pitfall 5: FormatCleaner False Positives on Story Content
**What goes wrong:** Some valid story content triggers format cleaning assertions (e.g., a character saying "#" or "**" in dialogue).
**Why it happens:** FormatCleaner's markdown detection is line-based and may match content that looks like markdown but is part of the story.
**How to avoid:** Run FormatCleaner and inspect the changes list. The FormatCleanResult.changes list has category and explanation for each change. If AI-generated content contains intentional markdown-like patterns, adjust assertions to check only specific categories.
**Warning signs:** FormatCleaner reports changes on what appears to be clean content.

### Pitfall 6: ExportBundle Missing Chapter Data
**What goes wrong:** ExportBundle.chapters is empty in the export test, causing assertion failures.
**Why it happens:** ExportBundle is a data container -- it must be constructed with chapters explicitly. The export service does not fetch chapters from the repository.
**How to avoid:** Construct ExportBundle with `chapters` populated from ChapterRepository. Convert Chapter entities to ChapterExport (title, sortOrder, content) before passing to ExportService.
**Warning signs:** Export output has zero chapter headers or empty content sections.

### Pitfall 7: Foreshadowing Reminder Threshold Calculation
**What goes wrong:** ForeshadowingReminderService uses `currentChapter - plantedChapter >= defaultThreshold` to compute overdue status. With defaultThreshold typically 30, entries planted in chapter 3 become overdue at chapter 33.
**Why it happens:** The threshold is not configurable per-entry. At 100-chapter scale, all early entries will trigger threshold overdue warnings.
**How to avoid:** Use a large defaultThreshold (e.g., 50 or 60) in the test, or accept that threshold overdue warnings are expected for early-planted entries. The test should verify the mechanism works, not that warnings are absent.
**Warning signs:** All foreshadowing entries show as threshold overdue by chapter 40.

## Code Examples

### Foreshadowing Entry Lifecycle (JOURNEY-07)

```dart
// Source: lib/features/story_structure/application/foreshadowing_notifier.dart
// Source: lib/features/story_structure/domain/foreshadowing_entry.dart

// Create entry in 'planted' state
final entry = ForeshadowingEntry(
  id: 'fs-ancient-artifact',
  title: '远古法器',
  mode: ForeshadowingMode.detailed,
  status: ForeshadowingStatus.planted,
  plantedChapter: 30,
  targetResolutionChapter: 95,
  sourceExcerpt: '林风发现玉简表面刻满古老符文',
  createdAt: DateTime.now(),
);
await notifier.add(entry);

// Transition to 'developing' at chapter 70
final developingEntry = entry.copyWith(
  status: ForeshadowingStatus.developing,
  notes: '玉简开始散发更强灵光，符文似乎在变化',
);
await notifier.save(developingEntry);

// Resolve at chapter 98
await notifier.markResolved(entry.id, resolvedChapter: 98);

// Verify state transitions
final allEntries = await container.read(foreshadowingNotifierProvider.future);
final resolved = allEntries.firstWhere((e) => e.id == 'fs-ancient-artifact');
expect(resolved.status, equals(ForeshadowingStatus.resolved));
expect(resolved.resolvedChapter, equals(98));
```

### Reminder Service (JOURNEY-07)

```dart
// Source: lib/features/story_structure/application/foreshadowing_reminder_service.dart
final service = container.read(foreshadowingReminderServiceProvider);
final entries = await container.read(foreshadowingNotifierProvider.future);
final reminders = service.findReminders(
  entries: entries,
  currentChapter: 85,
  defaultThreshold: 30,
);
// Should have thresholdOverdue for early-planted entries
expect(
  reminders.any((r) => r.kind == ForeshadowingReminderKind.thresholdOverdue),
  isTrue,
);
```

### Format Cleaning Assertions (JOURNEY-08)

```dart
// Source: lib/features/story_structure/application/format_cleaner.dart
final cleaner = const FormatCleaner();
final result = cleaner.clean(chapterContent);

// 1. Markdown residue: no heading markers at line start
expect(result.cleanedText, isNot(matches(r'(^|\n)#{1,6}\s')));
// No bold markers
expect(result.cleanedText, isNot(matches(r'\*\*[^*]+\*\*')));
// No code fences
expect(result.cleanedText, isNot(contains('```')));

// 2. CJK punctuation: no ASCII punctuation after Chinese characters
expect(result.cleanedText, isNot(matches(r'[一-鿿][,;:!?]')));

// 3. Layout: no 3+ consecutive blank lines
expect(result.cleanedText, isNot(matches(r'\n{4,}')));

// 4. Idempotent: second pass produces no changes
final secondPass = cleaner.clean(result.cleanedText);
expect(secondPass.changes, isEmpty);
```

### Export Three-Format Build (JOURNEY-09)

```dart
// Source: lib/features/story_structure/application/export_service.dart
// Source: lib/features/story_structure/domain/export_bundle.dart
final exportService = ExportService(fileWriter: (_, __) async {});
final bundle = ExportBundle(
  schemaVersion: '1.0',
  exportedAt: DateTime.now(),
  manuscriptText: fullManuscriptText,
  chapters: chapterExports, // List<ChapterExport> with 100 items
  foreshadowingEntries: foreshadowingEntries,
  characterCards: characterCardsJson,
  worldSettings: worldSettingsJson,
  skillDocuments: skillDocumentsJson,
);

// Markdown: 100 ## chapter headers
final md = exportService.buildMarkdown(bundle);
final mdChapterHeaders = RegExp(r'^## ', multiLine: true).allMatches(md);
expect(mdChapterHeaders.length, equals(100));

// TXT: no markdown syntax
final txt = exportService.buildTxt(bundle);
expect(txt, isNot(contains('##')));
expect(txt, isNot(contains('**')));

// JSON: parseable with 100 chapters
final json = exportService.buildJson(bundle);
final decoded = jsonDecode(json) as Map<String, dynamic>;
expect(decoded['chapters'], isA<List>());
expect((decoded['chapters'] as List).length, equals(100));
expect(decoded['schemaVersion'], equals('1.0'));
expect(decoded['exportedAt'], isNotNull);
```

### Statistics and Token Audit (JOURNEY-10)

```dart
// Source: lib/features/stats/infrastructure/token_audit_repository.dart
// Source: lib/features/stats/domain/stats_snapshot.dart

// Token audit
final auditService = await container.read(tokenAuditServiceProvider.future);
await auditService.flush(); // Critical: flush before reading
final auditRepo = await container.read(tokenAuditRepositoryProvider.future);
final snapshot = await auditRepo.buildSnapshot();

expect(snapshot.totalCalls, greaterThanOrEqualTo(100));
expect(snapshot.totalInputTokens, greaterThan(0));
expect(snapshot.totalOutputTokens, greaterThan(0));

// Per-record validation
final records = snapshot.records;
for (final record in records) {
  expect(record.inputTokens, greaterThan(0));
  expect(record.outputTokens, greaterThan(0));
  expect(record.operationType, isNotNull);
  expect(record.timestamp, isNotNull);
}
```

### Previous Chapter Summary Injection (D-04)

```dart
// Pattern for injecting previous chapter summary into generation prompt
Future<String> generateChapterWithContext({
  required int index,
  required ChapterRepository chapterRepo,
  required String manuscriptId,
  required PromptPipeline pipeline,
  required dynamic adapter,
  // ... other params
}) async {
  // Get previous chapter for summary injection
  String? previousSummary;
  if (index > 0) {
    final chapters = chapterRepo.getByManuscriptId(manuscriptId);
    final sorted = chapters..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (index - 1 < sorted.length) {
      final prevContent = sorted[index - 1].documentContent;
      // Simple truncation: first 100 chars as summary
      previousSummary = prevContent.length > 100
          ? '${prevContent.substring(0, 100)}...'
          : prevContent;
    }
  }

  final plotPoint = StoryOutline.chapters[index];
  final contextText = previousSummary != null
      ? '上一章概要：$previousSummary\n\n本章情节：$plotPoint'
      : plotPoint;

  final fragment = Fragment(id: 'frag-$index', text: contextText, createdAt: DateTime.now());
  // ... build prompt and generate ...
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual chapter content writing | AI-generated with enforceD11Bounds post-processing | Phase 14 (D-11) | 100 chapters can be generated automatically with consistent length bounds |
| Manual format checking | FormatCleaner with 5 automated passes | Phase 5 | Format issues are detectable and fixable in bulk |
| Single-chapter testing | 30-chapter serial generation with deviation detection | Phase 14 | Proven pattern now extends to 100 chapters |

**Deprecated/outdated:**
- None for this phase. All services used are current and actively maintained from Phases 5, 9, 12, and 14.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GLM API can sustain 70 sequential calls with 3s delay without rate limiting | Common Pitfalls | Test times out or fails partway through generation |
| A2 | Hive temp directory cleanup is reliable across 100-chapter test runs | Common Pitfalls | Stale data leaks between test runs |
| A3 | The deterministic adapter pattern from Phase 14 works for 100 chapters when StoryOutline is extended | Architecture Patterns | Deterministic test path fails |
| A4 | WritingStatsCollector.recordAiInsertion() accumulates correctly across 100 sequential calls after flush() | Code Examples | Statistics assertions fail |

**Note:** These assumptions are LOW risk because Phase 14 already validated 30-chapter versions of the same patterns. The scaling from 30 to 100 is the primary uncertainty.

## Open Questions

1. **Previous chapter summary injection method (D-04)**
   - What we know: CONTEXT.md gives Claude discretion to choose between AI-generated summaries and simple truncation. Phase 11 has an adjacent chapter summary mechanism.
   - What's unclear: Whether the Phase 11 mechanism is accessible from the test infrastructure or requires UI-only access.
   - Recommendation: Start with simple truncation (first 100 chars of previous chapter). AI-generated summaries would add 70 more GLM API calls and complexity.

2. **Stage prompt granularity**
   - What we know: Three stages (Golden Core Ch 31-60, Nascent Soul Ch 61-90, Ascension Ch 91-100) each need a prompt. Within each stage, individual chapters have plot points.
   - What's unclear: Whether stage prompts replace or supplement the existing StoryOutline plot points for chapters 31-100.
   - Recommendation: Stage prompts set the scene/theme for each 30/10-chapter block. Individual chapter plot points within StoryOutline provide per-chapter direction. The generation loop prepends the active stage prompt to each chapter's fragment text.

3. **Deterministic test timeout budget**
   - What we know: Phase 14 deterministic full journey runs in < 5 minutes. Phase 15 adds 70 more chapters plus 4 new test suites.
   - What's unclear: Total test execution time for all Phase 15 suites combined.
   - Recommendation: Set individual test timeouts generously (deterministic: 10 min, real GLM: 60 min). Plan for total CI time under 15 minutes for deterministic path.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Test runner | Yes | 3.44.0 | -- |
| Dart SDK | Test compilation | Yes | 3.5.4 (ships with Flutter) | -- |
| GLM API key | Real GLM test path | Conditional | -- | Deterministic adapter path runs without key |
| WSL2 Linux | Test execution | Yes | Linux 6.18.26.1-microsoft-standard-WSL2 | -- |

**Missing dependencies with no fallback:**
- None. The deterministic adapter path provides full coverage for all assertions except real GLM streaming validation.

**Missing dependencies with fallback:**
- GLM API key: If not set in environment, real GLM tests are skipped (inherited from Phase 14 skip pattern). Deterministic adapter path covers all logic assertions.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (ships with Flutter SDK 3.44.0) |
| Config file | none (test entries in test/journey/) |
| Quick run command | `flutter test test/journey/foreshadowing_lifecycle_test.dart -j 1 --timeout 300s` |
| Full suite command | `flutter test test/journey/ -j 1 --timeout 3600s` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| JOURNEY-07 | Foreshadowing lifecycle (plant/track/resolve 3-4 threads) | integration | `flutter test test/journey/foreshadowing_lifecycle_test.dart -j 1 --timeout 300s` | Wave 0 (new) |
| JOURNEY-07 | Deviation detection across 100 chapters | integration | `flutter test test/journey/serial_generation_test.dart -j 1 --timeout 3600s` | Extend existing |
| JOURNEY-08 | Format cleaning full 100-chapter run | integration | `flutter test test/journey/format_cleaning_test.dart -j 1 --timeout 300s` | Wave 0 (new) |
| JOURNEY-09 | Three-format export validation | integration | `flutter test test/journey/export_validation_test.dart -j 1 --timeout 300s` | Wave 0 (new) |
| JOURNEY-10 | Statistics accuracy + token audit | integration | `flutter test test/journey/statistics_accuracy_test.dart -j 1 --timeout 300s` | Wave 0 (new) |

### Sampling Rate
- **Per task commit:** `flutter test test/journey/{specific_test}.dart -j 1 --timeout 300s`
- **Per wave merge:** `flutter test test/journey/ -j 1 --timeout 3600s`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/journey/foreshadowing_lifecycle_test.dart` -- covers JOURNEY-07
- [ ] `test/journey/format_cleaning_test.dart` -- covers JOURNEY-08
- [ ] `test/journey/export_validation_test.dart` -- covers JOURNEY-09
- [ ] `test/journey/statistics_accuracy_test.dart` -- covers JOURNEY-10
- [ ] `test/journey/helpers/story_outline.dart` -- extend to chapters 31-100
- [ ] `test/journey/helpers/stage_prompts.dart` -- new three-stage prompt definitions

## Security Domain

> Security enforcement is enabled (default). This is a validation phase with no new production code, so the security surface is minimal.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Test scripts do not handle user authentication |
| V3 Session Management | no | No sessions in test scripts |
| V4 Access Control | no | Test scripts bypass UI access control |
| V5 Input Validation | yes | FormatCleaner validates text input; ExportService validates bundle structure |
| V6 Cryptography | no | API key passed via environment variable (existing pattern) |

### Known Threat Patterns for Test Infrastructure

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| API key leakage in test output | Information Disclosure | `_safeExceptionDiagnostic()` sanitizes error messages (redacts bearer tokens, api_key values). Inherited from Phase 14. |
| Stale Hive data between tests | Tampering | Per-container temp directories with try/finally cleanup. Inherited from Phase 14. |

## Sources

### Primary (HIGH confidence)
- Code analysis: `lib/features/story_structure/` -- FormatCleaner (578 lines), ExportService (149 lines), ForeshadowingNotifier (89 lines), ForeshadowingEntry (298 lines), ForeshadowingReminderService (102 lines)
- Code analysis: `test/journey/` -- serial_generation_test.dart (483 lines), full_journey_test.dart (435 lines), journey_container.dart (169 lines), d11_bounds.dart (48 lines), story_outline.dart (50 lines)
- Code analysis: `lib/features/stats/` -- WritingStatsCollector (96 lines), TokenAuditRepository (119 lines), StatsSnapshot (83 lines)
- Code analysis: `lib/features/knowledge/application/deviation_detection_service.dart` (149 lines)
- Phase 14 VERIFICATION.md -- 6/6 success criteria, all wiring confirmed
- Phase 14 ISSUE-LOG.md -- 6 issues (5 closed, 1 deferred), established patterns

### Secondary (MEDIUM confidence)
- Phase 15 CONTEXT.md -- 11 locked decisions, 8 discretion areas, deferred scope
- Phase 15 UI-SPEC.md -- No new UI, validation contract for JOURNEY-07/08/09/10
- Phase 14 CONTEXT.md -- Inherited decisions for generation patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all code analyzed directly, no external dependencies
- Architecture: HIGH -- all services confirmed to expose required APIs through code reading
- Pitfalls: HIGH -- derived from Phase 14 execution experience (30 chapters validated) plus scaling analysis

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (stable -- no external dependencies or fast-moving libraries)
