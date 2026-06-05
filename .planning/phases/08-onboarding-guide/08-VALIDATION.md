---
phase: 8
slug: onboarding-guide
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
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
| 08-01-01 | 01 | 1 | ONBD-01 | — | N/A | unit | `flutter test test/features/onboarding/application/onboarding_redirect_test.dart` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 1 | ONBD-06 | — | N/A | unit | `flutter test test/features/onboarding/application/onboarding_redirect_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-01 | 02 | 1 | ONBD-02 | — | N/A | widget | `flutter test test/features/onboarding/presentation/onboarding_wizard_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-02 | 02 | 1 | ONBD-02 | — | N/A | widget | `flutter test test/features/onboarding/presentation/onboarding_wizard_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-03 | 02 | 1 | ONBD-03 | — | N/A | unit | `flutter test test/features/onboarding/application/onboarding_progress_test.dart` | ❌ W0 | ⬜ pending |
| 08-03-01 | 03 | 2 | ONBD-04 | T-08-01 | Input length limit (500 chars), structured JSON parsing with error handling | unit | `flutter test test/features/onboarding/application/opening_generator_service_test.dart` | ❌ W0 | ⬜ pending |
| 08-03-02 | 03 | 2 | ONBD-04 | — | N/A | widget | `flutter test test/features/onboarding/presentation/opening_generator_sheet_test.dart` | ❌ W0 | ⬜ pending |
| 08-03-03 | 03 | 2 | ONBD-05 | — | N/A | unit | `flutter test test/features/onboarding/application/opening_insertion_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/onboarding/application/` — directory and all test files
- [ ] `test/features/onboarding/presentation/` — directory and all widget test files
- [ ] `test/features/onboarding/domain/` — directory for OpeningVariant tests
- [ ] Test infrastructure: shared test helpers for mock OpenAIAdapter streaming (pattern exists in `test/features/ai/infrastructure/openai_adapter_test.dart`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First-run redirect triggers on fresh install | ONBD-01 | Requires clean app state | Uninstall app → reinstall → verify wizard launches |
| Wizard skip/resume UX flow feels natural | ONBD-02 | Subjective UX quality | Walk through 4 steps, skip step 2, close app, reopen, verify resume |
| AI opening quality (distinct styles) | ONBD-04 | Requires LLM evaluation | Generate openings for same concept, verify 3 styles are meaningfully different |
| Opening insertion into editor cursor position | ONBD-05 | Requires live editor state | Generate opening, select one, verify insertion at cursor in editor |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
