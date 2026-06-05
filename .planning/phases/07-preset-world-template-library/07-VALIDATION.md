---
phase: 07
slug: preset-world-template-library
status: automated_passed_manual_pending
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test test/features/templates` |
| **Full suite command** | `flutter test test/features/templates test/features/knowledge` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/templates`
- **After every plan wave:** Run `flutter test test/features/templates test/features/knowledge`
- **Before `/gsd:verify-work`:** Full suite plus `flutter analyze lib/features/templates test/features/templates` must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | TMPL-01, TMPL-06 | T-07-01 | Bundled assets only, no network template updates | unit | `flutter test test/features/templates/domain test/features/templates/infrastructure` | W0 | passed |
| 07-02-01 | 02 | 2 | TMPL-01, TMPL-02, TMPL-04, TMPL-06 | — | UI reads local template models only | widget | `flutter test test/features/templates/presentation` | W0 | passed |
| 07-03-01 | 03 | 3 | TMPL-03, TMPL-05 | T-07-02 | AI failure does not block manual save | unit/widget | `flutter test test/features/templates/application test/features/templates/presentation` | W0 | passed |

*Status: pending until execution writes tests.*

---

## Wave 0 Requirements

- Existing Flutter test infrastructure covers all phase requirements.
- Executors should create missing `test/features/templates/**` files before implementing production files for TDD-eligible services.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Template prose has no obvious AI-scent and matches Chinese genre expectations | TMPL-02, TMPL-06 | Requires human reading judgement | Review all 14 bundled templates before marking Phase 7 complete |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
