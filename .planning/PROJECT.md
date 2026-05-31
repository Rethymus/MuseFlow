# MuseFlow 灵韵

## What This Is

MuseFlow 灵韵是一个人机协作的小说创作辅助工具，面向"有故事但拙于表达"的创作者。它不是AI代写的打字机，而是一块磨刀石——帮助作者将脑中混乱的画面理顺、润色、连缀成文，同时确保每一行文字都带有"人"的温度。

基于Flutter实现Windows/Android跨平台，采用"碎片捕捉→AI整理→精细打磨"的三段式创作流程，配合知识库自动注入和故事结构守护，解决从灵感碎片到成稿的完整链路。

## Core Value

**让AI帮你写好故事，但让读者看不出AI的痕迹。** 反AI味是产品灵魂，不是附加功能。

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] 碎片捕捉器：自由输入灵感碎片，子弹笔记模式
- [ ] AI整理成段：将碎片整理成逻辑通畅的故事段落
- [ ] 沉浸式编辑器：选中文本弹出浮窗菜单（语气改写/文段润色/自由输入编辑）
- [ ] 知识库自动注入：写作时AI自动参考角色卡和设定集
- [ ] 故事结构层：伏笔跟踪、剧情节点管理、逻辑闭环检测
- [ ] 角色记忆守护：AI记住角色人设，防止人设崩塌
- [ ] Skill世界观系统：AI辅助创建完整世界观设定集 + 写作时实时守护（偏离设定时提醒）
- [ ] AI模型市场：支持自定义API Key/Base URL，兼容OpenAI/Claude/DeepSeek/Ollama
- [ ] 反AI味：通过Prompt工程隐式实现，避免AI常用连接词和陈词滥调
- [ ] 格式清洗：标点修复、排版美化、Markdown残留清理

### Out of Scope

- **一键生成全书** — 违背核心理念，强制分段交互 — 防止批量生产垃圾文
- **短剧剧本功能** — 计划中，但属于后续里程碑
- **预设世界观模板库** — Skill核心功能先做，修仙/武侠等预设模板后续补充
- **云端同步/账户系统** — MVP所有数据本地存储
- **iOS/macOS平台** — 先聚焦Windows/Android
- **实时协作/多人编辑** — 单人创作工具

## Context

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
| 三段式创作流程（捕捉→整理→打磨） | 匹配"拙"笔用户的真实写作习惯：先有想法再理顺再精修 | — Pending |
| 编辑器采用豆包扩展式选文浮窗 | 直觉化交互，用户无学习成本，拖选即出功能菜单 | — Pending |
| 知识库自动注入而非手动选择 | 减少用户操作负担，AI写的时候自动加载相关角色/设定 | — Pending |
| 反AI味通过Prompt工程隐式实现 | 不增加UI复杂度，在Prompt层注入"反AI味"指令和后处理 | — Pending |
| Skill系统先做核心（AI创建+守护），模板库后补 | 核心价值在于"AI辅助创建+实时守护"能力，预设模板是锦上添花 | — Pending |
| 故事结构层纳入MVP | 伏笔跟踪和逻辑闭环是核心差异化，不能等到Phase 2 | — Pending |
| Flutter跨平台 | "一处编写，处处运行"，同时满足Windows桌面和Android移动端 | — Pending |

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
*Last updated: 2026-05-31 after initialization*
