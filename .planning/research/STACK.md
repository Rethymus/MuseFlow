# Technology Stack -- v1.1 Milestone Additions

**Project:** MuseFlow -- AI-assisted creative writing tool (Flutter Windows + Android)
**Researched:** 2026-06-04
**Flutter version (local):** 3.44.0 stable / Dart 3.12.0
**Scope:** NEW packages only. Existing stack (super_editor, Riverpod, Hive CE, openai_dart/anthropic_sdk_dart/ollama_dart, go_router, window_manager) is validated and unchanged.

---

## Overview

The v1.1 milestone adds 4 features to the shipped v1.0 MVP. This document covers ONLY the new technology additions needed. The existing stack in the v1.0 STACK.md remains the foundation.

New capabilities required:
1. **Interactive graph rendering** -- story arc visualization with draggable nodes, zoom/pan, connection lines
2. **Data visualization charts** -- writing analytics with trend lines, bar charts, statistics dashboards
3. **Template data loading** -- YAML/JSON world-building preset packs bundled as assets
4. **Onboarding wizard UI** -- first-run experience and AI opening generator

Every new addition is evaluated against the Windows <100MB install constraint.

---

## New Dependencies

### Data Visualization (Writing Analytics)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **fl_chart** | ^1.2.0 | LineChart, BarChart, PieChart for writing analytics | **The standard Flutter chart library.** 10K+ GitHub stars, actively maintained, zero native dependencies (pure Dart rendering via CustomPainter). LineChart for word count trends over time, BarChart for daily/weekly writing speed, PieChart for AI vs human text ratio. Built-in touch interactions, tooltips, animations, and `FlTransformationConfig` for pan/zoom on line charts. Min Flutter 3.27.4 -- compatible with our 3.44.0. |

**Why fl_chart over alternatives:**

| Criterion | fl_chart | Syncfusion Flutter Charts | Victory Flutter |
|-----------|----------|--------------------------|-----------------|
| License | MIT (free) | Community license has restrictions for commercial use | MIT |
| Package size impact | ~200KB (pure Dart) | Heavy -- pulls in Syncfusion ecosystem | Moderate |
| Native dependencies | None | None | None |
| Customization | Very high -- every element configurable | Very high but verbose API | Moderate |
| Animations | Built-in, implicit animations | Built-in | Limited |
| Windows support | Full | Full | Full |
| Maintenance | Active, frequent releases | Commercial backing | Less active |
| Install budget | Fits <100MB | Risky for <100MB constraint | Fits |

Syncfusion is overkill for the 3-4 chart types needed and risks the 100MB install budget. fl_chart is the proven lightweight choice.

**Confidence:** HIGH -- verified via `flutter pub add --dry-run` (resolves 1.2.0), pub.dev page, Context7 docs, changelog confirming Flutter 3.27.4 min.

---

### Interactive Graph Rendering (Story Arc Visualization)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **graphview** | ^1.5.1 | Interactive graph visualization for story arc nodes | **The only mature Flutter graph library.** Supports FruchtermanReingold (force-directed layout ideal for plot node networks), Sugiyama (layered/hierarchical), custom node widgets via builder pattern, node dragging via `setFocusedNode` + position update, InteractiveViewer integration for zoom/pan, edge painting with custom colors/styles per connection, animated transitions. 1.5.1 adds GraphViewController with jumpToNode, animateToNode, zoomToFit, and expand/collapse. |

**Why graphview over raw CustomPainter:**

| Criterion | graphview | Custom CustomPainter |
|-----------|-----------|---------------------|
| Layout algorithms | Built-in: FruchtermanReingold, Sugiyama, BuchheimWalker, Circle, Balloon, Radial | Must implement from scratch -- force-directed layout is non-trivial |
| Node rendering | Widget builder pattern -- any Flutter widget as a node | Must paint everything manually on canvas |
| Interaction | Node tap, drag, focus, expand/collapse, animated transitions | All hit-testing and gesture handling must be custom |
| Zoom/Pan | InteractiveViewer integration built-in | Must implement matrix transforms manually |
| Edge rendering | Multiple renderers (TreeEdgeRenderer, ArrowEdgeRenderer) with per-edge color/style | Must implement Bezier/straight line rendering with arrow heads |
| Development time | Days | Weeks |
| Testability | High -- widget-based nodes testable in widget tests | Low -- canvas painting requires golden tests |
| Maintenance burden | Library handles edge cases (overlapping, crossing reduction) | Every edge case is custom code to maintain |

