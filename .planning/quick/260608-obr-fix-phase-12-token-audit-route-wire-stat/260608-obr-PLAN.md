---
phase: 260608-obr-fix-phase-12-token-audit-route-wire-stat
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/app.dart
  - test/app/token_audit_route_test.dart
autonomous: true
requirements:
  - AUDIT-03
must_haves:
  truths:
    - "User opening /stats/tokens sees the real Token 消耗总览 page, not a placeholder."
    - "WritingStatsPage actions and token summary navigation land on TokenAuditPage through AppConstants.statsTokens."
    - "A route-level widget test prevents regression of the /stats/tokens wiring."
  artifacts:
    - path: "lib/app.dart"
      provides: "GoRouter child route for /stats/tokens wired to TokenAuditPage"
      contains: "TokenAuditPage"
    - path: "test/app/token_audit_route_test.dart"
      provides: "Regression test for /stats/tokens route"
      contains: "AppConstants.statsTokens"
  key_links:
    - from: "lib/features/stats/presentation/writing_stats_page.dart"
      to: "lib/app.dart"
      via: "context.go(AppConstants.statsTokens)"
      pattern: "statsTokens"
    - from: "lib/app.dart"
      to: "lib/features/stats/presentation/token_audit_page.dart"
      via: "GoRoute(path: 'tokens') builder"
      pattern: "TokenAuditPage"
---

<objective>
Fix the Phase 12 token audit route regression so `/stats/tokens` opens the completed TokenAuditPage instead of the leftover placeholder.

Purpose: Phase 12 AUDIT-03 requires users to view token consumption totals and distributions from the statistics area. The UI page exists, and WritingStatsPage already navigates to `AppConstants.statsTokens`, but the app router still builds a placeholder for the `tokens` child route.

Output: Real route wiring plus a focused route regression test.
</objective>

<execution_context>
@/home/re/code/MuseFlow/.claude/get-shit-done/workflows/execute-plan.md
@/home/re/code/MuseFlow/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/.planning/ROADMAP.md
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/lib/app.dart
@/home/re/code/MuseFlow/lib/shared/constants/app_constants.dart
@/home/re/code/MuseFlow/lib/features/stats/presentation/writing_stats_page.dart
@/home/re/code/MuseFlow/lib/features/stats/presentation/token_audit_page.dart
@/home/re/code/MuseFlow/test/helpers/hive_test_helper.dart

<interfaces>
Existing route constants:
- `AppConstants.stats = '/stats'`
- `AppConstants.statsProject = '/stats/project'`
- `AppConstants.statsTokens = '/stats/tokens'`

Existing app route issue in `lib/app.dart`:
- Branch 4 has parent `GoRoute(path: AppConstants.stats, builder: WritingStatsPage)`.
- Child route `GoRoute(path: 'tokens')` currently builds `Scaffold(body: Center(child: Text('Token Audit Page - Coming in Plan 03')))`.
- Replace that child builder with the real `const TokenAuditPage()` and add the required import.

Existing page contract:
- `TokenAuditPage` is exported by `package:museflow/features/stats/presentation/token_audit_page.dart`.
- `TokenAuditPage` renders AppBar title text `Token 消耗总览` and empty-state text `开始使用 AI 功能后，这里会出现消耗统计。` when no token calls exist.

