# Architecture Patterns: v1.3 Testing & Token Auditing Integration

**Domain:** Automated test scripts + token auditing for a Flutter creative writing app
**Researched:** 2026-06-06
**Confidence:** HIGH (based on direct codebase analysis of 50+ source and test files)

## Recommended Architecture

The v1.3 milestone adds two cross-cutting capabilities -- automated testing scripts and token consumption auditing -- to the existing Clean Architecture. These are not new user-facing features but infrastructure layers that observe, measure, and validate the existing feature stack.

### Integration Principle

Neither testing scripts nor token auditing change the core data flow. They are **observer-sidecar** patterns: they tap into existing streams and repositories without modifying domain logic. This avoids the "audit concerns leak into business logic" anti-pattern.

```
                        EXISTING FLOW (unchanged)
 Fragment -> SynthesisNotifier -> OpenAIAdapter -> Stream<String>
                                        |
                                        v
                              +-------------------+
                              | Token Audit Hook   |  (NEW - measurement tap)
                              | counts in/out tokens|
                              +-------------------+
                                        |
                                        v
                              +-------------------+
                              | TokenAuditRepository| (NEW - Hive persistence)
                              +-------------------+
                                        |
                                        v
                              +-------------------+
                              | TokenAuditNotifier | (NEW - presentation state)
                              +-------------------+

                        AUTOMATION LAYER (new)
 +-------------------+     +-------------------+     +-------------------+
 | TestOrchestrator  | --> | ScenarioRunner     | --> | AssertionCollector|
 | (Dart test)       |     | (per-chapter loop) |     | (result reporter) |
 +-------------------+     +-------------------+     +-------------------+
         |                         |
         v                         v
 ProviderContainer           Riverpod overrides
 (real app providers)        (mock adapter, in-mem Hive)
```

---

## Component Boundaries

### NEW Components

| Component | Layer | Responsibility | Communicates With |
|-----------|-------|---------------|-------------------|
| `TokenAuditRecord` | Stats/Domain | Immutable entity: timestamp, provider, model, inputTokens, outputTokens, operation type, chapterId, manuscriptId | TokenAuditRepository |
| `TokenAuditRepository` | Stats/Infrastructure | Persists TokenAuditRecord to a new Hive box `token_audit_log` | Hive CE |
| `TokenAuditNotifier` | Stats/Application | Aggregates audit records for presentation (total cost, per-session, per-chapter breakdown) | TokenAuditRepository |
| `TokenAuditSummaryPage` | Stats/Presentation | Displays token consumption analytics (new section in existing stats page) | TokenAuditNotifier |
| `TestOrchestrator` | test/automation (Dart script) | Entry point for "write 100 chapters" automated flow; manages ProviderContainer lifecycle | ScenarioRunner |
| `ScenarioRunner` | test/automation (Dart script) | Executes a single chapter creation scenario: create chapter -> synthesize -> insert -> save | ChapterNotifier, SynthesisNotifier (via ProviderContainer) |
| `AssertionCollector` | test/automation (Dart script) | Captures pass/fail results, token counts, timing data per chapter | TestOrchestrator, TokenAuditRepository |

### MODIFIED Components

| Component | Change Type | What Changes |
|-----------|-------------|-------------|
| `SynthesisNotifier._fetchKeyAndStream()` | Minor modification | Add token counting before stream (estimate input tokens from messages) and after stream (estimate output tokens from accumulatedText). Write `TokenAuditRecord` on stream completion or error. |
| `EditorAINotifier._fetchKeyAndStream()` | Minor modification | Same token audit recording pattern as SynthesisNotifier. |
| `providers.dart` | Minor addition | Register 3 new providers: `tokenAuditRepositoryProvider`, `tokenAuditNotifierProvider`. |
| `writing_stats_page.dart` | Minor addition | Add a section or tab for token audit summary display. |

### UNCHANGED Components (explicit)

These components are deliberately NOT modified to avoid scope creep:

| Component | Why Not Changed |
|-----------|----------------|
| `OpenAIAdapter` | The adapter returns `Stream<String>` and handles HTTP/error concerns. Token counting belongs at the caller level where business context (operation type, chapter ID) is available. Adding audit to the adapter would violate SRP and lose contextual data. |
| `PromptPipeline` / `PromptMiddleware` | Pipeline middlewares transform the prompt *before* the API call. Token auditing is a post-call measurement. Mixing them conflates prompt construction with observation. |
| `TokenBudgetCalculator` | Estimates tokens for budget allocation. The audit system *reuses* its `estimateTokens()` method but does not change it. |
| `ChapterAutoSave` | Works via `forceSave()` before transitions. Automation scripts call `forceSave()` directly -- no change needed. |
| `Chapter` / `Manuscript` domain entities | No new fields. Token audit records live in their own Hive box with `chapterId`/`manuscriptId` as foreign-key references. Audit is an observation about an API call, not an intrinsic property of a chapter. |
| `ChapterRepository` | No new queries. The audit repository is queried separately. |
| `WritingStatsCollector` | Existing human/AI writing-unit counting continues unchanged. Token audit is a parallel concern (API tokens vs. writing units). |

---

## Data Flow: "Write 100 Chapters" Automated Flow

This is the complete data flow for the v1.3 primary validation scenario.

### Phase 1: Setup

```
TestOrchestrator
  |
  +-- Create ProviderContainer
  |     overrides:
  |       openaiAdapterProvider -> FakeXianxiaAdapter (canned prose)
  |       OR real adapter if OPENAI_API_KEY is set (real API validation)
  |       Hive boxes -> temp directory (isolated per test run)
  |
  +-- Create manuscript (ManuscriptNotifier.add)
  |     title: "百章修仙录"
  |     genre: "修仙"
  |
  +-- Create knowledge base entries (optional)
        CharacterCardNotifier.add -> protagonist, rival, mentor
        WorldSettingNotifier.add -> cultivation system, sect hierarchy
```

### Phase 2: Per-Chapter Loop (repeated 100x)

```
for i in range(1, 101):
  ScenarioRunner.runChapter(i)
    |
    +-- Step 1: Create chapter
    |     ChapterNotifier.add(Chapter(
    |       title: "第${i}章",
    |       manuscriptId: manuscript.id,
    |       sortOrder: i - 1,
    |     ))
    |
    +-- Step 2: Prepare fragments (simulate user input)
    |     Create 2-3 Fragment entities with xianxia plot beats
    |     These represent "user's chaotic ideas" for the chapter
    |
    +-- Step 3: Select fragments
    |     Override selectedFragmentsProvider with current fragments
    |
    +-- Step 4: Trigger synthesis
    |     SynthesisNotifier.startSynthesis()
    |       |
    |       +-- Estimate input tokens from PromptContext.messages
    |       |     Record: {timestamp, provider, model, inputTokens, chapterId}
    |       |
    |       +-- OpenAIAdapter.createStream()
    |       |     Returns Stream<String> (real or fake)
    |       |
    |       +-- Collect streamed tokens
    |       |     accumulatedText grows token by token
    |       |
    |       +-- AntiAIScentProcessor.process()
    |       |     Post-processes accumulated text
    |       |
    |       +-- Estimate output tokens from accumulatedText
    |             Write TokenAuditRecord to TokenAuditRepository
    |
    +-- Step 5: Accept and insert
    |     SynthesisNotifier.confirmAndInsert()
    |     Text enters the editor document
    |
    +-- Step 6: Save chapter
    |     ChapterAutoSave.onDocumentChanged(chapterId, markdown)
    |     ChapterAutoSave.forceSave()
    |
    +-- Step 7: Collect metrics
          AssertionCollector.record({
            chapterIndex: i,
            tokenCount: auditRecord.totalTokens,
            charCount: accumulatedText.length,
            duration: elapsed,
            passed: accumulatedText.isNotEmpty,
          })
```

