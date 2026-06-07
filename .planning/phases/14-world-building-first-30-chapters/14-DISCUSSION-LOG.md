# Phase 14: World-Building & First 30 Chapters - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-07
**Phase:** 14-world-building-first-30-chapters
**Areas discussed:** 验证执行方式, 世界观与故事策略

---

## 验证执行方式

### Q1: 30章验证的主要执行方式

| Option | Description | Selected |
|--------|-------------|----------|
| 自动化为主（推荐） | FakeAdapter + 自动化脚本创建 30 章，手动抽查关键交互 | ✓ |
| 手动全流程 | 手动创建世界、输入碎片、逐章生成。真实但耗时 3-5 小时 | |
| 混合模式 | 自动创建骨架，手动验证 AI 生成和编辑器 | |

**User's choice:** 自动化为主

### Q2: AI 内容生成数据来源

| Option | Description | Selected |
|--------|-------------|----------|
| FakeAdapter（推荐） | 确定性输出，无需 API Key | |
| 真实 API（GLM） | 验证真实 AI 交互、知识库注入、反AI味 | ✓ |
| 混合：25+5 | 25 章 FakeAdapter + 5 章真实 API | |

**User's choice:** 真实 API（GLM）— 用户已有 API Key

### Q3: 手动抽查范围

| Option | Description | Selected |
|--------|-------------|----------|
| 编辑器浮窗操作 | 验证改写/润色/自由编辑 + 反AI味 | ✓ |
| 知识库注入 + Skill 守护 | 角色名称/设定注入 + 偏离检测提醒 | ✓ |
| 开篇引导三种风格 | 场景切入/人物切入/悬念切入 | ✓ |
| 章节操作（排序/拆分/合并） | CRUD + 排序/拆分/合并/复制/删除 | ✓ |

**User's choice:** 全部 4 项

### Q4: 问题记录方式

| Option | Description | Selected |
|--------|-------------|----------|
| 结构化问题清单（推荐） | 分类（功能缺陷/体验问题/缺失需求），按严重程度排序 | ✓ |
| 简单笔记 | 随手记录不做分类 | |
| 即时修复 | 发现即修，不单独记录 | |

**User's choice:** 结构化问题清单

### Q5: GLM API Key 状态

| Option | Description | Selected |
|--------|-------------|----------|
| 已有 API Key | 执行时可直接配置 | ✓ |
| 还没，会准备 | 执行前获取 | |
| 执行时再说 | 不提前确认 | |

**User's choice:** 已有 API Key

### Q6: AI 调用并发策略

| Option | Description | Selected |
|--------|-------------|----------|
| 串行 + 间隔（推荐） | 逐章生成，间隔 2-3 秒，约 3-5 分钟 | ✓ |
| 小批量并发（5章） | 批量 5 章并发，更快但可能限流 | |
| 不在意 | 速度不重要 | |

**User's choice:** 串行 + 间隔

### Q7: AI 调用失败处理

| Option | Description | Selected |
|--------|-------------|----------|
| 遇错即停 | 立即停止，记录错误 | ✓ |
| 跳过失败继续 | 标记空章继续 | |
| 重试 3 次后跳过 | 最多重试 3 次 | |

**User's choice:** 遇错即停

---

## 世界观与故事策略

### Q8: 修仙世界观搭建方式

| Option | Description | Selected |
|--------|-------------|----------|
| 使用修仙预设模板（推荐） | Phase 7 已有模板，快速启动 | |
| 从零手动创建 | 更贴近真实用户，但耗时 | |
| 模板 + 自定义补充 | 模板做基础，手动补充角色和设定 | ✓ |

**User's choice:** 模板 + 自定义补充

### Q9: 角色卡数量

| Option | Description | Selected |
|--------|-------------|----------|
| 3-4 个角色（推荐） | 主角 + 2-3 配角，验证基本功能 | ✓ |
| 6-8 个角色 | 更丰富但创建耗时 | |
| 2-3 个角色 | 最小集合 | |

**User's choice:** 3-4 个角色

### Q10: Skill 守护规则数量

| Option | Description | Selected |
|--------|-------------|----------|
| 1-2 条核心规则（推荐） | 简单有效 | |
| 4-5 条规则 | 更全面的 Skill 守护验证 | ✓ |
| 不配置 Skill | 只验证世界观和知识库 | |

**User's choice:** 4-5 条规则

### Q11: 30 章内容策略

| Option | Description | Selected |
|--------|-------------|----------|
| 连贯故事线（推荐） | 凡人到筑基的成长线，验证跨章一致性 | ✓ |
| 独立验证章节 | 每章验证不同功能 | |
| 5 个小弧线 | 每弧 6 章，折中方案 | |

**User's choice:** 连贯故事线

### Q12: 每章字数

| Option | Description | Selected |
|--------|-------------|----------|
| 每章 ~100 字 | ROADMAP 最低标准，总计 ~3000 字 | |
| 每章 300-500 字 | 更接近真实创作，总计 ~1-1.5 万字 | ✓ |
| 前重后轻（5+25） | 前 5 章长，后 25 章短 | |

**User's choice:** 每章 300-500 字

---

## Claude's Discretion

以下方面用户授权 Claude 自行决定：
- 修仙故事的具体情节大纲（30 章主题/情节点）
- 角色卡的具体字段内容（名字、性格、背景、能力）
- Skill 守护规则的具体措辞和触发条件
- 自动化脚本的具体结构（脚本分段策略、复用 Phase 13 基础设施的方式）
- 结构化问题清单的具体格式和存储位置
- 手动抽查的操作步骤清单格式
- 碎片捕捉验证的灵感碎片内容
- 知识库注入验证的断言方式

## Deferred Ideas

None — discussion stayed within phase scope.
