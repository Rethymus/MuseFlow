---
phase: 00-technical-validation
plan: 02
subsystem: editor
tags: [ime, cjk, validation, spike, super_editor, appflowy_editor]
dependency_graph:
  requires: []
  provides: [ime_test_apps, ime_test_results, ime_scores]
  affects: [00-03]
tech_stack:
  added:
    - super_editor 0.3.0-dev.51
    - appflowy_editor 6.2.0 (incompatible)
    - window_manager 0.5.1
  patterns:
    - Editor composition lifecycle simulation
    - Separate Flutter apps per editor (dependency conflict avoidance)
key_files:
  created:
    - benchmark/ime_super_editor_app/pubspec.yaml
    - benchmark/ime_super_editor_app/lib/main.dart
    - benchmark/ime_super_editor_app/test/super_editor_ime_test.dart
    - benchmark/ime_appflowy_editor_app/pubspec.yaml
    - benchmark/ime_appflowy_editor_app/lib/main.dart
    - benchmark/ime_appflowy_editor_app/test/appflowy_editor_ime_test.dart
    - test/ime/super_editor_ime_test.dart
    - test/ime/appflowy_editor_ime_test.dart
    - benchmark/results/IME_VALIDATION.md
  modified: []
decisions:
  - super_editor 0.3.0-dev.51 resolves and passes all composition tests on Flutter 3.44.0/Dart 3.12.0
  - appflowy_editor 6.2.0 fails to compile on Flutter 3.44.0 due to TextInputClient.onFocusReceived incompatibility
  - IME test apps use separate Flutter projects per Pitfall 2 (editors cannot coexist in same pubspec)
  - Tests use direct document model manipulation (not widget tests) to verify composing lifecycle
metrics:
  duration: 21m
  completed: 2026-06-01
  tasks_completed: 2
  tasks_total: 3
  files_created: 9
  files_modified: 0
---

# Phase 0 Plan 02: CJK IME Validation Spike Summary

IME composition validation spike for both candidate editors: automated TextEditingDelta composition simulation confirms super_editor handles the composing-to-committed lifecycle correctly, while appflowy_editor 6.2.0 is incompatible with Flutter 3.44.0.

## Tasks Completed

| Task | Name | Commit | Key Files |
|---|---|---|---|
| 1 | Create IME test apps and automated composition tests | 657f97d | benchmark/ime_super_editor_app/*, benchmark/ime_appflowy_editor_app/*, test/ime/* |
| 2 | Run automated tests and prepare standalone IME validation report | 3de4ffa | benchmark/results/IME_VALIDATION.md |
| 3 | Checkpoint: human-verify | PENDING | Requires manual IME testing with physical keyboard |

## Key Findings

### super_editor (0.3.0-dev.51)
- All 4 automated composition tests PASS
- Pinyin composing, multi-character commit, cancellation, and mixed input all handled correctly
- Ready for manual IME testing (Sogou Pinyin, Wubi, Microsoft Pinyin)

### appflowy_editor (6.2.0)
- **CRITICAL: Does not compile on Flutter 3.44.0 / Dart 3.12.0**
- Root cause: `DeltaTextInputService` missing `TextInputClient.onFocusReceived()` implementation
- Same issue exists in the git main branch (checked commit 6fbe7ba)
- Manual IME testing BLOCKED until compatible version is released
- This may be a deciding factor in the editor selection (D-04)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] super_editor Editor constructor API changed**
- **Found during:** Task 1 test execution
- **Issue:** Plan's research documented `Editor(document: ..., composer: ...)` constructor, but super_editor 0.3.0-dev.51 uses `Editor(editables: {Editor.documentKey: ..., Editor.composerKey: ...})`
- **Fix:** Updated test to use correct `editables` map constructor pattern (found from super_editor's own quill parser code)
- **Files modified:** test/ime/super_editor_ime_test.dart
- **Commit:** 657f97d

**2. [Rule 3 - Blocking] Dart getter vs field type mismatch in test code**
- **Found during:** Task 1 test execution
- **Issue:** Using Dart getters (`String get firstNodeId`) as if they were fields caused type errors (`String Function()` instead of `String`)
- **Fix:** Replaced getters with inline expressions evaluated at point of use
- **Files modified:** test/ime/super_editor_ime_test.dart, test/ime/appflowy_editor_ime_test.dart
- **Commit:** 657f97d

**3. [Rule 1 - Bug] appflowy_editor test API mismatch**
- **Found during:** Task 1 test execution
- **Issue:** Used `transaction.commit()` (non-existent) instead of `editorState.apply(transaction)` and `document.plainText` (non-existent) instead of `node.delta.toPlainText()`
- **Fix:** Updated to use correct `EditorState.apply()` and `node.delta!.toPlainText()` APIs
- **Files modified:** test/ime/appflowy_editor_ime_test.dart
- **Commit:** 657f97d

### Critical Discovery

**4. appflowy_editor 6.2.0 incompatible with Flutter 3.44.0**
- **Found during:** Task 1 test execution
- **Issue:** Compilation fails with `DeltaTextInputService` missing `TextInputClient.onFocusReceived`
- **Impact:** Cannot run any appflowy_editor tests or manual IME testing
- **Resolution needed:** Wait for appflowy_editor release or downgrade Flutter
- **Documented in:** benchmark/results/IME_VALIDATION.md

## Known Stubs

| File | Line | Stub | Reason |
|---|---|---|---|
| benchmark/results/IME_VALIDATION.md | Section 4 | "PENDING MANUAL TESTING" scores | Manual IME testing requires physical keyboard on Windows |
| benchmark/ime_appflowy_editor_app/lib/main.dart | entire file | Cannot compile | Blocked by Flutter 3.44.0 incompatibility |

## Threat Flags

| Flag | File | Description |
|---|---|---|
| threat_flag: compatibility | benchmark/ime_appflowy_editor_app/pubspec.yaml | appflowy_editor 6.2.0 has unresolved Flutter SDK interface compatibility issue |

## Self-Check

- [x] All created files exist on disk
- [x] Commit 657f97d exists in git log
- [x] Commit 3de4ffa exists in git log
- [x] No unintended file deletions in any commit

## Self-Check: PASSED
