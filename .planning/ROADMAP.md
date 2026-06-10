# Roadmap: MuseFlow 灵韵

## Milestones

- ✅ **v1.0 MVP** — Phases 0–6 (shipped 2026-06-04)
- ✅ **v1.1 创作体验升级** — Phases 7–10 (shipped 2026-06-05)
- ✅ **v1.2 多文稿架构** — Phase 11 (shipped 2026-06-06)
- ✅ **v1.3 用户视角全流程验证 — 百章修仙小说** — Phases 12–16 (shipped 2026-06-09)
- 🚧 **v1.4 AI辅助创作体验深度优化** — Phases 17–24 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 0–6) — SHIPPED 2026-06-04</summary>

- [x] Phase 0: Technical Validation (3/3 plans) — completed 2026-06-01
- [x] Phase 1: App Shell + Editor + Capture UI (4/4 plans) — completed 2026-06-01
- [x] Phase 2: AI Provider + Capture Synthesis (3/3 plans) — completed 2026-06-02
- [x] Phase 3: Editor AI Toolbar (3/3 plans) — completed 2026-06-02
- [x] Phase 4: Knowledge Base + Skill System (5/5 plans) — completed 2026-06-04
- [x] Phase 5: Story Structure + Format + Export (4/4 plans) — completed 2026-06-04
- [x] Phase 6: Multi Provider + Android Polish (3/3 plans) — completed 2026-06-04

</details>

<details>
<summary>✅ v1.1 创作体验升级 (Phases 7–10) — SHIPPED 2026-06-05</summary>

- [x] Phase 7: 预设世界观模板库 (3/3 plans) — completed 2026-06-04
- [x] Phase 8: 开篇引导 (5/5 plans) — completed 2026-06-04
- [x] Phase 9: 写作数据统计 (5/5 plans) — completed 2026-06-05
- [x] Phase 10: 故事弧可视化 (4/4 plans) — completed 2026-06-05

</details>

<details>
<summary>✅ v1.2 多文稿架构 (Phase 11) — SHIPPED 2026-06-06</summary>

- [x] Phase 11: 文稿库与章节管理 (6/6 plans) — completed 2026-06-06

</details>

<details>
<summary>✅ v1.3 用户视角全流程验证 — 百章修仙小说 (Phases 12–16) — SHIPPED 2026-06-09</summary>

- [x] Phase 12: Token Audit Infrastructure (3/3 plans) — completed 2026-06-06
- [x] Phase 13: Automation Test Harness (4/4 plans) — completed 2026-06-07
- [x] Phase 14: World-Building & First 30 Chapters (10/10 plans) — completed 2026-06-08
- [x] Phase 15: Full Manuscript & Story Structure (7/7 plans) — completed 2026-06-08
- [x] Phase 16: Analysis & Reports (3/3 plans) — completed 2026-06-08

</details>

### 🚧 v1.4 AI辅助创作体验深度优化 (In Progress)

**Milestone Goal:** 以真实作者的创作体验为中心，从"能用"到"好用"——强化作者风格学习、反AI味深度优化、知识库智能化，让AI真正成为作者的磨刀石。

- [ ] **Phase 17: Author Style Fingerprint + Dynamic Prompt** — Author style analysis, dynamic prompt adaptation, and few-shot sample injection
- [ ] **Phase 18: Anti-AI-Scent Deepening** — Expanded banned phrase library and enhanced post-processing pipeline
- [ ] **Phase 19: Style Deviation Detection + Style Thermometer** — Style deviation highlighting, semantic AI-scent detection, and style thermometer dashboard
- [ ] **Phase 20: Smart Knowledge Injection** — Fuzzy matching, alias extraction, pronoun resolution, and context-aware priority injection
- [ ] **Phase 21: Relationship Graph + Foreshadowing Reminders** — Character relationship management and real-time foreshadowing reminders
- [ ] **Phase 22: Long-form Context + Guided Writing** — Chapter context chain, multi-turn AI dialog, and guided continuation suggestions
- [ ] **Phase 23: Editor AI Operations + Undo History** — Expanded AI toolbar operations and 20-step undo history
- [ ] **Phase 24: Web Responsive + Progress Dashboard** — Web responsive layout and writing progress visualization

## Phase Details

<details>
<summary>v1.0–v1.3 Phase Details (shipped)</summary>

### Phase 12: Token Audit Infrastructure

