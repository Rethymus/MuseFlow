# Phase 12: Token Audit Infrastructure - Research

**Researched:** 2026-06-06
**Domain:** Token usage tracking for AI API calls in Flutter/Dart with Hive persistence and fl_chart visualization
**Confidence:** HIGH

## Summary

This phase builds automatic token usage recording for every AI API call in MuseFlow. The core challenge is capturing usage data from the streaming OpenAI-compatible API responses, which currently discard usage data entirely. The `openai_dart` package provides a `ChatStreamAccumulator` class that accumulates `Usage` data (promptTokens, completionTokens, totalTokens) from the final streaming event, and `ChatCompletionCreateRequest` supports `streamOptions: StreamOptions(includeUsage: true)` to request usage data in streaming mode [VERIFIED: openai_dart 6.1.0 source code]. However, CONTEXT.md defers `stream_options` to keep estimation sufficient, meaning the `TokenBudgetCalculator` text estimation serves as the primary token counting method.

The architecture centers on a `TokenAuditMiddleware` added to the existing `PromptPipeline` middleware chain, an independent Hive box (`token_audit`) for persistence, and two UI surfaces: an embedded summary card in the existing `WritingStatsPage` and a dedicated `TokenAuditPage` with fl_chart visualizations. Six AI call sites need modification to pass operation type and manuscript/chapter ID context. A debatched write pattern (reusing the `WritingStatsCollector` 30-second debounce approach) prevents excessive Hive I/O during rapid AI operations.

**Primary recommendation:** Modify `OpenAIAdapter.createStream()` to optionally accept a callback that receives the accumulated usage data from `ChatStreamAccumulator`. Create a `TokenAuditService` that implements the debatched write pattern. Add `AuditOperationType` enum and `AuditContext` (manuscriptId, chapterId?) to `PromptContext`. The middleware intercepts the stream wrapper to record usage on completion.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Token usage captured via Pipeline middleware. `TokenAuditMiddleware` added to existing PromptPipeline middleware chain. Callers pass operation type and associated ID context when building prompt. Middleware records audit data after stream completes. Adapter return type not changed.
- **D-02:** Two-layer UI: (1) WritingStatsPage bottom embeds Token consumption summary card (total input tokens, total output tokens, AI call count); (2) Independent TokenAuditPage shows detailed charts (per-chapter distribution, per-operation-type distribution). Stats page AppBar or summary card provides navigation entry.
- **D-03:** This phase only displays token counts and distributions, no currency cost conversion. AUDIT-03's "total cost" in this phase means "total token consumption." Currency cost estimation deferred to Phase 16 (REPORT-01).
- **D-04:** 4 functional groups for operation types: Organize (synthesis), Edit (rewrite + polish + freeInput), Worldview (skillGen + opening + deviationDetect), Template (templateComplete).
- **D-05:** manuscriptId + chapterId dual-dimension association. All AI calls associate at least manuscriptId. Chapter-context operations additionally associate chapterId. No-chapter-context calls associate only manuscriptId with chapterId as null. Audit page supports viewing by manuscript and by chapter dimensions.
- **D-06:** Audit records have auto-cleanup with upper limit. When exceeded, oldest records deleted chronologically, keeping newest records.

### Claude's Discretion
- Cleanup limit count (suggest 10000 records, approx 100 chapters with 10x margin)
- TokenAuditMiddleware specific implementation approach (how to capture usage data after stream completion in PromptPipeline middleware chain)
- Operation type Chinese labels and enum naming
- Token estimation method: use usage field from API response (openai_dart may return in stream end event), or fallback to TokenBudgetCalculator text estimation
- TokenAuditPage specific chart types (bar chart, pie chart, etc.)

