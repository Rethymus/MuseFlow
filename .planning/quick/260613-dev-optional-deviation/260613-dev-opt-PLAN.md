---
phase: quick
plan: 260613-dev-opt
type: tdd
wave: 1
depends_on: []
files_modified:
  - lib/core/infrastructure/settings_repository.dart
  - lib/core/presentation/providers.dart
  - lib/features/editor/application/editor_ai_notifier.dart
  - lib/features/settings/presentation/settings_page.dart
  - test/features/editor/application/editor_ai_notifier_test.dart
autonomous: true
requirements: [COST-TRANSPARENCY, CP-01]
tags: [ai, editor, deviation-detection, cost, settings, bugfix]

must_haves:
  truths:
    - "By default, completing an editor AI operation does NOT trigger a second deviation-detection LLM call (no silent 2x token cost)"
    - "A user-facing setting controls whether post-operation consistency checking runs; it is OFF by default"
    - "When the setting is ON, checkDeviations is invoked as before (behavior preserved for users who opt in)"
    - "All 1508 existing tests continue to pass after the change"
  artifacts:
    - path: "lib/core/infrastructure/settings_repository.dart"
      provides: "getAutoDeviationCheck() sync read (default false) + saveAutoDeviationCheck(bool) persist"
      contains: "auto_deviation_check"
    - path: "lib/core/presentation/providers.dart"
      provides: "autoDeviationCheckProvider NotifierProvider<bool> with set() that persists"
      contains: "autoDeviationCheckProvider"
    - path: "lib/features/editor/application/editor_ai_notifier.dart"
      provides: "Gate unawaited(checkDeviations) behind ref.read(autoDeviationCheckProvider)"
      contains: "autoDeviationCheckProvider"
    - path: "lib/features/settings/presentation/settings_page.dart"
      provides: "SwitchListTile for the opt-in toggle in the AI section"
      contains: "SwitchListTile"
    - path: "test/features/editor/application/editor_ai_notifier_test.dart"
      provides: "Regression: default=no deviation call; setting on=deviation call"
      contains: "autoDeviationCheckProvider"
  key_links:
    - from: "editor_ai_notifier _completeOperation (line ~287)"
      to: "deviationNotifierProvider.checkDeviations"
      via: "if (ref.read(autoDeviationCheckProvider)) unawaited(checkDeviations(...))"
      pattern: "autoDeviationCheckProvider"
---

<objective>
Eliminate the silent cost-doubling hidden inside editor AI operations. Today, every editor AI operation (tone/polish/free-input) ends with an unconditional `unawaited(checkDeviations(...))` at `editor_ai_notifier.dart:287`, which fires a FULL second LLM call (`deviation_detection_service.dart` createStream, audited as `deviationDetect`). This is invisible and uncontrollable to the user — editor AI operations consume ~2x the tokens shown in audit. That violates the README "成本透明" (cost transparency) promise and corresponds to v1.5 roadmap item CP-01 (P0).

Purpose: Make the post-operation consistency check OPT-IN (default OFF), so the default creation flow pays only for the single synthesis call. Users who want live skill-consistency warnings can enable it in Settings.

Output: A persisted boolean setting + provider, a gated call site, a Settings toggle, and TDD regression tests proving the default path triggers zero deviation calls.
</objective>

<context>
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/lib/features/editor/application/editor_ai_notifier.dart
@/home/re/code/MuseFlow/lib/core/infrastructure/settings_repository.dart
@/home/re/code/MuseFlow/lib/features/settings/presentation/settings_page.dart

<interfaces>
Established codebase patterns (confirmed by code audit):

1. SettingsRepository synchronous-get / async-set pattern (mirror getDefaultTag/setDefaultTag):
   - `String getDefaultTag() => _box.get(_defaultTagKey, defaultValue: ...) as String;`
   - `Future<void> setDefaultTag(String tag) async => await _box.put(_defaultTagKey, tag);`

2. Provider that reads the settings repo synchronously (mirror bannedPhrasesProvider / _getBannedPhrases):
   - `final settingsAsync = ref.read(settingsRepositoryProvider);`
   - `final settings = settingsAsync.value;  // null while loading -> safe default`
   - settingsRepositoryProvider is a FutureProvider<SettingsRepository> (providers.dart:103).

3. Editor notifier reads a setting provider via `ref.read(...)` (editor_ai_notifier.dart:531).

4. DeviationNotifier.checkDeviations(String text) (skill_notifier.dart:122) is an async void-returning method on deviationNotifierProvider.notifier. It early-returns when no active skills / empty text.

5. Test override pattern (editor_ai_notifier_test.dart): createContainer() uses provider.overrideWith(...) / overrideWithValue(...). deviationNotifierProvider can be overridden with a recording fake that stores the texts passed to checkDeviations.
</interfaces>
</context>

<tasks>

