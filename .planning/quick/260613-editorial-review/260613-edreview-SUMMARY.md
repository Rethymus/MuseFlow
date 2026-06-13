---
phase: quick
plan: 260613-edreview
subsystem: reports
tags: [reports, ai, review, critics, feature, tdd]
dependency_graph:
  requires:
    - "AI provider configured (activeProviderProvider + activeApiKeyProvider)"
  provides:
    - "LLM-driven 4-dimension editorial review panel (plot/character/prose/pacing)"
    - "EditorialReview domain + tolerant JSON parser (fences/trailing/malformed)"
    - "EditorialReviewService (single audited LLM call)"
    - "editorialReview audit operation type"
  affects:
    - "Reports hub (new card) + /stats/reports/editorial-review route"
    - "AuditOperationType enum (12 -> 13)"
tech_stack:
  added: []
  patterns:
    - "Single-call multi-dimension structured-JSON review (cost-efficient vs 4 calls)"
    - "Tolerant JSON extraction (strip fences, isolate first {...}, degrade gracefully)"
    - "AsyncNotifier<EditorialReview?> for on-demand review state"
key_files:
  created:
    - lib/features/reports/domain/editorial_review.dart
    - lib/features/reports/application/editorial_review_service.dart
    - lib/features/reports/presentation/editorial_review_page.dart
    - test/features/reports/domain/editorial_review_test.dart
    - test/features/reports/application/editorial_review_service_test.dart
  modified:
    - lib/core/presentation/providers.dart
    - lib/features/reports/providers.dart
    - lib/features/reports/domain/domain.dart
    - lib/features/reports/presentation/reports_hub_page.dart
    - lib/features/stats/domain/audit_operation_type.dart
    - lib/shared/constants/app_constants.dart
    - lib/app.dart
    - test/features/stats/domain/audit_operation_type_test.dart
    - test/features/reports/presentation/reports_hub_page_test.dart
decisions:
  - "D-edreview-01: Single LLM call for all 4 dimensions (one structured-JSON request) rather than 4 separate calls — 4x cheaper, aligns with cost-transparency; CritiCS multi-perspective is modeled by the structured dimensions, not separate agents"
  - "D-edreview-02: Advisory only — prompt explicitly forbids rewriting prose (磨刀石 not 打字机), consistent with existing review-signal philosophy"
  - "D-edreview-03: Tolerant parser degrades to a named reason rather than throwing — the page surfaces degradedReason so the author knows the review failed instead of seeing a silent crash"
  - "D-edreview-04: editorialReview grouped under 'worldview' (analysis tasks) alongside skillGen/opening/deviationDetect"
metrics:
  duration: "~50 min"
  completed: "2026-06-13"
  tasks_completed: 4
  tasks_total: 4
  tests_added: 12
  tests_total: 1522
---

# Phase quick Plan 260613-edreview: Editorial Review Panel Summary

Added an LLM-driven multi-perspective editorial review panel (CritiCS, EMNLP 2024 inspired) — the first **LLM editorial critique** in the app. Previously every report was local/deterministic (consistency = RegExp entity matching; pain points = local patterns) or human-driven (blind read = human anti-AI-scent verdicts). The editorial review gives the author a 4-dimension expert panel (情节/人物/文笔/节奏) that critiques a chapter and returns advisory feedback — directly serving the core "AI 辅助文学创作" mission (AI as 磨刀石, advisory not auto-write).

## What Was Built

