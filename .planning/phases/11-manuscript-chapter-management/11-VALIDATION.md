---
phase: 11
slug: manuscript-chapter-management
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-06
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (dart test) |
| **Config file** | pubspec.yaml (dev_dependencies) |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test && flutter analyze`
- **Before `/gsd:verify-work`:** Full suite must be green, `flutter analyze` zero errors
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | SC-1 | — | Manuscript CRUD operations validate input | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-01-02 | 01 | 1 | SC-1 | — | Soft-delete prevents data leakage | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-02-01 | 02 | 1 | SC-2 | — | Chapter reordering preserves data integrity | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-02-02 | 02 | 1 | SC-2 | — | Split/merge operations are atomic | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-03-01 | 03 | 2 | SC-3 | — | Chapter switch saves current and loads target | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-03-02 | 03 | 2 | SC-4 | — | Auto-save fires on debounce and forced triggers | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-04-01 | 04 | 2 | SC-5 | — | Template creation populates all required entities | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-05-01 | 05 | 3 | SC-6 | — | Export produces chapter-aware structure | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 11-05-02 | 05 | 3 | — | T-11-01 | Data migration preserves existing manuscripts | unit | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/manuscript/domain/manuscript_test.dart` — Manuscript entity stubs
- [ ] `test/features/manuscript/domain/chapter_test.dart` — Chapter entity stubs
- [ ] `test/features/manuscript/infrastructure/manuscript_repository_test.dart` — Repository stubs
- [ ] `test/features/manuscript/application/create_manuscript_test.dart` — Use case stubs
- [ ] `test/features/manuscript/application/chapter_operations_test.dart` — Chapter CRUD use case stubs
- [ ] `test/features/manuscript/presentation/manuscript_library_test.dart` — Library page widget stubs
- [ ] `test/features/editor/chapter_switching_test.dart` — Editor chapter switching stubs

*Existing infrastructure: `flutter test` runner, `mockito`/`mocktail` for mocking, Hive test adapters.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drag-and-drop chapter reordering visual feedback | SC-2 | Gesture animation requires human eye | Open manuscript → chapter list → drag chapter → verify smooth reorder animation |
| Genre-colored manuscript covers in library grid | SC-1 | Visual color correctness | Create manuscripts with different genres → verify cover colors match genre |
| Editor sidebar chapter navigation UX | SC-3 | Sidebar interaction flow | Open manuscript → click chapters in sidebar → verify editor content switches |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
