# Roadmap: MuseFlow 灵韵

## Milestones

- ✅ **v1.0 MVP** — Phases 0–6 (shipped 2026-06-04)
- ✅ **v1.1 创作体验升级** — Phases 7–10 (shipped 2026-06-05)
- ✅ **v1.2 多文稿架构** — Phase 11 (shipped 2026-06-06)
- 🚧 **v1.3 用户视角全流程验证 — 百章修仙小说** — Phases 12–16 (in progress)

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

### 🚧 v1.3 用户视角全流程验证 — 百章修仙小说 (In Progress)

**Milestone Goal:** 代入核心用户视角，用 MuseFlow 真实写一篇100章修仙超短篇小说，在创作过程中走完所有功能、验证可靠性、发掘痛点。

- [x] **Phase 12: Token Audit Infrastructure** — 每次 AI 调用自动记录 token 用量，可查看消耗总览 (completed 2026-06-06)
- [ ] **Phase 13: Automation Test Harness** — FakeAdapter + 测试脚本，无需真实 API 即可验证核心流程
- [ ] **Phase 14: World-Building & First 30 Chapters** — 修仙世界观搭建 + 碎片捕捉 + 开篇引导 + 前30章创作验证
- [ ] **Phase 15: Full Manuscript & Story Structure** — 31-100章创作 + 故事结构验证 + 格式清洗 + 导出验证
- [ ] **Phase 16: Analysis & Reports** — Token成本分析 + 痛点报告 + 反AI味评估 + 知识库一致性分析

## Phase Details

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

- [ ] 13-01-PLAN.md — Extract AIAdapter interface, FakeAdapter, test container factory, fixtures

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 13-02-PLAN.md — Dart automation script TEST-01 (8 segments + E2E) and FakeAdapter tests TEST-03
- [ ] 13-03-PLAN.md — Flutter integration tests TEST-02 (UI flow + error scenarios) and widget key additions

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

**Plans**: TBD
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

**Plans**: TBD
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

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 12 → 13 → 14 → 15 → 16

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
| 12. Token Audit Infrastructure | v1.3 | 3/3 | Complete   | 2026-06-06 |
| 13. Automation Test Harness | v1.3 | 0/3 | Not started | - |
| 14. World-Building & First 30 Chapters | v1.3 | 0/? | Not started | - |
| 15. Full Manuscript & Story Structure | v1.3 | 0/? | Not started | - |
| 16. Analysis & Reports | v1.3 | 0/? | Not started | - |
