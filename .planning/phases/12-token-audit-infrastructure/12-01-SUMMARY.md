---
phase: 12-token-audit-infrastructure
plan: 01
subsystem: stats
tags: [domain, infrastructure, audit, hive]
dependency_graph:
  requires: [Phase 11 (chapter persistence)]
  provides: [token audit foundation for Phase 12-02 and 12-03]
  affects: [stats module, AI infrastructure]
tech_stack:
  added: []
  patterns: [debatched writes, Hive TypeAdapter, AsyncNotifier aggregation]
key_files:
  created:
    - lib/features/stats/domain/token_audit_record.dart
    - lib/features/stats/domain/audit_operation_type.dart
    - lib/features/stats/infrastructure/token_audit_repository.dart
    - lib/features/stats/application/token_audit_service.dart
    - lib/features/stats/application/token_audit_notifier.dart
  modified:
    - lib/core/infrastructure/hive_adapters.dart
    - lib/main.dart
    - lib/core/presentation/providers.dart
    - lib/features/ai/infrastructure/openai_adapter.dart
decisions:
  - Enhanced enum pattern for AuditOperationType with Chinese labels and 4 functional groups
  - Hive TypeId 10 for TokenAuditRecord
  - 30s debounce timer for debatched writes (same pattern as WritingStatsCollector)
  - 10000 record cleanup limit with timestamp-based deletion (oldest first)
  - Optional onUsage callback in OpenAIAdapter.createStream for backward compatibility
metrics:
  duration_seconds: 644
  tasks_completed: 2
  files_created: 5
  files_modified: 4
  tests_added: 49
  commits: 2
completed_date: 2026-06-06
---

# Phase 12 Plan 01: Token Audit Infrastructure Summary

**One-liner:** Complete token audit foundation with domain entities, Hive persistence with auto-cleanup, 30s debatched service, and OpenAI adapter usage callback integration.

## What Was Built

Built the complete token usage tracking infrastructure for AI API calls:

**Domain Layer:**
- `TokenAuditRecord` entity with 8 fields (id, inputTokens, outputTokens, modelName, operationType, manuscriptId, chapterId?, timestamp)
- `AuditOperationType` enhanced enum with 8 operation types, Chinese labels, and 4 functional groups (organize, edit, worldview, template)
- Immutable entity with toJson/fromJson, copyWith, validation (non-negative token counts)

**Infrastructure Layer:**
- `TokenAuditRepository` with independent 'token_audit' Hive box
- Auto-cleanup at 10000 records (deletes oldest by timestamp)
- `TokenAuditRecordAdapter` with HiveTypeId 10, registered in main.dart

**Application Layer:**
- `TokenAuditService` with 30s debounce timer for debatched writes
- Fallback to `TokenBudgetCalculator` when API usage is null
- `TokenAuditNotifier` AsyncNotifier exposing aggregated snapshot (totals, records)
- `TokenAuditSnapshot` immutable state model

**AI Integration:**
- Modified `OpenAIAdapter.createStream()` to accept optional `onUsage` callback
- Uses `ChatStreamAccumulator` to capture usage from final stream event
- Backward compatible (callback is optional)

**Providers:**
- `tokenAuditRepositoryProvider` - opens 'token_audit' Hive box
- `tokenAuditServiceProvider` - creates service with dispose lifecycle
- `tokenAuditNotifierProvider` - exposes aggregated audit state

## Tests

**49 tests added, all passing:**
- 12 tests for `TokenAuditRecord` (JSON serialization, validation, getters)
- 12 tests for `AuditOperationType` (enum values, labels, groups)
- 7 tests for `TokenAuditRepository` (CRUD, auto-cleanup, count)
- 9 tests for `TokenAuditService` (debounce, flush, fallback estimation, dispose)
- 6 tests for `TokenAuditNotifier` (aggregation, snapshot)
- 3 tests for `TokenAuditSnapshot` (creation, copyWith)

## Deviations from Plan

### Auto-fixed Issues

**None** - plan executed exactly as written.

### Fixes Applied

**1. [Rule 1 - Bug] Fixed fake adapter signatures in existing tests**
- **Found during:** Task 2 verification (flutter analyze)
- **Issue:** 4 test files had `_FakeOpenAIAdapter.createStream()` without the new `onUsage` parameter, causing invalid override errors
- **Fix:** Added `void Function(Usage?)? onUsage` parameter to all fake adapters
- **Files modified:** 
  - test/features/ai/presentation/synthesis_notifier_test.dart
  - test/features/editor/application/editor_ai_notifier_test.dart
  - test/features/knowledge/application/deviation_detection_service_test.dart
  - test/features/knowledge/application/skill_generation_service_test.dart