### Phase 3: Validation and Reporting

```
TestOrchestrator
  |
  +-- Validate 100 chapters exist
  |     ChapterNotifier.loadChapters(manuscript.id)
  |     assert chapters.length == 100
  |
  +-- Validate chapter ordering
  |     assert chapters[i].sortOrder == i
  |
  +-- Validate content integrity
  |     for each chapter: assert documentContent.isNotEmpty
  |
  +-- Generate token audit report
  |     TokenAuditNotifier.loadAuditLog()
  |     Sum: totalTokens, perChapter breakdown, perModel breakdown
  |     Estimate cost: tokens * model_price_per_1k / 1000
  |
  +-- Generate test report
  |     AssertionCollector.generateReport()
  |     Write to: .planning/reports/v1.3-test-report.md
  |
  +-- Cleanup
        Hive.deleteFromDisk()
```

---

## Patterns to Follow

### Pattern 1: Token Audit as Caller-Side Measurement (NEW)

**What:** Record token consumption at the notifier level, wrapping the existing OpenAIAdapter stream call.

**When:** Every AI API call (synthesis, editor AI operations).

**Why this pattern:** The existing PromptMiddleware chain transforms context *before* the call and cannot measure output. The adapter lacks business context (operation type, chapter ID). The notifier sits at the intersection: it has both the business context and access to the stream output.

**Example:**

```dart
/// Inside SynthesisNotifier._fetchKeyAndStream()
/// Adding audit recording around the existing stream logic.

Future<void> _fetchKeyAndStream(
  AIProvider provider,
  List<Fragment> fragments,
  String? additionalInstruction,
) async {
  // ... existing validation and budget calculation ...

  final stopwatch = Stopwatch()..start();

  // Estimate input tokens from built messages
  final calculator = ref.read(tokenBudgetCalculatorProvider);
  var inputTokens = 0;
  for (final msg in messages) {
    inputTokens += calculator.estimateTokens(msg.toString());
  }

  // ... existing streaming logic (unchanged) ...
  // await for (final token in stream) { ... }
  // await _postProcess();

  stopwatch.stop();

  // Record audit after stream completes
  if (!ref.mounted) return;
  final outputTokens = calculator.estimateTokens(state.accumulatedText);
  final auditRepo = await ref.read(tokenAuditRepositoryProvider.future);
  await auditRepo.record(TokenAuditRecord(
    id: '',
    timestamp: DateTime.now(),
    providerId: provider.id,
    model: provider.model,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    operationType: 'synthesis',
    manuscriptId: null,
    chapterId: null,
    elapsed: stopwatch.elapsed,
  ));
}
```

### Pattern 2: TokenAuditRecord Domain Entity (NEW)

**What:** A dedicated immutable entity for token audit data, following the same conventions as `WritingSession`, `Chapter`, and `AIProvider`.

**Why:** Keeps audit data separate from domain entities. `Chapter` does not need a `tokenCount` field because token consumption is an observation about an API call, not an intrinsic property of a chapter.

**Example:**

```dart
class TokenAuditRecord {
  final String id;
  final DateTime timestamp;
  final String providerId;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final String operationType; // 'synthesis', 'tone_rewrite', 'polish', 'free_input'
  final String? manuscriptId;
  final String? chapterId;
  final Duration elapsed;

  const TokenAuditRecord({
    required this.id,
    required this.timestamp,
    required this.providerId,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.operationType,
    this.manuscriptId,
    this.chapterId,
    required this.elapsed,
  });

  int get totalTokens => inputTokens + outputTokens;
  // copyWith, toJson, fromJson follow project conventions (see Chapter, AIProvider)
}
```

### Pattern 3: Dart Test Scripts as Automation (NEW)

**What:** Standalone `dart test` files that exercise the full feature stack via Riverpod `ProviderContainer`, without Flutter widget tree.

