---
phase: quick
plan: 260613-q8x
subsystem: ai
tags: [ai, claude, token-audit, bugfix, tdd]
dependency_graph:
  requires: []
  provides:
    - "Correct two-event Claude usage capture (MessageStartEvent.inputTokens + MessageDeltaEvent.outputTokens)"
    - "Testable processStreamEvents seam for ClaudeAdapter event processing"
  affects:
    - "Token audit subsystem (accurate promptTokens for Claude cost accounting)"
tech_stack:
  added: []
  patterns:
    - "Two-event streaming usage capture (Anthropic MessageStartEvent + MessageDeltaEvent)"
    - "Shared static _buildUsage helper (DRY across createStream and processStreamEvents)"
    - "@visibleForTesting seam extraction for unit-testable streaming logic"
key_files:
  created: []
  modified:
    - lib/features/ai/infrastructure/claude_adapter.dart
    - test/features/ai/infrastructure/claude_adapter_test.dart
decisions:
  - "D-q8x-01: Read prompt tokens from MessageStartEvent (non-null in real streams) rather than MessageDeltaEvent.usage.inputTokens (always null in real Anthropic streams)"
  - "D-q8x-02: Emit partial-but-nonzero Usage when only one of the two events arrives (defensive) rather than null, matching token-audit 'record what we know' intent"
  - "D-q8x-03: Shared static _buildUsage helper so createStream and processStreamEvents cannot diverge"
metrics:
  duration: "~35 min"
  completed: "2026-06-13"
  tasks_completed: 3
  tasks_total: 3
  tests_added: 3
  tests_total: 1508
---

# Phase quick Plan 260613-q8x: Claude Token-Audit Bug Fix Summary

Fixed the Claude token-audit bug where `promptTokens` was always recorded as 0, restoring accurate cost accounting for Claude users by capturing input tokens from `MessageStartEvent` and output tokens from `MessageDeltaEvent`.

## What Was Built

The Anthropic streaming API splits usage across two events — input (prompt) tokens arrive in `MessageStartEvent.message.usage.inputTokens` at stream start, output (completion) tokens arrive in `MessageDeltaEvent.usage.outputTokens` at stream end. The previous `claude_adapter.dart` read usage ONLY from `MessageDeltaEvent`, whose `inputTokens` field is null in real streams, so `promptTokens` was always 0. For writing tasks, input tokens (amplified by knowledge injection) are 10-100x output tokens, so the cost audit violated the "成本透明" promise.

The fix introduces a testable seam (`processStreamEvents`, `@visibleForTesting`) and a shared static helper (`_buildUsage`) so both `createStream` and the seam capture both events identically. A behavioral regression test feeds synthetic stream events and asserts the emitted `Usage` payload.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | RED: extract seam + failing regression test | 8e973f1 | test/features/ai/infrastructure/claude_adapter_test.dart, lib/features/ai/infrastructure/claude_adapter.dart |
| 2 | GREEN: fix two-event usage capture | 58632e7 | lib/features/ai/infrastructure/claude_adapter.dart |
| 3 | Full regression + analyze | (no code change) | — |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SDK constructor signature mismatch with plan's `<interfaces>` block**
- **Found during:** Task 1
- **Issue:** The plan's `<interfaces>` block specified `anthropic.Usage(type: 'message_start', inputTokens: ..., outputTokens: ...)` and stated the resolved SDK was 4.1.0. Actual resolved version is 4.0.0, and the real `anthropic.Usage` constructor has NO `type` field. Following the plan literally would not compile.
- **Fix:** Dropped the `type:` parameter from the synthetic `Usage` construction. Verified all other constructors (`MessageStartEvent`, `MessageDeltaEvent`, `ContentBlockDeltaEvent`, `TextDelta`, `MessageDelta`, `MessageDeltaUsage`, `Message`) against the actual 4.0.0 source in `~/.pub-cache`. All others matched the plan.
- **Files modified:** test/features/ai/infrastructure/claude_adapter_test.dart
- **Commit:** 8e973f1

**2. [Rule 1 - Bug] Stray closing brace in `_buildUsage` signature broke compilation**
- **Found during:** Task 2
- **Issue:** After editing the seam, the `_buildUsage` method signature read `}) {` instead of `) {` — a stray `}` that closed the class body prematurely, producing a cascade of "Setter not found: '_client'" / "Can't have modifier 'static' here" errors that masked the real cause.
- **Fix:** Corrected `}) {` to `) {`. Diagnosed via `cat -A` to locate the mismatched paren after the initial compile error pointed at column 28 of a line that Read rendered as valid.
- **Files modified:** lib/features/ai/infrastructure/claude_adapter.dart
- **Commit:** 58632e7

No other deviations. The plan's logic, test design, edge-case handling, and threat model were followed exactly.

## TDD Gate Compliance

- **RED gate (commit 8e973f1):** A `test(claude-usage):` commit precedes any fix. Verified RED: the usage-capture test failed with `promptTokens Expected: 120, Actual: 0`, proving the test exercises the bug. The text-delta test passed (extraction was already correct), and the null-usage test passed (contract preserved).
- **GREEN gate (commit 58632e7):** A `fix(claude-usage):` commit follows, making all 3 usage-tracking tests pass (promptTokens=120, completionTokens=45, totalTokens=165).
- **Refactor:** No separate refactor commit needed; DRY extraction of `_buildUsage` was part of the GREEN implementation.

Gate sequence valid: test → fix.

## Verification Results

| Check | Command | Result |
| ----- | ------- | ------ |
| Usage-tracking group | `flutter test test/features/ai/infrastructure/claude_adapter_test.dart` | 20 passed (17 prior + 3 new), 0 failed |
| Full regression | `flutter test` | 1508 passed, 12 skipped, 0 failed |
| Static analysis | `flutter analyze lib/features/ai/infrastructure/claude_adapter.dart` | No issues found |
| Grep guard | `grep -v '^//' claude_adapter.dart \| grep "deltaUsage!.inputTokens"` | Empty (buggy line removed) |

Baseline was 1505 tests; the 3 new usage-tracking tests bring the total to 1508. No pre-existing test regressed.

## Self-Check: PASSED

- [x] `lib/features/ai/infrastructure/claude_adapter.dart` exists and modified (commits 8e973f1, 58632e7)
- [x] `test/features/ai/infrastructure/claude_adapter_test.dart` exists and modified (commit 8e973f1)
- [x] Commit 8e973f1 (RED) present in git log
- [x] Commit 58632e7 (GREEN) present in git log
- [x] `MessageStartEvent` capture present in createStream (line 84) and processStreamEvents (line 209)
- [x] Buggy `deltaUsage!.inputTokens ?? 0` pattern removed (grep guard empty)

## Threat Surface

No new threat surface introduced. The `processStreamEvents` seam (`@visibleForTesting`, accepts typed `List<MessageStreamEvent>` — no string/JSON parsing, no new trust boundary) was reviewed and accepted per T-q8x-01. The fix itself IS the mitigation for T-q8x-02 (cost underreporting). T-q8x-03 (partial-stream edge case) is handled defensively in `_buildUsage`.
