# Phase 7: 预设世界观模板库 - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers a bundled preset world-building template library for MuseFlow. Users can browse a curated genre gallery, preview template content, optionally customize it with AI based on their story concept, and create editable `WorldSetting` plus `CharacterCard` entities in the existing local knowledge base.

This phase does not create story structure entries from template foreshadowing arcs, does not add online template updates, and does not add community/custom template authoring.

</domain>

<decisions>
## Implementation Decisions

### 类型清单
- **D-01:** Use 14 main templates organized as main genre + popular sub-tags, not 14 flat one-off hot tags.
- **D-02:** The gallery must support `全部 / 男频 / 女频` grouped views. The `全部` view remains available for fast browsing.
- **D-03:** Template card titles use `主类｜默认热门方向` style, for example a stable main type plus a subtitle showing the default hot direction.
- **D-04:** Each main template carries 5-8 popular sub-tags. These tags are for discovery, search, and market flavor, not unlimited expansion.

### 模板内容
- **D-05:** Template preview uses full content in collapsed sections. Users can inspect all template material before creating entities without being overwhelmed by default.
- **D-06:** Each template contains one `WorldSetting` skeleton plus three `CharacterCard` prototypes.
- **D-07:** Foreshadowing patterns are represented as 3-5 arcs in `起点 -> 发展 -> 回收` form, not just loose tags.
- **D-08:** Each template includes three opening sample paragraphs split by entry style: scene-led, character-led, and suspense-led. This should align with Phase 8 opening generator categories.

### 创建流程
- **D-09:** `Use Template` creates an editable draft first; it must not immediately write to Hive.
- **D-10:** The draft confirmation page defaults all entities selected: one world setting plus three characters. Users may deselect individual entities before saving.
- **D-11:** Entity names start from template defaults but are editable in the draft flow.
- **D-12:** In Phase 7, only `WorldSetting` and `CharacterCard` entities are persisted. Foreshadowing arcs and opening samples stay as template preview/reference content and are not written to story structure.

### AI补全
- **D-13:** AI completion defaults to filling blank fields only, preserving preset template content and user edits.
- **D-14:** A secondary action may allow polishing the full draft after blank-field completion.
- **D-15:** The story concept input is available on the preview page and remains editable on the draft confirmation page.
- **D-16:** AI completion writes structured JSON into draft fields. Do not rely on Markdown parsing for field assignment.
- **D-17:** If AI completion fails, keep the original draft and allow manual editing plus save. AI failure must not block template creation.

### 数据来源
- **D-18:** Initial template content should be produced as AI drafts followed by manual review and revision before being bundled as assets.
- **D-19:** Template prose should combine neutral structural usefulness with platform heat signals. Avoid over-binding the template content to any single platform's wording.
- **D-20:** Manual review must check four quality gates per template: no obvious AI-scent prose, no genre-common-sense violations, valid field lengths/schema, and non-duplicative opening samples.
- **D-21:** Template data updates only with app releases. No online template update mechanism in Phase 7.

### 筛选排序
- **D-22:** The gallery channel filter uses a top segmented control for `全部 / 男频 / 女频`.
- **D-23:** Popular sub-tags are displayed and searchable but do not become filter chips in Phase 7.
- **D-24:** Default order is curated manually, prioritizing the most useful/easy-to-start templates first.
- **D-25:** Provide text search matching template name, subtitle, description, and sub-tags. Existing knowledge-base search behavior can guide the UX.

### 编辑粒度
- **D-26:** The draft confirmation page allows editing all fields of the selected `WorldSetting` and `CharacterCard` drafts.
- **D-27:** Draft entities are collapsed by default to keep the page usable, with full fields available when expanded.
- **D-28:** AI-completed fields should show source markers such as template default, AI completed, or user edited.
- **D-29:** After saving, show a creation result summary listing the new world setting and character cards, with navigation to the knowledge base.

### 模板元数据
- **D-30:** Template JSON should include full maintenance metadata such as `id`, independent schema version, channel, curated sort order, source/review notes, and review timestamp.
- **D-31:** Template schema version is independent from app version, e.g. `templateSchemaVersion: 1`.
- **D-32:** UI should expose only a light trust cue such as built-in/reviewed template. Do not expose detailed maintenance metadata in the creative flow.
- **D-33:** Phase 7 ships Chinese templates only, but the schema should reserve a language field for future use.

### Claude's Discretion
No user decisions were delegated to Claude during this discussion. Planners may choose implementation details that preserve the decisions above and the existing MuseFlow architecture.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product Scope
- `.planning/ROADMAP.md` — Phase 7 goal, success criteria, plan split, and v1.1 milestone boundary.
- `.planning/REQUIREMENTS.md` — TMPL-01 through TMPL-06 requirement definitions and v2 deferred template items.
- `.planning/PROJECT.md` — Core product value, local-first constraints, anti-AI-scent principle, and v1.1 milestone decisions.
- `.planning/STATE.md` — Current project state and carried research notes, including bundled JSON asset direction and Phase 7 content quality concern.

### Existing Code Anchors
- `lib/features/knowledge/domain/world_setting.dart` — Target world-setting entity fields and validation limits.
- `lib/features/knowledge/domain/character_card.dart` — Target character-card entity fields and validation limits.
- `lib/features/knowledge/infrastructure/world_setting_repository.dart` — Existing Hive persistence path for created world settings.
- `lib/features/knowledge/infrastructure/character_card_repository.dart` — Existing Hive persistence path for created character cards.
- `lib/features/knowledge/presentation/knowledge_base_page.dart` — Existing knowledge-base list/search UI patterns.
- `lib/features/knowledge/application/skill_generation_service.dart` — Existing AI generation pattern; useful reference, but Phase 7 completion must use structured JSON rather than Markdown parsing.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WorldSetting` already supports editable fields for description, rules, factions, geography, tech level, aliases, timestamps, JSON serialization, and context-string rendering.
- `CharacterCard` already supports editable fields for personality, appearance, backstory, aliases, timestamps, JSON serialization, and context-string rendering.
- `WorldSettingRepository.add` and `CharacterCardRepository.add` already generate UUIDs and persist to Hive boxes; template instantiation should reuse these rather than adding a separate storage path.
- `KnowledgeBasePage` already has tab/list/search patterns that can guide the gallery search and post-save knowledge-base navigation.

### Established Patterns
- Knowledge entities are immutable classes with `copyWith`, `toJson`, `fromJson`, validation in constructors, and Hive-backed repositories.
- The app prefers local bundled data and local persistence; Phase 7 template assets should follow bundled JSON under app assets, with no runtime network dependency.
- AI generation already streams through `OpenAIAdapter`, but current `SkillGenerationService` parses Markdown/JSON for skill documents. Template completion should be stricter and field-oriented.

### Integration Points
- New template feature should connect to existing knowledge repositories for final save.
- New template gallery can live as a new feature area or knowledge sub-route, but it must end by creating normal `WorldSetting` and `CharacterCard` records.
- AI completion should operate on draft data before persistence, preserving manual edits and allowing save after failure.

</code_context>

<specifics>
## Specific Ideas

- Card title pattern: `主类｜默认热门方向`.
- Channel filter labels: `全部 / 男频 / 女频`.
- Opening sample categories: scene-led, character-led, suspense-led.
- Foreshadowing arc expression: `起点 -> 发展 -> 回收`.
- Result summary should list created entities after save instead of silently jumping away.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 7-预设世界观模板库*
*Context gathered: 2026-06-04*
