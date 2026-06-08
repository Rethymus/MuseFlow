---
phase: 260608-oxm-finalize-current-workspace-triage-verify
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/12-token-audit-infrastructure/12-VALIDATION.md
  - .planning/v1.3-MILESTONE-AUDIT.md
  - .planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md
autonomous: true
requirements:
  - AUDIT-01
  - AUDIT-02
  - AUDIT-03
must_haves:
  truths:
    - "Existing Phase 12 validation/test dirty changes are classified and verified from the main working tree before commit."
    - "The v1.3 milestone audit explicitly records that quick task 260608-obr fixed the `/stats/tokens` route to TokenAuditPage."
    - "Leftover `.claude/worktrees/agent-*` entries are inspected and reported as cleanup candidates only; none are deleted automatically."
    - "The quick task leaves a SUMMARY with verification results, commit hash if created, and cleanup recommendations."
  artifacts:
    - path: ".planning/phases/12-token-audit-infrastructure/12-VALIDATION.md"
      provides: "Updated Phase 12 validation record matching the verified test changes"
    - path: ".planning/v1.3-MILESTONE-AUDIT.md"
      provides: "Milestone audit entry noting quick task 260608-obr `/stats/tokens` fix"
    - path: ".planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md"
      provides: "Execution summary with test results, commit result, and worktree triage"
  key_links:
    - from: "Phase 12 dirty tests"
      to: ".planning/phases/12-token-audit-infrastructure/12-VALIDATION.md"
      via: "validation evidence update"
      pattern: "Phase 12|token audit|validation"
    - from: "quick task 260608-obr"
      to: ".planning/v1.3-MILESTONE-AUDIT.md"
      via: "milestone audit note"
      pattern: "260608-obr|/stats/tokens|TokenAuditPage"
    - from: "git status worktree entries"
      to: "260608-oxm-SUMMARY.md"
      via: "inspect-only cleanup report"
      pattern: "agent-"
---

<objective>
Finalize the current main workspace triage without losing existing uncommitted work: verify Phase 12 validation/test changes, commit them if green, refresh the v1.3 milestone audit for the already-completed `/stats/tokens` quick fix, and inspect leftover agent worktrees for safe cleanup candidates without deleting them.

Purpose: The working tree already contains Phase 12 validation test repairs, a new milestone audit file, and many agent worktree entries. This plan is intentionally for the main working tree, not a clean isolated worktree, because the goal is to classify, verify, and finalize those existing dirty changes.

Output: Focused verification results, an updated milestone audit, a commit for green Phase 12/audit changes if appropriate, and an execution summary listing cleanup candidates.
</objective>

<execution_context>
@/home/re/code/MuseFlow/.claude/get-shit-done/workflows/execute-plan.md
@/home/re/code/MuseFlow/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/.claude/rules/02-museflow-architecture.md
@/home/re/code/MuseFlow/.claude/rules/03-flutter-standards.md
@/home/re/code/MuseFlow/.claude/rules/04-workflow.md
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/.planning/PROJECT.md
@/home/re/code/MuseFlow/.planning/ROADMAP.md
@/home/re/code/MuseFlow/.planning/quick/260608-obr-fix-phase-12-token-audit-route-wire-stat/260608-obr-PLAN.md
@/home/re/code/MuseFlow/.planning/quick/260608-obr-fix-phase-12-token-audit-route-wire-stat/260608-obr-SUMMARY.md

<interfaces>
Current dirty tree context from planning discovery:
- Tracked Phase 12 validation/test files are modified:
  - `.planning/phases/12-token-audit-infrastructure/12-VALIDATION.md`
  - `test/features/ai/infrastructure/openai_adapter_test.dart`
  - `test/features/ai/presentation/synthesis_notifier_test.dart`
  - `test/features/editor/application/editor_ai_notifier_test.dart`
  - `test/features/knowledge/application/deviation_detection_service_test.dart`
  - `test/features/knowledge/application/skill_generation_service_test.dart`
  - `test/features/onboarding/application/opening_generator_service_test.dart`
  - `test/features/stats/presentation/token_audit_page_test.dart`
  - `test/features/stats/presentation/writing_stats_page_test.dart`
  - `test/features/templates/application/template_completion_service_test.dart`
