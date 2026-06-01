---
phase: 01-app-shell-editor-capture-ui
plan: 03
subsystem: capture
tags: [fragment-capture, bullet-notes, tag-filtering, riverpod-state]
dependency_graph:
  requires: [01-01]
  provides: [capture-page, fragment-service, capture-state-management]
  affects: [lib/features/capture/, lib/core/application/]
tech_stack:
  added: []
  patterns: [Riverpod 3.x Notifier/NotifierProvider, manual timestamp formatting without intl]
key_files:
  created:
    - lib/core/application/fragment_service.dart
    - lib/features/capture/presentation/capture_provider.dart
    - lib/features/capture/presentation/fragment_card.dart
    - test/features/capture/fragment_tag_test.dart
    - test/features/capture/fragment_input_test.dart
  modified:
    - lib/features/capture/presentation/capture_page.dart
decisions:
  - "Riverpod 3.x Notifier used instead of StateNotifier (removed in flutter_riverpod 3.3.1) with ref.listen pattern for async repository initialization"
  - "Manual timestamp formatting (yyyy-MM-dd HH:mm) without intl package to avoid adding a dependency for a single format"
  - "CaptureNotifier uses nullable FragmentService with early-return guards instead of placeholder repository during loading"
metrics:
  duration: 12m
  completed: 2026-06-01
  tasks: 2
  files: 6
  tests: 15
---

# Phase 1 Plan 3: Fragment Capture Workspace Summary

Fragment capture bullet-note workspace with always-visible input field, tag-based filtering (全部/故事/章节/场景), multi-select checkboxes, and Hive-backed persistence via FragmentService and Riverpod 3.x state management.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Fragment service and capture state management | ec142ae | lib/core/application/fragment_service.dart, lib/features/capture/presentation/capture_provider.dart, test/features/capture/fragment_tag_test.dart |
| 2 | Capture page UI with fragment list, input field, and tag filtering | 53c0900 | lib/features/capture/presentation/capture_page.dart, lib/features/capture/presentation/fragment_card.dart, test/features/capture/fragment_input_test.dart |

## What Was Built

### Task 1: Fragment Service and Capture State Management
- **FragmentService**: Application-layer use case with createFragment, listFragments (descending sort), listFragmentsByTag ('全部' returns all), removeFragment, updateFragmentTags (sets updatedAt), getDefaultTags
- **CaptureState**: Immutable state class with fragments list, selectedIds set, activeFilter string, isLoading flag, and copyWith
- **CaptureNotifier**: Riverpod 3.x `Notifier<CaptureState>` managing CRUD, filtering, and selection -- uses `ref.listen` on fragmentRepositoryProvider to init when repository becomes available
- **Providers**: captureProvider (NotifierProvider), captureInputProvider (NotifierProvider for input text), fragmentFilterProvider (NotifierProvider for active filter), selectedFragmentsProvider (computed Provider)
- **8 unit tests**: All FragmentService methods tested with mock FragmentRepository

### Task 2: Capture Page UI
- **CapturePage**: Replaced placeholder with full implementation -- TextField input with hint '输入灵感碎片，按回车添加...', FilterChip row, ListView.builder with FragmentCard items, empty state, loading indicator
- **FragmentCard**: Card widget with Checkbox (multi-select), fragment text (maxLines 3, ellipsis), tag Chip widgets, formatted timestamp (yyyy-MM-dd HH:mm)
- **FilterChip row**: 全部 (default active), 故事, 章节, 场景 -- active chip uses primary color
- **Empty state**: Centered with bookmark icon, heading '还没有灵感碎片', body text per UI-SPEC copywriting
- **7 widget tests**: Input field, empty state, filter chips, fragment display, checkboxes, loading indicator, tag display

## Tests

| Suite | Tests | Status |
|-------|-------|--------|
| test/features/capture/fragment_tag_test.dart | 8 | PASSED (FragmentService CRUD, filtering, sorting) |
| test/features/capture/fragment_input_test.dart | 7 | PASSED (widget tests for CapturePage UI) |
| **Total** | **15** | **All passed** |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unmodifiable list sort failure in FragmentService**
- **Found during:** Task 1 -- listFragments() tried to sort repository's unmodifiable list
- **Issue:** Mock repository returns `List.unmodifiable()`, and real Hive box values may also be unmodifiable
- **Fix:** Use `List<Fragment>.of()` to create mutable copy before sorting
- **Files modified:** lib/core/application/fragment_service.dart
- **Commit:** ec142ae

**2. [Rule 3 - Blocking] StateNotifierProvider not available in Riverpod 3.x**
- **Found during:** Task 1 -- flutter_riverpod 3.3.1 removed StateNotifierProvider and StateProvider
- **Issue:** Plan specified @riverpod code generation but project uses manual providers; StateNotifier API not exported
- **Fix:** Rewrote using Riverpod 3.x `Notifier`/`NotifierProvider` with ref.listen pattern for async repository init
- **Files modified:** lib/features/capture/presentation/capture_provider.dart
- **Commit:** ec142ae

**3. [Rule 1 - Bug] Widget test pumpAndSettle timeout with CircularProgressIndicator**
- **Found during:** Task 2 -- loading indicator test timed out because CircularProgressIndicator animates indefinitely
- **Fix:** Changed to `pump()` instead of `pumpAndSettle()` for the loading test
- **Files modified:** test/features/capture/fragment_input_test.dart
- **Commit:** 53c0900

## Key Decisions

1. **Riverpod 3.x Notifier over StateNotifier**: flutter_riverpod 3.3.1 removed the legacy StateNotifier API. The new `Notifier` class with `NotifierProvider` is the correct pattern. Async repository initialization is handled via `ref.listen` with `fireImmediately: true`.

2. **Manual timestamp formatting without intl**: The `intl` package is not in the project's dependencies. Rather than adding it for a single format string, a simple `_formatTimestamp()` method pads year/month/day/hour/minute to produce 'yyyy-MM-dd HH:mm'.

3. **Nullable FragmentService with early-return guards**: Instead of creating a placeholder repository during loading, the CaptureNotifier uses a nullable `_service` field with early returns. This avoids the need for a mock/empty repository implementation and keeps the loading state handling clean.

## Self-Check: PASSED

- [x] lib/core/application/fragment_service.dart exists and contains FragmentService
- [x] lib/features/capture/presentation/capture_provider.dart exists and contains CaptureNotifier
- [x] lib/features/capture/presentation/capture_page.dart exists and contains TextField
- [x] lib/features/capture/presentation/fragment_card.dart exists and contains Checkbox
- [x] Commit ec142ae exists in git log
- [x] Commit 53c0900 exists in git log
- [x] 15/15 capture tests pass
- [x] flutter analyze: No issues found