### Deferred Ideas (OUT OF SCOPE)
- **Currency cost calculation** -- deferred to Phase 16 (REPORT-01)
- **Token precise counting (stream_options)** -- Out of Scope, estimation sufficient for this milestone
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUDIT-01 | Every AI API call records token usage (input tokens, output tokens, model name, operation type, associated chapter ID, timestamp) | `openai_dart` `ChatStreamAccumulator` accumulates `Usage` (promptTokens, completionTokens, totalTokens) from final stream event [VERIFIED: source]. `TokenBudgetCalculator` provides fallback estimation. `AuditOperationType` enum maps to 4 groups per D-04. `PromptContext` extended with `AuditContext` carries manuscriptId/chapterId per D-05. |
| AUDIT-02 | Token audit data persisted to independent Hive box (TokenAuditRecord entity), no intrusion into existing Chapter/Manuscript domain layer | New `token_audit` Hive box. Manual TypeAdapter with HiveTypeId 10 (next available). JSON-serialized via toJson/fromJson (no freezed required -- follows existing pattern from `WritingStatsRepository`). Chapter and Manuscript entities unchanged. |
| AUDIT-03 | Viewable token consumption summary page (total cost, per-chapter distribution, per-operation-type distribution) | WritingStatsPage gets embedded `TokenSummaryCard` using `StatsSummaryCard` pattern. New `TokenAuditPage` uses fl_chart (already in project at ^1.2.0) for bar chart (per-chapter) and pie chart (per-operation-type). Route added under `/stats` branch. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token usage capture (stream interception) | Application | Infrastructure | Application-tier middleware wraps the AI call; infrastructure-tier adapter provides raw stream data |
| Audit record persistence | Infrastructure | -- | Hive box interaction is infrastructure-layer concern |
| Audit record domain entity | Domain | -- | Pure Dart entity with no Flutter dependencies, per clean architecture |
| Debatched write scheduling | Application | -- | Timer-based debounce is application logic (same tier as WritingStatsCollector) |
| Token usage estimation (fallback) | Application | -- | TokenBudgetCalculator already lives in application tier |
| Summary card (embedded in stats page) | Presentation | Application | UI widget reads from application-tier notifier |
| Detailed audit page with charts | Presentation | Application | UI page reads aggregated data from application-tier provider |
| Operation type classification | Domain | -- | Enum definition is a pure domain concept |
| Route registration | Presentation | -- | go_router route definition is presentation concern |
| Hive TypeAdapter registration | Infrastructure | -- | Adapter registration in main.dart is infrastructure bootstrap |

## Standard Stack

### Core (all already in project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| hive_ce | ^2.19.3 | Independent `token_audit` box for audit records | Project standard for all local storage. Proven in Phases 9/11. No new package needed. |
| hive_ce_flutter | ^2.3.4 | Flutter Hive initialization | Already initialized in main.dart. `token_audit` box opens alongside existing boxes. |
| openai_dart | ^6.0.0 (6.1.0 resolved) | `ChatStreamAccumulator` for usage capture from streaming responses | Provides `Usage` class (promptTokens, completionTokens, totalTokens) and `ChatStreamAccumulator` that accumulates usage from final stream event. No new package. [VERIFIED: pub cache source] |
| fl_chart | ^1.2.0 | Bar chart (per-chapter) and pie chart (per-operation-type) on TokenAuditPage | Already used by `AIUsagePieChart`. Same charting patterns. No new package. |
| flutter_riverpod | ^3.3.1 | AsyncNotifier for audit state, providers for repository/service | Project standard state management. No new package. |
| go_router | ^17.2.3 | Route for TokenAuditPage under `/stats` branch | Project standard router. No new package. |
| uuid | ^4.5.1 | Unique IDs for TokenAuditRecord entities | Project standard for entity IDs. No new package. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| TokenBudgetCalculator (existing) | n/a | Fallback token estimation when API response lacks usage | When `ChatStreamAccumulator.usage` is null (some OpenAI-compatible providers may not return usage) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual Hive TypeAdapter | freezed + hive_generator | freezed adds code-gen complexity for a simple audit entity. Manual adapter follows existing project pattern (`FragmentAdapter`, etc.) and is more transparent. |
| Per-stream usage capture | Batch aggregation | Per-stream capture allows fine-grained per-call records with operation type and chapter association. Batch aggregation would lose per-call granularity needed for per-chapter and per-operation breakdowns. |
| TokenBudgetCalculator estimation | tiktoken Dart port | tiktoken would be more accurate but adds a heavy dependency with native code. Estimation is sufficient per CONTEXT.md deferred decision on stream_options. |

**Installation:**
```bash
# No new packages needed for this phase -- all dependencies already in pubspec.yaml
```

