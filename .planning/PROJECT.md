# MuseFlow 灵韵

## What This Is

MuseFlow 灵韵是一个人机协作的小说创作辅助工具，面向"有故事但拙于表达"的创作者。它不是AI代写的打字机，而是一块磨刀石——帮助作者将脑中混乱的画面理顺、润色、连缀成文，同时确保每一行文字都带有"人"的温度。

基于Flutter实现Windows/Android跨平台，采用"碎片捕捉→AI整理→精细打磨"的三段式创作流程，配合知识库自动注入和故事结构守护，解决从灵感碎片到成稿的完整链路。

**v1.2 shipped** — 11 phases, 48 plans, ~49K LOC Dart (29K source + 20K test), full capture→synthesis→editor pipeline with knowledge base, skill system, story structure, template library, analytics, story arc visualization, and multi-manuscript chapter editor.

## Core Value

**让AI帮你写好故事，但让读者看不出AI的痕迹。** 反AI味是产品灵魂，不是附加功能。

## Current Milestone: v1.3 用户视角全流程验证 — 百章修仙小说

**Goal:** 代入核心用户视角，用 MuseFlow 真实写一篇100章修仙超短篇小说，在创作过程中走完所有功能、验证可靠性、发掘痛点。特别关注 token 消耗效率。

**Target features:**
- 用户旅程全流程验证（世界观搭建→碎片捕捉→AI整理→开篇→章节管理→AI生成→编辑润色→故事结构→格式清洗→导出→统计）
- Token 消耗全程审计与分析
- 用户痛点报告（功能缺陷 + 体验问题 + 缺失需求）
- Dart 自动化脚本 + Flutter 集成测试
- 100章修仙超短篇小说（~1万字）+ 三格式导出

## Requirements

### Validated

- ✓ 碎片捕捉器：自由输入灵感碎片，子弹笔记模式 — v1.0
- ✓ AI整理成段：将碎片整理成逻辑通畅的故事段落 — v1.0
- ✓ 沉浸式编辑器：选中文本弹出浮窗菜单（语气改写/文段润色/自由输入编辑） — v1.0
- ✓ 知识库自动注入：写作时AI自动参考角色卡和设定集 — v1.0
- ✓ 故事结构层：伏笔跟踪、剧情节点管理、逻辑闭环检测 — v1.0
- ✓ 角色记忆守护：AI记住角色人设，防止人设崩塌 — v1.0
- ✓ Skill世界观系统：AI辅助创建完整世界观设定集 + 写作时实时守护（偏离设定时提醒） — v1.0
- ✓ AI模型市场：支持自定义API Key/Base URL，兼容OpenAI/Claude/DeepSeek/Ollama — v1.0
- ✓ 反AI味：通过Prompt工程隐式实现，避免AI常用连接词和陈词滥调 — v1.0
- ✓ 格式清洗：标点修复、排版美化、Markdown残留清理 — v1.0
- ✓ 预设世界观模板库：修仙/武侠/都市/科幻/玄幻 preset world-building packs — v1.1
- ✓ 开篇引导：交互式问卷生成3种风格开篇 — v1.1
- ✓ 写作数据统计：字数、写作速度、AI使用率 — v1.1
- ✓ 故事弧可视化：剧情结构节点连线图 — v1.1
- ✓ 文稿库与章节管理：多文稿库、章节导航、章节级自动保存、模板章节骨架、章节感知导出 — v1.2

### Active

- [ ] 用户旅程全流程验证：从世界观搭建到导出，以真实用户身份走完所有功能
- [ ] 章节管理可靠性验证：100章 CRUD + 排序/拆分/合并，验证多文稿架构
- [ ] 编辑器浮窗验证：语气改写、段落润色、自由编辑，验证反AI味效果
- [ ] 故事结构验证：伏笔埋设→跟踪→填坑，逻辑闭环检测
- [ ] Token 消耗审计：全程跟踪，分析万字短篇成本，推算长篇消耗量级
- [ ] 用户痛点报告：功能缺陷、体验问题、缺失需求
- [ ] 自动化测试：Dart 脚本 + Flutter 集成测试（基于发现的痛点）
- [ ] 导出验证：Markdown/TXT/JSON 三格式
- [ ] 百章修仙超短篇小说产出（~1万字）

### Out of Scope

- **一键生成全书** — 违背核心理念，强制分段交互 — 防止批量生产垃圾文
- **短剧剧本功能** — 计划中，但属于后续里程碑
- **云端同步/账户系统** — MVP所有数据本地存储
- **iOS/macOS平台** — 先聚焦Windows/Android
- **实时协作/多人编辑** — 单人创作工具
- **故事弧可视化高级形态** — 已有 v1.1 基础可视化；更复杂的 v2 交互/性能优化另行规划
- **模板文学性审核** — 预设模板的文学质量需专业编辑审核，不在开发阶段 scope

## Context

### Current State (post v1.2)

