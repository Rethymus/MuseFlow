---
phase: 13
slug: automation-test-harness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-07
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test / dart test |
| **Config file** | none — existing Flutter test infrastructure |
| **Quick run command** | `flutter test test/automation/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/automation/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | TEST-01 | — | N/A (test infrastructure) | unit | `flutter test test/automation/` | ❌ W0 | ⬜ pending |
| 13-02-01 | 02 | 1 | TEST-02 | — | N/A (test infrastructure) | unit | `flutter test test/automation/` | ❌ W0 | ⬜ pending |
| 13-03-01 | 03 | 2 | TEST-03 | — | N/A (test infrastructure) | unit | `flutter test test/automation/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/automation/fake_adapter_test.dart` — stubs for TEST-01 (FakeAdapter verification)
- [ ] `test/automation/flow_test.dart` — stubs for TEST-02 (end-to-end flow automation)
- [ ] `test/automation/integration_test.dart` — stubs for TEST-03 (Flutter integration tests)
- [ ] `test/automation/helpers/` — shared test helpers and fixtures

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| FakeAdapter output resembles plausible 修仙 (cultivation) genre text | TEST-01 | Creative text quality requires human judgment | Review sample output for genre-appropriate language and character names |
| Integration test UI interactions match expected user flow | TEST-02 | Visual correctness of widget interactions | Run integration test, observe emulator for correct screen transitions |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
