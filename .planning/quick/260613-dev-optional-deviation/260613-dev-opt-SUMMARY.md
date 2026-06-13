---
phase: quick
plan: 260613-dev-opt
subsystem: editor
tags: [editor, ai, deviation-detection, cost-transparency, settings, bugfix, tdd]
dependency_graph:
  requires: []
  provides:
    - "Opt-in post-operation consistency check (default off) eliminating hidden 2x token cost on editor AI ops"
    - "autoDeviationCheckProvider NotifierProvider<bool> (persisted, testable)"
    - "SettingsRepository.getAutoDeviationCheck / saveAutoDeviationCheck persistence seam"
  affects:
    - "Editor AI operation cost accounting (no longer silently doubles on tone/polish/free-input)"
    - "Settings page AI section (new opt-in toggle)"
tech_stack:
  added: []
  patterns:
    - "Setting-gated fire-and-forget secondary LLM call (cost-transparency default-off)"
    - "NotifierProvider<bool> backed by synchronous SettingsRepository read with loading-safe ?? false fallback"
    - "Recording DeviationNotifier fake for deterministic 'was the hidden call made' assertions"
key_files:
  created: []
  modified:
    - lib/core/infrastructure/settings_repository.dart
    - lib/core/presentation/providers.dart
    - lib/features/editor/application/editor_ai_notifier.dart
    - lib/features/settings/presentation/settings_page.dart
    - test/features/editor/application/editor_ai_notifier_test.dart
decisions:
  - "D-devopt-01: Default OFF rather than 'batch at chapter end' — simplest correct fix for the P0 cost-transparency breach; batch mode deferred (not needed to remove the silent doubling)"
  - "D-devopt-02: autoDeviationCheckProvider reads the repo synchronously via .value with ?? false fallback (matches bannedPhrasesProvider read pattern) — safe because the encrypted box is loaded at app shell startup, long before any editor operation"
  - "D-devopt-03: Override-deviationNotifier-with-recorder test seam isolates the assertion to 'was checkDeviations invoked at all', independent of skill repo / LLM availability"
metrics:
  duration: "~30 min"
  completed: "2026-06-13"
  tasks_completed: 3
  tasks_total: 3
  tests_added: 2
  tests_total: 1510
---

# Phase quick Plan 260613-dev-opt: Optional Post-Operation Deviation Check Summary

Made the editor's automatic skill-consistency (deviation) check **opt-in (default off)**, eliminating the hidden second LLM call that silently doubled token cost on every editor AI operation.

## What Was Built

After every editor AI operation (tone-rewrite / paragraph-polish / free-input), `editor_ai_notifier.dart` unconditionally fired `unawaited(checkDeviations(...))`, which runs a full second streaming LLM call (`deviation_detection_service` `createStream`, audited as `deviationDetect`) against active skills. This was invisible and uncontrollable — the user saw one operation but paid for two. For the core creation flow this violates the README **成本透明** (cost-transparency) promise and corresponds to v1.5 roadmap item **CP-01 (P0)**.

The fix gates that call behind a persisted, user-facing boolean setting that is **OFF by default**:

1. **`SettingsRepository`** — `getAutoDeviationCheck()` (sync Hive read, default `false`) + `saveAutoDeviationCheck(bool)` (persist), key `auto_deviation_check`. Mirrors the existing `getDefaultTag`/`setDefaultTag` pattern.
2. **`autoDeviationCheckProvider`** (`NotifierProvider<AutoDeviationCheckNotifier, bool>`) — `build()` reads the repo synchronously with a `?? false` loading fallback (same pattern as `bannedPhrasesProvider`); `set(bool)` updates state and persists.
3. **`editor_ai_notifier.dart`** — the `unawaited(checkDeviations(...))` block is wrapped in `if (ref.read(autoDeviationCheckProvider)) { ... }`.
4. **`settings_page.dart`** — a `SwitchListTile` ("AI 操作后自动一致性检查") in the AI section, two-way bound to the provider.

Opt-in preserves the prior behavior exactly: when enabled, `checkDeviations` runs as before.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | RED: failing regression (default-off + opt-in tests) | f71865d | test/features/editor/application/editor_ai_notifier_test.dart, lib/core/presentation/providers.dart |
| 2 | GREEN: repo persistence + provider + gate + UI toggle | dfe3198 | lib/core/infrastructure/settings_repository.dart, lib/core/presentation/providers.dart, lib/features/editor/application/editor_ai_notifier.dart, lib/features/settings/presentation/settings_page.dart |
| 3 | Full regression — 1510 green + analyze clean | (no code change) | — |

## Deviations from Plan

None. The plan's interfaces, gate placement, provider shape, and test design were followed exactly. The RED stub (`autoDeviationCheckProvider` returning `false` to keep the test compilable) was introduced as planned and replaced with the repo-backed notifier in GREEN.

## TDD Gate Compliance

- **RED gate (commit f71865d):** `test(deviation-opt):` precedes any fix. Verified RED: the default-off test failed with `Expected: empty, Actual: ['结果']` — proving checkDeviations was called unconditionally. The opt-in test passed coincidentally (call happens regardless when ungated).
- **GREEN gate (commit dfe3198):** `fix(deviation-opt):` follows, making both tests pass (default=0 calls, opt-in=1 call).

Gate sequence valid: test → fix.

## Verification Results

| Check | Command | Result |
| ----- | ------- | ------ |
| Deviation-gating group | `flutter test ... --plain-name "deviation check gating"` | 2 passed, 0 failed |
| editor_ai_notifier file | `flutter test test/features/editor/application/editor_ai_notifier_test.dart` | 23 passed (21 prior + 2 new), 0 failed |
| Full regression | `flutter test` | 1510 passed, 12 skipped, 0 failed |
| Static analysis | `flutter analyze` (4 touched lib files) | No issues found |

Baseline was 1508 tests; the 2 new gating tests bring the total to 1510. No pre-existing test regressed.

## Self-Check: PASSED

- [x] `getAutoDeviationCheck()` + `saveAutoDeviationCheck()` present in settings_repository.dart
- [x] `autoDeviationCheckProvider` + `AutoDeviationCheckNotifier` present in providers.dart (repo-backed, not the RED stub)
- [x] Gate `if (ref.read(autoDeviationCheckProvider))` wraps the unawaited call in editor_ai_notifier.dart
- [x] SwitchListTile present in settings_page.dart AI section
- [x] Commit f71865d (RED) and dfe3198 (GREEN) in git log
- [x] Full suite 1510 green, analyze clean

## Threat Surface

No new threat surface. The change REMOVES a hidden cost (information-disclosure-adjacent: opaque resource consumption). The opt-in toggle is a plain local preference persisted in the existing encrypted settings box — no new trust boundary, no new external call (it only suppresses an existing one). The recording-fake test seam overrides a provider in-process only; no parsing of untrusted input.
