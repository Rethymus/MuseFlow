# Research Summary: v1.1 创作体验升级

**Project:** MuseFlow 灵韵
**Milestone:** v1.1 创作体验升级
**Researched:** 2026-06-04
**Confidence:** HIGH

## Executive Summary

v1.1 adds 4 features to the shipped v1.0 MVP: world-building templates, story arc visualization, onboarding wizard, and writing statistics. Research confirms all 4 features are achievable with the existing Flutter/Riverpod/Hive stack plus 2 new packages. Total new package size is ~350KB, well within the 100MB Windows install constraint.

**Key finding:** The Stack researcher discovered `graphview ^1.5.1` which provides force-directed layout, node dragging, zoom/pan, and edge rendering — features that would take weeks to build with raw CustomPainter. This challenges the initial preference for custom canvas and should be evaluated before implementation.

## Stack Additions

| Package | Version | Purpose | Size Impact |
|---------|---------|---------|-------------|
| **fl_chart** | ^1.2.0 | LineChart, BarChart, PieChart for writing analytics | ~200KB |
| **graphview** | ^1.5.1 | Interactive graph for story arc visualization | ~50KB |
| Template JSON assets | bundled | Genre preset data | ~100KB |

**No other new packages needed.** Onboarding uses built-in PageView/Stepper. Template loading uses existing json_serializable + dart:convert. Stats storage uses Hive CE.

## Feature Categories

### Templates (Phase 7) — Medium Complexity
- **Table stakes:** Genre grid, one-click instantiation, editable entities, AI-assisted completion
- **Differentiators:** Genre-specific foreshadowing patterns, opening hook samples, trending badges
- **Genre scope:** 14 primary genres (8 男频 + 6 女频) curated from 起点/番茄 platforms
- **Anti-features:** No community sharing, no user-created templates, no internet updates

### Onboarding (Phase 8) — Medium Complexity
- **Table stakes:** First-run wizard (4 steps: genre → world → character → opening), skip option
- **Differentiators:** AI opening generator (3 styles: 场景切入, 人物切入, 悬念切入)
- **Dependencies:** Templates feature (reuses TemplateRepository in wizard step 1)

### Analytics (Phase 9) — Medium-Low Complexity
- **Table stakes:** Total words, writing streak, AI assist ratio, session duration
- **Differentiators:** fl_chart visualizations (trends, daily bars, AI pie), milestone badges
- **New storage:** 2 Hive boxes (writingStats, dailyStats) with 365-day auto-prune

### Visualization (Phase 10) — High Complexity
- **Table stakes:** Node graph from PlotNode data, zoom/pan, color-coded roles
- **Differentiators:** Drag-to-reorder, foreshadowing arc lines, minimap, export as image
- **Critical decision:** graphview library vs custom CustomPainter

## Key Technical Decision: graphview vs CustomPainter

The user initially chose Custom Flutter Canvas. The Stack researcher discovered graphview ^1.5.1 which provides:

| Criterion | graphview | CustomPainter |
|-----------|-----------|---------------|
| Layout algorithms | Built-in (FruchtermanReingold, Sugiyama) | Must implement from scratch |
| Node rendering | Widget builder (any Flutter widget) | Manual canvas painting |
| Interaction | Built-in tap, drag, focus | Custom hit-testing + gestures |
| Zoom/Pan | InteractiveViewer integration | Manual matrix transforms |
| Edge rendering | Multiple renderers with per-edge style | Manual Bezier + arrows |
| Development time | Days | Weeks |
| CJK text | Standard Flutter widgets in nodes | TextPainter measurement needed |
| Testability | Widget tests | Golden tests |

**Recommendation:** Use graphview. The performance concern (Pitfall #1) applies to both approaches but graphview handles layout complexity that CustomPainter would require weeks to implement.

## Critical Pitfalls

| # | Risk | Level | Phase | Mitigation |
|---|------|-------|-------|------------|
| 1 | Graph rendering perf with 100+ nodes | 🔴 HIGH | 10 | Virtual viewport, debounced layout |
| 2 | Template data quality/authenticity | 🟡 MED | 7 | AI-generated + manual review, 8-10 genres first |
| 3 | Onboarding wizard UX traps | 🟡 MED | 8 | Every step delivers value, prominent skip |
| 4 | Stats collection editor impact | 🟡 MED | 9 | Debounced collection (30s), in-memory counters |
| 5 | AI opening quality vs core value | 🟡 MED | 8 | 3 distinct strategies, anti-AI-scent middleware |

## Suggested Phase Order

| Phase | Feature | Why |
|-------|---------|-----|
| 7 | Templates | Foundation. No complex deps. |
| 8 | Onboarding | Depends on templates. |
| 9 | Analytics | Independent of 8 and 10. |
| 10 | Visualization | Most complex. Independent of 9. |

Phases 9 and 10 can run in parallel after Phase 8.

## Open Questions for Requirements Phase

1. **graphview vs CustomPainter** — User initially chose CustomPainter but research shows graphview saves weeks. Decision needed.
2. **Analytics as settings sub-route vs new main tab** — How prominently should stats be displayed?
3. **Template count for v1.1** — Start with 8-10 quality templates or aim for full 14?

---
*Research completed: 2026-06-04*
*Ready for requirements: yes*
