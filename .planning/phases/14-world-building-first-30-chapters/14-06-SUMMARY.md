---
phase: 14-world-building-first-30-chapters
plan: 06
subsystem: testing
tags: [flutter, dart, journey-tests, glm, token-audit, d11-validation]

requires:
  - phase: 14-world-building-first-30-chapters
    provides: Phase 14 journey validation and P14-04-GLM-01 blocker context
provides:
  - Secret-safe OpenAI-compatible stream diagnostics
  - Deterministic no-credential 30-chapter serial journey coverage
  - Deterministic no-credential full journey coverage
  - Sanitized live GLM rerun evidence showing D-11 failure
  - Blocked outcome for P14-04-GLM-01 pending D-11 enforcement

affects: [phase-14-validation, JOURNEY-05, GLM-live-validation]

tech-stack:
  added: []
  patterns:
    - Deterministic AIAdapter wrappers for journey orchestration tests
    - Sanitized exception diagnostics for external API failures

key-files:
  created:
    - .planning/phases/14-world-building-first-30-chapters/14-06-SUMMARY.md
  modified:
    - lib/features/ai/infrastructure/openai_adapter.dart
    - test/features/ai/infrastructure/openai_adapter_test.dart
    - test/journey/serial_generation_test.dart
    - test/journey/full_journey_test.dart
    - .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md

key-decisions:
  - "Keep deterministic journey evidence supplemental; do not use it to close D-02 real GLM evidence."
  - "Keep P14-04-GLM-01 open because live GLM reached 30/30 generation but failed D-11 character bounds."

patterns-established:
  - "Live GLM chapter failures log exception runtime type plus sanitized message."
  - "No-credential journey tests use journey-local-test-key and deterministic adapter overrides."

requirements-completed: []
duration: blocked
completed: 2026-06-07
---

# Phase 14 Plan 06: Sustained GLM Journey Validation Summary

**Secret-safe GLM diagnostics plus deterministic 30-chapter journey coverage; real GLM remains blocked by D-11 length violations**

## Performance

- **Duration:** blocked after live GLM validation
- **Started:** 2026-06-07T16:22:57Z
- **Completed:** 2026-06-07T17:06:38Z
- **Tasks:** 3/3 executed; plan outcome blocked/failed by Task 3 acceptance criteria
- **Files modified:** 5

## Accomplishments

- Added sanitized OpenAI-compatible stream diagnostics so GLM failures include exception type/message without secrets.
- Added deterministic no-credential serial journey coverage that generates 30/30 chapters, validates D-11 bounds, invokes all-30 deviation checks, and flushes token audit with `totalCalls >= 30`.
- Added deterministic no-credential full journey coverage for world-building, fragment synthesis, opening surrogate, 30 chapter generation, persistence, and token audit.
- Reran live GLM validation; smoke passed and 30 chapters generated, but D-11 failed at chapter 5 (`504` chars), so `P14-04-GLM-01` remains open.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make GLM stream failures diagnosable without exposing secrets** - `dc4e87c` (feat)
2. **Task 2: Add deterministic full 30-chapter orchestration coverage and live D-11 bounds validation** - `aabd4ab` (test)
3. **Task 3: Rerun real GLM sustained validation and close P14-04-GLM-01 only on 30/30 success** - `c5128e4` (test/evidence)

**Plan metadata:** pending final commit

## Files Created/Modified

- `lib/features/ai/infrastructure/openai_adapter.dart` - Adds sanitized diagnostic messages to typed stream exception classification.
- `test/features/ai/infrastructure/openai_adapter_test.dart` - Covers diagnostic preservation and secret redaction.
- `test/journey/serial_generation_test.dart` - Adds deterministic 30-chapter path and D-11 live validation gate.
- `test/journey/full_journey_test.dart` - Adds deterministic full journey path with opening JSON surrogate and token audit verification.
- `.planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` - Records supplemental deterministic evidence and live GLM D-11 failure evidence.

## Decisions Made

- Deterministic tests are supplemental only; they cannot close `P14-04-GLM-01` or replace D-02 real GLM evidence.
- Live GLM success requires D-11 compliance for every generated/persisted chapter; 30/30 generation alone is insufficient.
- `P14-04-GLM-01` stays open and should route to debug/replan for product/test harness enforcement of 300-500 character bounds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Prevent deterministic test from contaminating live HTTP tests**
- **Found during:** Task 3 live GLM verification
- **Issue:** Running deterministic and live serial tests in one file with `GLM_API_KEY` caused `TestWidgetsFlutterBinding` HTTP interception before live network calls.
- **Fix:** Skip the deterministic serial test when `GLM_API_KEY` is present, preserving the no-credential path while keeping live GLM tests network-capable.
- **Files modified:** `test/journey/serial_generation_test.dart`
- **Verification:** `dart analyze test/journey/serial_generation_test.dart` passed; live serial test reached real GLM and generated chapters.
- **Committed in:** `c5128e4`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required to preserve the separation between deterministic supplemental coverage and real GLM D-02 evidence.

## Issues Encountered

- Live GLM rerun did not satisfy Task 3 success criteria: smoke passed, serial run generated 30/30 chapters with 3s spacing, but chapter 5 was `504` chars and later chapters also exceeded 500 chars before validation stopped.
- Because D-11 failed, all-30 deviation detection and token audit flush did not run for live evidence; `P14-04-GLM-01` remains open.

## User Setup Required

- `GLM_API_KEY` was available during execution and used only through the shell environment.
- No secrets were written to the issue log or summary.

## Known Stubs

None found in files modified by this plan.

## Threat Flags

None beyond the plan threat model. The external GLM boundary and log evidence boundary were already covered by `T-14-06-01` through `T-14-06-04`.

## Verification

- `dart analyze lib/features/ai/infrastructure/openai_adapter.dart test/journey/serial_generation_test.dart test/features/ai/infrastructure/openai_adapter_test.dart` passed.
- `flutter test test/features/ai/infrastructure/openai_adapter_test.dart --plain-name "error classification" --timeout 120s` passed.
- `flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s` passed with live GLM credentials.
- `dart analyze test/journey/serial_generation_test.dart test/journey/full_journey_test.dart test/journey/helpers/journey_container.dart` passed.
- `flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "deterministic" --timeout 300s` passed.
- `flutter test test/journey/full_journey_test.dart -j 1 --plain-name "deterministic" --timeout 300s` passed.
- `GLM_API_KEY="$GLM_API_KEY" flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should generate 30 chapters with knowledge injection and Skill guardian" --timeout 1200s` failed on D-11 as expected for blocked outcome.

## Self-Check: PASSED

- Found summary file: `.planning/phases/14-world-building-first-30-chapters/14-06-SUMMARY.md`
- Found task commit: `dc4e87c`
- Found task commit: `aabd4ab`
- Found task commit: `c5128e4`

## Next Phase Readiness

- Ready for `/gsd:debug` or a follow-up gap plan focused on enforcing or constraining live chapter output to 300-500 characters before persistence.
- Phase 14 JOURNEY-05 should not be marked complete until a real GLM rerun records 30/30 generation, D-11 compliance, all-30 deviation checks, and token audit totals.

---
*Phase: 14-world-building-first-30-chapters*
*Completed: 2026-06-07 with blocked plan outcome*
