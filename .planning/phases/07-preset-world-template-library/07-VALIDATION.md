---
phase: 07
slug: preset-world-template-library
status: automated_passed_manual_pending
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
audited: 2026-06-05
test_count: 31
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
| 07-01-01 | 01 | 1 | TMPL-01, TMPL-06 | T-07-01 | Bundled assets only, no network template updates | unit | `flutter test test/features/templates/domain test/features/templates/infrastructure` | W0 | passed (7 tests) |
| 07-02-01 | 02 | 2 | TMPL-01, TMPL-02, TMPL-04, TMPL-06 | — | UI reads local template models only | widget | `flutter test test/features/templates/presentation` | W0 | passed (11 tests) |
| 07-03-01 | 03 | 3 | TMPL-03, TMPL-05 | T-07-02 | AI failure does not block manual save | unit/widget | `flutter test test/features/templates/application test/features/templates/presentation` | W0 | passed (13 tests) |

*Status: all automated tests pass (31 total). G1–G13 gaps filled 2026-06-05.*

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

---

## Validation Audit 2026-06-05

| Metric | Count |
|--------|-------|
| Gaps found | 13 |
| Resolved | 13 |
| Escalated | 0 |

### Gap Resolution Details

| Gap | Priority | Test File | Test Name | Result |
|-----|----------|-----------|-----------|--------|
| G1 | HIGH | template_instantiation_service_test.dart | editing a field changes its source marker to userEdited | ✅ passed |
| G2 | HIGH | template_instantiation_service_test.dart | saveDraft returns created entity summary with names and ids | ✅ passed |
| G3 | HIGH | template_instantiation_service_test.dart | foreshadowing arcs and opening samples are not saved to repositories | ✅ passed |
| G4 | HIGH | template_completion_service_test.dart | stream error preserves original draft and returns failure | ✅ passed |
| G5 | HIGH | template_instantiation_service_test.dart | saves selected entities only *(unit test covers deselection)* | ✅ covered |
| G6 | MEDIUM | template_preview_page_test.dart | shows safe not-found state for missing template id | ✅ passed |
| G7 | MEDIUM | template_completion_service_test.dart | aiCompleted source applied to blank fields while templateDefault preserved | ✅ passed |
| G8 | MEDIUM | template_gallery_page_test.dart | tags are displayed as passive labels without tap handlers | ✅ passed |
| G9 | MEDIUM | template_draft_page_test.dart | AI completion error shows message without losing current draft | ✅ passed |
| G10 | LOW | template_gallery_page_test.dart | tapping a template card navigates to template detail route | ✅ passed |
| G11 | LOW | template_gallery_page_test.dart | shows loading indicator before templates load | ✅ passed |
| G12 | LOW | template_preview_page_test.dart | expanding opening samples shows all three styles | ✅ passed |
| G13 | LOW | template_gallery_page_test.dart | route constant knowledgeTemplates matches expected path | ✅ passed |

### Test Suite Summary

| Layer | Before | After | Delta |
|-------|--------|-------|-------|
| Domain | 3 | 3 | — |
| Infrastructure | 4 | 4 | — |
| Application | 4 | 7 | +3 |
| Presentation | 7 | 17 | +10 |
| **Total** | **18** | **31** | **+13** |