**Goal**: 每次 AI 调用自动记录 token 用量数据，用户可以在统计页面查看消耗总览和分布
**Depends on**: Phase 11 (v1.2 shipped)
**Requirements**: AUDIT-01, AUDIT-02, AUDIT-03
**Success Criteria** (what must be TRUE):

  1. 每次 AI API 调用（synthesis、editor rewrite、polish、free input、deviation detection）后，自动记录一条包含输入 token、输出 token、模型名称、操作类型、关联章节 ID、时间戳的审计记录
  2. Token 审计数据存储在独立 Hive box 中，Chapter 和 Manuscript 实体不受任何侵入
  3. 用户可以在写作统计页面查看 token 消耗总览：总成本、每章分布、按操作类型分布

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 12-01-PLAN.md — Domain entities, Hive persistence, debatched write service, adapter onUsage callback, providers

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 12-02-PLAN.md — Wire 6 AI call sites, embed token summary in WritingStatsPage, register route
- [x] 12-03-PLAN.md — TokenAuditPage with per-chapter bar chart, operation-type pie chart, trend line chart

### Phase 13: Automation Test Harness

**Goal**: 自动化测试脚本可以在没有真实 API Key 的情况下完整验证核心创作流程
**Depends on**: Phase 12 (token audit infrastructure for test assertions)
**Requirements**: TEST-01, TEST-02, TEST-03
**Success Criteria** (what must be TRUE):

  1. Dart 自动化脚本可以无 UI 运行完整流程（创建文稿 → 创建100章 → 调用 AI 生成内容 → 导出），使用 FakeAdapter 无需真实 API
  2. Flutter 集成测试覆盖关键 UI 节点（文稿创建 → 章节管理 → AI 生成 → 编辑 → 导出）
  3. FakeAdapter 返回可复现的修仙题材文本，脚本可以断言章节内容、导出格式、token 审计记录

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 13-01-PLAN.md — Extract AIAdapter interface, FakeAdapter, test container factory, fixtures

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 13-02-PLAN.md — Dart automation script TEST-01 (8 segments + E2E) and FakeAdapter tests TEST-03
- [x] 13-03-PLAN.md — Flutter integration tests TEST-02 (UI flow + error scenarios) and widget key additions

### Phase 14: World-Building & First 30 Chapters

**Goal**: 用户可以使用 MuseFlow 搭建完整修仙世界观并写出前30章，验证核心创作循环的可靠性
**Depends on**: Phase 12, Phase 13
**Requirements**: JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04, JOURNEY-05, JOURNEY-06
**Success Criteria** (what must be TRUE):

  1. 用户可以用修仙模板创建完整世界观（角色卡、设定集、Skill 设定守护配置），知识库可供后续章节自动注入
  2. 用户可以输入灵感碎片（子弹笔记模式），AI 将碎片整理成逻辑通畅的故事段落
  3. 用户可以通过开篇引导生成第一章，并体验3种风格开篇（场景切入/人物切入/悬念切入）
  4. 用户可以创建并管理前30章（CRUD、排序、拆分、合并、复制、删除），多文稿架构稳定运行
  5. 用户可以逐章使用 AI 生成内容（每章~100字修仙内容），知识库自动注入和 Skill 设定守护连续工作
  6. 用户可以在编辑器中选中文本触发浮窗操作（语气改写、段落润色、自由输入编辑），验证反AI味效果

**Plans**: 10 plans

Plans:
**Wave 1**

- [x] 14-01-PLAN.md — Journey container factory, xianxia fixtures, story outline, world-building test (JOURNEY-01)

**Wave 2** *(depends on Wave 1)*

- [x] 16-02-PLAN.md — REPORT-01 Token cost analysis + REPORT-02 Pain point report

**Wave 3** *(depends on Wave 2)*

- [x] 16-03-PLAN.md — REPORT-03 Anti-AI-scent blind read + REPORT-04 KB consistency analysis

- [x] 14-02-PLAN.md — Fragment synthesis, opening guide, chapter management tests (JOURNEY-02, JOURNEY-03, JOURNEY-04)
- [x] 14-03-PLAN.md — 30-chapter serial generation, E2E full-journey, issue log template (JOURNEY-05, JOURNEY-06)

**Gap Closure:**