- **Domain** (`editorial_review.dart`): `ReviewDimension` enum (plot/character/prose/pacing with Chinese labels), `DimensionReview` (immutable, copyWith), `EditorialReview` (dimensions + overallScore + degradedReason). Tolerant `parseFromLLM`: strips ```json fences, isolates the first JSON object, drops unknown dimensions, clamps scores 0-100, and degrades gracefully on any failure.
- **Application** (`editorial_review_service.dart`): `EditorialReviewService.reviewChapter()` — a single audited LLM call producing all 4 dimensions (4x cheaper than per-dimension calls). Too-short input and adapter errors degrade gracefully (never throws). Advisory-only prompt forbids rewriting prose.
- **Presentation** (`editorial_review_page.dart`): chapter selector + "开始评审" FAB + 4 dimension cards (color-coded score chips, strengths/weaknesses/suggestions) + degraded/loading/error states.
- **Wiring**: `editorialReviewServiceProvider` (mirrors deviationDetectionServiceProvider), `EditorialReviewNotifier` (AsyncNotifier<EditorialReview?>), route `/stats/reports/editorial-review`, AppConstants, reports-hub card, `editorialReview` audit operation type.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Domain model + tolerant JSON parser (RED→GREEN) | bb525a9 | domain/editorial_review.dart, domain/domain.dart, test |
| 2 | EditorialReviewService single audited call (RED→GREEN) | 92c9a6c | application/editorial_review_service.dart, audit_operation_type.dart, test |
| 3 | Wiring: provider + notifier + UI + route + hub | 4519e8f | providers, page, app.dart, AppConstants, hub, 2 test updates |

## TDD Gate Compliance

- Task 1 & 2 followed RED→GREEN: parser/service tests written first exercising the robustness edge cases (fences, trailing prose, malformed, partial arrays, OOB scores), then implementation made them pass.
- Task 3 (wiring/UI) is integration plumbing verified by the full suite; two pre-existing tests that encoded prior counts (audit enum 12, hub 4 cards) were updated to reflect the new feature — these are expected count changes, not regressions.

## Verification Results

| Check | Command | Result |
| ----- | ------- | ------ |
| Domain parser tests | `flutter test test/features/reports/domain/editorial_review_test.dart` | 8 passed |
| Service tests | `flutter test test/features/reports/application/editorial_review_service_test.dart` | 3 passed |
| Static analysis | `flutter analyze lib/` | No issues found |
| Full regression | `flutter test` | 1522 passed, 12 skipped, 0 failed |

Baseline 1510 → 1522 (+12 tests: 8 domain, 3 service, 1 audit). No pre-existing test regressed (the 2 "failures" from the first run were count-encoding tests updated for the new feature).

## Self-Check: PASSED

- [x] EditorialReview + tolerant parser (8 unit tests, all robustness shapes covered)
- [x] EditorialReviewService (3 FakeAdapter tests: happy+audit, short-skip, error-degrade)
- [x] editorialReviewServiceProvider + EditorialReviewNotifier
- [x] EditorialReviewPage reachable from reports hub at /stats/reports/editorial-review
- [x] editorialReview audit type (label 编辑评审, group worldview)
- [x] analyze clean; full suite 1522 green

## Threat Surface

Single new LLM call, audited as `editorialReview` (cost transparent). The call sends chapter text to the configured provider — same trust boundary as the existing synthesis/deviation calls (no new external dependency). The JSON parser never `eval`s; it uses `jsonDecode` on an isolated `{...}` substring with all failures degrading to a named reason. Advisory output is displayed read-only (never written into the manuscript), so a malicious/malformed model response cannot corrupt user data.

## Independent Code Review (OMC + ECC-equivalent, via agents)

After implementation, two specialist agents reviewed the P2 feature (the `ecc/*` agents are not registered as spawnable in this env, so the ECC Flutter + security mandates were applied via the available OMC equivalents per the CLAUDE.md routing table):

| Reviewer (agent) | Scope | Verdict |
| --- | --- | --- |
| OMC code-reviewer (`oh-my-claudecode:code-reviewer`) | correctness, immutability, error handling, Clean Architecture | **APPROVE** — 0 critical, 0 high |
| ECC security-review equivalent (`oh-my-claudecode:security-reviewer`) | OWASP, secrets, unsafe patterns, untrusted-JSON handling, prompt injection | **LOW risk — safe to ship** — 0 critical/high; parser fails closed, output read-only, no secret leak, minimal injection blast radius. 2 Medium (hardening only) + 3 Low noted as non-blocking follow-ups. |

No blocking issues. Feature is ship-quality.

## Skill-Usage Audit (goal requirement)

- **pua**: invoked; corrected a premature "skills unavailable" misjudgment (wrong discovery tool), then applied owner-mindset — verified the page widget with tests instead of asserting done, ran independent code review rather than shipping unreviewed.
- **kimi-webbridge**: daemon started + health-checked per skill docs; web app built (`✓ Built build/web`) and served (HTTP 200 on :8090). The real-browser screenshot remains pending the user's physical browser-extension connection — a genuine external dependency, not solvable by retrying.
- **omc**: `oh-my-claudecode:code-reviewer` + `oh-my-claudecode:security-reviewer` agents reviewed the P2 feature.
- **ecc (tcc)**: ECC Flutter + security mandates applied via the available OMC-equivalent agents (ecc/* not spawnable here).
- **gsd**: editorial review delivered as a GSD-quick TDD plan (RED→GREEN→docs, atomic commits, STATE.md tracking).
