---
phase: quick-260606-mvg-fix-phase-11-security-mitigations-from-1
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/manuscript/domain/manuscript.dart
  - lib/features/manuscript/domain/chapter.dart
  - lib/features/manuscript/presentation/manuscript_create_dialog.dart
  - lib/features/manuscript/presentation/manuscript_settings_page.dart
  - lib/features/manuscript/presentation/editor_with_sidebar.dart
  - test/features/manuscript/domain/manuscript_test.dart
  - test/features/manuscript/domain/chapter_test.dart
  - test/features/manuscript/presentation/manuscript_library_page_test.dart
  - test/features/manuscript/presentation/editor_with_sidebar_test.dart
autonomous: true
requirements:
  - T-11-01-plan01
  - T-11-02-plan01
  - T-11-01-plan03
  - T-11-06-02
must_haves:
  truths:
    - "Corrupted local Hive JSON for Manuscript/Chapter cannot crash unsafe direct casts or DateTime.parse calls."
    - "Manuscript create/settings title input rejects empty and over-length titles consistently."
    - "Custom manuscript genre threat is resolved by either preset-only UI or bounded validated custom genre with explicit product-risk handling in code/tests."
    - "EditorWithSidebar dispose path does not call ChapterAutoSave.forceSave without awaiting it."
  artifacts:
    - path: "lib/features/manuscript/domain/manuscript.dart"
      provides: "Defensive Manuscript.fromJson validation with safe field extraction and date parsing"
    - path: "lib/features/manuscript/domain/chapter.dart"
      provides: "Defensive Chapter.fromJson validation with safe field extraction and date parsing"
    - path: "lib/features/manuscript/presentation/manuscript_create_dialog.dart"
      provides: "Bounded manuscript title and genre validation in create flow"
    - path: "lib/features/manuscript/presentation/manuscript_settings_page.dart"
      provides: "Bounded manuscript title and genre validation in settings flow"
    - path: "lib/features/manuscript/presentation/editor_with_sidebar.dart"
      provides: "Dispose cleanup without unawaited force-save path"
  key_links:
    - from: "ManuscriptRepository/ChapterRepository Hive reads"
      to: "Manuscript.fromJson / Chapter.fromJson"
      via: "domain deserialization"
      pattern: "fromJson"
    - from: "ManuscriptCreateDialog / ManuscriptSettingsPage"
      to: "Manuscript entity creation/save"
      via: "validated title and genre before notifier call"
      pattern: "Manuscript\(|copyWith\("
    - from: "EditorWithSidebar.dispose"
      to: "ChapterAutoSave.forceSave"
      via: "no synchronous dispose-time forceSave call"
      pattern: "dispose[\\s\\S]*forceSave"
---

<objective>
Fix the four open Phase 11 security mitigations listed in `11-SECURITY.md`: safe Manuscript/Chapter deserialization, manuscript title length validation, custom genre mitigation, and removal of the unawaited dispose force-save path.

Purpose: Phase 11 security audit is blocked until these open threats are either mitigated in code or explicitly resolved with bounded validation and tests.
Output: Focused code and test updates that close T-11-01-plan01, T-11-02-plan01, T-11-01-plan03, and T-11-06-02.
</objective>

<execution_context>
@/home/re/code/MuseFlow/.claude/get-shit-done/workflows/execute-plan.md
@/home/re/code/MuseFlow/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/re/code/MuseFlow/CLAUDE.md
@/home/re/code/MuseFlow/.claude/rules/02-museflow-architecture.md
@/home/re/code/MuseFlow/.claude/rules/03-flutter-standards.md
@/home/re/code/MuseFlow/.planning/STATE.md
@/home/re/code/MuseFlow/.planning/phases/11-manuscript-chapter-management/11-SECURITY.md
@/home/re/code/MuseFlow/lib/features/manuscript/domain/manuscript.dart
@/home/re/code/MuseFlow/lib/features/manuscript/domain/chapter.dart
@/home/re/code/MuseFlow/lib/features/manuscript/domain/manuscript_genre.dart
@/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_create_dialog.dart
@/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart
@/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart
@/home/re/code/MuseFlow/test/features/manuscript/domain/manuscript_test.dart
@/home/re/code/MuseFlow/test/features/manuscript/domain/chapter_test.dart
@/home/re/code/MuseFlow/test/features/manuscript/presentation/manuscript_library_page_test.dart
@/home/re/code/MuseFlow/test/features/manuscript/presentation/editor_with_sidebar_test.dart

<interfaces>
Existing contracts to preserve:
- `Manuscript.fromJson(Map<String, dynamic> json)` and `Chapter.fromJson(Map<String, dynamic> json)` must remain synchronous factory constructors returning entities for valid JSON.
- `ManuscriptGenre.presets` is the authoritative preset list. `ManuscriptGenre.genreColor(String genre)` currently returns a default color for unknown/custom genres.
- `EditorWithSidebar._switchChapter`, `_navigateBack`, and `_openSettings` already await `_forceSaveAsync()`. Keep these awaited paths; remove only the unawaited dispose-time force-save guarantee gap.
</interfaces>
</context>

