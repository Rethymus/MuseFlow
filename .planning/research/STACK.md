# Testing Stack Additions for v1.3 Validation

**Project:** MuseFlow v1.3 -- User-perspective full-flow validation
**Researched:** 2026-06-06
**Flutter version (local):** 3.44.0 stable / Dart 3.12.0
**Scope:** ONLY new testing dependencies needed for Flutter integration tests and pure Dart automation scripts. Existing app stack (super_editor, Riverpod, Hive CE, AI SDKs) is validated and out of scope.

---

## Overview

The v1.3 milestone validates the complete user flow by writing a 100-chapter xianxia novel through MuseFlow. This requires two new testing capabilities on top of the existing 930+ unit/widget tests:

1. **Flutter integration tests** -- full user-journey tests that pump the real app and exercise multi-screen flows (manuscript creation -> AI generation -> export)
2. **Pure Dart automation scripts** -- standalone scripts for token audit reporting, export verification, and batch test orchestration

The existing test infrastructure (flutter_test, integration_test SDK, hand-rolled fakes) is solid. The scope of additions is intentionally minimal.

---

## Existing Testing Infrastructure (DO NOT add, already present)

| What | Status | Notes |
|------|--------|-------|
| `flutter_test` SDK | In dev_dependencies | 930+ passing unit/widget tests across 117 files |
| `integration_test` SDK | In dev_dependencies | 5 basic smoke tests exist in `integration_test/app_test.dart` |
| `build_runner` | In dev_dependencies | Runs freezed/riverpod code generation |
| `hive_test_helper.dart` | In `test/helpers/` | Hive temp-dir setup/teardown for unit tests |
| Manual `Fake` subclasses | In test files | `_FakeOpenAIAdapter`, `MockFragmentRepository` -- hand-rolled, no mocking library |
| `mockito` (transitive) | In pubspec.lock via build_runner | NOT directly used by project tests |
| `test` package (transitive) | In pubspec.lock | Available for pure Dart test scripts |
| `args` package (transitive) | In pubspec.lock | Available for CLI arg parsing in automation scripts |
| `path` package (transitive) | In pubspec.lock | Available for cross-platform path handling |
| `IntegrationTestWidgetsFlutterBinding` | Already used in app_test.dart | Integration test entry point, confirmed working on Windows |

---

## Recommended New Additions

### 1. mocktail ^1.0.4 -- Mocking Library for Integration Test Provider Overrides

| Field | Value |
|-------|-------|
| Package | `mocktail` |
| Version | ^1.0.4 |
| Type | dev_dependency |
| Publisher | felangel.dev (verified) |
| License | MIT |
| Downloads | 2.15M+ |
| Confidence | HIGH -- verified on pub.dev + Context7 API docs |

**Why this and not alternatives:**

The project currently hand-rolls `Fake` subclasses (e.g., `_FakeOpenAIAdapter extends OpenAIAdapter`) for every test that needs mock AI providers. This pattern works for simple unit tests but has three specific limitations that matter for v1.3 integration tests:

1. **Cannot verify call counts or arguments.** The token audit tests need to verify that the AI adapter received correct prompt messages with the right token budgets. `mocktail` provides `verify(() => adapter.createStream(captureAny())).called(n)` which hand-rolled fakes cannot do.

2. **Cannot stub different returns per invocation.** A 100-chapter flow test needs the AI adapter to return different chapter content on each call. With fakes, you manage a `List<String>` and pop elements. With `mocktail`, `when(() => adapter.createStream(any())).thenAnswer((_) => Stream.fromIterable(['chapter text']))` handles this cleanly.

3. **Cannot share mock setup across test files.** Currently each test file defines its own fake class. Integration test flows spanning 5+ test files need a shared mock setup in `integration_test/helpers/ai_mocks.dart`.

**Why mocktail over mockito:** The project already has `mockito` as a transitive dependency (from build_runner), but mockito requires `@GenerateMocks` annotations and a `build_runner` step for every mock class. `mocktail` generates mocks at runtime with zero codegen. Since integration tests change frequently during validation (new flows, new assertions), avoiding a build_runner cycle per mock change saves significant iteration time.

**When to use:**
- Integration tests exercising the AI pipeline with controlled responses
- Tests that need `verify()` to assert on prompt message content or call frequency
- Token audit tests that count how many AI calls happen per chapter

**When NOT to use:**
- Existing unit tests with working hand-rolled fakes -- do not migrate, leave them alone
- Simple value objects -- use freezed classes directly
- Tests that do not need call verification

### 2. No Additional Packages for Integration Tests

The `integration_test` SDK shipped with Flutter 3.44.0 provides everything needed for the v1.3 integration tests. The binding already supports:

- `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` -- test entry point
- `tester.pumpWidget()` / `tester.pumpAndSettle()` -- widget lifecycle
- `tester.tap()` / `tester.enterText()` -- user interaction simulation
- `binding.traceAction()` -- performance timeline capture for slow operations
- `flutter test integration_test/` -- runs on Windows desktop with device selection

Here is the rationale for rejecting each candidate:

