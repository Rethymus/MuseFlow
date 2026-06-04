---
phase: 08-onboarding-guide
plan: 04
subsystem: ai, domain
tags: [opening-generator, streaming, json-parsing, ai-service, value-object]

# Dependency graph
requires:
  - phase: 02-ai-provider-capture-synthesis
    provides: OpenAIAdapter streaming interface, openai_dart ChatMessage
  - phase: 08-onboarding-guide plan 01
    provides: OnboardingProgress model, onboarding feature structure
provides:
  - OpeningVariant value object with OpeningVariantStyle enum
  - OpeningGeneratorService for AI-powered 3-variant opening generation
  - OpeningStream typedef for test-only mock injection
affects: [08-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "OpeningStream typedef for test-only mock injection (same as TemplateCompletionStream)"
    - "Markdown fence stripping for AI JSON output"
    - "Input truncation guards (storyConcept 500 chars, opening text 1000 chars)"

key-files:
  created:
    - lib/features/onboarding/domain/opening_variant.dart
    - lib/features/onboarding/application/opening_generator_service.dart
    - test/features/onboarding/domain/opening_variant_test.dart
    - test/features/onboarding/application/opening_generator_service_test.dart
  modified: []

key-decisions:
  - "Created standalone OpeningVariantStyle enum rather than reusing OpeningSampleStyle — templates feature not available in worktree branch"
  - "Manual immutable class with copyWith for OpeningVariant (not freezed) — consistent with codebase patterns"
  - "OpeningGeneratorService returns empty list on all errors (JSON parse, stream, malformed) — graceful degradation for T-08-08"

patterns-established:
  - "AI service with mock stream typedef: OpeningStream for test injection mirrors TemplateCompletionStream pattern"
  - "Markdown fence stripping in AI response parser (```json ... ```) for robust JSON extraction"

requirements-completed: [ONBD-04]

# Metrics
duration: 5m
completed: 2026-06-04
---

# Phase 8 Plan 04: AI Opening Generator Service Summary

**OpeningVariant domain model and OpeningGeneratorService producing 3 distinct opening styles (scene/character/suspense) via single streaming AI call with JSON parsing and error resilience**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-04T13:58:38Z
- **Completed:** 2026-06-04T14:03:40Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments
- OpeningVariantStyle enum with 3 values (scene, character, suspense) and Chinese display labels
- OpeningVariant immutable value object with fromJson/toJson/copyWith
- OpeningGeneratorService following TemplateCompletionService streaming pattern
- JSON response parsing with markdown fence stripping
- storyConcept input truncated to 500 chars (T-08-07)
- Opening text truncated to 1000 chars max (T-08-09)
- Graceful empty-list fallback on all error types (T-08-08)
- 23 tests passing (11 domain + 12 service)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create OpeningVariant domain model** - `e806e39` (feat)
2. **Task 2: Create OpeningGeneratorService with AI streaming** - `a1710c7` (feat)

## Files Created
- `lib/features/onboarding/domain/opening_variant.dart` - OpeningVariantStyle enum with displayLabel getter, OpeningVariant class with fromJson/toJson/copyWith/equality
- `lib/features/onboarding/application/opening_generator_service.dart` - AI streaming service with JSON parsing, markdown fence stripping, input truncation, OpeningStream typedef
- `test/features/onboarding/domain/opening_variant_test.dart` - 11 tests for enum values, display labels, JSON roundtrip, equality
- `test/features/onboarding/application/opening_generator_service_test.dart` - 12 tests for 3-variant generation, malformed JSON, markdown fences, streaming chunks, stream errors, concept truncation, empty/null concept handling, text truncation, message content, non-map filtering

## Decisions Made
- Created standalone OpeningVariantStyle enum instead of reusing OpeningSampleStyle from world_template.dart — templates feature files are not present in the current worktree branch; the enum values (scene/character/suspense) are semantically identical for future unification
- Used manual immutable class pattern for OpeningVariant (not freezed) — consistent with existing domain models like ForeshadowingEntry and PlotNode
- OpeningGeneratorService returns empty list on all errors rather than throwing — enables graceful UI degradation (show "retry" instead of crash)
- Added OpeningStream typedef matching TemplateCompletionStream pattern for clean test injection without mocking OpenAIAdapter

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed openai_dart v6 ChatMessage API in tests**
- **Found during:** Task 2 test compilation
- **Issue:** Test code used ChatMessageRole.user and .content getter which don't exist in openai_dart v6 (sealed class API)
- **Fix:** Changed to `messages.whereType<UserMessage>().first.text` pattern
- **Files modified:** test/features/onboarding/application/opening_generator_service_test.dart
- **Commit:** a1710c7

## Issues Encountered
- None beyond the openai_dart v6 API adjustment

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan 08-05 can proceed: OpeningVariant model and OpeningGeneratorService are ready for UI integration
- Provider registration (openingGeneratorServiceProvider) will be added in Plan 08-05 when wiring up the UI
- The service accepts OpenAIAdapter + apiKey + baseUrl + model, matching the existing provider pattern in providers.dart

## Self-Check: PASSED

All 5 created files verified present. All 2 commits verified in git log.

---
*Phase: 08-onboarding-guide*
*Completed: 2026-06-04*
