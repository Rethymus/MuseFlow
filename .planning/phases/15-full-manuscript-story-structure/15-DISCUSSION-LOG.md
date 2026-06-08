# Phase 15: Full Manuscript & Story Structure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 15-full-manuscript-story-structure
**Areas discussed:** 故事延续策略, 伏笔验证方式, 清洗与导出验证, 统计验证方式, GitHub展示延后项

---

## 故事延续策略

| Option | Description | Selected |
|--------|-------------|----------|
| 四段式 (金丹→元婴→化神→结局) | 每阶段有明确目标，经典修仙节奏 | |
| 三段式 (金丹→元婴→飞升) | 前松后紧，中间有冲突高潮 | ✓ |
| 自定义方向 | 用户有自己的故事线规划 | |

**User's choice:** 三段式 (金丹→元婴→飞升)
**Notes:** 31-60章金丹期（含结丹失败/重来），61-90章元婴期（含劫难/心魔），91-100章飞升结局。

| Option | Description | Selected |
|--------|-------------|----------|
| 经典冲突多线并进 | 结丹失败、同门算计、师姐被掳、门派大战、心魔劫、天劫。适合验证伏笔埋设和回收。 | ✓ |
| 单主线+简单支线 | 结构简单但伏笔验证空间较小 | |
| 自定义冲突 | 用户有具体冲突设计想法 | |

**User's choice:** 经典冲突多线并进

| Option | Description | Selected |
|--------|-------------|----------|
| 复用 + 阶段 prompt | 复用 Phase 14 serial_generation_test 模式，改起始章节为31，prompt加入阶段上下文 | ✓ |
| 每章独立 prompt | 灵活性高但工作量大 | |
| 交给你决定 | Claude 规划具体 prompt 策略 | |

**User's choice:** 复用 + 阶段 prompt

| Option | Description | Selected |
|--------|-------------|----------|
| 前章摘要注入 | 每章生成时注入前一章摘要作为上下文，Phase 11 已有相邻章节摘要机制 | ✓ |
| 每 5 章注入阶段摘要 | 减少 token 消耗但可能牺牲连贯性 | |
| 仅知识库不注前文 | 不注入前文上下文，仅依赖知识库 | |

**User's choice:** 前章摘要注入

---

## 伏笔验证方式 (JOURNEY-07)

| Option | Description | Selected |
|--------|-------------|----------|
| 3-4 条主伏笔线 | 神秘身世、师姐的秘密、门派禁地、远古法器。在30章前埋设，100章内全部回收。 | ✓ |
| 1-2 条主+小伏笔 | 验证范围较窄但更容易断言 | |
| 自定义伏笔设计 | 用户有伏笔具体设计想法 | |

**User's choice:** 3-4 条主伏笔线

| Option | Description | Selected |
|--------|-------------|----------|
| 手动操作 UI 验证 | 手动埋设伏笔节点，验证 UI 显示状态变化 | |
| 自动化脚本验证 | Dart 测试调用 ForeshadowingService API，断言数据层 | |
| 自动化 + 手动 UI 抽查 | 覆盖最全：数据层 + UI 层 | ✓ |

**User's choice:** 自动化 + 手动 UI 抽查

| Option | Description | Selected |
|--------|-------------|----------|
| 验证偏离检测持续工作 | 100章偏离检测应持续触发，警告数量合理增长（Phase 14 的 30章有 87 次） | ✓ |
| 跳过，Phase 14 已覆盖 | Phase 14 已验证 30 章偏离检测 | |
| 自定义验证范围 | 用户有其他验证需求 | |

**User's choice:** 验证偏离检测持续工作

---

## 清洗与导出验证 (JOURNEY-08/09)

| Option | Description | Selected |
|--------|-------------|----------|
| 全量清洗 + 自动化断言 | 对 100 章全量执行格式清洗，自动化检查结果 | ✓ |
| 全量清洗 + 抽查 | 全量清洗但只抽查 10-20 章 | |
| 自定义方案 | 用户有其他想法 | |

