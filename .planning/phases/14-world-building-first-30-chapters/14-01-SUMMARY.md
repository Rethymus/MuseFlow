---
phase: 14-world-building-first-30-chapters
plan: 01
subsystem: journey-testing
tags: [journey, world-building, xianxia, integration-test, fixtures]
dependency_graph:
  requires: []
  provides: [journey-container-factory, xianxia-fixtures, story-outline, world-building-test]
  affects: []
tech_stack:
  added: []
  patterns: [provider-container-factory, domain-fixtures, story-outline-data-class]
key_files:
  created:
    - test/journey/helpers/journey_container.dart
    - test/journey/helpers/xianxia_fixtures.dart
    - test/journey/helpers/story_outline.dart
    - test/journey/world_building_test.dart
  modified: []
decisions: []
metrics:
  duration: 4m
  completed: 2026-06-07
  tasks: 2
  files_created: 4
  files_modified: 0
  total_lines: 409
---

# Phase 14 Plan 01: Journey Test Infrastructure & World-Building Test Summary

Journey test infrastructure with real GLM API ProviderContainer factory, xianxia domain fixtures (4 characters, 1 world, 4 Skill rules), 30-chapter story outline, and JOURNEY-01 integration test covering entity creation and NameIndex verification.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Journey helper utilities (container, fixtures, outline) | 032e241 | test/journey/helpers/journey_container.dart, xianxia_fixtures.dart, story_outline.dart |
| 2 | World-building integration test (JOURNEY-01) | c82199f | test/journey/world_building_test.dart |
| 3 | Checkpoint: verify journey infrastructure | auto-approved | (verification only) |

## Key Artifacts

### journey_container.dart (77 lines)
- `createJourneyContainer()`: ProviderContainer with OpenAIAdapter (real, not Fake), activeProviderProvider (GLM config), activeApiKeyProvider overrides
- Opens 15 Hive boxes: manuscripts, chapters, token_audit, ai_providers, fragments, character_cards, world_settings, skill_documents, writing_stats, daily_writing_stats, achievement_badges, plot_nodes, foreshadowing_entries, graph_positions, guardian_annotations
- Does NOT open 'settings' box (SecureStorage fails in test context -- Pitfall 6)
- `cleanupJourneyContainer()`: disposes container and deletes Hive data from disk

### xianxia_fixtures.dart (144 lines)
- 4 CharacterCards: protagonist (林风), master (清虚真人), senior (苏雪晴), rival (赵天磊)
- 1 WorldSetting: 青云宗修仙界 with six-tier realm system (凡人->练气->筑基->金丹->元婴->化神)
- 4 SkillDocuments with isActive:true: 境界体系约束, 门派等级森严, 世界观禁忌, 能力限制

### story_outline.dart (50 lines)
- 30 chapter plot points covering mortal to Foundation Establishment arc
- Character names list: [林风, 清虚真人, 苏雪晴, 赵天磊]

### world_building_test.dart (138 lines)
- 4 test groups: Character Card Creation, World Setting Creation, Skill Document Creation, NameIndex Refresh
- Reads GLM_API_KEY from Platform.environment, skips gracefully when absent
- Verifies NameIndex.refresh() builds index containing character names after entity creation
- Uses `container.read(nameIndexServiceProvider.notifier).refresh()` per RESEARCH.md Pitfall 2

## Verification Results

- `dart analyze test/journey/` -- zero errors, zero warnings
- `flutter test test/journey/world_building_test.dart` -- all 4 tests skip with "GLM_API_KEY not set" (expected without API key)
- test/journey/ is independent from test/automation/ (Phase 13 infrastructure untouched)

## Deviations from Plan

None -- plan executed exactly as written.

## Auto-Approved Checkpoint

Task 3 (checkpoint:human-verify) auto-approved in auto mode. All verification criteria met:
- dart analyze passes with zero errors
- Test skips gracefully without API key
- No SecureStorage errors possible (settings box not opened)
- Journey directory separate from automation directory

## Self-Check: PASSED

All 5 files verified present. All 3 commits verified in git log.