| Candidate | Why NOT |
|-----------|---------|
| **patrol** | No Windows desktop support. Patrol targets Android/iOS/Web only. MuseFlow's primary platform is Windows desktop. Verified via Context7 Patrol docs and pub.dev -- platform support matrix lists Android, iOS, Web. Windows/Linux are absent. Adding patrol would provide zero benefit for the target platform. |
| **flutter_driver** | Deprecated since Flutter 2.x. `integration_test` is the official replacement. The Flutter docs explicitly state to migrate away from flutter_driver. |
| **appium_flutter** | Mobile-focused automation framework. Adds native binary dependencies (Node.js, Appium server). Overkill for a desktop-first app doing validation testing. |
| **golden_toolkit / alchemist** | Screenshot/pixel comparison tools. Useful for visual regression, but v1.3 validation is about data correctness (export formats, token counts, story structure integrity), not pixel-perfect UI matching. |
| **flutter_gherkin / bdd_widget_test** | BDD syntax wrappers around testWidgets. Adds an abstraction layer that provides no value for a 2-developer team writing direct integration tests. Descriptive test names serve the same documentation purpose. |

### 3. Pure Dart Automation Scripts -- No New Dependencies Needed

The v1.3 milestone requires standalone Dart scripts for:
- Token consumption audit across the full 100-chapter flow
- Export file validation (Markdown/TXT/JSON format correctness)
- Batch test orchestration and report generation

All necessary tools are already available without new packages:

| Tool | Purpose | Already Available |
|------|---------|-------------------|
| `dart:io` Process.run() | Run `flutter test` from automation scripts | Yes (Dart SDK) |
| `dart:io` File/Directory | Read/write test artifacts, export files, reports | Yes (Dart SDK) |
| `dart:convert` JSON | Parse test output, validate export formats | Yes (Dart SDK) |
| `package:test` | Test runner for pure Dart test scripts | Yes (transitive via flutter_test) |
| `package:args` | CLI argument parsing for automation scripts | Yes (transitive) |
| `package:hive_ce` | Direct database reads for token audit data | Yes (main dependency) |
| `package:path` | Cross-platform path handling | Yes (transitive) |
| `package:logger` | Structured logging in automation output | Yes (main dependency) |

**Why no `process_run`:** The `process_run` package (v1.2.4 on pub.dev) provides a shell abstraction (`Shell().run('echo hello')`), but for the 3-4 automation scripts in v1.3, `dart:io` `Process.run()` with direct argument lists is sufficient and avoids an extra dependency. `process_run` would be worth reconsidering if the automation suite grows to 10+ scripts with complex shell piping.

**Why no `shelf`/`http` mock server:** Mocking AI endpoints with a local HTTP server (e.g., `shelf`) would be architecturally clean for test isolation, but v1.3 validation intentionally uses real AI API calls -- that is the point of user-perspective validation. For tests that must avoid network calls, Riverpod provider overrides with mocktail mocks are the correct approach (and consistent with the existing test pattern).

---

## What NOT to Add

| Package | Why NOT | What to Do Instead |
|---------|---------|-------------------|
| **patrol** | No Windows desktop support (Android/iOS/Web only). Verified via pub.dev and official docs. | Built-in `integration_test` SDK |
| **mockito** | Requires `@GenerateMocks` + build_runner cycle per mock class. Slows iteration on frequently-changing integration tests. | mocktail (zero codegen, same API style) |
| **process_run** | `dart:io` Process.run() sufficient for 3-4 scripts | `dart:io` Process.run() with argument lists |
| **shelf / http** | Mock HTTP server unnecessary; v1.3 needs real AI API calls for validation. Test isolation via Riverpod overrides. | Riverpod provider overrides + mocktail |
| **golden_toolkit / alchemist** | Visual regression testing not needed for flow/data validation | Text-based assertions on widget content |
| **bloc_test** | Project uses Riverpod, not Bloc | Riverpod ProviderContainer for test scoping |
| **flutter_gherkin / bdd_widget_test** | BDD abstraction adds no value for 2-developer team | Standard testWidgets with descriptive names |
| **test_cov_console / coverage** | Coverage reporting is a future concern, not a v1.3 validation need | `flutter test --coverage` if needed later |

---

## Installation

```bash
# Single new package
dart pub add --dev mocktail:^1.0.4
```

No other installations required. Everything else is already present via the Flutter SDK or existing transitive dependencies.

---

## Integration Test File Structure Recommendation

