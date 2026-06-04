# Architecture Research: v1.1 创作体验升级

**Researched:** 2026-06-04
**Milestone:** v1.1 创作体验升级

## Existing Architecture Recap

```
lib/
├── core/                    # Core infrastructure
│   └── presentation/        # App shell, navigation, constants
├── features/
│   ├── editor/              # super_editor, floating toolbar
│   ├── knowledge/           # CharacterCard, WorldSetting, Skill system
│   ├── ai/                  # PromptPipeline, multi-provider adapters
│   ├── story_structure/     # PlotNode, Foreshadowing, Guardian
│   └── settings/            # App settings, banned phrases
└── shared/                  # Utilities, theme, constants
```

**Navigation:** go_router with `StatefulShellRoute.indexedStack` — 5 branches:
- `/capture` — Fragment capture
- `/editor` — Rich text editor
- `/knowledge` — Knowledge base (with sub-routes for characters, settings, skills)
- `/story-structure` — Story structure
- `/settings` — Settings (with sub-routes for AI providers, banned phrases)

## New Feature Integration Points

### Feature 1: 预设世界观模板库

**New domain entities:**
```dart
// lib/features/knowledge/domain/world_template.dart
class WorldTemplate {
  final String id;
  final String name;           // "修仙·凡人修真"
  final String genreId;        // "xianxia_cultivation"
  final String description;
  final String iconAsset;
  final WorldSettingSkeleton worldSkeleton;
  final List<CharacterArchetype> characterArchetypes;
  final List<ForeshadowingPattern> foreshadowingPatterns;
  final List<String> openingHooks;  // 3 sample opening paragraphs
  final bool isTrending;
}
```

**New infrastructure:**
```dart
// lib/features/knowledge/infrastructure/template_repository.dart
class TemplateRepository {
  Future<List<WorldTemplate>> loadAllTemplates();    // from assets/templates/
  Future<WorldTemplate?> getTemplateById(String id);
  Future<List<WorldTemplate>> getTrendingTemplates();
}
```

**New presentation:**
```dart
// lib/features/knowledge/presentation/template_gallery_page.dart
// Genre grid with filtering, trending badges
// One-click "使用模板" → creates WorldSetting + CharacterCards
```

**Integration with existing:**
- "使用模板" → calls existing `KnowledgeNotifier.createWorldSetting()` + `createCharacterCard()` with template data
- Templates instantiate real domain entities (WorldSetting, CharacterCard, SkillDocument)
- Navigation: sub-route under `/knowledge/templates`

**Template data storage:** `assets/templates/world_presets/{genre_id}.json` — bundled with app

---

### Feature 2: 故事弧可视化

**No new domain entities** — reads existing `PlotNode` and `ForeshadowingEntry`.

**Existing PlotNode fields used:**
- `causeNodeIds`, `consequenceNodeIds` → directional edges
- `relatedNodeIds` → lateral relationship edges
- `linkedForeshadowingIds` → foreshadowing arc edges (dashed)
- `structuralRole` (setup/development/turn/climax/resolution) → node color
- `writingStatus` (notStarted/drafting/complete/needsRevision) → node border style

**New presentation layer:**
```dart
// lib/features/story_structure/presentation/story_graph/
├── story_graph_page.dart          // Main page with canvas + toolbar
├── story_graph_canvas.dart        // CustomPainter or graphview widget
├── story_graph_controller.dart    // Riverpod Notifier for graph state
├── graph_node_widget.dart         // Node rendering
├── graph_edge_renderer.dart       // Connection line logic
└── graph_gesture_handler.dart     // Drag, tap, zoom, pan
```

**Navigation:** Sub-route under `/story-structure/graph`

---

### Feature 3: 开篇引导

**New domain:**
```dart
// lib/features/onboarding/domain/onboarding_state.dart
class OnboardingState {
  final int currentStep;          // 0-3
  final String? selectedGenreId;
  final String? worldName;
  final String? characterName;
  final bool isCompleted;
}
```

**New presentation:**
```dart
// lib/features/onboarding/presentation/
├── onboarding_wizard_page.dart      // Main wizard with PageView
├── steps/
│   ├── genre_selection_step.dart    // Genre grid (reuses template gallery)
│   ├── world_creation_step.dart     // Name input + template auto-load
│   ├── character_creation_step.dart // Name + role + AI suggestions
│   └── opening_generation_step.dart // AI generates 3 openings
└── onboarding_notifier.dart         // Riverpod state
```

**Navigation:** Full-screen route `/onboarding` with go_router redirect guard
**First-run detection:** `appSettings` Hive box key `onboardingCompleted`
**Dependencies:** Templates feature (reuses TemplateRepository)

---

### Feature 4: 写作数据统计

**New domain entities:**
```dart
// lib/features/analytics/domain/
├── writing_session.dart      // One editing session
├── daily_stats.dart          // Aggregated daily stats
└── project_stats.dart        // Per-project aggregated stats

class WritingSession {
  final String id;
  final String projectId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int wordsAdded;
  final int wordsDeleted;
  final int aiInteractions;
}

class DailyStats {
  final DateTime date;
  final int netWords;
  final int sessionCount;
  final int aiInteractionCount;
  final Duration totalEditingTime;
}
```

**New feature module:**
```dart
// lib/features/analytics/
├── application/
│   ├── stats_collector.dart      // Editor hooks for data collection
│   ├── stats_aggregator.dart     // Session → daily aggregation
│   └── stats_notifier.dart       // Riverpod provider
├── domain/                       // WritingSession, DailyStats, ProjectStats
├── infrastructure/
│   ├── stats_repository.dart     // Hive box CRUD
│   └── stats_box.dart            // Hive box definitions
└── presentation/
    ├── global_stats_page.dart     // All-projects overview
    ├── project_stats_page.dart    // Single project detail
    └── widgets/                   // fl_chart components
```

**Data collection hooks:**
- Editor word count delta: hook into super_editor's document change events
- AI interaction count: increment in AI toolbar action handlers
- Session tracking: timer in editor page initState/dispose

**Navigation:** Sub-route under `/settings/stats`

**Hive storage:**
- `writingStats` box: individual sessions (auto-pruned after 365 days)
- `dailyStats` box: aggregated daily data

---

## Navigation Structure Changes

### Proposed (v1.1):
```
StatefulShellRoute.indexedStack
├── /capture
├── /editor
├── /knowledge
│   ├── /templates         ← NEW
│   ├── /character/new, /character/:id
│   ├── /setting/new, /setting/:id
│   └── /skills, /skills/new
├── /story-structure
│   └── /graph             ← NEW
└── /settings
    ├── /ai-providers
    ├── /banned-phrases
    └── /stats             ← NEW

/onboarding               ← NEW (full-screen, no shell)
```

---

## Suggested Build Order

| Phase | Feature | Rationale |
|-------|---------|-----------|
| **Phase 7** | 预设世界观模板库 | Foundation. No complex dependencies. Adds domain + repository + gallery UI. |
| **Phase 8** | 开篇引导 | Depends on templates. Reuses template gallery. Creates onboarding flow. |
| **Phase 9** | 写作数据统计 | Independent. Adds data collection + Hive storage + fl_chart. |
| **Phase 10** | 故事弧可视化 | Most complex. Custom rendering + gestures + performance. Data exists. |

**Dependency chain:** Phase 7 → Phase 8. Phases 9 and 10 are independent.

---
*Architecture researched: 2026-06-04 for v1.1 milestone*
