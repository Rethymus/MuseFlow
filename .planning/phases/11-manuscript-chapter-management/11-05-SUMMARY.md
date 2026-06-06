---
phase: 11-manuscript-chapter-management
plan: 05
subsystem: integration
tags: [export, template, ai-pipeline, startup-purge, chapter-aware]
dependency_graph:
  requires: [11-04]
  provides: [chapter-aware-export, template-chapter-skeleton, chapter-context-middleware, startup-purge]
  affects: [export_bundle, export_service, export_dialog, template_draft, template_instantiation_service, prompt_pipeline, editor_prompt_pipeline, main]
tech_stack:
  added: []
  patterns: [chapter-aware-export, middleware-injection, startup-lifecycle]
key_files:
  created:
    - lib/features/editor/application/chapter_context_middleware.dart
    - test/features/manuscript/domain/chapter_aware_export_test.dart
    - test/features/manuscript/application/template_chapter_test.dart
    - test/features/manuscript/application/chapter_context_middleware_test.dart
  modified:
    - lib/features/story_structure/domain/export_bundle.dart
    - lib/features/story_structure/application/export_service.dart
    - lib/features/story_structure/presentation/export_dialog.dart
    - lib/features/templates/application/template_instantiation_service.dart
    - lib/features/templates/application/template_draft.dart
    - lib/features/ai/application/prompt_pipeline.dart
    - lib/features/editor/application/editor_prompt_pipeline.dart
    - lib/core/presentation/providers.dart
    - lib/main.dart
    - test/features/templates/application/template_instantiation_service_test.dart
    - test/features/templates/presentation/template_draft_page_test.dart
decisions:
  - "ExportBundle.chapters defaults to empty list, backward-compatible with existing code"
  - "ChapterContextMiddleware appends as system message rather than modifying existing system message"
  - "TemplateDraft.chapterTitles defaults to genre-appropriate Chinese titles"
  - "ManuscriptPurgeService on startup opens boxes directly rather than using providers (main.dart is not a ConsumerWidget)"
metrics:
  duration: 9m 32s
  completed: 2026-06-06
  tasks: 2
  files_modified: 11
  files_created: 4
  tests_added: 18
---

# Phase 11 Plan 05: Integration Wiring Summary

Chapter-aware export pipeline, template chapter skeletons, AI chapter context injection, and manuscript purge on startup.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend ExportBundle with chapters, chapter-aware export, ExportDialog | 98c8e94 | export_bundle.dart, export_service.dart, export_dialog.dart, chapter_aware_export_test.dart |
| 2 | Template chapter skeletons, ChapterContextMiddleware, purge on startup | db3e18c | template_instantiation_service.dart, template_draft.dart, prompt_pipeline.dart, editor_prompt_pipeline.dart, chapter_context_middleware.dart, main.dart, providers.dart, 3 test files |

## Key Changes

### Task 1: Chapter-Aware Export (D-23)
- **ExportBundle**: Added `List<ChapterExport> chapters` field with default `const []`. Updated `fromJson`/`toJson`, equality, and hashCode. Fixed null-safety in `fromJson` for all list fields.
- **ExportService**: `buildMarkdown` produces `## {title}` headers when chapters non-empty, falls back to `manuscriptText` otherwise. `buildTxt` uses plain text separators without Markdown headers.
- **ExportDialog**: Shows "包含 N 个章节" info line when `bundle.chapters.isNotEmpty`.

### Task 2: Template Skeletons + AI Context + Startup Purge (D-20, D-24, D-21)
- **TemplateInstantiationService**: Accepts `ChapterRepository`, creates chapter skeleton entities when `manuscriptId` is provided with titles from `TemplateDraft.chapterTitles`.
- **TemplateDraft**: Added `manuscriptId` (String?) and `chapterTitles` (defaults to `['世界观铺垫', '角色登场', '主线开启']`).
- **TemplateCreationResult**: Added `chapters` field of type `List<Chapter>`.
- **PromptContext**: Added `previousChapterSummary` and `nextChapterSummary` fields with default null. All copyWith-style methods updated.
- **ChapterContextMiddleware**: New middleware that injects adjacent chapter summaries into system message (`上一章节摘要：` / `下一章节摘要：`).
- **EditorPromptPipeline**: Inserts `ChapterContextMiddleware` between `ContextAnchorMiddleware` and `EditorOperationMiddleware`.
- **main.dart**: Calls `ManuscriptPurgeService.purgeExpired()` after Hive initialization, wrapped in try-catch with `debugPrint` logging.
- **providers.dart**: Updated `templateInstantiationServiceProvider` to inject `ChapterRepository`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Input Validation] Fixed null-safety in ExportBundle.fromJson**
- **Found during:** Task 1
- **Issue:** `fromJson` used `as List<dynamic>` casts on JSON keys that could be missing, causing `Null is not a subtype of List<dynamic>` errors
- **Fix:** Changed all list field casts to use `as List<dynamic>?` with null-coalescing to `const []`
- **Files modified:** lib/features/story_structure/domain/export_bundle.dart
- **Commit:** 98c8e94

**2. [Rule 1 - Bug] Fixed existing test call sites for new TemplateInstantiationService constructor parameter**
- **Found during:** Task 2
- **Issue:** Existing tests in template_instantiation_service_test.dart and template_draft_page_test.dart failed because they did not include the new `chapterRepository` parameter
- **Fix:** Added `ChapterRepository` with test Hive box to both test files
- **Files modified:** test/features/templates/application/template_instantiation_service_test.dart, test/features/templates/presentation/template_draft_page_test.dart
- **Commit:** db3e18c

## Verification Results

- 652 tests passed across manuscript, story_structure, templates, AI, and editor test suites
- Zero regressions in existing tests
- 18 new tests added (9 for chapter-aware export, 3 for template chapters, 6 for chapter context middleware)

## Known Stubs

None -- all fields are wired to real data sources.

## Threat Flags

No new security-relevant surface introduced beyond what the threat model covers. All changes operate on local-only user data.

## Self-Check: PASSED

- All 13 key files verified present on disk
- All 3 commits (98c8e94, db3e18c, db01859) verified in git log
- 652 tests passed with zero regressions