**Version verification:**
```bash
# All versions confirmed from pubspec.yaml:
# hive_ce: ^2.19.3 (in pubspec)
# openai_dart: ^6.0.0 (in pubspec, 6.1.0 resolved in pub cache)
# fl_chart: ^1.2.0 (in pubspec)
# flutter_riverpod: ^3.3.1 (in pubspec)
# go_router: ^17.2.3 (in pubspec)
# uuid: ^4.5.1 (in pubspec)
```

## Package Legitimacy Audit

> No new packages are installed in this phase. All required dependencies are already present in pubspec.yaml and verified in prior phases.

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| hive_ce | pub.dev | Already in project | N/A |
| openai_dart | pub.dev | Already in project | N/A |
| fl_chart | pub.dev | Already in project | N/A |
| flutter_riverpod | pub.dev | Already in project | N/A |
| go_router | pub.dev | Already in project | N/A |
| uuid | pub.dev | Already in project | N/A |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*This phase installs zero new external packages.*

## Architecture Patterns

### System Architecture Diagram

```
AI Call Sites (6 notifiers/services)
    |
    | pass AuditContext(operationType, manuscriptId, chapterId?)
    v
PromptContext (extended with auditContext field)
    |
    v
PromptPipeline.build(context)
    |
    | middleware chain processes context
    v
[List<ChatMessage>] --> OpenAIAdapter.createStream()
                          |
                          | Stream<String> + optional onUsage callback
                          v
                      Stream consumer (notifier/service)
                          |
                          | on stream completion: callback(Usage?)
                          v
TokenAuditMiddleware / TokenAuditService.record()
                          |
                          | debatched 30s timer
                          v
                  TokenAuditRepository
                          |
                          | Hive box 'token_audit'
                          v
                  [TokenAuditRecord] entities

                    === UI Reading Path ===

TokenAuditNotifier (AsyncNotifier)
    |
    | reads from TokenAuditRepository
    | aggregates: totals, per-chapter, per-operation-type
    v
WritingStatsPage (embedded TokenSummaryCard)
TokenAuditPage (bar chart + pie chart via fl_chart)
```

### Recommended Project Structure
```
lib/
  features/
    stats/
      domain/
        token_audit_record.dart      # Immutable audit record entity
        audit_operation_type.dart    # Enum: synthesis, rewrite, polish, freeInput, skillGen, opening, deviationDetect, templateComplete
      application/
        token_audit_service.dart     # Debatched write service (30s debounce, auto-cleanup)
        token_audit_notifier.dart    # AsyncNotifier for UI state (aggregations)
      infrastructure/
        token_audit_repository.dart  # Hive box CRUD for token_audit records
      presentation/
        token_summary_card.dart      # Embedded card for WritingStatsPage
        token_audit_page.dart        # Dedicated page with fl_chart charts
  features/ai/
    application/
      prompt_pipeline.dart           # Modified: PromptContext gets auditContext field
      token_audit_middleware.dart    # New middleware (or logic in TokenAuditService)
    infrastructure/
      openai_adapter.dart            # Modified: optional usage capture callback
  core/
    infrastructure/
      hive_adapters.dart             # Add TokenAuditRecordAdapter with typeId 10
    presentation/
      providers.dart                 # Add token audit providers
```

### Pattern 1: Debached Audit Write (follows WritingStatsCollector)
**What:** Buffer audit records in memory and flush to Hive on a 30-second timer
**When to use:** Every AI call completion triggers a record, but Hive writes are batched
**Example:**
```dart
// Pattern from existing WritingStatsCollector (lib/features/stats/application/writing_stats_collector.dart)
class TokenAuditService {
  final TokenAuditRepository _repository;
  final Duration debounceDuration;

  Timer? _flushTimer;
  final List<TokenAuditRecord> _pendingRecords = <TokenAuditRecord>[];

  void record(TokenAuditRecord record) {
    _pendingRecords.add(record);
    _scheduleFlush();
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingRecords.isEmpty) return;
    final records = List<TokenAuditRecord>.from(_pendingRecords);
    _pendingRecords.clear();
    await _repository.saveAll(records);
    await _repository.enforceLimit(_maxRecords);
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(debounceDuration, () => unawaited(flush()));
  }
}
```

