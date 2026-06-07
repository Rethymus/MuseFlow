---
phase: 14
slug: world-building-first-30-chapters
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-07
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test |
| **Config file** | none — existing Phase 13 infrastructure |
| **Quick run command** | `flutter test test/automation/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds (30-chapter serial generation + assertions) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/automation/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green + manual spot-check checklist complete
- **Max feedback latency:** 30 seconds (unit tests), ~5 minutes (30-chapter AI generation script)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | JOURNEY-01 | — | N/A | integration | `flutter test test/automation/world_building_test.dart` | ❌ W0 | ⬜ pending |
| 14-01-02 | 01 | 1 | JOURNEY-01 | — | N/A | integration | `flutter test test/automation/world_building_test.dart` | ❌ W0 | ⬜ pending |
| 14-02-01 | 02 | 1 | JOURNEY-02 | — | N/A | integration | `flutter test test/automation/fragment_capture_test.dart` | ❌ W0 | ⬜ pending |
| 14-03-01 | 03 | 1 | JOURNEY-03 | — | N/A | integration | `flutter test test/automation/opening_guide_test.dart` | ❌ W0 | ⬜ pending |
| 14-04-01 | 04 | 1 | JOURNEY-04 | — | N/A | integration | `flutter test test/automation/chapter_management_test.dart` | ❌ W0 | ⬜ pending |
| 14-05-01 | 05 | 2 | JOURNEY-05 | — | API key not logged | integration | `flutter test test/automation/chapter_generation_test.dart` | ❌ W0 | ⬜ pending |
| 14-06-01 | 06 | 2 | JOURNEY-06 | — | N/A | manual | spot-check checklist | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/automation/helpers/glm_adapter_helper.dart` — OpenAIAdapter configured with GLM baseUrl + apiKey override
- [ ] `test/automation/helpers/test_data_factory.dart` — world-building fixture factory (character cards, skill rules, chapter stubs)
- [ ] `test/automation/world_building_test.dart` — stubs for JOURNEY-01
- [ ] `test/automation/fragment_capture_test.dart` — stubs for JOURNEY-02
- [ ] `test/automation/opening_guide_test.dart` — stubs for JOURNEY-03
- [ ] `test/automation/chapter_management_test.dart` — stubs for JOURNEY-04
- [ ] `test/automation/chapter_generation_test.dart` — stubs for JOURNEY-05

*Existing infrastructure from Phase 13: `test/automation/helpers/test_container.dart`, `test/automation/helpers/fake_adapter.dart`, `test/automation/helpers/hive_test_helper.dart`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Editor floating toolbar operations (rewrite/polish/free-edit) | JOURNEY-06 | UI interaction requires visual verification | 1. Open app with generated manuscript 2. Select text in any chapter 3. Verify floating toolbar appears 4. Test each operation (rewrite tone, polish paragraph, free input edit) 5. Verify anti-AI-scent output quality |
| Knowledge injection visual confirmation | JOURNEY-05 | DeviationWarningWidget rendering requires visual check | 1. After 30-chapter generation, inspect DeviationWarningWidget in chapters with skill rule conflicts 2. Verify warnings are accurate |
| Opening guide 3-style output quality | JOURNEY-03 | Creative output quality is subjective | 1. Trigger opening guide 2. Generate all 3 styles (scene/character/suspense) 3. Compare output quality and style differentiation |
| Chapter operations UI (sort/split/merge/copy/delete) | JOURNEY-04 | Drag-and-drop and multi-select UI interaction | 1. Create 5+ chapters 2. Test reorder via drag 3. Test split at cursor position 4. Test merge adjacent chapters 5. Test copy chapter 6. Test delete with confirmation |
| Fragment capture → AI synthesis flow | JOURNEY-02 | End-to-end creative flow requires manual UX validation | 1. Enter bullet-note fragments 2. Trigger AI synthesis 3. Verify logical coherence of output paragraphs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (unit tests)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
