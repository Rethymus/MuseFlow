# Pitfalls Research: v1.1 创作体验升级

**Researched:** 2026-06-04
**Milestone:** v1.1 创作体验升级

## Pitfall 1: Graph Rendering Performance with Large Node Counts

**Risk Level:** 🔴 HIGH
**Feature:** Story Arc Visualization
**Phase:** Phase 10

### Description
Whether using CustomPainter or graphview, rendering 100+ PlotNode items with connection lines can degrade performance. [Flutter Issue #72066](https://github.com/flutter/flutter/issues/72066) documents CustomPainter degradation during zoom/pan with complex paths. graphview's force-directed layout recalculation can also be CPU-intensive.

### Warning Signs
- Frame rate drops below 60fps with 50+ nodes
- Janky zoom animation
- Excessive GPU usage in DevTools

### Prevention Strategy
1. **Virtual viewport** (CustomPainter) or **lazy rendering** (graphview): Only render visible nodes
2. **Debounced layout recalculation**: Don't recalculate graph layout on every frame
3. **`shouldRepaint` optimization**: Return false for pan-only changes
4. **Performance budget**: Test with 200 nodes as ceiling, target 55+ FPS
5. **[PlugFox high-performance canvas guide](https://plugfox.dev/high-performance-canvas-rendering/)**: Follow best practices for CustomPainter optimization

---

## Pitfall 2: Template Data Quality and Genre Accuracy

**Risk Level:** 🟡 MEDIUM
**Feature:** World-Building Templates
**Phase:** Phase 7

### Description
14 genres × sub-types = ~30 template files with genre-specific content. Generic or inaccurate templates destroy the feature's value. A "玄幻" template that reads like Western fantasy will alienate Chinese novel authors.

### Warning Signs
- Templates feel generic and interchangeable
- Users skip templates and create worlds manually
- Cultivation/power systems feel inauthentic

### Prevention Strategy
1. **Quality over quantity**: 8-10 well-crafted templates first
2. **AI-assisted generation with genre-specific prompts**: Use existing PromptPipeline with genre context
3. **Source from real platforms**: Reference 起点中文网 and 番茄小说 top works for genre conventions
4. **Flexible template format**: Optional fields — not every genre has `techLevel` or `factions`

---

## Pitfall 3: Onboarding Wizard UX Traps

**Risk Level:** 🟡 MEDIUM
**Feature:** Onboarding Wizard
**Phase:** Phase 8

### Description
A 4-step wizard can feel patronizing or slow. Users who know what they want get frustrated by forced steps. Confused users won't be helped by a rushing wizard.

### Warning Signs
- Users click "跳过" on step 1
- Created worlds/characters are abandoned immediately
- Users never return after first session

### Prevention Strategy
1. **Every step delivers tangible value**: Genre → "app understands me", World → real entity, Character → personal, Opening → "aha moment"
2. **Prominent skip on every step**: Top-right, not hidden
3. **AI previews at each step**: Show suggestions immediately, don't make user wait
4. **Instant gratification at step 4**: Opening generator must produce genuinely good openings
5. **Remember partial progress**: Resume from where user left off if they exit mid-wizard
6. **Don't block progress**: If user skips step 2, still generate openings based on genre alone

---

## Pitfall 4: Stats Collection Impact on Editor Performance

**Risk Level:** 🟡 MEDIUM
**Feature:** Writing Statistics
**Phase:** Phase 9

### Description
Tracking word count deltas on every keystroke can cause jank. super_editor fires frequent document change events, and processing each one synchronously blocks the UI thread.

### Warning Signs
- Typing latency increases after stats feature is added
- Editor scrolling stutters on large documents
- Hive writes happening on every keystroke

### Prevention Strategy
1. **Debounced collection**: Accumulate deltas in memory, flush to Hive every 30 seconds or on dispose
2. **Isolate aggregation**: Daily stats calculation on app startup or in compute isolate
3. **Minimal per-event work**: In-memory counter only, no I/O per keystroke
4. **Lazy chart rendering**: fl_chart rebuilds only when stats page is visible
5. **Capped history**: Auto-prune sessions older than 365 days

---

## Pitfall 5: AI Opening Generator Quality vs Core Value Conflict

**Risk Level:** 🟡 MEDIUM
**Feature:** Onboarding / AI Opening Generator
**Phase:** Phase 8

### Description
The app's core value is "让读者看不出AI的痕迹". The opening generator's 3 variants set high expectations. If all 3 feel AI-scented, the feature undermines the entire product's promise.

### Warning Signs
- All 3 variants use similar structures
- Openings contain AI clichés ("在这个...", "命运的齿轮开始转动...")
- Users consistently skip generated openings

### Prevention Strategy
1. **Strong anti-AI-scent**: Ensure existing `AntiAIScentProcessor` middleware is active
2. **3 genuinely different strategies**: 场景切入, 人物切入, 悬念切入
3. **Post-processing diversity check**: If outputs too similar, regenerate
4. **Genre-specific style guidance**: Opening style must match genre conventions

---

## Pitfall 6: CJK Text in Graph Nodes

**Risk Level:** 🟢 LOW
**Feature:** Story Arc Visualization
**Phase:** Phase 10

### Prevention Strategy
1. Use `TextPainter` for all text measurement
2. Truncate with ellipsis, tooltip on tap for full title
3. Test with worst-case Chinese titles (10+ character compounds)

---

## Pitfall 7: Data Privacy in Local Stats

**Risk Level:** 🟢 LOW
**Feature:** Writing Statistics
**Phase:** Phase 9

### Prevention Strategy
1. Stats in dedicated Hive boxes, easily cleared
2. "清除写作数据" button in settings
3. No export to external services

---

## Summary: Pitfalls by Phase

| Phase | Pitfalls | Risk Levels |
|-------|----------|-------------|
| **Phase 7** (Templates) | #2 Data quality | 🟡 |
| **Phase 8** (Onboarding) | #3 Wizard UX, #5 Opening quality | 🟡🟡 |
| **Phase 9** (Analytics) | #4 Editor performance, #7 Data privacy | 🟡🟢 |
| **Phase 10** (Visualization) | #1 Rendering perf, #6 CJK text | 🔴🟢 |

**Highest risk:** Graph rendering performance (#1) — address with virtual viewport or graphview optimization from the start.

---
*Pitfalls researched: 2026-06-04 for v1.1 milestone*