**When:** Automated validation scenarios like "write 100 chapters" that do not need UI rendering.

**Why:** Flutter integration tests (`integration_test/`) require a running app with rendering. For pure logic validation (CRUD, AI pipeline, state management), Dart unit tests with `ProviderContainer` are faster and more reliable. The codebase already uses this pattern in `synthesis_notifier_test.dart`.

**Example:**

```dart
/// test/automation/hundred_chapter_test.dart
///
/// Run with fake adapter (default):
///   dart test test/automation/hundred_chapter_test.dart
///
/// Run with real API (requires key):
///   OPENAI_API_KEY=sk-... dart test test/automation/hundred_chapter_test.dart

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hundred Chapter Xianxia', () {
    late ProviderContainer container;

    setUp(() async {
      await setUpHiveTest();
      container = ProviderContainer(overrides: [
        openaiAdapterProvider.overrideWithValue(FakeXianxiaAdapter()),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await tearDownHiveTest();
    });

    test('create 100 chapters with synthesis', () async {
      // ScenarioRunner loop as described in data flow
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
```

### Pattern 4: Existing Test Fake Pattern (follow established convention)

**What:** Subclass `OpenAIAdapter` and override `createStream()` to return controlled data.

**Why:** The codebase already establishes this pattern in `synthesis_notifier_test.dart` via `_FakeOpenAIAdapter`. Following it avoids introducing mockito/mocktail and stays consistent.

**Example (extending existing pattern):**

```dart
class FakeXianxiaAdapter extends OpenAIAdapter {
  int callCount = 0;

  static const _chapterTemplates = [
    '剑气纵横三万里，一剑光寒十九洲。少年站在悬崖之上，...',
    '灵气在经脉中奔涌，他感受到前所未有的突破。...',
  ];

  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
  }) {
    callCount++;
    final text = _chapterTemplates[callCount % _chapterTemplates.length];
    return Stream.fromIterable(text.split(''));
  }
}
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Token Counting Inside OpenAIAdapter

**What:** Adding token counting logic inside `OpenAIAdapter.createStream()`.
**Why bad:** Violates single responsibility. The adapter's job is HTTP communication and error classification. Token counting is a measurement concern that belongs at the caller level (notifiers), where the business context (operation type, chapter ID) is available.
**Instead:** Count tokens in the notifiers before and after the adapter call.

### Anti-Pattern 2: Token Audit as a PromptMiddleware

**What:** Creating a `TokenAuditMiddleware` that plugs into the existing `PromptPipeline`.
**Why bad:** The pipeline runs *before* the API call. It cannot measure output tokens. It also lacks access to the provider identity, chapter context, and timing data that audit needs.
**Instead:** Token audit is a caller-side concern in the notifiers, not a prompt transformation.

### Anti-Pattern 3: Automation Scripts That Drive the Widget Tree

**What:** Using `testWidgets()` with `tester.tap()` and `find.text()` to simulate the 100-chapter flow.
**Why bad:** Widget tests are slow (10-30 seconds per interaction), flaky (timing-dependent), and unnecessary for validating business logic. The 100-chapter flow exercises providers, repositories, and notifiers -- none of which require a widget tree.
**Instead:** Use `ProviderContainer` directly in Dart test files. Reserve widget tests for UI-specific validations.

### Anti-Pattern 4: Modifying Domain Entities for Audit

**What:** Adding a `tokenCount` field to `Chapter` or `Manuscript`.
**Why bad:** Token consumption is an observation about an API call, not an intrinsic property of a chapter. Chapters exist independent of how many tokens were used to create them. Mixing audit data into domain entities couples observation to identity.
**Instead:** Separate `TokenAuditRecord` entity in its own Hive box with `chapterId` as a foreign-key reference.

### Anti-Pattern 5: Shared Mutable Test State Without Isolation

**What:** Using `setUpAll` for shared state across all 100 chapters, so a failure at chapter 47 cascades errors through chapters 48-100.
**Why bad:** The 100-chapter test accumulates state. A single failure should not produce 53 cascading failures that obscure the root cause.
**Instead:** Use `AssertionCollector` that records per-chapter pass/fail independently, then asserts aggregate results at the end. Individual chapter failures are logged but do not halt execution.

---

## File Placement Map

```
lib/
  features/
    stats/
      domain/
        token_audit_record.dart          (NEW - domain entity)
      application/
        token_audit_notifier.dart        (NEW - aggregation logic)
      infrastructure/
        token_audit_repository.dart      (NEW - Hive persistence)
      presentation/
        token_audit_summary_page.dart    (NEW - analytics UI)
  core/
    presentation/
      providers.dart                     (MODIFIED - add 2-3 providers)

