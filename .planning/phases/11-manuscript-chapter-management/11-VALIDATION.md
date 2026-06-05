---
phase: 11
slug: manuscript-chapter-management
status: draft
nyquist_compliant: true
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
| 11-01-01 | 01 | 1 | SC-1 | — | Manuscript entity immutability + roundtrip | unit | `flutter test test/features/manuscript/domain/` | ❌ W0 | ⬜ pending |
| 11-01-02 | 01 | 1 | SC-1 | — | Hive TypeAdapter registration | unit | `flutter analyze lib/core/infrastructure/hive_adapters.dart lib/main.dart` | ❌ W0 | ⬜ pending |
| 11-02-01 | 02 | 2 | SC-2,SC-4 | — | Repository CRUD + soft delete + purge | unit | `flutter test test/features/manuscript/infrastructure/ test/features/manuscript/application/manuscript_sort_test.dart` | ❌ W0 | ⬜ pending |
| 11-02-02 | 02 | 2 | SC-2,SC-4 | T-11-03 | Notifier CRUD + auto-save debounce + forced save | unit | `flutter test test/features/manuscript/application/` | ❌ W0 | ⬜ pending |
| 11-03-01 | 03 | 3 | SC-1 | — | Library page renders card grid with genre covers | widget | `flutter test test/features/manuscript/presentation/manuscript_library_page_test.dart` | ❌ W0 | ⬜ pending |
| 11-03-02 | 03 | 3 | SC-1,SC-5 | — | Create dialog + settings page + template trigger | widget | `flutter test test/features/manuscript/presentation/` | ❌ W0 | ⬜ pending |
| 11-04-01 | 04 | 4 | SC-2,SC-3 | — | Sidebar components render correctly | widget | `flutter test test/features/manuscript/presentation/chapter_sidebar_test.dart` | ❌ W0 | ⬜ pending |
| 11-04-02 | 04 | 4 | SC-3,SC-4 | T-11-08 | Chapter switching + forced save + auto-save + keyboard shortcuts + EditorHolderNotifier update | unit+widget | `flutter test test/features/manuscript/presentation/editor_with_sidebar_test.dart test/features/manuscript/presentation/chapter_sidebar_test.dart` | ❌ W0 | ⬜ pending |
| 11-05-01 | 05 | 5 | SC-5,SC-6 | — | ExportBundle chapters + template chapter skeleton | unit | `flutter test test/features/manuscript/domain/chapter_export_test.dart test/features/templates/` | ❌ W0 | ⬜ pending |
| 11-05-02 | 05 | 5 | SC-6,D-24 | — | AI chapter context middleware + StatusBar progress + purge startup | unit | `flutter test test/features/editor/application/editor_prompt_pipeline_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

These test files are scaffolded as part of their respective plans' TDD tasks. Each plan creates its own test files as specified in `<behavior>` blocks. The files below are the complete set that must exist before phase completion:

- [ ] `test/features/manuscript/domain/manuscript_test.dart` — Manuscript entity roundtrip, coverLetter, equality (Plan 01 T1)
- [ ] `test/features/manuscript/domain/chapter_test.dart` — Chapter entity roundtrip, wordCount, equality (Plan 01 T1)
- [ ] `test/features/manuscript/domain/manuscript_genre_test.dart` — 14 presets, genreColor mapping (Plan 01 T1)
- [ ] `test/features/manuscript/domain/chapter_export_test.dart` — ChapterExport serialization (Plan 01 T1)
- [ ] `test/features/manuscript/infrastructure/manuscript_repository_test.dart` — CRUD + soft delete + purge queries (Plan 02 T1)
- [ ] `test/features/manuscript/infrastructure/chapter_repository_test.dart` — CRUD + manuscript-scoped queries (Plan 02 T1)
- [ ] `test/features/manuscript/application/manuscript_notifier_test.dart` — Notifier CRUD + softDelete + search (Plan 02 T2)
- [ ] `test/features/manuscript/application/chapter_notifier_test.dart` — Notifier CRUD + reorder + split + merge + duplicate (Plan 02 T2)
- [ ] `test/features/manuscript/application/chapter_auto_save_test.dart` — Debounce + forceSave + dirty flag (Plan 02 T2)
- [ ] `test/features/manuscript/application/manuscript_sort_test.dart` — Sort comparator logic (Plan 02 T1)
- [ ] `test/features/manuscript/presentation/manuscript_library_page_test.dart` — Card grid + empty state + sort (Plan 03 T1)
- [ ] `test/features/manuscript/presentation/manuscript_card_test.dart` — Genre cover + progress bar + status badge (Plan 03 T1)
- [ ] `test/features/manuscript/presentation/chapter_sidebar_test.dart` — Reorderable list + active highlight (Plan 04 T1)
- [ ] `test/features/manuscript/presentation/editor_with_sidebar_test.dart` — Chapter switching + forced save + auto-save lifecycle + keyboard shortcuts (Plan 04 T2)
- [ ] `test/features/templates/application/template_instantiation_service_test.dart` — Chapter skeleton creation (Plan 05 T1)

*Existing infrastructure: `flutter test` runner, `mockito`/`mocktail` for mocking, Hive test adapters.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drag-and-drop chapter reordering visual feedback | SC-2 | Gesture animation requires human eye | Open manuscript -> chapter list -> drag chapter -> verify smooth reorder animation |
| Genre-colored manuscript covers in library grid | SC-1 | Visual color correctness | Create manuscripts with different genres -> verify cover colors match genre |
| Editor sidebar chapter navigation UX | SC-3 | Sidebar interaction flow | Open manuscript -> click chapters in sidebar -> verify editor content switches |
| Keyboard shortcuts (Ctrl+Up/Down, Ctrl+Shift+N) | D-26 | Shortcut binding requires human verification | Open manuscript editor -> press Ctrl+Up -> verify previous chapter selected |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