- [x] 14-04-PLAN.md — Verification pass with RESEARCH.md open questions investigation (JOURNEY-05, JOURNEY-06)
- [x] 14-05-PLAN.md — Anti-AI-scent phrase removal + chapter management validation fixes (JOURNEY-06, P14-04-AI-01, P14-05-CHAPTER-01)
- [x] 14-06-PLAN.md — Live GLM serial generation debug (JOURNEY-05, P14-04-GLM-01)
- [x] 14-07-PLAN.md — Human observation checkpoint + dark theme fix (JOURNEY-06, P14-04-AUTO-01, P14-07-UI-01)
- [x] 14-08-PLAN.md — D-11 bounds post-processing for GLM output + live rerun (JOURNEY-05, P14-04-GLM-01)
- [x] 14-09-PLAN.md — Security fixes CR-01/CR-02 + DeviationWarningWidget widget test (JOURNEY-06, CR-01, CR-02, P14-07-HUMAN-02)
- [x] 14-10-PLAN.md — IME deferral documentation + final status update (JOURNEY-06, P14-07-HUMAN-01)

**UI hint**: yes

### Phase 15: Full Manuscript & Story Structure

**Goal**: 用户可以完成100章修仙小说，验证故事结构管理、格式清洗和多格式导出在规模下的可靠性
**Depends on**: Phase 14
**Requirements**: JOURNEY-07, JOURNEY-08, JOURNEY-09, JOURNEY-10
**Success Criteria** (what must be TRUE):

  1. 用户可以在100章尺度下验证故事结构（伏笔埋设 → 跨章跟踪 → 填坑解决），逻辑闭环检测和一致性守护有效
  2. 用户可以对完成的100章文稿执行格式清洗（标点修复、排版美化、Markdown 残留清理），输出干净可读
  3. 用户可以将100章文稿导出为三种格式（Markdown 带章节标题结构、TXT 纯文本、JSON 含完整元数据）
  4. 用户可以查看写作统计数据（字数统计、AI 使用率、写作速度），数据在100章规模下准确

**Plans**: 7 plans

Plans:
**Wave 1**

- [x] 15-01-PLAN.md — Story outline extension (30->100 chapters), stage prompt definitions (JOURNEY-07/08/09/10 foundation)

**Wave 2** *(depends on Wave 1)*

- [x] 15-02-PLAN.md — Deterministic adapter fix, 100-chapter generation with stage prompts + previous-chapter summary injection (JOURNEY-07)
- [x] 15-03-PLAN.md — Foreshadowing lifecycle test: 4 threads planted/resolved + deviation detection at 100-chapter scale (JOURNEY-07)
- [x] 15-04-PLAN.md — Format cleaning validation (100 chapters, 3 assertion categories + idempotent) + three-format export validation (JOURNEY-08, JOURNEY-09)
- [x] 15-05-PLAN.md — Writing statistics accuracy + token audit completeness at 100-chapter scale (JOURNEY-10)

**Wave 3** *(depends on Wave 2)*

- [x] 15-06-PLAN.md — E2E full journey extension (30->100 chapters) + issue log template (JOURNEY-07, JOURNEY-10)
- [x] 15-07-PLAN.md — Automated UI evidence extension for JOURNEY-07/08/09/10 + Phase 14 regression checks (JOURNEY-07, JOURNEY-08, JOURNEY-09, JOURNEY-10)
**UI hint**: yes

### Phase 16: Analysis & Reports

**Goal**: 用户和开发者可以查看全面的 token 成本分析、痛点报告、反AI味评估和知识库一致性分析
**Depends on**: Phase 15
**Requirements**: REPORT-01, REPORT-02, REPORT-03, REPORT-04
**Success Criteria** (what must be TRUE):

  1. 生成 token 消耗分析报告：万字短篇实际成本 + 50万字长篇消耗推算 + 优化建议
  2. 生成用户痛点报告：功能缺陷列表 + 体验摩擦点 + 缺失需求建议，按严重程度分类
  3. 生成反AI味效果评估：盲读测试结果，人判断选取段落是否为 AI 生成
  4. 生成知识库一致性衰减分析：100章后角色卡和设定集与实际内容的一致性对比

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 16-01-PLAN.md — Domain models, export service, ReportsHubPage, routing

**Wave 2** *(depends on Wave 1)*

- [x] 16-02-PLAN.md — REPORT-01 Token cost analysis + REPORT-02 Pain point report

**Wave 3** *(depends on Wave 2)*

