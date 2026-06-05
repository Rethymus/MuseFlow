---
phase: 8
slug: onboarding-guide
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
validated: 2026-06-05
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (bundled with SDK) |
| **Config file** | None — test structure follows convention |
| **Quick run command** | `flutter test test/features/onboarding/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/onboarding/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | ONBD-01 | — | N/A | unit | `flutter test test/features/onboarding/application/onboarding_redirect_test.dart` | ✅ present | ✅ green |
| 08-01-02 | 01 | 1 | ONBD-06 | — | N/A | unit | `flutter test test/features/onboarding/application/onboarding_redirect_test.dart` | ✅ present | ✅ green |
| 08-02-01 | 02 | 1 | ONBD-02 | — | N/A | widget | `flutter test test/features/onboarding/presentation/onboarding_wizard_test.dart` | ✅ present | ✅ green |
| 08-02-02 | 02 | 1 | ONBD-02 | — | N/A | widget | `flutter test test/features/onboarding/presentation/onboarding_wizard_test.dart` | ✅ present | ✅ green |
| 08-02-03 | 02 | 1 | ONBD-03 | — | N/A | unit | `flutter test test/features/onboarding/application/onboarding_progress_test.dart` | ✅ present | ✅ green |
| 08-04-01 | 04 | 3 | ONBD-04 | T-08-07, T-08-08, T-08-09 | Input length limit (500 chars), structured JSON parsing with graceful fallback, output truncation | unit | `flutter test test/features/onboarding/application/opening_generator_service_test.dart test/features/onboarding/domain/opening_variant_test.dart` | ✅ present | ✅ green |
| 08-05-01 | 05 | 3 | ONBD-04 | — | N/A | widget | `flutter test test/features/onboarding/presentation/opening_variant_card_test.dart` | ✅ present | ✅ green |
| 08-05-02 | 05 | 3 | ONBD-04 | T-08-10 | Concept input limited to 500 chars; generation uses provider override in test | widget | `flutter test test/features/onboarding/presentation/opening_step_page_test.dart` | ✅ present | ✅ green |
| 08-05-03 | 05 | 3 | ONBD-04 + ONBD-05 | T-08-10, T-08-11 | Bottom sheet generation renders variants; selected variant inserts into editor through helper | widget | `flutter test test/features/onboarding/presentation/opening_generator_sheet_test.dart` | ✅ present | ✅ green |
| 08-05-04 | 05 | 3 | ONBD-05 | T-08-11 | Cursor insertion, selection replacement, no-selection append, AI provenance attribution | unit | `flutter test test/features/onboarding/application/opening_insertion_test.dart` | ✅ present | ✅ green |
| 08-05-05 | 05 | 3 | ONBD-05 | — | N/A | widget | `flutter test test/features/editor/presentation/editor_toolbar_test.dart` | ✅ present | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/features/onboarding/application/` — directory and all test files
- [x] `test/features/onboarding/presentation/` — directory and all widget test files
- [x] `test/features/onboarding/domain/` — directory for OpeningVariant tests
- [x] Test infrastructure: provider overrides and mock `OpeningGeneratorService` streams used for UI tests; Hive test helper used where editor stats side effects open boxes

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First-run redirect triggers on fresh install | ONBD-01 | Requires clean app install state outside widget/unit harness | Uninstall app → reinstall → verify wizard launches |
| Wizard skip/resume UX flow feels natural | ONBD-02 | Subjective UX quality beyond deterministic navigation assertions | Walk through 4 steps, skip step 2, close app, reopen, verify resume feels natural |
| AI opening quality (distinct styles) | ONBD-04 | Requires human/LLM quality evaluation; automated service tests verify structure, not prose quality | Generate openings for same concept, verify 3 styles are meaningfully different |

---

## Validation Audit 2026-06-05

Nyquist adversarial gap fill added direct behavioral coverage for all remaining Phase 8 UI gaps:

| Gap | Requirement | New/Relevant File | Command Run | Result |
|-----|-------------|-------------------|-------------|--------|
| OpeningStepPage UI behavior | ONBD-04 | `test/features/onboarding/presentation/opening_step_page_test.dart` | `flutter test test/features/onboarding/presentation/opening_step_page_test.dart test/features/onboarding/presentation/opening_generator_sheet_test.dart test/features/editor/presentation/editor_toolbar_test.dart` | ✅ green, 6 tests passed |
| OpeningGeneratorSheet generation + insertion behavior | ONBD-04 + ONBD-05 | `test/features/onboarding/presentation/opening_generator_sheet_test.dart` | `flutter test test/features/onboarding/presentation/opening_step_page_test.dart test/features/onboarding/presentation/opening_generator_sheet_test.dart test/features/editor/presentation/editor_toolbar_test.dart` | ✅ green, 6 tests passed |
| Editor toolbar opening generator entry | ONBD-05 | `test/features/editor/presentation/editor_toolbar_test.dart` | `flutter test test/features/onboarding/presentation/opening_step_page_test.dart test/features/onboarding/presentation/opening_generator_sheet_test.dart test/features/editor/presentation/editor_toolbar_test.dart` | ✅ green, 6 tests passed |

Known prior green commands from phase verification:

- `flutter test test/features/onboarding/` — passed, 90 tests.
- `flutter test test/features/editor/formatting_test.dart test/features/onboarding/application/opening_insertion_test.dart test/features/onboarding/presentation/opening_variant_card_test.dart` — passed, 19 tests.

Debug iterations during audit:

1. Initial run failed because the isolated worktree branch was behind `main` and missing Phase 8 implementation files; fast-forwarded the worktree branch to `main` before re-running.
2. Second run found test-only issues: missing `EditorHolderNotifier` import and over-specific transient loading assertion; fixed tests without implementation changes.
3. Third run found test environment Hive initialization for stats side effect after sheet insertion; initialized Hive via existing test helper. Final run passed.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or justified manual-only UX/quality checks
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s for targeted gap tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-05