- New milestone audit file exists as untracked: `.planning/v1.3-MILESTONE-AUDIT.md`.
- Multiple `.claude/worktrees/agent-*` paths appear as modified/untracked in `git status`; these are inspect/report-only in this plan.
- STATE.md says quick task `260608-obr` completed the Phase 12 token audit route fix: wire `/stats/tokens` to `TokenAuditPage` and add/repair route test.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Classify current dirty workspace and verify focused Phase 12 tests</name>
  <files>.planning/phases/12-token-audit-infrastructure/12-VALIDATION.md, test/features/ai/infrastructure/openai_adapter_test.dart, test/features/ai/presentation/synthesis_notifier_test.dart, test/features/editor/application/editor_ai_notifier_test.dart, test/features/knowledge/application/deviation_detection_service_test.dart, test/features/knowledge/application/skill_generation_service_test.dart, test/features/onboarding/application/opening_generator_service_test.dart, test/features/stats/presentation/token_audit_page_test.dart, test/features/stats/presentation/writing_stats_page_test.dart, test/features/templates/application/template_completion_service_test.dart</files>
  <action>Run on `/home/re/code/MuseFlow` main working tree, not the agent worktree. Inspect `git status --short` and `git diff --stat` to separate code/test/validation changes from `.claude/worktrees/agent-*` noise. Review the Phase 12 test diffs only enough to classify intent and catch accidental unrelated edits; do not rewrite the test strategy unless verification exposes a failure. Run focused Phase 12-related tests for every modified test file listed in this task. If focused tests pass, update `.planning/phases/12-token-audit-infrastructure/12-VALIDATION.md` so it accurately records the verified status and commands. If any focused test fails, stop before committing, preserve the dirty tree, and record the failing command/output in the summary.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && flutter test test/features/ai/infrastructure/openai_adapter_test.dart test/features/ai/presentation/synthesis_notifier_test.dart test/features/editor/application/editor_ai_notifier_test.dart test/features/knowledge/application/deviation_detection_service_test.dart test/features/knowledge/application/skill_generation_service_test.dart test/features/onboarding/application/opening_generator_service_test.dart test/features/stats/presentation/token_audit_page_test.dart test/features/stats/presentation/writing_stats_page_test.dart test/features/templates/application/template_completion_service_test.dart -x</automated>
  </verify>
  <done>Every modified Phase 12-focused test file has been run in one focused command, pass/fail is known, and `12-VALIDATION.md` matches the result.</done>
</task>

<task type="auto">
  <name>Task 2: Refresh v1.3 milestone audit and commit green validation changes</name>
  <files>.planning/v1.3-MILESTONE-AUDIT.md, .planning/phases/12-token-audit-infrastructure/12-VALIDATION.md, test/features/ai/infrastructure/openai_adapter_test.dart, test/features/ai/presentation/synthesis_notifier_test.dart, test/features/editor/application/editor_ai_notifier_test.dart, test/features/knowledge/application/deviation_detection_service_test.dart, test/features/knowledge/application/skill_generation_service_test.dart, test/features/onboarding/application/opening_generator_service_test.dart, test/features/stats/presentation/token_audit_page_test.dart, test/features/stats/presentation/writing_stats_page_test.dart, test/features/templates/application/template_completion_service_test.dart</files>
  <action>Update `.planning/v1.3-MILESTONE-AUDIT.md` to reflect that quick task `260608-obr` fixed `/stats/tokens` by wiring it to `TokenAuditPage` and adding/repairing route test coverage. Do not claim Phase 16 is complete. If Task 1 verification is green, stage only the Phase 12 validation/test files plus `.planning/v1.3-MILESTONE-AUDIT.md`; explicitly exclude `.claude/worktrees/agent-*` paths. Commit with a concise message such as `test(phase-12): finalize token audit validation repairs`. Include the required co-author trailer exactly: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. If tests are not green, do not commit; leave changes uncommitted for follow-up.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && grep -n "260608-obr\|/stats/tokens\|TokenAuditPage" .planning/v1.3-MILESTONE-AUDIT.md</automated>
    <automated>cd /home/re/code/MuseFlow && git status --short</automated>
  </verify>
  <done>The milestone audit records the `/stats/tokens` fix, green validation/test/audit changes are committed if eligible, and worktree agent paths remain unstaged/uncommitted.</done>
</task>

