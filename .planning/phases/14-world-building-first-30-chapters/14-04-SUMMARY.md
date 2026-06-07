---
phase: 14-world-building-first-30-chapters
plan: 04
subsystem: journey-validation-gap-closure
tags: [journey, validation, glm, automated-evidence, xianxia]
dependency_graph:
  requires: [14-01, 14-02, 14-03]
  provides: [template-instantiation-evidence, glm-smoke-evidence, automated-ui-evidence, structured-limitations]
  affects: [JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04, JOURNEY-05, JOURNEY-06]
tech_stack:
  added: []
  patterns: [ProviderContainer journey harness, FakeAdapter automated evidence, filesystem template asset loader, Hive adapter registration]
key_files:
  created:
    - test/journey/automated_ui_evidence_test.dart
  modified:
    - test/journey/world_building_test.dart
    - test/journey/helpers/xianxia_fixtures.dart
    - test/journey/helpers/journey_container.dart
    - test/journey/serial_generation_test.dart
    - test/journey/full_journey_test.dart
    - .planning/phases/14-world-building-first-30-chapters/14-ISSUE-LOG.md
decisions:
  - "Task 3 checkpoint converted by user from manual item-by-item evidence to automated-first validation with final human review only."
  - "Do not mark GLM 30-chapter serial generation complete because the real run failed on chapter 2 with AIStreamException."
metrics:
  duration: "checkpoint continuation"
  completed_date: "2026-06-07"
  tasks_completed: 3
  files_changed: 7
---

# Phase 14 Plan 04: Verification Gap Closure Summary

## One-Liner

Closed Phase 14 validation gaps with Phase 7 xianxia template instantiation, real GLM smoke/synthesis/opening evidence, and automated-first UI validation evidence while preserving honest blockers for sustained GLM generation and platform-only checks.

## Tasks Completed

| Task | Status | Commit | Evidence |
|---|---|---|---|
| Task 1: Fix JOURNEY-01 to instantiate Phase 7 xianxia template | Complete | `9c84ff0` | `world_building_test.dart` now uses `worldTemplateRepositoryProvider`, `getById('male-xianxia-sect')`, `templateInstantiationServiceProvider`, `createDraft`, and `saveDraft`; `sectWorld()` removed. |
| Task 2: Run real GLM journey tests and record non-secret evidence | Complete with blocker recorded | `dfd8c90` | GLM smoke, fragment synthesis, and opening guide evidence recorded; serial 30-chapter run failed at chapter 2 and remains `P14-04-GLM-01`. |
| Task 3: Automated-first replacement for manual UI validation | Complete as controlled deviation | `d798d31` | `automated_ui_evidence_test.dart` covers editor operation triggerability, anti-AI-scent detection, knowledge/Skill evidence, opening styles, and chapter operations. |

## Verification Performed

- `dart analyze test/journey/world_building_test.dart test/journey/helpers/xianxia_fixtures.dart`
- `flutter test test/journey/world_building_test.dart --timeout 120s`
- `GLM_API_KEY` present: `flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s`
- `GLM_API_KEY` present: `flutter test test/journey/fragment_synthesis_test.dart -j 1 --timeout 300s`
- `GLM_API_KEY` present: `flutter test test/journey/opening_guide_test.dart -j 1 --timeout 300s`
- `GLM_API_KEY` present: `flutter test test/journey/serial_generation_test.dart -j 1 --timeout 1200s` failed at chapter 2 and was recorded as blocker.
- `dart analyze test/journey/automated_ui_evidence_test.dart test/journey/helpers/journey_container.dart test/journey/world_building_test.dart test/journey/helpers/xianxia_fixtures.dart test/journey/serial_generation_test.dart test/journey/full_journey_test.dart`
- `flutter test test/journey/world_building_test.dart test/journey/automated_ui_evidence_test.dart --timeout 240s`
- Secret hygiene check confirmed `14-ISSUE-LOG.md` does not contain `$GLM_API_KEY`.

## Automated Evidence Added

`test/journey/automated_ui_evidence_test.dart` passed 5/5 and records repeatable evidence for:

- Editor AI triggerability: `语气改写`, `文段润色`, and `自由输入` with `让这段更悬疑`.
- Anti-AI-scent detection: `值得注意的是` is removed; `总而言之` and `需要指出的是` remain as documented limitation rather than false pass.
- Knowledge/Skill evidence: NameIndex matches template/custom names and 4 active Skill rules resolve.
- Opening guide styles: `scene`, `character`, `suspense` variants are distinct.
- Chapter operations: reorder, split, merge, copy, delete, and final sequential sort order.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Real network tests were blocked by Flutter test HTTP interception**
- **Found during:** Task 2 GLM smoke test
- **Issue:** `TestWidgetsFlutterBinding.ensureInitialized()` in the shared journey container caused real `HttpClient` requests to be intercepted with HTTP 400.
- **Fix:** Only initialize `TestWidgetsFlutterBinding` for local asset/test-key mode, allowing real GLM tests to use network IO.
- **Files modified:** `test/journey/helpers/journey_container.dart`
- **Commit:** `dfd8c90`

**2. [Rule 3 - Blocking] Journey Hive boxes lacked registered adapters and had a typed fragments conflict**
- **Found during:** Task 2 fragment synthesis run
- **Issue:** `Fragment` writes failed without adapters; opening `fragments` as `dynamic` conflicted with typed repository access.
- **Fix:** Registered Hive adapters in the journey container and let `fragmentRepositoryProvider` open the typed `fragments` box.
- **Files modified:** `test/journey/helpers/journey_container.dart`
- **Commit:** `dfd8c90`

**3. [Rule 3 - Blocking] Template asset loading failed in non-widget GLM tests**
- **Found during:** Task 2 serial/full journey setup
- **Issue:** `rootBundle` required Flutter services binding in non-widget tests.
- **Fix:** Overrode `worldTemplateRepositoryProvider` with a filesystem asset loader for journey tests.
- **Files modified:** `test/journey/helpers/journey_container.dart`
- **Commit:** `dfd8c90`

**4. [Rule 1 - Bug] Serial/full tests asserted template prose that does not exist in the actual Phase 7 asset**
- **Found during:** Task 2 serial run
- **Issue:** Tests expected the saved template world description to contain `练气`, but the real `male-xianxia-sect` asset description contains `宗门` and stores cultivation details elsewhere.
- **Fix:** Updated assertions to verify actual template identity/content (`青冥`, `宗门`) without weakening the required template path.
- **Files modified:** `test/journey/serial_generation_test.dart`, `test/journey/full_journey_test.dart`
- **Commit:** `dfd8c90`

### Controlled User Deviation

**Task 3 checkpoint changed from manual evidence entry to automated-first/final-review-only.**
- **Requested by:** User after checkpoint
- **Implementation:** Added automated evidence test and rewrote issue-log manual sections as automated evidence plus explicit platform limitations.
- **Files modified:** `test/journey/automated_ui_evidence_test.dart`, `test/journey/helpers/journey_container.dart`, `14-ISSUE-LOG.md`
- **Commit:** `d798d31`

## Blockers and Limitations

| ID | Status | Description |
|---|---|---|
| `P14-04-GLM-01` | Open | Real GLM serial generation failed on chapter 2 after smoke and chapter 1 success; 30-chapter generation, all-chapter deviation detection, and totalCalls >= 30 token audit remain unproven. |
| `P14-04-AUTO-01` | Open limitation | Headless automated tests cannot fully prove OS-level IME composition or pixel-perfect toolbar flip on real desktop/mobile targets. |
| `P14-04-AI-01` | Open | Anti-AI-scent processor removes `值得注意的是` but not `总而言之` / `需要指出的是`; recorded honestly rather than marked pass. |

## Known Stubs

None found in created/modified plan files. The automated evidence uses `FakeAdapter` intentionally for deterministic non-GLM UI-operation triggerability; it is not a product stub and does not claim real 30-chapter output.

## Threat Flags

No new product trust boundary was introduced. Existing external GLM API and evidence-log boundaries were exercised; API key secrecy was verified by grep and no secrets were committed.

## Requirements Impact

- `JOURNEY-01`: Template-instantiation blocker closed.
- `JOURNEY-02`: Real GLM fragment synthesis evidence passed.
- `JOURNEY-03`: Real GLM opening guide and automated style evidence passed.
- `JOURNEY-04`: Automated chapter operation evidence passed.
- `JOURNEY-05`: Partially verified; sustained 30-chapter GLM generation blocked by `P14-04-GLM-01`.
- `JOURNEY-06`: Automated-first evidence passed for operation triggerability and rules; platform-only IME/visual checks remain final-review limitations.

## Self-Check: PASSED

- Created summary exists: `.planning/phases/14-world-building-first-30-chapters/14-04-SUMMARY.md`.
- Task commits exist: `9c84ff0`, `dfd8c90`, `d798d31`.
- Shared orchestrator artifacts intentionally not modified: `STATE.md` and `ROADMAP.md` untouched by this worktree agent.