<task type="tdd" tdd="true">
  <name>Task 1 (RED): Add failing regression tests proving deviation check is gated by setting</name>
  <files>test/features/editor/application/editor_ai_notifier_test.dart</files>
  <behavior>
    - Test "does NOT trigger deviation check by default (no 2x cost)": run an editor AI operation to completion with the default container (autoDeviationCheckProvider absent/false) and a recording deviationNotifierProvider override; assert the fake's recorded checkDeviations calls list is EMPTY.
    - Test "triggers deviation check when setting is ON": same flow but with autoDeviationCheckProvider overridden to true; assert the fake recorded exactly one checkDeviations call with the processed text.
  </behavior>
  <action>
    RED — write the two failing tests FIRST. Add a recording fake DeviationNotifier (or override deviationNotifierProvider.overrideWith with a notifier subclass that appends each checkDeviations text to a list). In createContainer, accept an optional `bool? autoDeviationCheck` param; when non-null, add `autoDeviationCheckProvider.overrideWith(() => _StaticDeviationCheck(autoDeviationCheck))` (a Notifier subclass returning the bool). Always add the recording deviationNotifierProvider override so the assertion target exists. Run the tests — both FAIL because the current code calls checkDeviations unconditionally (default-off test fails: it sees a call). Commit: `test(deviation-opt): add failing regression for optional deviation check`.
    DO NOT add the provider or repo getter yet (they won't exist -> tests won't compile). Therefore Task 1 ALSO adds the minimal `autoDeviationCheckProvider` stub (returning false) + repo `getAutoDeviationCheck()` stub so the test compiles, but the GATE in editor_ai_notifier is still absent so the default-off test fails. This keeps RED honest while remaining compilable.
  </action>
  <verify>
    <automated>flutter test test/features/editor/application/editor_ai_notifier_test.dart --plain-name "deviation"</automated>
    Confirm: the default-off test FAILS (checkDeviations called despite no opt-in). The on-setting test may pass coincidentally; the default-off failure is the RED signal.
  </verify>
  <done>
    Two deviation-gating tests exist. Project compiles. Default-off test fails (RED). No existing test broken.
  </done>
</task>

<task type="tdd" tdd="true">
  <name>Task 2 (GREEN): Gate the call behind autoDeviationCheckProvider + add repo persistence + Settings toggle</name>
  <files>lib/core/infrastructure/settings_repository.dart, lib/core/presentation/providers.dart, lib/features/editor/application/editor_ai_notifier.dart, lib/features/settings/presentation/settings_page.dart</files>
  <behavior>
    - Both Task-1 tests now PASS (default=no call, opt-in=one call).
  </behavior>
  <action>
    GREEN —
    1. settings_repository.dart: add `bool getAutoDeviationCheck() => _box.get('auto_deviation_check', defaultValue: false) as bool;` and `Future<void> saveAutoDeviationCheck(bool v) async => await _box.put('auto_deviation_check', v);`. Add a `_autoDeviationCheckKey` constant for tidiness.
    2. providers.dart: define `final autoDeviationCheckProvider = NotifierProvider<AutoDeviationCheckNotifier, bool>(AutoDeviationCheckNotifier.new);` and the notifier class: build() returns `ref.watch(settingsRepositoryProvider).value?.getAutoDeviationCheck() ?? false`; `Future<void> set(bool v)` sets state and persists via `saveAutoDeviationCheck`.
    3. editor_ai_notifier.dart ~line 287: wrap the unawaited(checkDeviations(...)) block in `if (ref.read(autoDeviationCheckProvider)) { ... }`. Keep the existing catchError and comment, update the comment to note it is opt-in.
    4. settings_page.dart: add a `SwitchListTile` in the AI section ("AI 操作后自动一致性检查", subtitle explaining extra token cost) bound to `ref.watch(autoDeviationCheckProvider)` with onChanged `ref.read(autoDeviationCheckProvider.notifier).set(v)`. This requires the widget to be a ConsumerWidget (it already is) — SwitchListTile rebuilds via ref.watch on toggle.
    Run the deviation tests -> GREEN. Run full editor_ai_notifier_test.dart -> all pass. Commit: `fix(deviation-opt): make post-operation consistency check opt-in (default off)`.
  </action>
  <verify>
    <automated>flutter test test/features/editor/application/editor_ai_notifier_test.dart</automated>
    Confirm: all tests pass including the two deviation-gating tests.
  </verify>
  <done>
    Default editor AI operation triggers no second LLM call. Setting persisted and surfaced in Settings. Regression tests green.
  </done>
</task>

<task type="auto">
  <name>Task 3: Full regression — confirm 1508 tests still green + analyze clean</name>
  <files></files>
  <action>
    Run `flutter test` (full suite) and `flutter analyze` on the modified lib files. The gate only suppresses a fire-and-forget call in the default path; no existing test should depend on checkDeviations being auto-invoked (if any does, it encoded the hidden-cost behavior and must be updated to set the opt-in). Confirm analyze reports zero issues. If analyze flags the new public provider/notifier, keep them public (they are consumed cross-feature) — no @visibleForTesting needed.
  </action>
  <verify>
    <automated>flutter test</automated>
    <automated>flutter analyze lib/core/infrastructure/settings_repository.dart lib/core/presentation/providers.dart lib/features/editor/application/editor_ai_notifier.dart lib/features/settings/presentation/settings_page.dart</automated>
    Confirm: full suite green (1508 + 2 new = 1510); analyze clean.
  </verify>
  <done>
    Full `flutter test` passes; `flutter analyze` clean on touched files.
  </done>
</task>

</tasks>

<verification>
- `flutter test test/features/editor/application/editor_ai_notifier_test.dart` — deviation-gating group passes.
- `flutter test` — full suite green, no regression.
- `flutter analyze` on touched lib files — zero issues.
- Grep guard: `grep -n "unawaited" lib/features/editor/application/editor_ai_notifier.dart` shows the call now wrapped in `if (ref.read(autoDeviationCheckProvider))`.
</verification>

<success_criteria>
- Default editor AI operation issues zero deviation-detection LLM calls (no silent 2x cost).
- A persisted, user-facing "AI 操作后自动一致性检查" toggle exists (default OFF) and gates the call.
- Opt-in preserves prior behavior (checkDeviations runs when enabled).
- Behavioral regression test protects against reintroduction.
- All prior tests pass; flutter analyze clean.
</success_criteria>

<output>
Create `.planning/quick/260613-dev-optional-deviation/260613-dev-opt-SUMMARY.md` when done.
</output>