### Pattern 2: Stream Usage Capture via ChatStreamAccumulator
**What:** Accumulate streaming events to extract usage data from final event
**When to use:** When consuming OpenAI streaming responses that may include usage in final chunk
**Example:**
```dart
// openai_dart provides ChatStreamAccumulator that captures Usage from final event
// Source: openai_dart-6.1.0/lib/src/models/streaming/chat_stream_event.dart
// The accumulator.us.age getter returns Usage? from the last event that had usage data

// Modified createStream approach:
Stream<String> createStreamWithUsage({
  required String apiKey,
  required String baseUrl,
  required String model,
  required List<ChatMessage> messages,
  void Function(Usage?)? onUsage,  // Callback for usage data
}) {
  final rawStream = client.chat.completions.createStream(request);
  final accumulator = ChatStreamAccumulator();

  return rawStream.map((event) {
    accumulator.add(event);
    final delta = event.textDelta;
    return delta ?? '';
  }).where((delta) => delta.isNotEmpty).handleError((error) {
    throw classifyException(error);
  }).transform(StreamTransformer.fromHandlers(
    handleDone: (sink) {
      onUsage?.call(accumulator.usage);
      sink.close();
    },
  ));
}
```

### Pattern 3: Independent Hive Box with Auto-Cleanup
**What:** Audit records in a standalone Hive box with size-based eviction
**When to use:** Preventing unbounded growth of audit data
**Example:**
```dart
// Pattern: manual TypeAdapter + JSON serialization (same as FragmentAdapter)
class TokenAuditRecordAdapter extends TypeAdapter<TokenAuditRecord> {
  @override
  final int typeId = HiveTypeIds.tokenAuditRecord; // 10

  @override
  TokenAuditRecord read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return TokenAuditRecord.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, TokenAuditRecord obj) {
    writer.writeMap(obj.toJson());
  }
}

// Repository auto-cleanup:
Future<void> enforceLimit(int maxRecords) async {
  final count = _box.length;
  if (count <= maxRecords) return;
  final keysToDelete = _box.keys.take(count - maxRecords).toList();
  await _box.deleteAll(keysToDelete);
}
```

### Anti-Patterns to Avoid
- **Modifying Chapter/Manuscript entities to hold audit data:** AUDIT-02 explicitly prohibits this. Audit data lives in its own box and is associated via IDs, not embedded.
- **Synchronous Hive writes on every AI call:** Would cause jank during rapid AI operations. Must use the debatched pattern.
- **Adding freezed code generation for a single simple entity:** The audit record is a simple data class. Manual toJson/fromJson + Hive TypeAdapter follows existing patterns (FragmentAdapter, etc.) and avoids build_runner overhead.
- **Creating a second PromptPipeline variant:** The middleware approach means the existing pipeline stays intact. The audit middleware wraps the stream consumption, not the pipeline itself.
- **Hardcoding operation type labels:** Use the `AuditOperationType` enum with a label map for Chinese display names. This makes Phase 16 cost estimation straightforward.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stream usage accumulation | Custom SSE parser for usage data | `openai_dart` `ChatStreamAccumulator` | Already handles multi-choice accumulation, nullable fields from various providers, tool call delta merging. 800+ lines of edge-case handling. [VERIFIED: pub cache source] |
| Token estimation | Custom tokenizer | `TokenBudgetCalculator` (existing) | Already handles Chinese 1.8x and ASCII 0.25x multipliers with 10% safety margin. Proven in production since Phase 2. |
| Debatched persistence | Custom timer-based write queue | `WritingStatsCollector` pattern (existing) | Already handles 30s debounce, pending buffer, flush on dispose, and unawaited async. Copy the pattern. |
| Chart rendering | Custom Canvas painting | `fl_chart` `PieChart` / `BarChart` | Already in project at ^1.2.0, proven in `AIUsagePieChart`. Production-quality animations and theming. |
| Summary card layout | Custom card widget | `StatsSummaryCard` (existing) | Already provides icon + title + value + optional subtitle layout with proper theming. Reuse directly. |

**Key insight:** This phase reuses more than it builds. The primary new code is the domain entity, the repository, the service, and the middleware wiring. The UI reuses existing card and chart patterns.

## Runtime State Inventory