**User's choice:** 全量清洗 + 自动化断言

| Option | Description | Selected |
|--------|-------------|----------|
| 全量导出 + 多层断言 | Markdown 结构/TXT 纯文本/JSON 元数据/文件大小 | ✓ |
| 仅文件存在性检查 | 最简单但验证力弱 | |
| 自定义验证深度 | 用户有其他想法 | |

**User's choice:** 全量导出 + 多层断言

| Option | Description | Selected |
|--------|-------------|----------|
| 三类核心断言 | Markdown残留、中英标点混用、排版异常 | ✓ |
| 仅 Markdown 残留 | 最简单 | |
| 自定义检查项 | 用户有其他想检查的问题类型 | |

**User's choice:** 三类核心断言

---

## 统计验证方式 (JOURNEY-10)

| Option | Description | Selected |
|--------|-------------|----------|
| 三指标验证 | 总字数、AI使用率、写作速度 | ✓ |
| 字数 + AI 使用率 | 不验证写作速度 | |
| 自定义指标 | 用户有其他统计指标想验证 | |

**User's choice:** 三指标验证

| Option | Description | Selected |
|--------|-------------|----------|
| 范围断言，允许误差 | 总字数 ±10%，AI使用率 ±5%，写作速度 > 0 | ✓ |
| 精确断言，严格匹配 | 每章字数精确匹配 | |
| 自定义精度 | 用户有其他精度要求 | |

**User's choice:** 范围断言，允许误差

| Option | Description | Selected |
|--------|-------------|----------|
| 验证审计记录完整性 | 审计记录 ≥ 100 次，token 在合理范围 | ✓ |
| 跳过，Phase 14 已覆盖 | Phase 14 已验证 30 次审计 | |

**User's choice:** 验证审计记录完整性

---

## GitHub展示延后项

| Option | Description | Selected |
|--------|-------------|----------|
| 完整小说包 | 100章+标题+简介+角色图+世界观摘要 | ✓ |
| 仅原始手稿 | 最小化处理 | |

**User's choice:** 完整小说包

| Option | Description | Selected |
|--------|-------------|----------|
| 产品经理式激情推广 | 强调反AI味核心理念、三段式流程、100章实战案例、截图展示 | ✓ |
| 技术文档式 | 架构图、API说明、贡献指南 | |

**User's choice:** 产品经理式激情推广

| Option | Description | Selected |
|--------|-------------|----------|
| WSL2 现有环境截图 | 自动化流程绕过 IME 限制，Phase 14 已证明可行 | ✓ |
| Phase 16 后统一截图 | 等原生设备 | |

**User's choice:** WSL2 现有环境截图，自动化流程绕过 IME 限制。用户指出"IME不可用是限制人工操作的，自动化流程可以忽略这个缺陷"。

| Option | Description | Selected |
|--------|-------------|----------|
| docs/sample-novel/ + 双语 README | 小说包独立目录，README.md + README_EN.md 互相链接 | ✓ |
| 独立小说仓库 | 小说放到单独 repo | |

**User's choice:** docs/sample-novel/ + 双语 README

---

## Claude's Discretion

Planners may choose:
- 三段式故事的具体情节大纲和每阶段章数分配
- 3-4 条主伏笔线的具体内容
- 阶段 prompt 的具体措辞
- 前章摘要的生成方式（AI 生成 vs 截取前 N 字）
- 格式清洗断言的正则表达式细节
- 导出 JSON 元数据的具体字段验证列表
- 自动化测试脚本的具体结构和分段策略
- 伏笔 UI 抽查的具体操作步骤

## Deferred Ideas

- 完整小说包（100章+标题+简介+角色图+世界观摘要）→ docs/sample-novel/
- 中英文双语 README（产品经理推广风格）→ README.md + README_EN.md
- 全功能自动化截图（WSL2 环境，绕过 IME 限制）
- 同步到远程仓库（发布流程）
