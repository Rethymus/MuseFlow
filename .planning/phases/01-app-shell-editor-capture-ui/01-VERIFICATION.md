---
phase: 01-app-shell-editor-capture-ui
verified: 2026-06-01T15:45:00Z
status: gaps_found
score: 5/6 must-haves verified
overrides_applied: 0
gaps:
  - truth: "App launches with remembered window size (window size persisted across restarts)"
    status: failed
    reason: "SettingsRepository has saveWindowSize/getWindowSize methods but nothing calls them. AppShellScaffold does not implement WindowListener to save on resize/move. main.dart does not restore saved size on startup. Window always opens at hardcoded 1200x800 default."
    artifacts:
      - path: "lib/core/presentation/app_shell.dart"
        issue: "Does not implement WindowListener; never calls settingsRepository.saveWindowSize/saveWindowPosition"
      - path: "lib/main.dart"
        issue: "Does not read settingsRepository.getWindowSize() to restore saved window geometry before showing"
    missing:
      - "WindowListener mixin on AppShellScaffold that saves size/position on resize/move events via settingsRepositoryProvider"
      - "Window size restoration in main.dart: read saved size from settings before windowManager.waitUntilReadyToShow"
human_verification:
  - test: "Launch app on Windows with Chinese IME (Sogou/Wubi/Microsoft Pinyin), type text in editor"
    expected: "IME composition works correctly, underlined composing text appears, candidates window shows, committed text enters editor"
    why_human: "IME behavior is platform-dependent and cannot be verified by automated tests in headless environment"
  - test: "Launch app on Windows and measure time to interactive editor"
    expected: "App shows editor and is interactive within 3 seconds"
    why_human: "Startup performance must be measured on real hardware with release build"
  - test: "Paste a 300K+ character Chinese document into editor and scroll"
    expected: "Smooth scrolling at 60fps, no visible lag or jank"
    why_human: "Large document rendering performance requires real device testing; Phase 0 validated super_editor capability but real-world feel needs human confirmation"
---

# Phase 1: App Shell + Editor + Capture UI Verification Report

**Phase Goal:** Users can launch the app, navigate between modules, write in a rich text editor with Chinese IME, and capture/organize inspiration fragments
**Verified:** 2026-06-01T15:45:00Z
**Status:** gaps_found
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | App launches as native Windows desktop app with proper window management (title bar, minimize/maximize/close, remembered size) | PARTIAL | Title bar, min/max/close, centering at 1200x800 all work (main.dart:19-33). **Remembered size FAILED** -- SettingsRepository.saveWindowSize is never called, no WindowListener wired. |
| 2 | User can navigate between modules (capture, editor, settings) via the app shell | VERIFIED | StatefulShellRoute.indexedStack in app.dart with 3 branches. NavigationRail with Chinese labels in sidebar.dart. goBranch wired in app_shell.dart:32,50. |
| 3 | Rich text editor supports bold, italic, headings, lists and handles 300K+ character documents | VERIFIED | EditorToolbar with 6 controls (editor_toolbar.dart), ToggleTextAttributionsRequest/ReplaceNodeRequest wired (5 execute calls). SuperEditor with autofocus in editor_page.dart. Phase 0 validated 300K+ perf. |
| 4 | Sogou, Wubi, and Microsoft Pinyin input methods work correctly in the editor | VERIFIED (code) | super_editor handles IME natively via Flutter's platform channels. Editor page uses SuperEditor with standard text input. Phase 0 spike validated. Human verification needed for runtime confirmation. |
| 5 | User can create, edit, and organize fragments in bullet-note mode by story/chapter/scene | VERIFIED | CapturePage with TextField input (capture_page.dart:29-54), FilterChip row for tags (line 62-77), FragmentCard with checkbox (fragment_card.dart), FragmentService with CRUD+filtering (fragment_service.dart), Hive persistence via FragmentRepository. Full data flow confirmed. |
| 6 | Floating quick-capture window is accessible from any screen | VERIFIED | QuickCaptureShortcut wraps Scaffold in AppShellScaffold (app_shell.dart:26,43). Ctrl+Shift+N registered via LogicalKeySet (keyboard_shortcuts.dart:30-33). QuickCaptureDialog saves via captureProvider (quick_capture.dart:44). SnackBar confirmation (quick_capture.dart:49). |