The story arc visualization maps directly to graphview's data model:
- **PlotNode** -> `Node.Id(plotNodeId)` with a builder that renders node title, structural role badge, writing status color
- **causeNodeIds/consequenceNodeIds** -> `graph.addEdge()` with directional arrows
- **relatedNodeIds** -> `graph.addEdge()` with dashed line style
- **linkedForeshadowingIds** -> Dotted edges with distinct color

Force-directed layout (FruchtermanReingold) is ideal because plot nodes do not form a clean tree -- they have cause/consequence chains AND lateral relationships AND foreshadowing links. Tree layouts would force an artificial hierarchy.

**Confidence:** HIGH -- verified via `flutter pub add --dry-run` (resolves 1.5.1), pub.dev page with full API documentation, Context7 docs confirming builder pattern, node dragging, and InteractiveViewer integration.

---

### Template Data Loading (World-Building Presets)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **yaml** (transitive) | 3.1.3 | Parse YAML template files | Already in dependency tree (transitive via build_runner, json_serializable, etc.). No new dependency needed. Dart's `yaml` package parses YAML into `YamlMap`/`YamlList`, convertible to standard Map/List. |
| **json_serializable** (existing) | ^6.14.0 | Generate fromJson/toJson for template models | Already in dev_dependencies. Template data models will use the same pattern as existing domain entities. |

**Template storage strategy:**

Templates are **bundled as assets** (not fetched from a server -- local-first, offline-ready, privacy-preserving).

```
assets/
  templates/
    world_presets/
      xuanhuan.json      # Full preset pack
      xianxia.json
      wuxia.json
      urban.json
      scifi.json
      ...
```

JSON (not YAML) is the better choice for template data because:
1. **json_serializable** is already in the project -- template models get free serialization
2. **Consistency** -- every domain entity (PlotNode, CharacterCard, SkillDocument) uses JSON
3. **No parser needed** -- `dart:convert` is built-in, `yaml` requires an extra parse step
4. **Editor tooling** -- JSON has better editor support for large structured data files
5. **Validation** -- JSON schemas can validate template files at build time

Template data is loaded via `rootBundle.loadString()` (for read-only bundled templates) and stored in Hive boxes after user customization (for user-modified copies).

**No new package needed.** Use existing `json_annotation` + `json_serializable` + `dart:convert` + Hive CE.

**Confidence:** HIGH -- yaml 3.1.3 verified in `flutter pub deps`, json_serializable already in pubspec.yaml, rootBundle is Flutter standard API.

---

### Onboarding Wizard UI

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Flutter Stepper** (built-in) | N/A | Multi-step wizard for first-run experience | Built-in Material widget, enhanced in Flutter 3.44 with customizable header/content padding. Sufficient for a linear wizard (select genre -> name project -> configure AI provider -> done). |
| **Flutter PageView** (built-in) | N/A | Page-based navigation for wizard steps | More flexible than Stepper for custom layouts. PageController manages state, supports animated transitions. Used for non-linear wizard flows where steps may vary. |

**Why no dedicated onboarding package:**

Packages like `introduction_screen` or `flutter_onboarding_slider` add dependency weight for functionality easily built with PageView + a few custom widgets. The wizard has specific MuseFlow logic (genre selection triggers template load, AI provider test, opening generation) that generic packages cannot handle without heavy customization. Building with built-in widgets gives full control.

**Onboarding state storage:** Use existing `appSettings` Hive box with a `onboardingCompleted` boolean key. No new storage needed.

**Confidence:** HIGH -- Stepper and PageView are Flutter SDK built-ins, verified via Context7 Flutter docs confirming 3.44 Stepper enhancements.

---

## What NOT to Add

| Technology | Why NOT | What to Use Instead |
|------------|---------|-------------------|
| **syncfusion_flutter_charts** | Commercial license restrictions. Heavy package that risks the 100MB Windows install constraint. Overkill for 3-4 chart types. | fl_chart |
| **victory_flutter** | Less actively maintained than fl_chart. Smaller community. No clear advantage for our use case. | fl_chart |
| **introduction_screen** | Generic onboarding carousel. Cannot handle MuseFlow-specific wizard logic (AI provider test, genre-triggered template load). Adds a dependency for trivial PageView wrapping. | Flutter PageView + Stepper |
| **flutter_onboarding_slider** | Same as above -- too generic, adds unnecessary dependency. | Flutter PageView |
| **graphview alternatives** (none exist) | There is no other mature Flutter graph visualization library. graphview is the only option with layout algorithms, custom nodes, and interaction support. | graphview |
| **CustomPainter from scratch** | Implementing force-directed layout, node hit-testing, edge rendering, zoom/pan transforms, and animated transitions from scratch would take weeks and be a maintenance burden. graphview handles all of this. | graphview |
| **shared_preferences** | Onboarding state is a single boolean flag. Goes in existing `appSettings` Hive box. Adding shared_preferences creates a second key-value store alongside Hive, which is confusing. | Hive CE `appSettings` box |
| **yaml for template files** | YAML would add a non-standard data format alongside the JSON used everywhere else. JSON templates with json_serializable is consistent with existing patterns. | JSON with json_serializable |

