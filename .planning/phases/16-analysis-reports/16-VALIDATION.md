---
phase: 16
slug: analysis-reports
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test |
| **Config file** | none — existing infrastructure |
| **Quick run command** | `flutter test test/features/stats/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~75 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/stats/ test/features/reports/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | REPORT-01 | — | N/A | unit | `flutter test test/features/stats/` | ❌ W0 | ⬜ pending |
| 16-02-01 | 02 | 1 | REPORT-02 | — | N/A | unit | `flutter test test/features/reports/` | ❌ W0 | ⬜ pending |
| 16-03-01 | 03 | 1 | REPORT-03 | — | N/A | unit | `flutter test test/features/reports/` | ❌ W0 | ⬜ pending |
| 16-04-01 | 04 | 2 | REPORT-04 | — | N/A | unit | `flutter test test/features/reports/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/reports/application/token_cost_report_service_test.dart` — stubs for REPORT-01
- [ ] `test/features/reports/application/pain_points_report_service_test.dart` — stubs for REPORT-02
- [ ] `test/features/reports/application/anti_ai_scent_eval_service_test.dart` — stubs for REPORT-03
- [ ] `test/features/reports/application/kb_consistency_report_service_test.dart` — stubs for REPORT-04

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Anti-AI-scent blind read test | REPORT-03 | Human judgment required to evaluate prose quality | Present 10 sampled paragraphs to human reader, ask AI-generated Y/N |
| Report visual formatting | REPORT-01-04 | Visual layout verification | Open each report page, verify layout matches design spec |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
