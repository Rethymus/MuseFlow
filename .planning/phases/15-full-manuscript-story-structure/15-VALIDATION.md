---
phase: 15
slug: full-manuscript-story-structure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (dart test) |
| **Config file** | none — existing infrastructure from Phase 14 |
| **Quick run command** | `flutter test test/journey/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/journey/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | JOURNEY-07 | — | N/A | integration | `flutter test test/journey/` | ❌ W0 | ⬜ pending |
| 15-01-02 | 01 | 1 | JOURNEY-07 | — | N/A | integration | `flutter test test/journey/` | ❌ W0 | ⬜ pending |
| 15-02-01 | 02 | 1 | JOURNEY-08 | — | N/A | unit | `flutter test test/features/story_structure/` | ❌ W0 | ⬜ pending |
| 15-03-01 | 03 | 2 | JOURNEY-09 | — | N/A | unit | `flutter test test/features/stats/` | ❌ W0 | ⬜ pending |
| 15-04-01 | 04 | 2 | JOURNEY-10 | — | N/A | unit | `flutter test test/features/stats/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/journey/manuscript_100_chapter_test.dart` — stubs for JOURNEY-07
- [ ] `test/features/story_structure/format_cleaner_test.dart` — stubs for JOURNEY-08
- [ ] `test/features/stats/writing_stats_test.dart` — stubs for JOURNEY-09
- [ ] `test/features/stats/export_service_test.dart` — stubs for JOURNEY-10

*Existing infrastructure from Phase 14 covers journey container setup and basic generation patterns.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 100-chapter manuscript visual review | JOURNEY-07 | Human judgment on story coherence | Generate 100 chapters, review continuity markers |
| Export format visual inspection | JOURNEY-09 | Human judgment on formatting quality | Export all 3 formats, open in respective readers |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