> This is a greenfield phase adding new data structures. No existing runtime state requires migration.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None -- new `token_audit` Hive box will be created on first use | Create box, register TypeAdapter |
| Live service config | None -- no external service configuration affected | -- |
| OS-registered state | None | -- |
| Secrets/env vars | None -- no new secrets needed | -- |
| Build artifacts | None -- no build step changes | -- |

## Common Pitfalls

### Pitfall 1: OpenAI Adapter Discards Usage Data
**What goes wrong:** The current `OpenAIAdapter.createStream()` maps the raw stream to `String` deltas via `.map((event) => event.textDelta)`, completely discarding the `Usage` field from the final stream event.
**Why it happens:** The original implementation only needed text content for the typewriter effect. Usage data was never requested or captured.
**How to avoid:** Modify `createStream()` to optionally accept a `void Function(Usage?)? onUsage` callback. Use `StreamTransformer` to invoke the callback in `handleDone` after accumulating usage via `ChatStreamAccumulator`. This preserves the existing `Stream<String>` return type (D-01 constraint: "adapter return type not changed").
**Warning signs:** If `accumulator.usage` is null after stream completes, the provider did not return usage data. Fall back to `TokenBudgetCalculator` estimation.

### Pitfall 2: Missing manuscriptId/chapterId Context in AI Call Sites
**What goes wrong:** None of the 6 AI call sites currently pass manuscriptId or chapterId. The synthesis notifier has no manuscript context. The editor AI notifier has no explicit chapter ID.
**Why it happens:** These IDs were never needed before. The prompt pipeline was purely content-driven.
**How to avoid:** Extend `PromptContext` with an `auditContext` field (`AuditContext?` containing `operationType`, `manuscriptId`, `chapterId?`). Each call site must be modified to pass this context. For `SynthesisNotifier`, the manuscriptId comes from the active manuscript state. For `EditorAINotifier`, both manuscriptId (from `widget.manuscriptId`) and chapterId (from `_currentChapterId`) are available in `EditorWithSidebar` but not currently passed to the notifier.
**Warning signs:** If audit records show null manuscriptId, a call site was missed or the context was not threaded through properly.

### Pitfall 3: EditorWithSidebar Does Not Pass manuscriptId to AI Notifiers
**What goes wrong:** `EditorWithSidebar` has `widget.manuscriptId` and `_currentChapterId` but the `EditorAINotifier` and `SynthesisNotifier` have no mechanism to receive these values.
**Why it happens:** The notifiers use Riverpod's `ref.read()` to access providers, with no parameter passing for manuscript context.
**How to avoid:** Two approaches: (1) Add manuscriptId/chapterId parameters to the notifier's operation methods (e.g., `startOperation(..., manuscriptId: '...', chapterId: '...')`), or (2) Create a provider that tracks the "current editing context" (manuscriptId + chapterId) that the audit middleware can read. Approach (1) is simpler and more explicit. The `EditorWithSidebar` already has both values available.
**Warning signs:** Compilation errors if method signatures change without updating all call sites.

### Pitfall 4: Hive Box Not Opened Before First Write
**What goes wrong:** The `token_audit` box needs to be opened before any writes. If the first AI call happens before the box is ready, writes silently fail.
**Why it happens:** Hive boxes are opened asynchronously. The `WritingStatsCollector` handles this by depending on `writingStatsRepositoryProvider` which opens the box.
**How to avoid:** Create a `tokenAuditRepositoryProvider` FutureProvider that opens the box (same pattern as `writingStatsRepositoryProvider`). The `TokenAuditService` depends on this provider. If the service is not yet ready when the first AI call completes, buffer the record in the service's pending list -- the flush timer will write it once the repository is available.
**Warning signs:** Missing audit records for early-session AI calls.

### Pitfall 5: Auto-Cleanup Deleting Wrong Records
**What goes wrong:** If audit records are not stored in chronological order in the Hive box, deleting "first N records" may remove recent records instead of old ones.
**Why it happens:** Hive boxes are ordered by insertion by default, but if records are written in batches (via debatched flush), the order depends on the batch timing, not the record timestamp.
**How to avoid:** Use a timestamp-based key or query records by timestamp for cleanup. The `TokenAuditRecord.timestamp` field enables sorting. The repository's `enforceLimit()` should sort by timestamp ascending and delete the oldest.
**Warning signs:** Recent audit records disappearing from the UI.

