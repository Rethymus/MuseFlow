# Phase 7: 预设世界观模板库 - Research

## RESEARCH COMPLETE

**Phase:** 7 - 预设世界观模板库
**Date:** 2026-06-04
**Question:** What do we need to know to plan this phase well?

## Scope Summary

Phase 7 adds a local, bundled template library that lets users browse 14 genre templates, preview world/character/foreshadowing/opening content, optionally AI-complete draft fields from a story concept, and save editable `WorldSetting` plus `CharacterCard` entities into the existing knowledge base.

The key boundary from CONTEXT.md is that Phase 7 persists only `WorldSetting` and `CharacterCard`. Foreshadowing arcs and opening samples remain template reference content and are not written to story-structure storage.

## Existing Code Patterns

### Knowledge Entities

- `WorldSetting` is an immutable domain entity with fields: `id`, `name`, `description`, `rules`, `factions`, `geography`, `techLevel`, `aliases`, `createdAt`, `updatedAt`.
- `CharacterCard` is an immutable domain entity with fields: `id`, `name`, `personality`, `appearance`, `backstory`, `aliases`, `createdAt`, `updatedAt`.
- Both entities validate field lengths and control characters in constructors, making template data validation essential before entity creation.
- Both repositories generate IDs and timestamps in `add`, so template drafts should use empty IDs until save.

### State Management

- The project uses `flutter_riverpod` with `AsyncNotifierProvider` for knowledge lists.
- Repositories are registered in `lib/core/presentation/providers.dart` as `FutureProvider`s that open Hive boxes.
- Template assets can follow the same provider style: a repository/service loaded through a provider and consumed by presentation widgets.

### Routing/UI

- `go_router` uses a `StatefulShellRoute.indexedStack` in `lib/app.dart`.
- Knowledge routes are nested below `/knowledge`, including `character/new`, `setting/new`, `skills`, and `skills/new`.
- Phase 7 should add template routes under the knowledge branch, for example `/knowledge/templates`, `/knowledge/templates/:id`, and `/knowledge/templates/:id/draft`.
- Current knowledge list UI uses simple Material widgets, search text field, tabs, `ListView.builder`, and existing route constants in `AppConstants`.

### AI Integration

- `SkillGenerationService` is a useful reference for OpenAI-compatible streaming, but it parses Markdown and optional JSON into `SkillDocument`.
- Phase 7 needs structured JSON field completion, not Markdown parsing, because template fields map directly to `WorldSetting` and `CharacterCard` draft fields.
- Existing active provider wiring is available through `activeProviderProvider`, `activeApiKeyProvider`, and `openaiAdapterProvider`.
- AI completion must be non-blocking for save: if completion fails, users can keep and save the draft manually.

## Recommended Data Model

Create a template-specific domain model under a new feature area, likely `lib/features/templates/`:

- `WorldTemplateLibrary`: root asset wrapper with `templateSchemaVersion`, `language`, `templates`.
- `WorldTemplate`: one main genre template with `id`, `channel`, `sortOrder`, `genreName`, `subtitle`, `description`, `iconName`, `tags`, `review`, `world`, `characters`, `foreshadowingArcs`, `openingSamples`.
- `TemplateChannel`: `male`, `female` with UI filter `all` handled at presentation layer.
- `WorldTemplateWorld`: source fields for a `WorldSetting` draft.
- `WorldTemplateCharacter`: source fields for a `CharacterCard` draft.
- `ForeshadowingArc`: `setup`, `development`, `payoff`.
- `OpeningSample`: `style` enum or string values `scene`, `character`, `suspense`, plus `text`.
- `TemplateReviewMetadata`: `sourceNote`, `reviewedAt`, `qualityChecks`.

The asset should be one deterministic JSON file for Phase 7, for example `assets/templates/world_presets/templates_zh.json`, registered in `pubspec.yaml`.

## Template Content Quality

CONTEXT.md locks the production process as AI draft plus manual review. The implementation should make this review checkable:

- Tests should parse all bundled templates and assert there are exactly 14 templates.
- Tests should assert 8 male-frequency and 6 female-frequency templates.
- Tests should assert every template has 5-8 tags, one world skeleton, exactly 3 character prototypes, 3-5 foreshadowing arcs, and 3 opening samples with styles `scene`, `character`, `suspense`.
- Tests should instantiate all template worlds and characters into domain entities to catch field length and control-character violations.
- Optional lightweight anti-AI-scent validation can check for banned generic phrases in template samples, but this should not replace human review.

## UI Architecture Recommendation

Keep the UI minimal and consistent with existing Material patterns:

- Gallery page: segmented control `全部 / 男频 / 女频`, search field, curated-order cards.
- Tags: shown on cards and included in search matching, but no tag chips as active filters in Phase 7.
- Preview page: full content in collapsed sections for world skeleton, three characters, foreshadowing arcs, and opening samples.
- Story concept input: available on preview and passed into draft page; draft page can edit it before AI completion.
- Draft page: selected entities default checked, all fields editable, entity panels collapsed by default, field source markers shown.
- Result page or result state: show the created world setting and character cards after save, with knowledge-base navigation.

## AI Completion Recommendation

Separate template completion from final persistence:

- Draft model stores `TemplateFieldSource.templateDefault`, `aiCompleted`, and `userEdited`.
- Completion service builds a strict JSON instruction and asks the model to return the same draft shape with only blank fields filled by default.
- A secondary polish action may allow all draft fields to be rewritten, but should preserve manual edits unless the user explicitly triggers polish.
- Completion parser should reject invalid JSON and surface an error while preserving current draft.
- Save service should persist current draft values whether AI completion succeeded or not.

## Risks and Pitfalls

- `pubspec.yaml` currently has no assets section. Plan 07-01 must add the template asset path and include a test or source assertion that the path is registered.
- Existing repositories `add` methods discard incoming `createdAt` and assign timestamps. Drafts should not depend on preserving template timestamps.
- Existing `WorldSetting`/`CharacterCard` constructors enforce field limits; bundled template tests must catch invalid content early.
- If plan 07-03 tries to persist foreshadowing arcs, it violates the phase boundary. Keep arcs as preview/reference only.
- If AI completion uses freeform Markdown, structured field assignment will be brittle. Use strict JSON and tests for parser failure paths.
- The worktree is currently dirty with unrelated changes. Executors must read current files before editing and avoid touching unrelated deleted/moved planning artifacts.

## Validation Architecture

Validation should sample both asset correctness and user-facing behavior:

- Domain/model tests for JSON parsing, channel counts, content completeness, and entity instantiation.
- Repository/service tests for asset loading and search/filter ordering.
- Widget tests for gallery segmented control, search behavior, preview collapsed sections, draft source markers, and result summary.
- Service/notifier tests for draft creation, selection/deselection, AI JSON completion success, invalid JSON failure, and save after AI failure.
- Full phase verification should run targeted template tests plus `flutter analyze lib/features/templates test/features/templates`.

## Research Output for Planner

Use the existing roadmap split:

- `07-01`: Template data model and bundled JSON assets.
- `07-02`: Genre gallery UI with filtering and preview.
- `07-03`: Template instantiation, draft editing/save flow, and AI completion.

Each plan should cite TMPL requirements and CONTEXT decisions by ID in `must_haves` so coverage gates can verify no decision was dropped.
