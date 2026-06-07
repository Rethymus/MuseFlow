---
phase: 14
slug: world-building-first-30-chapters
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-07
updated: 2026-06-07
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test |
| **Config file** | none — Phase 14 creates `test/journey/` scripts using existing Phase 13 patterns |
| **Quick run command** | `dart analyze test/journey/helpers/ test/journey/chapter_management_test.dart` |
| **Journey smoke command** | `flutter test test/journey/chapter_management_test.dart --timeout 60s` |
| **Real API smoke command** | `flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s` |
| **Full suite command** | `flutter test test/journey/ -j 1 --timeout 900s` |
| **Estimated runtime** | Local-only checks < 60 seconds; real GLM 30-chapter generation + all-30 deviation detection may take ~10-15 minutes |

---

## Sampling Rate

- **After every task commit:** Run the task-specific `<automated>` command from its PLAN.md.
- **Fast feedback before long GLM runs:** Run `dart analyze test/journey/` plus the targeted smoke command when available.
- **After every plan wave:** Run all completed files in `test/journey/` with `-j 1` if real API tests are included.
- **Before `/gsd:verify-work`:** Full journey suite green + blocking JOURNEY-06 manual spot-check evidence recorded in `14-ISSUE-LOG.md`.
- **Max feedback latency:** < 60 seconds for local/analyze smoke checks; ~15 minutes for real API phase gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | JOURNEY-01 | T-14-01/T-14-02 | API key not logged; SecureStorage avoided | analyze | `dart analyze test/journey/helpers/journey_container.dart test/journey/helpers/xianxia_fixtures.dart test/journey/helpers/story_outline.dart` | W0 | pending |
| 14-01-02 | 01 | 1 | JOURNEY-01 | T-14-01/T-14-02 | Uses Phase 7 xianxia template, not manual world skeleton | integration | `flutter test test/journey/world_building_test.dart --timeout 120s` | W0 | pending |
| 14-02-01 | 02 | 2 | JOURNEY-02 | T-14-05 | API key not logged; knowledge assertion is failing test | integration | `flutter test test/journey/fragment_synthesis_test.dart --timeout 120s` | W0 | pending |
| 14-02-02 | 02 | 2 | JOURNEY-03 | T-14-06 | API key not logged; previews via debugPrint only | integration | `flutter test test/journey/opening_guide_test.dart --timeout 120s` | W0 | pending |
| 14-02-03 | 02 | 2 | JOURNEY-04 | T-14-07 | Local-only Hive temp data | integration | `flutter test test/journey/chapter_management_test.dart --timeout 60s` | W0 | pending |
| 14-03-01 | 03 | 3 | JOURNEY-05 | T-14-08/T-14-09 | Stop-on-error, 3s rate limit, all 30 deviation checks, no credential logging | integration | `dart analyze test/journey/serial_generation_test.dart && flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s && flutter test test/journey/serial_generation_test.dart -j 1 --timeout 900s` | W0 | pending |
| 14-03-02 | 03 | 3 | JOURNEY-05 | T-14-10/T-14-12 | E2E logs summaries only, audit flushed before snapshot | integration | `dart analyze test/journey/full_journey_test.dart && flutter test test/journey/full_journey_test.dart -j 1 --timeout 900s` | W0 | pending |
| 14-03-03 | 03 | 3 | JOURNEY-06 | T-14-10 | Evidence recorded without API keys | manual blocking | Actual app interaction: toolbar rewrite/polish/free-input, anti-AI-scent review, knowledge/Skill UI, opening guide styles, chapter operations; evidence recorded in `14-ISSUE-LOG.md` | manual | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] `test/journey/helpers/journey_container.dart` — ProviderContainer factory with real OpenAIAdapter + GLM provider/api-key overrides.
- [ ] `test/journey/helpers/xianxia_fixtures.dart` — custom supplemental character cards and Skill rules only; no manual xianxia world skeleton.
- [ ] `test/journey/helpers/story_outline.dart` — 30-chapter mortal -> Qi Refining -> Foundation Establishment outline.
- [ ] `test/journey/world_building_test.dart` — JOURNEY-01, using `worldTemplateRepositoryProvider` + `templateInstantiationServiceProvider` with template id `male-xianxia-sect` per D-07.
- [ ] `test/journey/fragment_synthesis_test.dart` — JOURNEY-02, single-body fragment -> pipeline -> real synthesis -> knowledge assertion.
- [ ] `test/journey/opening_guide_test.dart` — JOURNEY-03, service resolution + 3 differentiated variants.
- [ ] `test/journey/chapter_management_test.dart` — JOURNEY-04, independent local-only CRUD/reorder/split/merge/copy/delete cases.
- [ ] `test/journey/serial_generation_test.dart` — JOURNEY-05, single long-running 30-chapter generation with 300-500 char assertions and all-30 deviation detection.
- [ ] `test/journey/full_journey_test.dart` — E2E full flow in one test body without duplicated setUp world-building.
- [ ] `.planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` — issue log + manual evidence checklist.

Existing infrastructure from Phase 13 remains in `test/automation/` and is used only as a pattern source; Phase 14 artifacts are under `test/journey/`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Editor floating toolbar operations (rewrite/polish/free-input) | JOURNEY-06 | Requires actual selection, toolbar positioning, streaming/diff visual confirmation | 1. Open app with a generated chapter 2. Select paragraph text 3. Verify toolbar appears 4. Execute `语气改写` 5. Execute `文段润色` 6. Execute `自由输入` with `让这段更悬疑` 7. Record before/after evidence in `14-ISSUE-LOG.md` |
| Anti-AI-scent review | JOURNEY-06 | Creative quality is subjective | Review toolbar outputs for obvious AI phrases (`值得注意的是`, `总而言之`, `需要指出的是`) and record assessment/evidence |
| Knowledge injection + Skill guardian UI confirmation | JOURNEY-05/JOURNEY-06 | DeviationWarningWidget and UI affordances require visual check | Inspect generated chapters and warning UI; confirm character consistency and no obvious Skill rule violations; record findings |
| Opening guide 3-style output quality | JOURNEY-03 | Creative style differentiation is subjective | Trigger opening guide in UI; verify scene/character/suspense outputs match expected style patterns |
| Chapter operations UI (sort/split/merge/copy/delete) | JOURNEY-04 | Drag/drop, context menu, split cursor, confirmation dialogs require UI interaction | Reorder via sidebar, split at cursor, merge adjacent chapters, copy with `(副本)`, delete with confirmation, verify sidebar order |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or a blocking human checkpoint.
- [ ] Sampling continuity: every plan has fast feedback plus phase-gate command where long real API tests are required.
- [ ] Wave 0 covers all MISSING references in `test/journey/`.
- [ ] No watch-mode flags.
- [ ] Local fast feedback latency < 60s; real API phase gate documented as long-running.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
