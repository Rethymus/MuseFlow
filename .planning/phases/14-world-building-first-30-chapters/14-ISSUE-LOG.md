# Phase 14 Issue Log: World-Building First 30 Chapters

**Phase:** 14-world-building-first-30-chapters  
**Created:** YYYY-MM-DD  
**Updated:** 2026-06-07  

This log captures execution findings for JOURNEY-05/JOURNEY-06: bugs, UX friction, missing needs, GLM compatibility findings, automated UI evidence, and final human-review-only notes.

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total issues | 3 |
| High severity | 1 |
| Medium severity | 2 |
| Low severity | 0 |
| 功能缺陷 | 2 |
| 体验摩擦 | 0 |
| 缺失需求 | 1 |

## Issues

| ID | Category (功能缺陷/体验摩擦/缺失需求) | Severity (高/中/低) | Requirement | Title | Reproduction Steps | Expected Behavior | Actual Behavior | Evidence |
|----|--------------------------------------|--------------------|-------------|-------|--------------------|-------------------|-----------------|----------|
| P14-04-GLM-01 | 功能缺陷 | 高 | JOURNEY-05 | Serial GLM generation fails on chapter 2 after smoke and chapter 1 success | `GLM_API_KEY` present; run `flutter test test/journey/serial_generation_test.dart -j 1 --timeout 1200s` | All 30 chapter generations complete serially with 3s spacing, then deviation detection and token audit run | Smoke passed twice; chapter 1 generated 512 chars; chapter 2 raised `AIStreamException`, so 30-chapter, deviation, and token audit evidence remain blocked | Command log observation: `[SMOKE_TEST_PASSED]` then `[JOURNEY] Chapter 1/30 generated (512 chars)` then `[ERROR] Chapter 2/30 failed: AIStreamException: ...`; reruns now log exception class plus sanitized message only; no secrets printed |
| P14-04-AUTO-01 | 缺失需求 | 中 | JOURNEY-06 | IME composition and pixel-level toolbar flip cannot be fully proven headlessly | Run `flutter test test/journey/automated_ui_evidence_test.dart --timeout 180s` in headless test environment | Automated suite should prove all previously manual toolbar checks | Operation triggerability is proven, but real system IME composition and pixel-perfect desktop toolbar flip require platform rendering / OS IME event evidence outside headless Dart tests | Automated limitation recorded; final human review should inspect IME and visual flip on target Windows/Android devices |
| P14-04-AI-01 | 功能缺陷 | 中 | JOURNEY-06 | Anti-AI-scent processor did not remove all verifier-listed phrases | Run automated anti-AI-scent evidence test with text containing all three phrases | All obvious AI-scent phrases listed by verifier are removed or flagged | Closed by P14-05: `值得注意的是`, `总而言之`, and `需要指出的是` are removed and recorded as banned-word highlights | `flutter test test/journey/automated_ui_evidence_test.dart --plain-name "should remove obvious AI-scent phrases from editor output" --timeout 180s`; source gate asserts `isNot(contains('总而言之'))` and `isNot(contains('需要指出的是'))` |

- [x] CR-01/P14-05-HIVE: journey Hive cleanup now owns a per-container `Directory.systemTemp.createTempSync('journey_test_')` directory, calls `Hive.close()`, and deletes only that `tempDir` recursively; no helper-level global `Hive.deleteFromDisk()` cleanup remains.
- [x] P14-05-AI-01: anti-AI-scent processing now removes `值得注意的是`, `总而言之`, and `需要指出的是`; automated evidence asserts absence and highlight reporting for all three verifier-listed phrases.

- [x] Deterministic supplemental JOURNEY-05 path: no-credential serial journey uses `journey-local-test-key` + deterministic adapter, generated 30/30 local chapters in D-11 range, sampled character-name checks passed, all-30 deviation detection invoked, and token audit flushed with `totalCalls >= 30`. This is local orchestration evidence only and does not close `P14-04-GLM-01`.
- [x] Deterministic supplemental full journey path: no-credential world-building → fragment synthesis/opening surrogate → 30 chapter generation → persistence → token audit path runs with deterministic adapter and D-11 checks. This supplements, but does not replace, required real GLM D-02/D-11 evidence.

## RESEARCH.md Open Questions -- Execution Findings

### OQ-01: GLM API Streaming Compatibility