---

## New Storage Patterns

### Writing Statistics (New Hive Box)

```
Boxes (new):
  - writingStats      -> { statId: WritingSession }
    Fields: date, projectId, wordCount, wordsAdded, wordsDeleted,
            aiAssistedCount, sessionDurationMinutes, timestamp
  - dailyStats        -> { dateKey: DailyAggregate }
    Fields: date, totalWordsWritten, totalSessions, totalAiUsage,
            averageSpeed (words/min), projectId -> wordCount map
```

Writing stats are append-only time series data. Each writing session creates a `WritingSession` record. Daily aggregates are computed from sessions and cached in `dailyStats` for fast dashboard rendering.

Aggregate queries (total words across all projects, monthly trends) scan `dailyStats` which has one entry per day. This is efficient for the expected data volume (hundreds of entries, not millions).

### Template Data (Asset Bundle + Hive Cache)

```
Boxes (new):
  - worldPresets      -> { presetId: WorldPreset }
    Populated on first load from asset bundle JSON files.
    User-customized copies stored here with isModified flag.
```

Bundled templates are read-only. When a user customizes a template, a copy is created in the `worldPresets` Hive box with `isModified: true` and `sourcePresetId` pointing to the original. This preserves the original template for reference while allowing user modifications.

### Onboarding State (Existing Box)

```
Boxes (existing):
  - appSettings       -> add key: 'onboardingCompleted' (bool)
                         add key: 'firstRunDate' (DateTime ISO string)
```

No new box needed. Onboarding state is two keys in the existing app settings box.

---

## Integration Points with Existing Stack

### Story Arc Visualization + PlotNode (Existing)

The graphview integration maps directly to the existing `PlotNode` model:

```dart
// PlotNode already has:
//   causeNodeIds, consequenceNodeIds, relatedNodeIds, linkedForeshadowingIds
//   structuralRole (setup/development/turn/climax/resolution)
//   writingStatus (notStarted/drafting/complete/needsRevision)

// Mapping to graphview:
final graph = Graph()..isTree = false;  // plot nodes are NOT a tree

for (final node in plotNodes) {
  graph.addNode(Node.Id(node.id));
}
for (final node in plotNodes) {
  for (final causeId in node.causeNodeIds) {
    graph.addEdge(
      Node.Id(causeId), Node.Id(node.id),
      paint: Paint()..color = Colors.blue,  // causal chain
    );
  }
  for (final relatedId in node.relatedNodeIds) {
    graph.addEdge(
      Node.Id(node.id), Node.Id(relatedId),
      paint: Paint()..color = Colors.grey..strokeWidth = 1,  // lateral
    );
  }
}
```

The existing `PlotNodeRepository` (Hive-based) provides all CRUD operations. The graph visualization is a read-only view with drag-to-reposition. Node position persistence requires adding `positionX`/`positionY` fields to PlotNode (or a separate mapping box).

### Writing Analytics + Editor (Existing)

Word count tracking hooks into the existing editor pipeline:
- `super_editor` provides `EditTransaction` events that can be counted for words added/deleted
- AI-assisted text changes are already tracked via `DiffState` and `ProvenanceAttribution`
- Session tracking starts when the editor page is mounted and ends on dispose

### Template System + Skill System (Existing)

World-building presets map directly to the existing `SkillDocument` and `WorldSetting` models:
- A full preset pack is a bundle of pre-populated `SkillDocument` + `CharacterCard` + `WorldSetting` entities
- When a user selects a preset, entities are created in their knowledge base via existing repositories
- The existing `SkillSections` structure (powerHierarchy, factionRelations, rules, taboos, terminology) is populated by the preset

### Onboarding + go_router (Existing)

First-run detection uses `go_router` redirect guards:

```dart
GoRouter(
  redirect: (context, state) {
    final onboardingDone = /* read from appSettings box */;
    if (!onboardingDone && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
)
```

---

## Installation

```bash
# NEW packages for v1.1 milestone
flutter pub add fl_chart       # Writing analytics charts
flutter pub add graphview      # Story arc interactive graph

# No other new packages needed -- yaml is transitive, Stepper/PageView are built-in
# json_serializable and hive_ce are already installed
```

