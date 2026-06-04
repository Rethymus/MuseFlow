# Features Research: v1.1 创作体验升级

**Researched:** 2026-06-04
**Milestone:** v1.1 创作体验升级

## Chinese Novel Genre Taxonomy

Curated from 起点中文网 and 番茄小说 (2025-2026 platform data).

Sources: [起点中文网](https://www.qidian.com/), [番茄小说 App Store](https://apps.apple.com/cn/app/), [中国作家网 网络文学多元化发展](https://www.chinawriter.com.cn/n1/2026/0108/c404027-40641641.html)

### Male-Frequency (男频) — 8 Primary Genres

| Genre | Chinese | Sub-types | Template Focus |
|-------|---------|-----------|----------------|
| Xuanhuan (Eastern Fantasy) | 玄幻 | 东方玄幻, 异世大陆, 高武世界 | Power systems, cultivation stages, realm hierarchy |
| Xianxia (Immortal Cultivation) | 仙侠 | 修真文明, 古典仙侠, 都市修仙 | Cultivation methods, spiritual realms, tribulation system |
| Wuxia (Martial Arts) | 武侠 | 传统武侠, 新派武侠 | Martial arts styles, jianghu factions, honor codes |
| Urban | 都市 | 都市生活, 都市异能, 娱乐明星 | Modern setting, hidden powers, career progression |
| History | 历史 | 架空历史, 历史穿越 | Historical periods, political intrigue, military strategy |
| Sci-Fi | 科幻 | 末世危机, 星际文明, 时空穿梭 | Tech levels, space operas, post-apocalyptic survival |
| Games | 游戏 | 虚拟网游, 游戏异界 | Game mechanics, class systems, leveling |
| Military | 军事 | 军事战争, 军事谍战 | War campaigns, espionage, tactical planning |

### Female-Frequency (女频) — 6 Primary Genres

| Genre | Chinese | Sub-types | Template Focus |
|-------|---------|-----------|----------------|
| Ancient Romance | 古代言情 | 穿越架空, 宫闱宅斗 | Court intrigue, family politics, romantic dynamics |
| Modern Romance | 现代言情 | 豪门世家, 婚恋情缘 | Contemporary settings, relationship arcs |
| Fantasy Romance | 仙侠奇缘 | 古典仙侠 | Cultivation + romance blend |
| Youth/Campus | 浪漫青春 | 青春校园 | Coming-of-age, school settings |
| Sci-Fi Romance | 科幻空间 | 末世科幻 | Survival + romance |
| Game Romance | 游戏竞技 | 网游情缘 | Virtual worlds + romance |

### 2025-2026 Trending Genres

Based on 番茄小说 2025年度关键词报告 and 起点年度数据:

1. **都市修仙 (Urban Cultivation)** — 修仙2.0, 单日搜索 Top 2 on 番茄
2. **都市脑洞 (Urban Creative)** — 男频顶流, 异能+高武+脑洞
3. **现实+ (Reality Fusion)** — 现实+玄幻/科幻/穿越, 年增20万部
4. **古言重生 (Ancient Rebirth)** — 女频持续火爆
5. **末世高武 (Post-Apocalyptic High Martial)** — 末世+高武融合

**Total curated genres for MVP:** 14 primary (8 男频 + 6 女频), ~30 sub-types

---

## Feature 1: 预设世界观模板库 (World-Building Template Library)

### Table Stakes
- **Genre selection grid** — User picks genre from curated list with icons/preview
- **One-click template instantiation** — Creates WorldSetting + CharacterCard archetypes from template
- **Template preview** — Shows what the template includes before committing
- **Editable after creation** — Templates create editable entities, not locked presets
- **AI-assisted detail completion** — AI fills in template blanks based on user's story concept

### Differentiators
- **Genre-specific foreshadowing patterns** — Templates include common plot devices for the genre (e.g., 玄幻: hidden bloodline → awakening → tribulation)
- **Opening hook samples** — 3 sample opening paragraphs per genre template
- **Cross-genre blending** — User can mix elements from 2 templates (e.g., 都市+仙侠 = 都市修仙)
- **Community-inspired "trending" badges** — Templates tagged with 2025-2026 hot genres

### Anti-Features
- ❌ Community template sharing — Requires backend, out of scope for local-first app
- ❌ User-created templates from scratch — Too complex for v1.1, template editing is enough
- ❌ Auto-updating templates from internet — Local-only app, no cloud dependency

### Complexity: **Medium**

---

## Feature 2: 故事弧可视化 (Story Arc Visualization)

### Table Stakes
- **Node graph from PlotNode data** — Automatically generates graph from existing story structure
- **Connection lines** — Shows plot progression (sequential) and foreshadowing links (dashed)
- **Node details on tap** — Shows PlotNode title, chapter, structural role, writing status
- **Zoom and pan** — Mouse wheel zoom, drag to pan canvas
- **Color-coded roles** — Setup/development/turn/climax/resolution each have distinct colors

### Differentiators
- **Drag-to-reorder nodes** — User can rearrange plot nodes by dragging them on the graph
- **Edit node properties inline** — Tap node → edit title/role/status directly on graph
- **Foreshadowing arc lines** — Dashed lines connecting foreshadow → resolution nodes
- **Minimap** — Overview thumbnail for navigating large graphs
- **Export as image** — Save graph visualization as PNG

### Anti-Features
- ❌ Auto-layout algorithms (force-directed, hierarchical) — v1.1 uses manual positioning only
- ❌ Real-time collaboration on graph — Single-user app
- ❌ 3D visualization — Unnecessary, 2D canvas sufficient
- ❌ Animation playback of story progression — Nice-to-have for future version

### Complexity: **High**
- Custom CustomPainter with gesture handling OR graphview library
- Virtual viewport for large graphs (100+ nodes)
- Performance-critical rendering path
- Depends on existing PlotNode + Foreshadowing domain data

---

## Feature 3: 开篇引导 (Onboarding Wizard + AI Opening Generator)

### Table Stakes (First-Run Wizard)
- **First-run detection** — Show wizard only on first app launch
- **Step 1: Pick a genre** — Genre grid with descriptions
- **Step 2: Name your world** — Quick world creation with genre template auto-loaded
- **Step 3: Create first character** — Character name + role, AI suggests personality traits
- **Step 4: Write first lines** — AI generates 3 opening variants based on genre + world + character
- **Skip option** — "跳过" button on every step, exit to main app
- **Progress indicator** — Step dots showing current position

### Differentiators (AI Opening Generator)
- **Accessible from editor** — Not just first-run, any time user wants opening inspiration
- **3 variant styles** — AI generates 3 different tones/opening approaches
- **User selects → refine** — Pick one, then refine in editor with AI toolbar
- **Context-aware** — Uses existing world settings and characters as context

### Anti-Features
- ❌ Mandatory completion — User can always skip
- ❌ Tutorial overlays (coachmarks) — Not a feature tour, it's a creation flow
- ❌ Video tutorials — Overkill, text + AI guidance sufficient
- ❌ Account creation step — Local-only app, no accounts

### Complexity: **Medium**

---

## Feature 4: 写作数据统计 (Writing Statistics)

### Table Stakes
- **Total word count** — Across all projects
- **Writing streak** — Consecutive days with writing activity
- **AI assist ratio** — % of text that involved AI interaction
- **Chapter word counts** — Per-chapter breakdown
- **Session duration** — Time spent in active editing per session

### Differentiators
- **Writing speed trend chart** — Line chart showing words/hour over time (fl_chart)
- **Daily word count bar chart** — Bar chart for last 30 days (fl_chart)
- **AI usage pie chart** — Visual breakdown of AI vs manual writing (fl_chart)
- **Milestone badges** — "First 1000 words", "10K words", "30-day streak"
- **Export stats** — Save statistics as image or text report

### Anti-Features
- ❌ Social sharing of stats — No account system
- ❌ Comparative benchmarks (vs other authors) — No cloud, no community data
- ❌ Real-time word count in editor overlay — Distracting, stats page is sufficient
- ❌ Goal-setting and notifications — Future version

### Complexity: **Medium-Low**

---

## Feature Priority by Complexity vs Impact

| Feature | Complexity | Impact | Dependencies |
|---------|-----------|--------|-------------|
| Onboarding wizard | Medium | High (new user retention) | Templates (reuses gallery) |
| World-building templates | Medium | High (cold-start problem) | None — standalone |
| Writing statistics | Medium-Low | Medium (engagement) | Editor hooks needed |
| Story arc visualization | High | Medium-High (power user) | PlotNode data exists |

**Recommended build order:** Templates → Onboarding → Stats → Visualization

---
*Features researched: 2026-06-04 for v1.1 milestone*
