---
phase: 01-app-shell-editor-capture-ui
reviewed: 2026-06-01T23:30:00Z
depth: deep
files_reviewed: 24
files_reviewed_list:
  - lib/app.dart
  - lib/core/application/fragment_service.dart
  - lib/core/domain/app_settings.dart
  - lib/core/domain/fragment.dart
  - lib/core/domain/fragment_tag.dart
  - lib/core/infrastructure/fragment_repository.dart
  - lib/core/infrastructure/hive_adapters.dart
  - lib/core/infrastructure/secure_storage_service.dart
  - lib/core/infrastructure/settings_repository.dart
  - lib/core/presentation/app_shell.dart
  - lib/core/presentation/providers.dart
  - lib/core/presentation/sidebar.dart
  - lib/features/capture/presentation/capture_page.dart
  - lib/features/capture/presentation/capture_provider.dart
  - lib/features/capture/presentation/fragment_card.dart
  - lib/features/capture/presentation/quick_capture.dart
  - lib/features/editor/presentation/editor_page.dart
  - lib/features/editor/presentation/editor_provider.dart
  - lib/features/editor/presentation/editor_toolbar.dart
  - lib/features/settings/presentation/settings_page.dart
  - lib/main.dart
  - lib/shared/constants/app_constants.dart
  - lib/shared/theme/app_theme.dart
  - lib/shared/utils/keyboard_shortcuts.dart
findings:
  critical: 4
  warning: 8
  info: 5
  total: 17
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-06-01T23:30:00Z
**Depth:** deep
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed all 24 source files from Phase 01 (App Shell + Editor + Capture UI) at deep depth, including cross-file call-chain analysis. The codebase establishes a solid structural foundation with Clean Architecture layering and Riverpod state management. However, several significant bugs and architecture violations were identified.

Key concerns:
- **CaptureNotifier silently ignores user actions** when the repository hasn't loaded yet, with no loading indicator or error feedback.
- **Duplicate bold/italic logic** between EditorPage and EditorToolbar violates DRY and will drift.
- **CapturePage TextField lacks a controller**, so it cannot be programmatically cleared after submission despite the code attempting to do so.
- **Domain layer imports infrastructure layer**, violating the Clean Architecture dependency rule.
- **No error handling** on Hive operations, secure storage operations, or repository calls anywhere in the stack.
- **Encryption key loss risk** -- `Hive.generateSecureKey()` produces 32 bytes but `HiveAesCipher` requires exactly 32 bytes; no length validation on the decode path.

## Critical Issues

### CR-01: CaptureNotifier silently drops all user actions when repository is not ready

**File:** `lib/features/capture/presentation/capture_provider.dart:68-69`
**Issue:** `addFragment()` (line 68), `deleteFragment()` (line 75), `updateTags()` (line 112) all guard with `if (_service == null) return;`. The initial `build()` method starts with `isLoading: true` (line 19), but `addFragment` does not check `isLoading` -- it silently returns. The user types text, presses Enter, and nothing happens with zero feedback. After the repository loads, `_loadFragments` sets `isLoading: false` but by that point the user's input is gone from the TextField (cleared on submit in capture_page.dart line 48). This is a data loss scenario.

**Fix:**
```dart
void addFragment(String text, {List<String>? tags}) {
  if (_service == null) {
    // Queue or show error -- do not silently discard
    return;
  }
  _service!.createFragment(text, tags: tags);
  _reload();
}
```
Additionally, `capture_page.dart` should NOT clear the input until `addFragment` confirms success, or should at minimum check the loading state before calling clear:
```dart
onSubmitted: (text) {
  if (text.trim().isNotEmpty) {
    final state = ref.read(captureProvider);
    if (state.isLoading) return; // Don't clear if not ready
    ref.read(captureProvider.notifier).addFragment(text.trim());
    ref.read(captureInputProvider.notifier).clear();
  }
},
```

### CR-02: CapturePage TextField is never bound to captureInputProvider -- input clearing is broken

**File:** `lib/features/capture/presentation/capture_page.dart:29-54`
**Issue:** The `TextField` on line 29 has no `controller` parameter. The `onChanged` callback updates `captureInputProvider` (line 51-52) and `onSubmitted` calls `captureInputProvider.notifier.clear()` (line 48), but since no `TextEditingController` bound to `captureInputProvider` is provided to the `TextField`, calling `clear()` on the provider does not actually clear the text in the UI. The `CaptureInputNotifier` stores text state in Riverpod but the `TextField` manages its own internal state independently. After submitting, the text remains visible in the field, leading to duplicate submissions if the user presses Enter again.

