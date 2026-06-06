# Milestones

## v1.0 MVP (Shipped: 2026-06-04)

**Phases completed:** 7 phases (0–6), 25 plans, ~40 tasks
**Timeline:** 4 days (2026-05-31 → 2026-06-04)
**Codebase:** 111 source files (18,685 LOC), 64 test files (12,286 LOC)
**Commits:** 173

**Key accomplishments:**

1. **Editor spike validated** — super_editor confirmed for CJK IME (Sogou/Wubi/MSPinyin) and 100K+ character Chinese document performance, de-risking the entire project
2. **Full app shell** — Windows desktop app with sidebar navigation, Hive CE persistence, flutter_secure_storage for API keys, and adaptive layout for Android
3. **Rich text editor** — super_editor integration with formatting toolbar, large document support, and system-level IME compatibility
4. **AI provider + PromptPipeline** — OpenAI adapter with SSE streaming, 5-stage middleware chain (system prompt → knowledge injection → skill enforcement → anti-AI-scent → user content), token budget management
5. **Fragment capture → synthesis flow** — Bullet-note mode, AI synthesis with streaming display, editable output before editor insertion
6. **Floating AI toolbar** — Selection-triggered overlay with 3 AI actions (tone rewrite, paragraph polish, free input), text provenance tracking (inline diff with accept/reject), selective undo stack, and context anchors
7. **Knowledge base + Skill system** — Character cards, world settings, name-index entity matching, AI-assisted world-building documents, real-time skill enforcement with deviation detection
8. **Story structure** — Foreshadowing tracking with resolution detection, plot node management, character consistency guardian, logic loop detection via AI analysis
9. **Format cleaning + export** — Deterministic Chinese punctuation/Markdown/whitespace fixer with preview-first confirmation, TXT/Markdown/JSON export
10. **Multi-provider + Android** — Claude preset via OpenAI-compatible endpoint, per-provider model parameters (temperature/topP/maxTokens), responsive layout for Android

**Known deferred items at close:** 3 (Phase 00/01 human testing on physical Windows device — see STATE.md)

**Audit score:** 47/50 requirements covered (3 pending manual verification on real hardware)

---

## v1.1 创作体验升级 (Shipped: 2026-06-05)

**Phases completed:** 4 phases (7–10), 17 plans
**Timeline:** 2 days (2026-06-04 → 2026-06-05)
**Commits:** ~50

**Key accomplishments:**

1. **预设世界观模板库** — 14种小说类型模板（8男频+6女频），类型画廊 UI，一键创建 WorldSetting + CharacterCard 原型，AI 补全空白字段
2. **开篇引导** — 首次启动 4 步向导（选类型→创建世界→创建角色→AI开篇），AI 开篇生成器（3种风格：场景切入/人物切入/悬念切入），引导可中断恢复
3. **写作数据统计** — 全球/项目数据面板，fl_chart 图表（折线/柱状/饼图），成就徽章（1K/10K/50K 字、7/30/100 天），无感数据采集
4. **故事弧可视化** — graphview 交互式节点图，缩放平移，关系线样式区分，节点颜色编码，拖拽持久化，缩略图导航

**Known deferred items at close:** Phase 7 bundled template prose still needs human literary review

---

## v1.2 多文稿架构 (Shipped: 2026-06-06)

**Phases completed:** 1 phase (11), 6 plans
**Timeline:** ~1 day (2026-06-05 → 2026-06-06)
**Codebase:** 183 source files (29,363 LOC), 117 test files (20,099 LOC)
**Commits:** 76

**Key accomplishments:**

1. **文稿+章节领域模型** — Manuscript/Chapter 实体、Hive TypeAdapters、Genre 预设 14 种 WCAG AA 色彩映射、ChapterExport 模型
2. **完整 CRUD 仓储层** — 软删除+30天级联清除、2秒防抖自动保存+强制保存保证、章节排序/拆分/合并/复制
3. **文稿库 UI** — 类型色卡网格、长按上下文菜单、文稿创建/设置页、go_router 路由集成
4. **编辑器+章节侧边栏** — 文档切换 ValueKey 策略、WidgetsBindingObserver 生命周期保存、拖拽排序、章节操作对话框
5. **全链路集成** — 章节感知导出（Markdown/TXT 按章节结构）、模板章节骨架、AI 章节上下文中间件、启动过期清除
6. **Gap 闭环** — 编辑器进入时加载首章节、所有路由转换前强制保存、dispose 不再 flush（持久化由显式 forceSave 保证）

**Known deferred items at close:** 3 manual UAT scenarios (platform-specific visual and lifecycle testing)

**Audit score:** 6/6 requirements, Nyquist compliant, 4 non-critical tech debt items

---
