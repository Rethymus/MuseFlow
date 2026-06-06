---
phase: 12
slug: token-audit-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-06
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test |
| **Config file** | none — existing infrastructure |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | AUDIT-01 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 12-01-02 | 01 | 1 | AUDIT-01 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 12-02-01 | 02 | 2 | AUDIT-02 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 12-02-02 | 02 | 2 | AUDIT-02 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 12-03-01 | 03 | 2 | AUDIT-03 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 12-03-02 | 03 | 2 | AUDIT-03 | — | N/A | unit | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/ai/infrastructure/token_audit_repository_test.dart` — stubs for AUDIT-01
- [ ] `test/features/ai/domain/token_usage_record_test.dart` — entity tests for AUDIT-01
- [ ] `test/features/ai/domain/token_statistics_test.dart` — statistics computation tests for AUDIT-03

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Token usage statistics page renders correctly | AUDIT-03 | UI visual verification | Run app, navigate to statistics page, verify charts and totals display |

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