**Shipped:** v1.0 MVP + v1.1 创作体验升级 + v1.2 多文稿架构。
**Codebase:** Flutter/Dart app with capture→synthesis→editor pipeline, knowledge base, story structure, template library, analytics, story arc visualization, and multi-manuscript chapter editor.
**Tech stack:** Flutter 3.44 + super_editor + Riverpod + Hive CE + openai_dart/anthropic_sdk_dart/ollama_dart.
**Platforms:** Windows desktop (primary) + Android (adaptive layout).
**Coverage:** Automated `flutter test` passes (930 passed, 1 skipped after Phase 11). Human UAT remains for physical device/IME/lifecycle validation.

### 市场背景
各大小说平台针对AI内容严规频出，粗制滥造的AI小说纷纷下架。但人机协奏是大势所趋，关键在于如何把握"辅助创作"与"AI代写"的平衡。MuseFlow从交互设计上强制分段操作，从产品层面遏制批量生产。

### 目标用户
- **核心用户：有故事的"拙"笔** — 脑洞极大、世界观宏大，却苦于文字驾驭不足，常陷于"词不达意"或"开篇难下笔"
- **进阶用户：追求效率的构思者** — 厌恶AI陈词滥调与逻辑崩坏，需要工具辅助梳理人物关系和剧情伏笔

### 核心创作流程
```
碎片输入（捕捉器）→ AI整理成段 → 编辑器精细打磨（选文浮窗菜单）
                       ↑                    ↑
                知识库自动注入          Skill设定守护
              （角色卡/设定集）      （偏离设定时提醒）
```

### 竞品差异
市面上AI写作工具要么是"一键生成"的快餐工具，要么是面向专业编辑的笨重软件。MuseFlow的独特定位是：**作者主导、AI辅助、反AI味输出**。

### Known Issues & Technical Debt

- Anti-AI-scent banned phrase lists are from domain knowledge, not empirical testing — needs validation with real Chinese prose
- `flutter analyze --no-fatal-infos` reports existing warning/info lint items, but no analysis errors
- Phase 00/01 human testing (IME, startup speed, 300K document scrolling) deferred to physical device validation
- Integration tests scaffolded but not comprehensive — need real device testing
- Phase 7 bundled template prose needs human literary review before release sign-off
- Phase 11: 4 non-critical tech debt items (INFO/WARNING level, see v1.2 audit)

## Constraints

- **技术栈**: Flutter (Dart) — Windows/Android跨平台
- **状态管理**: Riverpod
- **本地存储**: Hive数据库 + JSON导出
- **原生输入法**: 必须调用系统级IME，禁止应用内嵌入输入框（确保五笔、搜狗等输入法兼容）
- **安装包**: Windows < 100MB
- **启动速度**: < 3秒
- **数据隐私**: 所有配置与文稿仅存本地，API Key加密存储在本地数据库
- **防滥用**: UI设计不提供"一键生成"按钮，强制分段交互

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 三段式创作流程（捕捉→整理→打磨） | 匹配"拙"笔用户的真实写作习惯：先有想法再理顺再精修 | ✓ Good — shipped in v1.0, all three stages working |
| 编辑器采用豆包扩展式选文浮窗 | 直觉化交互，用户无学习成本，拖选即出功能菜单 | ✓ Good — FloatingToolbar with Follower positioning works well |
| super_editor (not appflowy_editor) | CJK IME and large document performance are existential for Chinese novel authors on Windows | ✓ Good — Phase 0 spike validated |
| 知识库自动注入而非手动选择 | 减少用户操作负担，AI写的时候自动加载相关角色/设定 | ✓ Good — NameIndex matcher enables seamless injection |
| 反AI味通过Prompt工程隐式实现 | 不增加UI复杂度，在Prompt层注入"反AI味"指令和后处理 | ✓ Good — 5-stage PromptPipeline with anti-AI-scent middleware |
| Skill系统先做核心（AI创建+守护），模板库后补 | 核心价值在于"AI辅助创建+实时守护"能力，预设模板是锦上添花 | ✓ Good — core shipped, templates in v1.1 |
| 故事结构层纳入MVP | 伏笔跟踪和逻辑闭环是核心差异化，不能等到Phase 2 | ✓ Good — foreshadowing, consistency guardian, logic loop all shipped |
| PromptMiddleware const constructor | Enables const middleware subclasses, Dart best practice | ✓ Good — clean middleware chain |
| EditorHolderNotifier pattern | Notifier<Editor?> set in initState, cleared in dispose — works with StatefulShellRoute.indexedStack | ✓ Good — editor stays mounted across tab switches |
| activeProviderProvider wraps async FutureProviders | Sync reads in SynthesisNotifier from async provider sources | ⚠ Revisit — wrapping pattern works but could be cleaner with Riverpod 3.x |
| graphview for story arc visualization | Saves weeks vs custom Canvas layout/interaction work | ✓ Good — shipped in Phase 10, interactive graph works well |
| super_editor_markdown discontinued — use built-in | Package abandoned during Phase 11 development | ✓ Good — D-27, super_editor built-in serialization works |
| ChapterAutoSave dispose no-flush | Persistence via explicit awaited forceSave, not dispose | ✓ Good — D-dispose-no-flush, cleaner lifecycle |
| 文稿库使用 ConsumerStatefulWidget for sort state | Local sort state management without extra notifier | ✓ Good — simple and effective |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-06 after v1.3 milestone started*