**Fix:**
```dart
// In CapturePage.build(), create/use a controller bound to the provider:
final inputText = ref.watch(captureInputProvider);
final inputController = useTextEditingController(text: inputText); // or use a hook

TextField(
  controller: inputController, // bind the controller
  ...
  onSubmitted: (text) {
    if (text.trim().isNotEmpty) {
      ref.read(captureProvider.notifier).addFragment(text.trim());
      inputController.clear(); // clear the actual controller
    }
  },
)
```
The simplest correct fix is to add a `TextEditingController` field to a `ConsumerStatefulWidget` version of CapturePage, or use the `onChanged`/`onSubmitted` pair with a controller that is actually wired up.

### CR-03: Architecture violation -- Domain layer imports Infrastructure layer

**File:** `lib/core/domain/fragment.dart:2` (via `HiveTypeIds` reference) and `lib/core/domain/fragment_tag.dart`
**Issue:** `lib/core/domain/fragment.dart` line 3 defines `HiveTypeIds` inside the domain file. `HiveTypeIds` is an infrastructure concern (Hive type adapter registration IDs). The domain layer must have zero knowledge of persistence mechanisms. Per the project's architecture rules in `.claude/rules/02-museflow-architecture.md`: "Domain layer: pure Dart, no Flutter dependency, no dependency on any other layer." Hive type IDs are storage infrastructure details leaking into the domain.

Additionally, `lib/core/domain/app_settings.dart` does not import infrastructure directly but the `Fragment.fromJson` factory (line 46) and `toJson` (line 59) methods exist solely to serve Hive serialization, which is an infrastructure concern polluting the domain entity.

**Fix:**
Move `HiveTypeIds` to `lib/core/infrastructure/hive_adapters.dart` (where it is actually consumed). Keep domain entities as pure data classes without serialization methods -- move `fromJson`/`toJson` to DTO or adapter classes in the infrastructure layer:
```dart
// lib/core/infrastructure/hive_type_ids.dart
abstract class HiveTypeIds {
  static const int fragment = 0;
  static const int appSettings = 1;
  static const int manuscript = 2;
}
```

### CR-04: No error handling on critical storage operations -- potential crash and data loss

**File:** `lib/core/infrastructure/fragment_repository.dart:25`, `lib/core/infrastructure/settings_repository.dart:19-56`, `lib/core/infrastructure/secure_storage_service.dart:21-35`
**Issue:** Every storage operation (`_box.put`, `_box.get`, `_box.delete`, `_storage.write`, `_storage.read`) is called without any try-catch. If the Hive box is corrupted, the secure storage is unavailable, or the disk is full, the app will crash with an unhandled exception. Per project standards (`04-workflow.md`): "use `Result<T>` type, full try-catch." None of the repositories or services return `Result<T>` or handle errors.

For example, `FragmentRepository.addFragment()` (line 25) calls `_box.put()` synchronously but the method signature returns a `Fragment` without any error path. The `_box.put()` call actually returns a `Future<void>` but the future is not awaited, meaning the write may silently fail:
```dart
_box.put(fragment.id, fragment); // Future not awaited!
```

**Fix:**
```dart
Future<Fragment> addFragment(String text, {List<String>? tags}) async {
  final now = DateTime.now();
  final fragment = Fragment(
    id: _uuid.v4(),
    text: text,
    tags: tags ?? [],
    createdAt: now,
  );
  await _box.put(fragment.id, fragment); // await the write
  return fragment;
}
```
Wrap all storage calls in try-catch and propagate errors via `Result<T>` as the project standards require.

## Warnings

### WR-01: Duplicate bold/italic toggle logic between EditorPage and EditorToolbar

**File:** `lib/features/editor/presentation/editor_page.dart:35-66` and `lib/features/editor/presentation/editor_toolbar.dart:121-167`
**Issue:** The exact same `_toggleBold()` and `_toggleItalic()` logic is copy-pasted in both `EditorPage` (lines 35-49 for bold, 52-66 for italic) and `_EditorToolbarState` (lines 121-136 for bold, 152-167 for italic). Any bug fix or feature change must be applied in both places, and they will inevitably drift. The EditorPage keyboard shortcuts duplicate toolbar button behavior.