<task type="auto">
  <name>Task 3: Inspect leftover agent worktrees and write execution summary</name>
  <files>.planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md</files>
  <action>Inspect `.claude/worktrees/agent-*` entries shown in `git status` to identify cleanup candidates. Do not delete any worktree directory or git worktree registration in this plan. For each candidate, report whether it is untracked-only, modified tracked gitlink/file, contains a nested git worktree, has unique commits compared with `main`, or needs manual review. Use `git worktree list` and targeted `git -C <worktree> status --short` / `git -C <worktree> log --oneline main..HEAD` where applicable; if a path is not a valid git worktree, state that. Write `/home/re/code/MuseFlow/.planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md` with: focused test command/result, commit hash or reason no commit was made, milestone audit update note, current remaining dirty files, and inspect-only cleanup recommendations. Avoid saying cleanup was performed unless it actually was not; this plan is report-only for cleanup.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && test -f .planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md</automated>
    <automated>cd /home/re/code/MuseFlow && grep -n "focused test\|commit\|cleanup\|agent-" .planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md</automated>
  </verify>
  <done>The summary exists and contains verification results, commit outcome, milestone audit status, and non-destructive worktree cleanup candidates.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| dirty working tree → git commit | Existing uncommitted files may include unrelated agent worktree noise; only verified intended files should be staged. |
| validation tests → project status docs | Test results influence `12-VALIDATION.md` and milestone audit claims. |
| agent worktree directories → cleanup recommendations | Leftover directories may contain unique unmerged work; inspection must not destroy data. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-260608-OXM-01 | Tampering | git staging/commit | mitigate | Stage only explicit Phase 12 validation/test files and `.planning/v1.3-MILESTONE-AUDIT.md`; exclude `.claude/worktrees/agent-*`. |
| T-260608-OXM-02 | Repudiation | validation/audit documentation | mitigate | Record exact focused test command/result and commit hash or no-commit reason in SUMMARY. |
| T-260608-OXM-03 | Denial of Service | worktree cleanup | mitigate | Inspect/report cleanup candidates only; do not delete worktrees or prune registrations in this plan. |
| T-260608-OXM-SC | Tampering | package installs | accept | No package-manager install task is planned. |
</threat_model>

<verification>
Required focused verification:
- `cd /home/re/code/MuseFlow && flutter test test/features/ai/infrastructure/openai_adapter_test.dart test/features/ai/presentation/synthesis_notifier_test.dart test/features/editor/application/editor_ai_notifier_test.dart test/features/knowledge/application/deviation_detection_service_test.dart test/features/knowledge/application/skill_generation_service_test.dart test/features/onboarding/application/opening_generator_service_test.dart test/features/stats/presentation/token_audit_page_test.dart test/features/stats/presentation/writing_stats_page_test.dart test/features/templates/application/template_completion_service_test.dart -x`
- `cd /home/re/code/MuseFlow && grep -n "260608-obr\|/stats/tokens\|TokenAuditPage" .planning/v1.3-MILESTONE-AUDIT.md`
- `cd /home/re/code/MuseFlow && git status --short`
- `cd /home/re/code/MuseFlow && test -f .planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md`
</verification>

<success_criteria>
- Existing Phase 12 validation/test changes are verified from the main working tree.
- `.planning/v1.3-MILESTONE-AUDIT.md` records quick task `260608-obr` and the `/stats/tokens` TokenAuditPage route fix.
- If focused verification is green, intended Phase 12/audit changes are committed without staging `.claude/worktrees/agent-*` paths.
- If focused verification is red, no commit is made and failures are recorded.
- Agent worktrees are inspected and summarized as cleanup candidates only; no deletion is performed.
- `260608-oxm-SUMMARY.md` exists with verification results, commit outcome, remaining dirty state, and cleanup recommendations.
</success_criteria>

<source_audit>
## Multi-Source Coverage Audit

| Source | Item | Coverage |
|--------|------|----------|
| GOAL | Finalize current workspace triage: verify Phase 12 validation test changes, commit if green, refresh milestone audit, inspect leftover agent worktrees | Covered by Tasks 1, 2, and 3. |
| REQ | AUDIT-01/AUDIT-02/AUDIT-03 Phase 12 token audit validation evidence | Covered by Task 1 focused tests and validation doc update. |
| RESEARCH | No research artifact requested for this quick plan; no new libraries or external integrations | Excluded: discovery Level 0. |
| CONTEXT | Executor must run on main tree, not isolated worktree | Covered in objective and Task 1 action. |
| CONTEXT | Do not delete worktrees automatically; inspect/report only | Covered by Task 3 and threat T-260608-OXM-03. |
| CONTEXT | Include verification commands for focused Phase 12 test files | Covered by Task 1 verify and verification section. |
| CONTEXT | Update `.planning/v1.3-MILESTONE-AUDIT.md` to reflect `260608-obr` `/stats/tokens` fix | Covered by Task 2. |
| CONTEXT | Write summary at `.planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md` | Covered by Task 3. |
</source_audit>

<output>
Create `/home/re/code/MuseFlow/.planning/quick/260608-oxm-finalize-current-workspace-triage-verify/260608-oxm-SUMMARY.md` when done.
</output>
