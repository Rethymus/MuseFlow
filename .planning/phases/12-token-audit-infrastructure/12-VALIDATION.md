---
phase: 12
slug: token-audit-infrastructure
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-06
validated: 2026-06-08
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter test |
| **Config file** | none — existing infrastructure |
| **Quick run command** | `flutter test <focused files>` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | focused ~5s; full suite varies |

---

## Sampling Rate

- **After every task commit:** Run focused `flutter test` for affected files
- **After every plan wave:** Run focused Phase 12 suite
- **Before `/gsd:verify-work`:** Full suite should be green or unrelated failures documented
- **Max feedback latency:** focused commands used for Nyquist gaps

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | AUDIT-01 | T-12-03 | TokenAuditRecord validates non-negative token counts; AuditOperationType exposes 8 typed operations and 4 groups | unit | `flutter test test/features/stats/domain/token_audit_record_test.dart test/features/stats/domain/audit_operation_type_test.dart` | ✅ | ✅ green |
| 12-01-02 | 01 | 1 | AUDIT-01, AUDIT-02 | T-12-01, T-12-02, T-12-04 | Repository persists and limits records; service buffers/flushes/falls back; OpenAI adapter exposes usage callback | unit/integration | `flutter test test/features/stats/infrastructure/token_audit_repository_test.dart test/features/stats/application/token_audit_service_test.dart test/features/stats/application/token_audit_notifier_test.dart test/features/ai/infrastructure/openai_adapter_test.dart` | ✅ | ✅ green |
| 12-02-01 | 02 | 2 | AUDIT-01 | T-12-02 | All 6 AI call sites record audit data after successful stream completion with correct operation type/context; synthesis no-record-on-error remains covered | unit | `flutter test test/features/ai/presentation/synthesis_notifier_test.dart --name "token audit" test/features/editor/application/editor_ai_notifier_test.dart test/features/onboarding/application/opening_generator_service_test.dart test/features/knowledge/application/skill_generation_service_test.dart test/features/knowledge/application/deviation_detection_service_test.dart test/features/templates/application/template_completion_service_test.dart` | ✅ | ✅ green |
| 12-02-02 | 02 | 2 | AUDIT-03 | T-12-05 | WritingStatsPage renders stats content inside ProviderScope and token summary provider boundary does not crash | widget | `flutter test test/features/stats/presentation/writing_stats_page_test.dart` | ✅ | ✅ green |
| 12-03-01 | 03 | 2 | AUDIT-03 | T-12-08 | Three chart widgets render empty/data states and aggregate token audit records | widget | `flutter test test/features/stats/presentation/charts/operation_type_pie_chart_test.dart test/features/stats/presentation/charts/chapter_token_bar_chart_test.dart test/features/stats/presentation/charts/token_trend_line_chart_test.dart` | ✅ | ✅ green |
| 12-03-02 | 03 | 2 | AUDIT-03 | T-12-08 | TokenAuditPage renders AppBar, summary cards, chart sections, loading/error/empty/data states | widget | `flutter test test/features/stats/presentation/token_audit_page_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ partial/flaky*

---

## Wave 0 Requirements

Existing infrastructure now covers all Phase 12 requirements, including all AI call-site token audit paths.

- [x] `test/features/stats/domain/token_audit_record_test.dart` — AUDIT-01 entity behavior
- [x] `test/features/stats/domain/audit_operation_type_test.dart` — AUDIT-01 operation taxonomy
- [x] `test/features/stats/infrastructure/token_audit_repository_test.dart` — AUDIT-02 persistence/cleanup
- [x] `test/features/stats/application/token_audit_service_test.dart` — AUDIT-01/AUDIT-02 audit record creation and flush behavior
- [x] `test/features/stats/application/token_audit_notifier_test.dart` — AUDIT-03 aggregation state
- [x] `test/features/ai/infrastructure/openai_adapter_test.dart` — OpenAIAdapter usage callback behavior
- [x] `test/features/ai/presentation/synthesis_notifier_test.dart --name "token audit"` — synthesis call-site record/no-record behavior
- [x] `test/features/stats/presentation/writing_stats_page_test.dart` — WritingStatsPage token summary boundary
- [x] `test/features/stats/presentation/token_audit_page_test.dart` — TokenAuditPage data/chart/AppBar behavior
- [x] `test/features/editor/application/editor_ai_notifier_test.dart` — EditorAINotifier audit callback behavior
- [x] `test/features/onboarding/application/opening_generator_service_test.dart` — opening generation audit callback behavior
- [x] `test/features/knowledge/application/skill_generation_service_test.dart` — skill generation audit callback behavior
- [x] `test/features/knowledge/application/deviation_detection_service_test.dart` — deviation detection audit callback behavior
- [x] `test/features/templates/application/template_completion_service_test.dart` — template completion audit callback behavior

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full visual chart appearance and route navigation polish | AUDIT-03 | Golden/route-level UI verification not added in this Nyquist pass; widget behavior is automated | Run app, navigate to `/stats/tokens`, verify charts are visually legible and WritingStatsPage Token 消耗 button navigates correctly |

---

## Nyquist Audit Trail

| Gap | Action | Command | Result |
|-----|--------|---------|--------|
| 1 | Fixed TokenAuditPage chart-section test to scroll to offscreen chart sections before asserting widgets | `flutter test test/features/stats/presentation/token_audit_page_test.dart test/features/stats/presentation/writing_stats_page_test.dart test/features/ai/infrastructure/openai_adapter_test.dart test/features/ai/presentation/synthesis_notifier_test.dart --name "token audit\|TokenAuditPage\|writing stats\|OpenAIAdapter"` | green |
| 2 | Fixed TokenAuditPage AppBar test to use TokenAuditPage directly and scope title lookup to AppBar | same as above | green |
| 3 | Wrapped WritingStatsPage debug harness in ProviderScope to satisfy `_TokenSummarySection` provider boundary | same as above | green |
| 4 | Added synthesis call-site audit tests for successful stream record and stream-error no-record behavior | same as above | green |
| 5 | Added OpenAIAdapter onUsage accumulator callback behavioral coverage without external network | same as above | green |
| 6 | Updated stale draft/W0 pending map to focused-command map with partial coverage caveat | N/A | complete |
| 7 | Added audit callback tests for EditorAINotifier, OpeningGeneratorService, SkillGenerationService, DeviationDetectionService, and TemplateCompletionService | `flutter test test/features/editor/application/editor_ai_notifier_test.dart test/features/onboarding/application/opening_generator_service_test.dart test/features/knowledge/application/skill_generation_service_test.dart test/features/knowledge/application/deviation_detection_service_test.dart test/features/templates/application/template_completion_service_test.dart` | green |

### Validation Audit 2026-06-08

| Metric | Count |
|--------|-------|
| Gaps found | 7 |
| Resolved | 7 |
| Escalated/manual-only | 0 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency covered by focused commands
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated — all Phase 12 requirements have automated verification
