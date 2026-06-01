---
phase: 1
slug: app-shell-editor-capture-ui
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-01
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK built-in) |
| **Config file** | none — uses pubspec.yaml flutter.test directory |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test --coverage`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | TECH-01 | — | N/A | widget | `flutter test test/app/window_management_test.dart` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | TECH-03 | T-1-01 | Hive encrypted box opens with cipher | unit | `flutter test test/infrastructure/hive_init_test.dart` | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 1 | TECH-04 | T-1-02 | API key write/read roundtrip via secure storage | unit | `flutter test test/infrastructure/secure_storage_test.dart` | ❌ W0 | ⬜ pending |
| 01-01-04 | 01 | 1 | TECH-06 | — | N/A | integration | Manual — measure startup time | N/A | ⬜ pending |
| 01-02-01 | 02 | 1 | EDIT-01 | — | N/A | widget | `flutter test test/features/editor/formatting_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | EDIT-04 | — | N/A | integration | Manual — 300K+ char document scroll test | N/A | ⬜ pending |
| 01-02-03 | 02 | 1 | TECH-02 | — | N/A | integration | Manual — IME composition test (validated Phase 0) | N/A | ⬜ pending |
| 01-03-01 | 03 | 2 | CAPT-01 | — | N/A | widget | `flutter test test/features/capture/fragment_input_test.dart` | ❌ W0 | ⬜ pending |
| 01-03-02 | 03 | 2 | CAPT-02 | — | N/A | unit | `flutter test test/features/capture/fragment_tag_test.dart` | ❌ W0 | ⬜ pending |
| 01-04-01 | 04 | 2 | CAPT-05 | — | N/A | widget | `flutter test test/features/capture/quick_capture_test.dart` | ❌ W0 | ⬜ pending |
| 01-04-02 | 04 | 2 | TECH-05 | — | N/A | widget | `flutter test test/app/navigation_test.dart` | ❌ W0 | ⬜ pending |
| 01-04-03 | 04 | 2 | TECH-07 | — | N/A | widget | `flutter test test/app/adaptive_layout_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/app/window_management_test.dart` — stubs for TECH-01
- [ ] `test/infrastructure/hive_init_test.dart` — stubs for TECH-03
- [ ] `test/infrastructure/secure_storage_test.dart` — stubs for TECH-04
- [ ] `test/app/navigation_test.dart` — stubs for TECH-05
- [ ] `test/features/editor/formatting_test.dart` — stubs for EDIT-01
- [ ] `test/features/capture/fragment_input_test.dart` — stubs for CAPT-01
- [ ] `test/features/capture/fragment_tag_test.dart` — stubs for CAPT-02
- [ ] `test/features/capture/quick_capture_test.dart` — stubs for CAPT-05
- [ ] `test/helpers/` — shared test fixtures (Hive test helpers, mock secure storage)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App launches in under 3 seconds | TECH-06 | Requires real device timing, not test environment | Launch app on Windows, measure time to editor visible |
| CJK IME composition works (Sogou/Wubi/MSPinyin) | TECH-02 | Requires real IME interaction, validated in Phase 0 | Open editor, type with each IME, verify composing text renders correctly |
| 300K+ character document scrolls at 60fps | EDIT-04 | Requires real rendering pipeline, validated in Phase 0 | Load large Chinese document, scroll through full content |
| Window size persists across restarts | TECH-01 | Requires app restart cycle | Resize window, close app, reopen, verify size restored |
| Quick-capture hotkey (Ctrl+Shift+N) works | CAPT-05 | Requires keyboard shortcut interaction | Press Ctrl+Shift+N from any screen, verify overlay appears |
| Android adaptive layout collapses sidebar | TECH-07 | Requires Android device or emulator | Run on Android emulator at various widths, verify sidebar collapses |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