### Asset bundle configuration (pubspec.yaml addition)

```yaml
flutter:
  assets:
    - assets/templates/world_presets/
```

---

## Install Budget Impact

| Package | Estimated Size Impact | Notes |
|---------|----------------------|-------|
| fl_chart | ~200KB | Pure Dart, no native code, no assets |
| graphview | ~50KB | Pure Dart, no native code |
| Template JSON assets | ~100KB total | ~10KB per genre preset, 8-10 genres |
| **Total new impact** | **~350KB** | Well within 100MB constraint |

Current Windows build estimated at ~60-70MB (Flutter engine + super_editor + existing deps). Adding 350KB leaves significant headroom under 100MB.

---

## Sources

| Source | Confidence | What It Verified |
|--------|------------|------------------|
| `flutter pub add --dry-run` (live) | HIGH | fl_chart 1.2.0 and graphview 1.5.1 resolve cleanly with Flutter 3.44 |
| pub.dev / fl_chart | HIGH | Version 1.2.0, MIT license, min Flutter 3.27.4, no native deps |
| pub.dev / graphview | HIGH | Version 1.5.1, MIT license, GraphViewController API, layout algorithms |
| Context7 / fl_chart docs | HIGH | LineChart, BarChart, PieChart API, FlTransformationConfig for pan/zoom |
| Context7 / graphview docs | HIGH | Builder pattern, node dragging, FruchtermanReingoldAlgorithm, edge rendering |
| Context7 / Flutter docs | HIGH | Stepper widget enhanced in 3.44, PageView API |
| `flutter pub deps` (live) | HIGH | yaml 3.1.3 already transitive in dependency tree |
| Existing codebase analysis | HIGH | PlotNode model fields, PlotNodeRepository pattern, SkillDocument structure |

---

## Chinese Web Novel Genre Taxonomy (for Template Presets)

**Confidence:** MEDIUM -- based on domain knowledge of Chinese web novel platforms. Should be validated by browsing 起点/番茄 category pages during implementation.

The top genres on Qidian (起点中文网) and Fanqie (番茄小说) that map to world-building presets:

| Genre | Chinese | Key World-Building Elements | Preset Complexity |
|-------|---------|---------------------------|-------------------|
| Xuanhuan (Eastern Fantasy) | 玄幻 | Cultivation levels, elemental systems, beast realms, tournament arcs | High -- full preset |
| Xianxia (Immortal Cultivation) | 仙侠 | Dao/immortality system, heavenly tribulations, spiritual energy, pill refining | High -- full preset |
| Wuxia (Martial Arts) | 武侠 | Martial arts schools, jianghu politics, weapon systems, chivalry codes | Medium |
| Urban (Modern City) | 都市 | Company/power hierarchies, modern technology, social dynamics | Medium |
| Sci-Fi (Science Fiction) | 科幻 | Tech trees, space colonization, AI/robot rules, physics constraints | High -- full preset |
| Historical | 历史 | Dynasty systems, court politics, military ranks, cultural customs | Medium |
| Fantasy (Western) | 奇幻 | Magic systems, racial hierarchies, guild structures, deity pantheons | High -- full preset |
| E-sports / Gaming | 游戏 | Game class systems, skill trees, guild mechanics, tournament brackets | Medium |
| Military | 军事 | Rank systems, unit structures, strategic doctrines, technology eras | Medium |
| Suspense / Thriller | 悬疑 | Clue structures, psychological profiles, timeline management | Low -- lightweight template |

Priority presets (most popular on both platforms): Xuanhuan, Xianxia, Urban, Sci-Fi, Wuxia.

Each full preset contains: SkillSections (powerHierarchy, factionRelations, rules, taboos, terminology) + sample CharacterCard templates + WorldSetting template with geography and techLevel.

---

## Chinese Novel Genre Data Sources

**Confidence:** LOW -- web search API was unavailable during research. Must be verified during implementation.

Recommended sources for genre category structures:

| Source | URL | Use |
|--------|-----|-----|
| Qidian (起点中文网) | `www.qidian.com` | Category navigation -- browse all genre classifications |
| Fanqie (番茄小说) | `fanqienovel.com` | Category pages -- cross-reference with Qidian for coverage |
| Qidian ranking pages | `www.qidian.com/rank/` | Popularity data to prioritize which genres get full presets |

The genre taxonomy above covers the top categories. During implementation, browse these sites to:
1. Verify the genre list is complete and current
2. Get sub-genre classifications (e.g., 玄幻 splits into 异世大陆, 东方玄幻, etc.)
3. Identify trending genres that may warrant additional presets
