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
| **Gap closure deterministic command** | `flutter test test/journey/automated_ui_evidence_test.dart test/journey/chapter_management_test.dart --timeout 300s` |
| **Gap closure real GLM command** | `GLM_API_KEY="$GLM_API_KEY" flutter test test/journey/serial_generation_test.dart -j 1 --timeout 1200s && GLM_API_KEY="$GLM_API_KEY" flutter test test/journey/full_journey_test.dart -j 1 --plain-name "should complete full xianxia journey from world-building to 30 chapters" --timeout 1200s` |
| **Estimated runtime** | Local-only checks < 60 seconds; real GLM 30-chapter generation + all-30 deviation detection may take ~10-15 minutes |

---

## Sampling Rate

- **After every task commit:** Run the task-specific `<automated>` command from its PLAN.md.
- **Fast feedback before long GLM runs:** Run `dart analyze test/journey/` plus the targeted smoke command when available.
- **After every plan wave:** Run all completed files in `test/journey/` with `-j 1` if real API tests are included.
- **Gap closure Plan 14-05:** Run each local/analyze gate immediately after its task because it changes shared journey helpers and regression evidence.
- **Gap closure Plan 14-06:** Run deterministic local tests before live GLM; live GLM closure requires 30/30 generation, D-11 300-500 compliance, all-30 deviation detection, and token audit evidence.
- **Gap closure Plan 14-07:** Collect human evidence for IME, bottom toolbar flip, and DeviationWarningWidget; missing evidence blocks/fails final pass even if structured `human_needed` rows exist.
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
| 14-05-01 | 05 | 5 | JOURNEY-04/JOURNEY-06 | T-14-05-01 | Journey cleanup deletes only owned temp directory; no global Hive delete | analyze + grep gate | `dart analyze test/journey/helpers/journey_container.dart test/journey/world_building_test.dart test/journey/opening_guide_test.dart test/journey/fragment_synthesis_test.dart test/journey/serial_generation_test.dart test/journey/full_journey_test.dart test/journey/automated_ui_evidence_test.dart test/journey/chapter_management_test.dart && ! grep -v '^[[:space:]]*//' test/journey/helpers/journey_container.dart \\| grep -q "Hive.deleteFromDisk"` | existing | pending |
| 14-05-02 | 05 | 5 | JOURNEY-06 | T-14-05-02 | Anti-AI-scent evidence proves removal rather than documenting limitation | integration + grep gate | `dart analyze lib/features/ai/application/anti_ai_scent_processor.dart test/journey/automated_ui_evidence_test.dart && flutter test test/journey/automated_ui_evidence_test.dart --plain-name "should remove obvious AI-scent phrases from editor output" --timeout 180s && grep -v '^[[:space:]]*//' test/journey/automated_ui_evidence_test.dart \\| grep -q "isNot(contains('总而言之'))"` | existing | pending |
| 14-05-03 | 05 | 5 | JOURNEY-04 | T-14-05-03 | Chapter operations use production `ChapterNotifier`, not duplicated test logic | integration + grep gate | `dart analyze test/journey/chapter_management_test.dart && flutter test test/journey/chapter_management_test.dart --timeout 240s && grep -v '^[[:space:]]*//' test/journey/chapter_management_test.dart \\| grep -q "chapterNotifierProvider.notifier"` | existing | pending |
| 14-06-01 | 06 | 6 | JOURNEY-05 | T-14-06-01/T-14-06-03 | GLM failures are classified and secret-safe; classified failure does not count as completion | analyze + smoke + secret grep | `dart analyze lib/features/ai/infrastructure/openai_adapter.dart test/journey/serial_generation_test.dart && flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s && ! grep -R "GLM_API_KEY\\|Authorization: Bearer\\|Bearer " -n test/journey/serial_generation_test.dart .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` | existing | pending |
| 14-06-02 | 06 | 6 | JOURNEY-05 | T-14-06-04 | Deterministic coverage is supplemental; live D-11 300-500 validation remains enforced | deterministic integration + grep gate | `dart analyze test/journey/serial_generation_test.dart test/journey/full_journey_test.dart test/journey/helpers/journey_container.dart && flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "deterministic" --timeout 300s && flutter test test/journey/full_journey_test.dart -j 1 --plain-name "deterministic" --timeout 300s && grep -v '^[[:space:]]*//' test/journey/serial_generation_test.dart \\| grep -Eq "greaterThanOrEqualTo\\(300\\)|inInclusiveRange\\(300, 500\\)|lessThanOrEqualTo\\(500\\)"` | existing | pending |
| 14-06-03 | 06 | 6 | JOURNEY-05 | T-14-06-01/T-14-06-02/T-14-06-03/T-14-06-04 | Real GLM closure requires 30/30, D-11 bounds, all-30 deviation checks, token audit totals, and closed P14-04-GLM-01 | real API blocking | `test -n "$GLM_API_KEY" && GLM_API_KEY="$GLM_API_KEY" flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s && GLM_API_KEY="$GLM_API_KEY" flutter test test/journey/serial_generation_test.dart -j 1 --timeout 1200s && GLM_API_KEY="$GLM_API_KEY" flutter test test/journey/full_journey_test.dart -j 1 --plain-name "should complete full xianxia journey from world-building to 30 chapters" --timeout 1200s && grep -Eiq "P14-04-GLM-01.*(closed|resolved|已关闭|已解决)" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md && grep -Eiq "30/30" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md && grep -Eiq "all[- ]?30.*deviation|30.*deviation.*checks|30/30.*deviation" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md && grep -Eiq "totalCalls[^0-9]*(3[0-9]|[4-9][0-9]|[1-9][0-9]{2,})" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` | existing | pending |
| 14-07-01 | 07 | 7 | JOURNEY-06 | T-14-07-01/T-14-07-02 | Human evidence required for IME, bottom toolbar flip, and DeviationWarningWidget; `human_needed` blocks/fails full pass | manual blocking + grep gate | `grep -Eiq "FloatingToolbar|语气改写|文段润色|自由输入" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md && grep -Eiq "IME|输入法|composition|候选" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md && grep -Eiq "bottom.*flip|flip.*bottom|底部.*翻转|上方" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md && grep -Eiq "DeviationWarningWidget|偏离|Skill" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md && grep -Eiq "observed|observation|已观察|human evidence|人工证据" .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md` | manual | pending |

