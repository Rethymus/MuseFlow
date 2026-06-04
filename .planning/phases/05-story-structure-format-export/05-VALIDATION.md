---
phase: 5
slug: 05-story-structure-format-export
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 5 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (unit/widget) |
| **Config file** | none - Flutter test convention |
| **Quick run command** | `flutter test test/features/story_structure/` |
| **Full suite command** | `flutter test test/features/story_structure/` |
| **Estimated runtime** | ~7 seconds for story_structure suite |

---

## Sampling Rate

- **After every task commit:** Run the task-specific story_structure test file(s)
- **After every plan wave:** Run `flutter test test/features/story_structure/`
- **Before `/gsd:verify-work`:** Full story_structure suite must be green
- **Max feedback latency:** ~7 seconds for scoped story_structure suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | STRC-01 | - | ForeshadowingEntry serializes, tracks status, and exposes deterministic helpers | unit | `flutter test test/features/story_structure/domain/foreshadowing_entry_test.dart` | yes | green |
| 05-01-02 | 01 | 1 | STRC-02 | - | Reminder logic flags unresolved and overdue entries without AI/network dependency | unit | `flutter test test/features/story_structure/application/foreshadowing_reminder_service_test.dart` | yes | green |
| 05-01-03 | 01 | 1 | STRC-01 | - | Hive repository persists foreshadowing entries and notifier refreshes state | unit/integration | `flutter test test/features/story_structure/infrastructure/foreshadowing_repository_test.dart test/features/story_structure/application/foreshadowing_notifier_test.dart` | yes | green |
| 05-01-04 | 01 | 1 | STRC-01 | - | Story Structure UI exposes tabs, add form, edit form, and selected-text prefill | widget | `flutter test test/features/story_structure/presentation/foreshadowing_test.dart` | yes | green |
| 05-02-01 | 02 | 2 | STRC-03 | - | PlotNode supports ordering, relationships, roles, status, and JSON roundtrip | unit | `flutter test test/features/story_structure/domain/plot_node_test.dart` | yes | green |
| 05-02-02 | 02 | 2 | STRC-03 | - | Plot node persistence and notifier CRUD/order operations work locally | unit/integration | `flutter test test/features/story_structure/infrastructure/plot_node_repository_test.dart test/features/story_structure/application/plot_node_notifier_test.dart` | yes | green |
| 05-02-03 | 02 | 2 | STRC-04 | - | GuardianAnnotation is advisory-only, dismissible, serializable, and location-aware | unit/widget | `flutter test test/features/story_structure/domain/guardian_annotation_test.dart test/features/story_structure/presentation/guardian_annotation_test.dart` | yes | green |
| 05-02-04 | 02 | 2 | STRC-04 | - | Character guardian parsing never auto-mutates manuscript text | unit | `flutter test test/features/story_structure/application/guardian_check_service_test.dart` | yes | green |
| 05-03-01 | 03 | 3 | STRC-04, STRC-05 | - | Guardian context builder keeps story context token-bounded and relevance-filtered | unit | `flutter test test/features/story_structure/application/guardian_context_builder_test.dart` | yes | green |
| 05-03-02 | 03 | 3 | STRC-05 | - | Logic guardian parses timeline/world/skill/foreshadowing findings defensively | unit | `flutter test test/features/story_structure/application/logic_guardian_service_test.dart` | yes | green |
| 05-04-01 | 04 | 4 | FRMT-01, FRMT-02, FRMT-03 | - | FormatCleaner is deterministic, idempotent, and preserves URLs/decimals/file paths | unit | `flutter test test/features/story_structure/application/format_cleaner_test.dart` | yes | green |
| 05-04-02 | 04 | 4 | FRMT-04 | - | ExportBundle preserves complete structured data for JSON export | unit | `flutter test test/features/story_structure/domain/export_bundle_test.dart` | yes | green |
| 05-04-03 | 04 | 4 | FRMT-04 | - | ExportService builds TXT/Markdown/JSON and writes through injectable file writer | unit | `flutter test test/features/story_structure/application/export_service_test.dart` | yes | green |
| 05-04-04 | 04 | 4 | FRMT-03, FRMT-04 | - | Cleanup preview requires explicit preview before apply; export dialog shows local path feedback | widget | `flutter test test/features/story_structure/presentation/format_export_test.dart` | yes | green |

Status: green · red · flaky · manual

---

## Wave 0 Requirements

- [x] `test/features/story_structure/domain/foreshadowing_entry_test.dart` - covers STRC-01 domain model and status helpers
- [x] `test/features/story_structure/application/foreshadowing_reminder_service_test.dart` - covers STRC-02 unresolved/overdue reminders
- [x] `test/features/story_structure/domain/plot_node_test.dart` and repository/notifier tests - cover STRC-03 plot node management
- [x] `test/features/story_structure/application/guardian_check_service_test.dart` and guardian annotation tests - cover STRC-04 advisory character guardian contract
- [x] `test/features/story_structure/application/guardian_context_builder_test.dart` and `logic_guardian_service_test.dart` - cover STRC-05 bounded context and logic finding parsing
- [x] `test/features/story_structure/application/format_cleaner_test.dart` - covers FRMT-01 through FRMT-03 formatting behavior
- [x] `test/features/story_structure/domain/export_bundle_test.dart`, `export_service_test.dart`, and `format_export_test.dart` - cover FRMT-04 export behavior and UI flow

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real character consistency guardian result quality | STRC-04 | Requires valid AI provider credentials and subjective review of model output quality | Configure provider, run guardian against a chapter with known personality contradiction, confirm finding is advisory and useful |
| Real timeline/world-rule contradiction result quality | STRC-05 | Requires valid AI provider credentials and story-specific judgment | Configure provider, run current chapter logic check, confirm timeline/world/skill findings are surfaced without manuscript mutation |
| Production file-picker save path UX | FRMT-04 | Current implementation includes text-field fallback; production desktop/mobile save picker should be checked interactively | Export TXT/Markdown/JSON from running app and verify path selection and written files |

These manual checks do not block local Phase 5 validation because deterministic contracts, data flow, and UI gating are covered by automated tests, while AI quality and native file picker behavior depend on credentials/device/runtime context.

---

## Validation Audit 2026-06-04

| Metric | Count |
|--------|-------|
| Phase requirements | 9 |
| Roadmap success criteria | 6 |
| Automated coverage groups | 14 |
| Gaps found | 1 |
| Resolved with documentation/test evidence | 1 |
| Escalated to manual UAT | 3 |

Automated gate command run:

- `flutter test test/features/story_structure/` - passed, 204 tests

Validation notes:

- `05-VERIFICATION.md` already verified all 6 roadmap success criteria and all 9 requirement IDs.
- The full story_structure suite now passes locally without the older provider/import blockers mentioned in early summaries.
- The known `guardian_annotation_overlay.dart` disabled "Run Check" button is non-blocking because the primary `GuardianPanel` check path is wired and tested.
- The `export_dialog.dart` path text field fallback is documented as intentional; automated tests verify export content and injectable file writing, while production picker UX remains manual.

Residual risks:

- AI-dependent guardian finding quality still needs real-provider UAT and cannot be fully proven by unit tests.
- File picker behavior should be checked in the running Windows/Android app before release.
- `flutter analyze` has repository-level warnings/info items recorded in verification; no Phase 5 test failures remain.

---

## Validation Sign-Off

- [x] All tasks have automated verification or documented manual UAT coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 10s for scoped story_structure suite
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
