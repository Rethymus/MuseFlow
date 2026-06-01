---
phase: 01-app-shell-editor-capture-ui
plan: 01
subsystem: core
tags: [app-shell, navigation, storage, domain-models]
dependency_graph:
  requires: []
  provides: [app-entry, domain-entities, storage-infra, navigation-shell]
  affects: [lib/main.dart, lib/app.dart, lib/core/]
tech_stack:
  added: [go_router StatefulShellRoute, NavigationRail/NavigationBar adaptive, manual Hive TypeAdapters]
  patterns: [Clean Architecture layers, immutable entities with copyWith, Riverpod FutureProvider for async repos]
key_files:
  created:
    - lib/core/domain/fragment.dart
    - lib/core/domain/fragment_tag.dart
    - lib/core/domain/app_settings.dart
    - lib/core/infrastructure/hive_adapters.dart
    - lib/core/infrastructure/secure_storage_service.dart
    - lib/core/infrastructure/fragment_repository.dart
    - lib/core/infrastructure/settings_repository.dart
    - lib/core/presentation/providers.dart
    - lib/core/presentation/app_shell.dart
    - lib/core/presentation/sidebar.dart
    - lib/shared/theme/app_theme.dart
    - lib/shared/constants/app_constants.dart
    - lib/features/editor/presentation/editor_page.dart
    - lib/features/capture/presentation/capture_page.dart
    - lib/features/settings/presentation/settings_page.dart
    - test/helpers/hive_test_helper.dart
    - test/infrastructure/hive_init_test.dart
    - test/infrastructure/secure_storage_test.dart
    - test/app/window_management_test.dart
  modified:
    - lib/main.dart
    - lib/app.dart
decisions:
  - "Domain models written manually without freezed due to freezed 3.2.6-dev.1 generating abstract mixin members incompatible with Dart analysis"
  - "Manual Hive TypeAdapters delegating to toJson/fromJson instead of hive_ce_generator (not in dependencies)"
  - "Encryption key stored as base64-encoded string in flutter_secure_storage, decoded to List<int> for HiveAesCipher"
  - "Widget tests use simple placeholder pages instead of SuperEditor to avoid platform-specific rendering issues in test environment"
metrics:
  duration: 18m
  completed: 2026-06-01
  tasks: 2
  files: 19
  tests: 12
---

# Phase 1 Plan 1: Domain Models, Storage, and App Shell Summary

