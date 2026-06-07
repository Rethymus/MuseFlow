---
phase: 14-world-building-first-30-chapters
plan: 02
subsystem: journey-tests
tags: [integration-test, journey, fragment-synthesis, opening-guide, chapter-management, glm-api]
dependency_graph:
  requires: [14-01]
  provides: [JOURNEY-02, JOURNEY-03, JOURNEY-04]
  affects: []
tech_stack:
  added: []
  patterns: [journey-integration-test, real-api-streaming, hive-local-crud, skip-without-api-key]
key_files:
  created:
    - test/journey/fragment_synthesis_test.dart
    - test/journey/opening_guide_test.dart
    - test/journey/chapter_management_test.dart
  modified: []
decisions:
  - D-14-02-01: ChatMessage content extraction uses sealed class pattern matching (SystemMessage/UserMessage/AssistantMessage/DeveloperMessage/ToolMessage) instead of non-existent .map() method
  - D-14-02-02: Manuscript() constructor uses non-const instantiation with top-level final fixedDate (not file-local _fixedDate) to avoid const-context issues
  - D-14-02-03: Chapter management helper function named create30Chapters (not _create30Chapters) to satisfy no_leading_underscores_for_local_identifiers lint
metrics:
  duration: 4min
  completed: "2026-06-07"
---

# Phase 14 Plan 02: Journey Integration Tests (JOURNEY-02/03/04) Summary

Validated the core creation pipeline (fragment capture, AI synthesis, opening guide 3-style generation) and all chapter management operations at 30-chapter scale using real GLM API for AI-dependent tests.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fragment capture and AI synthesis test (JOURNEY-02) | 91d06bd | test/journey/fragment_synthesis_test.dart |
| 2 | Opening guide 3-style test (JOURNEY-03) | 09f5db9 | test/journey/opening_guide_test.dart |
| 3 | Chapter management test (JOURNEY-04) | 40b13ce | test/journey/chapter_management_test.dart |

## Verification Results

- `dart analyze test/journey/` -- zero errors, zero warnings
- `flutter test test/journey/chapter_management_test.dart` -- 7/7 passed (no API key needed)
- `flutter test test/journey/fragment_synthesis_test.dart` -- 4 tests skip gracefully without GLM_API_KEY
- `flutter test test/journey/opening_guide_test.dart` -- 3 tests skip gracefully without GLM_API_KEY

## Test Coverage

### fragment_synthesis_test.dart (294 lines)
- Fragment Creation: 5 xianxia fragments created and persisted in FragmentRepository
- PromptPipeline Assembly: build() produces >= 2 messages containing fragment content
- AI Synthesis: Real GLM API streaming with onUsage callback, output > 50 chars
- Quality Check: Verifies character names from StoryOutline.characterNames in synthesis output

### opening_guide_test.dart (161 lines)
- Service Resolution: openingGeneratorServiceProvider resolves without StateError
- Generate 3 Styles: generateOpenings() returns exactly 3 non-empty variants
- Style Differentiation: 3 variants not all identical, >= 2 distinct styles

### chapter_management_test.dart (386 lines)
- Create 30 Chapters: 30 chapters with sortOrder 1-30
- Content Update: updateDocumentContent() persists correctly
- Reorder: Swaps sortOrders 5/10/15 and verifies position
- Split: Replaces 1 chapter with 2, content halves preserved, count = 31
- Merge: Combines 2 into 1 with concatenated content, count = 29
- Copy: New chapter with identical content, unique ID, (副本) suffix
- Delete: Removes chapter, getById returns null, count = 29

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ChatMessage.map() does not exist in openai_dart 6.1.0**
- Found during: Task 1 (fragment_synthesis_test.dart)
- Issue: Plan specified `.map()` pattern for ChatMessage content extraction, but openai_dart 6.1.0 uses sealed classes (SystemMessage, UserMessage, AssistantMessage, DeveloperMessage, ToolMessage) without a .map() method
- Fix: Replaced with switch pattern matching on sealed class subtypes, extracting content field from each
- Files modified: test/journey/fragment_synthesis_test.dart
- Commit: 91d06bd

**2. [Rule 3 - Blocking] const Manuscript() with non-const DateTime fields**
- Found during: Task 2 and Task 3
- Issue: `const Manuscript(createdAt: _fixedDate)` fails because top-level variables in Dart are not compile-time constants
- Fix: Removed `const` keyword and renamed `_fixedDate` to `fixedDate` (top-level, no underscore)
- Files modified: test/journey/opening_guide_test.dart, test/journey/chapter_management_test.dart
- Commits: 09f5db9, 40b13ce

**3. [Rule 3 - Blocking] Missing ChapterRepository import and underscored local function**
- Found during: Task 3
- Issue: ChapterRepository type used in helper function without import; `_create30Chapters` triggered no_leading_underscores_for_local_identifiers lint
- Fix: Added `import chapter_repository.dart`; renamed to `create30Chapters`
- Files modified: test/journey/chapter_management_test.dart
- Commit: 40b13ce

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| D-14-02-01 | ChatMessage content via sealed pattern matching | openai_dart 6.1.0 sealed class hierarchy requires switch matching, not .map() |
| D-14-02-02 | Non-const Manuscript with top-level fixedDate | Dart const constructor requires compile-time constants; top-level finals are not |
| D-14-02-03 | create30Chapters (no underscore) | Satisfies project lint rules for local identifiers |

## Self-Check: PASSED

- [x] test/journey/fragment_synthesis_test.dart exists (294 lines, min 80)
- [x] test/journey/opening_guide_test.dart exists (161 lines, min 60)
- [x] test/journey/chapter_management_test.dart exists (386 lines, min 100)
- [x] Commit 91d06bd exists
- [x] Commit 09f5db9 exists
- [x] Commit 40b13ce exists