**Fix:** Extract formatting commands into a shared utility or have the EditorPage actions call methods exposed by the toolbar (or vice versa). For example:
```dart
// shared utility
void toggleAttribution(Editor editor, Attribution attribution) {
  final composer = editor.composer;
  final selection = composer.selection;
  if (selection == null) return;
  if (selection.isCollapsed) {
    composer.preferences.toggleStyles({attribution});
  } else {
    editor.execute([
      ToggleTextAttributionsRequest(
        documentRange: selection,
        attributions: {attribution},
      ),
    ]);
  }
}
```

### WR-02: FragmentRepository.addFragment returns before Hive write completes

**File:** `lib/core/infrastructure/fragment_repository.dart:17-27`
**Issue:** `addFragment` is synchronous but `_box.put()` returns `Future<void>`. The fragment is returned to the caller before the Hive write completes. If the app crashes between the method returning and the Hive write flushing, the fragment is lost despite the caller believing it was persisted. The method should be async and await the put.

**Fix:**
```dart
Future<Fragment> addFragment(String text, {List<String>? tags}) async {
  final now = DateTime.now();
  final fragment = Fragment(
    id: _uuid.v4(),
    text: text,
    tags: tags ?? [],
    createdAt: now,
  );
  await _box.put(fragment.id, fragment);
  return fragment;
}
```

### WR-03: CaptureNotifier.build() uses ref.watch on FutureProvider -- potential rebuild loop

