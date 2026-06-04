---
phase: 04
slug: knowledge-base-skill-system
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 04 — Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`) |
| **Config file** | `analysis_options.yaml` |
| **Quick run command** | `flutter test test/features/knowledge/` |
| **Full suite command** | `flutter test` |
| **Static analysis command** | `flutter analyze --no-fatal-infos` |
| **Estimated runtime** | ~4 seconds for knowledge suite |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/knowledge/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green and UAT checks must pass
- **Max feedback latency:** ~4 seconds for Phase 4 scoped tests

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | KNOW-01, KNOW-02 | T-04-01, T-04-02 | Entity field limits, control-character rejection, alias limits | unit | `flutter test test/features/knowledge/domain/character_card_test.dart test/features/knowledge/domain/world_setting_test.dart` | yes | green |
| 04-01-02 | 01 | 1 | KNOW-01, KNOW-02 | T-04-02 | Hive-backed CRUD and search persist/retrieve local knowledge data | unit/integration | `flutter test test/features/knowledge/infrastructure/character_card_repository_test.dart test/features/knowledge/infrastructure/world_setting_repository_test.dart` | yes | green |
| 04-01-03 | 01 | 1 | KNOW-01, KNOW-02 | — | Riverpod notifiers load, add, save, delete, and search current state | unit | `flutter test test/features/knowledge/application/character_card_notifier_test.dart test/features/knowledge/application/world_setting_notifier_test.dart` | yes | green |
| 04-02-01 | 02 | 2 | KNOW-04 | T-04-04 | NameIndex skips too-short names, finds CJK matches, supports removal and duplicate names | unit | `flutter test test/features/knowledge/infrastructure/name_index_test.dart` | yes | green |
| 04-02-02 | 02 | 2 | KNOW-03, KNOW-04 | T-04-03 | KnowledgeInjectionMiddleware injects matched context and appends to system prompt within token budget path | unit | `flutter test test/features/knowledge/application/knowledge_injection_middleware_test.dart` | yes | green |
| 04-03-01 | 03 | 2 | SKIL-01, SKIL-02 | T-04-05, T-04-06 | SkillDocument serializes, implements KnowledgeEntity, and enforces size boundaries | unit | `flutter test test/features/knowledge/domain/skill_document_test.dart` | yes | green |
| 04-03-02 | 03 | 2 | SKIL-01, SKIL-02 | T-04-05, T-04-06 | SkillGenerationService builds structured prompts and parses JSON/Markdown/raw fallback | unit | `flutter test test/features/knowledge/application/skill_generation_service_test.dart` | yes | green |
| 04-04-01 | 04 | 3 | SKIL-03, SKIL-05 | T-04-08 | SkillEnforcementMiddleware injects active rules, taboos, and terminology only | unit | `flutter test test/features/knowledge/application/skill_enforcement_middleware_test.dart` | yes | green |
| 04-04-02 | 04 | 3 | SKIL-04 | T-04-07 | DeviationDetectionService parses warnings, filters low severity, and handles invalid JSON safely | unit | `flutter test test/features/knowledge/application/deviation_detection_service_test.dart` | yes | green |
| 04-04-03 | 04 | 3 | SKIL-04, SKIL-05 | T-04-07 | Editor AI path triggers advisory deviation check without blocking AI operation | regression | `flutter test test/features/editor/application/editor_ai_notifier_test.dart` | yes | green |
| 04-05-01 | 05 | 3 | KNOW-05 | T-04-09 | Ctrl+K route/dialog integration and shell navigation remain valid | regression | `flutter test test/app/navigation_test.dart test/app/window_management_test.dart test/app/adaptive_layout_test.dart` | yes | green |

Status: green · red · flaky · manual

---

## Wave 0 Requirements

Existing infrastructure covers all Phase 4 requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Knowledge base CRUD through UI | KNOW-01, KNOW-02 | Widget-level forms/navigation currently validated by UAT rather than dedicated widget tests | Open knowledge base, create/edit/search/delete character and world-setting entries, navigate away/back, confirm persistence. |
| AI provider receives injected knowledge in a real operation | KNOW-03 | Requires configured provider or controlled E2E prompt capture | Create a character/setting, mention its name in editor, trigger AI operation, confirm matched context is included. |
| Skill generation wizard experience | SKIL-01, SKIL-02 | Streaming AI UX and review flow require interactive validation | Open skill wizard, enter concept, generate, review sections, save. |
| Deviation warning display/dismissal | SKIL-04 | Visual placement and dismissal UX require UI validation | Trigger a contradiction warning and dismiss individual/all warnings. |
| Quick insert keyboard behavior | KNOW-05 | Native keyboard focus/caret behavior is best verified in interactive editor | Press Ctrl+K in editor, search/filter, select entity, confirm display name insertion at caret/selection. |

Manual UAT source: `.planning/phases/04-knowledge-base-skill-system/04-UAT.md` records 7/7 pass, 0 issues.

---

## Validation Audit 2026-06-04

| Metric | Count |
|--------|-------|
| Phase requirements | 10 |
| Automated coverage groups | 11 |
| Manual UAT behaviors | 5 |
| Gaps found | 5 |
| Resolved with tests | 5 |
| Escalated | 0 |

Added validation tests:

- `test/features/knowledge/infrastructure/name_index_test.dart`
- `test/features/knowledge/application/knowledge_injection_middleware_test.dart`
- `test/features/knowledge/application/skill_generation_service_test.dart`
- `test/features/knowledge/application/skill_enforcement_middleware_test.dart`
- `test/features/knowledge/application/deviation_detection_service_test.dart`

Verification commands run:

- `flutter test test/features/knowledge/infrastructure/name_index_test.dart test/features/knowledge/application/knowledge_injection_middleware_test.dart test/features/knowledge/application/skill_generation_service_test.dart test/features/knowledge/application/skill_enforcement_middleware_test.dart test/features/knowledge/application/deviation_detection_service_test.dart` — passed
- `flutter test test/features/knowledge/` — passed, 107 tests
- `flutter analyze --no-fatal-infos` — completed with existing warnings/info outside this validation scope

Analysis residual risks:

- Static analysis currently reports pre-existing warnings/info in `integration_test/`, `story_structure`, and several older tests. None were introduced by the Phase 4 validation tests, but they should be cleaned before a strict zero-warning release gate.

---

## Validation Sign-Off

- [x] All tasks have automated verification or documented manual UAT coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 10s for scoped Phase 4 tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