- **Commit:** bf3fbdf

**2. [Rule 3 - Blocking] Fixed Usage constructor calls in tests**
- **Found during:** Task 2 test execution
- **Issue:** `openai_dart` 6.1.0 requires `totalTokens` parameter in `Usage` constructor
- **Fix:** Updated all test Usage constructors to include `totalTokens: promptTokens + completionTokens`
- **Files modified:** test/features/stats/application/token_audit_service_test.dart
- **Commit:** bf3fbdf

**3. [Rule 3 - Blocking] Added missing dart:async import**
- **Found during:** Task 2 compilation
- **Issue:** `StreamTransformer` not available in openai_adapter.dart
- **Fix:** Added `import 'dart:async';` to lib/features/ai/infrastructure/openai_adapter.dart
- **Commit:** bf3fbdf

## Verification

All verification steps passed:

1. ✅ `flutter test test/features/stats/domain/` - all domain entity tests pass
2. ✅ `flutter test test/features/stats/infrastructure/token_audit_repository_test.dart` - persistence and cleanup tests pass
3. ✅ `flutter test test/features/stats/application/token_audit_service_test.dart` - debatched write and fallback estimation tests pass
4. ✅ `flutter test test/features/stats/application/token_audit_notifier_test.dart` - notifier aggregation tests pass
5. ✅ `flutter analyze` - zero errors
6. ✅ Verify HiveTypeId 10: `grep -c 'tokenAuditRecord' lib/core/infrastructure/hive_adapters.dart` returns 1
7. ✅ Verify adapter registered: `grep -c 'TokenAuditRecordAdapter' lib/main.dart` returns 1
8. ✅ Verify onUsage parameter: `grep -c 'onUsage' lib/features/ai/infrastructure/openai_adapter.dart` returns 4

## Key Design Decisions

1. **Debatched writes pattern:** Reused exact pattern from `WritingStatsCollector` with 30s timer to prevent excessive Hive I/O during rapid AI operations.

2. **Cleanup strategy:** 10000 record limit chosen to accommodate ~100 chapters with 10x margin. Cleanup deletes oldest records by timestamp, preserving newest data.

3. **Optional callback design:** `onUsage` parameter is optional in `createStream()` to maintain backward compatibility with existing call sites. No breaking changes to AI infrastructure.

4. **Fallback estimation:** When API providers don't return usage data, service falls back to `TokenBudgetCalculator` text estimation (Chinese 1.8x, ASCII 0.25x, 10% safety margin).

5. **Enum-as-index storage:** `operationType` stored as integer index in JSON to minimize storage overhead. Safer than string-based storage (no typos, version-agnostic).

## Integration Points

**Downstream dependencies (ready for Phase 12-02):**
- All 6 AI call sites can now pass audit context to middleware
- `TokenAuditService.recordAudit()` ready to receive calls from middleware
- Repository auto-cleanup ensures bounded storage growth

**No breaking changes:**
- Existing AI call sites unchanged (onUsage callback is optional)
- All existing tests pass with fake adapter updates

## Known Stubs

None. This is pure infrastructure - no UI components or stub data.

## Threat Flags

None. All threats from PLAN.md threat model were accepted or mitigated:
- T-12-03 (Input Validation): Mitigated via constructor assertions (inputTokens >= 0, outputTokens >= 0)

## Self-Check: PASSED

✅ All created files exist:
- lib/features/stats/domain/token_audit_record.dart
- lib/features/stats/domain/audit_operation_type.dart
- lib/features/stats/infrastructure/token_audit_repository.dart
- lib/features/stats/application/token_audit_service.dart
- lib/features/stats/application/token_audit_notifier.dart

✅ All commits exist:
- 4f3daf9: test(12-01): add failing tests for TokenAuditRecord and AuditOperationType
- 713a507: feat(12-01): implement TokenAuditRecord entity and Hive adapter
- bf3fbdf: feat(12-01): implement token audit infrastructure

✅ All tests pass (49 tests)
✅ Flutter analyze reports zero errors
✅ All modified files compile successfully
