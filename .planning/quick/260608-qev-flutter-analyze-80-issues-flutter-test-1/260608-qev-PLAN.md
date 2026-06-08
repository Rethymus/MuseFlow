---
phase: quick-260608-qev-flutter-analyze-80-issues-flutter-test-1
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/ai/infrastructure/openai_adapter.dart
  - test/features/ai/infrastructure/model_list_fetch_test.dart
  - "analyzer-reported files as needed"
autonomous: true
requirements:
  - QEV-TEST-01
  - QEV-ANALYZE-01
must_haves:
  truths:
    - "flutter test no longer fails in OpenAIAdapter.fetchModelList invalid-baseUrl fallback coverage"
    - "flutter analyze reports zero issues after warning/info cleanup"
    - "OpenAI model-list provider failures remain silent fallbacks so users can manually type model IDs"
  artifacts:
    - path: "lib/features/ai/infrastructure/openai_adapter.dart"
      provides: "OpenAIAdapter.fetchModelList error-fallback behavior"
      contains: "Future<List<String>> fetchModelList"
    - path: "test/features/ai/infrastructure/model_list_fetch_test.dart"
      provides: "Regression coverage for silent model-list fallback"
      contains: "should return a list type when provider fetch fails"
  key_links:
    - from: "test/features/ai/infrastructure/model_list_fetch_test.dart"
      to: "lib/features/ai/infrastructure/openai_adapter.dart"
      via: "OpenAIAdapter.fetchModelList(apiKey, baseUrl)"
      pattern: "fetchModelList"
    - from: "flutter analyze"
      to: "all modified Dart files"
      via: "Dart analyzer/lints"
      pattern: "No issues found"
---

<objective>
Fix the current branch health check failures with the smallest safe changes.

Purpose: restore a green Flutter health check before progress is recorded.
Output: one passing model-list regression path, zero analyzer issues, and a full green `flutter test` run.

Observed failure evidence to preserve in executor context:
- `flutter analyze` failed with 80 issues.
- `flutter test` had only 1 failure: `test/features/ai/infrastructure/model_list_fetch_test.dart`, test `OpenAIAdapter.fetchModelList should return a list type when provider fetch fails`.
- Root clue: `lib/features/ai/infrastructure/openai_adapter.dart` `fetchModelList` calls `_validateBaseUrl` before `try/catch`, causing invalid `baseUrl` to throw `AIStreamException` instead of silently returning `[]`.
</objective>

<execution_context>
@/home/re/code/MuseFlow/.claude/get-shit-done/workflows/execute-plan.md
@/home/re/code/MuseFlow/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/lib/features/ai/infrastructure/openai_adapter.dart
@/home/re/code/MuseFlow/test/features/ai/infrastructure/model_list_fetch_test.dart

<interfaces>
From `lib/features/ai/infrastructure/openai_adapter.dart`:
- `class OpenAIAdapter implements AIAdapter`
- `Future<List<String>> fetchModelList({required String apiKey, required String baseUrl})`
- `void _validateBaseUrl(String baseUrl)` throws `AIStreamException` when URL is not HTTPS and not localhost.
- `createStream(...)` should continue validating baseUrl before creating/caching streaming clients; do not weaken streaming HTTPS enforcement.

From `test/features/ai/infrastructure/model_list_fetch_test.dart`:
- The invalid `baseUrl: 'not-a-valid-url'` case expects `List<String>` and `isEmpty`.
- The unreachable localhost case expects `isEmpty`.
- Empty API key expects `isEmpty`.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Restore fetchModelList silent fallback for invalid provider URLs</name>
  <files>/home/re/code/MuseFlow/lib/features/ai/infrastructure/openai_adapter.dart, /home/re/code/MuseFlow/test/features/ai/infrastructure/model_list_fetch_test.dart</files>
  <behavior>
    - Test 1: `fetchModelList(apiKey: 'test-key', baseUrl: 'not-a-valid-url')` returns an empty `List<String>` instead of throwing.
    - Test 2: `fetchModelList(apiKey: 'invalid-key', baseUrl: 'http://127.0.0.1:1/v1')` returns `[]` on connection failure.
    - Test 3: `fetchModelList(apiKey: '', baseUrl: 'https://api.openai.com/v1')` returns `[]` without network access.
    - Regression guard: `createStream` must still reject non-HTTPS non-localhost base URLs; do not move or remove its validation.
  </behavior>
  <action>Fix `OpenAIAdapter.fetchModelList` so every provider fetch failure, including invalid/non-HTTPS/non-localhost `baseUrl`, is caught and converted to `[]` per the existing D-08 comment. Keep the security posture for `createStream`: `_validateBaseUrl` should still run before stream client creation. Prefer wrapping validation and temporary `OpenAIClient` creation in the existing `try` path, while ensuring `client.close()` is only called when a client was actually created. Do not add live network dependencies to tests.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && flutter test test/features/ai/infrastructure/model_list_fetch_test.dart -r expanded</automated>
  </verify>
  <done>The model-list test file passes, and the invalid baseUrl case returns an empty list without throwing `AIStreamException`.</done>