*Status: pending · green · red · flaky*

---

## Gap Closure Sampling Expectations

### Plan 14-05

- **Task 14-05-01:** Sample every journey test file that imports `journey_container.dart` through `dart analyze`; grep gate must prove no uncommented `Hive.deleteFromDisk()` remains in the helper.
- **Task 14-05-02:** Sample the exact anti-AI-scent regression test and inspect source gates for `isNot(contains('总而言之'))` and `isNot(contains('需要指出的是'))`.
- **Task 14-05-03:** Sample production-path chapter operations by running the full `chapter_management_test.dart`; grep gate must find `chapterNotifierProvider.notifier`, `splitChapter`, `mergeChapters`, and `duplicateChapter`.

### Plan 14-06

- **Task 14-06-01:** Run analyze and the GLM smoke test. If credentials are absent, smoke may skip, but skip is not JOURNEY-05 closure evidence. Secret grep must pass.
- **Task 14-06-02:** Run deterministic serial and full journey tests without `GLM_API_KEY`; require D-11 source assertions in the live serial path as a guard against deterministic-only downgrade.
- **Task 14-06-03:** Run live GLM commands with `-j 1`. Closure sampling is all-or-nothing: 30/30 real chapters, every live chapter within 300-500 characters, all-30 deviation detection, token audit `totalCalls >= 30`, aggregate token totals, and `P14-04-GLM-01` closed/resolved. A classified GLM failure is valid debug evidence but is a red/blocking sample.

### Plan 14-07

- Human reviewer must sample actual platform UI behavior for all required platform-only items: Chinese IME composition, FloatingToolbar bottom-viewport flip, and DeviationWarningWidget readability.
- Automated grep gates only confirm that evidence was recorded; they do not replace the human checkpoint.
- If any required platform-only item has only `human_needed`, missing evidence, or an untested note, mark the sample red/blocked and do not sign off Phase 14 as fully passed.

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

| Behavior | Requirement | Why Manual | Test Instructions | Sign-Off Rule |
|----------|-------------|------------|-------------------|---------------|
| Editor floating toolbar operations (rewrite/polish/free-input) | JOURNEY-06 | Requires actual selection, toolbar positioning, streaming/diff visual confirmation | 1. Open app with a generated chapter 2. Select paragraph text 3. Verify toolbar appears 4. Execute `语气改写` 5. Execute `文段润色` 6. Execute `自由输入` with `让这段更悬疑` 7. Record before/after evidence in `14-ISSUE-LOG.md` | Human evidence required |
| FloatingToolbar bottom-viewport flip | JOURNEY-06 | Pixel-level placement cannot be proven by headless tests | Select text in the bottom 40% of the editor viewport; confirm whether toolbar flips above the selection; record platform and observation evidence | Human evidence required for full Phase 14 pass |
| Chinese IME composition | JOURNEY-06 | Requires system IME and platform composition UI | Type with Chinese IME in the editor; confirm composition/candidate behavior remains system-controlled and not obscured by toolbar | Human evidence required for full Phase 14 pass |
| Anti-AI-scent review | JOURNEY-06 | Creative quality is subjective | Review toolbar outputs for obvious AI phrases (`值得注意的是`, `总而言之`, `需要指出的是`) and record assessment/evidence | Human evidence supplements automated removal gate |
| Knowledge injection + Skill guardian UI confirmation | JOURNEY-05/JOURNEY-06 | DeviationWarningWidget and UI affordances require visual check | Inspect generated chapters and warning UI; confirm character consistency and no obvious Skill rule violations; record findings | DeviationWarningWidget human evidence required for full Phase 14 pass |
| Opening guide 3-style output quality | JOURNEY-03 | Creative style differentiation is subjective | Trigger opening guide in UI; verify scene/character/suspense outputs match expected style patterns | Human evidence recommended |
| Chapter operations UI (sort/split/merge/copy/delete) | JOURNEY-04 | Drag/drop, context menu, split cursor, confirmation dialogs require UI interaction | Reorder via sidebar, split at cursor, merge adjacent chapters, copy with `(副本)`, delete with confirmation, verify sidebar order | Human evidence recommended |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or a blocking human checkpoint.
- [ ] Sampling continuity: every plan has fast feedback plus phase-gate command where long real API tests are required.
- [ ] Gap closure plans 14-05, 14-06, and 14-07 have per-task verification rows and sampling expectations.
- [ ] JOURNEY-05 closure includes successful real GLM 30/30 evidence, D-11 300-500 live bounds, all-30 deviation detection, and token audit totals.
- [ ] JOURNEY-06 platform UI closure includes human evidence for IME composition, FloatingToolbar bottom flip, and DeviationWarningWidget; `human_needed` rows block/fail full pass.
- [ ] Wave 0 covers all MISSING references in `test/journey/`.
- [ ] No watch-mode flags.
- [ ] Local fast feedback latency < 60s; real API phase gate documented as long-running.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