- [x] 16-03-PLAN.md — REPORT-03 Anti-AI-scent blind read + REPORT-04 KB consistency analysis

</details>

### Phase 17: Author Style Fingerprint + Dynamic Prompt

**Goal**: AI learns the author's writing style from existing chapters and adapts its output to match, instead of using a fixed one-line persona instruction
**Depends on**: Phase 16 (v1.3 shipped)
**Requirements**: STYLE-01, STYLE-02, STYLE-03
**Success Criteria** (what must be TRUE):
  1. User can view an AuthorStyleProfile page showing their analyzed style across 5 dimensions (sentence length, rhythm, vocabulary, rhetoric, emotional tone) with concrete metrics
  2. AI-generated text (synthesis, rewrite, polish) reflects the author's measured style dimensions in the prompt, replacing the previous fixed "natural, warm, human-like" instruction
  3. AI prompts automatically include 3-5 high-quality paragraphs extracted from the author's own chapters as few-shot style examples, visible in the prompt preview
**Plans**: TBD

### Phase 18: Anti-AI-Scent Deepening

**Goal**: The banned phrase library expands from 15 to 200+ entries with categories, and the post-processing pipeline catches 20+ structural patterns that betray AI authorship
**Depends on**: Phase 16 (v1.3 shipped)
**Requirements**: AISC-01, AISC-04
**Success Criteria** (what must be TRUE):
  1. User can browse and manage a categorized banned phrase library with 200+ entries across categories (transitions, modifiers, summaries, genre cliches), and add custom entries
  2. Post-processing pipeline detects and highlights 20+ structural patterns including repetitive sentence structures, modifier overload, passive voice frequency, and monotonous declarative patterns
**Plans**: TBD

### Phase 19: Style Deviation Detection + Style Thermometer

**Goal**: Users can quantitatively measure how "AI-scented" their text is and see style deviations highlighted, making anti-AI-scent an observable, trackable metric
**Depends on**: Phase 17 (AuthorStyleProfile), Phase 18 (enhanced detection)
**Requirements**: STYLE-04, AISC-02, AISC-03
**Success Criteria** (what must be TRUE):
  1. AI-generated text is compared against the author's AuthorStyleProfile and style deviations are highlighted in the diff review view with specific dimension breakdowns
  2. System detects AI semantic patterns beyond keyword matching: information density uniformity, emotion curve flatness, over-balanced descriptions, and unnaturally perfect logic
  3. User can view a style thermometer dashboard showing AI-scent score (0-100), style consistency with their profile, literary quality score, and readability metrics
**Plans**: TBD
**UI hint**: yes

### Phase 20: Smart Knowledge Injection

**Goal**: Knowledge injection matches characters and settings even with typos, aliases, and pronouns, and prioritizes chapter-relevant knowledge over global knowledge within token budget
**Depends on**: Phase 16 (v1.3 shipped)
**Requirements**: KNOW-01, KNOW-03
**Success Criteria** (what must be TRUE):
  1. Knowledge injection matches character names with edit distance <=2 (handles typos like "林锋" matching "林风"), extracts aliases from character descriptions ("小风" matches "林风"), and resolves pronoun coreferences ("他" in context maps to the active character)
  2. Knowledge injection prioritizes chapter-active characters above related characters above global characters, with adaptive token budget allocation that prefers relevant over exhaustive
**Plans**: TBD

### Phase 21: Relationship Graph + Foreshadowing Reminders

**Goal**: Users can define character relationships and receive real-time reminders about unresolved foreshadowing tied to the characters and locations in their current chapter
**Depends on**: Phase 20 (improved matching)
**Requirements**: KNOW-02, KNOW-04
**Success Criteria** (what must be TRUE):
  1. User can define and manage character relationships (mentor, enemy, family, lover, etc.) in a relationship graph, and related character info is injected into AI prompts when those characters appear
  2. User sees real-time foreshadowing reminders in the editor sidebar when writing chapters involving characters or locations associated with unresolved foreshadowing entries
**Plans**: TBD
**UI hint**: yes

### Phase 22: Long-form Context + Guided Writing