### Pitfall 6: Race Condition Between Flush and EnforceLimit
**What goes wrong:** If `flush()` and `enforceLimit()` run concurrently (e.g., from two overlapping timer firings), records could be double-written or the wrong records deleted.
**Why it happens:** Timer-based debounce can overlap if the previous flush hasn't completed.
**How to avoid:** Use a single `flush()` method that saves records AND enforces the limit in sequence. Cancel the timer before flush and restart after. Follow the exact pattern from `WritingStatsCollector.flush()` which handles this correctly.
**Warning signs:** Duplicate audit records or missing records in the box.

## Code Examples

### Audit Operation Type Enum
```dart
// Domain entity: lib/features/stats/domain/audit_operation_type.dart
enum AuditOperationType {
  synthesis('碎片整理', 'organize'),
  rewrite('语气改写', 'edit'),
  polish('段落润色', 'edit'),
  freeInput('自由输入', 'edit'),
  skillGen('Skill生成', 'worldview'),
  opening('开篇生成', 'worldview'),
  deviationDetect('偏离检测', 'worldview'),
  templateComplete('模板补全', 'template');

  const AuditOperationType(this.label, this.group);

  /// Chinese display label for UI
  final String label;

  /// Functional group per D-04
  final String group;
}
```

### Token Audit Record Entity
```dart
// Domain entity: lib/features/stats/domain/token_audit_record.dart
class TokenAuditRecord {
  final String id;
  final int inputTokens;
  final int outputTokens;
  final String modelName;
  final AuditOperationType operationType;
  final String manuscriptId;
  final String? chapterId;
  final DateTime timestamp;

  const TokenAuditRecord({
    required this.id,
    required this.inputTokens,
    required this.outputTokens,
    required this.modelName,
    required this.operationType,
    required this.manuscriptId,
    this.chapterId,
    required this.timestamp,
  });

  int get totalTokens => inputTokens + outputTokens;

  factory TokenAuditRecord.fromJson(Map<String, dynamic> json) => TokenAuditRecord(
    id: json['id'] as String,
    inputTokens: json['inputTokens'] as int,
    outputTokens: json['outputTokens'] as int,
    modelName: json['modelName'] as String,
    operationType: AuditOperationType.values[json['operationTypeIndex'] as int],
    manuscriptId: json['manuscriptId'] as String,
    chapterId: json['chapterId'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'modelName': modelName,
    'operationTypeIndex': operationType.index,
    'manuscriptId': manuscriptId,
    'chapterId': chapterId,
    'timestamp': timestamp.toIso8601String(),
  };
}
```

### Modified OpenAIAdapter with Usage Callback
```dart
// Key change: optional onUsage callback preserves existing Stream<String> return type
// Source: verified against openai_dart-6.1.0 ChatStreamAccumulator API

Stream<String> createStream({
  required String apiKey,
  required String baseUrl,
  required String model,
  required List<ChatMessage> messages,
  double? temperature,
  double? topP,
  int? maxTokens,
  void Function(Usage?)? onUsage, // NEW: optional callback
}) {
  _validateBaseUrl(baseUrl);
  final client = _getOrCreateClient(apiKey, baseUrl);
  final request = ChatCompletionCreateRequest(
    model: model,
    messages: messages,
    temperature: temperature,
    topP: topP,
    maxTokens: maxTokens,
  );

  final rawStream = client.chat.completions.createStream(request);
  final accumulator = ChatStreamAccumulator();

  return rawStream.map((event) {
    accumulator.add(event);
    final delta = event.textDelta;
    return delta ?? '';
  }).where((delta) => delta.isNotEmpty).handleError((error) {
    throw classifyException(error);
  }).transform(StreamTransformer<String, String>.fromHandlers(
    handleDone: (sink) {
      onUsage?.call(accumulator.usage);
      sink.close();
    },
  ));
}
```

