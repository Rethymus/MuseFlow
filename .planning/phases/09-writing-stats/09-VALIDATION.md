---
phase: 9
slug: writing-stats
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for writing statistics execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test |
| **Config file** | None — conventional Flutter test layout |
| **Quick run command** | `flutter test test/features/stats/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task:** Run the task-specific automated command.
- **After every plan:** Run `flutter test test/features/stats/` plus any touched feature tests.
- **Before phase verification:** Run `flutter test`.
- **Max feedback latency:** 20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | STAT-05 | T-09-01 | No synchronous Hive write in typing path | unit | `flutter test test/features/stats/domain/writing_unit_counter_test.dart` | W0 | pending |
| 09-01-02 | 01 | 1 | STAT-01, STAT-02 | T-09-02 | Local-only Hive persistence | unit | `flutter test test/features/stats/infrastructure/writing_stats_repository_test.dart` | W0 | pending |
| 09-01-03 | 01 | 1 | STAT-05 | T-09-01 | 30-second debounced flush | unit | `flutter test test/features/stats/application/writing_stats_collector_test.dart` | W0 | pending |
| 09-01-04 | 01 | 1 | STAT-01, STAT-02 | — | N/A | unit | `flutter test test/features/stats/application/writing_stats_notifier_test.dart` | W0 | pending |
| 09-02-01 | 02 | 2 | STAT-03 | — | N/A | widget | `flutter test test/features/stats/presentation/writing_stats_page_test.dart` | W0 | pending |
| 09-02-02 | 02 | 2 | STAT-01, STAT-02 | — | N/A | widget | `flutter test test/features/stats/presentation/project_stats_page_test.dart` | W0 | pending |
| 09-03-01 | 03 | 3 | STAT-04 | — | N/A | unit | `flutter test test/features/stats/application/achievement_service_test.dart` | W0 | pending |
| 09-03-02 | 03 | 3 | STAT-06 | T-09-03 | Explicit confirmation before destructive local clear | widget | `flutter test test/features/settings/presentation/settings_page_stats_test.dart` | W0 | pending |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Typing remains smooth during long editing | STAT-05 | Requires subjective/editor runtime feel | Type continuously for 60s in editor; verify no visible stalls around flush interval. |
| Charts are readable on Android-sized width | STAT-03 | Visual layout check | Resize below 600px or run mobile emulator; verify cards/charts do not overflow. |
| Badge copy feels motivating but not gamified slop | STAT-04 | Product/voice judgment | Unlock sample badges and review Chinese copy. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-09-01 | Denial of Service | Editor stats collection | mitigate | In-memory counting, debounced Hive writes, no awaited writes in typing path. |
| T-09-02 | Information Disclosure | Writing statistics storage | mitigate | Store only aggregate counts locally in Hive; no network calls. |
| T-09-03 | Tampering | Clear all stats action | mitigate | Require confirmation dialog and invalidate providers after clear. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] No watch-mode flags.
- [x] Feedback latency < 20s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** ready for execution