**Goal**: AI understands long-form story position with multi-chapter context, supports iterative refinement through multi-turn conversation, and offers directional plot suggestions that keep the author in control
**Depends on**: Phase 16 (v1.3 shipped)
**Requirements**: LFIN-01, LFIN-02, LFIN-03
**Success Criteria** (what must be TRUE):
  1. AI context chain includes previous 3 chapter summaries (with decreasing detail), current chapter outline/goal, and story arc position (rising/falling/climax), providing long-form narrative awareness
  2. User can engage in multi-turn AI conversations (e.g., "polish this" -> "too flowery" -> "better") with conversation history managed within token budget
  3. System offers 3 directional plot continuation suggestions based on current story context; user selects a direction before AI generates expanded content
**Plans**: TBD
**UI hint**: yes

### Phase 23: Editor AI Operations + Undo History

**Goal**: The floating toolbar offers rich AI operations beyond rewrite and polish, and every AI operation is undoable with a 20-step history
**Depends on**: Phase 17 (style-aware prompts for new operations)
**Requirements**: EDIT-01, EDIT-02
**Success Criteria** (what must be TRUE):
  1. User can select text and choose from expanded AI operations: expand (detail enhancement), compress (text condensation), dialogue generation, and scene description, in addition to existing tone rewrite and polish
  2. User can undo up to 20 AI operations and compare versions side by side (view versions A/B/C) to pick the best result
**Plans**: TBD
**UI hint**: yes

### Phase 24: Web Responsive + Progress Dashboard

**Goal**: MuseFlow Web renders correctly on narrow viewports, and users can visualize their writing progress with a rich dashboard
**Depends on**: Phase 16 (v1.3 shipped)
**Requirements**: EDIT-03, EDIT-04
**Success Criteria** (what must be TRUE):
  1. Web build renders correctly on narrow viewports (mobile web testing) with responsive layout adaptations for navigation, editor, and side panels
  2. User can view a writing progress dashboard showing daily creation rhythm heatmap, AI-assisted vs manual ratio visualization, chapter completion tracking, and estimated completion time
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 17 -> 18 -> 19 -> 20 -> 21 -> 22 -> 23 -> 24

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 0. Technical Validation | v1.0 | 3/3 | Complete | 2026-06-01 |
| 1. App Shell + Editor + Capture | v1.0 | 4/4 | Complete | 2026-06-01 |
| 2. AI Provider + Synthesis | v1.0 | 3/3 | Complete | 2026-06-02 |
| 3. Editor AI Toolbar | v1.0 | 3/3 | Complete | 2026-06-02 |
| 4. Knowledge Base + Skills | v1.0 | 5/5 | Complete | 2026-06-04 |
| 5. Story Structure + Export | v1.0 | 4/4 | Complete | 2026-06-04 |
| 6. Multi Provider + Android | v1.0 | 3/3 | Complete | 2026-06-04 |
| 7. 预设世界观模板库 | v1.1 | 3/3 | Complete | 2026-06-04 |
| 8. 开篇引导 | v1.1 | 5/5 | Complete | 2026-06-04 |
| 9. 写作数据统计 | v1.1 | 5/5 | Complete | 2026-06-05 |
| 10. 故事弧可视化 | v1.1 | 4/4 | Complete | 2026-06-05 |
| 11. 文稿库与章节管理 | v1.2 | 6/6 | Complete | 2026-06-06 |
| 12. Token Audit Infrastructure | v1.3 | 3/3 | Complete | 2026-06-06 |
| 13. Automation Test Harness | v1.3 | 4/4 | Complete | 2026-06-07 |
| 14. World-Building & First 30 Chapters | v1.3 | 10/10 | Complete | 2026-06-08 |
| 15. Full Manuscript & Story Structure | v1.3 | 7/7 | Complete | 2026-06-08 |
| 16. Analysis & Reports | v1.3 | 3/3 | Complete | 2026-06-08 |
| 17. Author Style Fingerprint + Dynamic Prompt | v1.4 | 0/? | Not started | - |
| 18. Anti-AI-Scent Deepening | v1.4 | 0/? | Not started | - |
| 19. Style Deviation Detection + Style Thermometer | v1.4 | 0/? | Not started | - |
| 20. Smart Knowledge Injection | v1.4 | 0/? | Not started | - |
| 21. Relationship Graph + Foreshadowing Reminders | v1.4 | 0/? | Not started | - |
| 22. Long-form Context + Guided Writing | v1.4 | 0/? | Not started | - |
| 23. Editor AI Operations + Undo History | v1.4 | 0/? | Not started | - |
| 24. Web Responsive + Progress Dashboard | v1.4 | 0/? | Not started | - |