- **Status:** verified
- **Findings:** GLM streaming compatibility was proven for short calls. The smoke command `flutter test test/journey/serial_generation_test.dart -j 1 --plain-name "should pass GLM streaming smoke test" --timeout 120s` passed with a 230-character streamed response. The full serial command also passed its initial smoke (191 chars) and the pre-loop smoke (482 chars) before failing later in sustained generation.
- **Impact:** Basic streaming compatibility is verified; sustained 30-chapter validation is blocked by P14-04-GLM-01 after chapter 1.
- **Evidence:** Safe output excerpts: `[SMOKE_TEST_PASSED] GLM API streaming compatible (230 chars)`, `[SMOKE_TEST_PASSED] GLM API streaming compatible (191 chars)`, `[SMOKE_TEST_PASSED] GLM API streaming compatible (482 chars)`. No API key or bearer token was printed.

### OQ-02: Provider Graph Depth with Real API Credentials

- **Status:** verified
- **Findings:** Provider graph overrides resolved for real GLM credentials after two test-harness fixes: (1) `createJourneyContainer()` no longer initializes `TestWidgetsFlutterBinding` for real network keys, avoiding Flutter test HTTP interception; (2) the journey container registers Hive adapters and uses a filesystem asset loader for `WorldTemplateRepository`, avoiding typed Hive and asset-bundle failures in non-widget GLM tests. Fragment synthesis and opening guide suites passed with real `GLM_API_KEY`.
- **Impact:** PromptPipeline, OpeningGeneratorService, template instantiation, real adapter, and token audit provider graph can resolve. Long-run serial generation is now blocked by the API stream failure recorded in P14-04-GLM-01, not by missing provider overrides.
- **Evidence:** `fragment_synthesis_test.dart` passed 4/4 with synthesis length 445 chars and character names `[林风, 清虚真人, 苏雪晴, 赵天磊]`; `opening_guide_test.dart` passed 3/3 with 3 non-identical styles `[场景切入, 人物切入, 悬念切入]`; `world_building_test.dart` passed 1/1 after template repository/service wiring.

### OQ-03: Manual Spot-Check Scope Definition

- **Status:** revised-to-automated-first
- **Findings:** User changed the checkpoint from manual step-by-step evidence collection to automated-first validation with final human review only. Added `test/journey/automated_ui_evidence_test.dart`, which passed 5/5 and covers editor AI operation triggerability (`语气改写`/`文段润色`/`自由输入` with `让这段更悬疑`), anti-AI-scent phrase detection, knowledge/Skill evidence, opening guide style generation, and chapter reorder/split/merge/copy/delete/final order.
- **Impact:** Phase 14 now records repeatable automated evidence for most former manual-only checks. Platform-specific visual/IME checks remain as explicit limitations in P14-04-AUTO-01 and require final human review rather than executor-side manual data entry.
- **Evidence:** `dart analyze test/journey/automated_ui_evidence_test.dart test/journey/helpers/journey_container.dart` passed; `flutter test test/journey/automated_ui_evidence_test.dart --timeout 180s` passed 5/5 with `[AUTO_UI]` evidence logs.

- [x] P14-05-CHAPTER-01: chapter management validation now calls production `chapterNotifierProvider.notifier` operations for reorder, split, merge, duplicate, and delete; duplicate re-reads updated content before copying and does not claim platform UI proof.

## Automated UI Evidence + Final Human Review (JOURNEY-06)

### Automated Verifications

Executed by test scripts and checkable via test output:

- [x] Editor AI operation triggerability: rewrite, polish, free input with `让这段更悬疑` (automated_ui_evidence_test)
- [x] Anti-AI-scent check removes all verifier-listed obvious phrases and records banned-word highlights (automated_ui_evidence_test)
- [x] Knowledge/Skill evidence: NameIndex matches and 4 active Skill rules (automated_ui_evidence_test)
- [x] Opening guide 3 non-identical variants (opening_guide_test group 3 + automated_ui_evidence_test)
- [x] Fragment synthesis produces non-empty output > 50 chars (fragment_synthesis_test group 3)
- [x] Chapter operations: reorder/split/merge/copy/delete/final order (automated_ui_evidence_test)

### Blocked GLM Serial Verifications

Remain blocked by P14-04-GLM-01; not marked complete:

- [ ] Character name presence in generated 30-chapter content (serial_generation_test group 4)
- [ ] Deviation detection warnings logged for 30 chapters (serial_generation_test group 5)
- [ ] Token audit accuracy: totalCalls >= 30 (serial_generation_test group 6)
- [ ] 30 chapters each 300-500 characters (serial_generation_test group 3, per D-11)

### Automated-First Evidence Details

Former manual-only checks converted to repeatable automated checks where possible.

#### Editor Floating Toolbar

- [x] `语气改写` operation triggerability proven via `EditorAINotifier.startOperation(EditorAIOperation.toneRewrite, ...)` with FakeAdapter stream.
- [x] `文段润色` operation triggerability proven via `EditorAIOperation.paragraphPolish`.
- [x] `自由输入` operation triggerability proven via `EditorAIOperation.freeInput` with instruction `让这段更悬疑`.
- [x] Output check proves `值得注意的是`, `总而言之`, and `需要指出的是` removal.
- [x] All three removed phrases are recorded as banned-word highlights for UI reporting.
- [ ] Pixel-level toolbar positioning/flip and real IME composition are not fully provable in headless tests; see P14-04-AUTO-01.

**Evidence:** `flutter test test/journey/automated_ui_evidence_test.dart --plain-name "should remove obvious AI-scent phrases from editor output" --timeout 180s` passed. Logs: `[AUTO_UI] editor operations passed: rewrite/polish/freeInput`; `[AUTO_UI] anti-AI-scent removal passed; verifier-listed phrases removed`.

#### Knowledge Injection + Skill Guardian

- [x] NameIndex finds character/template setting matches after template save and custom supplements.
- [x] Four active Skill rules exist (`境界体系约束`, `门派等级森严`, `世界观禁忌`, `能力限制`).
- [x] `KnowledgeInjectionMiddleware` provider resolves against refreshed NameIndex.
- [ ] Generated 30-chapter content cannot be checked for all-chapter Skill consistency because serial GLM generation remains blocked by P14-04-GLM-01.
- [ ] `DeviationWarningWidget` visual rendering remains final-review-only/platform UI evidence; see P14-04-AUTO-01.

**Evidence:** `automated_ui_evidence_test.dart` passed with `[AUTO_UI] knowledge/Skill evidence passed: matches=3, skills=4`.

#### Opening Guide 3 Styles

- [x] Scene-style (`场景切入`) returns environmental/atmospheric text in automated stream.
- [x] Character-style (`人物切入`) returns protagonist action text in automated stream.
- [x] Suspense-style (`悬念切入`) returns mystery/tension hook text in automated stream.
- [x] GLM opening guide test also passed with three non-identical styles.

**Evidence:** `opening_guide_test.dart` passed 3/3 with `[STYLES] [场景切入, 人物切入, 悬念切入]`; `automated_ui_evidence_test.dart` passed with `[AUTO_UI] opening guide styles passed: [scene, character, suspense]`.

#### Chapter Operations

- [x] Reorder operation proven through `ChapterNotifier.reorder()`; final sort order remains sequential.
- [x] Split operation proven through `splitChapter()`; before/after content persisted.
- [x] Merge operation proven through `mergeChapters()`; merged content persisted and second chapter removed.
- [x] Copy operation proven through `duplicateChapter()`; duplicate has `(副本)` suffix and copied content.
- [x] Delete operation proven through `delete()`; deleted chapter is absent from repository.
- [x] Final sort order remains `[0, 1, 2, 3, 4]`.

**Evidence:** `automated_ui_evidence_test.dart` passed with `[AUTO_UI] chapter operations passed: reorder/split/merge/copy/delete/finalOrder`.

## Severity Classification Guide

| Severity | Definition | Examples |
|----------|------------|----------|
| 高 | Data loss, crash, AI call failure, incorrect content generation | API call fails after smoke test, chapter save drops content, generated chapter violates required 300-500 bounds |
| 中 | Noticeable UX friction, missing expected feedback, suboptimal layout | Toolbar appears in awkward position, operation lacks loading feedback, chapter reorder is confusing |
| 低 | Minor visual inconsistency, nice-to-have, edge case polish | Label alignment issue, copy text wording, rare edge case notes |

## Evidence Hygiene

- Never paste `GLM_API_KEY` or any other secret.
- Prefer command output excerpts that show status markers and counts, not full generated chapter prose.
- For manual UI checks, record concise observations plus screenshot/file paths where available.