### TokenAuditService Recording (called by middleware/callers)
```dart
// Source: follows WritingStatsCollector pattern exactly
void recordAudit({
  required Usage? usage,
  required String modelName,
  required AuditOperationType operationType,
  required String manuscriptId,
  String? chapterId,
  required String inputText,  // For fallback estimation
  required String outputText, // For fallback estimation
}) {
  final inputTokens = usage?.promptTokens ??
    _tokenBudgetCalculator.estimateTokens(inputText);
  final outputTokens = usage?.completionTokens ??
    _tokenBudgetCalculator.estimateTokens(outputText);

  final record = TokenAuditRecord(
    id: const Uuid().v4(),
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    modelName: modelName,
    operationType: operationType,
    manuscriptId: manuscriptId,
    chapterId: chapterId,
    timestamp: DateTime.now(),
  );
  record(record); // Adds to _pendingRecords, schedules flush
}
```

### Embedding Token Summary in WritingStatsPage
```dart
// Pattern: follows existing _StatsContent._SummaryWrap layout
// Add to the ListView children in _StatsContent.build():

_TokenSummarySection(
  totalInputTokens: tokenSnapshot.totalInputTokens,
  totalOutputTokens: tokenSnapshot.totalOutputTokens,
  totalCalls: tokenSnapshot.totalCalls,
  onTap: () => context.go(AppConstants.tokenAudit), // new route
),
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Sync Hive writes | Debatched 30s writes | Phase 9 | Already established pattern. Must use for audit writes. |
| Single PromptPipeline | Dual (PromptPipeline + EditorPromptPipeline) | Phase 3 | Audit context must work with both pipelines. EditorPromptPipeline extends PromptPipeline. |
| No manuscript context in AI calls | ManuscriptId available via EditorWithSidebar | Phase 11 | Now available but not threaded to AI notifiers. Must thread through. |

**Deprecated/outdated:**
- Direct `Stream<String>` without usage capture: The current `createStream()` returns only text. Must be enhanced with usage callback for this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ChatStreamAccumulator` captures usage from OpenAI-compatible providers (GLM/DeepSeek) even without `stream_options` | Standard Stack | Some providers may never return usage in streaming mode. Fallback to estimation exists. MEDIUM risk. |
| A2 | HiveTypeId 10 is available (next after 9 = chapter) | Code Examples | If another type was registered with ID 10, there will be a conflict. LOW risk -- checked hive_adapters.dart, IDs 0-9 are taken. |
| A3 | `TokenBudgetCalculator.estimateTokens()` provides reasonable estimates for Chinese+mixed text | Standard Stack | If estimation is wildly off, audit data will be misleading. LOW risk -- proven since Phase 2. |
| A4 | All 6 AI call sites can access manuscriptId at their call point | Pitfall 2 | Some call sites (opening generator, template completion) may not have a manuscriptId context. These would use null or a placeholder. LOW risk -- per D-05, these operations only need manuscriptId, and the current manuscript context is available via providers. |
| A5 | fl_chart ^1.2.0 supports the bar/pie chart configurations needed for audit visualization | Standard Stack | If fl_chart API changed, chart code may need adjustment. LOW risk -- already used successfully in AIUsagePieChart. |

## Open Questions

1. **How do non-editor AI services (OpeningGeneratorService, SkillGenerationService, DeviationDetectionService, TemplateCompletionService) access manuscriptId?**
   - What we know: These services take adapter/apiKey/baseUrl/model as constructor params. They don't currently receive manuscriptId.
   - What's unclear: Whether a "current manuscript" concept exists in the app when these services are called (e.g., during onboarding, there may be no manuscript yet).
   - Recommendation: The services themselves should not change. Instead, the callers (notifiers/pages) that invoke these services should also invoke `TokenAuditService.record()` after completion, passing the manuscriptId from their own context. For onboarding (no manuscript), manuscriptId can be a special value like `'onboarding'`.

2. **Should the audit middleware wrap the entire AI call or just the stream consumption?**
   - What we know: CONTEXT.md says "middleware in the pipeline chain." But the pipeline only builds messages -- it doesn't execute the AI call itself. The actual streaming happens in the notifiers after `pipeline.build()`.
   - What's unclear: The exact interception point.
   - Recommendation: The "middleware" is really a service that the notifiers call after stream completion. The pipeline's role is only to carry the `AuditContext` through `PromptContext`. The actual recording happens at the call site level. This is simpler and more explicit than trying to wrap the stream.

## Environment Availability