**File:** `lib/features/capture/presentation/capture_provider.dart:43-49`
**Issue:** `CaptureNotifier.build()` calls `ref.watch(fragmentRepositoryProvider)` (line 45). The `fragmentRepositoryProvider` is a `FutureProvider` that opens a Hive box. If the build method re-runs (which it will when the FutureProvider's AsyncValue transitions from loading to data), `_loadFragments` is called again via `whenData`. This can lead to `_service` being reassigned and the fragment list being reloaded on every state transition, which may cause flickering. More critically, if the FutureProvider ever errors and retries, the callback structure could lead to unexpected behavior.

**Fix:** Use `ref.listen` or handle the async states explicitly rather than relying on `whenData` side effects:
```dart
@override
CaptureState build() {
  ref.listen(fragmentRepositoryProvider, (previous, next) {
    next.whenData((repository) {
      _loadFragments(FragmentService(repository));
    });
  });
  return const CaptureState();
}
```

### WR-04: CaptureState does not handle or expose error state

**File:** `lib/features/capture/presentation/capture_provider.dart:9-35`
**Issue:** `CaptureState` has `isLoading` but no `error` field. If the repository fails to open, the user sees a perpetual loading spinner with no indication of failure. All async operations in the notifier (`deleteFragment`, `updateTags`) have no error handling -- exceptions propagate unhandled to the zone handler.

**Fix:** Add an error field to `CaptureState`:
```dart
class CaptureState {
  final List<Fragment> fragments;
  final Set<String> selectedIds;
  final String activeFilter;
  final bool isLoading;
  final String? error;
  // ...
}
```

### WR-05: EditorPage.dispose() only disposes composer, leaks Editor resources

**File:** `lib/features/editor/presentation/editor_page.dart:30-33`
**Issue:** The `dispose()` method calls `_editor.composer.dispose()` but does not dispose the editor's document or other resources. The `createDefaultDocumentEditor()` creates a `MutableDocument` which may hold listeners. Depending on super_editor's internal lifecycle, this could leak resources.

**Fix:** Verify super_editor's disposal requirements. Typically:
```dart
@override
void dispose() {
  _editor.composer.dispose();
  _editor.document.dispose(); // if applicable
  super.dispose();
}
```

### WR-06: _hasAttributionInRange silently swallows all exceptions

**File:** `lib/features/editor/presentation/editor_toolbar.dart:275-277`
**Issue:** The `_hasAttributionInRange` method (line 275) has a bare `catch (_)` that catches every exception and returns `false`. This masks real bugs like class cast errors (if `nodePosition` is not a `TextNodePosition`) or null pointer errors. These should at minimum be logged for debugging.

**Fix:**
```dart
} catch (e) {
  debugPrint('_hasAttributionInRange error: $e');
  return false;
}
```

### WR-07: Fragment.copyWith cannot set updatedAt to null

**File:** `lib/core/domain/fragment.dart:29-43`
**Issue:** The `copyWith` method uses `updatedAt ?? this.updatedAt`, which means there is no way to explicitly set `updatedAt` to `null` (to clear it). While this may be intentional for the current use case, it violates the standard `copyWith` pattern. The `updateFragmentTags` method in `FragmentService` always sets `updatedAt` to `DateTime.now()`, so this is not currently triggered, but it limits future flexibility.

**Fix:** Use a sentinel pattern if null-clearing is needed:
```dart
Fragment copyWith({
  String? id,
  String? text,
  List<String>? tags,
  DateTime? createdAt,
  Object? updatedAt = _sentinel,
}) {
  return Fragment(
    // ...
    updatedAt: updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
  );
}
```

### WR-08: SettingsRepository.imports dart:ui -- tight coupling to Flutter in infrastructure

**File:** `lib/core/infrastructure/settings_repository.dart:1`
**Issue:** `import 'dart:ui';` brings in `Size` and `Offset` types for window geometry persistence. The infrastructure layer should not depend on Flutter UI types. This prevents the repository from being tested in a pure Dart test context and violates the project convention of keeping infrastructure decoupled from presentation types.

**Fix:** Define plain DTOs for window geometry:
```dart
class WindowGeometry {
  final double width;
  final double height;
  final double? x;
  final double? y;
  const WindowGeometry({required this.width, required this.height, this.x, this.y});
}
```
Use these in the repository, and convert to/from `Size`/`Offset` at the presentation layer boundary.

## Info

### IN-01: Unused provider -- fragmentFilterProvider and FragmentFilterNotifier

**File:** `lib/features/capture/presentation/capture_provider.dart:147-156`
**Issue:** `FragmentFilterNotifier` and `fragmentFilterProvider` are defined but never referenced anywhere in the codebase. The active filter is tracked within `CaptureState.activeFilter` instead, making these dead code.

**Fix:** Remove `FragmentFilterNotifier`, `fragmentFilterProvider`, and the unused import of `fragment_tag.dart` if applicable.

### IN-02: Magic string '全部' used as filter constant

**File:** `lib/features/capture/presentation/capture_provider.dart:18,106`, `lib/features/capture/presentation/capture_page.dart:67`, `lib/core/application/fragment_service.dart:32`
**Issue:** The string `'全部'` (meaning "All") is used as a sentinel filter value in multiple files without being defined as a constant. If it's ever misspelled or changed, the filter logic breaks silently.

**Fix:** Define a constant:
```dart
// In app_constants.dart or fragment_tag.dart
static const String allFilterTag = '全部';
```

### IN-03: AppShellScaffold duplicatively checks screen width -- width queried twice

**File:** `lib/core/presentation/app_shell.dart:21-22` and `lib/core/presentation/sidebar.dart:23`
**Issue:** `AppShellScaffold.build()` checks `screenWidth < AppConstants.sidebarCollapsedBreakpoint` to decide layout (line 22), then passes data to `AdaptiveSidebar` which checks the exact same condition again (sidebar.dart line 26). This means the narrow-layout branch of `AppShellScaffold` always renders `_BottomNavBar`, and the desktop branch always renders `NavigationRail`. The `AdaptiveSidebar` never actually switches between the two because its parent already made the decision.

**Fix:** In the narrow layout, just use `_BottomNavBar` directly instead of wrapping it in `AdaptiveSidebar`. Or remove the branching in `AppShellScaffold` and let `AdaptiveSidebar` handle it entirely.

### IN-04: EditorToolbar is a StatefulWidget but has no mutable state

**File:** `lib/features/editor/presentation/editor_toolbar.dart:9-15`
**Issue:** `EditorToolbar` extends `StatefulWidget` but `_EditorToolbarState` has no mutable fields and does not call `setState`. The toolbar reactively reads from `widget.editor.composer.selectionNotifier` via `ListenableBuilder`. A `StatelessWidget` would suffice.

**Fix:** Convert to `StatelessWidget` unless there are plans to add mutable state (e.g., tracking dropdown open state).

### IN-05: SecureStorageService lacks error handling documentation

**File:** `lib/core/infrastructure/secure_storage_service.dart:21-35`
**Issue:** The `FlutterSecureStorage` methods can throw `PlatformException` on Windows if the credential manager is unavailable, or on Android if the keystore is corrupted. These are unhandled and undocumented. While the interface is clean, callers have no way to know what exceptions to expect.

**Fix:** Add documentation to each method listing possible exceptions, or wrap in try-catch returning `Result<T>`:
```dart
/// Throws [PlatformException] if secure storage is unavailable on the platform.
Future<void> saveApiKey(String providerId, String key) async { ... }
```

---

_Reviewed: 2026-06-01T23:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
