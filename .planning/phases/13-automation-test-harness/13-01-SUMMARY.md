---
phase: 13-automation-test-harness
plan: 01
plan_name: AIAdapter Interface and FakeAdapter Test Infrastructure
subsystem: automation-test-harness
tags:
  - ai-adapter
  - test-infrastructure
  - provider-overrides
  - hive-test
requires: []
provides:
  - AIAdapter abstract interface
  - FakeAdapter deterministic AI test double
  - automation ProviderContainer factory
  - xianxia/manuscript fixtures
affects:
  - lib/features/ai
  - lib/core/presentation/providers.dart
  - test/automation
decisions:
  - "D-01: Extracted AIAdapter from OpenAIAdapter to enable deterministic test doubles."
  - "D-02: Provider and dependent AI services now depend on AIAdapter rather than OpenAIAdapter."
  - "D-03: FakeAdapter supports deterministic xianxia output, usage callbacks, error text mode, and empty stream mode."
tech_stack:
  added: []
  patterns:
    - Riverpod Provider override with FakeAdapter
    - Hive temp directory setup for automation tests
    - Deterministic streaming test double
key_files:
  created:
    - lib/features/ai/domain/ai_adapter.dart
    - test/features/ai/domain/ai_adapter_test.dart
    - test/automation/helpers/fake_adapter.dart
    - test/automation/helpers/fake_adapter_test.dart
    - test/automation/helpers/test_container.dart
    - test/automation/fixtures/xianxia_content.dart
    - test/automation/fixtures/manuscript_fixtures.dart
  modified:
    - lib/features/ai/infrastructure/openai_adapter.dart
    - lib/core/presentation/providers.dart
    - lib/features/knowledge/application/skill_generation_service.dart
    - lib/features/knowledge/application/deviation_detection_service.dart
    - lib/features/templates/application/template_completion_service.dart
    - lib/features/onboarding/application/opening_generator_service.dart
metrics:
  completed_at: "2026-06-07T15:58:00Z"
  duration_minutes: 28
  tasks_completed: 2
  files_created: 7
  files_modified: 6
  tests_added: 11
---

# Phase 13 Plan 01: AIAdapter Interface and FakeAdapter Test Infrastructure Summary

## One-Liner

AI streaming was abstracted behind `AIAdapter`, enabling deterministic `FakeAdapter` provider overrides for Phase 13 automation tests without real API calls.

## Tasks Completed

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Extract AIAdapter interface, refactor OpenAIAdapter, update provider type | f79de2e | Complete |
| 2 | Build FakeAdapter, test container factory, and test fixtures | c1dd182 | Complete |

## What Changed

### Production code

- Added `AIAdapter` domain interface with the same `createStream` signature as `OpenAIAdapter`, including `onUsage`.
- Updated `OpenAIAdapter` to implement `AIAdapter`.
- Changed `openaiAdapterProvider` to `Provider<AIAdapter>` so tests can override it with `FakeAdapter`.
- Updated AI service constructor fields that receive `openaiAdapterProvider` to depend on `AIAdapter` rather than concrete `OpenAIAdapter`.

### Test infrastructure

- Added `FakeAdapter` with deterministic xianxia streaming responses for synthesis, rewrite, polish, and free-input operations.
- Added configurable fake error behavior via `errorRate` and `errorText`.
- Added `emptyResponse` mode for empty-stream tests.
- Added token usage simulation with non-zero prompt/completion/total token counts after stream completion.
- Added `createTestContainer()` and `cleanupTestContainer()` for Riverpod + Hive automation tests.
- Added deterministic xianxia content and manuscript/chapter fixtures.

## Verification

- `dart analyze lib/features/ai/domain/ai_adapter.dart lib/features/ai/infrastructure/openai_adapter.dart lib/core/presentation/providers.dart lib/features/knowledge/application/skill_generation_service.dart lib/features/knowledge/application/deviation_detection_service.dart lib/features/templates/application/template_completion_service.dart lib/features/onboarding/application/opening_generator_service.dart test/features/ai/domain/ai_adapter_test.dart test/automation/helpers/fake_adapter.dart test/automation/helpers/fake_adapter_test.dart test/automation/helpers/test_container.dart test/automation/fixtures/xianxia_content.dart test/automation/fixtures/manuscript_fixtures.dart` — passed.
- `flutter test --no-pub test/features/ai/domain/ai_adapter_test.dart test/automation/helpers/fake_adapter_test.dart` — 11 tests passed.
- `flutter test --no-pub test/automation/helpers/` — 8 tests passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Widened dependent AI service constructor types**
- **Found during:** Task 1 verification.
- **Issue:** After `openaiAdapterProvider` was changed to `Provider<AIAdapter>`, downstream constructors still required `OpenAIAdapter`, causing analyzer type errors.
- **Fix:** Updated skill generation, deviation detection, template completion, and opening generation services to accept `AIAdapter`.
- **Files modified:**
  - `lib/features/knowledge/application/skill_generation_service.dart`
  - `lib/features/knowledge/application/deviation_detection_service.dart`
  - `lib/features/templates/application/template_completion_service.dart`
  - `lib/features/onboarding/application/opening_generator_service.dart`
- **Commit:** f79de2e

**2. [Rule 3 - Blocking Issue] Corrected worktree base after invalid expected hash**
- **Found during:** Executor startup / Task 1 verification.
- **Issue:** The provided expected base hash had a typo and the worktree initially pointed at an older branch state that lacked Phase 13 source files.
- **Fix:** Reset the worktree to the local `phase-8-nyquist-validation` ref at `749903b` and reapplied current task changes.
- **Files modified:** none beyond task files.
- **Commit:** f79de2e

## Auth Gates

None.

## Known Stubs

None. Test fixtures intentionally contain deterministic hardcoded content for automation assertions; these are test data, not UI-facing stubs.

## Threat Flags

None. This plan introduced no new network endpoints, auth paths, file access patterns outside temporary Hive test directories, or production schema changes.

## Self-Check: PASSED

Created files verified:

- `lib/features/ai/domain/ai_adapter.dart`
- `test/features/ai/domain/ai_adapter_test.dart`
- `test/automation/helpers/fake_adapter.dart`
- `test/automation/helpers/fake_adapter_test.dart`
- `test/automation/helpers/test_container.dart`
- `test/automation/fixtures/xianxia_content.dart`
- `test/automation/fixtures/manuscript_fixtures.dart`

Commits verified:

- `f79de2e` — task 1 implementation commit exists.
- `c1dd182` — task 2 implementation commit exists.

No shared orchestrator artifacts (`STATE.md`, `ROADMAP.md`) were modified by this executor.