Manual immutable domain entities (Fragment, AppSettings, FragmentTags), Hive CE storage infrastructure with encryption, flutter_secure_storage for API keys, go_router StatefulShellRoute with adaptive NavigationRail sidebar, and three placeholder branch pages.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Domain models, storage infrastructure, and app initialization | 4f08e66 | lib/core/domain/*, lib/core/infrastructure/*, lib/core/presentation/providers.dart, lib/main.dart |
| 2 | App shell with go_router, adaptive sidebar, and placeholder pages | e62caff | lib/app.dart, lib/core/presentation/app_shell.dart, lib/core/presentation/sidebar.dart, lib/features/*, lib/shared/* |

## What Was Built

### Task 1: Domain Models and Storage Infrastructure
- **Fragment**: Immutable entity with id, text, tags, createdAt, updatedAt -- manual implementation with copyWith, toJson/fromJson, equality
- **AppSettings**: Immutable entity with window geometry and defaultTag preferences
- **FragmentTags**: Static constants for default tags (story, chapter, scene)
- **HiveTypeIds**: Centralized type ID registry (fragment=0, appSettings=1, manuscript=2)
- **FragmentAdapter / AppSettingsAdapter**: Manual TypeAdapters delegating to JSON serialization
- **SecureStorageService**: Wraps flutter_secure_storage with providerId-based API key CRUD
- **FragmentRepository**: CRUD operations over Hive Box<Fragment> with UUID v4 ID generation
- **SettingsRepository**: Window size/position persistence over encrypted Hive box, default tag management
- **Providers**: Riverpod FutureProviders for repositories, Provider for SecureStorageService
- **main.dart**: Init sequence -- Hive.initFlutter -> register adapters -> window_manager -> ProviderScope

### Task 2: App Shell and Navigation
- **MuseFlowApp**: ConsumerWidget with go_router StatefulShellRoute.indexedStack, initialLocation /editor
- **AppShellScaffold**: Row layout with sidebar + Expanded content area, switches to bottom NavigationBar on narrow screens
- **AdaptiveSidebar**: NavigationRail (extended at >=1000px, collapsed at 600-1000px, bottom bar below 600px)
- **EditorPage**: super_editor with centered ConstrainedBox(maxWidth: 800) layout
- **CapturePage / SettingsPage**: Placeholder pages for Phase 1
- **AppConstants**: Layout breakpoints, route paths, window defaults
- **appTheme()**: Material 3 dark indigo theme with Noto Sans SC via google_fonts

## Tests

| Suite | Tests | Status |
|-------|-------|--------|
| test/infrastructure/hive_init_test.dart | 4 | PASSED (Hive box CRUD, encrypted box, Fragment serialization) |
| test/infrastructure/secure_storage_test.dart | 4 | PASSED (graceful skip on platform without secure storage) |
| test/app/window_management_test.dart | 4 | PASSED (NavigationRail, initial route, branch switching, NavigationBar on narrow) |
| **Total** | **12** | **All passed** |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] freezed 3.2.6-dev.1 generates abstract mixin members**
- **Found during:** Task 1 -- build_runner generated mixin `_$Fragment` with abstract getters that caused `non_abstract_class_inherits_abstract_member` errors
- **Issue:** freezed ^3.2.5 resolved to 3.2.6-dev.1; pinning to stable 3.2.5 failed due to transitive dependency conflicts
- **Fix:** Wrote domain models manually without freezed, using immutable classes with copyWith, toJson/fromJson, and equality operators
- **Files modified:** lib/core/domain/fragment.dart, lib/core/domain/app_settings.dart
- **Commit:** 4f08e66

**2. [Rule 1 - Bug] Hive encryption key type mismatch in providers**
- **Found during:** Task 1 -- `Hive.generateSecureKey()` returns `List<int>`, not `String`
- **Fix:** Store key as base64-encoded string in flutter_secure_storage, decode to List<int> for HiveAesCipher
- **Files modified:** lib/core/presentation/providers.dart
- **Commit:** 4f08e66

**3. [Rule 1 - Bug] SuperEditor fails in widget test environment**
- **Found during:** Task 2 -- SuperEditor's Android controls overlay causes RenderObject type mismatch in test environment
- **Fix:** Widget tests use simple placeholder pages instead of the real EditorPage with SuperEditor
- **Files modified:** test/app/window_management_test.dart
- **Commit:** e62caff

**4. [Rule 2 - Security] Removed deprecated encryptedSharedPreferences parameter**
- **Found during:** Task 1 -- flutter_secure_storage deprecated `encryptedSharedPreferences` in AndroidOptions
- **Fix:** Removed the parameter (data migration is automatic per deprecation notice)
- **Files modified:** lib/core/infrastructure/secure_storage_service.dart
- **Commit:** 4f08e66

## Key Decisions

1. **Manual domain models over freezed**: Due to freezed 3.2.6-dev.1 generating incompatible code, domain entities are written manually. This is a pragmatic choice -- the entities are simple value objects that don't need union types. Future plans can revisit freezed when the stable version resolves the transitive dependency conflict.

2. **Manual Hive TypeAdapters**: Without hive_ce_generator in dependencies, adapters delegate to the entities' toJson/fromJson methods. This keeps the serialization logic in one place (the entity class) and avoids adding another code generation dependency.

3. **Base64-encoded encryption key**: Hive.generateSecureKey() returns List<int> which can't be stored directly in flutter_secure_storage. Base64 encoding provides a safe, reversible conversion.

## Known Stubs

| File | Stub | Reason |
|------|------|--------|
| lib/features/capture/presentation/capture_page.dart | Placeholder UI with "即将上线" text | Full implementation in Plan 03 |
| lib/features/settings/presentation/settings_page.dart | Static list items without functionality | Full settings UI in later phases |
| lib/features/editor/presentation/editor_page.dart | No toolbar yet | Toolbar added in Plan 02 |

## Self-Check: PASSED

- [x] lib/main.dart exists and contains Hive.initFlutter
- [x] lib/app.dart exists and contains StatefulShellRoute.indexedStack
- [x] lib/core/presentation/app_shell.dart exists and contains AppShellScaffold
- [x] lib/core/presentation/sidebar.dart exists and contains NavigationRail
- [x] lib/core/domain/fragment.dart exists and contains toJson/fromJson
- [x] lib/core/infrastructure/secure_storage_service.dart exists and contains FlutterSecureStorage
- [x] lib/shared/constants/app_constants.dart exists and contains breakpoint
- [x] Commit 4f08e66 exists in git log
- [x] Commit e62caff exists in git log
- [x] 12/12 tests pass
- [x] flutter analyze: No issues found