test/
  automation/                            (NEW directory)
    hundred_chapter_test.dart            (NEW - 100-chapter orchestration)
    scenario_runner.dart                 (NEW - per-chapter logic)
    assertion_collector.dart             (NEW - result collection)
    fake_xianxia_adapter.dart            (NEW - canned xianxia text)
    test_reporter.dart                   (NEW - markdown report generation)
  helpers/
    hive_test_helper.dart                (EXISTING - reuse as-is)
    provider_container_helper.dart       (NEW - shared container setup)
  features/
    stats/
      application/
        token_audit_notifier_test.dart   (NEW - unit tests for notifier)
      infrastructure/
        token_audit_repository_test.dart (NEW - unit tests for repository)

integration_test/
  token_audit_flow_test.dart            (NEW - Flutter-level integration test)
```

---

## Scalability Considerations

| Concern | At 100 chapters (~1K words) | At 1000 chapters (stress test) | At production use |
|---------|---------------------------|-------------------------------|-------------------|
| Token audit log size | ~100 records, <50KB | ~1000 records, ~200KB in Hive | Prune records older than 90 days |
| Test execution time | ~2 min (fake) / ~30 min (real API) | ~20 min (fake) / ~5 hrs (real API) | Batch execution, parallel chapter groups |
| Hive box memory | All in-memory, ~1MB | ~10MB, still fine | Lazy loading, pagination in audit UI |
| Report file size | ~20KB markdown | ~200KB markdown | JSON format, rendered dashboard |

---

## Build Order (Dependency-Aware)

Recommended implementation order based on dependency analysis. Each step is independently testable.

### Step 1: Token Audit Domain + Infrastructure (no UI, no notifiers)

Build the data layer first. Everything else depends on it.

| # | File | Type |
|---|------|------|
| 1 | `lib/features/stats/domain/token_audit_record.dart` | NEW entity |
| 2 | `lib/features/stats/infrastructure/token_audit_repository.dart` | NEW repository |
| 3 | `test/features/stats/infrastructure/token_audit_repository_test.dart` | NEW test |

**Dependencies:** Hive CE (existing), `TokenBudgetCalculator.estimateTokens()` (existing). Zero coupling to other new code.

### Step 2: Token Audit Integration into Existing Notifiers

Wire token counting into the two AI call sites.

| # | File | Type |
|---|------|------|
| 4 | `lib/features/ai/presentation/synthesis_notifier.dart` | MODIFIED |
| 5 | `lib/features/editor/application/editor_ai_notifier.dart` | MODIFIED |
| 6 | `lib/core/presentation/providers.dart` | MODIFIED (add providers) |
| 7 | `test/features/ai/presentation/synthesis_notifier_test.dart` | MODIFIED |
| 8 | `test/features/editor/application/editor_ai_notifier_test.dart` | MODIFIED |

**Dependencies:** Step 1 (TokenAuditRecord + repository).

### Step 3: Token Audit Aggregation + Presentation

Build the read side of the audit system.

| # | File | Type |
|---|------|------|
| 9 | `lib/features/stats/application/token_audit_notifier.dart` | NEW |
| 10 | `test/features/stats/application/token_audit_notifier_test.dart` | NEW |
| 11 | `lib/features/stats/presentation/token_audit_summary_page.dart` | NEW |
| 12 | Navigation wiring in stats page | MODIFIED |

**Dependencies:** Step 1 (repository). Step 2 is NOT a dependency (presentation reads from the same repository).

### Step 4: Automation Script Infrastructure

Build the test harness. Can be done in parallel with Steps 2-3.

| # | File | Type |
|---|------|------|
| 13 | `test/automation/fake_xianxia_adapter.dart` | NEW |
| 14 | `test/automation/scenario_runner.dart` | NEW |
| 15 | `test/automation/assertion_collector.dart` | NEW |
| 16 | `test/automation/test_reporter.dart` | NEW |
| 17 | `test/helpers/provider_container_helper.dart` | NEW |

**Dependencies:** None (pure test code). Uses existing patterns from `synthesis_notifier_test.dart`.

### Step 5: Full Automation Scenario

The capstone that exercises everything built in Steps 1-4.

| # | File | Type |
|---|------|------|
| 18 | `test/automation/hundred_chapter_test.dart` | NEW |
| 19 | Run with fake adapter, verify all assertions pass | Execution |
| 20 | Run with real API key (optional, manual), collect token audit data | Execution |

**Dependencies:** Steps 1-4.

### Step 6: Integration Test (Flutter-level)

| # | File | Type |
|---|------|------|
| 21 | `integration_test/token_audit_flow_test.dart` | NEW |

**Dependencies:** Steps 1-3 (full feature implemented).

---

## Token Estimation Accuracy Notes

The existing `TokenBudgetCalculator.estimateTokens()` uses a 1.8x multiplier for Chinese characters and 0.25x for ASCII, with a 10% safety margin. For v1.3 token auditing:

- **Input tokens:** Use `estimateTokens()` on the serialized prompt messages. Same estimation used for budget allocation, ensuring consistency.
- **Output tokens:** Use `estimateTokens()` on the accumulated response text.
- **Limitation:** This is an approximation, not exact tokenizer output (tiktoken for OpenAI, Claude's tokenizer). The audit report should label these as "estimated tokens" not "actual tokens."
- **Future improvement path:** The OpenAI streaming API supports `stream_options: { include_usage: true }` which returns a final chunk with actual token counts. This could replace estimation in a future iteration, but requires changes to `OpenAIAdapter` and is out of scope for v1.3.

---

## Sources

| Source | Confidence | What It Verified |
|--------|------------|------------------|
| Direct codebase analysis (50+ files) | HIGH | All architecture decisions, existing patterns, integration points |
| `providers.dart` (679 lines) | HIGH | Provider wiring pattern, dependency graph, where to add new providers |
| `synthesis_notifier.dart` + `synthesis_notifier_test.dart` | HIGH | Existing test fake pattern, ProviderContainer override approach |
| `openai_adapter.dart` | HIGH | Stream API surface, error classification, why token counting should NOT go there |
| `prompt_pipeline.dart` | HIGH | Middleware chain design, why token audit is not a middleware |
| `token_budget_calculator.dart` | HIGH | Existing estimation logic to reuse for audit |
| `writing_stats_collector.dart` + `writing_stats_repository.dart` | HIGH | Existing stats pattern to follow for audit records |
| `chapter_notifier.dart` + `chapter_auto_save.dart` | HIGH | Chapter lifecycle, forceSave pattern for automation |
| `editor_ai_notifier.dart` | HIGH | Second AI call site that needs audit integration |
| `integration_test/app_test.dart` | HIGH | Existing integration test pattern |
| `test/streaming/sse_streaming_test.dart` | HIGH | Real API test pattern with env var gating |
| PROJECT.md v1.3 requirements | HIGH | Milestone scope, constraints, target deliverables |

---
*Architecture researched: 2026-06-06 for v1.3 milestone*