<source_audit>
## Multi-Source Coverage Audit

| Source | Item | Coverage |
|--------|------|----------|
| SECURITY | T-11-01-plan01: type-safe deserialization/casts and UI title length validation | Task 1 and Task 2 |
| SECURITY | T-11-02-plan01: corrupted Hive data guarded from unsafe parser path | Task 1 |
| SECURITY | T-11-01-plan03: title max-length and custom genre mitigation | Task 2 |
| SECURITY | T-11-06-02: remove unawaited dispose force-save path | Task 3 |
| PROJECT/CLAUDE | Clean Architecture, immutable entities, Result-style safe errors where applicable, TDD practical | All tasks use domain/presentation boundaries and add tests first |
</source_audit>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add defensive Manuscript and Chapter JSON deserialization</name>
  <files>lib/features/manuscript/domain/manuscript.dart, lib/features/manuscript/domain/chapter.dart, test/features/manuscript/domain/manuscript_test.dart, test/features/manuscript/domain/chapter_test.dart</files>
  <behavior>
    - Test 1: `Manuscript.fromJson` preserves valid round-trip behavior and existing defaults.
    - Test 2: `Manuscript.fromJson` rejects or safely handles malformed field types, invalid dates, and non-string `characterCardIds` without `TypeError` or raw `FormatException` from direct casts/parsing.
    - Test 3: `Chapter.fromJson` preserves valid round-trip behavior and existing defaults.
    - Test 4: `Chapter.fromJson` rejects or safely handles malformed field types and invalid dates without `TypeError` or raw `FormatException` from direct casts/parsing.
  </behavior>
  <action>Add failing tests first for corrupted local Hive JSON cases called out in T-11-01-plan01 and T-11-02-plan01. Then replace unsafe `as String`, `as int`, `.cast<String>()`, and `DateTime.parse(...)` paths in `Manuscript.fromJson` and `Chapter.fromJson` with small private extraction helpers in the same domain files. Preserve public constructors and `toJson` output. Use deterministic safe behavior: required fields (`id`, `title`, `genre`/`manuscriptId`, `sortOrder`, `createdAt`, `updatedAt`) should throw `FormatException` with a domain-specific message when invalid or missing; optional fields should default only when absent/null, not when attacker/corruption provides a wrong type. For `characterCardIds`, accept only a list whose items are strings; otherwise throw `FormatException`. Use `DateTime.tryParse` and throw `FormatException` with field name on invalid dates. Do not import Flutter into domain files.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && flutter test test/features/manuscript/domain/manuscript_test.dart test/features/manuscript/domain/chapter_test.dart</automated>
  </verify>
  <done>Valid JSON round-trips still pass; corrupted JSON tests fail RED before implementation and pass GREEN after implementation; direct unsafe casts/parsing identified in 11-SECURITY.md are gone or wrapped by checked helpers.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Bound manuscript title and custom genre input in create/settings flows</name>
  <files>lib/features/manuscript/presentation/manuscript_create_dialog.dart, lib/features/manuscript/presentation/manuscript_settings_page.dart, test/features/manuscript/presentation/manuscript_library_page_test.dart</files>
  <behavior>
    - Test 1: create dialog prevents creating a manuscript when title is empty or over max length.
    - Test 2: settings page prevents saving when title is empty or over max length.
    - Test 3: custom genre handling is bounded: either custom genre is removed/preset-only, or custom genre validates non-empty and max length before create/save.
  </behavior>
  <action>Add widget tests first where practical for T-11-01-plan03. Define shared private constants in the presentation files if no existing constant exists: manuscript title max length 100 chars, custom genre max length 20 chars if custom genres remain. Add `LengthLimitingTextInputFormatter`/`maxLength` to title fields in both create and settings pages and enforce the same limit in `_handleCreate`/`_handleSave` so pasted/programmatic text is rejected with visible error feedback. Resolve the custom genre mitigation explicitly: prefer bounded validated custom genre because `ManuscriptGenre.genreColor` already has a documented default color for unknown/custom genres; keep the custom option only with non-empty and max-length validation, formatter/maxLength, and visible error feedback. Do not silently return on invalid genre. Add `package:flutter/services.dart` imports where needed for formatters. Preserve Riverpod notifier usage and Clean Architecture boundaries.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && flutter test test/features/manuscript/presentation/manuscript_library_page_test.dart</automated>
  </verify>
  <done>Create/settings UI both enforce non-empty and max-length manuscript titles; custom genre is bounded and visibly validated; no arbitrary unbounded custom genre path remains.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Remove unawaited dispose force-save path in EditorWithSidebar</name>
  <files>lib/features/manuscript/presentation/editor_with_sidebar.dart, test/features/manuscript/presentation/editor_with_sidebar_test.dart</files>
  <behavior>
    - Test 1: disposing `EditorWithSidebar` does not call `ChapterAutoSave.forceSave` from a synchronous dispose cleanup path.
    - Test 2: awaited save paths for chapter switch/back/settings remain intact and existing editor tests keep passing.
  </behavior>
  <action>Add or update focused tests for T-11-06-02. Remove `_forceSaveSync()` entirely if unused after this change. Change `dispose()`/`_forceSaveAndCleanup()` so cleanup only removes listeners, clears editor references, disposes composer, and does not invoke `ChapterAutoSave.forceSave()` or `onDocumentChanged()` from synchronous dispose. Keep `_forceSaveAsync()` awaited in `_switchChapter`, `_openSettings`, and `_navigateBack`; keep lifecycle `_forceSaveBestEffort()` with catch/log behavior because 11-SECURITY.md only flags the dispose unawaited guarantee path. Update comments to state that dispose is cleanup-only and all controllable exits use awaited save paths.</action>
  <verify>
    <automated>cd /home/re/code/MuseFlow && flutter test test/features/manuscript/presentation/editor_with_sidebar_test.dart</automated>
    <automated>cd /home/re/code/MuseFlow && grep -n "_forceSaveSync\|_forceSaveAndCleanup\|forceSave()" lib/features/manuscript/presentation/editor_with_sidebar.dart</automated>
  </verify>
  <done>`dispose()` no longer reaches `forceSave()`; `_forceSaveSync` is removed or unused; editor sidebar focused tests pass.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Hive JSON → domain entities | Corrupted local persisted maps flow into `Manuscript.fromJson` and `Chapter.fromJson`. |