> This phase has no new external dependencies beyond what's already in the project.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build/run | Yes | 3.44.0 stable | -- |
| Dart SDK | Build/run | Yes | 3.5.4 | -- |
| hive_ce | Audit persistence | Yes | ^2.19.3 | -- |
| openai_dart | Usage capture | Yes | ^6.0.0 (6.1.0 resolved) | -- |
| fl_chart | Audit charts | Yes | ^1.2.0 | -- |
| flutter_riverpod | State management | Yes | ^3.3.1 | -- |
| go_router | Routing | Yes | ^17.2.3 | -- |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none (standard flutter test) |
| Quick run command | `flutter test test/features/stats/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUDIT-01 | Token usage recorded after every AI call with all required fields | unit | `flutter test test/features/stats/domain/token_audit_record_test.dart` | Wave 0 |
| AUDIT-01 | AuditOperationType enum covers all 8 operation types and 4 groups | unit | `flutter test test/features/stats/domain/audit_operation_type_test.dart` | Wave 0 |
| AUDIT-01 | Token estimation falls back when API usage is null | unit | `flutter test test/features/stats/application/token_audit_service_test.dart` | Wave 0 |
| AUDIT-02 | Audit records persist to independent Hive box | unit | `flutter test test/features/stats/infrastructure/token_audit_repository_test.dart` | Wave 0 |
| AUDIT-02 | Auto-cleanup enforces record limit | unit | `flutter test test/features/stats/infrastructure/token_audit_repository_test.dart` | Wave 0 |
| AUDIT-03 | Token summary card displays correct totals | widget | `flutter test test/features/stats/presentation/token_summary_card_test.dart` | Wave 0 |
| AUDIT-03 | TokenAuditPage renders charts with aggregated data | widget | `flutter test test/features/stats/presentation/token_audit_page_test.dart` | Wave 0 |
| AUDIT-01 | Debatched write batches multiple records before flush | unit | `flutter test test/features/stats/application/token_audit_service_test.dart` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/stats/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/stats/domain/token_audit_record_test.dart` -- covers AUDIT-01, AUDIT-02 record serialization
- [ ] `test/features/stats/domain/audit_operation_type_test.dart` -- covers AUDIT-01 enum completeness
- [ ] `test/features/stats/application/token_audit_service_test.dart` -- covers AUDIT-01 debatched recording + fallback estimation
- [ ] `test/features/stats/infrastructure/token_audit_repository_test.dart` -- covers AUDIT-02 persistence + cleanup
- [ ] `test/features/stats/presentation/token_summary_card_test.dart` -- covers AUDIT-03 summary display
- [ ] `test/features/stats/presentation/token_audit_page_test.dart` -- covers AUDIT-03 chart rendering

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | AI API key already managed by SecureStorageService |
| V3 Session Management | no | No session changes |
| V4 Access Control | no | All audit data is local, no multi-user access |
| V5 Input Validation | yes | Audit record fields validated at construction (non-negative tokens, non-empty IDs, valid operation type enum) |
| V6 Cryptography | no | Audit data is not sensitive (token counts, not content). No encryption needed for audit box. |

### Known Threat Patterns for Flutter/Hive Local Storage

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Data tampering (local Hive box) | Tampering | Low risk -- token counts are not security-sensitive. No financial data until Phase 16. |
| Information disclosure (audit records show AI usage patterns) | Information Disclosure | Low risk -- data is local-only, no network transmission. App already stores content locally. |

## Sources

### Primary (HIGH confidence)
- openai_dart 6.1.0 source code (pub cache) -- ChatStreamAccumulator, Usage class, ChatStreamEvent.usage, StreamOptions
- Existing codebase: prompt_pipeline.dart, openai_adapter.dart, writing_stats_collector.dart, writing_stats_repository.dart, writing_stats_page.dart, providers.dart, app.dart, main.dart, hive_adapters.dart, app_constants.dart
- CONTEXT.md decisions (D-01 through D-06)

### Secondary (MEDIUM confidence)
- WebSearch verified with official source: fl_chart API for PieChart/BarChart (confirmed via existing AIUsagePieChart usage in codebase)

### Tertiary (LOW confidence)
- None -- all findings verified against codebase source

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all packages already in project, verified in pubspec.yaml
- Architecture: HIGH - patterns established in Phases 9/11, exact code reviewed
- Pitfalls: HIGH - identified from direct codebase analysis of current adapter and call sites

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 (stable -- no fast-moving dependencies)