```
integration_test/
  app_test.dart                      # EXISTING -- keep, basic smoke tests
  helpers/
    test_app.dart                    # Shared pumpApp + Hive init (extracted from app_test.dart)
    ai_mocks.dart                    # mocktail-based AI adapter mocks for all providers
    token_tracker.dart               # Token consumption tracker used by audit tests
  flows/
    manuscript_lifecycle_test.dart   # Create manuscript -> add chapters -> edit -> export
    capture_synthesis_test.dart      # Fragment capture -> AI synthesis -> insert into editor
    chapter_management_test.dart     # 100-chapter CRUD + reorder/split/merge stress test
    story_structure_test.dart        # Foreshadowing setup -> track -> resolve -> logic loop check
    export_validation_test.dart      # Markdown/TXT/JSON three-format correctness
    ai_editor_tools_test.dart        # Floating toolbar: tone rewrite, paragraph polish, free edit
    token_audit_test.dart            # Full-flow token consumption measurement and reporting

tool/
  token_audit_report.dart            # Standalone: run flows, aggregate token stats, output report
  export_verifier.dart               # Standalone: validate exported files match expected format
  run_validation.dart                # CLI runner: execute all validation + generate summary report
```

**Rationale for structure:**
- `helpers/` centralizes the Hive initialization and adapter registration boilerplate currently duplicated in `app_test.dart` (lines 11-41). Every integration test needs this -- extract it once.
- `helpers/ai_mocks.dart` provides `MockOpenAIAdapter`, `MockAnthropicAdapter`, `MockOllamaAdapter` as mocktail-based mocks that any flow test can import and configure.
- `helpers/token_tracker.dart` wraps a simple `int totalTokens` counter that tests inject via Riverpod override to accumulate token usage across the full flow.
- `flows/` groups tests by user journey, directly matching the v1.3 "user perspective" requirement. Each file is one complete user story.
- `tool/` holds standalone scripts runnable via `dart run tool/<script>.dart`. These are NOT Flutter tests -- they are Dart CLI programs that orchestrate test runs, read results, and generate reports.
- Existing `test/helpers/hive_test_helper.dart` stays for unit tests. Integration test helpers live in `integration_test/helpers/` to keep concerns separated.

---

## How Integration Tests Fit With Existing Patterns

### Existing pattern (unit tests with ProviderContainer):

```dart
// Current pattern from synthesis_notifier_test.dart
late ProviderContainer container;
late _FakeOpenAIAdapter fakeAdapter;

ProviderContainer createContainer({...}) {
  fakeAdapter = _FakeOpenAIAdapter();
  return ProviderContainer(overrides: [
    openaiAdapterProvider.overrideWithValue(fakeAdapter),
    ...
  ]);
}
```

### New pattern (integration tests with WidgetTester + mocktail):

```dart
// New pattern for integration flow tests
Future<void> pumpAppWithMocks(WidgetTester tester, {
  Stream<String>? aiStreamOutput,
}) async {
  final mockAdapter = MockOpenAIAdapter();
  if (aiStreamOutput != null) {
    when(() => mockAdapter.createStream(
      apiKey: any(named: 'apiKey'),
      baseUrl: any(named: 'baseUrl'),
      model: any(named: 'model'),
      messages: any(named: 'messages'),
    )).thenAnswer((_) => aiStreamOutput);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        openaiAdapterProvider.overrideWithValue(mockAdapter),
      ],
      child: const MuseFlowApp(),
    ),
  );
  await tester.pumpAndSettle();
}
```

The key difference: unit tests use `ProviderContainer` (no widget tree), integration tests use `tester.pumpWidget(ProviderScope(...))` (full widget tree). Both use Riverpod overrides, but the integration test exercises the real UI navigation and state propagation.

### Token tracking pattern:

```dart
// TokenTracker injected via Riverpod override
class TokenTracker {
  int totalTokens = 0;
  int callCount = 0;
  void record(int tokens) { totalTokens += tokens; callCount++; }
}

// In test, wrap the mock adapter to track tokens
when(() => mockAdapter.createStream(...)).thenAnswer((invocation) {
  tracker.callCount++;
  return Stream.fromIterable(['generated text']);
});
```

This approach does not require any new package -- it is a plain Dart class that integration tests inject via Riverpod overrides alongside the mock adapters.

---

## Sources

| Source | Confidence | What It Verified |
|--------|------------|------------------|
| pub.dev/mocktail (live) | HIGH | Version 1.0.4 current, 1.2k likes, 2.15M downloads, MIT license, zero codegen, verified publisher felangel.dev |
| Context7 / Flutter integration_test docs | HIGH | `flutter test integration_test/` works on Windows desktop; `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` is the entry point; `traceAction()` for performance profiling |
| Context7 / Patrol docs | HIGH | Patrol supports Android/iOS/Web only; no Windows desktop support confirmed in platform matrix |
| Context7 / mocktail docs | HIGH | `when()`/`verify()`/`any(named:)`/`registerFallbackValue` API confirmed; zero codegen usage pattern |
| Flutter 3.44.0 installed locally | HIGH | `flutter test integration_test/` confirmed working for Windows target; Dart 3.12.0 stable |
| pub.dev/process_run (live) | HIGH | v1.2.4, 337 likes, BSD-2-Clause -- viable but unnecessary for small script count |
| Project codebase analysis (pubspec.yaml + lock) | HIGH | 117 test files, 930+ passing tests, hand-rolled fakes pattern, no direct mocking library, transitive deps available |
| Flutter docs -- Windows integration test output | HIGH | `flutter test integration_test/app_test.dart` on Windows prompts device selection, builds exe, runs tests |