</task>

<task type="auto">
  <name>Task 2: Clear analyzer warnings and infos without changing product behavior</name>
  <files>/home/re/code/MuseFlow/lib/**/*.dart, /home/re/code/MuseFlow/test/**/*.dart</files>
  <action>Run `flutter analyze`, inspect the 80 reported issues, and fix them in focused batches. Apply Dart/Flutter lint-safe changes only: remove unused imports/declarations, add missing `const`, correct deprecated/member access patterns, replace `print` with `debugPrint` if encountered, and keep Clean Architecture dependencies intact. Do not introduce new packages. Do not suppress lints with ignore comments unless an issue is demonstrably a false positive and a local explanation is necessary. After each batch that touches several files, rerun a targeted analyzer command or full `flutter analyze` until the output is clean.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && flutter analyze</automated>
  </verify>
  <done>`flutter analyze` exits 0 with no issues, and fixes do not alter user-facing AI/editor behavior beyond lint-compatible cleanup.</done>
</task>

<task type="auto">
  <name>Task 3: Run full health check and produce quick-task summary</name>
  <files>/home/re/code/MuseFlow/.planning/quick/260608-qev-flutter-analyze-80-issues-flutter-test-1/260608-qev-SUMMARY.md</files>
  <action>Run the full verification suite after the targeted fix and analyzer cleanup. If `flutter test` reveals new failures, only fix failures caused by this quick-task's changes; if unrelated pre-existing failures appear, document exact failing tests and stop for direction. Create the required GSD summary file with commands run, results, files changed, and any remaining risks. Do not run `/gsd:progress`; leave that for after the executor reports green status.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && flutter analyze && flutter test</automated>
  </verify>
  <done>`flutter analyze` and `flutter test` both exit 0, and `/home/re/code/MuseFlow/.planning/quick/260608-qev-flutter-analyze-80-issues-flutter-test-1/260608-qev-SUMMARY.md` exists with verification evidence.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| user/provider config → OpenAIAdapter.fetchModelList | Untrusted provider API key and baseUrl are used to discover model IDs. |
| user/provider config → OpenAIAdapter.createStream | Untrusted provider API key and baseUrl are used for streaming AI calls. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-QEV-01 | Information Disclosure | `OpenAIAdapter.createStream` | mitigate | Preserve `_validateBaseUrl` enforcement for streaming calls so API keys are not sent to non-HTTPS remote endpoints. |
| T-QEV-02 | Denial of Service | `OpenAIAdapter.fetchModelList` | mitigate | Keep the existing 5-second timeout and silent `[]` fallback so broken provider endpoints do not block settings/model entry flows. |
| T-QEV-03 | Spoofing/Tampering | analyzer cleanup | accept | No dependency installs or protocol changes are planned; cleanup is limited to existing Dart files and lint corrections. |
| T-QEV-SC | Tampering | package installs | mitigate | No npm/pip/cargo/pub package installation is permitted in this quick task. |
</threat_model>

<verification>
Required automated checks:
1. `cd /home/re/code/MuseFlow && flutter test test/features/ai/infrastructure/model_list_fetch_test.dart -r expanded`
2. `cd /home/re/code/MuseFlow && flutter analyze`
3. `cd /home/re/code/MuseFlow && flutter test`
</verification>

<success_criteria>
- `OpenAIAdapter.fetchModelList` silently returns `[]` for invalid baseUrl/provider failures.
- `OpenAIAdapter.createStream` still validates baseUrl before streaming.
- `flutter analyze` exits 0 with no issues.
- `flutter test` exits 0.
- Summary file is created at `/home/re/code/MuseFlow/.planning/quick/260608-qev-flutter-analyze-80-issues-flutter-test-1/260608-qev-SUMMARY.md`.
</success_criteria>

<source_audit>
## Multi-Source Coverage Audit

| Source | Item | Coverage |
|--------|------|----------|
| GOAL | Fix current branch health check failures | Covered by Tasks 1-3. |
| REQ QEV-TEST-01 | `flutter test` has only one observed failure in model-list fetch fallback | Covered by Task 1 and Task 3. |
| REQ QEV-ANALYZE-01 | `flutter analyze` has 80 issues to clear | Covered by Task 2 and Task 3. |
| RESEARCH | No research phase requested; existing stack uses Flutter/Dart/openai_dart | Covered by context and no dependency changes. |
| CONTEXT | Root clue: `_validateBaseUrl` runs before `try/catch` in `fetchModelList` | Covered by Task 1 action. |
</source_audit>

<output>
Create `/home/re/code/MuseFlow/.planning/quick/260608-qev-flutter-analyze-80-issues-flutter-test-1/260608-qev-SUMMARY.md` when done.
</output>