**Score:** 5/6 truths fully verified (1 partial: window persistence)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/main.dart` | App entry with Hive init, window_manager, ProviderScope | VERIFIED (41 lines) | Hive.initFlutter, adapter registration, WindowManager with WindowOptions, ProviderScope wrapping MuseFlowApp |
| `lib/app.dart` | MuseFlowApp with go_router StatefulShellRoute | VERIFIED (71 lines) | StatefulShellRoute.indexedStack, initialLocation /editor, 3 branches |
| `lib/core/presentation/app_shell.dart` | AppShellScaffold with sidebar + content Row layout | VERIFIED (63 lines) | Adaptive layout with QuickCaptureShortcut wrapping Scaffold, Row/Column layout |
| `lib/core/presentation/sidebar.dart` | Adaptive NavigationRail sidebar | VERIFIED (112 lines) | 3 NavigationRailDestination with Chinese labels, extended/collapsed/bottom-nav modes |
| `lib/core/domain/fragment.dart` | Fragment entity with copyWith, toJson/fromJson, equality | VERIFIED (94 lines) | Manual immutable implementation with all fields, Hive-compatible |
| `lib/core/infrastructure/secure_storage_service.dart` | Secure storage wrapper for API key CRUD | VERIFIED (36 lines) | FlutterSecureStorage with saveApiKey/getApiKey/deleteApiKey |
| `lib/shared/constants/app_constants.dart` | Layout breakpoints, route paths, window defaults | VERIFIED (26 lines) | sidebarExtendedBreakpoint=1000, sidebarCollapsedBreakpoint=600, editorMaxWidth=800, routes |
| `lib/features/editor/presentation/editor_toolbar.dart` | Fixed formatting toolbar with 6 controls | VERIFIED (334 lines) | Bold, italic, H1/H2/H3, unordered/ordered list with ListenableBuilder reactivity |
| `lib/features/editor/presentation/editor_page.dart` | Editor page with toolbar + centered super_editor | VERIFIED (129 lines) | Column(EditorToolbar + Divider + Expanded(SuperEditor)), Ctrl+B/I shortcuts |
| `lib/features/editor/presentation/editor_provider.dart` | Editor state helper | VERIFIED (19 lines) | createDefaultEditor() function |
| `lib/features/capture/presentation/capture_page.dart` | Capture page with input, filter chips, fragment list | VERIFIED (172 lines) | TextField with onSubmitted, FilterChip row, ListView.builder, empty state |
| `lib/features/capture/presentation/fragment_card.dart` | Fragment card with checkbox, text, tags, timestamp | VERIFIED (115 lines) | Checkbox, text display, tag Chips, formatted timestamp |
| `lib/features/capture/presentation/capture_provider.dart` | Capture state management via Riverpod | VERIFIED (165 lines) | CaptureNotifier with CRUD, filtering, selection; 4 providers |
| `lib/features/capture/presentation/quick_capture.dart` | Quick-capture dialog with TextField + save/cancel | VERIFIED (92 lines) | AlertDialog with multiline TextField, save via captureProvider, SnackBar |
| `lib/core/application/fragment_service.dart` | Fragment CRUD use case | VERIFIED (65 lines) | createFragment, listFragments (sorted), listFragmentsByTag, removeFragment, updateFragmentTags |
| `lib/shared/utils/keyboard_shortcuts.dart` | Ctrl+Shift+N shortcut definition | VERIFIED (53 lines) | QuickCaptureIntent, QuickCaptureShortcut with Shortcuts/Actions |
| `lib/core/infrastructure/fragment_repository.dart` | Hive-backed Fragment CRUD | VERIFIED (50 lines) | UUID v4 IDs, Hive box put/get/delete, tag filtering |
| `lib/core/infrastructure/settings_repository.dart` | Window persistence over encrypted Hive | VERIFIED (57 lines) | saveWindowSize, getWindowSize, saveWindowPosition, getWindowPosition, defaultTag |
| `lib/core/presentation/providers.dart` | Riverpod providers for repos | VERIFIED (55 lines) | fragmentRepositoryProvider, settingsRepositoryProvider (encrypted), secureStorageServiceProvider |
| `lib/core/infrastructure/hive_adapters.dart` | Manual Hive TypeAdapters | VERIFIED (59 lines) | FragmentAdapter, AppSettingsAdapter delegating to toJson/fromJson |
| `lib/core/domain/fragment_tag.dart` | Default tag constants | VERIFIED (18 lines) | story, chapter, scene + defaults list |
| `lib/core/domain/app_settings.dart` | AppSettings entity | VERIFIED (77 lines) | Window geometry + defaultTag with copyWith |
| `lib/shared/theme/app_theme.dart` | Material 3 dark indigo theme | VERIFIED (25 lines) | ColorScheme.fromSeed(indigo, dark), Noto Sans SC |
| `lib/features/settings/presentation/settings_page.dart` | Settings placeholder | VERIFIED (61 lines) | ListView with section headers |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| lib/main.dart | lib/app.dart | import + runApp | WIRED | `import 'package:museflow/app.dart'` line 4, `MuseFlowApp()` passed to ProviderScope |
| lib/app.dart | lib/core/presentation/app_shell.dart | StatefulShellRoute builder | WIRED | `AppShellScaffold(navigationShell: navigationShell)` line 36 |
| lib/core/presentation/app_shell.dart | lib/core/presentation/sidebar.dart | AdaptiveSidebar in Row/Column | WIRED | 2 references: line 29 (bottom nav), line 47 (desktop sidebar) |
| lib/core/presentation/app_shell.dart | go_router | navigationShell.goBranch() | WIRED | line 32, 50 -- `goBranch(index, initialLocation:)` |
| lib/features/editor/presentation/editor_page.dart | lib/features/editor/presentation/editor_toolbar.dart | EditorToolbar widget in Column | WIRED | `EditorToolbar(editor: _editor)` line 93 |
| lib/features/editor/presentation/editor_toolbar.dart | super_editor | editor.execute() pipeline | WIRED | 5 calls to `widget.editor.execute([ToggleTextAttributionsRequest/ReplaceNodeRequest])` |
| lib/features/editor/presentation/editor_page.dart | super_editor | SuperEditor widget | WIRED | `SuperEditor(editor: _editor, autofocus: true)` line 105 |
| lib/features/capture/presentation/capture_page.dart | lib/features/capture/presentation/capture_provider.dart | ref.watch/ref.read captureProvider | WIRED | `ref.watch(captureProvider)` line 20, `ref.read(captureProvider.notifier).addFragment` line 47 |
| lib/features/capture/presentation/capture_provider.dart | lib/core/application/fragment_service.dart | FragmentService delegation | WIRED | `FragmentService(repository)` line 47, `_service` field line 52 |
| lib/core/application/fragment_service.dart | lib/core/infrastructure/fragment_repository.dart | repository CRUD calls | WIRED | `final FragmentRepository _repository` line 11, all methods delegate |
| lib/features/capture/presentation/capture_page.dart | lib/features/capture/presentation/fragment_card.dart | ListView.builder item builder | WIRED | `FragmentCard(fragment:, isSelected:, onToggleSelect:)` line 129 |
| lib/features/capture/presentation/quick_capture.dart | lib/features/capture/presentation/capture_provider.dart | ref.read captureProvider | WIRED | `ref.read(captureProvider.notifier).addFragment(text)` line 44 |
| lib/core/presentation/app_shell.dart | lib/shared/utils/keyboard_shortcuts.dart | QuickCaptureShortcut wrapping Scaffold | WIRED | `QuickCaptureShortcut(child: Scaffold(...))` lines 26, 43 |
| lib/shared/utils/keyboard_shortcuts.dart | lib/features/capture/presentation/quick_capture.dart | showDialog(QuickCaptureDialog) | WIRED | `showDialog(builder: (_) => const QuickCaptureDialog())` line 50 |
| lib/core/presentation/sidebar.dart | lib/shared/constants/app_constants.dart | breakpoint constants | WIRED | `sidebarCollapsedBreakpoint` line 26, `sidebarExtendedBreakpoint` line 35 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| CapturePage | captureState (ref.watch) | CaptureNotifier | Yes -- loads from Hive via FragmentRepository | FLOWING |
| FragmentCard | fragment (from list) | CaptureState.fragments | Yes -- real Fragment objects from Hive | FLOWING |
| EditorToolbar | editor.composer.selection | super_editor Editor | Yes -- live selection state from editor | FLOWING |
| QuickCaptureDialog | _controller.text | User input | Yes -- text passed to addFragment | FLOWING |
| FragmentRepository | _box (Hive Box) | Hive.openBox('fragments') | Yes -- real Hive box CRUD | FLOWING |
| SettingsRepository | _box (encrypted Hive) | Hive.openBox('settings', encryptionCipher) | Yes -- encrypted box with AES | FLOWING (but never consumed for window restore) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 57 tests pass | `flutter test 2>&1 \| tail -30` | All tests passed! (57 pass, 1 skip) | PASS |
| Zero analysis errors | `flutter analyze` | No issues found! (ran in 0.9s) | PASS |
| Key dependencies present | `grep pubspec.yaml` | super_editor, go_router, flutter_riverpod, hive_ce, flutter_secure_storage, window_manager, uuid, google_fonts all present | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| N/A | SKIPPED | No probes defined for this phase | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TECH-01 | 01-01 | Native Windows desktop with window management | PARTIAL | WindowManager with WindowOptions works. Remembered size NOT implemented. |
| TECH-02 | 01-02 | System-level IME works correctly | NEEDS HUMAN | super_editor handles IME natively; Phase 0 validated. Runtime verification required. |
| TECH-03 | 01-01 | Hive CE initialized with encrypted storage | SATISFIED | providers.dart:25-49 opens encrypted settings box with HiveAesCipher |
| TECH-04 | 01-01 | API Keys via flutter_secure_storage | SATISFIED | secure_storage_service.dart wraps FlutterSecureStorage with providerId keys |
| TECH-05 | 01-01, 01-03 | App shell with navigation between modules | SATISFIED | StatefulShellRoute with 3 branches, NavigationRail/NavigationBar adaptive |
| TECH-06 | 01-01 | App launches in under 3 seconds | NEEDS HUMAN | main.dart init is lightweight (Hive + WindowManager); no blockers in code |
| TECH-07 | 01-04 | App runs on Android with adaptive layout | SATISFIED | _BottomNavBar at < 600px, NavigationRail extended/collapsed above |
| EDIT-01 | 01-02 | Rich text editor with standard formatting | SATISFIED | EditorToolbar with bold, italic, H1/H2/H3, unordered/ordered list |
| EDIT-04 | 01-02 | Editor handles 300K+ char documents | NEEDS HUMAN | Phase 0 validated super_editor performance; runtime verification on large doc needed |
| CAPT-01 | 01-03 | Bullet-note mode for rapid fragment input | SATISFIED | CapturePage TextField with onSubmitted, FragmentCard list |
| CAPT-02 | 01-03 | Fragments organized by story/chapter/scene | SATISFIED | FilterChip row with tags, FragmentService.listFragmentsByTag |
| CAPT-05 | 01-04 | Floating quick-capture window from any screen | SATISFIED | Ctrl+Shift+N shortcut, QuickCaptureDialog, saves via captureProvider |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | - | - | - | No TBD/FIXME/XXX/TODO markers found. No stub implementations. No placeholder text in production code. |

### Human Verification Required

### 1. Chinese IME Input Behavior

**Test:** Launch app on Windows, activate Sogou/Wubi/Microsoft Pinyin IME, type Chinese text in the editor
**Expected:** IME composition works correctly -- underlined composing text appears, candidates window shows, committed text enters editor at correct position
**Why human:** IME behavior is platform-dependent, involves native platform channels, and cannot be verified in headless test environments

### 2. Startup Performance

**Test:** Build release version (`flutter build windows`), launch, measure time to interactive editor
**Expected:** App is interactive within 3 seconds from launch
**Why human:** Performance timing requires release build on real hardware; debug builds are not representative

### 3. Large Document Scrolling

**Test:** Paste a 300K+ character Chinese document into the editor and scroll through it
**Expected:** Smooth scrolling at 60fps, no visible lag, jank, or frame drops
**Why human:** Rendering performance requires real device testing; Phase 0 validated super_editor's virtualization capability but real-world feel needs human confirmation

### Gaps Summary

**1 gap blocking full goal achievement:**

**Window size persistence not wired.** The ROADMAP success criterion requires "remembered size" -- the app should persist and restore window geometry across restarts. The `SettingsRepository` has `saveWindowSize()`, `getWindowSize()`, `saveWindowPosition()`, and `getWindowPosition()` methods that operate on the encrypted Hive settings box. However, nothing calls these methods:

- `AppShellScaffold` does not implement `WindowListener` and never saves size/position on window resize/move events
- `main.dart` does not read saved geometry from `settingsRepositoryProvider` before calling `windowManager.waitUntilReadyToShow`
- The window always opens at the hardcoded `1200x800` default

The fix requires:
1. In `main.dart`: await `settingsRepositoryProvider` (or read synchronously from already-opened box), get saved size/position, pass to `WindowOptions` or call `windowManager.setSize()`/`windowManager.setPosition()` before `show()`
2. In `app_shell.dart`: mix in `WindowListener`, override `onWindowResize`/`onWindowMove` to save geometry via `settingsRepositoryProvider` (debounced to avoid excessive writes)

---

_Verified: 2026-06-01T15:45:00Z_
_Verifier: Claude (gsd-verifier)_
