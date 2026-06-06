---
phase: 11-manuscript-chapter-management
plan: 03
subsystem: manuscript-library-ui
tags: [presentation, routing, widgets, tdd]
dependency_graph:
  requires: [11-02]
  provides: [ManuscriptLibraryPage, ManuscriptCard, ManuscriptCreateDialog, ManuscriptSettingsPage, manuscript-routes]
  affects: [app.dart, app_constants.dart]
tech_stack:
  added: [ConsumerStatefulWidget, GridView.builder, GoRoute top-level routes]
  patterns: [TDD RED/GREEN, Riverpod AsyncNotifier override, responsive grid]
key_files:
  created:
    - lib/features/manuscript/presentation/manuscript_library_page.dart
    - lib/features/manuscript/presentation/manuscript_card.dart
    - lib/features/manuscript/presentation/manuscript_create_dialog.dart
    - lib/features/manuscript/presentation/manuscript_settings_page.dart
    - test/features/manuscript/presentation/manuscript_library_page_test.dart
    - test/features/manuscript/presentation/manuscript_card_test.dart
  modified:
    - lib/app.dart
    - lib/shared/constants/app_constants.dart
decisions:
  - Library page uses ConsumerStatefulWidget for sort state management
  - Long-press context menu uses BottomSheet instead of PopupMenu for better UX
  - Editor route placeholder (Scaffold with text) awaits Plan 04 EditorWithSidebar
  - Card cover letter falls back to first 2 chars of title when coverLetter is empty
metrics:
  duration: 5m26s
  completed: 2026-06-06T00:52:49Z
  tasks_completed: 2
  files_created: 6
  files_modified: 2
  tests_added: 8
  test_suite: 897 passed, 1 skipped, 0 failed
---

# Phase 11 Plan 03: Manuscript Library Homepage & Routing Summary

Manuscript library homepage with responsive card grid, quick-create dialog, metadata settings page, and routing infrastructure that makes the library the new home screen with full-screen editor sub-routes outside the shell.

## What Was Built

### Task 1: Presentation Layer (TDD)
**Commits:** `95a1d9d` (RED), `8a3767d` (GREEN)

- **ManuscriptLibraryPage**: ConsumerStatefulWidget with sort state (default: recentEdit). Watches `manuscriptNotifierProvider`, renders GridView.builder with responsive columns (3/2/1). Empty state with `Icons.auto_stories`, heading, body, and FilledButton CTA. FAB for quick-create. AppBar with sort PopupMenuButton.
- **ManuscriptCard**: Genre-colored cover area (80px), title with ellipsis, word count progress bar with LinearProgressIndicator, status badge with color-coded pill, relative timestamp. Tap navigates to `/manuscript/:id/editor`, long-press shows context menu (edit info / delete with 30-day warning).
- **ManuscriptCreateDialog**: AlertDialog with title TextField (required validation), genre DropdownButtonFormField from ManuscriptGenre.presets with custom option. Creates manuscript with status "构思中", auto-generates cover letter from title.
- **ManuscriptSettingsPage**: ConsumerStatefulWidget loading manuscript by ID. Form fields for title, genre, description (max 500), target word count. Save button persists via ManuscriptNotifier.save.

### Task 2: Routing Infrastructure
**Commit:** `3a19bef`

- Added `manuscriptEditor` and `manuscriptSettings` route constants to AppConstants.
- Branch 1 in StatefulShellRoute now renders ManuscriptLibraryPage (replacing EditorPage).
- Top-level `/manuscript/:id/editor` route (placeholder scaffold for Plan 04).
- Top-level `/manuscript/:id/settings` route rendering ManuscriptSettingsPage.
- Both manuscript routes are outside StatefulShellRoute per RESEARCH Pitfall 4 (bottom nav hidden).

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED (failing tests) | `95a1d9d` | 2 test files, 8 test cases, all failing (implementation files not yet created) |
| GREEN (implementation) | `8a3767d` | All 8 tests pass |
| REFACTOR | N/A | No refactoring needed |

## Key Decisions

1. **BottomSheet for context menu**: Used `showModalBottomSheet` instead of `PopupMenuButton` for long-press actions on cards, providing better touch targets and more space for action descriptions.
2. **Editor route placeholder**: The `/manuscript/:id/editor` route renders a simple Scaffold with placeholder text. Plan 04 will replace this with `EditorWithSidebar`.
3. **Cover letter fallback**: When `coverLetter` is empty, ManuscriptCard falls back to the first 1-2 characters of the title.
4. **Sort dropdown in AppBar**: Used `PopupMenuButton` for sort mode selection (keeps AppBar clean, matches Material Design patterns).

## Deviations from Plan

None - plan executed exactly as written.

## Threat Model Compliance

| Threat ID | Mitigation | Status |
|-----------|-----------|--------|
| T-11-01 | Title field validation (non-empty check), genre restricted to presets dropdown | Implemented in ManuscriptCreateDialog and ManuscriptSettingsPage |
| T-11-02 | Route ID used for local Hive lookup only | Accepted per plan |
| T-11-03 | Card grid bounded by manuscript count | Accepted per plan |

## Self-Check

All files verified present. All commits verified in git log. Full test suite: 897 passed, 1 skipped, 0 failed.