Existing Hive test helper:
- `setUpHiveTest()` initializes Hive with a temp directory.
- `tearDownHiveTest()` deletes Hive data from disk.
- The real app redirect reads `Hive.box('settings').get('onboarding_completed', defaultValue: false)`; tests that pump `MuseFlowApp` should open the `settings` box and set `onboarding_completed` to true before navigating.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add failing route regression test for /stats/tokens</name>
  <files>test/app/token_audit_route_test.dart</files>
  <behavior>
    - Test 1: When the app router navigates to `AppConstants.statsTokens`, the rendered page contains `Token 消耗总览` and does not contain `Token Audit Page - Coming in Plan 03`.
    - Test 2: The test setup marks onboarding complete so redirect logic does not send `/stats/tokens` to `/onboarding`.
  </behavior>
  <action>Create `test/app/token_audit_route_test.dart`. Use `ProviderScope(child: MuseFlowApp())` rather than a duplicate test router so the test exercises the production `lib/app.dart` GoRouter configuration. In `setUp`, call `setUpHiveTest()`, open the `settings` box, and put `onboarding_completed = true`. In `tearDown`, call `tearDownHiveTest()`. Pump the app, wait for routing to settle, then navigate to `AppConstants.statsTokens` using the production router access pattern available from `go_router` in widget tests, or by pumping with an initial route if already established in project tests. Assert the real token audit title is visible and the placeholder text is absent. This test should fail before Task 2 because `lib/app.dart` still builds the placeholder.</action>
  <verify>
    <automated>flutter test test/app/token_audit_route_test.dart -x</automated>
  </verify>
  <done>The new test fails for the current placeholder route and clearly names the expected real `/stats/tokens` behavior.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire /stats/tokens to TokenAuditPage</name>
  <files>lib/app.dart, test/app/token_audit_route_test.dart</files>
  <behavior>
    - Test 1: `/stats/tokens` renders `TokenAuditPage` content through production `MuseFlowApp` routing.
    - Test 2: Placeholder text `Token Audit Page - Coming in Plan 03` no longer appears in source or rendered UI.
  </behavior>
  <action>Modify `lib/app.dart`: import `package:museflow/features/stats/presentation/token_audit_page.dart`; in the stats branch child route with `path: 'tokens'`, replace the placeholder `Scaffold` builder with `builder: (context, state) => const TokenAuditPage()`. Do not change `AppConstants.statsTokens`, `WritingStatsPage`, or navigation labels unless the new test reveals a compile-only adjustment is required. Keep the route as the existing child route under `AppConstants.stats` so `/stats/tokens` remains compatible with existing `context.go(AppConstants.statsTokens)` calls.</action>
  <verify>
    <automated>flutter test test/app/token_audit_route_test.dart -x</automated>
    <automated>grep -R "Token Audit Page - Coming in Plan 03" -n /home/re/code/MuseFlow/lib /home/re/code/MuseFlow/test | grep -v '^#' ; test $? -eq 1</automated>
  </verify>
  <done>`/stats/tokens` opens `TokenAuditPage`, the route regression test passes, and the obsolete placeholder text is removed from app/test source.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| app navigation → route builder | In-app route strings select UI pages; no external input or privilege change occurs. |
| TokenAuditPage → tokenAuditNotifierProvider | Page reads local token audit data through Riverpod/Hive providers. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-260608-OBR-01 | Tampering | `lib/app.dart` route table | mitigate | Add production-router widget test that asserts `/stats/tokens` resolves to TokenAuditPage and not the placeholder. |
| T-260608-OBR-02 | Information Disclosure | `TokenAuditPage` | accept | Route exposes only local token usage data already intended for the stats page; no network or cross-user boundary is introduced. |
| T-260608-OBR-SC | Tampering | package installs | accept | No package-manager install task is planned. |
</threat_model>

<verification>
Run focused verification:
- `flutter test test/app/token_audit_route_test.dart -x`
- `grep -R "Token Audit Page - Coming in Plan 03" -n /home/re/code/MuseFlow/lib /home/re/code/MuseFlow/test | grep -v '^#' ; test $? -eq 1`

Optional if context remains: `flutter test test/features/stats/presentation/token_audit_page_test.dart test/features/stats/presentation/writing_stats_page_test.dart -x`.
</verification>

<success_criteria>
- `lib/app.dart` imports and builds `TokenAuditPage` for the `tokens` child route under `/stats`.
- `/stats/tokens` renders `Token 消耗总览` through the production app router.
- The stale placeholder text is absent from app and test source.
- The new regression test passes in under 60 seconds.
</success_criteria>

<source_audit>
## Multi-Source Coverage Audit

| Source | Item | Coverage |
|--------|------|----------|
| GOAL | Fix Phase 12 token audit route: wire `/stats/tokens` to TokenAuditPage and add/repair route test | Covered by Task 1 and Task 2. |
| REQ | AUDIT-03: 用户可以在写作统计页面查看 token 消耗总览：总成本、每章分布、按操作类型分布 | Covered by Task 2 route wiring to existing TokenAuditPage. |
| RESEARCH | No research phase requested for quick task | Excluded: no research artifact. |
| CONTEXT | Quick planning context explicitly names `/stats/tokens`, TokenAuditPage, route test | Covered by Task 1 and Task 2. |
</source_audit>

<output>
Create `/home/re/code/MuseFlow/.planning/quick/260608-obr-fix-phase-12-token-audit-route-wire-stat/260608-obr-SUMMARY.md` when done.
</output>