| User input → manuscript metadata | Title and custom genre text flow into local manuscript entities and Hive storage. |
| Flutter lifecycle/dispose → local persistence | Synchronous widget disposal previously attempted asynchronous force-save work. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-11-01-plan01 | Tampering | `Manuscript.fromJson` / `Chapter.fromJson` and title UI | mitigate | Checked JSON extraction helpers plus title max-length validation in create/settings flows. |
| T-11-02-plan01 | Denial of Service | Hive box corruption deserialization | mitigate | `DateTime.tryParse`, required-field checks, and domain-specific `FormatException` instead of unsafe direct cast/parser crashes. |
| T-11-01-plan03 | Tampering | `ManuscriptCreateDialog` / `ManuscriptSettingsPage` genre/title fields | mitigate | Title max 100; custom genre kept only as bounded max 20 with visible validation, or removed if implementation chooses preset-only. |
| T-11-06-02 | Denial of Service | `EditorWithSidebar.dispose` force-save path | mitigate | Dispose cleanup-only; all controllable exits keep awaited `_forceSaveAsync()`. |
| T-quick-SC | Tampering | Package installs | accept | No package installs in this quick fix. |
</threat_model>

<verification>
Run focused tests and analyzer after all tasks:

```bash
cd /home/re/code/MuseFlow && flutter test test/features/manuscript/domain/manuscript_test.dart test/features/manuscript/domain/chapter_test.dart test/features/manuscript/presentation/manuscript_library_page_test.dart test/features/manuscript/presentation/editor_with_sidebar_test.dart
cd /home/re/code/MuseFlow && flutter analyze --no-fatal-infos
```

Also run source checks:

```bash
cd /home/re/code/MuseFlow && grep -n "as String\|as int\|DateTime.parse\|cast<String>" lib/features/manuscript/domain/manuscript.dart lib/features/manuscript/domain/chapter.dart
cd /home/re/code/MuseFlow && grep -n "_forceSaveSync\|_forceSaveAndCleanup\|forceSave()" lib/features/manuscript/presentation/editor_with_sidebar.dart
```

Expected: remaining grep hits, if any, are inside checked helper implementations or awaited/lifecycle-safe paths, not the unsafe lines identified in `11-SECURITY.md`.
</verification>

<success_criteria>
- All four open threats from `11-SECURITY.md` have code/test evidence that mitigates or explicitly bounds the risk.
- Domain tests prove corrupted `fromJson` inputs do not fail via raw unsafe casts/parsers.
- Create/settings UI enforce max title length and bounded custom genre behavior.
- `EditorWithSidebar.dispose()` has no unawaited save attempt.
- Focused tests pass and `flutter analyze --no-fatal-infos` has no analysis errors.
</success_criteria>

<output>
Create `/home/re/code/MuseFlow/.planning/quick/260606-mvg-fix-phase-11-security-mitigations-from-1/260606-mvg-SUMMARY.md` when done.
</output>
